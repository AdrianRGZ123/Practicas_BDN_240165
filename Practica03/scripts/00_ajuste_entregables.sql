/* ============================================================
   PRÁCTICA 03 · Ajuste de la base db_test a los entregables
   Resultado: 25 tablas (24 operativas + tb_logs), 72 triggers AFTER,
              25 vistas (24 de trazabilidad + productos por categoría).
   Orden de ejecución: 00 → 01 → 02 → 03 → 05 (04 son las pruebas de simulación).
   HAGA UN RESPALDO ANTES DE EJECUTAR. Usar con una cuenta superadmin.
   ============================================================ */
USE db_test;

/* ---------- 1. TABLAS: de 27 a 25 ---------- */
-- 1.1 tb_payment_methods duplicaba a tbc_payment_methods_types (mismos IDs 1-4: débito, crédito,
--     transferencia, efectivo). tb_payments pasa a apuntar al catálogo.
ALTER TABLE tb_payments DROP FOREIGN KEY fk_payment_method;
ALTER TABLE tb_payments
    ADD CONSTRAINT fk_payment_method FOREIGN KEY (payment_method_ID)
    REFERENCES tbc_payment_methods_types (ID);
DROP TABLE IF EXISTS tb_payment_methods;      -- elimina también sus 3 triggers

-- 1.2 tb_seller_orders quedó huérfana (ninguna FK la referencia; la sustituye tbd_buyer_orders)
DROP TABLE IF EXISTS tb_seller_orders;        -- elimina también sus 3 triggers

/* ---------- 2. TRIGGERS: de 85 a 72 (3 AFTER por cada una de las 24 tablas operativas) ---------- */
-- 2.1 Duplicados: se conservan trg_users_* y trg_products_after_insert/update (bitácora más detallada)
DROP TRIGGER IF EXISTS trg_tb_users_after_insert;
DROP TRIGGER IF EXISTS trg_tb_users_after_update;
DROP TRIGGER IF EXISTS trg_tb_users_after_delete;
DROP TRIGGER IF EXISTS trg_tb_products_after_insert;
DROP TRIGGER IF EXISTS trg_tb_products_after_update;
-- 2.2 Triggers BEFORE (los pedidos son solo AFTER INSERT / UPDATE / DELETE)
DROP TRIGGER IF EXISTS trg_products_before_delete;
DROP TRIGGER IF EXISTS trg_tbd_cart_items_before_insert;
-- La validación de carrito activo / existencias que hacía este trigger debe quedar en
-- sp_create_order_from_cart o en la capa de aplicación.

/* ---------- 3. VISTAS: de 29 a 25 ---------- */
DROP VIEW IF EXISTS vw_trazabilidad_seller_orders;
DROP VIEW IF EXISTS vw_trazabilidad_payment_methods;
DROP VIEW IF EXISTS vw_total_products_by_category1;   -- duplicada de vw_total_products_by_category
DROP VIEW IF EXISTS vw_available_products;            -- ya no la usa ningún trigger tras el punto 2.2

/* ---------- 4. RUTINA que consultaba la tabla eliminada ---------- */
DROP PROCEDURE IF EXISTS sp_register_payment;
DELIMITER ;;
CREATE PROCEDURE sp_register_payment(IN p_order_id INT UNSIGNED, IN p_user_payment_method_id BIGINT UNSIGNED, OUT p_payment_id INT UNSIGNED)
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

    SELECT ID INTO v_pm FROM tbc_payment_methods_types WHERE code = v_type;

    INSERT INTO tb_payments (order_ID, payment_method_ID, user_payment_method_ID, amount, currency, payment_status, provider, provider_reference)
    VALUES (p_order_id, v_pm, p_user_payment_method_id, v_total, 'MXN', 'Pending', v_provider, CONCAT('PAY-', UUID_SHORT()));
    SET p_payment_id = LAST_INSERT_ID();
END ;;
DELIMITER ;

/* ---------- 5. COMPROBACIÓN (esperado: 25 / 72 / 25) ---------- */
SELECT (SELECT COUNT(*) FROM information_schema.TABLES   WHERE TABLE_SCHEMA = 'db_test' AND TABLE_TYPE = 'BASE TABLE') AS tablas,
       (SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = 'db_test') AS triggers,
       (SELECT COUNT(*) FROM information_schema.VIEWS    WHERE TABLE_SCHEMA = 'db_test') AS vistas;
