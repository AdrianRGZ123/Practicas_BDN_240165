/* ============================================================
   CASO DE PRUEBA 5 - PARTE 2 (pasos 5 y 6) - Conexión: adrian.rios (superadmin)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 9000;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);
SET @prod = (SELECT oi.product_ID FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID WHERE bo.order_ID = @order LIMIT 1);

/* Antes de que se atienda la orden, otros compradores agotan las existencias del producto */
SELECT id AS product_ID, name, current_stock AS existencias_antes FROM tb_products WHERE id = @prod;
UPDATE tb_products SET current_stock = 0 WHERE id = @prod;
SELECT id AS product_ID, current_stock AS existencias_ahora FROM tb_products WHERE id = @prod;

/* PASO 5. El sistema intenta procesar la orden: no alcanza el inventario, queda como NO atendida */
CALL sp_process_order(@order);
SELECT ID, status_string, total_cost FROM tb_orders WHERE ID = @order;
SELECT ID, cancellation_scope, reason_code, reason_detail, cancellation_status FROM tb_order_cancellations WHERE order_ID = @order;

/* PASO 6. La orden queda cancelada, se reembolsa el pago y se reasigna el cupón utilizado */
SELECT p.ID AS payment_ID, p.amount, p.payment_status, t.transaction_type, t.transaction_status, t.amount AS monto_transaccion
FROM tb_payments p JOIN tb_payment_transaction t ON t.payment_ID = p.ID WHERE p.order_ID = @order ORDER BY t.ID;
SELECT ID, code, amount, coupon_status, user_ID, order_ID, times_reassigned FROM tb_gift_coupons WHERE code = 'REGALO-JP-2026-5000';
SELECT order_ID, buyer_order_ID, fulfillment_status, product_name, quantity, canceled_quantity FROM vw_order_detail WHERE order_ID = @order;
