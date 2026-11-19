/* ============================================================
   CASO DE PRUEBA 5: "Compra fallida por falta de inventario"
   PARTE 0 (preparación) - Conexión: adrian.rios (superadmin)
   El sistema asigna al usuario ID 9000 (John Pérez) un cupón de regalo.
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

INSERT INTO tb_gift_coupons (code, amount, user_ID) VALUES ('REGALO-JP-2026-5000', 5000.00, 9000);
SELECT ID, code, amount, coupon_status, user_ID, order_ID, times_reassigned FROM tb_gift_coupons WHERE code = 'REGALO-JP-2026-5000';
