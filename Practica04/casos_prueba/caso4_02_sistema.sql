/* ============================================================
   CASO DE PRUEBA 4 - PARTE 2 (pasos 6 a 8) - Conexión: adrian.rios (superadmin)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 7400;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);
SET @pay = (SELECT MAX(ID) FROM tb_payments WHERE order_ID = @order);

/* PASO 6. El sistema confirma el pago y procesa la orden marcándola como atendida */
CALL sp_authorize_payment(@pay, 1, '00', 'Pago en efectivo recibido');
CALL sp_process_order(@order);
SELECT ID, status_string, total_products, total_cost FROM tb_orders WHERE ID = @order;

/* PASO 7. El sistema realiza el envío (un solo envío: un solo proveedor) */
CALL sp_ship_order(@order);
SELECT s.ID, s.shipment_status, s.tracking_number, s.address_line_1, s.address_line_2, s.city, s.postal_code
FROM tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID WHERE bo.order_ID = @order;

/* PASO 8. Nadie recibe el pedido: queda en el punto de recolección y el cliente lo recoge */
CALL sp_deliver_to_pickup_point(@order, 'Punto de recolección SimExpress - Centro de Huauchinango, Puebla');
SELECT s.ID, s.shipment_status, s.pickup_point FROM tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID WHERE bo.order_ID = @order;
CALL sp_pickup_order(@order);
SELECT o.ID AS order_ID, o.status_string, s.shipment_status, s.pickup_point, s.delivered_at
FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID JOIN tb_shipments s ON s.buyer_order_ID = bo.ID WHERE o.ID = @order;
