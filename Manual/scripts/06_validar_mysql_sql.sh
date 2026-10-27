#!/bin/bash
# Uso (en el VPS): bash scripts/06_validar_mysql_sql.sh
# Prueba sql/mysql.sql en un MySQL 8.4 DESECHABLE (sin puertos publicados, no toca mysql40166)
# y comprueba bases de datos, tablas, triggers, vistas, procedimientos, roles, cuentas y privilegios.
cd "$(dirname "$0")/.."
mkdir -p evidencias
exec > >(tee evidencias/mysql_validacion_mysql_sql.log) 2>&1
C=mysql_validacion
R=$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)
PP=$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)
PA=$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)
M="docker exec -i $C mysql -uroot -p$R -N -B"
echo "fecha: $(date '+%F %T')  | imagen: mysql:8.4 (contenedor desechable)"
docker rm -f $C >/dev/null 2>&1
docker run -d --name $C -e MYSQL_ROOT_PASSWORD="$R" mysql:8.4 --mysql-native-password=ON >/dev/null
echo -n "Esperando a MySQL"; until docker exec $C mysqladmin ping -h 127.0.0.1 -P 3306 -uroot -p"$R" --silent >/dev/null 2>&1; do echo -n .; sleep 3; done; echo " listo"

echo; echo "== Carga de sql/mysql.sql (1a vez) =="
sed -e "s/__PW_PERSONAL__/$PP/g" -e "s/__PW_APP__/$PA/g" sql/mysql.sql | docker exec -i $C mysql -uroot -p"$R" 2>&1 | grep -v "Using a password"
echo "== Carga de sql/mysql.sql (2a vez, comprueba que se puede repetir) =="
sed -e "s/__PW_PERSONAL__/$PP/g" -e "s/__PW_APP__/$PA/g" sql/mysql.sql | docker exec -i $C mysql -uroot -p"$R" 2>&1 | grep -v "Using a password"

echo; echo "== Objetos creados en db_test =="
$M -e "SELECT 'tablas', COUNT(*) FROM information_schema.tables WHERE table_schema='db_test' AND table_type='BASE TABLE'
 UNION ALL SELECT 'vistas', COUNT(*) FROM information_schema.views WHERE table_schema='db_test'
 UNION ALL SELECT 'triggers', COUNT(*) FROM information_schema.triggers WHERE trigger_schema='db_test'
 UNION ALL SELECT 'procedimientos', COUNT(*) FROM information_schema.routines WHERE routine_schema='db_test' AND routine_type='PROCEDURE';" 2>&1 | grep -v "Using a password"
echo "== Contador de ID reiniciado (AUTO_INCREMENT) =="
$M -e "SELECT table_name, auto_increment FROM information_schema.tables WHERE table_schema='db_test' AND table_name IN ('tb_users','tb_products','tb_people','tb_logs');" 2>&1 | grep -v "Using a password"
echo "== Roles (cuentas sin login) y cuentas personales con su rol =="
$M -e "SELECT user FROM mysql.user WHERE account_locked='Y' AND user IN ('superadmin','admin','seller','buyer','support','common','not_registered') ORDER BY user;" 2>&1 | grep -v "Using a password"
$M -e "SELECT u.user, COALESCE(GROUP_CONCAT(e.from_user),'(sin rol)') FROM mysql.user u LEFT JOIN mysql.role_edges e ON e.to_user=u.user WHERE u.user IN ('adrian.rios','marco.ramirez','carlos.rene','juan.pablo','erick.uriel','jose.maria','app_web','app_movil') GROUP BY u.user ORDER BY u.user;" 2>&1 | grep -v "Using a password"
echo "== Privilegios de los roles =="
for r in superadmin admin support seller buyer common not_registered; do
  echo "-- $r"; docker exec -i $C mysql -uroot -p"$R" -N -B -e "SHOW GRANTS FOR '$r'" 2>&1 | grep -v "Using a password"; done
echo "-- jose.maria (sin rol)"; docker exec -i $C mysql -uroot -p"$R" -N -B -e "SHOW GRANTS FOR 'jose.maria'@'%'" 2>&1 | grep -v "Using a password"

echo; echo "== Funcionamiento: insertar con una cuenta y revisar trigger y vista =="
docker exec -i $C mysql -ujuan.pablo -p"$PP" db_test -e "INSERT INTO tb_products (sku,name,current_price,current_stock) VALUES ('VAL-0001','Producto de validacion',10,1);" 2>&1 | grep -v "Using a password"
$M -e "SELECT operation, db_user, table_name FROM db_test.vw_trazabilidad_productos;" 2>&1 | grep -v "Using a password"

docker rm -f $C >/dev/null && echo; echo "Contenedor desechable eliminado."
