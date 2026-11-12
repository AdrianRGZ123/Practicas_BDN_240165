/* ============================================================
   CASO DE PRUEBA 3 - PARTE 4 (pasos 8 a 11) - Conexión: adrian.rios (superadmin)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 5100;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);
SET @cancel = (SELECT MAX(ID) FROM tb_order_cancellations WHERE requested_by_user_ID = @uid);
SELECT ID, total_products, total_cost AS total_antes_del_ajuste FROM tb_orders WHERE ID = @order;

/* PASO 8. El sistema actualiza la orden de compra (ítems, subtotal, totales e inventario) */
CALL sp_apply_cancellation(@cancel);
SELECT ID, total_products, total_cost AS total_despues_del_ajuste, status_string FROM tb_orders WHERE ID = @order;
SELECT order_item_ID, product_name, quantity, canceled_quantity, active_subtotal FROM vw_order_detail WHERE order_ID = @order ORDER BY order_item_ID;

/* PASO 9. El sistema reembolsa el monto de los productos cancelados */
CALL sp_refund_cancellation(@cancel);
SELECT r.ID AS refund_ID, r.payment_ID, r.reason, r.amount, r.refund_status, r.processed_at FROM tb_refunds r JOIN tb_payments p ON p.ID = r.payment_ID WHERE p.order_ID = @order;
SELECT p.ID, p.amount AS monto_cobrado, p.payment_status, t.transaction_type, t.transaction_status, t.amount AS monto_transaccion
FROM tb_payments p JOIN tb_payment_transaction t ON t.payment_ID = p.ID WHERE p.order_ID = @order ORDER BY t.ID;
SELECT ID, cancellation_status, completed_at FROM tb_order_cancellations WHERE ID = @cancel;

/* PASO 10. El sistema realiza el envío */
CALL sp_ship_order(@order);
SELECT s.ID, s.shipment_status, s.tracking_number, s.recipient_name, s.address_line_1, s.address_line_2, s.city, s.state_region, s.postal_code
FROM tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID WHERE bo.order_ID = @order;

/* PASO 11. El cliente recibe el pedido en "Casa Papas" */
CALL sp_deliver_order(@order);
SELECT o.ID AS order_ID, o.status_string, o.total_products, o.total_cost, s.shipment_status, s.delivered_at
FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID JOIN tb_shipments s ON s.buyer_order_ID = bo.ID WHERE o.ID = @order;
