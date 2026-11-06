/* ============================================================
   PRÁCTICA 03 · Usuarios remotos, roles y privilegios (db_test)
   Roles: superadmin, admin, support, seller, buyer, common_user, user_not_registered
   Privilegios definidos sobre las 24 tablas operativas (tb_logs solo la lee la auditoría).
   Ejecutar con una cuenta administradora (root / adrian.rios).

   CREDENCIALES: las contraseñas NO se guardan en el repositorio. Sustituya cada
   'CAMBIAR_ANTES_DE_EJECUTAR' por la contraseña real o use ALTER USER después.
   ============================================================ */
USE db_test;

/* ============================================================
   1. USUARIOS REMOTOS
   ============================================================ */
CREATE USER IF NOT EXISTS 'adrian.rios'@'%'   IDENTIFIED BY 'CAMBIAR_ANTES_DE_EJECUTAR';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'CAMBIAR_ANTES_DE_EJECUTAR';
CREATE USER IF NOT EXISTS 'carlos.rene'@'%'   IDENTIFIED BY 'CAMBIAR_ANTES_DE_EJECUTAR';
CREATE USER IF NOT EXISTS 'juan.pablo'@'%'    IDENTIFIED BY 'CAMBIAR_ANTES_DE_EJECUTAR';   -- seller1
CREATE USER IF NOT EXISTS 'erick.uriel'@'%'   IDENTIFIED BY 'CAMBIAR_ANTES_DE_EJECUTAR';   -- seller2
CREATE USER IF NOT EXISTS 'jose.maria'@'%'    IDENTIFIED BY 'CAMBIAR_ANTES_DE_EJECUTAR';
CREATE USER IF NOT EXISTS 'luis.mua'@'%'      IDENTIFIED BY 'CAMBIAR_ANTES_DE_EJECUTAR';
CREATE USER IF NOT EXISTS 'app_web'@'%'       IDENTIFIED BY 'CAMBIAR_ANTES_DE_EJECUTAR';
CREATE USER IF NOT EXISTS 'app_movil'@'%'     IDENTIFIED BY 'CAMBIAR_ANTES_DE_EJECUTAR';

/* Superusuario: solo Adrián */
GRANT ALL PRIVILEGES ON *.* TO 'adrian.rios'@'%' WITH GRANT OPTION;

/* ============================================================
   2. ROLES
   ============================================================ */
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'support';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';

/* ============================================================
   3. PRIVILEGIOS POR ROL
   ============================================================ */

/* ---- superadmin: todo el servidor ---- */
GRANT ALL PRIVILEGES ON *.* TO 'superadmin';

/* ---- admin: toda la base db_test (tablas, vistas, rutinas) ---- */
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

/* ---- support: consulta general, actualiza cuentas/productos/categorías/pedidos y ejecuta rutinas ---- */
GRANT SELECT ON db_test.* TO 'support';                          -- tablas y vistas de trazabilidad
GRANT UPDATE ON db_test.tb_users               TO 'support';
GRANT UPDATE ON db_test.tb_people              TO 'support';
GRANT UPDATE ON db_test.tb_products            TO 'support';
GRANT INSERT, UPDATE ON db_test.tbc_categories TO 'support';
GRANT UPDATE ON db_test.tb_orders              TO 'support';
GRANT UPDATE ON db_test.tb_shipments           TO 'support';
GRANT UPDATE ON db_test.tb_returns             TO 'support';
GRANT UPDATE ON db_test.tb_refunds             TO 'support';
GRANT UPDATE ON db_test.tb_order_cancellations TO 'support';
GRANT EXECUTE ON db_test.*                     TO 'support';

/* ---- seller: administra sus productos y atiende pedidos ---- */
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products                  TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_categories      TO 'seller';
GRANT SELECT, INSERT, UPDATE ON db_test.tbd_products_users_providers TO 'seller';
GRANT SELECT ON db_test.tbc_categories     TO 'seller';
GRANT SELECT, UPDATE ON db_test.tbd_buyer_orders TO 'seller';
GRANT SELECT ON db_test.tbd_order_items    TO 'seller';
GRANT SELECT, UPDATE ON db_test.tb_shipments TO 'seller';
GRANT SELECT ON db_test.tbd_cancellation_items TO 'seller';
GRANT SELECT ON db_test.tbd_return_items   TO 'seller';
GRANT SELECT ON db_test.vw_trazabilidad_productos TO 'seller';
GRANT SELECT ON db_test.vw_total_products_by_category TO 'seller';
GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_product TO 'seller';
GRANT EXECUTE ON PROCEDURE db_test.sp_restore_product     TO 'seller';

/* ---- buyer: compra (carrito, pedidos, pagos, devoluciones) ---- */
GRANT SELECT ON db_test.tb_products                  TO 'buyer';
GRANT SELECT ON db_test.tbc_categories               TO 'buyer';
GRANT SELECT ON db_test.tbd_products_categories      TO 'buyer';
GRANT SELECT ON db_test.tbd_products_users_providers TO 'buyer';
GRANT SELECT ON db_test.tbc_payment_methods_types    TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tb_carts                    TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_cart_items              TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_users_wishlist_products TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tb_user_addresses           TO 'buyer';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_address_components      TO 'buyer';
GRANT SELECT, INSERT, UPDATE         ON db_test.tbd_user_payment_methods    TO 'buyer';
GRANT SELECT, UPDATE ON db_test.tb_users  TO 'buyer';
GRANT SELECT, UPDATE ON db_test.tb_people TO 'buyer';
GRANT SELECT ON db_test.tb_orders          TO 'buyer';
GRANT SELECT ON db_test.tbd_buyer_orders   TO 'buyer';
GRANT SELECT ON db_test.tbd_order_items    TO 'buyer';
GRANT SELECT ON db_test.tb_payments        TO 'buyer';
GRANT SELECT ON db_test.tb_payment_transaction TO 'buyer';
GRANT SELECT ON db_test.tb_shipments       TO 'buyer';
GRANT SELECT ON db_test.tb_refunds         TO 'buyer';
GRANT SELECT, INSERT ON db_test.tb_order_cancellations TO 'buyer';
GRANT SELECT, INSERT ON db_test.tbd_cancellation_items TO 'buyer';
GRANT SELECT, INSERT ON db_test.tb_returns             TO 'buyer';
GRANT SELECT, INSERT ON db_test.tbd_return_items       TO 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_create_order_from_cart TO 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_register_payment       TO 'buyer';
GRANT EXECUTE ON PROCEDURE db_test.sp_authorize_payment      TO 'buyer';

/* ---- common_user: cuenta registrada que solo explora el catálogo y administra su perfil/lista de deseos ---- */
GRANT SELECT ON db_test.tb_products                  TO 'common_user';
GRANT SELECT ON db_test.tbc_categories               TO 'common_user';
GRANT SELECT ON db_test.tbd_products_categories      TO 'common_user';
GRANT SELECT ON db_test.vw_total_products_by_category TO 'common_user';
GRANT SELECT, UPDATE ON db_test.tb_users             TO 'common_user';
GRANT SELECT, UPDATE ON db_test.tb_people            TO 'common_user';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_test.tbd_users_wishlist_products TO 'common_user';

/* ---- user_not_registered: solo puede registrarse ---- */
GRANT INSERT ON db_test.tb_users  TO 'user_not_registered';
GRANT INSERT ON db_test.tb_people TO 'user_not_registered';
GRANT EXECUTE ON PROCEDURE db_test.sp_register_user_with_person TO 'user_not_registered';

/* Usuario sin rol con permiso directo de registro */
GRANT INSERT ON db_test.tb_users  TO 'jose.maria'@'%';
GRANT INSERT ON db_test.tb_people TO 'jose.maria'@'%';

/* ============================================================
   4. ASIGNACIÓN DE ROLES
   ============================================================ */
GRANT 'superadmin' TO 'adrian.rios'@'%';
GRANT 'admin'      TO 'marco.ramirez'@'%';
GRANT 'support'    TO 'carlos.rene'@'%';
GRANT 'seller'     TO 'juan.pablo'@'%';     -- seller1
GRANT 'seller'     TO 'erick.uriel'@'%';    -- seller2
GRANT 'buyer', 'common_user' TO 'luis.mua'@'%';
GRANT 'user_not_registered'  TO 'app_web'@'%';
GRANT 'user_not_registered'  TO 'app_movil'@'%';

/* ============================================================
   5. ROLES ACTIVOS AL INICIAR SESIÓN
   ============================================================ */
SET DEFAULT ROLE 'superadmin'  TO 'adrian.rios'@'%';
SET DEFAULT ROLE 'admin'       TO 'marco.ramirez'@'%';
SET DEFAULT ROLE 'support'     TO 'carlos.rene'@'%';
SET DEFAULT ROLE 'seller'      TO 'juan.pablo'@'%';
SET DEFAULT ROLE 'seller'      TO 'erick.uriel'@'%';
SET DEFAULT ROLE 'buyer'       TO 'luis.mua'@'%';
SET DEFAULT ROLE 'user_not_registered' TO 'app_web'@'%';
SET DEFAULT ROLE 'user_not_registered' TO 'app_movil'@'%';

FLUSH PRIVILEGES;

/* ============================================================
   6. VERIFICACIÓN (privilegios, roles asignados y roles activos)
   ============================================================ */
SELECT FROM_USER AS rol, TO_USER AS usuario, TO_HOST AS host FROM mysql.role_edges ORDER BY FROM_USER, TO_USER;
SELECT USER, HOST, DEFAULT_ROLE_USER AS rol_predeterminado FROM mysql.default_roles ORDER BY USER;
SHOW GRANTS FOR 'seller';
SHOW GRANTS FOR 'buyer';
SHOW GRANTS FOR 'common_user';
SHOW GRANTS FOR 'user_not_registered';
SELECT CURRENT_USER() AS cuenta, CURRENT_ROLE() AS rol_activo;   -- ejecutar desde cada conexión remota

SELECT 'Los usuarios, roles y privilegios han sido creados correctamente' AS mensaje;
