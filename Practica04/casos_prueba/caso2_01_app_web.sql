/* ============================================================
   CASO DE PRUEBA 2: "Compra con detalles en el último pago, reclamación y reenvío"
   PARTE 1 (pasos 1 a 5) - Conexión: app_web  (rol user_not_registered; buyer al pagar)
   Usuario ya registrado: ID 1500 (Carlos López)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 1500;

/* PASO 1. Crea 1 carrito con 10 productos aleatorios, cantidades de 1 a 5 unidades */
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, x.provider_ID, x.product_ID, 1 + MOD(x.product_ID, 5)
FROM (SELECT provider_ID, product_ID FROM vw_available_products
      WHERE current_stock >= 5 ORDER BY MD5(CONCAT('caso2-', product_ID)) LIMIT 10) x;
SELECT ci.provider_ID, ci.product_ID, p.name, ci.quantity, p.current_price, ci.quantity * p.current_price AS importe
FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart ORDER BY ci.provider_ID, ci.product_ID;

/* PASO 2. Realiza la orden de compra */
CALL sp_create_order_from_cart(@uid, @order);
SELECT * FROM vw_cart_to_order WHERE cart_ID = @cart;
SELECT buyer_order_ID, seller_ID, COUNT(*) AS productos, SUM(active_subtotal) AS subtotal_vendedor
FROM vw_order_detail WHERE order_ID = @order GROUP BY buyer_order_ID, seller_ID;

/* PASO 3. Registra su domicilio de envío en un lugar que no es su hogar (trabajo) */
CALL sp_register_address(@uid, 'Trabajo', 'Carlos López (Recepción)', '+52 5557001122', 'Entregar en recepción, horario de 9 a 18 h', 0,
     'Ciudad de México', 'Cuauhtémoc', 'Ciudad de México', 'Juárez', '06600', 'Juárez', 'Calle Londres', '247', '3B', @addr);
CALL sp_set_order_address(@order, @addr);
SELECT * FROM vw_user_addresses_full WHERE address_ID = @addr;

/* PASO 4. Registra su método de pago: tarjeta de crédito (cuenta simulada de 16 dígitos) */
SET @card = '4916338506082832';
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'BancoSim', @card, 'Crédito Carlos', RIGHT(@card, 4), 0
FROM tbc_payment_methods_types WHERE code = 'CREDIT_CARD';
SET @upm = LAST_INSERT_ID();
SELECT m.ID, t.code AS tipo, m.provider, m.provider_method_ref AS cuenta_16_digitos FROM tbd_user_payment_methods m
JOIN tbc_payment_methods_types t ON t.ID = m.payment_method_type_ID WHERE m.ID = @upm;

/* PASO 5. Registra 6 pagos mensuales (al pagar se activa el rol buyer) */
SET ROLE 'buyer';
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, 6, NULL, @pay);
SELECT ID, installment_number, installments_total, due_date, amount, payment_status FROM tb_payments WHERE order_ID = @order ORDER BY installment_number;
