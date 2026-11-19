/* ============================================================
   CASO DE PRUEBA 4: "Compra exitosa del mismo proveedor con entrega en punto de recolección"
   PARTE 1 (pasos 1 a 5) - Conexión: app_web  (rol user_not_registered; buyer al pagar)
   Usuario ya registrado: ID 7400 (Emily Pérez)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 7400;

/* PASO 1. Carrito con 3 productos del MISMO proveedor, de 1 a 3 unidades cada uno */
SET @prov = (SELECT provider_ID FROM vw_available_products WHERE current_stock >= 3
             GROUP BY provider_ID HAVING COUNT(*) >= 3 ORDER BY provider_ID LIMIT 1 OFFSET 9);
SELECT @prov AS proveedor_elegido;
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, x.provider_ID, x.product_ID, 1 + MOD(x.product_ID, 3)
FROM (SELECT provider_ID, product_ID FROM vw_available_products
      WHERE provider_ID = @prov AND current_stock >= 3 ORDER BY MD5(CONCAT('caso4-', product_ID)) LIMIT 3) x;
SELECT ci.provider_ID, ci.product_ID, p.name, ci.quantity, p.current_price, ci.quantity * p.current_price AS importe
FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart;

/* PASO 2. Realiza la orden de compra */
CALL sp_create_order_from_cart(@uid, @order);
SELECT * FROM vw_cart_to_order WHERE cart_ID = @cart;

/* PASO 3. Domicilio de envío en un lugar que no es su hogar (casa de una amiga) */
CALL sp_register_address(@uid, 'Casa de Daniela', 'Daniela Ortega', '+52 7641876655', 'Si nadie abre, dejar en el punto de recolección', 0,
     'Puebla', 'Huauchinango', 'Huauchinango', 'Huauchinango Centro', '73160', 'Aquiles Serdán', 'Calle Hidalgo', '312', NULL, @addr);
CALL sp_set_order_address(@order, @addr);
SELECT * FROM vw_user_addresses_full WHERE address_ID = @addr;

/* PASO 4. Método de pago: transferencia SPEI (cuenta simulada de 16 dígitos) */
SET @card = '6381270094415530';
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'BancoSim-SPEI', @card, 'SPEI Emily', RIGHT(@card, 4), 0
FROM tbc_payment_methods_types WHERE code = 'SPEI';
SET @upm = LAST_INSERT_ID();
SELECT m.ID, t.code AS tipo, m.provider, m.provider_method_ref AS cuenta_16_digitos FROM tbd_user_payment_methods m
JOIN tbc_payment_methods_types t ON t.ID = m.payment_method_type_ID WHERE m.ID = @upm;

/* PASO 5. Registra un solo pago en efectivo por el costo total (rol buyer) */
SET ROLE 'buyer';
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, 1, 'CASH', @pay);
SELECT p.ID, p.order_ID, p.amount, pm.name AS forma_de_pago, p.payment_status, p.user_payment_method_ID
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID WHERE p.ID = @pay;
