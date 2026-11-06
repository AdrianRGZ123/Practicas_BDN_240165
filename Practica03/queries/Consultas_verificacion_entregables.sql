/* ============================================================
   PRÁCTICA 03 · Consultas de verificación de entregables (db_test)
   Complementa a "Consultas _de_verificacion.sql".
   ============================================================ */
USE db_test;

/* 1. Cantidades de estructura: esperado 25 tablas, 72 triggers, 25 vistas, 2 eventos */
SELECT
  (SELECT COUNT(*) FROM information_schema.TABLES   WHERE TABLE_SCHEMA = 'db_test' AND TABLE_TYPE = 'BASE TABLE') AS tablas,
  (SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = 'db_test') AS triggers,
  (SELECT COUNT(*) FROM information_schema.VIEWS    WHERE TABLE_SCHEMA = 'db_test') AS vistas,
  (SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = 'db_test' AND ROUTINE_TYPE = 'PROCEDURE') AS procedimientos,
  (SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = 'db_test' AND ROUTINE_TYPE = 'FUNCTION')  AS funciones,
  (SELECT COUNT(*) FROM information_schema.EVENTS   WHERE EVENT_SCHEMA = 'db_test') AS eventos;

/* 2. Triggers por tabla: 3 por cada tabla operativa (INSERT, UPDATE, DELETE), todos AFTER; tb_logs sin triggers */
SELECT EVENT_OBJECT_TABLE AS tabla, COUNT(*) AS triggers,
       GROUP_CONCAT(CONCAT(ACTION_TIMING, ' ', EVENT_MANIPULATION) ORDER BY EVENT_MANIPULATION) AS detalle
FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = 'db_test'
GROUP BY EVENT_OBJECT_TABLE HAVING COUNT(*) <> 3 OR SUM(ACTION_TIMING <> 'AFTER') > 0;   -- debe devolver 0 filas

/* 3. Vistas: 24 de trazabilidad + 1 de productos por categoría */
SELECT SUM(TABLE_NAME LIKE 'vw\_trazabilidad\_%') AS trazabilidad,
       SUM(TABLE_NAME LIKE 'vw\_total\_products%') AS productos_por_categoria
FROM information_schema.VIEWS WHERE TABLE_SCHEMA = 'db_test';

/* 4. Usuarios simulados: total >= 7,500 y relación 1:1 entre tb_users y tb_people */
SELECT COUNT(*) AS usuarios_bulk FROM tb_users WHERE email LIKE 'bulk\_%';
SELECT COUNT(*) AS usuarios_sin_persona FROM tb_users u LEFT JOIN tb_people p ON p.user_ID = u.ID WHERE p.person_ID IS NULL;
SELECT COUNT(*) AS personas_huerfanas FROM tb_people p LEFT JOIN tb_users u ON u.ID = p.user_ID WHERE u.ID IS NULL;

/* 5. Test 1 (500 hombres de EE. UU.), Test 2 (19-35 años), Test 3 (80 % activos) */
SELECT country_code, gender_ID, COUNT(*) AS total
FROM tb_people p JOIN tb_users u ON u.ID = p.user_ID
WHERE u.email LIKE 'bulk\_%' GROUP BY country_code, gender_ID ORDER BY total DESC;
SELECT TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS edad, COUNT(*) AS total
FROM tb_people GROUP BY edad ORDER BY edad;
SELECT status AS activo, COUNT(*) AS total, ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS porcentaje
FROM tb_users WHERE email LIKE 'bulk\_%' GROUP BY status;

/* 6. Productos: al menos 7,000 y distribución por vendedor (seller1 = 5,000, seller2 = 2,000) */
SELECT COUNT(*) AS total_productos FROM tb_products;
SELECT u.email AS vendedor, COUNT(*) AS productos
FROM tbd_products_users_providers pup JOIN tb_users u ON u.ID = pup.user_ID
GROUP BY u.email ORDER BY productos DESC;

/* 7. Categorías o subcategorías con menos de 5 productos (debe devolver 0 filas) */
SELECT c.ID, c.name, COUNT(pc.product_ID) AS productos
FROM tbc_categories c LEFT JOIN tbd_products_categories pc ON pc.category_ID = c.ID
GROUP BY c.ID, c.name HAVING COUNT(pc.product_ID) < 5;

/* 8. Productos descontinuados (status = b'0') y su representación en la vista por categoría */
SELECT SUM(status = b'1') AS activos, SUM(status = b'0') AS descontinuados FROM tb_products;
SELECT * FROM vw_total_products_by_category ORDER BY category_path LIMIT 20;

/* 9. Trazabilidad: operaciones por cuenta remota (superadmin y sellers) */
SELECT db_user, operation, COUNT(*) AS operaciones FROM vw_trazabilidad_usuarios GROUP BY db_user, operation ORDER BY operaciones DESC;
SELECT db_user, operation, COUNT(*) AS operaciones FROM vw_trazabilidad_productos GROUP BY db_user, operation ORDER BY operaciones DESC;

/* 10. Integridad referencial: llaves foráneas declaradas y filas huérfanas */
SELECT COUNT(*) AS llaves_foraneas FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = 'db_test';
SELECT COUNT(*) AS productos_sin_vendedor FROM tb_products p LEFT JOIN tbd_products_users_providers pup ON pup.product_ID = p.id WHERE pup.product_ID IS NULL;
SELECT COUNT(*) AS productos_sin_categoria FROM tb_products p LEFT JOIN tbd_products_categories pc ON pc.product_ID = p.id WHERE pc.product_ID IS NULL;

/* 11. Eventos programados */
SELECT EVENT_NAME, STATUS, INTERVAL_VALUE, INTERVAL_FIELD, LAST_EXECUTED FROM information_schema.EVENTS WHERE EVENT_SCHEMA = 'db_test';
