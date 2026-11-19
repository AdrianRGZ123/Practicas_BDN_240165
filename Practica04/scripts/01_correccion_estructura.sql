/* ============================================================
   PRÁCTICA 04 - 01. CORRECCIÓN DE ESTRUCTURA DE db_test
   Se aplica sobre "Respaldo 28-10-26.sql" ya restaurado.
   Ejecutar como: adrian.rios (superadmin)
   Orden: 01_correccion_estructura -> 02_direcciones_jerarquicas ->
          03_procedimientos_compra -> remote_users_privileges_creation
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;

/* ------------------------------------------------------------
   1. CARRITO: un usuario puede tener varios carritos a lo largo
      del tiempo, pero solo uno activo (status = 1).
   ------------------------------------------------------------ */
ALTER TABLE tb_carts
  ADD KEY idx_cart_user (user_ID),
  ADD COLUMN active_user_ID INT GENERATED ALWAYS AS (IF(status = b'1', user_ID, NULL)) STORED AFTER status,
  ADD UNIQUE KEY uk_cart_active_user (active_user_ID),
  DROP INDEX uk_cart_user;

/* ------------------------------------------------------------
   2. FK COMPUESTA de los ítems del carrito hacia el par
      (proveedor, producto) de tbd_products_users_providers.
   ------------------------------------------------------------ */
ALTER TABLE tbd_cart_items
  DROP FOREIGN KEY tbd_cart_items_ibfk_2,
  DROP FOREIGN KEY tbd_cart_items_ibfk_3,
  ADD KEY idx_cart_items_provider_product (provider_ID, product_ID),
  ADD CONSTRAINT fk_cart_items_provider_product FOREIGN KEY (provider_ID, product_ID)
      REFERENCES tbd_products_users_providers (user_ID, product_ID);

/* ------------------------------------------------------------
   3. CARRITO -> ORDEN DE COMPRA
      tb_orders.cart_ID liga la orden con el carrito que la originó
      (relación 1 a 1: un carrito genera como máximo una orden).
      tb_orders.shipping_address_ID liga la orden con el domicilio
      de envío elegido por el comprador.
      Jerarquía: tb_orders -> tbd_buyer_orders (una por vendedor)
                 -> tbd_order_items (productos).
      tb_seller_orders queda sin uso (0 registros) y se conserva.
   ------------------------------------------------------------ */
ALTER TABLE tb_orders
  MODIFY total_cost DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  ADD COLUMN cart_ID INT UNSIGNED DEFAULT NULL AFTER User_ID,
  ADD COLUMN shipping_address_ID BIGINT UNSIGNED DEFAULT NULL AFTER cart_ID,
  ADD UNIQUE KEY uk_orders_key (`key`),
  ADD UNIQUE KEY uk_orders_cart (cart_ID),
  ADD KEY idx_orders_address (shipping_address_ID),
  ADD CONSTRAINT fk_orders_cart FOREIGN KEY (cart_ID) REFERENCES tb_carts (ID),
  ADD CONSTRAINT fk_orders_address FOREIGN KEY (shipping_address_ID) REFERENCES tb_user_addresses (ID);

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
  ADD COLUMN canceled_quantity INT UNSIGNED NOT NULL DEFAULT 0 AFTER quantity,
  ADD KEY idx_order_items_provider_product (provider_ID, product_ID),
  ADD CONSTRAINT fk_order_items_buyer_order FOREIGN KEY (buyer_order_ID) REFERENCES tbd_buyer_orders (ID),
  ADD CONSTRAINT fk_order_items_provider_product FOREIGN KEY (provider_ID, product_ID)
      REFERENCES tbd_products_users_providers (user_ID, product_ID),
  ADD CONSTRAINT chk_order_items_canceled CHECK (canceled_quantity <= quantity);

/* ------------------------------------------------------------
   4. CATÁLOGOS DE PAGO Y CUPONES DE REGALO
   ------------------------------------------------------------ */
INSERT INTO tbc_payment_methods_types (code, description) VALUES
  ('DEBIT_CARD',   'Tarjeta de débito'),
  ('CREDIT_CARD',  'Tarjeta de crédito'),
  ('DIGITAL_CARD', 'Tarjeta digital (Spin)'),
  ('SPEI',         'Transferencia electrónica SPEI'),
  ('CASH',         'Efectivo'),
  ('GIFT_COUPON',  'Cupón de regalo');

ALTER TABLE tb_payment_methods
  ADD COLUMN type_ID INT UNSIGNED DEFAULT NULL AFTER name,
  ADD CONSTRAINT fk_payment_methods_type FOREIGN KEY (type_ID) REFERENCES tbc_payment_methods_types (ID);

INSERT INTO tb_payment_methods (name, description, type_ID)
SELECT n.name, n.description, t.ID
FROM (SELECT 'Tarjeta de débito' AS name, 'Pago con tarjeta de débito' AS description, 'DEBIT_CARD' AS code
      UNION ALL SELECT 'Tarjeta de crédito', 'Pago con tarjeta de crédito, admite mensualidades', 'CREDIT_CARD'
      UNION ALL SELECT 'Tarjeta digital Spin', 'Pago con tarjeta digital Spin', 'DIGITAL_CARD'
      UNION ALL SELECT 'Transferencia SPEI', 'Pago por transferencia electrónica SPEI', 'SPEI'
      UNION ALL SELECT 'Efectivo', 'Pago en efectivo', 'CASH'
      UNION ALL SELECT 'Cupón de regalo', 'Pago con saldo de cupón de regalo', 'GIFT_COUPON') n
JOIN tbc_payment_methods_types t ON t.code = n.code;

CREATE TABLE tb_gift_coupons (
  ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(30) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  coupon_status ENUM('Available','Used','Expired') NOT NULL DEFAULT 'Available',
  user_ID INT DEFAULT NULL COMMENT 'Usuario al que pertenece el cupón',
  order_ID INT UNSIGNED DEFAULT NULL COMMENT 'Orden en la que está aplicado (NULL si está disponible)',
  times_reassigned INT UNSIGNED NOT NULL DEFAULT 0,
  used_at DATETIME DEFAULT NULL,
  creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_update DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  UNIQUE KEY uk_coupon_code (code),
  KEY idx_coupon_user (user_ID),
  KEY idx_coupon_order (order_ID),
  CONSTRAINT fk_coupon_user FOREIGN KEY (user_ID) REFERENCES tb_users (ID),
  CONSTRAINT fk_coupon_order FOREIGN KEY (order_ID) REFERENCES tb_orders (ID),
  CONSTRAINT chk_coupon_amount CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/* ------------------------------------------------------------
   5. PAGOS: ligar el pago con el método registrado por el usuario
      (tbd_user_payment_methods) y soportar pagos en mensualidades.
   ------------------------------------------------------------ */
ALTER TABLE tb_payments
  ADD COLUMN user_payment_method_ID BIGINT UNSIGNED DEFAULT NULL AFTER payment_method_ID,
  ADD COLUMN installment_number TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER currency,
  ADD COLUMN installments_total TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER installment_number,
  ADD COLUMN due_date DATE DEFAULT NULL AFTER installments_total,
  ADD KEY idx_payment_user_method (user_payment_method_ID),
  ADD UNIQUE KEY uk_payment_order_installment (order_ID, installment_number),
  ADD CONSTRAINT fk_payment_user_method FOREIGN KEY (user_payment_method_ID)
      REFERENCES tbd_user_payment_methods (ID),
  ADD CONSTRAINT chk_payment_installments CHECK (installment_number BETWEEN 1 AND installments_total);

ALTER TABLE tbd_user_payment_methods
  ADD CONSTRAINT chk_user_pm_last_four CHECK (last_four IS NULL OR last_four REGEXP '^[0-9]{4}$');

/* ------------------------------------------------------------
   6. ENVÍOS: punto de recolección y reenvíos por devolución
   ------------------------------------------------------------ */
ALTER TABLE tb_shipments
  MODIFY shipment_status ENUM('Pending','LabelCreated','ReadyToShip','InTransit','OutForDelivery','Delivered',
                              'DeliveryFailed','Lost','Returned','AtPickupPoint','PickedUp') NOT NULL DEFAULT 'Pending',
  ADD COLUMN pickup_point VARCHAR(255) DEFAULT NULL AFTER service_level,
  ADD COLUMN reshipment_of_return_ID INT UNSIGNED DEFAULT NULL AFTER buyer_order_ID,
  ADD KEY idx_shipments_reshipment (reshipment_of_return_ID),
  ADD CONSTRAINT fk_shipments_return FOREIGN KEY (reshipment_of_return_ID) REFERENCES tb_returns (ID);

/* ------------------------------------------------------------
   7. TRIGGER CON ERROR: registraba operation = 'Insert', valor que no
      existe en el ENUM de tb_logs.operation (Create, Read, Update, Delete).
   ------------------------------------------------------------ */
DROP TRIGGER IF EXISTS trg_products_users_providers_after_insert;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` TRIGGER trg_products_users_providers_after_insert
AFTER INSERT ON tbd_products_users_providers FOR EACH ROW
BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES ('tbd_products_users_providers', 'Create', USER(),
            CONCAT('Relación producto-usuario registrada. User_ID=', NEW.user_ID, ', Product_ID=', NEW.product_ID, ', Tipo=', NEW.type_ownership),
            NOW(), 1);
END$$
DELIMITER ;

/* ------------------------------------------------------------
   8. PRODUCTOS DISPONIBLES: tbd_products_users_providers estaba vacía,
      por eso ningún producto podía agregarse al carrito.
      Se asignan los productos activos a 20 usuarios proveedores.
   ------------------------------------------------------------ */
INSERT INTO tbd_products_users_providers (user_ID, product_ID, type_ownership, status, available_date)
SELECT s.ID, p.id, 'Owner', b'1', NOW()
FROM tb_products p
JOIN (SELECT ID, ROW_NUMBER() OVER (ORDER BY ID) - 1 AS n
      FROM (SELECT ID FROM tb_users WHERE status = 1 ORDER BY ID LIMIT 20) u) s
  ON s.n = MOD(p.id, 20)
WHERE p.status = 1;

/* ------------------------------------------------------------
   9. VISTAS
   ------------------------------------------------------------ */
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_available_products AS
SELECT p.id AS product_ID, p.sku, p.name, p.current_price, p.current_stock,
       pup.user_ID AS provider_ID, pup.type_ownership
FROM tb_products p
JOIN tbd_products_users_providers pup ON pup.product_ID = p.id
WHERE p.status = 1 AND pup.status = 1 AND p.current_stock > 0;

/* Del carrito a la orden: una fila por carrito con su orden (si la tiene) */
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_cart_to_order AS
SELECT c.ID AS cart_ID, c.user_ID, IF(c.status = b'1', 'Activo', 'Convertido en orden') AS cart_status,
       (SELECT COUNT(*) FROM tbd_cart_items ci WHERE ci.cart_ID = c.ID) AS cart_lines,
       (SELECT COALESCE(SUM(ci.quantity), 0) FROM tbd_cart_items ci WHERE ci.cart_ID = c.ID) AS cart_units,
       o.ID AS order_ID, o.`key` AS order_key, o.status_string AS order_status,
       o.total_products, o.total_cost, o.shipping_address_ID, o.creation_date AS order_date
FROM tb_carts c
LEFT JOIN tb_orders o ON o.cart_ID = c.ID;

/* Domicilios con su jerarquía vertical aplanada en columnas */
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_user_addresses_full AS
SELECT a.ID AS address_ID, a.user_ID, a.address_label, a.recipient_name, a.recipient_phone, a.is_default,
       MAX(IF(c.component_type = 'País', c.value, NULL))           AS country,
       MAX(IF(c.component_type = 'Estado', c.value, NULL))         AS state,
       MAX(IF(c.component_type = 'Municipio', c.value, NULL))      AS municipality,
       MAX(IF(c.component_type = 'Ciudad', c.value, NULL))         AS city,
       MAX(IF(c.component_type = 'Localidad', c.value, NULL))      AS locality,
       MAX(IF(c.component_type = 'Código Postal', c.value, NULL))  AS postal_code,
       MAX(IF(c.component_type = 'Colonia', c.value, NULL))        AS neighborhood,
       MAX(IF(c.component_type = 'Calle/Avenida', c.value, NULL))  AS street,
       MAX(IF(c.component_type = 'Número Exterior', c.value, NULL)) AS ext_number,
       MAX(IF(c.component_type = 'Número Interior', c.value, NULL)) AS int_number
FROM tb_user_addresses a
LEFT JOIN tbd_address_components c ON c.address_ID = a.ID AND c.status = b'1'
WHERE a.status = b'1'
GROUP BY a.ID, a.user_ID, a.address_label, a.recipient_name, a.recipient_phone, a.is_default;

/* Trazabilidad compra completa: orden -> vendedor -> producto */
CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_order_detail AS
SELECT o.ID AS order_ID, o.`key` AS order_key, o.User_ID AS buyer_ID, o.cart_ID, o.status_string AS order_status,
       bo.ID AS buyer_order_ID, bo.seller_ID, bo.fulfillment_status,
       oi.ID AS order_item_ID, oi.product_ID, oi.product_name, oi.quantity, oi.canceled_quantity,
       oi.unit_price, (oi.quantity - oi.canceled_quantity) * oi.unit_price AS active_subtotal
FROM tb_orders o
JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID
JOIN tbd_order_items oi ON oi.buyer_order_ID = bo.ID;

DELIMITER $$

/* ------------------------------------------------------------
   10. VALIDACIONES DEL CARRITO
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

CREATE DEFINER=`root`@`localhost` TRIGGER trg_tbd_cart_items_before_update
BEFORE UPDATE ON tbd_cart_items FOR EACH ROW
BEGIN
    IF (SELECT status FROM tb_carts WHERE ID = NEW.cart_ID) <> b'1' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El carrito ya fue convertido en orden y no se puede modificar';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` TRIGGER trg_tbd_cart_items_before_delete
BEFORE DELETE ON tbd_cart_items FOR EACH ROW
BEGIN
    IF (SELECT status FROM tb_carts WHERE ID = OLD.cart_ID) <> b'1' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El carrito ya fue convertido en orden y no se puede modificar';
    END IF;
END$$

DELIMITER ;
