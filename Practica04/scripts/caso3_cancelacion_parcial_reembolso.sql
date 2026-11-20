/* ============================================================
   PRÁCTICA 04 - CASO DE PRUEBA 3 (script consolidado)
   Las partes se ejecutan EN ORDEN; cada una con el usuario de conexión indicado
   (una sesión por parte, porque cambia el usuario de la base de datos).
   Cada paso se marca con sp_trace_step para la trazabilidad (vw_practica04_caso_3).
   ============================================================ */


/* ################ PARTE 1 de 4 -- CONECTAR COMO: app_web ################ */
/* ============================================================
   CASO DE PRUEBA 3: "Compra exitosa con cancelación parcial, ajuste y reembolso parcial"
   PARTE 1 (pasos 1 a 5) - Conexión: app_web  (rol user_not_registered; buyer al pagar)
   Usuario ya registrado: ID 5100 (John Williams)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 5100;

/* PASO 1. Carrito con 3 productos de la MISMA categoría, cantidades de 1 a 10 unidades */
CALL sp_trace_step(3, 1, 'PASO 1. Carrito con 3 productos de la MISMA categoría, cantidades de 1 a 10 unidades', CURRENT_ROLE());
SET @cat = (SELECT pc.category_ID
            FROM tbd_products_categories pc JOIN vw_available_products v ON v.product_ID = pc.product_ID
            WHERE v.current_stock >= 10
            GROUP BY pc.category_ID HAVING COUNT(*) >= 3
            ORDER BY pc.category_ID LIMIT 1 OFFSET 6);
SELECT ID AS category_ID, name AS categoria FROM tbc_categories WHERE ID = @cat;
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, x.provider_ID, x.product_ID, 1 + MOD(x.product_ID, 10)
FROM (SELECT v.provider_ID, v.product_ID
      FROM vw_available_products v JOIN tbd_products_categories pc ON pc.product_ID = v.product_ID
      WHERE pc.category_ID = @cat AND v.current_stock >= 10
      ORDER BY MD5(CONCAT('caso3-', v.product_ID)) LIMIT 3) x;
SELECT ci.product_ID, p.name, ci.quantity, p.current_price, ci.quantity * p.current_price AS importe
FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart;

/* PASO 2. Realiza la orden de compra */
CALL sp_trace_step(3, 2, 'PASO 2. Realiza la orden de compra', CURRENT_ROLE());
CALL sp_create_order_from_cart(@uid, @order);
SELECT * FROM vw_cart_to_order WHERE cart_ID = @cart;

/* PASO 3. Domicilio de envío en un lugar que no es su hogar: etiqueta "Casa Papas" */
CALL sp_trace_step(3, 3, 'PASO 3. Domicilio de envío en un lugar que no es su hogar: etiqueta "Casa Papas"', CURRENT_ROLE());
CALL sp_register_address(@uid, 'Casa Papas', 'Robert Williams', '+52 2281345670', 'Los papás recibirán el pedido; preguntar por Robert', 0,
     'Veracruz', 'Xalapa', 'Xalapa-Enríquez', 'Xalapa Centro', '91000', 'Salud', 'Calle Enríquez', '58', NULL, @addr);
CALL sp_set_order_address(@order, @addr);
SELECT * FROM vw_user_addresses_full WHERE address_ID = @addr;

/* PASO 4. Método de pago: tarjeta digital Spin (cuenta simulada de 16 dígitos) */
CALL sp_trace_step(3, 4, 'PASO 4. Método de pago: tarjeta digital Spin (cuenta simulada de 16 dígitos)', CURRENT_ROLE());
SET @card = '7312904455186027';
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'Spin', @card, 'Spin John', RIGHT(@card, 4), 0
FROM tbc_payment_methods_types WHERE code = 'DIGITAL_CARD';
SET @upm = LAST_INSERT_ID();
SELECT m.ID, t.code AS tipo, m.provider, m.provider_method_ref AS cuenta_16_digitos FROM tbd_user_payment_methods m
JOIN tbc_payment_methods_types t ON t.ID = m.payment_method_type_ID WHERE m.ID = @upm;

/* PASO 5. Registra un solo pago en efectivo por el costo total de la compra (rol buyer) */
SET ROLE 'buyer';
CALL sp_trace_step(3, 5, 'PASO 5. Registra un solo pago en efectivo por el costo total de la compra (rol buyer)', CURRENT_ROLE());
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, 1, 'CASH', @pay);
SELECT p.ID, p.order_ID, p.amount, pm.name AS forma_de_pago, p.payment_status, p.user_payment_method_ID
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID WHERE p.ID = @pay;


/* ################ PARTE 2 de 4 -- CONECTAR COMO: adrian.rios ################ */
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
CALL sp_trace_step(3, 6, 'PASO 6. El sistema confirma el pago en efectivo y procesa la orden marcándola como atendida', CURRENT_ROLE());
CALL sp_authorize_payment(@pay, 1, '00', 'Pago en efectivo recibido');
CALL sp_process_order(@order);
SELECT o.ID, o.status_string, o.total_products, o.total_cost, bo.fulfillment_status FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID WHERE o.ID = @order;


/* ################ PARTE 3 de 4 -- CONECTAR COMO: app_web (rol buyer) ################ */
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
CALL sp_trace_step(3, 7, 'PASO 7. Cancela por completo el segundo producto de la orden', CURRENT_ROLE());
SELECT oi.ID AS order_item_ID, oi.product_name, oi.quantity, oi.unit_price, oi.quantity * oi.unit_price AS importe
FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID WHERE bo.order_ID = @order ORDER BY oi.ID;
SET @item = (SELECT oi.ID FROM tbd_order_items oi JOIN tbd_buyer_orders bo ON bo.ID = oi.buyer_order_ID WHERE bo.order_ID = @order ORDER BY oi.ID LIMIT 1 OFFSET 1);
SET @qty = (SELECT quantity FROM tbd_order_items WHERE ID = @item);
CALL sp_request_item_cancellation(@uid, @item, @qty, 'CHANGED_MIND', 'Ya no necesito este producto', @cancel);
SELECT ID, cancellation_scope, cancellation_status, reason_code, reason_detail FROM tb_order_cancellations WHERE ID = @cancel;
SELECT * FROM tbd_cancellation_items WHERE cancellation_ID = @cancel;


/* ################ PARTE 4 de 4 -- CONECTAR COMO: adrian.rios ################ */
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
CALL sp_trace_step(3, 8, 'PASO 8. El sistema actualiza la orden de compra (ítems, subtotal, totales e inventario)', CURRENT_ROLE());
CALL sp_apply_cancellation(@cancel);
SELECT ID, total_products, total_cost AS total_despues_del_ajuste, status_string FROM tb_orders WHERE ID = @order;
SELECT order_item_ID, product_name, quantity, canceled_quantity, active_subtotal FROM vw_order_detail WHERE order_ID = @order ORDER BY order_item_ID;

/* PASO 9. El sistema reembolsa el monto de los productos cancelados */
CALL sp_trace_step(3, 9, 'PASO 9. El sistema reembolsa el monto de los productos cancelados', CURRENT_ROLE());
CALL sp_refund_cancellation(@cancel);
SELECT r.ID AS refund_ID, r.payment_ID, r.reason, r.amount, r.refund_status, r.processed_at FROM tb_refunds r JOIN tb_payments p ON p.ID = r.payment_ID WHERE p.order_ID = @order;
SELECT p.ID, p.amount AS monto_cobrado, p.payment_status, t.transaction_type, t.transaction_status, t.amount AS monto_transaccion
FROM tb_payments p JOIN tb_payment_transaction t ON t.payment_ID = p.ID WHERE p.order_ID = @order ORDER BY t.ID;
SELECT ID, cancellation_status, completed_at FROM tb_order_cancellations WHERE ID = @cancel;

/* PASO 10. El sistema realiza el envío */
CALL sp_trace_step(3, 10, 'PASO 10. El sistema realiza el envío', CURRENT_ROLE());
CALL sp_ship_order(@order);
SELECT s.ID, s.shipment_status, s.tracking_number, s.recipient_name, s.address_line_1, s.address_line_2, s.city, s.state_region, s.postal_code
FROM tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID WHERE bo.order_ID = @order;

/* PASO 11. El cliente recibe el pedido en "Casa Papas" */
CALL sp_trace_step(3, 11, 'PASO 11. El cliente recibe el pedido en "Casa Papas"', CURRENT_ROLE());
CALL sp_deliver_order(@order);
SELECT o.ID AS order_ID, o.status_string, o.total_products, o.total_cost, s.shipment_status, s.delivered_at
FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID JOIN tb_shipments s ON s.buyer_order_ID = bo.ID WHERE o.ID = @order;


/* Fin del caso (marca de cierre para las vistas de trazabilidad) */
CALL sp_trace_step(3, 99, 'FIN DEL CASO 3', CURRENT_ROLE());
