/* ============================================================
   PRÁCTICA 04 - CASO DE PRUEBA 4 (script consolidado)
   Las partes se ejecutan EN ORDEN; cada una con el usuario de conexión indicado
   (una sesión por parte, porque cambia el usuario de la base de datos).
   Cada paso se marca con sp_trace_step para la trazabilidad (vw_practica04_caso_4).
   ============================================================ */


/* ################ PARTE 1 de 2 -- CONECTAR COMO: app_web ################ */
/* ============================================================
   CASO DE PRUEBA 4: "Compra exitosa del mismo proveedor con entrega en punto de recolección"
   PARTE 1 (pasos 1 a 5) - Conexión: app_web  (rol user_not_registered; buyer al pagar)
   Usuario ya registrado: ID 7400 (Emily Pérez)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 7400;

/* PASO 1. Carrito con 3 productos del MISMO proveedor, de 1 a 3 unidades cada uno */
CALL sp_trace_step(4, 1, 'PASO 1. Carrito con 3 productos del MISMO proveedor, de 1 a 3 unidades cada uno', CURRENT_ROLE());
SET @prov = (SELECT provider_ID FROM vw_available_products WHERE current_stock >= 3
             GROUP BY provider_ID HAVING COUNT(*) >= 3 ORDER BY provider_ID LIMIT 1 OFFSET 9);
SELECT @prov AS proveedor_elegido;
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, x.provider_ID, x.product_ID, 1 + MOD(x.product_ID, 3)
FROM (SELECT provider_ID, product_ID FROM vw_available_products
      WHERE provider_ID = @prov AND current_stock >= 3 ORDER BY MD5(CONCAT('caso4-', product_ID)) LIMIT 3) x;
SELECT ci.provider_ID, ci.product_ID, p.name, ci.quantity, p.current_price, ci.quantity * p.current_price AS importe
FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart;

/* PASO 2. Realiza la orden de compra */
CALL sp_trace_step(4, 2, 'PASO 2. Realiza la orden de compra', CURRENT_ROLE());
CALL sp_create_order_from_cart(@uid, @order);
SELECT * FROM vw_cart_to_order WHERE cart_ID = @cart;

/* PASO 3. Domicilio de envío en un lugar que no es su hogar (casa de una amiga) */
CALL sp_trace_step(4, 3, 'PASO 3. Domicilio de envío en un lugar que no es su hogar (casa de una amiga)', CURRENT_ROLE());
CALL sp_register_address(@uid, 'Casa de Daniela', 'Daniela Ortega', '+52 7641876655', 'Si nadie abre, dejar en el punto de recolección', 0,
     'Puebla', 'Huauchinango', 'Huauchinango', 'Huauchinango Centro', '73160', 'Aquiles Serdán', 'Calle Hidalgo', '312', NULL, @addr);
CALL sp_set_order_address(@order, @addr);
SELECT * FROM vw_user_addresses_full WHERE address_ID = @addr;

/* PASO 4. Método de pago: transferencia SPEI (cuenta simulada de 16 dígitos) */
CALL sp_trace_step(4, 4, 'PASO 4. Método de pago: transferencia SPEI (cuenta simulada de 16 dígitos)', CURRENT_ROLE());
SET @card = '6381270094415530';
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'BancoSim-SPEI', @card, 'SPEI Emily', RIGHT(@card, 4), 0
FROM tbc_payment_methods_types WHERE code = 'SPEI';
SET @upm = LAST_INSERT_ID();
SELECT m.ID, t.code AS tipo, m.provider, m.provider_method_ref AS cuenta_16_digitos FROM tbd_user_payment_methods m
JOIN tbc_payment_methods_types t ON t.ID = m.payment_method_type_ID WHERE m.ID = @upm;

/* PASO 5. Registra un solo pago en efectivo por el costo total (rol buyer) */
SET ROLE 'buyer';
CALL sp_trace_step(4, 5, 'PASO 5. Registra un solo pago en efectivo por el costo total (rol buyer)', CURRENT_ROLE());
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, 1, 'CASH', @pay);
SELECT p.ID, p.order_ID, p.amount, pm.name AS forma_de_pago, p.payment_status, p.user_payment_method_ID
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID WHERE p.ID = @pay;


/* ################ PARTE 2 de 2 -- CONECTAR COMO: adrian.rios ################ */
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
CALL sp_trace_step(4, 6, 'PASO 6. El sistema confirma el pago y procesa la orden marcándola como atendida', CURRENT_ROLE());
CALL sp_authorize_payment(@pay, 1, '00', 'Pago en efectivo recibido');
CALL sp_process_order(@order);
SELECT ID, status_string, total_products, total_cost FROM tb_orders WHERE ID = @order;

/* PASO 7. El sistema realiza el envío (un solo envío: un solo proveedor) */
CALL sp_trace_step(4, 7, 'PASO 7. El sistema realiza el envío (un solo envío: un solo proveedor)', CURRENT_ROLE());
CALL sp_ship_order(@order);
SELECT s.ID, s.shipment_status, s.tracking_number, s.address_line_1, s.address_line_2, s.city, s.postal_code
FROM tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID WHERE bo.order_ID = @order;

/* PASO 8. Nadie recibe el pedido: queda en el punto de recolección y el cliente lo recoge */
CALL sp_trace_step(4, 8, 'PASO 8. Nadie recibe el pedido: queda en el punto de recolección y el cliente lo recoge', CURRENT_ROLE());
CALL sp_deliver_to_pickup_point(@order, 'Punto de recolección SimExpress - Centro de Huauchinango, Puebla');
SELECT s.ID, s.shipment_status, s.pickup_point FROM tb_shipments s JOIN tbd_buyer_orders bo ON bo.ID = s.buyer_order_ID WHERE bo.order_ID = @order;
CALL sp_pickup_order(@order);
SELECT o.ID AS order_ID, o.status_string, s.shipment_status, s.pickup_point, s.delivered_at
FROM tb_orders o JOIN tbd_buyer_orders bo ON bo.order_ID = o.ID JOIN tb_shipments s ON s.buyer_order_ID = bo.ID WHERE o.ID = @order;


/* Fin del caso (marca de cierre para las vistas de trazabilidad) */
CALL sp_trace_step(4, 99, 'FIN DEL CASO 4', CURRENT_ROLE());
