/* ============================================================
   PRÁCTICA 03 · Funciones auxiliares para la simulación masiva
   Base de datos: db_test
   Todas aceptan NULL, '' o '*' como comodín (valor aleatorio).
   ============================================================ */
USE db_test;

DROP FUNCTION IF EXISTS fn_get_random_gender_id;
DROP FUNCTION IF EXISTS fn_get_random_country_code;
DROP FUNCTION IF EXISTS fn_get_random_status;
DROP FUNCTION IF EXISTS fn_get_random_birth_date;
DROP FUNCTION IF EXISTS fn_get_phone_by_country;
-- Funciones anteriores que dependían de la tabla inexistente tbc_gender_options
DROP FUNCTION IF EXISTS fn_simulate_gender_id;
DROP FUNCTION IF EXISTS fn_simulate_courtesy_title_id;
DROP FUNCTION IF EXISTS fn_simulate_country_code;
DROP FUNCTION IF EXISTS fn_simulate_birthdate;

DELIMITER ;;

/* Género: 'M' = masculino (1), 'F' = femenino (2), comodín = aleatorio */
CREATE FUNCTION fn_get_random_gender_id(p_gender CHAR(1))
RETURNS TINYINT UNSIGNED
NO SQL
BEGIN
    IF p_gender IS NULL OR p_gender = '' OR p_gender = '*' THEN
        RETURN FLOOR(1 + RAND() * 2);
    END IF;
    IF UPPER(p_gender) = 'M' THEN
        RETURN 1;
    END IF;
    RETURN 2;
END ;;

/* País (ISO 2 letras): el indicado, o uno aleatorio entre 6 países */
CREATE FUNCTION fn_get_random_country_code(p_country VARCHAR(5))
RETURNS CHAR(2)
NO SQL
BEGIN
    IF p_country IS NULL OR p_country = '' OR p_country = '*' THEN
        RETURN ELT(FLOOR(1 + RAND() * 6), 'MX', 'US', 'CO', 'PE', 'AR', 'CL');
    END IF;
    RETURN LEFT(UPPER(p_country), 2);
END ;;

/* Estado de la cuenta: p_active_ratio = % de cuentas activas (b'1'); NULL = todas activas */
CREATE FUNCTION fn_get_random_status(p_active_ratio INT)
RETURNS BIT(1)
NO SQL
BEGIN
    IF p_active_ratio IS NULL THEN
        RETURN b'1';
    END IF;
    RETURN IF((RAND() * 100) < p_active_ratio, b'1', b'0');
END ;;

/* Fecha de nacimiento aleatoria entre p_min_age y p_max_age años (18-65 por omisión) */
CREATE FUNCTION fn_get_random_birth_date(p_min_age INT, p_max_age INT)
RETURNS DATE
NO SQL
BEGIN
    DECLARE v_min_date DATE;
    DECLARE v_max_date DATE;
    SET p_min_age = IFNULL(p_min_age, 18);
    SET p_max_age = IFNULL(p_max_age, 65);
    SET v_max_date = DATE_SUB(CURDATE(), INTERVAL p_min_age YEAR);
    SET v_min_date = DATE_SUB(CURDATE(), INTERVAL p_max_age + 1 YEAR);
    RETURN DATE_ADD(v_min_date, INTERVAL FLOOR(RAND() * (DATEDIFF(v_max_date, v_min_date) + 1)) DAY);
END ;;

/* Teléfono con lada según el país */
CREATE FUNCTION fn_get_phone_by_country(p_country_code VARCHAR(5))
RETURNS VARCHAR(20)
NO SQL
BEGIN
    RETURN CASE p_country_code
        WHEN 'US' THEN CONCAT('+1',  FLOOR(2000000000 + RAND() * 7999999999))
        WHEN 'MX' THEN CONCAT('+52', FLOOR(1000000000 + RAND() * 8999999999))
        WHEN 'CO' THEN CONCAT('+57', FLOOR(3000000000 + RAND() * 6999999999))
        WHEN 'PE' THEN CONCAT('+51', FLOOR(900000000  + RAND() * 899999999))
        WHEN 'AR' THEN CONCAT('+54', FLOOR(1100000000 + RAND() * 8999999999))
        ELSE CONCAT('+', FLOOR(10 + RAND() * 89), FLOOR(1000000000 + RAND() * 8999999999))
    END;
END ;;

DELIMITER ;
