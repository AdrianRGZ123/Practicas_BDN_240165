/* ============================================================
   CASO DE PRUEBA 2 - PARTE 2 (pasos 6 a 8) - Conexión: adrian.rios (superadmin)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 1500;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);

/* PASO 6. El sistema registra las transacciones bancarias: autoriza 5 y rechaza la última */
CALL sp_authorize_payment((SELECT ID FROM tb_payments WHERE order_ID = @order AND installment_number = 1), 1, '00', 'Aprobada');
CALL sp_authorize_payment((SELECT ID FROM tb_payments WHERE order_ID = @order AND installment_number = 2), 1, '00', 'Aprobada');
CALL sp_authorize_payment((SELECT ID FROM tb_payments WHERE order_ID = @order AND installment_number = 3), 1, '00', 'Aprobada');
CALL sp_authorize_payment((SELECT ID FROM tb_payments WHERE order_ID = @order AND installment_number = 4), 1, '00', 'Aprobada');
CALL sp_authorize_payment((SELECT ID FROM tb_payments WHERE order_ID = @order AND installment_number = 5), 1, '00', 'Aprobada');
CALL sp_authorize_payment((SELECT ID FROM tb_payments WHERE order_ID = @order AND installment_number = 6), 0, '51', 'Límite excedido de crédito');
SELECT p.installment_number, p.amount, p.payment_status, t.transaction_type, t.transaction_status, t.response_code, t.response_message
FROM tb_payments p JOIN tb_payment_transaction t ON t.payment_ID = p.ID
WHERE p.order_ID = @order ORDER BY p.installment_number, t.ID;

/* PASO 7. El sistema procesa la orden y la marca como atendida; se genera el envío */
CALL sp_process_order(@order);
CALL sp_ship_order(@order);
SELECT ID, status_string, total_products, total_cost FROM tb_orders WHERE ID = @order;

/* PASO 8. El usuario recibe el producto en su lugar de trabajo */
CALL sp_deliver_order(@order);
SELECT o.ID AS order_ID, o.status_string, bo.seller_ID, s.shipment_status, s.address_line_1, s.address_line_2, s.city, s.postal_code, s.delivered_at
FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID JOIN tb_shipments s ON s.buyer_order_ID = bo.ID WHERE o.ID = @order;
