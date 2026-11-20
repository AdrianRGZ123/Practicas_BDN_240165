/* ============================================================
   PRÁCTICA 04 - CASO DE PRUEBA 5 (script consolidado)
   Las partes se ejecutan EN ORDEN; cada una con el usuario de conexión indicado
   (una sesión por parte, porque cambia el usuario de la base de datos).
   Cada paso se marca con sp_trace_step para la trazabilidad (vw_practica04_caso_5).
   ============================================================ */


/* ################ PARTE 1 de 3 -- CONECTAR COMO: adrian.rios ################ */
/* ============================================================
   CASO DE PRUEBA 5: "Compra fallida por falta de inventario"
   PARTE 0 (preparación) - Conexión: adrian.rios (superadmin)
   El sistema asigna al usuario ID 9000 (John Pérez) un cupón de regalo.
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
CALL sp_trace_step(5, 0, 'PREPARACIÓN: el sistema asigna un cupón de regalo al usuario', CURRENT_ROLE());

INSERT INTO tb_gift_coupons (code, amount, user_ID) VALUES ('REGALO-JP-2026-5000', 5000.00, 9000);
SELECT ID, code, amount, coupon_status, user_ID, order_ID, times_reassigned FROM tb_gift_coupons WHERE code = 'REGALO-JP-2026-5000';


/* ################ PARTE 2 de 3 -- CONECTAR COMO: app_web ################ */
/* ============================================================
   CASO DE PRUEBA 5 - PARTE 1 (pasos 1 a 4) - Conexión: app_web
   Usuario ya registrado: ID 9000 (John Pérez)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 9000;

/* PASO 1. Carrito con 1 producto (de 1 a 5 unidades) de un proveedor; quedan pocas existencias */
CALL sp_trace_step(5, 1, 'PASO 1. Carrito con 1 producto (de 1 a 5 unidades) de un proveedor; quedan pocas existencias', CURRENT_ROLE());
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, x.provider_ID, x.product_ID, 4
FROM (SELECT provider_ID, product_ID FROM vw_available_products
      WHERE current_stock BETWEEN 4 AND 8 AND current_price <= 900 ORDER BY product_ID LIMIT 1 OFFSET 40) x;
SELECT ci.provider_ID, ci.product_ID, p.name, ci.quantity, p.current_price, p.current_stock AS existencias, ci.quantity * p.current_price AS importe
FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart;

/* PASO 2. Realiza la orden de compra */
CALL sp_trace_step(5, 2, 'PASO 2. Realiza la orden de compra', CURRENT_ROLE());
CALL sp_create_order_from_cart(@uid, @order);
SELECT * FROM vw_cart_to_order WHERE cart_ID = @cart;

/* PASO 3. Domicilio de envío (no es su hogar) */
CALL sp_trace_step(5, 3, 'PASO 3. Domicilio de envío (no es su hogar)', CURRENT_ROLE());
CALL sp_register_address(@uid, 'Casa de Verano', 'John Pérez', '+52 9981234500', 'Llamar al llegar', 0,
     'Quintana Roo', 'Benito Juárez', 'Cancún', 'Supermanzana 22', '77500', 'Centro', 'Av. Tulum', '215', '2', @addr);
CALL sp_set_order_address(@order, @addr);
SELECT * FROM vw_user_addresses_full WHERE address_ID = @addr;

/* PASO 4. Método de pago: cupón de regalo (el cupón se vincula al usuario y se aplica a la orden) */
SET ROLE 'buyer';
CALL sp_trace_step(5, 4, 'PASO 4. Método de pago: cupón de regalo (el cupón se vincula al usuario y se aplica a la orden)', CURRENT_ROLE());
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'GiftCoupon', 'REGALO-JP-2026-5000', 'Cupón de regalo', NULL, 0
FROM tbc_payment_methods_types WHERE code = 'GIFT_COUPON';
SET @upm = LAST_INSERT_ID();
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, 1, NULL, @pay);
SELECT p.ID, p.order_ID, p.amount, pm.name AS forma_de_pago, p.payment_status FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID WHERE p.ID = @pay;
SELECT ID, code, amount, coupon_status, user_ID, order_ID, times_reassigned FROM tb_gift_coupons WHERE code = 'REGALO-JP-2026-5000';
SELECT ID, status_string, total_cost FROM tb_orders WHERE ID = @order;


/* ################ PARTE 3 de 3 -- CONECTAR COMO: adrian.rios ################ */
/* ============================================================
   CASO DE PRUEBA 5 - PARTE 2 (pasos 5 y 6) - Conexión: adrian.rios (superadmin)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 9000;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);
SET @prod = (SELECT oi.product_ID FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID WHERE bo.order_ID = @order LIMIT 1);

/* PASO 5. El sistema intenta procesar la orden: no alcanza el inventario, queda como NO atendida */
CALL sp_trace_step(5, 5, 'PASO 5. El sistema intenta procesar la orden: no alcanza el inventario, queda como NO atendida', CURRENT_ROLE());
/* Antes de que se atienda la orden, otros compradores agotan las existencias del producto */
SELECT id AS product_ID, name, current_stock AS existencias_antes FROM tb_products WHERE id = @prod;
UPDATE tb_products SET current_stock = 0 WHERE id = @prod;
SELECT id AS product_ID, current_stock AS existencias_ahora FROM tb_products WHERE id = @prod;

CALL sp_process_order(@order);
SELECT ID, status_string, total_cost FROM tb_orders WHERE ID = @order;
SELECT ID, cancellation_scope, reason_code, reason_detail, cancellation_status FROM tb_order_cancellations WHERE order_ID = @order;

/* PASO 6. La orden queda cancelada, se reembolsa el pago y se reasigna el cupón utilizado */
CALL sp_trace_step(5, 6, 'PASO 6. La orden queda cancelada, se reembolsa el pago y se reasigna el cupón utilizado', CURRENT_ROLE());
SELECT p.ID AS payment_ID, p.amount, p.payment_status, t.transaction_type, t.transaction_status, t.amount AS monto_transaccion
FROM tb_payments p JOIN tb_payment_transaction t ON t.payment_ID = p.ID WHERE p.order_ID = @order ORDER BY t.ID;
SELECT ID, code, amount, coupon_status, user_ID, order_ID, times_reassigned FROM tb_gift_coupons WHERE code = 'REGALO-JP-2026-5000';
SELECT order_ID, buyer_order_ID, fulfillment_status, product_name, quantity, canceled_quantity FROM vw_order_detail WHERE order_ID = @order;


/* Fin del caso (marca de cierre para las vistas de trazabilidad) */
CALL sp_trace_step(5, 99, 'FIN DEL CASO 5', CURRENT_ROLE());
