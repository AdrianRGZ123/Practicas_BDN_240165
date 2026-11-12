/* ============================================================
   CASO DE PRUEBA 1: "Compra exitosa, sin modificaciones"
   PARTE 1 (pasos 1 a 8) - Conexión: app_web
   Rol activo al conectar: user_not_registered  (en el paso 8 se activa buyer)
   Ejecutar: mysql -u app_web -p -h <host> -P <puerto> < caso1_01_app_web.sql
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

/* PASO 1. Un usuario nuevo se registra con sus datos personales y de cuenta */
INSERT INTO tb_users (email, nickname, password)
VALUES ('valeria.montes@correo-demo.mx', 'valeria_montes', SHA2('Vale#Montes2026', 256));
SET @uid = LAST_INSERT_ID();
INSERT INTO tb_people (user_ID, courtesy_title, given_names, family_names, birth_date, gender_ID, country_code, phone)
VALUES (@uid, 'Srita.', 'Valeria', 'Montes Cabrera', '2001-08-23', 2, 'MX', '+52 7641012233');
SELECT @uid AS user_ID_registrado;

/* PASO 2. Selección de 5 productos del catálogo disponible (~15 mil) verificando su estatus */
SELECT COUNT(*) AS productos_disponibles FROM vw_available_products;
SELECT v.product_ID, v.sku, v.name, v.current_price, v.current_stock, v.provider_ID,
       IF(p.status = 1, 'Activo', 'Inactivo') AS estatus_producto
FROM vw_available_products v JOIN tb_products p ON p.id = v.product_ID
WHERE v.current_stock >= 6
ORDER BY MD5(CONCAT('caso1-', v.product_ID))
LIMIT 5;

/* PASO 3. El usuario crea 1 carrito de compra */
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();
SELECT @cart AS cart_ID;

/* PASO 4. Agrega los 5 productos con cantidades diferentes (2, 3, 1, 4 y 5) */
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, x.provider_ID, x.product_ID, ELT(x.rn, 2, 3, 1, 4, 5)
FROM (SELECT v.provider_ID, v.product_ID, ROW_NUMBER() OVER (ORDER BY MD5(CONCAT('caso1-', v.product_ID))) AS rn
      FROM vw_available_products v WHERE v.current_stock >= 6
      ORDER BY MD5(CONCAT('caso1-', v.product_ID)) LIMIT 5) x;
SELECT ci.product_ID, p.name, ci.quantity, p.current_price, ci.quantity * p.current_price AS importe
FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart;

/* PASO 5. El usuario realiza la orden de compra (el carrito se convierte en orden) */
CALL sp_create_order_from_cart(@uid, @order);
SELECT * FROM vw_cart_to_order WHERE cart_ID = @cart;
SELECT * FROM vw_order_detail WHERE order_ID = @order;

/* PASO 6. Registra su domicilio de envío (dirección jerárquica: país > estado > ... > número) */
CALL sp_register_address(@uid, 'Casa', 'Valeria Montes Cabrera', '+52 7641012233', 'Tocar el timbre del portón azul', 1,
     'Puebla', 'Xicotepec', 'Xicotepec de Juárez', 'Villa Ávila Camacho', '73080', 'La Ribera', '21 de Marzo', '114', 'B', @addr);
CALL sp_set_order_address(@order, @addr);
SELECT address_ID, component_type, value, address_sup_ID FROM tbd_address_components WHERE address_ID = @addr ORDER BY ID;
SELECT * FROM vw_user_addresses_full WHERE address_ID = @addr;

/* PASO 7. Registra su método de pago: tarjeta de débito (cuenta simulada de 16 dígitos) */
SET @card = '5204883177204419';
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'BancoSim', @card, 'Débito Valeria', RIGHT(@card, 4), 1
FROM tbc_payment_methods_types WHERE code = 'DEBIT_CARD';
SET @upm = LAST_INSERT_ID();
SELECT m.ID, t.code AS tipo, m.provider, m.provider_method_ref AS cuenta_16_digitos, m.last_four
FROM tbd_user_payment_methods m JOIN tbc_payment_methods_types t ON t.ID = m.payment_method_type_ID WHERE m.ID = @upm;

/* PASO 8. Registra un pago único: al pagar, la conexión activa el rol buyer */
SET ROLE 'buyer';
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, 1, NULL, @pay);
SELECT ID, order_ID, amount, currency, installment_number, installments_total, payment_status FROM tb_payments WHERE ID = @pay;
