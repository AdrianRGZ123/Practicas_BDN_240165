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
CREATE USER IF NOT EXISTS 'app_web'@'%' IDENTIFIED BY 'Web123';
CREATE USER IF NOT EXISTS 'app_movil'@'%' IDENTIFIED BY 'Mobile890';


/* ============================================================
   2. PRIVILEGIOS DEL SUPERUSUARIO
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
GRANT ALL PRIVILEGES ON *.* TO 'superadmin';

/* -------------------------
   ADMIN
   ------------------------- */
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

/* -------------------------
   SUPPORT
   ------------------------- */
GRANT SELECT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, UPDATE ON db_test.tb_products TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories TO 'support';
GRANT EXECUTE ON db_test.* TO 'support';

/* -------------------------
   SELLER
   ------------------------- */
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_seller_orders TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_order_items TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_users_providers TO 'seller';

/* -------------------------
   USER NOT REGISTERED
   ------------------------- */
-- Paso 1: Registro de credenciales y datos personales
GRANT INSERT ON db_test.tb_users TO 'user_not_registered';
GRANT INSERT ON db_test.tb_people TO 'user_not_registered';

/* -------------------------
   BUYER (COMPRADOR)
   ------------------------- */
-- Consulta y actualización de datos de cuenta e información personal
GRANT SELECT, UPDATE ON db_test.tb_users TO 'buyer';
GRANT SELECT, UPDATE ON db_test.tb_people TO 'buyer';

-- Paso 2: Consulta de catálogo de productos, disponibilidad por proveedor y categorías
GRANT SELECT ON db_test.tb_products TO 'buyer';
GRANT SELECT ON db_test.tbd_products_users_providers TO 'buyer';
GRANT SELECT ON db_test.tbc_categories TO 'buyer';
GRANT SELECT ON db_test.tbd_products_categories TO 'buyer';

-- Pasos 3 y 4: Creación, lectura, actualización y limpieza de carrito de compras e ítems
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tb_carts TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_cart_items TO 'buyer';

-- Pasos 5 y 10: Generación y actualización de ordenes de compra e ítems asociados
GRANT SELECT, INSERT, UPDATE ON db_test.tb_orders TO 'buyer';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_seller_orders TO 'buyer';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_order_items TO 'buyer';

-- Paso 6: Registro de direcciones de envío y componentes de domicilio
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tb_user_addresses TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_address_components TO 'buyer';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_shipments TO 'buyer';

-- Paso 7: Consulta de catálogo de métodos de pago y registro de tarjeta de débito vinculada
GRANT SELECT ON db_test.tb_payment_methods TO 'buyer';
GRANT SELECT ON db_test.tbc_payment_methods_types TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_user_payment_methods TO 'buyer';

-- Pasos 8 y 9: Registro y autorización de pagos y transacciones bancarias
GRANT SELECT, INSERT, UPDATE ON db_test.tb_payments TO 'buyer';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_payment_transaction TO 'buyer';


/* ============================================================
   5. PERMISOS ESPECÍFICOS DIRECTOS
   ============================================================ */

GRANT INSERT ON db_test.tb_users TO 'jose.maria'@'%';
GRANT INSERT ON db_test.tb_people TO 'jose.maria'@'%';


/* ============================================================
   6. ASIGNACIÓN DE ROLES A LOS USUARIOS
   ============================================================ */

GRANT 'superadmin' TO 'adrian.rios'@'%';
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'carlos.rene'@'%';
GRANT 'seller' TO 'juan.pablo'@'%', 'erick.uriel'@'%';

-- Los usuarios de conexión de las apps reciben los roles necesarios para el ciclo completo
GRANT 'user_not_registered', 'buyer' TO 'app_web'@'%';
GRANT 'user_not_registered', 'buyer' TO 'app_movil'@'%';


/* ============================================================
   7. ACTIVAR ROLES AUTOMÁTICAMENTE AL INICIAR SESIÓN
   ============================================================ */

SET DEFAULT ROLE 'superadmin' TO 'adrian.rios'@'%';
SET DEFAULT ROLE 'admin' TO 'marco.ramirez'@'%';
SET DEFAULT ROLE 'support' TO 'carlos.rene'@'%';
SET DEFAULT ROLE 'seller' TO 'juan.pablo'@'%', 'erick.uriel'@'%';

-- Activación por defecto de los roles para los usuarios de la aplicación
SET DEFAULT ROLE 'user_not_registered', 'buyer' TO 'app_web'@'%';
SET DEFAULT ROLE 'user_not_registered', 'buyer' TO 'app_movil'@'%';


/* ============================================================
   8. REFRESCAR PRIVILEGIOS
   ============================================================ */

FLUSH PRIVILEGES;


/* ============================================================
   9. MENSAJE DE CONFIRMACIÓN
   ============================================================ */

SELECT 'Los usuarios, roles y privilegios para el proceso de compra han sido actualizados correctamente' AS mensaje;