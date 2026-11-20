/* ============================================================
   PRÁCTICA 04 - CASO DE PRUEBA 2 (script consolidado)
   Las partes se ejecutan EN ORDEN; cada una con el usuario de conexión indicado
   (una sesión por parte, porque cambia el usuario de la base de datos).
   Cada paso se marca con sp_trace_step para la trazabilidad (vw_practica04_caso_2).
   ============================================================ */


/* ################ PARTE 1 de 4 -- CONECTAR COMO: app_web ################ */
/* ============================================================
   CASO DE PRUEBA 2: "Compra con detalles en el último pago, reclamación y reenvío"
   PARTE 1 (pasos 1 a 5) - Conexión: app_web  (rol user_not_registered; buyer al pagar)
   Usuario ya registrado: ID 1500 (Carlos López)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 1500;

/* PASO 1. Crea 1 carrito con 10 productos aleatorios, cantidades de 1 a 5 unidades */
CALL sp_trace_step(2, 1, 'PASO 1. Crea 1 carrito con 10 productos aleatorios, cantidades de 1 a 5 unidades', CURRENT_ROLE());
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, x.provider_ID, x.product_ID, 1 + MOD(x.product_ID, 5)
FROM (SELECT provider_ID, product_ID FROM vw_available_products
      WHERE current_stock >= 5 ORDER BY MD5(CONCAT('caso2-', product_ID)) LIMIT 10) x;
SELECT ci.provider_ID, ci.product_ID, p.name, ci.quantity, p.current_price, ci.quantity * p.current_price AS importe
FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart ORDER BY ci.provider_ID, ci.product_ID;

/* PASO 2. Realiza la orden de compra */
CALL sp_trace_step(2, 2, 'PASO 2. Realiza la orden de compra', CURRENT_ROLE());
CALL sp_create_order_from_cart(@uid, @order);
SELECT * FROM vw_cart_to_order WHERE cart_ID = @cart;
SELECT buyer_order_ID, seller_ID, COUNT(*) AS productos, SUM(active_subtotal) AS subtotal_vendedor
FROM vw_order_detail WHERE order_ID = @order GROUP BY buyer_order_ID, seller_ID;

/* PASO 3. Registra su domicilio de envío en un lugar que no es su hogar (trabajo) */
CALL sp_trace_step(2, 3, 'PASO 3. Registra su domicilio de envío en un lugar que no es su hogar (trabajo)', CURRENT_ROLE());
CALL sp_register_address(@uid, 'Trabajo', 'Carlos López (Recepción)', '+52 5557001122', 'Entregar en recepción, horario de 9 a 18 h', 0,
     'Ciudad de México', 'Cuauhtémoc', 'Ciudad de México', 'Juárez', '06600', 'Juárez', 'Calle Londres', '247', '3B', @addr);
CALL sp_set_order_address(@order, @addr);
SELECT * FROM vw_user_addresses_full WHERE address_ID = @addr;

/* PASO 4. Registra su método de pago: tarjeta de crédito (cuenta simulada de 16 dígitos) */
CALL sp_trace_step(2, 4, 'PASO 4. Registra su método de pago: tarjeta de crédito (cuenta simulada de 16 dígitos)', CURRENT_ROLE());
SET @card = '4916338506082832';
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'BancoSim', @card, 'Crédito Carlos', RIGHT(@card, 4), 0
FROM tbc_payment_methods_types WHERE code = 'CREDIT_CARD';
SET @upm = LAST_INSERT_ID();
SELECT m.ID, t.code AS tipo, m.provider, m.provider_method_ref AS cuenta_16_digitos FROM tbd_user_payment_methods m
JOIN tbc_payment_methods_types t ON t.ID = m.payment_method_type_ID WHERE m.ID = @upm;

/* PASO 5. Registra 6 pagos mensuales (al pagar se activa el rol buyer) */
SET ROLE 'buyer';
CALL sp_trace_step(2, 5, 'PASO 5. Registra 6 pagos mensuales (al pagar se activa el rol buyer)', CURRENT_ROLE());
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, 6, NULL, @pay);
SELECT ID, installment_number, installments_total, due_date, amount, payment_status FROM tb_payments WHERE order_ID = @order ORDER BY installment_number;


/* ################ PARTE 2 de 4 -- CONECTAR COMO: adrian.rios ################ */
/* ============================================================
   CASO DE PRUEBA 2 - PARTE 2 (pasos 6 a 8) - Conexión: adrian.rios (superadmin)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 1500;
SET @order = (SELECT MAX(ID) FROM tb_orders WHERE User_ID = @uid);

/* PASO 6. El sistema registra las transacciones bancarias: autoriza 5 y rechaza la última */
CALL sp_trace_step(2, 6, 'PASO 6. El sistema registra las transacciones bancarias: autoriza 5 y rechaza la última', CURRENT_ROLE());
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
CALL sp_trace_step(2, 7, 'PASO 7. El sistema procesa la orden y la marca como atendida; se genera el envío', CURRENT_ROLE());
CALL sp_process_order(@order);
CALL sp_ship_order(@order);
SELECT ID, status_string, total_products, total_cost FROM tb_orders WHERE ID = @order;

/* PASO 8. El usuario recibe el producto en su lugar de trabajo */
CALL sp_trace_step(2, 8, 'PASO 8. El usuario recibe el producto en su lugar de trabajo', CURRENT_ROLE());
CALL sp_deliver_order(@order);
SELECT o.ID AS order_ID, o.status_string, bo.seller_ID, s.shipment_status, s.address_line_1, s.address_line_2, s.city, s.postal_code, s.delivered_at
FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID JOIN tb_shipments s ON s.buyer_order_ID = bo.ID WHERE o.ID = @order;


/* ################ PARTE 3 de 4 -- CONECTAR COMO: app_web (rol buyer) ################ */
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
CALL sp_trace_step(2, 9, 'PASO 9. Reclama un producto dañado (tercer producto de la orden, 1 unidad)', CURRENT_ROLE());
SET @item = (SELECT ID FROM tbd_order_items WHERE buyer_order_ID IN (SELECT ID FROM tbd_buyer_orders WHERE order_ID = @order) ORDER BY ID LIMIT 1 OFFSET 2);
SELECT ID AS order_item_ID, product_ID, product_name, quantity FROM tbd_order_items WHERE ID = @item;
CALL sp_request_return(@uid, @item, 1, 'Damaged', 'DAMAGED_ON_ARRIVAL', 'El producto llegó con la caja abierta y la pieza rota', @ret);
SELECT ID, buyer_order_ID, return_status, reason_code, reason_detail, requested_at FROM tb_returns WHERE ID = @ret;
SELECT * FROM tbd_return_items WHERE return_ID = @ret;
SELECT ID, status_string FROM tb_orders WHERE ID = @order;


/* ################ PARTE 4 de 4 -- CONECTAR COMO: adrian.rios ################ */
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
CALL sp_trace_step(2, 10, 'PASO 10. Autoriza la devolución, recibe el producto dañado y envía la pieza de reemplazo', CURRENT_ROLE());
CALL sp_reship_return(@ret);
SELECT s.ID, s.reshipment_of_return_ID, s.service_level, s.tracking_number, s.shipment_status, s.address_line_1, s.city FROM tb_shipments s
JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID WHERE bo.order_ID = @order AND s.reshipment_of_return_ID = @ret;
CALL sp_deliver_reshipment(@ret);
SELECT r.ID, r.return_status, r.authorized_at, r.closed_at, ri.item_condition, ri.disposition, ri.item_status
FROM tb_returns r JOIN tbd_return_items ri ON ri.return_ID = r.ID WHERE r.ID = @ret;
SELECT ID, status_string FROM tb_orders WHERE ID = @order;


/* Fin del caso (marca de cierre para las vistas de trazabilidad) */
CALL sp_trace_step(2, 99, 'FIN DEL CASO 2', CURRENT_ROLE());
