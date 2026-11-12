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
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_buyer_orders TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_order_items TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_users_providers TO 'seller';

/* -------------------------
   USER NOT REGISTERED
   Rol activo por defecto de app_web / app_movil. Cubre los pasos 1 a 6 del
   flujo de compra: registro, consulta de productos, carrito, orden,
   domicilio y método de pago.
   ------------------------- */
-- Registro de credenciales y datos personales
GRANT INSERT ON db_test.tb_users TO 'user_not_registered';
GRANT INSERT ON db_test.tb_people TO 'user_not_registered';

-- Paso 1: consulta de productos disponibles y verificación de estatus
GRANT SELECT ON db_test.tb_products TO 'user_not_registered';
GRANT SELECT ON db_test.tbd_products_users_providers TO 'user_not_registered';
GRANT SELECT ON db_test.tbc_categories TO 'user_not_registered';
GRANT SELECT ON db_test.tbd_products_categories TO 'user_not_registered';
GRANT SELECT ON db_test.vw_available_products TO 'user_not_registered';

-- Pasos 2 y 3: carrito de compra e ítems
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tb_carts TO 'user_not_registered';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_cart_items TO 'user_not_registered';

-- Paso 4: orden de compra (la crea el procedimiento con permisos del definidor)
GRANT EXECUTE ON PROCEDURE db_test.sp_create_order_from_cart TO 'user_not_registered';
GRANT SELECT ON db_test.tb_orders TO 'user_not_registered';
GRANT SELECT ON db_test.tbd_buyer_orders TO 'user_not_registered';
GRANT SELECT ON db_test.tbd_order_items TO 'user_not_registered';

-- Paso 5: domicilio de envío
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tb_user_addresses TO 'user_not_registered';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_address_components TO 'user_not_registered';

-- Paso 6: método de pago (tarjeta) vinculado al usuario
GRANT SELECT ON db_test.tbc_payment_methods_types TO 'user_not_registered';
GRANT SELECT ON db_test.tb_payment_methods TO 'user_not_registered';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_user_payment_methods TO 'user_not_registered';

/* -------------------------
   BUYER (COMPRADOR)
   Se activa con SET ROLE al momento de pagar (paso 7). Los pasos 8 a 10 los
   ejecuta el sistema con los procedimientos sp_authorize_payment,
   sp_process_order y sp_deliver_order (rol admin / superadmin).
   ------------------------- */
-- Consulta y actualización de datos de cuenta e información personal
GRANT SELECT, UPDATE ON db_test.tb_users TO 'buyer';
GRANT SELECT, UPDATE ON db_test.tb_people TO 'buyer';

-- Catálogo de productos
GRANT SELECT ON db_test.tb_products TO 'buyer';
GRANT SELECT ON db_test.tbd_products_users_providers TO 'buyer';
GRANT SELECT ON db_test.tbc_categories TO 'buyer';
GRANT SELECT ON db_test.tbd_products_categories TO 'buyer';
GRANT SELECT ON db_test.vw_available_products TO 'buyer';

-- Carrito, órdenes, envíos y direcciones
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tb_carts TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_cart_items TO 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_create_order_from_cart TO 'buyer';
GRANT SELECT ON db_test.tb_orders TO 'buyer';
GRANT SELECT ON db_test.tbd_buyer_orders TO 'buyer';
GRANT SELECT ON db_test.tbd_order_items TO 'buyer';
GRANT SELECT ON db_test.tb_shipments TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tb_user_addresses TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_address_components TO 'buyer';

-- Métodos de pago y paso 7: registro del pago único de la orden
GRANT SELECT ON db_test.tb_payment_methods TO 'buyer';
GRANT SELECT ON db_test.tbc_payment_methods_types TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_user_payment_methods TO 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_register_payment TO 'buyer';
GRANT SELECT ON db_test.tb_payments TO 'buyer';
GRANT SELECT ON db_test.tb_payment_transaction TO 'buyer';

-- Se retiran permisos de versiones anteriores que permitían al comprador
-- marcar sus propios pagos u órdenes como pagados
REVOKE IF EXISTS INSERT, UPDATE ON db_test.tb_orders FROM 'buyer';
REVOKE IF EXISTS INSERT, UPDATE ON db_test.tb_seller_orders FROM 'buyer';
REVOKE IF EXISTS INSERT, UPDATE ON db_test.tbd_order_items FROM 'buyer';
REVOKE IF EXISTS INSERT, UPDATE ON db_test.tb_shipments FROM 'buyer';
REVOKE IF EXISTS INSERT, UPDATE ON db_test.tb_payments FROM 'buyer';
REVOKE IF EXISTS INSERT, UPDATE ON db_test.tb_payment_transaction FROM 'buyer';
REVOKE IF EXISTS SELECT, INSERT, UPDATE ON db_test.tb_seller_orders FROM 'seller';


/* -------------------------
   PRÁCTICA 04: PROCEDIMIENTOS, VISTAS Y TABLAS DEL FLUJO COMPLETO
   Los procedimientos que escriben tablas sin privilegio directo se ejecutan
   con los permisos del definidor (SQL SECURITY DEFINER); sp_register_address
   es SQL SECURITY INVOKER y usa los privilegios propios del rol.
   Los pasos del sistema (autorizar pago, atender, enviar, entregar, reembolsar,
   reenviar) los ejecuta adrian.rios (superadmin) / admin; no se otorgan a
   los roles de la aplicación.
   ------------------------- */
GRANT EXECUTE ON PROCEDURE db_test.sp_register_address        TO 'user_not_registered', 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_set_order_address       TO 'user_not_registered', 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_request_item_cancellation TO 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_request_return          TO 'buyer';
GRANT SELECT ON db_test.vw_cart_to_order        TO 'user_not_registered', 'buyer';
GRANT SELECT ON db_test.vw_user_addresses_full  TO 'user_not_registered', 'buyer';
GRANT SELECT ON db_test.vw_order_detail         TO 'user_not_registered', 'buyer';
GRANT SELECT ON db_test.tb_gift_coupons         TO 'buyer';
GRANT SELECT ON db_test.tb_order_cancellations  TO 'buyer';
GRANT SELECT ON db_test.tbd_cancellation_items  TO 'buyer';
GRANT SELECT ON db_test.tb_refunds              TO 'buyer';
GRANT SELECT ON db_test.tb_returns              TO 'buyer';
GRANT SELECT ON db_test.tbd_return_items        TO 'buyer';

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

-- Las apps inician sesión solo con user_not_registered; el rol buyer se activa
-- con SET ROLE 'buyer' al registrar el pago (paso 7).
SET DEFAULT ROLE 'user_not_registered' TO 'app_web'@'%';
SET DEFAULT ROLE 'user_not_registered' TO 'app_movil'@'%';


/* ============================================================
   8. REFRESCAR PRIVILEGIOS
   ============================================================ */

FLUSH PRIVILEGES;


/* ============================================================
   9. MENSAJE DE CONFIRMACIÓN
   ============================================================ */

SELECT 'Los usuarios, roles y privilegios para el proceso de compra han sido actualizados correctamente' AS mensaje;