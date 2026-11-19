/* ============================================================
   CASO DE PRUEBA 3 - PARTE 3 (paso 7) - Conexión: app_web con rol buyer
   El usuario cancela un producto del pedido
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SET ROLE 'buyer';
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 5100;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);

/* PASO 7. Cancela por completo el segundo producto de la orden */
SELECT oi.ID AS order_item_ID, oi.product_name, oi.quantity, oi.unit_price, oi.quantity * oi.unit_price AS importe
FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID WHERE bo.order_ID = @order ORDER BY oi.ID;
SET @item = (SELECT oi.ID FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID WHERE bo.order_ID = @order ORDER BY oi.ID LIMIT 1 OFFSET 1);
SET @qty = (SELECT quantity FROM tbd_order_items WHERE ID = @item);
CALL sp_request_item_cancellation(@uid, @item, @qty, 'CHANGED_MIND', 'Ya no necesito este producto', @cancel);
SELECT ID, cancellation_scope, cancellation_status, reason_code, reason_detail FROM tb_order_cancellations WHERE ID = @cancel;
SELECT * FROM tbd_cancellation_items WHERE cancellation_ID = @cancel;
