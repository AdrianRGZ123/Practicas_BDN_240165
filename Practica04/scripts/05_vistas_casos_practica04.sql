/* ============================================================
   PRÁCTICA 04 - 05. VISTAS DE TRAZABILIDAD DE LOS CASOS DE PRUEBA
   vw_practica04_caso_1 ... _5 : cronología COMPLETA de cada caso, paso por paso.
     - Una fila "Paso" al iniciar cada paso (incluye los pasos de solo lectura,
       como la selección de productos, que no modifican datos).
     - Una fila por cada evento de auditoría (tb_logs) que generó ese paso:
       quién lo ejecutó, con qué conexión, en qué tabla, qué operación y detalle.
   vw_practica04_pasos   : cada paso con el rango de tb_logs que le corresponde.
   vw_practica04_resumen : resultado final de cada compra (una fila por caso).
   Requiere haber ejecutado los casos (marcan sus pasos con sp_trace_step).
   Ejecutar como: adrian.rios (superadmin).
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_practica04_pasos AS
SELECT t.ID AS marker_ID, t.caso, t.paso, t.descripcion, t.rol, t.db_user, t.creation_date, t.log_start_ID,
       COALESCE((SELECT MIN(n.log_start_ID) FROM tb_practica04_trace n WHERE n.ID > t.ID),
                (SELECT MAX(ID) + 1 FROM tb_logs)) - 1 AS log_end_ID
FROM tb_practica04_trace t;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_practica04_caso_1 AS
SELECT 'Caso 1 - Compra exitosa' AS caso, p.paso, p.descripcion AS descripcion_paso, p.rol,
       SUBSTRING_INDEX(p.db_user, '@', 1) AS usuario_ejecutor, p.db_user AS conexion_bd,
       p.creation_date AS fecha_evento, CONCAT('Paso ', p.paso) AS tabla_modificada, 'Paso' AS operacion,
       p.descripcion AS detalle_evento, 'Paso iniciado' AS resultado,
       p.log_start_ID * 1000 + MOD(p.marker_ID, 1000) AS secuencia
FROM vw_practica04_pasos p WHERE p.caso = 1 AND p.paso < 99
UNION ALL
SELECT 'Caso 1 - Compra exitosa', p.paso, p.descripcion, p.rol,
       SUBSTRING_INDEX(l.db_user, '@', 1), l.db_user,
       l.operation_date, l.table_name, l.operation,
       l.description, IF(l.operation_status = b'1', 'Evento registrado', 'Evento con error'),
       l.ID * 1000 + 999
FROM vw_practica04_pasos p JOIN tb_logs l ON l.ID BETWEEN p.log_start_ID AND p.log_end_ID
WHERE p.caso = 1 AND p.paso < 99
ORDER BY secuencia;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_practica04_caso_2 AS
SELECT 'Caso 2 - Pagos mensuales, reclamación y reenvío' AS caso, p.paso, p.descripcion AS descripcion_paso, p.rol,
       SUBSTRING_INDEX(p.db_user, '@', 1) AS usuario_ejecutor, p.db_user AS conexion_bd,
       p.creation_date AS fecha_evento, CONCAT('Paso ', p.paso) AS tabla_modificada, 'Paso' AS operacion,
       p.descripcion AS detalle_evento, 'Paso iniciado' AS resultado,
       p.log_start_ID * 1000 + MOD(p.marker_ID, 1000) AS secuencia
FROM vw_practica04_pasos p WHERE p.caso = 2 AND p.paso < 99
UNION ALL
SELECT 'Caso 2 - Pagos mensuales, reclamación y reenvío', p.paso, p.descripcion, p.rol,
       SUBSTRING_INDEX(l.db_user, '@', 1), l.db_user,
       l.operation_date, l.table_name, l.operation,
       l.description, IF(l.operation_status = b'1', 'Evento registrado', 'Evento con error'),
       l.ID * 1000 + 999
FROM vw_practica04_pasos p JOIN tb_logs l ON l.ID BETWEEN p.log_start_ID AND p.log_end_ID
WHERE p.caso = 2 AND p.paso < 99
ORDER BY secuencia;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_practica04_caso_3 AS
SELECT 'Caso 3 - Cancelación parcial y reembolso' AS caso, p.paso, p.descripcion AS descripcion_paso, p.rol,
       SUBSTRING_INDEX(p.db_user, '@', 1) AS usuario_ejecutor, p.db_user AS conexion_bd,
       p.creation_date AS fecha_evento, CONCAT('Paso ', p.paso) AS tabla_modificada, 'Paso' AS operacion,
       p.descripcion AS detalle_evento, 'Paso iniciado' AS resultado,
       p.log_start_ID * 1000 + MOD(p.marker_ID, 1000) AS secuencia
FROM vw_practica04_pasos p WHERE p.caso = 3 AND p.paso < 99
UNION ALL
SELECT 'Caso 3 - Cancelación parcial y reembolso', p.paso, p.descripcion, p.rol,
       SUBSTRING_INDEX(l.db_user, '@', 1), l.db_user,
       l.operation_date, l.table_name, l.operation,
       l.description, IF(l.operation_status = b'1', 'Evento registrado', 'Evento con error'),
       l.ID * 1000 + 999
FROM vw_practica04_pasos p JOIN tb_logs l ON l.ID BETWEEN p.log_start_ID AND p.log_end_ID
WHERE p.caso = 3 AND p.paso < 99
ORDER BY secuencia;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_practica04_caso_4 AS
SELECT 'Caso 4 - Mismo proveedor y punto de recolección' AS caso, p.paso, p.descripcion AS descripcion_paso, p.rol,
       SUBSTRING_INDEX(p.db_user, '@', 1) AS usuario_ejecutor, p.db_user AS conexion_bd,
       p.creation_date AS fecha_evento, CONCAT('Paso ', p.paso) AS tabla_modificada, 'Paso' AS operacion,
       p.descripcion AS detalle_evento, 'Paso iniciado' AS resultado,
       p.log_start_ID * 1000 + MOD(p.marker_ID, 1000) AS secuencia
FROM vw_practica04_pasos p WHERE p.caso = 4 AND p.paso < 99
UNION ALL
SELECT 'Caso 4 - Mismo proveedor y punto de recolección', p.paso, p.descripcion, p.rol,
       SUBSTRING_INDEX(l.db_user, '@', 1), l.db_user,
       l.operation_date, l.table_name, l.operation,
       l.description, IF(l.operation_status = b'1', 'Evento registrado', 'Evento con error'),
       l.ID * 1000 + 999
FROM vw_practica04_pasos p JOIN tb_logs l ON l.ID BETWEEN p.log_start_ID AND p.log_end_ID
WHERE p.caso = 4 AND p.paso < 99
ORDER BY secuencia;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_practica04_caso_5 AS
SELECT 'Caso 5 - Falta de inventario' AS caso, p.paso, p.descripcion AS descripcion_paso, p.rol,
       SUBSTRING_INDEX(p.db_user, '@', 1) AS usuario_ejecutor, p.db_user AS conexion_bd,
       p.creation_date AS fecha_evento, CONCAT('Paso ', p.paso) AS tabla_modificada, 'Paso' AS operacion,
       p.descripcion AS detalle_evento, 'Paso iniciado' AS resultado,
       p.log_start_ID * 1000 + MOD(p.marker_ID, 1000) AS secuencia
FROM vw_practica04_pasos p WHERE p.caso = 5 AND p.paso < 99
UNION ALL
SELECT 'Caso 5 - Falta de inventario', p.paso, p.descripcion, p.rol,
       SUBSTRING_INDEX(l.db_user, '@', 1), l.db_user,
       l.operation_date, l.table_name, l.operation,
       l.description, IF(l.operation_status = b'1', 'Evento registrado', 'Evento con error'),
       l.ID * 1000 + 999
FROM vw_practica04_pasos p JOIN tb_logs l ON l.ID BETWEEN p.log_start_ID AND p.log_end_ID
WHERE p.caso = 5 AND p.paso < 99
ORDER BY secuencia;

CREATE OR REPLACE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW vw_practica04_resumen AS
SELECT CASE o.ID WHEN 1 THEN 'Caso 1 - Compra exitosa'
                 WHEN 2 THEN 'Caso 2 - Pagos mensuales, reclamación y reenvío'
                 WHEN 3 THEN 'Caso 3 - Cancelación parcial y reembolso'
                 WHEN 4 THEN 'Caso 4 - Mismo proveedor y punto de recolección'
                 WHEN 5 THEN 'Caso 5 - Falta de inventario' END AS caso,
       o.User_ID AS comprador_ID, CONCAT(p.given_names, ' ', p.family_names) AS comprador,
       o.cart_ID, o.ID AS order_ID, o.`key` AS folio_orden, o.status_string AS estado_orden,
       (SELECT COUNT(*) FROM tbd_buyer_orders b WHERE b.order_ID = o.ID) AS vendedores,
       (SELECT COUNT(*) FROM tbd_order_items i JOIN tbd_buyer_orders b ON b.ID = i.buyer_order_ID WHERE b.order_ID = o.ID) AS productos,
       o.total_products AS unidades_vigentes, o.total_cost AS total_vigente,
       (SELECT address_label FROM tb_user_addresses a WHERE a.ID = o.shipping_address_ID) AS domicilio_envio,
       (SELECT GROUP_CONCAT(CONCAT(pay.installment_number, '/', pay.installments_total, ' ', pay.payment_status) ORDER BY pay.installment_number SEPARATOR ', ')
          FROM tb_payments pay WHERE pay.order_ID = o.ID) AS pagos,
       (SELECT COALESCE(SUM(r.amount), 0) FROM tb_refunds r JOIN tb_payments pay ON pay.ID = r.payment_ID WHERE pay.order_ID = o.ID) AS reembolsado,
       (SELECT GROUP_CONCAT(DISTINCT s.shipment_status) FROM tb_shipments s JOIN tbd_buyer_orders b ON b.ID = s.buyer_order_ID WHERE b.order_ID = o.ID) AS estado_envios
FROM tb_orders o
LEFT JOIN tb_people p ON p.user_ID = o.User_ID
WHERE o.ID BETWEEN 1 AND 5;
