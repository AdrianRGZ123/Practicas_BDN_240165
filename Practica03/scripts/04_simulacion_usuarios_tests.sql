/* ============================================================
   PRÁCTICA 03 · Escenarios de simulación de usuarios (7,500 en total)
   Requiere: 01_funciones_auxiliares.sql y 02_procedimiento_simulacion_masiva.sql
   Ejecutar con una conexión remota con el rol superadmin activo.
   Parámetros: (total, género, país, edad mín., edad máx., % activos)
   ============================================================ */
USE db_test;

SELECT CURRENT_ROLE() AS roles_activos, USER() AS cuenta;   -- debe incluir `superadmin`

/* Test 1: 500 usuarios de género masculino, originarios de Estados Unidos */
CALL sp_generate_bulk_users(500, 'M', 'US', NULL, NULL, NULL);

/* Test 2: 2,000 usuarios de diferentes países, entre 19 y 35 años */
CALL sp_generate_bulk_users(2000, NULL, NULL, 19, 35, NULL);

/* Test 3: 5,000 usuarios con 80 % de cuentas activas (b'1') y 20 % inactivas (b'0') */
CALL sp_generate_bulk_users(5000, NULL, NULL, NULL, NULL, 80);

/* Verificación rápida: deben sumar 7,500 usuarios nuevos */
SELECT COUNT(*) AS usuarios_simulados_en_esta_sesion
FROM tb_logs
WHERE table_name = 'tb_users' AND operation = 'Create'
  AND operation_date >= NOW() - INTERVAL 1 HOUR;
