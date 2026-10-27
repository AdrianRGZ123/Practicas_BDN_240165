#!/bin/bash
# Uso (en el VPS): bash scripts/04_casos_prueba_postgres.sh
# Ejecuta cada caso con su cuenta real. Los "ESPERADO: ERROR" son la prueba de que el privilegio se niega.
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
mkdir -p evidencias
exec > >(tee evidencias/postgresql_casos_prueba.log) 2>&1

# Se conecta por la IP del contenedor (no por localhost) para que PostgreSQL exija contrasena.
H=$(docker exec postgres40165 hostname -i | awk '{print $1}')
q() { # usuario sql
  echo; echo ">>> [$1] $2"
  docker exec -i -e PGPASSWORD="$PW_PERSONAL" postgres40165 psql -X -h "$H" -p 40165 -U "$1" -d db_test -c "$2" 2>&1
}
ROOT=adrian_rios; NOROL=jose_maria; SUP=carlos_rene; V1=juan_pablo; V2=erick_uriel
echo "Servidor: $(docker exec postgres40165 psql -X -U postgres -p 40165 -Atc 'select version()' | cut -c1-40)  | fecha: $(date '+%F %T')"

echo; echo "######## CASO 01: superadmin (adrian_rios) inserta 3 usuarios"
for i in 1 2 3; do q $ROOT "INSERT INTO tb_users (email,nickname,password) VALUES ('root_u$i@test.com','root_u$i',md5('Pass123*'));"; done
echo; echo "######## CASO 02: usuario SIN ROL (jose_maria) inserta 3 usuarios"
for i in 1 2 3; do q $NOROL "INSERT INTO tb_users (email,nickname,password) VALUES ('norol_u$i@test.com','norol_u$i',md5('Pass123*'));"; done
echo; echo "######## CASO 03: support (carlos_rene) inserta 3 usuarios (funcion sp_register_user_with_person)"
for i in 1 2 3; do q $SUP "SELECT sp_register_user_with_person('support_u$i@test.com','support_u$i','Pass123*','Sr','Support$i','Prueba','2000-01-0$i',1::smallint,'MX','555000000$i');"; done
echo; echo "######## CASO 04: superadmin modifica y elimina un usuario que no es el suyo"
q $ROOT "UPDATE tb_users SET nickname='norol_u1_mod' WHERE email='norol_u1@test.com';"
q $ROOT "DELETE FROM tb_users WHERE email='norol_u3@test.com';"
echo; echo "######## CASO 05: usuario SIN ROL intenta modificar y eliminar (ESPERADO: ERROR permission denied)"
q $NOROL "UPDATE tb_users SET nickname='hack' WHERE email='root_u1@test.com';"
q $NOROL "DELETE FROM tb_users WHERE email='root_u1@test.com';"
echo; echo "######## CASO 06: support modifica (permitido) y elimina (ESPERADO: ERROR en el DELETE)"
q $SUP "UPDATE tb_users SET nickname='root_u2_mod_support' WHERE email='root_u2@test.com';"
q $SUP "DELETE FROM tb_users WHERE email='root_u2@test.com';"
echo; echo "######## CASO 07: superadmin inserta 2 productos"
q $ROOT "INSERT INTO tb_products (sku,name,description,current_price,current_stock) VALUES ('ROOT-0001','Producto root 1','Insertado por root',100.00,10),('ROOT-0002','Producto root 2','Insertado por root',200.00,20);"
echo; echo "######## CASO 08: seller 1 (juan_pablo) inserta 5 productos"
q $V1 "INSERT INTO tb_products (sku,name,description,current_price,current_stock) VALUES ('V1-0001','Producto V1-1','Vendedor 1',10.00,5),('V1-0002','Producto V1-2','Vendedor 1',20.00,5),('V1-0003','Producto V1-3','Vendedor 1',30.00,5),('V1-0004','Producto V1-4','Vendedor 1',40.00,5),('V1-0005','Producto V1-5','Vendedor 1',50.00,5);"
echo; echo "######## CASO 09: seller 2 (erick_uriel) importa los 5000 productos del CSV"
docker cp seeds/tb_products_5000.csv postgres40165:/tmp/tb_products_5000.csv
echo ">>> [$V2] CREATE TEMP TABLE + \copy del CSV + INSERT ... SELECT"
docker exec -i -e PGPASSWORD="$PW_PERSONAL" postgres40165 psql -X -h "$H" -p 40165 -U $V2 -d db_test -v ON_ERROR_STOP=1 <<'SQL' 2>&1
CREATE TEMP TABLE stg (id int, sku varchar(50), name varchar(250), description text, current_price numeric(10,2), current_stock int, status int, creation_date timestamp, last_update timestamp);
\copy stg FROM '/tmp/tb_products_5000.csv' WITH (FORMAT csv, HEADER true)
INSERT INTO tb_products (sku,name,description,current_price,current_stock,status,creation_date,last_update)
  SELECT sku,name,description,current_price,current_stock,(status=1),creation_date,last_update FROM stg;
SQL

echo; echo "######## RESUMEN Y TRAZABILIDAD (adrian_rios)"
q $ROOT "SELECT (SELECT count(*) FROM tb_users) AS usuarios, (SELECT count(*) FROM tb_people) AS personas, (SELECT count(*) FROM tb_products) AS productos;"
q $ROOT "SELECT id,email,nickname,status FROM tb_users ORDER BY id;"
q $ROOT "SELECT db_user, operation, table_name, count(*) FROM tb_logs GROUP BY 1,2,3 ORDER BY 1,3,2;"
q $ROOT "SELECT id, operation, db_user, left(description,90) AS description FROM vw_trazabilidad_usuarios ORDER BY id LIMIT 6;"
q $ROOT "SELECT count(*) AS productos_en_vista_trazabilidad FROM vw_trazabilidad_productos;"
