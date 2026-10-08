/* ============================================================
   1. CREACIÓN DE USUARIOS REMOTOS
   ============================================================ */

CREATE USER IF NOT EXISTS 'adrian.rios'@'%' IDENTIFIED BY '240165';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'carlos.rene'@'%' IDENTIFIED BY '240221';
CREATE USER IF NOT EXISTS 'juan.pablo'@'%' IDENTIFIED BY '240148';
CREATE USER IF NOT EXISTS 'jose.maria'@'%' IDENTIFIED BY '240628';
CREATE USER IF NOT EXISTS 'luis.mua'@'%' IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'erick.uriel'@'%' IDENTIFIED BY '240485';


/* ============================================================
   2. PRIVILEGIOS DEL SUPERUSUARIO
   SOLO ADRIAN
   ============================================================ */

GRANT ALL PRIVILEGES
ON *.*
TO 'adrian.rios'@'%'
WITH GRANT OPTION;


/* ============================================================
   3. CREACIÓN DE ROLES
   ============================================================ */

CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';
CREATE ROLE IF NOT EXISTS 'support';


/* ============================================================
   4. PRIVILEGIOS DE LOS ROLES
   ============================================================ */


/* -------------------------
   SUPERADMIN
   ------------------------- */

GRANT ALL PRIVILEGES
ON *.*
TO 'superadmin';


/* -------------------------
   ADMIN
   ------------------------- */

GRANT ALL PRIVILEGES
ON db_test.*
TO 'admin';


/* -------------------------
   SUPPORT
   ------------------------- */

GRANT SELECT, UPDATE
ON db_test.tb_users
TO 'support';

GRANT SELECT, UPDATE
ON db_test.tb_products
TO 'support';

GRANT SELECT, INSERT, UPDATE
ON db_test.tbc_categories
TO 'support';

/* Permite ejecutar procedimientos almacenados */
GRANT EXECUTE
ON db_test.*
TO 'support';


/* -------------------------
   SELLER
   ------------------------- */

GRANT SELECT, INSERT, UPDATE
ON db_test.tb_products
TO 'seller';


/* ============================================================
   5. ASIGNACIÓN DE ROLES A LOS USUARIOS
   ============================================================ */


/* -------------------------
   SUPERADMIN
   ------------------------- */

GRANT 'superadmin'
TO 'adrian.rios'@'%';


/* -------------------------
   ADMIN
   ------------------------- */

GRANT 'admin'
TO 'marco.ramirez'@'%';


/* -------------------------
   SUPPORT
   ------------------------- */

GRANT 'support'
TO 'carlos.rene'@'%';


/* -------------------------
   SELLER
   ------------------------- */

GRANT 'seller'
TO 'juan.pablo'@'%';

GRANT 'seller'
TO 'erick.uriel'@'%';


/* ============================================================
   6. ACTIVAR ROLES AUTOMÁTICAMENTE AL INICIAR SESIÓN
   ============================================================ */

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


/* ============================================================
   7. REFRESCAR PRIVILEGIOS
   ============================================================ */

FLUSH PRIVILEGES;


/* ============================================================
   8. MENSAJE DE CONFIRMACIÓN
   ============================================================ */

SELECT
    'Los usuarios, roles y privilegios han sido creados correctamente'
    AS mensaje;