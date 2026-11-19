/* ============================================================
   CASO DE PRUEBA 2 - PARTE 4 (paso 10) - Conexión: adrian.rios (superadmin)
   El sistema realiza el reenvío del producto en buenas condiciones
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 1500;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);
SET @ret = (SELECT MAX(r.ID) FROM tb_returns r WHERE r.requested_by_user_ID = @uid);

/* PASO 10. Autoriza la devolución, recibe el producto dañado y envía la pieza de reemplazo */
CALL sp_reship_return(@ret);
SELECT s.ID, s.reshipment_of_return_ID, s.service_level, s.tracking_number, s.shipment_status, s.address_line_1, s.city FROM tb_shipments s
JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID WHERE bo.order_ID = @order AND s.reshipment_of_return_ID = @ret;
CALL sp_deliver_reshipment(@ret);
SELECT r.ID, r.return_status, r.authorized_at, r.closed_at, ri.item_condition, ri.disposition, ri.item_status
FROM tb_returns r JOIN tbd_return_items ri ON ri.return_ID = r.ID WHERE r.ID = @ret;
SELECT ID, status_string FROM tb_orders WHERE ID = @order;
