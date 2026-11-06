/* ============================================================
   PRÁCTICA 03 · Procedimiento general de simulación masiva de usuarios
   Requiere: 01_funciones_auxiliares.sql
   Ejecutar con una cuenta que tenga activo el rol superadmin.

   Parámetros:
     p_total         OBLIGATORIO  cantidad de usuarios (> 0)
     p_gender        opcional     'M' | 'F' | NULL / '' / '*' = aleatorio
     p_country       opcional     código ISO (ej. 'US') | NULL / '' / '*' = aleatorio
     p_min_age       opcional     edad mínima  (NULL = 18)
     p_max_age       opcional     edad máxima  (NULL = 65)
     p_active_ratio  opcional     % de cuentas activas b'1' (NULL = 100)
   ============================================================ */
USE db_test;

-- Procedimientos independientes por escenario que se sustituyen por el general
DROP PROCEDURE IF EXISTS sp_bulk_insert_users;
DROP PROCEDURE IF EXISTS sp_bulk_insert_persons;
DROP PROCEDURE IF EXISTS sp_bulk_insert_full_users;
DROP PROCEDURE IF EXISTS sp_simulate_users_bulk;
DROP PROCEDURE IF EXISTS sp_simulate_single_user;
DROP PROCEDURE IF EXISTS sp_generate_bulk_users;

DELIMITER ;;

CREATE PROCEDURE sp_generate_bulk_users(
    IN p_total INT UNSIGNED,
    IN p_gender CHAR(1),
    IN p_country VARCHAR(5),
    IN p_min_age INT,
    IN p_max_age INT,
    IN p_active_ratio INT
)
BEGIN
    DECLARE v_i INT UNSIGNED DEFAULT 0;
    DECLARE v_user_id INT;
    DECLARE v_gender_id TINYINT UNSIGNED;
    DECLARE v_country CHAR(2);
    DECLARE v_status BIT(1);
    DECLARE v_uid BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_total IS NULL OR p_total = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'p_total es obligatorio y debe ser mayor que cero';
    END IF;
    IF p_gender IS NOT NULL AND p_gender NOT IN ('', '*', 'M', 'F', 'm', 'f') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'p_gender debe ser M, F o comodín (NULL, vacío o *)';
    END IF;
    IF p_active_ratio IS NOT NULL AND (p_active_ratio < 0 OR p_active_ratio > 100) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'p_active_ratio debe estar entre 0 y 100';
    END IF;
    IF IFNULL(p_min_age, 18) > IFNULL(p_max_age, 65) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'p_min_age no puede ser mayor que p_max_age';
    END IF;

    START TRANSACTION;

    WHILE v_i < p_total DO
        SET v_uid        = UUID_SHORT();
        SET v_gender_id  = fn_get_random_gender_id(p_gender);
        SET v_country    = fn_get_random_country_code(p_country);
        SET v_status     = fn_get_random_status(p_active_ratio);

        INSERT INTO tb_users (email, nickname, password, status)
        VALUES (
            CONCAT('bulk_', v_uid, '@utxicotepec.edu.mx'),
            CONCAT('USER-', v_uid),
            SHA2(CONCAT('Password123!', v_uid, RAND()), 256),
            v_status
        );
        SET v_user_id = LAST_INSERT_ID();

        INSERT INTO tb_people (user_ID, courtesy_title, given_names, family_names, birth_date,
                               gender_ID, country_code, phone, status)
        VALUES (
            v_user_id,
            IF(v_gender_id = 1, 'Sr.', 'Sra.'),
            IF(v_gender_id = 1,
               ELT(FLOOR(1 + RAND() * 6), 'John', 'Carlos', 'Michael', 'Luis', 'David', 'Jorge'),
               ELT(FLOOR(1 + RAND() * 6), 'Emily', 'Ana', 'Sofia', 'María', 'Laura', 'Karen')),
            ELT(FLOOR(1 + RAND() * 6), 'Smith', 'Johnson', 'Pérez', 'García', 'Williams', 'López'),
            fn_get_random_birth_date(p_min_age, p_max_age),
            v_gender_id,
            v_country,
            fn_get_phone_by_country(v_country),
            v_status
        );

        SET v_i = v_i + 1;
        IF MOD(v_i, 1000) = 0 THEN        -- confirmación parcial por bloques
            COMMIT;
            START TRANSACTION;
        END IF;
    END WHILE;

    COMMIT;

    SELECT CONCAT('Simulación completada. Usuarios creados: ', v_i) AS result;
END ;;

DELIMITER ;
