/* ============================================================
   CASO DE PRUEBA 5 - PARTE 1 (pasos 1 a 4) - Conexión: app_web
   Usuario ya registrado: ID 9000 (John Pérez)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 9000;

/* PASO 1. Carrito con 1 producto (de 1 a 5 unidades) de un proveedor; quedan pocas existencias */
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, x.provider_ID, x.product_ID, 4
FROM (SELECT provider_ID, product_ID FROM vw_available_products
      WHERE current_stock BETWEEN 4 AND 8 AND current_price <= 900 ORDER BY product_ID LIMIT 1 OFFSET 40) x;
SELECT ci.provider_ID, ci.product_ID, p.name, ci.quantity, p.current_price, p.current_stock AS existencias, ci.quantity * p.current_price AS importe
FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart;

/* PASO 2. Realiza la orden de compra */
CALL sp_create_order_from_cart(@uid, @order);
SELECT * FROM vw_cart_to_order WHERE cart_ID = @cart;

/* PASO 3. Domicilio de envío (no es su hogar) */
CALL sp_register_address(@uid, 'Casa de Verano', 'John Pérez', '+52 9981234500', 'Llamar al llegar', 0,
     'Quintana Roo', 'Benito Juárez', 'Cancún', 'Supermanzana 22', '77500', 'Centro', 'Av. Tulum', '215', '2', @addr);
CALL sp_set_order_address(@order, @addr);
SELECT * FROM vw_user_addresses_full WHERE address_ID = @addr;

/* PASO 4. Método de pago: cupón de regalo (el cupón se vincula al usuario y se aplica a la orden) */
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'GiftCoupon', 'REGALO-JP-2026-5000', 'Cupón de regalo', NULL, 0
FROM tbc_payment_methods_types WHERE code = 'GIFT_COUPON';
SET @upm = LAST_INSERT_ID();
SET ROLE 'buyer';
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, 1, NULL, @pay);
SELECT p.ID, p.order_ID, p.amount, pm.name AS forma_de_pago, p.payment_status FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID WHERE p.ID = @pay;
SELECT ID, code, amount, coupon_status, user_ID, order_ID, times_reassigned FROM tb_gift_coupons WHERE code = 'REGALO-JP-2026-5000';
SELECT ID, status_string, total_cost FROM tb_orders WHERE ID = @order;
