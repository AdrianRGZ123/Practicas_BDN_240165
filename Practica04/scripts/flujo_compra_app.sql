/* ============================================================
   FLUJO DE COMPRA - PARTE 1 (pasos 1 a 7)
   Conexión: app_web  (o app_movil)
   Rol activo al conectar: user_not_registered
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

/* Registro del usuario nuevo: cuenta y datos personales */
SET @sfx = DATE_FORMAT(NOW(), '%m%d%H%i%s');
INSERT INTO tb_users (email, nickname, password)
VALUES (CONCAT('cliente.demo', @sfx, '@example.com'), CONCAT('cliente_demo_', @sfx), MD5('Demo#2026'));
SET @uid = LAST_INSERT_ID();
INSERT INTO tb_people (user_ID, courtesy_title, given_names, family_names, birth_date, gender_ID, country_code, phone)
VALUES (@uid, 'Sr.', 'Carlos', 'Mendoza Ruiz', '1998-04-12', 1, 'MX', '+52 5512345678');

/* 1. Selección de 5 productos disponibles (producto y proveedor activos, con existencias) */
SELECT product_ID, sku, name, current_price, current_stock, provider_ID
FROM vw_available_products
WHERE current_stock >= 6
ORDER BY product_ID
LIMIT 5;

/* 2. El usuario crea 1 carrito de compra */
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();

/* 3. Agrega los 5 productos con cantidades diferentes (2, 3, 4, 5 y 6) */
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, provider_ID, product_ID, ROW_NUMBER() OVER (ORDER BY product_ID) + 1
FROM (SELECT product_ID, provider_ID FROM vw_available_products WHERE current_stock >= 6 ORDER BY product_ID LIMIT 5) x;
SELECT ci.product_ID, p.name, ci.quantity, p.current_price FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart;

/* 4. Orden de compra */
CALL sp_create_order_from_cart(@uid, @order);
SELECT @order AS order_ID;
SELECT ID, `key`, total_products, total_cost, status_string FROM tb_orders WHERE ID = @order;

/* 5. Domicilio de envío */
INSERT INTO tb_user_addresses (user_ID, address_label, recipient_name, recipient_phone, delivery_instructions, is_default)
VALUES (@uid, 'Casa', 'Carlos Mendoza Ruiz', '+52 5512345678', 'Entregar con el portero', 1);
SET @addr = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, component_type, value) VALUES
  (@addr, 'street', 'Av. Reforma'), (@addr, 'number', '123'), (@addr, 'neighborhood', 'Centro'),
  (@addr, 'city', 'Ciudad de México'), (@addr, 'state', 'CDMX'), (@addr, 'postal_code', '06000'), (@addr, 'country', 'México');

/* 6. Método de pago: tarjeta de débito con cuenta simulada de 16 dígitos */
SET @card = CONCAT('4', LPAD(FLOOR(RAND() * 1000000000000000), 15, '0'));
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'SimBank', @card, 'Débito demo', RIGHT(@card, 4), 1
FROM tbc_payment_methods_types WHERE code = 'DEBIT_CARD';
SET @upm = LAST_INSERT_ID();

/* 7. Pago único: al pagar se activa el rol buyer */
SET ROLE 'buyer';
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, @pay);
SELECT ID, order_ID, amount, currency, payment_status FROM tb_payments WHERE ID = @pay;
