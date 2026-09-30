/*CREACION DE USUARIOS REMOTOS*/

CREATE USER IF NOT EXISTS 'adrian.rios'@'%' IDENTIFIED BY '240165';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'carlos.rene'@'%' IDENTIFIED BY '240221';
CREATE USER IF NOT EXISTS 'juan.pablo'@'%' IDENTIFIED BY '240148';
CREATE USER IF NOT EXISTS 'jose.maria'@'%' IDENTIFIED BY '240628';
CREATE USER IF NOT EXISTS 'luis.mua'@'%' IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'erick.uriel'@'%' IDENTIFIED BY '240485';

/*ASIGNACION DE PRIVILEGIOS DEL SUPER USUARIO IMPORTANTE: SOLO USTEDES*/
GRANT ALL PRIVILEGES ON *.* TO 'adrian.rios'@'%' WITH GRANT OPTION;

/*CREACIÓN DE ROLES PARA LOS USUARIOS DE LA PLATAFORMA DE ECOMMERCE*/
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';
CREATE ROLE IF NOT EXISTS 'support';

/*ASIGNACIÓN DE PRIVILEGIOS A LOS ROLES DE LA PLATAFORMA DE ECOMMERCE*/

-- ADMIN
GRANT ALL PRIVILEGES ON *.* TO 'superadmin';
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

-- SUPPORT
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.* TO 'jose.maria'@'%';
 
 -- Seller
 GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';


/*ASIGNAR EL ROL AL USUARIO*/

-- Este deben ser ustedes
GRANT 'superadmin' TO 'adrian.rios'@'%';

-- Soporte
GRANT 'admin' TO 'marco.ramirez'@'%';

GRANT 'support' TO 'carlos.rene'@'%';
GRANT 'seller' TO 'juan.pablo'@'%';
GRANT 'seller' TO 'erick.uriel'@'%';


/*6. Esto permite que el rol se active automaticamente cuando el usuario inicia sesión*/

SET DEFAULT ROLE 'superadmin'
TO 'adrian.rios'@'%';

SET DEFAULT ROLE 'admin'
TO 'marco.ramirez'@'%';

SET DEFAULT ROLE 'support'
TO 'carlos.rene'@'%';

SET DEFAULT ROLE 'seller'
TO 'juan.pablo'@'%';

SET DEFAULT ROLE 'seller'
TO 'erick.uriel'@'%';

-- 7. REFRESCAR PRIVILEGIOS Y MENSAJE DE CONFIRMACION
FLUSH PRIVILEGES;

SELECT "Los usuarios y privilegios han sido creados correctamente" AS mensaje;

SELECT COUNT(*) AS total_registros From tb_logs

--6 verificar que los usuarios remotos hayan sido creados
SELECT User,Host FROM mysql.user WHERE Host = '%' AND account_locked= 'N';

--7 verificarlos roles que fueron creados 
SELECT User,Host FROM mysql.user WHERE Host = '%' AND account_locked= 'Y';

/*8. Verificar que usuarios tienen que roles */
SELECT TO_USER AS usuario, TO_HOST AS host, FROM_USER AS rol, FROM_HOST AS rol_host
FROM mysql.role_edges ORDER BY TO_USER, FROM_USER;

/*9. Verificar el total de procedimientos almacenados que existen en la base de datos db_test */
SHOW PROCEDURE STATUS WHERE Db = 'db_test';