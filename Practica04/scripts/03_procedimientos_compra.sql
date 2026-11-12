/* ============================================================
   PRÁCTICA 04 - 03. PROCEDIMIENTOS DEL PROCESO DE COMPRA
   Ejecutar como: adrian.rios (superadmin), después de 01 y 02.
   Los GRANT EXECUTE se otorgan en remote_users_privileges_creation.sql

   Estados de la orden (tb_orders.status_string):
     Registered -> Payed -> Attended -> Sended -> Delivered
     Canceled (sin inventario / cancelación total) | Devolved (devolución en curso)

   Quién ejecuta cada procedimiento:
     Usuario (app_web / app_movil):
        sp_register_address, sp_create_order_from_cart, sp_set_order_address,
        sp_register_payment (rol buyer), sp_request_item_cancellation, sp_request_return
     Sistema (adrian.rios / admin):
        sp_authorize_payment, sp_process_order, sp_apply_cancellation,
        sp_refund_cancellation, sp_ship_order, sp_deliver_order,
        sp_deliver_to_pickup_point, sp_pickup_order, sp_reship_return,
        sp_deliver_reshipment
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;

DROP PROCEDURE IF EXISTS sp_create_order_from_cart;
DROP PROCEDURE IF EXISTS sp_set_order_address;
DROP PROCEDURE IF EXISTS sp_register_payment;
DROP PROCEDURE IF EXISTS sp_authorize_payment;
DROP PROCEDURE IF EXISTS sp_refund_amount;
DROP PROCEDURE IF EXISTS sp_cancel_whole_order;
DROP PROCEDURE IF EXISTS sp_process_order;
DROP PROCEDURE IF EXISTS sp_request_item_cancellation;
DROP PROCEDURE IF EXISTS sp_apply_cancellation;
DROP PROCEDURE IF EXISTS sp_refund_cancellation;
DROP PROCEDURE IF EXISTS sp_ship_order;
DROP PROCEDURE IF EXISTS sp_deliver_order;
DROP PROCEDURE IF EXISTS sp_deliver_to_pickup_point;
DROP PROCEDURE IF EXISTS sp_pickup_order;
DROP PROCEDURE IF EXISTS sp_request_return;
DROP PROCEDURE IF EXISTS sp_reship_return;
DROP PROCEDURE IF EXISTS sp_deliver_reshipment;

DELIMITER $$

/* ------------------------------------------------------------
   CARRITO -> ORDEN DE COMPRA
   Convierte el carrito activo del usuario en una orden:
     tb_orders (cabecera, liga cart_ID) -> tbd_buyer_orders (una por
     vendedor) -> tbd_order_items (productos con precio congelado).
   El carrito queda cerrado (status = 0). El inventario NO se descuenta
   aquí: se descuenta cuando el sistema atiende la orden.
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_create_order_from_cart(IN p_user_id INT, OUT p_order_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_cart INT UNSIGNED;
    DECLARE v_items INT DEFAULT 0;
    DECLARE v_bad INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT MAX(ID) INTO v_cart FROM tb_carts WHERE user_ID = p_user_id AND status = 1;
    IF v_cart IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene carrito activo';
    END IF;

    SELECT COUNT(*) INTO v_items FROM tbd_cart_items WHERE cart_ID = v_cart;
    IF v_items = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El carrito está vacío';
    END IF;

    SELECT COUNT(*) INTO v_bad
    FROM (SELECT ci.product_ID, SUM(ci.quantity) AS qty FROM tbd_cart_items ci WHERE ci.cart_ID = v_cart GROUP BY ci.product_ID) x
    JOIN tb_products p ON p.id = x.product_ID
    WHERE p.status <> 1 OR p.current_stock < x.qty;
    SELECT v_bad + COUNT(*) INTO v_bad
    FROM tbd_cart_items ci
    JOIN tbd_products_users_providers pup ON pup.user_ID = ci.provider_ID AND pup.product_ID = ci.product_ID
    WHERE ci.cart_ID = v_cart AND pup.status <> 1;
    IF v_bad > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El carrito contiene productos no disponibles o sin existencias';
    END IF;

    START TRANSACTION;

    INSERT INTO tb_orders (`key`, User_ID, cart_ID, total_products, total_cost)
    SELECT CONCAT('ORD-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), '-', v_cart),
           p_user_id, v_cart, SUM(ci.quantity), SUM(ci.quantity * p.current_price)
    FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID
    WHERE ci.cart_ID = v_cart;
    SET p_order_id = LAST_INSERT_ID();

    INSERT INTO tbd_buyer_orders (order_ID, seller_ID, subtotal)
    SELECT p_order_id, ci.provider_ID, SUM(ci.quantity * p.current_price)
    FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID
    WHERE ci.cart_ID = v_cart
    GROUP BY ci.provider_ID;

    INSERT INTO tbd_order_items (buyer_order_ID, product_ID, provider_ID, product_name, quantity, unit_price)
    SELECT bo.ID, ci.product_ID, ci.provider_ID, p.name, ci.quantity, p.current_price
    FROM tbd_cart_items ci
    JOIN tb_products p ON p.id = ci.product_ID
    JOIN tbd_buyer_orders bo ON bo.order_ID = p_order_id AND bo.seller_ID = ci.provider_ID
    WHERE ci.cart_ID = v_cart;

    UPDATE tb_carts SET status = 0 WHERE ID = v_cart;

    COMMIT;
END$$

/* ------------------------------------------------------------
   DOMICILIO DE ENVÍO DE LA ORDEN (debe pertenecer al comprador)
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_set_order_address(IN p_order_id INT UNSIGNED, IN p_address_id BIGINT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_user INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_addr_user INT;

    SELECT User_ID, status_string INTO v_user, v_status FROM tb_orders WHERE ID = p_order_id;
    IF v_user IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no existe';
    END IF;
    IF v_status NOT IN ('Registered', 'Payed', 'Attended') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden ya fue enviada o cancelada: no se puede cambiar el domicilio';
    END IF;
    SELECT user_ID INTO v_addr_user FROM tb_user_addresses WHERE ID = p_address_id AND status = 1;
    IF v_addr_user IS NULL OR v_addr_user <> v_user THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El domicilio no existe o no pertenece al comprador de la orden';
    END IF;

    UPDATE tb_orders SET shipping_address_ID = p_address_id, last_update = NOW() WHERE ID = p_order_id;
END$$

/* ------------------------------------------------------------
   REGISTRO DEL PAGO DE LA ORDEN (rol buyer)
   p_installments : número de pagos (más de 1 solo con tarjeta de crédito,
                    uno por mes). Se crean todos en estado Pending.
   p_method_override : forma de pago efectiva del catálogo (p. ej. 'CASH')
                    cuando difiere del tipo del método registrado; NULL usa
                    el tipo del método registrado.
   Con cupón de regalo el pago se liquida de inmediato (saldo prepagado).
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_register_payment(
    IN p_order_id INT UNSIGNED, IN p_user_payment_method_id BIGINT UNSIGNED,
    IN p_installments TINYINT UNSIGNED, IN p_method_override VARCHAR(30),
    OUT p_payment_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_user INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_type VARCHAR(30);
    DECLARE v_code VARCHAR(30);
    DECLARE v_provider VARCHAR(60);
    DECLARE v_ref VARCHAR(255);
    DECLARE v_pm INT UNSIGNED;
    DECLARE v_existing INT DEFAULT 0;
    DECLARE v_n INT;
    DECLARE v_i INT DEFAULT 1;
    DECLARE v_each DECIMAL(12,2);
    DECLARE v_amount DECIMAL(12,2);
    DECLARE v_coupon INT UNSIGNED;
    DECLARE v_coupon_amount DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT User_ID, status_string, total_cost INTO v_user, v_status, v_total FROM tb_orders WHERE ID = p_order_id;
    IF v_user IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no existe';
    END IF;
    IF v_status <> 'Registered' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no está pendiente de pago';
    END IF;

    SELECT t.code, m.provider, m.provider_method_ref INTO v_type, v_provider, v_ref
    FROM tbd_user_payment_methods m JOIN tbc_payment_methods_types t ON t.ID = m.payment_method_type_ID
    WHERE m.ID = p_user_payment_method_id AND m.user_ID = v_user AND m.status = 1;
    IF v_type IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El método de pago no existe, está inactivo o no pertenece al comprador de la orden';
    END IF;

    SELECT COUNT(*) INTO v_existing FROM tb_payments WHERE order_ID = p_order_id AND payment_status IN ('Pending','Authorized','Paid');
    IF v_existing > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden ya tiene un pago registrado';
    END IF;

    SET v_code = COALESCE(p_method_override, v_type);
    SELECT pm.ID INTO v_pm FROM tb_payment_methods pm JOIN tbc_payment_methods_types t ON t.ID = pm.type_ID WHERE t.code = v_code;
    IF v_pm IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La forma de pago indicada no existe en el catálogo';
    END IF;

    SET v_n = GREATEST(COALESCE(p_installments, 1), 1);
    IF v_n > 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El máximo de mensualidades es 12';
    END IF;
    IF v_n > 1 AND v_code <> 'CREDIT_CARD' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo la tarjeta de crédito admite pagos en mensualidades';
    END IF;

    IF v_code = 'GIFT_COUPON' THEN
        SELECT ID, amount INTO v_coupon, v_coupon_amount FROM tb_gift_coupons
        WHERE code = v_ref AND coupon_status = 'Available' AND (user_ID IS NULL OR user_ID = v_user) FOR UPDATE;
        IF v_coupon IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cupón no existe, ya fue utilizado o pertenece a otro usuario';
        END IF;
        IF v_coupon_amount < v_total THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El saldo del cupón no cubre el total de la orden';
        END IF;
    END IF;

    START TRANSACTION;

    SET v_each = ROUND(v_total / v_n, 2);
    WHILE v_i <= v_n DO
        SET v_amount = IF(v_i = v_n, v_total - v_each * (v_n - 1), v_each);
        INSERT INTO tb_payments (order_ID, payment_method_ID, user_payment_method_ID, amount, currency,
                                 installment_number, installments_total, due_date, payment_status, provider, provider_reference)
        VALUES (p_order_id, v_pm, p_user_payment_method_id, v_amount, 'MXN',
                v_i, v_n, DATE_ADD(CURDATE(), INTERVAL (v_i - 1) MONTH), 'Pending', v_provider, CONCAT('PAY-', UUID_SHORT()));
        IF v_i = 1 THEN
            SET p_payment_id = LAST_INSERT_ID();
        END IF;
        SET v_i = v_i + 1;
    END WHILE;

    IF v_code = 'GIFT_COUPON' THEN
        UPDATE tb_gift_coupons SET coupon_status = 'Used', user_ID = v_user, order_ID = p_order_id, used_at = NOW() WHERE ID = v_coupon;
    END IF;

    COMMIT;

    IF v_code = 'GIFT_COUPON' THEN
        CALL sp_authorize_payment(p_payment_id, 1, '00', 'Aprobada con saldo de cupón de regalo');
    END IF;
END$$

/* ------------------------------------------------------------
   TRANSACCIÓN BANCARIA Y AUTORIZACIÓN (sistema)
   p_approve = 1 : Authorization + Capture exitosas, pago Paid y la
                   orden pasa a Payed (si seguía Registered).
   p_approve = 0 : Authorization fallida con el motivo recibido,
                   el pago queda Failed.
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_authorize_payment(
    IN p_payment_id INT UNSIGNED, IN p_approve TINYINT, IN p_response_code VARCHAR(10), IN p_response_message VARCHAR(200))
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_order INT UNSIGNED;
    DECLARE v_amount DECIMAL(10,2);
    DECLARE v_currency CHAR(3);
    DECLARE v_provider VARCHAR(60);
    DECLARE v_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT order_ID, amount, currency, provider, payment_status INTO v_order, v_amount, v_currency, v_provider, v_status
    FROM tb_payments WHERE ID = p_payment_id;
    IF v_order IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El pago no existe';
    END IF;
    IF v_status <> 'Pending' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El pago no está pendiente';
    END IF;

    START TRANSACTION;

    IF p_approve = 1 THEN
        INSERT INTO tb_payment_transaction (payment_ID, transaction_type, transaction_status, amount, currency, provider,
                                            provider_transaction_id, idempotency_key, response_code, response_message, request_date, response_date)
        VALUES (p_payment_id, 'Authorization', 'Succeeded', v_amount, v_currency, v_provider,
                CONCAT('TXN-', UUID_SHORT()), UUID(), p_response_code, p_response_message, NOW(), NOW());
        INSERT INTO tb_payment_transaction (payment_ID, transaction_type, transaction_status, amount, currency, provider,
                                            provider_transaction_id, idempotency_key, response_code, response_message, request_date, response_date)
        VALUES (p_payment_id, 'Capture', 'Succeeded', v_amount, v_currency, v_provider,
                CONCAT('TXN-', UUID_SHORT()), UUID(), p_response_code, 'Cargo aplicado', NOW(), NOW());
        UPDATE tb_payments SET payment_status = 'Paid', paid_date = NOW() WHERE ID = p_payment_id;
        UPDATE tb_orders SET status_string = 'Payed', last_update = NOW() WHERE ID = v_order AND status_string = 'Registered';
    ELSE
        INSERT INTO tb_payment_transaction (payment_ID, transaction_type, transaction_status, amount, currency, provider,
                                            provider_transaction_id, idempotency_key, response_code, response_message, request_date, response_date)
        VALUES (p_payment_id, 'Authorization', 'Failed', v_amount, v_currency, v_provider,
                CONCAT('TXN-', UUID_SHORT()), UUID(), p_response_code, p_response_message, NOW(), NOW());
        UPDATE tb_payments SET payment_status = 'Failed' WHERE ID = p_payment_id;
    END IF;

    COMMIT;
END$$

/* ------------------------------------------------------------
   REEMBOLSO (interno): reparte p_amount entre los pagos cobrados de la
   orden, registra tb_refunds + transacción Refund y actualiza el estatus
   del pago. Si ya no queda ningún pago vigente, libera el cupón de regalo
   usado en la orden (se reasigna al usuario).
   La transacción la controla el procedimiento que lo invoca.
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_refund_amount(
    IN p_order_id INT UNSIGNED, IN p_cancellation_id INT UNSIGNED, IN p_amount DECIMAL(12,2),
    IN p_user_id INT, IN p_detail VARCHAR(500))
    SQL SECURITY DEFINER
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_pid INT UNSIGNED;
    DECLARE v_pamt DECIMAL(10,2);
    DECLARE v_refunded DECIMAL(12,2);
    DECLARE v_take DECIMAL(12,2);
    DECLARE v_remaining DECIMAL(12,2);
    DECLARE v_rid INT UNSIGNED;
    DECLARE cur CURSOR FOR
        SELECT ID, amount FROM tb_payments
        WHERE order_ID = p_order_id AND payment_status IN ('Paid', 'PartiallyRefunded') ORDER BY ID DESC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SET v_remaining = p_amount;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_pid, v_pamt;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        SELECT COALESCE(SUM(amount), 0) INTO v_refunded FROM tb_refunds
        WHERE payment_ID = v_pid AND refund_status IN ('Pending', 'Submitted', 'Succeeded');
        SET v_take = LEAST(v_remaining, v_pamt - v_refunded);
        IF v_take > 0 THEN
            INSERT INTO tb_refunds (payment_ID, cancellation_ID, reason, amount, currency, refund_status, provider, provider_reference,
                                    requested_by_user_ID, reason_detail, processed_at)
            SELECT v_pid, p_cancellation_id, 'Cancellation', v_take, currency, 'Succeeded', provider, CONCAT('RF-', UUID_SHORT()),
                   p_user_id, p_detail, NOW()
            FROM tb_payments WHERE ID = v_pid;
            SET v_rid = LAST_INSERT_ID();

            INSERT INTO tb_payment_transaction (payment_ID, refund_ID, transaction_type, transaction_status, amount, currency, provider,
                                                provider_transaction_id, idempotency_key, response_code, response_message, request_date, response_date)
            SELECT v_pid, v_rid, 'Refund', 'Succeeded', v_take, currency, provider,
                   CONCAT('TXN-', UUID_SHORT()), UUID(), '00', 'Reembolso aplicado', NOW(), NOW()
            FROM tb_payments WHERE ID = v_pid;

            UPDATE tb_payments
            SET payment_status = IF(v_refunded + v_take >= amount, 'Refunded', 'PartiallyRefunded')
            WHERE ID = v_pid;
            SET v_remaining = v_remaining - v_take;
        END IF;
        IF v_remaining <= 0 THEN
            LEAVE read_loop;
        END IF;
    END LOOP;
    CLOSE cur;

    UPDATE tb_gift_coupons
    SET coupon_status = 'Available', order_ID = NULL, used_at = NULL, times_reassigned = times_reassigned + 1
    WHERE order_ID = p_order_id
      AND NOT EXISTS (SELECT 1 FROM tb_payments p WHERE p.order_ID = p_order_id AND p.payment_status IN ('Paid', 'PartiallyRefunded'));
END$$

/* ------------------------------------------------------------
   CANCELACIÓN TOTAL DE LA ORDEN (interno, la usa el sistema)
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_cancel_whole_order(
    IN p_order_id INT UNSIGNED, IN p_reason_code VARCHAR(60), IN p_detail VARCHAR(500))
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_user INT;
    DECLARE v_cancel INT UNSIGNED;

    SELECT status_string, total_cost, User_ID INTO v_status, v_total, v_user FROM tb_orders WHERE ID = p_order_id;
    IF v_status IN ('Canceled', 'Sended', 'Delivered') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden ya no puede cancelarse en su estado actual';
    END IF;

    INSERT INTO tb_order_cancellations (order_ID, requested_by_user_ID, cancellation_scope, reason_code, reason_detail,
                                        cancellation_status, reviewed_at, completed_at, internal_notes)
    VALUES (p_order_id, NULL, 'WholeOrder', p_reason_code, p_detail, 'Completed', NOW(), NOW(), 'Cancelada automáticamente por el sistema');
    SET v_cancel = LAST_INSERT_ID();

    /* ítems cancelados (solo la cantidad que aún estaba vigente) */
    INSERT INTO tbd_cancellation_items (cancellation_ID, order_item_ID, quantity)
    SELECT v_cancel, oi.ID, oi.quantity - oi.canceled_quantity
    FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID
    WHERE bo.order_ID = p_order_id AND oi.quantity > oi.canceled_quantity;

    /* si ya se había descontado inventario, se regresa */
    IF v_status = 'Attended' THEN
        UPDATE tb_products p
        JOIN (SELECT oi.product_ID, SUM(oi.quantity - oi.canceled_quantity) AS qty
              FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID
              WHERE bo.order_ID = p_order_id GROUP BY oi.product_ID) x ON x.product_ID = p.id
        SET p.current_stock = p.current_stock + x.qty;
    END IF;

    UPDATE tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID
    SET oi.canceled_quantity = oi.quantity WHERE bo.order_ID = p_order_id;
    UPDATE tbd_buyer_orders SET fulfillment_status = 'Canceled' WHERE order_ID = p_order_id;
    UPDATE tb_payments SET payment_status = 'Failed' WHERE order_ID = p_order_id AND payment_status = 'Pending';

    IF v_total > 0 AND EXISTS (SELECT 1 FROM tb_payments WHERE order_ID = p_order_id AND payment_status IN ('Paid', 'PartiallyRefunded')) THEN
        CALL sp_refund_amount(p_order_id, v_cancel, v_total, v_user, p_detail);
    END IF;

    UPDATE tb_orders SET status_string = 'Canceled', last_update = NOW() WHERE ID = p_order_id;
END$$

/* ------------------------------------------------------------
   ATENDER LA ORDEN (sistema)
   Verifica inventario: si alcanza, lo descuenta y marca la orden como
   Attended; si no, la marca Canceled (no atendida por falta de inventario),
   reembolsa lo cobrado y reasigna el cupón de regalo utilizado.
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_process_order(IN p_order_id INT UNSIGNED)
    SQL SECURITY DEFINER
main: BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_short INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT status_string INTO v_status FROM tb_orders WHERE ID = p_order_id;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no existe';
    END IF;
    IF v_status <> 'Payed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no está pagada';
    END IF;

    START TRANSACTION;

    SELECT COUNT(*) INTO v_short
    FROM (SELECT oi.product_ID, SUM(oi.quantity - oi.canceled_quantity) AS qty
          FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID
          WHERE bo.order_ID = p_order_id GROUP BY oi.product_ID) x
    JOIN tb_products p ON p.id = x.product_ID
    WHERE p.current_stock < x.qty OR p.status <> 1;

    IF v_short > 0 THEN
        CALL sp_cancel_whole_order(p_order_id, 'OUT_OF_STOCK', 'Orden no atendida por falta de inventario');
        COMMIT;
        SELECT 'ORDEN NO ATENDIDA: falta de inventario. Orden cancelada y pago reembolsado' AS resultado;
        LEAVE main;
    END IF;

    UPDATE tb_products p
    JOIN (SELECT oi.product_ID, SUM(oi.quantity - oi.canceled_quantity) AS qty
          FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID
          WHERE bo.order_ID = p_order_id GROUP BY oi.product_ID) x ON x.product_ID = p.id
    SET p.current_stock = p.current_stock - x.qty;

    UPDATE tbd_buyer_orders SET fulfillment_status = 'Preparing' WHERE order_ID = p_order_id AND fulfillment_status = 'Pending';
    UPDATE tb_orders SET status_string = 'Attended', last_update = NOW() WHERE ID = p_order_id;

    COMMIT;
    SELECT 'ORDEN ATENDIDA: inventario descontado' AS resultado;
END$$

/* ------------------------------------------------------------
   CANCELACIÓN PARCIAL, PASO 1 (usuario): solicita cancelar unidades
   de un producto de su orden.
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_request_item_cancellation(
    IN p_user_id INT, IN p_order_item_id INT UNSIGNED, IN p_quantity INT UNSIGNED,
    IN p_reason_code VARCHAR(60), IN p_detail VARCHAR(500), OUT p_cancellation_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_buyer_order INT UNSIGNED;
    DECLARE v_order INT UNSIGNED;
    DECLARE v_user INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_avail INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT oi.buyer_order_ID, bo.order_ID, o.User_ID, o.status_string, oi.quantity - oi.canceled_quantity
      INTO v_buyer_order, v_order, v_user, v_status, v_avail
    FROM tbd_order_items oi
    JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID
    JOIN tb_orders o ON o.ID = bo.order_ID
    WHERE oi.ID = p_order_item_id;
    IF v_order IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto de la orden no existe';
    END IF;
    IF v_user <> p_user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto no pertenece a una orden del usuario';
    END IF;
    IF v_status NOT IN ('Registered', 'Payed', 'Attended') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden ya fue enviada o cancelada: no admite cancelaciones';
    END IF;
    IF p_quantity < 1 OR p_quantity > v_avail THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad a cancelar excede las unidades vigentes del producto';
    END IF;

    START TRANSACTION;
    INSERT INTO tb_order_cancellations (order_ID, buyer_order_ID, requested_by_user_ID, cancellation_scope, reason_code, reason_detail)
    VALUES (NULL, v_buyer_order, p_user_id, 'Items', p_reason_code, p_detail);
    SET p_cancellation_id = LAST_INSERT_ID();
    INSERT INTO tbd_cancellation_items (cancellation_ID, order_item_ID, quantity) VALUES (p_cancellation_id, p_order_item_id, p_quantity);
    COMMIT;
END$$

/* ------------------------------------------------------------
   CANCELACIÓN PARCIAL, PASO 2 (sistema): aprueba la cancelación y
   actualiza la orden (ítems, subtotal del vendedor, totales e inventario)
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_apply_cancellation(IN p_cancellation_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_buyer_order INT UNSIGNED;
    DECLARE v_order INT UNSIGNED;
    DECLARE v_order_status VARCHAR(20);
    DECLARE v_amount DECIMAL(12,2);
    DECLARE v_units INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT c.cancellation_status, c.buyer_order_ID, bo.order_ID, o.status_string
      INTO v_status, v_buyer_order, v_order, v_order_status
    FROM tb_order_cancellations c
    JOIN tbd_buyer_orders bo ON bo.ID = c.buyer_order_ID
    JOIN tb_orders o ON o.ID = bo.order_ID
    WHERE c.ID = p_cancellation_id AND c.cancellation_scope = 'Items';
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cancelación parcial no existe';
    END IF;
    IF v_status <> 'Requested' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cancelación ya fue procesada';
    END IF;
    IF v_order_status NOT IN ('Registered', 'Payed', 'Attended') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden ya fue enviada o cancelada';
    END IF;

    START TRANSACTION;

    SELECT SUM(ci.quantity * oi.unit_price), SUM(ci.quantity) INTO v_amount, v_units
    FROM tbd_cancellation_items ci JOIN tbd_order_items oi ON oi.ID = ci.order_item_ID
    WHERE ci.cancellation_ID = p_cancellation_id;

    UPDATE tbd_order_items oi JOIN tbd_cancellation_items ci ON ci.order_item_ID = oi.ID
    SET oi.canceled_quantity = oi.canceled_quantity + ci.quantity
    WHERE ci.cancellation_ID = p_cancellation_id;

    IF v_order_status = 'Attended' THEN
        UPDATE tb_products p
        JOIN (SELECT oi.product_ID, SUM(ci.quantity) AS qty
              FROM tbd_cancellation_items ci JOIN tbd_order_items oi ON oi.ID = ci.order_item_ID
              WHERE ci.cancellation_ID = p_cancellation_id GROUP BY oi.product_ID) x ON x.product_ID = p.id
        SET p.current_stock = p.current_stock + x.qty;
    END IF;

    UPDATE tbd_buyer_orders SET subtotal = subtotal - v_amount WHERE ID = v_buyer_order;
    IF (SELECT COALESCE(SUM(quantity - canceled_quantity), 0) FROM tbd_order_items WHERE buyer_order_ID = v_buyer_order) = 0 THEN
        UPDATE tbd_buyer_orders SET fulfillment_status = 'Canceled' WHERE ID = v_buyer_order;
    END IF;
    UPDATE tb_orders SET total_products = total_products - v_units, total_cost = total_cost - v_amount, last_update = NOW()
    WHERE ID = v_order;

    UPDATE tb_order_cancellations SET cancellation_status = 'Approved', reviewed_at = NOW(),
           internal_notes = 'Orden actualizada: ítems, subtotal, totales e inventario'
    WHERE ID = p_cancellation_id;

    COMMIT;
    SELECT p_cancellation_id AS cancellation_ID, v_units AS unidades_canceladas, v_amount AS monto_cancelado;
END$$

/* ------------------------------------------------------------
   CANCELACIÓN PARCIAL, PASO 3 (sistema): reembolso del monto cancelado
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_refund_cancellation(IN p_cancellation_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_order INT UNSIGNED;
    DECLARE v_user INT;
    DECLARE v_amount DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT c.cancellation_status, bo.order_ID, c.requested_by_user_ID INTO v_status, v_order, v_user
    FROM tb_order_cancellations c JOIN tbd_buyer_orders bo ON bo.ID = c.buyer_order_ID
    WHERE c.ID = p_cancellation_id AND c.cancellation_scope = 'Items';
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cancelación parcial no existe';
    END IF;
    IF v_status <> 'Approved' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cancelación no está aprobada o ya fue reembolsada';
    END IF;

    SELECT SUM(ci.quantity * oi.unit_price) INTO v_amount
    FROM tbd_cancellation_items ci JOIN tbd_order_items oi ON oi.ID = ci.order_item_ID
    WHERE ci.cancellation_ID = p_cancellation_id;

    START TRANSACTION;
    IF EXISTS (SELECT 1 FROM tb_payments WHERE order_ID = v_order AND payment_status IN ('Paid', 'PartiallyRefunded')) THEN
        CALL sp_refund_amount(v_order, p_cancellation_id, v_amount, v_user, 'Reembolso por cancelación parcial de productos');
    END IF;
    UPDATE tb_order_cancellations SET cancellation_status = 'Completed', completed_at = NOW() WHERE ID = p_cancellation_id;
    COMMIT;
    SELECT p_cancellation_id AS cancellation_ID, v_amount AS monto_reembolsado;
END$$

/* ------------------------------------------------------------
   ENVÍO (sistema): un envío por cada orden de vendedor vigente, hacia el
   domicilio elegido en la orden (o el predeterminado del comprador)
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_ship_order(IN p_order_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_user INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_addr BIGINT UNSIGNED;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT User_ID, status_string, shipping_address_ID INTO v_user, v_status, v_addr FROM tb_orders WHERE ID = p_order_id;
    IF v_user IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no existe';
    END IF;
    IF v_status <> 'Attended' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no ha sido atendida';
    END IF;
    IF v_addr IS NULL THEN
        SELECT ID INTO v_addr FROM tb_user_addresses
        WHERE user_ID = v_user AND status = 1 ORDER BY is_default DESC, ID DESC LIMIT 1;
    END IF;
    IF v_addr IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene domicilio de envío registrado';
    END IF;

    START TRANSACTION;

    INSERT INTO tb_shipments (buyer_order_ID, address_ID, recipient_name, recipient_phone, address_line_1, address_line_2,
                              city, state_region, postal_code, country_code, carrier, service_level, tracking_number,
                              shipment_status, shipped_at, estimated_delivery_at)
    SELECT bo.ID, v.address_ID, v.recipient_name, v.recipient_phone,
           CONCAT(v.street, ' ', v.ext_number, IF(v.int_number IS NULL, '', CONCAT(' Int. ', v.int_number))),
           v.neighborhood, v.city, v.state, v.postal_code, 'MX', 'SimExpress', 'Estándar', CONCAT('SIM', UUID_SHORT()),
           'InTransit', NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY)
    FROM tbd_buyer_orders bo JOIN vw_user_addresses_full v ON v.address_ID = v_addr
    WHERE bo.order_ID = p_order_id AND bo.fulfillment_status <> 'Canceled';

    UPDATE tbd_buyer_orders SET fulfillment_status = 'Sent' WHERE order_ID = p_order_id AND fulfillment_status <> 'Canceled';
    UPDATE tb_orders SET status_string = 'Sended', last_update = NOW() WHERE ID = p_order_id;

    COMMIT;
END$$

/* ------------------------------------------------------------
   ENTREGA EN DOMICILIO (sistema)
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_deliver_order(IN p_order_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT status_string INTO v_status FROM tb_orders WHERE ID = p_order_id;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no existe';
    END IF;
    IF v_status <> 'Sended' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no ha sido enviada';
    END IF;

    START TRANSACTION;
    UPDATE tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID
    SET s.shipment_status = 'Delivered', s.delivered_at = NOW()
    WHERE bo.order_ID = p_order_id AND s.reshipment_of_return_ID IS NULL AND s.shipment_status IN ('InTransit', 'OutForDelivery');
    UPDATE tbd_buyer_orders SET fulfillment_status = 'Delivered' WHERE order_ID = p_order_id AND fulfillment_status = 'Sent';
    UPDATE tb_orders SET status_string = 'Delivered', last_update = NOW() WHERE ID = p_order_id;
    COMMIT;
END$$

/* ------------------------------------------------------------
   ENTREGA EN PUNTO DE RECOLECCIÓN (sistema): nadie recibió el pedido
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_deliver_to_pickup_point(IN p_order_id INT UNSIGNED, IN p_pickup_point VARCHAR(255))
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT status_string INTO v_status FROM tb_orders WHERE ID = p_order_id;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no existe';
    END IF;
    IF v_status <> 'Sended' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no ha sido enviada';
    END IF;

    START TRANSACTION;
    UPDATE tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID
    SET s.shipment_status = 'AtPickupPoint', s.pickup_point = p_pickup_point
    WHERE bo.order_ID = p_order_id AND s.reshipment_of_return_ID IS NULL AND s.shipment_status IN ('InTransit', 'OutForDelivery');
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_pickup_order(IN p_order_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_pending INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT COUNT(*) INTO v_pending
    FROM tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID
    WHERE bo.order_ID = p_order_id AND s.shipment_status = 'AtPickupPoint';
    IF v_pending = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no tiene envíos en un punto de recolección';
    END IF;

    START TRANSACTION;
    UPDATE tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID
    SET s.shipment_status = 'PickedUp', s.delivered_at = NOW()
    WHERE bo.order_ID = p_order_id AND s.shipment_status = 'AtPickupPoint';
    UPDATE tbd_buyer_orders SET fulfillment_status = 'Delivered' WHERE order_ID = p_order_id AND fulfillment_status = 'Sent';
    UPDATE tb_orders SET status_string = 'Delivered', last_update = NOW() WHERE ID = p_order_id;
    COMMIT;
END$$

/* ------------------------------------------------------------
   DEVOLUCIÓN (usuario): reclama un producto recibido con daños
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_request_return(
    IN p_user_id INT, IN p_order_item_id INT UNSIGNED, IN p_quantity INT UNSIGNED,
    IN p_item_condition VARCHAR(20), IN p_reason_code VARCHAR(60), IN p_detail VARCHAR(1000),
    OUT p_return_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_buyer_order INT UNSIGNED;
    DECLARE v_order INT UNSIGNED;
    DECLARE v_user INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_avail INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT oi.buyer_order_ID, bo.order_ID, o.User_ID, o.status_string, oi.quantity - oi.canceled_quantity
      INTO v_buyer_order, v_order, v_user, v_status, v_avail
    FROM tbd_order_items oi
    JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID
    JOIN tb_orders o ON o.ID = bo.order_ID
    WHERE oi.ID = p_order_item_id;
    IF v_order IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto de la orden no existe';
    END IF;
    IF v_user <> p_user_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El producto no pertenece a una orden del usuario';
    END IF;
    IF v_status <> 'Delivered' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede reclamar una devolución de órdenes ya entregadas';
    END IF;
    IF p_quantity < 1 OR p_quantity > v_avail THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cantidad a devolver excede las unidades recibidas';
    END IF;

    START TRANSACTION;
    INSERT INTO tb_returns (buyer_order_ID, requested_by_user_ID, reason_code, reason_detail, return_status)
    VALUES (v_buyer_order, p_user_id, p_reason_code, p_detail, 'Requested');
    SET p_return_id = LAST_INSERT_ID();
    INSERT INTO tbd_return_items (return_ID, order_item_ID, quantity, item_condition, disposition, item_status)
    VALUES (p_return_id, p_order_item_id, p_quantity, p_item_condition, 'Pending', 'Requested');
    UPDATE tb_orders SET status_string = 'Devolved', last_update = NOW() WHERE ID = v_order;
    COMMIT;
END$$

/* ------------------------------------------------------------
   REENVÍO (sistema): autoriza la devolución, recibe el producto dañado y
   envía uno nuevo en buenas condiciones al mismo domicilio (sin reembolso)
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_reship_return(IN p_return_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_buyer_order INT UNSIGNED;
    DECLARE v_short INT DEFAULT 0;
    DECLARE v_shipments INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT return_status, buyer_order_ID INTO v_status, v_buyer_order FROM tb_returns WHERE ID = p_return_id;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La devolución no existe';
    END IF;
    IF v_status <> 'Requested' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La devolución ya fue procesada';
    END IF;

    SELECT COUNT(*) INTO v_short
    FROM tbd_return_items ri JOIN tbd_order_items oi ON oi.ID = ri.order_item_ID
    JOIN tb_products p ON p.id = oi.product_ID
    WHERE ri.return_ID = p_return_id AND p.current_stock < ri.quantity;
    IF v_short > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay inventario para el reenvío; procede un reembolso';
    END IF;

    SELECT COUNT(*) INTO v_shipments FROM tb_shipments WHERE buyer_order_ID = v_buyer_order AND reshipment_of_return_ID IS NULL;
    IF v_shipments = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no tiene un envío original del cual reenviar';
    END IF;

    START TRANSACTION;

    /* producto dañado recibido; la pieza de reemplazo sale del inventario */
    UPDATE tb_products p
    JOIN (SELECT oi.product_ID, SUM(ri.quantity) AS qty
          FROM tbd_return_items ri JOIN tbd_order_items oi ON oi.ID = ri.order_item_ID
          WHERE ri.return_ID = p_return_id GROUP BY oi.product_ID) x ON x.product_ID = p.id
    SET p.current_stock = p.current_stock - x.qty;

    UPDATE tbd_return_items SET item_status = 'Approved', disposition = 'SupplierReturn', approved_refund_amount = 0.00
    WHERE return_ID = p_return_id;
    UPDATE tb_returns SET return_status = 'Approved', authorized_at = NOW(), received_at = NOW(),
           internal_notes = 'Producto dañado recibido; se envía pieza de reemplazo sin costo'
    WHERE ID = p_return_id;

    INSERT INTO tb_shipments (buyer_order_ID, reshipment_of_return_ID, address_ID, recipient_name, recipient_phone, address_line_1,
                              address_line_2, city, state_region, postal_code, country_code, carrier, service_level, tracking_number,
                              shipment_status, shipped_at, estimated_delivery_at)
    SELECT s.buyer_order_ID, p_return_id, s.address_ID, s.recipient_name, s.recipient_phone, s.address_line_1,
           s.address_line_2, s.city, s.state_region, s.postal_code, s.country_code, s.carrier, 'Reenvío', CONCAT('SIM', UUID_SHORT()),
           'InTransit', NOW(), DATE_ADD(NOW(), INTERVAL 2 DAY)
    FROM tb_shipments s
    WHERE s.buyer_order_ID = v_buyer_order AND s.reshipment_of_return_ID IS NULL
    ORDER BY s.ID LIMIT 1;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE sp_deliver_reshipment(IN p_return_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_buyer_order INT UNSIGNED;
    DECLARE v_pending INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT COUNT(*) INTO v_pending FROM tb_shipments WHERE reshipment_of_return_ID = p_return_id AND shipment_status = 'InTransit';
    IF v_pending = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La devolución no tiene un reenvío en tránsito';
    END IF;
    SELECT buyer_order_ID INTO v_buyer_order FROM tb_returns WHERE ID = p_return_id;

    START TRANSACTION;
    UPDATE tb_shipments SET shipment_status = 'Delivered', delivered_at = NOW()
    WHERE reshipment_of_return_ID = p_return_id AND shipment_status = 'InTransit';
    UPDATE tb_returns SET return_status = 'Closed', closed_at = NOW() WHERE ID = p_return_id;
    UPDATE tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID
    SET o.status_string = 'Delivered', o.last_update = NOW()
    WHERE bo.ID = v_buyer_order AND o.status_string = 'Devolved';
    COMMIT;
END$$

DELIMITER ;
