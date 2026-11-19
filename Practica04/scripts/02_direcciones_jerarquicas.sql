/* ============================================================
   PRÁCTICA 04 - 02. DIRECCIONES CON ESCALAMIENTO VERTICAL
   tbd_address_components guarda cada domicilio como un árbol:
   cada componente apunta (address_sup_ID) al componente superior.

   País -> Estado -> Municipio -> Ciudad -> Localidad -> Código Postal
        -> Colonia -> Calle/Avenida -> Número Exterior -> Número Interior

   El primer componente (País) tiene address_sup_ID = NULL porque la FK
   compuesta (address_ID, address_sup_ID) exige que el superior exista.
   Ejecutar como: adrian.rios (superadmin)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;

/* ------------------------------------------------------------
   1. PROCEDIMIENTO PARA REGISTRAR UN DOMICILIO COMPLETO
      SQL SECURITY INVOKER: se ejecuta con los privilegios de quien
      lo invoca (user_not_registered / buyer ya tienen INSERT sobre
      tb_user_addresses y tbd_address_components).
   ------------------------------------------------------------ */
DROP PROCEDURE IF EXISTS sp_register_address;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE sp_register_address(
    IN  p_user_id        INT,
    IN  p_label          VARCHAR(100),
    IN  p_recipient      VARCHAR(150),
    IN  p_phone          VARCHAR(25),
    IN  p_instructions   VARCHAR(500),
    IN  p_is_default     TINYINT,
    IN  p_state          VARCHAR(255),
    IN  p_municipality   VARCHAR(255),
    IN  p_city           VARCHAR(255),
    IN  p_locality       VARCHAR(255),
    IN  p_postal_code    VARCHAR(255),
    IN  p_neighborhood   VARCHAR(255),
    IN  p_street         VARCHAR(255),
    IN  p_ext_number     VARCHAR(255),
    IN  p_int_number     VARCHAR(255),
    OUT p_address_id     BIGINT UNSIGNED)
    SQL SECURITY INVOKER
BEGIN
    DECLARE v_sup BIGINT UNSIGNED;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF p_is_default = 1 THEN
        UPDATE tb_user_addresses SET is_default = 0 WHERE user_ID = p_user_id;
    END IF;

    INSERT INTO tb_user_addresses (user_ID, address_label, recipient_name, recipient_phone, delivery_instructions, is_default)
    VALUES (p_user_id, p_label, p_recipient, p_phone, p_instructions, p_is_default);
    SET p_address_id = LAST_INSERT_ID();

    INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, 'México', 'País', NULL);
    SET v_sup = LAST_INSERT_ID();
    INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, p_state, 'Estado', v_sup);
    SET v_sup = LAST_INSERT_ID();
    INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, p_municipality, 'Municipio', v_sup);
    SET v_sup = LAST_INSERT_ID();
    INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, p_city, 'Ciudad', v_sup);
    SET v_sup = LAST_INSERT_ID();
    INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, p_locality, 'Localidad', v_sup);
    SET v_sup = LAST_INSERT_ID();
    INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, p_postal_code, 'Código Postal', v_sup);
    SET v_sup = LAST_INSERT_ID();
    INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, p_neighborhood, 'Colonia', v_sup);
    SET v_sup = LAST_INSERT_ID();
    INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, p_street, 'Calle/Avenida', v_sup);
    SET v_sup = LAST_INSERT_ID();
    INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, p_ext_number, 'Número Exterior', v_sup);
    SET v_sup = LAST_INSERT_ID();
    IF p_int_number IS NOT NULL AND p_int_number <> '' THEN
        INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID) VALUES (p_address_id, p_int_number, 'Número Interior', v_sup);
    END IF;

    COMMIT;
END$$
DELIMITER ;

/* ------------------------------------------------------------
   2. DOMICILIO "Casa" PARA CADA USUARIO ACTIVO CON DATOS PERSONALES
      (carga masiva por niveles: un INSERT por nivel del árbol)
   ------------------------------------------------------------ */
INSERT INTO tb_user_addresses (user_ID, address_label, recipient_name, recipient_phone, delivery_instructions, is_default)
SELECT u.ID, 'Casa', CONCAT(p.given_names, ' ', COALESCE(p.family_names, '')), p.phone, 'Entregar en puerta principal', 1
FROM tb_users u
JOIN tb_people p ON p.user_ID = u.ID
WHERE u.status = 1;

CREATE TEMPORARY TABLE tmp_loc (
    idx INT PRIMARY KEY, state VARCHAR(100), municipality VARCHAR(100), city VARCHAR(100),
    locality VARCHAR(100), postal VARCHAR(10), colony VARCHAR(100));
INSERT INTO tmp_loc VALUES
 (0,  'Puebla',            'Xicotepec',         'Xicotepec de Juárez',   'Villa Ávila Camacho',  '73080', 'Centro'),
 (1,  'Ciudad de México',  'Cuauhtémoc',        'Ciudad de México',      'Doctores',             '06720', 'Doctores'),
 (2,  'Jalisco',           'Guadalajara',       'Guadalajara',           'Zona Centro',          '44100', 'Americana'),
 (3,  'Nuevo León',        'Monterrey',         'Monterrey',             'Obispado',             '64060', 'Obispado'),
 (4,  'Querétaro',         'Querétaro',         'Santiago de Querétaro', 'Centro Histórico',     '76000', 'Centro'),
 (5,  'Yucatán',           'Mérida',            'Mérida',                'Mérida Centro',        '97000', 'Centro'),
 (6,  'Veracruz',          'Xalapa',            'Xalapa-Enríquez',       'Xalapa Centro',        '91000', 'Centro'),
 (7,  'Guanajuato',        'León',              'León de los Aldama',    'León Centro',          '37000', 'Centro'),
 (8,  'Baja California',   'Tijuana',           'Tijuana',               'Zona Río',             '22010', 'Zona Río'),
 (9,  'Oaxaca',            'Oaxaca de Juárez',  'Oaxaca de Juárez',      'Centro',               '68000', 'Centro'),
 (10, 'Chihuahua',         'Chihuahua',         'Chihuahua',             'Centro',               '31000', 'Centro'),
 (11, 'Quintana Roo',      'Benito Juárez',     'Cancún',                'Supermanzana 22',      '77500', 'Supermanzana 22');

CREATE TEMPORARY TABLE tmp_street (idx INT PRIMARY KEY, name VARCHAR(100));
INSERT INTO tmp_street VALUES
 (0,'Av. Juárez'),(1,'Calle Hidalgo'),(2,'Av. Reforma'),(3,'Calle 5 de Mayo'),(4,'Calle Morelos'),
 (5,'Av. Insurgentes'),(6,'Calle Allende'),(7,'Av. Universidad'),(8,'Calle Zaragoza'),(9,'Calle Independencia');

CREATE TEMPORARY TABLE tmp_seed (
    address_ID BIGINT UNSIGNED PRIMARY KEY, loc INT, st INT, ext INT, int_no CHAR(1));
INSERT INTO tmp_seed
SELECT a.ID, MOD(a.user_ID, 12), MOD(a.user_ID DIV 12, 10), 100 + MOD(a.user_ID * 7, 900),
       IF(MOD(a.user_ID, 3) = 0, CHAR(65 + MOD(a.user_ID, 4)), NULL)
FROM tb_user_addresses a;

/* Los 10 niveles del árbol de cada domicilio se insertan con ID explícito
   (address_ID-1)*10 + nivel, de modo que cada domicilio queda en bloques
   consecutivos y el superior de cada nivel es siempre el ID anterior.
   El País (nivel 1) es la raíz y su address_sup_ID es NULL. */
INSERT INTO tbd_address_components (ID, address_ID, value, component_type, address_sup_ID)
SELECT (s.address_ID - 1) * 10 + n.lvl, s.address_ID,
       CASE n.lvl WHEN 1 THEN 'México'    WHEN 2 THEN l.state   WHEN 3 THEN l.municipality
                  WHEN 4 THEN l.city      WHEN 5 THEN l.locality WHEN 6 THEN l.postal
                  WHEN 7 THEN l.colony    WHEN 8 THEN st.name   WHEN 9 THEN CAST(s.ext AS CHAR)
                  ELSE s.int_no END,
       CASE n.lvl WHEN 1 THEN 'País'      WHEN 2 THEN 'Estado'  WHEN 3 THEN 'Municipio'
                  WHEN 4 THEN 'Ciudad'    WHEN 5 THEN 'Localidad' WHEN 6 THEN 'Código Postal'
                  WHEN 7 THEN 'Colonia'   WHEN 8 THEN 'Calle/Avenida' WHEN 9 THEN 'Número Exterior'
                  ELSE 'Número Interior' END,
       IF(n.lvl = 1, NULL, (s.address_ID - 1) * 10 + n.lvl - 1)
FROM tmp_seed s
JOIN tmp_loc l    ON l.idx = s.loc
JOIN tmp_street st ON st.idx = s.st
JOIN (SELECT 1 AS lvl UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
      UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
WHERE n.lvl < 10 OR s.int_no IS NOT NULL
ORDER BY s.address_ID, n.lvl;

/* Los siguientes ID automáticos continúan después de la carga masiva */
SET @next_id = (SELECT MAX(ID) + 1 FROM tbd_address_components);
SET @ddl = CONCAT('ALTER TABLE tbd_address_components AUTO_INCREMENT = ', @next_id);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @next_id = (SELECT MAX(ID) + 1 FROM tb_user_addresses);
SET @ddl = CONCAT('ALTER TABLE tb_user_addresses AUTO_INCREMENT = ', @next_id);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

DROP TEMPORARY TABLE tmp_seed;
DROP TEMPORARY TABLE tmp_street;
DROP TEMPORARY TABLE tmp_loc;
