#!/bin/bash
# Uso (en el VPS):  OLD_MYSQL_ROOT=<actual> bash scripts/07_aplicar_en_vivo.sh
# 1) Rota las contrasenas de root/postgres y de las cuentas personales (las anteriores estuvieron en GitHub).
# 2) Aplica sql/mysql.sql al MySQL en ejecucion (roles common/not_registered, privilegios, vistas, triggers).
# 3) Corrige las llaves foraneas de tbd_cart_items y tbd_order_items y elimina los roles antiguos.
# 4) Re-aplica sql/postgresql.sql con las contrasenas nuevas y verifica ambos motores.
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
mkdir -p evidencias
exec > >(tee evidencias/aplicar_en_vivo.log) 2>&1
echo "fecha: $(date '+%F %T')"
MY="docker exec -i mysql40166 mysql -uroot -p$MYSQL_ROOT_PASSWORD -N -B"

echo; echo "== 1. Rotacion de contrasenas =="
if $MY -e "select 1" >/dev/null 2>&1; then echo "root de MySQL: ya usa la contrasena de .env"
else
  docker exec -i mysql40166 mysql -uroot -p"$OLD_MYSQL_ROOT" -e \
   "ALTER USER 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD'; ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;" 2>&1 | grep -v "Using a password"
  $MY -e "select 'root de MySQL rotado'" 2>&1 | grep -v "Using a password"
fi
docker exec postgres40165 psql -U postgres -p 40165 -qAt -c "ALTER ROLE postgres PASSWORD '$POSTGRES_PASSWORD'" && echo "postgres rotado"
echo "Recreando contenedores con el .env nuevo (los datos persisten en volumenes)..."
docker compose up -d 2>&1 | tail -4
for i in $(seq 1 40); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' mysql40166 2>/dev/null)" = "healthy" ] && \
  [ "$(docker inspect -f '{{.State.Health.Status}}' postgres40165 2>/dev/null)" = "healthy" ] && break; sleep 3; done
echo "mysql40166: $(docker inspect -f '{{.State.Health.Status}}' mysql40166) | postgres40165: $(docker inspect -f '{{.State.Health.Status}}' postgres40165)"

echo; echo "== 2. Aplicar sql/mysql.sql al MySQL en ejecucion =="
sed -e "s/__PW_PERSONAL__/$PW_PERSONAL/g" -e "s/__PW_APP__/$PW_APP/g" sql/mysql.sql | docker exec -i mysql40166 mysql -uroot -p"$MYSQL_ROOT_PASSWORD" 2>&1 | grep -v "Using a password"

echo; echo "== 3. Ajustes sobre las tablas existentes =="
if [ "$($MY -e "select count(*) from information_schema.table_constraints where constraint_schema='db_test' and constraint_name='tbd_cart_items_ibfk_3'" 2>/dev/null)" != "0" ]; then
  docker exec -i mysql40166 mysql -uroot -p"$MYSQL_ROOT_PASSWORD" db_test 2>&1 <<'SQL' | grep -v "Using a password"
ALTER TABLE tbd_cart_items  DROP FOREIGN KEY tbd_cart_items_ibfk_2,  DROP FOREIGN KEY tbd_cart_items_ibfk_3;
ALTER TABLE tbd_cart_items  ADD CONSTRAINT tbd_cart_items_ibfk_2  FOREIGN KEY (provider_ID, product_ID) REFERENCES tbd_products_users_providers (user_ID, product_ID);
ALTER TABLE tbd_order_items DROP FOREIGN KEY tbd_order_items_ibfk_2, DROP FOREIGN KEY tbd_order_items_ibfk_3;
ALTER TABLE tbd_order_items ADD CONSTRAINT tbd_order_items_ibfk_2 FOREIGN KEY (provider_ID, product_ID) REFERENCES tbd_products_users_providers (user_ID, product_ID);
SQL
  echo "llaves foraneas compuestas aplicadas"
else echo "llaves foraneas: ya compuestas"; fi
for u in adrian.rios marco.ramirez carlos.rene juan.pablo erick.uriel jose.maria; do
  $MY -e "ALTER USER '$u'@'%' IDENTIFIED BY '$PW_PERSONAL'" 2>&1 | grep -v "Using a password"; done
for u in app_web app_movil; do $MY -e "ALTER USER '$u'@'%' IDENTIFIED BY '$PW_APP'" 2>&1 | grep -v "Using a password"; done
$MY -e "DROP ROLE IF EXISTS 'common_user', 'user_not_registered'; FLUSH PRIVILEGES;" 2>&1 | grep -v "Using a password"
echo "roles antiguos (common_user, user_not_registered) eliminados; contrasenas de cuentas rotadas"

echo; echo "== 4. Re-aplicar sql/postgresql.sql (contrasenas nuevas) =="
bash scripts/02_cargar_postgres.sh 2>&1 | tail -3

echo; echo "== 5. Verificacion MySQL =="
$MY -e "SELECT 'tablas', COUNT(*) FROM information_schema.tables WHERE table_schema='db_test' AND table_type='BASE TABLE'
 UNION ALL SELECT 'vistas', COUNT(*) FROM information_schema.views WHERE table_schema='db_test'
 UNION ALL SELECT 'triggers', COUNT(*) FROM information_schema.triggers WHERE trigger_schema='db_test'
 UNION ALL SELECT 'productos', COUNT(*) FROM db_test.tb_products
 UNION ALL SELECT 'usuarios', COUNT(*) FROM db_test.tb_users;" 2>&1 | grep -v "Using a password"
echo "-- roles:"; $MY -e "SELECT user FROM mysql.user WHERE account_locked='Y' AND user IN ('superadmin','admin','seller','buyer','support','common','not_registered') ORDER BY user;" 2>&1 | grep -v "Using a password"
echo "-- cuentas y rol:"; $MY -e "SELECT u.user, COALESCE(GROUP_CONCAT(e.from_user),'(sin rol)') FROM mysql.user u LEFT JOIN mysql.role_edges e ON e.to_user=u.user WHERE u.user IN ('adrian.rios','marco.ramirez','carlos.rene','juan.pablo','erick.uriel','jose.maria','app_web','app_movil') GROUP BY u.user ORDER BY u.user;" 2>&1 | grep -v "Using a password"
echo "-- privilegios de los roles:"
for r in admin support seller buyer common not_registered; do echo "[$r]"; $MY -e "SHOW GRANTS FOR '$r'" 2>&1 | grep -v "Using a password\|USAGE"; done
echo "[superadmin] $($MY -e "SHOW GRANTS FOR 'superadmin'" 2>&1 | grep -c 'ALL PRIVILEGES\|SUPER') linea(s) con privilegios globales"
echo; echo "== 6. Verificacion PostgreSQL =="
bash scripts/03_verificar.sh 2>&1 | grep -v NOTICE
