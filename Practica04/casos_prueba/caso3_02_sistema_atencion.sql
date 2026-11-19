/* ============================================================
   CASO DE PRUEBA 3 - PARTE 2 (paso 6) - Conexión: adrian.rios (superadmin)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 5100;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);
SET @pay = (SELECT MAX(ID) FROM tb_payments WHERE order_ID = @order);

/* PASO 6. El sistema confirma el pago en efectivo y procesa la orden marcándola como atendida */
CALL sp_authorize_payment(@pay, 1, '00', 'Pago en efectivo recibido');
CALL sp_process_order(@order);
SELECT o.ID, o.status_string, o.total_products, o.total_cost, bo.fulfillment_status FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID WHERE o.ID = @order;
