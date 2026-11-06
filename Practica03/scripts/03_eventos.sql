/* ============================================================
   PRÁCTICA 03 · Eventos programados de MySQL
   Requiere el planificador activo:  SET GLOBAL event_scheduler = ON;
   ============================================================ */
USE db_test;

DROP EVENT IF EXISTS ev_deactivate_stale_carts;
DROP EVENT IF EXISTS ev_daily_summary_log;

/* 1. Cada día desactiva los carritos activos sin movimiento en 30 días */
CREATE EVENT ev_deactivate_stale_carts
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Desactiva carritos sin actividad durante 30 días'
DO
    UPDATE tb_carts
    SET status = b'0'
    WHERE status = b'1'
      AND COALESCE(last_update, creation_date) < NOW() - INTERVAL 30 DAY;

/* 2. Cada día registra en la bitácora un resumen de existencias de la base */
CREATE EVENT ev_daily_summary_log
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Resumen diario de usuarios y productos en tb_logs'
DO
    INSERT INTO tb_logs (table_name, operation, db_user, description)
    VALUES (
        'db_test', 'Read', USER(),
        CONCAT('Resumen diario: usuarios=', (SELECT COUNT(*) FROM tb_users),
               ', productos=', (SELECT COUNT(*) FROM tb_products),
               ', productos activos=', (SELECT COUNT(*) FROM tb_products WHERE status = b'1'))
    );
