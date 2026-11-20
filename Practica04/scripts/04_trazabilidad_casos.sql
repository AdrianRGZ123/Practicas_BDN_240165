/* ============================================================
   PRÁCTICA 04 - 04. INFRAESTRUCTURA DE TRAZABILIDAD DE LOS CASOS
   - tb_practica04_trace: marca el inicio de cada PASO de cada caso de prueba
     (caso, paso, descripción, rol activo, usuario de conexión y el primer
     tb_logs.ID que le corresponde).
   - sp_trace_step: la invocan los scripts de los casos al iniciar cada paso.
   - Triggers de auditoría de tb_gift_coupons (no tenía) para que la asignación,
     uso y reasignación del cupón de regalo queden en tb_logs.
   Las vistas vw_practica04_caso_1..5 (script 05) unen estas marcas con la
   bitácora para mostrar TODO lo que pasó en cada paso.
   Ejecutar como: adrian.rios (superadmin), antes de los casos de prueba.
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;

CREATE TABLE IF NOT EXISTS tb_practica04_trace (
  ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
  caso TINYINT UNSIGNED NOT NULL COMMENT 'Número de caso de prueba (1 a 5)',
  paso TINYINT UNSIGNED NOT NULL COMMENT '0 = preparación, 1..n = paso del caso, 99 = fin del caso',
  descripcion VARCHAR(300) NOT NULL COMMENT 'Texto del paso tal como lo define el caso de prueba',
  rol VARCHAR(100) DEFAULT NULL COMMENT 'Rol activo de la conexión al iniciar el paso',
  db_user VARCHAR(80) NOT NULL COMMENT 'Usuario@host de la conexión que ejecuta el paso',
  log_start_ID INT NOT NULL COMMENT 'Primer tb_logs.ID generado a partir de este paso',
  creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  KEY idx_trace_caso (caso, ID),
  CONSTRAINT chk_trace_caso CHECK (caso BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP PROCEDURE IF EXISTS sp_trace_step;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_trace_step(
    IN p_caso TINYINT UNSIGNED, IN p_paso TINYINT UNSIGNED, IN p_descripcion VARCHAR(300), IN p_rol VARCHAR(100))
    SQL SECURITY DEFINER
BEGIN
    INSERT INTO tb_practica04_trace (caso, paso, descripcion, rol, db_user, log_start_ID)
    VALUES (p_caso, p_paso, p_descripcion, p_rol, USER(), COALESCE((SELECT MAX(ID) FROM tb_logs), 0) + 1);
END$$

DROP TRIGGER IF EXISTS trg_tb_gift_coupons_after_insert$$
CREATE DEFINER=`root`@`localhost` TRIGGER trg_tb_gift_coupons_after_insert AFTER INSERT ON tb_gift_coupons FOR EACH ROW
BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description)
    VALUES ('tb_gift_coupons', 'Create', USER(),
            CONCAT('Cupón de regalo asignado. ID=', NEW.ID, ', code=', NEW.code, ', amount=', NEW.amount, ', user_ID=', IFNULL(NEW.user_ID, 'NULL')));
END$$

DROP TRIGGER IF EXISTS trg_tb_gift_coupons_after_update$$
CREATE DEFINER=`root`@`localhost` TRIGGER trg_tb_gift_coupons_after_update AFTER UPDATE ON tb_gift_coupons FOR EACH ROW
BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description)
    VALUES ('tb_gift_coupons', 'Update', USER(),
            CONCAT('Cupón de regalo actualizado. ID=', NEW.ID, ', code=', NEW.code, ', estado ', OLD.coupon_status, ' -> ', NEW.coupon_status,
                   ', order_ID=', IFNULL(NEW.order_ID, 'NULL'), ', veces reasignado=', NEW.times_reassigned));
END$$
DELIMITER ;
