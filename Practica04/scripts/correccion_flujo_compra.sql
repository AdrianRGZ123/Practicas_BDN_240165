/* ============================================================
   CORRECCIÓN DE db_test PARA EL FLUJO COMPLETO DE COMPRA
   Se aplica sobre "Respaldo 28-10-26.sql" ya restaurado.
   Después ejecutar scripts/remote_users_privileges_creation.sql
   (los GRANT de procedimientos requieren que ya existan).
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;

/* ------------------------------------------------------------
   1. CARRITO: un usuario puede tener varios carritos a lo largo
      del tiempo, pero solo uno activo (status = 1).
      Antes: UNIQUE(user_ID) impedía crear un segundo carrito.
   ------------------------------------------------------------ */
ALTER TABLE tb_carts
  ADD KEY idx_cart_user (user_ID),
  ADD COLUMN active_user_ID INT GENERATED ALWAYS AS (IF(status = b'1', user_ID, NULL)) STORED AFTER status,
  ADD UNIQUE KEY uk_cart_active_user (active_user_ID),
  DROP INDEX uk_cart_user;

/* ------------------------------------------------------------
   2. FK COMPUESTAS hacia tbd_products_users_providers.
      Antes: provider_ID y product_ID apuntaban por separado a
      user_ID y product_ID, sin garantizar que el par existiera.
   ------------------------------------------------------------ */
ALTER TABLE tbd_cart_items
  DROP FOREIGN KEY tbd_cart_items_ibfk_2,
  DROP FOREIGN KEY tbd_cart_items_ibfk_3,
  ADD KEY idx_cart_items_provider_product (provider_ID, product_ID),
  ADD CONSTRAINT fk_cart_items_provider_product FOREIGN KEY (provider_ID, product_ID)
      REFERENCES tbd_products_users_providers (user_ID, product_ID);

/* ------------------------------------------------------------
   3. ÓRDENES: tb_orders (cabecera de la compra) -> tbd_buyer_orders
      (una por vendedor) -> tbd_order_items.
      Antes: tb_orders no estaba ligada a nada y los ítems colgaban
      de tb_seller_orders, mientras envíos/devoluciones/cancelaciones
      colgaban de tbd_buyer_orders.
      tb_seller_orders queda sin uso (0 registros) y se conserva.
   ------------------------------------------------------------ */
ALTER TABLE tb_orders
  MODIFY total_cost DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  ADD UNIQUE KEY uk_orders_key (`key`);

ALTER TABLE tbd_buyer_orders
  ADD COLUMN order_ID INT UNSIGNED NOT NULL AFTER ID,
  ADD UNIQUE KEY uk_buyer_orders_order_seller (order_ID, seller_ID),
  ADD CONSTRAINT fk_buyer_orders_order FOREIGN KEY (order_ID) REFERENCES tb_orders (ID);

ALTER TABLE tbd_order_items
  DROP FOREIGN KEY tbd_order_items_ibfk_1,
  DROP FOREIGN KEY tbd_order_items_ibfk_2,
  DROP FOREIGN KEY tbd_order_items_ibfk_3,
  CHANGE COLUMN seller_order_ID buyer_order_ID INT UNSIGNED NOT NULL,
  RENAME INDEX seller_order_ID TO idx_order_items_buyer_order,
  ADD KEY idx_order_items_provider_product (provider_ID, product_ID),
  ADD CONSTRAINT fk_order_items_buyer_order FOREIGN KEY (buyer_order_ID) REFERENCES tbd_buyer_orders (ID),
  ADD CONSTRAINT fk_order_items_provider_product FOREIGN KEY (provider_ID, product_ID)
      REFERENCES tbd_products_users_providers (user_ID, product_ID);

/* ------------------------------------------------------------
   4. PAGOS: ligar el pago con la tarjeta registrada por el usuario
      (tbd_user_payment_methods). tb_payments.payment_method_ID sigue
      siendo el catálogo general (tb_payment_methods).
   ------------------------------------------------------------ */
ALTER TABLE tb_payments
  ADD COLUMN user_payment_method_ID BIGINT UNSIGNED DEFAULT NULL AFTER payment_method_ID,
  ADD KEY idx_payment_user_method (user_payment_method_ID),
  ADD CONSTRAINT fk_payment_user_method FOREIGN KEY (user_payment_method_ID)
      REFERENCES tbd_user_payment_methods (ID);

ALTER TABLE tbd_user_payment_methods
  ADD CONSTRAINT chk_user_pm_last_four CHECK (last_four IS NULL OR last_four REGEXP '^[0-9]{4}$');

/* ------------------------------------------------------------
   5. CATÁLOGOS VACÍOS
   ------------------------------------------------------------ */
INSERT INTO tbc_payment_methods_types (code, description) VALUES
  ('DEBIT_CARD',    'Tarjeta de débito'),
  ('CREDIT_CARD',   'Tarjeta de crédito'),
  ('BANK_TRANSFER', 'Transferencia bancaria'),
  ('CASH',          'Efectivo');

INSERT INTO tb_payment_methods (name, description) VALUES
  ('Tarjeta de débito',      'Pago con tarjeta de débito'),
  ('Tarjeta de crédito',     'Pago con tarjeta de crédito'),
  ('Transferencia bancaria', 'Pago por transferencia'),
  ('Efectivo',               'Pago en efectivo');

/* ------------------------------------------------------------
   5b. TRIGGER CON ERROR: registraba operation = 'Insert', valor que no
       existe en el ENUM de tb_logs.operation (Create, Read, Update, Delete),
       por lo que cualquier alta en tbd_products_users_providers fallaba.
   ------------------------------------------------------------ */
DROP TRIGGER IF EXISTS trg_products_users_providers_after_insert;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER trg_products_users_providers_after_insert
AFTER INSERT ON tbd_products_users_providers FOR EACH ROW
BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_products_users_providers',
        'Create',
        USER(),
        CONCAT('Relación producto-usuario registrada. User_ID=', NEW.user_ID, ', Product_ID=', NEW.product_ID, ', Tipo=', NEW.type_ownership),
        NOW(),
        1
    );
END$$
DELIMITER ;

/* ------------------------------------------------------------
   6. PRODUCTOS DISPONIBLES:tbd_products_users_providers estaba vacía,
      por eso ningún producto podía agregarse al carrito.
      Se asignan los productos activos a 20 usuarios proveedores.
   ------------------------------------------------------------ */
INSERT INTO tbd_products_users_providers (user_ID, product_ID, type_ownership, status, available_date)
SELECT s.ID, p.id, 'Owner', b'1', NOW()
FROM tb_products p
JOIN (SELECT ID, ROW_NUMBER() OVER (ORDER BY ID) - 1 AS n FROM (SELECT ID FROM tb_users WHERE status = 1 ORDER BY ID LIMIT 20) u) s
  ON s.n = MOD(p.id, 20)
WHERE p.status = 1;

/* ------------------------------------------------------------
   7. VISTA PARA "VERIFICAR ESTATUS" DE PRODUCTOS (paso 1)
   ------------------------------------------------------------ */
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_available_products AS
SELECT p.id AS product_ID, p.sku, p.name, p.current_price, p.current_stock,
       pup.user_ID AS provider_ID, pup.type_ownership
FROM tb_products p
JOIN tbd_products_users_providers pup ON pup.product_ID = p.id
WHERE p.status = 1 AND pup.status = 1 AND p.current_stock > 0;

DELIMITER $$

/* ------------------------------------------------------------
   8. VALIDACIÓN AL AGREGAR AL CARRITO (paso 3)
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` TRIGGER trg_tbd_cart_items_before_insert
BEFORE INSERT ON tbd_cart_items FOR EACH ROW
BEGIN
    DECLARE v_ok INT DEFAULT 0;
    DECLARE v_cart_status BIT(1);

    SELECT status INTO v_cart_status FROM tb_carts WHERE ID = NEW.cart_ID;
    IF v_cart_status IS NULL OR v_cart_status <> b'1' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El carrito no está activo';
    END IF;

    SELECT COUNT(*) INTO v_ok
    FROM vw_available_products
    WHERE product_ID = NEW.product_ID AND provider_ID = NEW.provider_ID
      AND current_stock >= NEW.quantity;
    IF v_ok = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Producto no disponible: inactivo, sin proveedor activo o sin existencias suficientes';
    END IF;
END$$

/* ------------------------------------------------------------
   9. PASO 4: ORDEN DE COMPRA A PARTIR DEL CARRITO ACTIVO
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

    /* productos inactivos, proveedor inactivo o existencias insuficientes (sumando por producto) */
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

    INSERT INTO tb_orders (`key`, User_ID, total_products, total_cost)
    SELECT CONCAT('ORD-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), '-', p_user_id),
           p_user_id, SUM(ci.quantity), SUM(ci.quantity * p.current_price)
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

    UPDATE tb_products p
    JOIN (SELECT product_ID, SUM(quantity) AS qty FROM tbd_cart_items WHERE cart_ID = v_cart GROUP BY product_ID) x
      ON x.product_ID = p.id
    SET p.current_stock = p.current_stock - x.qty;

    UPDATE tb_carts SET status = 0 WHERE ID = v_cart;

    COMMIT;
END$$

/* ------------------------------------------------------------
   10. PASO 7: PAGO ÚNICO DE LA ORDEN (rol buyer)
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_register_payment(IN p_order_id INT UNSIGNED, IN p_user_payment_method_id BIGINT UNSIGNED, OUT p_payment_id INT UNSIGNED)
    SQL SECURITY DEFINER
BEGIN
    DECLARE v_user INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_type VARCHAR(30);
    DECLARE v_provider VARCHAR(60);
    DECLARE v_pm INT UNSIGNED;
    DECLARE v_existing INT DEFAULT 0;

    SELECT User_ID, status_string, total_cost INTO v_user, v_status, v_total FROM tb_orders WHERE ID = p_order_id;
    IF v_user IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no existe';
    END IF;
    IF v_status <> 'Registered' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no está pendiente de pago';
    END IF;

    SELECT t.code, m.provider INTO v_type, v_provider
    FROM tbd_user_payment_methods m JOIN tbc_payment_methods_types t ON t.ID = m.payment_method_type_ID
    WHERE m.ID = p_user_payment_method_id AND m.user_ID = v_user AND m.status = 1;
    IF v_type IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El método de pago no existe, está inactivo o no pertenece al comprador de la orden';
    END IF;

    SELECT COUNT(*) INTO v_existing FROM tb_payments WHERE order_ID = p_order_id AND payment_status IN ('Pending','Authorized','Paid');
    IF v_existing > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden ya tiene un pago registrado';
    END IF;

    SELECT ID INTO v_pm FROM tb_payment_methods
    WHERE name = CASE v_type WHEN 'DEBIT_CARD' THEN 'Tarjeta de débito' WHEN 'CREDIT_CARD' THEN 'Tarjeta de crédito'
                             WHEN 'BANK_TRANSFER' THEN 'Transferencia bancaria' ELSE 'Efectivo' END;

    INSERT INTO tb_payments (order_ID, payment_method_ID, user_payment_method_ID, amount, currency, payment_status, provider, provider_reference)
    VALUES (p_order_id, v_pm, p_user_payment_method_id, v_total, 'MXN', 'Pending', v_provider, CONCAT('PAY-', UUID_SHORT()));
    SET p_payment_id = LAST_INSERT_ID();
END$$

/* ------------------------------------------------------------
   11. PASO 8 (sistema): TRANSACCIÓN BANCARIA Y AUTORIZACIÓN
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_authorize_payment(IN p_payment_id INT UNSIGNED)
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

    INSERT INTO tb_payment_transaction (payment_ID, transaction_type, transaction_status, amount, currency, provider,
                                        provider_transaction_id, idempotency_key, response_code, response_message, request_date, response_date)
    VALUES (p_payment_id, 'Authorization', 'Succeeded', v_amount, v_currency, v_provider,
            CONCAT('TXN-', UUID_SHORT()), UUID(), '00', 'Aprobada', NOW(), NOW());

    INSERT INTO tb_payment_transaction (payment_ID, transaction_type, transaction_status, amount, currency, provider,
                                        provider_transaction_id, idempotency_key, response_code, response_message, request_date, response_date)
    VALUES (p_payment_id, 'Capture', 'Succeeded', v_amount, v_currency, v_provider,
            CONCAT('TXN-', UUID_SHORT()), UUID(), '00', 'Cargo aplicado', NOW(), NOW());

    UPDATE tb_payments SET payment_status = 'Paid', paid_date = NOW() WHERE ID = p_payment_id;
    UPDATE tb_orders SET status_string = 'Payed', last_update = NOW() WHERE ID = v_order;

    COMMIT;
END$$

/* ------------------------------------------------------------
   12. PASO 9 (sistema): ORDEN ATENDIDA Y ENVÍO GENERADO
   ------------------------------------------------------------ */
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_process_order(IN p_order_id INT UNSIGNED)
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

    SELECT User_ID, status_string INTO v_user, v_status FROM tb_orders WHERE ID = p_order_id;
    IF v_user IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no existe';
    END IF;
    IF v_status <> 'Payed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no está pagada';
    END IF;

    SELECT ID INTO v_addr FROM tb_user_addresses
    WHERE user_ID = v_user AND status = 1 ORDER BY is_default DESC, ID DESC LIMIT 1;
    IF v_addr IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene domicilio de envío registrado';
    END IF;

    START TRANSACTION;

    INSERT INTO tb_shipments (buyer_order_ID, address_ID, recipient_name, recipient_phone, address_line_1, address_line_2,
                              city, state_region, postal_code, country_code, carrier, service_level, tracking_number,
                              shipment_status, shipped_at, estimated_delivery_at)
    SELECT bo.ID, a.ID, a.recipient_name, a.recipient_phone,
           (SELECT GROUP_CONCAT(c.value ORDER BY c.ID SEPARATOR ' ') FROM tbd_address_components c
             WHERE c.address_ID = a.ID AND c.component_type IN ('street','number')),
           (SELECT MAX(c.value) FROM tbd_address_components c WHERE c.address_ID = a.ID AND c.component_type = 'neighborhood'),
           (SELECT MAX(c.value) FROM tbd_address_components c WHERE c.address_ID = a.ID AND c.component_type = 'city'),
           (SELECT MAX(c.value) FROM tbd_address_components c WHERE c.address_ID = a.ID AND c.component_type = 'state'),
           (SELECT MAX(c.value) FROM tbd_address_components c WHERE c.address_ID = a.ID AND c.component_type = 'postal_code'),
           'MX', 'SimExpress', 'Estándar', CONCAT('SIM', UUID_SHORT()),
           'InTransit', NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY)
    FROM tbd_buyer_orders bo JOIN tb_user_addresses a ON a.ID = v_addr
    WHERE bo.order_ID = p_order_id;

    UPDATE tbd_buyer_orders SET fulfillment_status = 'Sent' WHERE order_ID = p_order_id;
    UPDATE tb_orders SET status_string = 'Attended', last_update = NOW() WHERE ID = p_order_id;

    COMMIT;
END$$

/* ------------------------------------------------------------
   13. PASO 10 (sistema): ENTREGA EN DOMICILIO
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
    IF v_status <> 'Attended' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La orden no ha sido atendida';
    END IF;

    START TRANSACTION;

    UPDATE tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID
    SET s.shipment_status = 'Delivered', s.delivered_at = NOW()
    WHERE bo.order_ID = p_order_id;
    UPDATE tbd_buyer_orders SET fulfillment_status = 'Delivered' WHERE order_ID = p_order_id;
    UPDATE tb_orders SET status_string = 'Delivered', last_update = NOW() WHERE ID = p_order_id;

    COMMIT;
END$$

DELIMITER ;
