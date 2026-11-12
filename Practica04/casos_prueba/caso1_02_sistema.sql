/* ============================================================
   CASO DE PRUEBA 1: "Compra exitosa, sin modificaciones"
   PARTE 2 (pasos 9 a 11) - Conexión: adrian.rios (superadmin)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

SET @uid = (SELECT ID FROM tb_users WHERE email = 'valeria.montes@correo-demo.mx');
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);
SET @pay = (SELECT MAX(ID) FROM tb_payments WHERE order_ID = @order);

/* PASO 9. El sistema registra la transacción bancaria y la autoriza */
CALL sp_authorize_payment(@pay, 1, '00', 'Aprobada');
SELECT ID, transaction_type, transaction_status, amount, response_code, response_message FROM tb_payment_transaction WHERE payment_ID = @pay ORDER BY ID;
SELECT ID, payment_status, paid_date FROM tb_payments WHERE ID = @pay;

/* PASO 10. El sistema procesa la orden y la marca como atendida; se genera el envío */
CALL sp_process_order(@order);
CALL sp_ship_order(@order);
SELECT ID, status_string FROM tb_orders WHERE ID = @order;

/* PASO 11. El usuario recibe el producto en casa */
CALL sp_deliver_order(@order);
SELECT o.ID AS order_ID, o.status_string, s.shipment_status, s.address_line_1, s.address_line_2, s.city, s.state_region, s.postal_code, s.delivered_at
FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID JOIN tb_shipments s ON s.buyer_order_ID = bo.ID
WHERE o.ID = @order;
