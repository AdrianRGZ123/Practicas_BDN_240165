/* Practica 04 - Ejercicios. Ejecutar cada bloque con el usuario indicado:
   mysql -P 40166 -u USUARIO -p db_test
   root = adrian.rios (superadmin) | sin rol = jose.maria | support = carlos.rene
   vendedor 1 = juan.pablo | vendedor 2 = erick.uriel                         */
USE db_test;

/* ---------- EJ 1: ROOT inserta 3 usuarios ---------- */
INSERT INTO tb_users (email,nickname,password) VALUES ('root_u1@test.com','root_u1','Pass123*');
INSERT INTO tb_users (email,nickname,password) VALUES ('root_u2@test.com','root_u2','Pass123*');
INSERT INTO tb_users (email,nickname,password) VALUES ('root_u3@test.com','root_u3','Pass123*');

/* ---------- EJ 2: SIN ROL (jose.maria) inserta 3 usuarios ---------- */
INSERT INTO tb_users (email,nickname,password) VALUES ('norol_u1@test.com','norol_u1','Pass123*');
INSERT INTO tb_users (email,nickname,password) VALUES ('norol_u2@test.com','norol_u2','Pass123*');
INSERT INTO tb_users (email,nickname,password) VALUES ('norol_u3@test.com','norol_u3','Pass123*');

/* ---------- EJ 3: SUPPORT (carlos.rene) inserta 3 usuarios (tiene EXECUTE, no INSERT directo) ----------
   Ver firma del procedimiento: SHOW CREATE PROCEDURE sp_register_user_with_person; */
CALL sp_register_user_with_person('support_u1@test.com','support_u1','Pass123*','Sr','Support1','Prueba','2000-01-01',1,'MX','5550000001');  -- x3

/* ---------- EJ 4: ROOT modifica y elimina un usuario que no sea el suyo ---------- */
UPDATE tb_users SET nickname='root_u1_mod' WHERE email='norol_u1@test.com';
DELETE FROM tb_users WHERE email='norol_u3@test.com';

/* ---------- EJ 5: SIN ROL intenta modificar y eliminar (debe DENEGAR) ---------- */
UPDATE tb_users SET nickname='hack' WHERE email='root_u1@test.com';   -- ERROR 1142 esperado
DELETE FROM tb_users WHERE email='root_u1@test.com';                  -- ERROR 1142 esperado

/* ---------- EJ 6: SUPPORT modifica (permitido) y elimina (debe DENEGAR) ---------- */
UPDATE tb_users SET nickname='support_mod' WHERE email='root_u2@test.com';  -- OK
DELETE FROM tb_users WHERE email='root_u2@test.com';                        -- ERROR 1142 esperado

/* ---------- EJ 7: ROOT inserta 2 productos ---------- */
INSERT INTO tb_products (sku,name,description,current_price,current_stock) VALUES ('ROOT-0001','Producto root 1','Insertado por root',100.00,10);
INSERT INTO tb_products (sku,name,description,current_price,current_stock) VALUES ('ROOT-0002','Producto root 2','Insertado por root',200.00,20);

/* ---------- EJ 8: VENDEDOR 1 (juan.pablo) inserta 5 productos ---------- */
INSERT INTO tb_products (sku,name,description,current_price,current_stock) VALUES
('V1-0001','Producto V1-1','Vendedor 1',10.00,5),('V1-0002','Producto V1-2','Vendedor 1',20.00,5),
('V1-0003','Producto V1-3','Vendedor 1',30.00,5),('V1-0004','Producto V1-4','Vendedor 1',40.00,5),
('V1-0005','Producto V1-5','Vendedor 1',50.00,5);

/* ---------- EJ 9: VENDEDOR 2 (erick.uriel) importa los 5000 productos del CSV ----------
   Conectar con: mysql --local-infile=1 -P 40166 -u erick.uriel -p db_test  (CSV en el VPS)  */
LOAD DATA LOCAL INFILE '/home/user240165/tb_products_5000.csv'
INTO TABLE tb_products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@id, sku, name, description, current_price, current_stock, @st, creation_date, last_update)
SET status = @st + 0;

SELECT COUNT(*) AS total_productos FROM tb_products;
