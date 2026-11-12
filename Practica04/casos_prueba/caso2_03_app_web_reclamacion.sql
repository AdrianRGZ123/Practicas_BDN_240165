/* ============================================================
   CASO DE PRUEBA 2 - PARTE 3 (paso 9) - Conexión: app_web con rol buyer
   El usuario reclama la devolución de un producto que llegó dañado
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SET ROLE 'buyer';
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 1500;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);

/* PASO 9. Reclama un producto dañado (tercer producto de la orden, 1 unidad) */
SET @item = (SELECT ID FROM tbd_order_items WHERE buyer_order_ID IN (SELECT ID FROM tbd_buyer_orders WHERE order_ID = @order) ORDER BY ID LIMIT 1 OFFSET 2);
SELECT ID AS order_item_ID, product_ID, product_name, quantity FROM tbd_order_items WHERE ID = @item;
CALL sp_request_return(@uid, @item, 1, 'Damaged', 'DAMAGED_ON_ARRIVAL', 'El producto llegó con la caja abierta y la pieza rota', @ret);
SELECT ID, buyer_order_ID, return_status, reason_code, reason_detail, requested_at FROM tb_returns WHERE ID = @ret;
SELECT * FROM tbd_return_items WHERE return_ID = @ret;
SELECT ID, status_string FROM tb_orders WHERE ID = @order;
