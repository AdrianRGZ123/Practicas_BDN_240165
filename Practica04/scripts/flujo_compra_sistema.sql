/* ============================================================
   FLUJO DE COMPRA - PARTE 2 (pasos 8 a 10, los ejecuta el sistema)
   Conexión: adrian.rios (superadmin) o un usuario con rol admin
   Procesa la última orden del último cliente demo.
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SET @order = (SELECT o.ID FROM tb_orders o JOIN tb_users u ON u.ID = o.User_ID
              WHERE u.email LIKE 'cliente.demo%' ORDER BY o.ID DESC LIMIT 1);
SET @pay = (SELECT ID FROM tb_payments WHERE order_ID = @order ORDER BY ID DESC LIMIT 1);

/* 8. Registro de la transacción bancaria y autorización */
CALL sp_authorize_payment(@pay);
SELECT ID, transaction_type, transaction_status, amount, response_message FROM tb_payment_transaction WHERE payment_ID = @pay;
SELECT ID, payment_status, paid_date FROM tb_payments WHERE ID = @pay;

/* 9. Orden atendida (se genera el envío) */
CALL sp_process_order(@order);
SELECT ID, status_string FROM tb_orders WHERE ID = @order;

/* 10. Entrega en domicilio */
CALL sp_deliver_order(@order);
SELECT o.ID, o.status_string, s.shipment_status, s.address_line_1, s.city, s.delivered_at
FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID JOIN tb_shipments s ON s.buyer_order_ID = bo.ID
WHERE o.ID = @order;
