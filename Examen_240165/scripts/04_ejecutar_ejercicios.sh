#!/bin/bash
# Uso (en el VPS): bash ~/Examen_240165/scripts/04_ejecutar_ejercicios.sh
# Ejecuta cada ejercicio con el usuario indicado. Los ERROR 1142 marcados "ESPERADO" son la prueba de que el permiso se niega.
OUT=~/Examen_240165/queries/ejercicios_mysql_40166.log
exec > >(tee "$OUT") 2>&1
run() { # usuario password sql
  echo; echo ">>> [$1] $3"
  docker exec -i mysql40166 mysql -h127.0.0.1 -P40166 -u"$1" -p"$2" --local-infile=1 db_test -e "$3" 2>&1 | grep -v "Using a password"
}
ROOT=adrian.rios;   RP=240165      # superadmin (root de la practica)
NOROL=jose.maria;   NP=240628      # sin rol
SUP=carlos.rene;    SP=240221      # support
V1=juan.pablo;      V1P=240148     # vendedor 1
V2=erick.uriel;     V2P=240485     # vendedor 2

echo "######## EJ1: ROOT inserta 3 usuarios"
for i in 1 2 3; do run $ROOT $RP "INSERT INTO tb_users (email,nickname,password) VALUES ('root_u$i@test.com','root_u$i',MD5('Pass123*'));"; done
echo "######## EJ2: SIN ROL inserta 3 usuarios"
for i in 1 2 3; do run $NOROL $NP "INSERT INTO tb_users (email,nickname,password) VALUES ('norol_u$i@test.com','norol_u$i',MD5('Pass123*'));"; done
echo "######## EJ3: SUPPORT inserta 3 usuarios (via sp_register_user_with_person, solo tiene EXECUTE)"
for i in 1 2 3; do run $SUP $SP "CALL sp_register_user_with_person('support_u$i@test.com','support_u$i','Pass123*','Sr','Support$i','Prueba','2000-01-0$i',1,'MX','555000000$i');"; done
echo "######## EJ4: ROOT modifica y elimina un usuario que no es el suyo"
run $ROOT $RP "UPDATE tb_users SET nickname='norol_u1_mod' WHERE email='norol_u1@test.com';"
run $ROOT $RP "DELETE FROM tb_users WHERE email='norol_u3@test.com';"
echo "######## EJ5: SIN ROL intenta modificar y eliminar (ESPERADO: ERROR 1142)"
run $NOROL $NP "UPDATE tb_users SET nickname='hack' WHERE email='root_u1@test.com';"
run $NOROL $NP "DELETE FROM tb_users WHERE email='root_u1@test.com';"
echo "######## EJ6: SUPPORT modifica (permitido) y elimina (ESPERADO: ERROR 1142 en el DELETE)"
run $SUP $SP "UPDATE tb_users SET nickname='root_u2_mod_support' WHERE email='root_u2@test.com';"
run $SUP $SP "DELETE FROM tb_users WHERE email='root_u2@test.com';"
echo "######## EJ7: ROOT inserta 2 productos"
run $ROOT $RP "INSERT INTO tb_products (sku,name,description,current_price,current_stock) VALUES ('ROOT-0001','Producto root 1','Insertado por root',100.00,10),('ROOT-0002','Producto root 2','Insertado por root',200.00,20);"
echo "######## EJ8: VENDEDOR 1 inserta 5 productos"
run $V1 $V1P "INSERT INTO tb_products (sku,name,description,current_price,current_stock) VALUES ('V1-0001','Producto V1-1','Vendedor 1',10.00,5),('V1-0002','Producto V1-2','Vendedor 1',20.00,5),('V1-0003','Producto V1-3','Vendedor 1',30.00,5),('V1-0004','Producto V1-4','Vendedor 1',40.00,5),('V1-0005','Producto V1-5','Vendedor 1',50.00,5);"
echo "######## EJ9: VENDEDOR 2 importa los 5000 productos del CSV"
docker cp ~/Examen_240165/seeds/tb_products_5000.csv mysql40166:/tmp/tb_products_5000.csv
run $V2 $V2P "LOAD DATA LOCAL INFILE '/tmp/tb_products_5000.csv' INTO TABLE tb_products CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (@id,sku,name,description,current_price,current_stock,@st,creation_date,last_update) SET status=@st+0;"

echo; echo "######## RESUMEN (root)"
run $ROOT $RP "SELECT COUNT(*) AS usuarios FROM tb_users; SELECT COUNT(*) AS personas FROM tb_people; SELECT COUNT(*) AS productos FROM tb_products; SELECT id,email,nickname FROM tb_users;"
run $ROOT $RP "SELECT db_user, operation, table_name, COUNT(*) total FROM tb_logs GROUP BY db_user, operation, table_name ORDER BY db_user;"
