#!/bin/bash
# Uso (en el VPS): bash scripts/03_verificar.sh
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
P="docker exec -i -e PGPASSWORD=$POSTGRES_PASSWORD postgres40165 psql -U postgres -p 40165 -d db_test -At"
echo "== Contenedores =="; docker compose ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'
echo "== PostgreSQL: version =="; $P -c "select version();" | cut -c1-60
echo "== PostgreSQL: tablas / triggers / vistas / funciones =="
$P -c "select count(*) from information_schema.tables where table_schema='public' and table_type='BASE TABLE';"
$P -c "select count(*) from information_schema.triggers where trigger_schema='public';"
$P -c "select count(*) from information_schema.views where table_schema='public';"
$P -c "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like 'sp\_%';"
echo "== PostgreSQL: roles y membresias =="
$P -c "select r.rolname, coalesce(string_agg(g.rolname, ','),'(sin rol)') from pg_roles r left join pg_auth_members m on m.member=r.oid left join pg_roles g on g.oid=m.roleid where r.rolname in ('adrian_rios','marco_ramirez','carlos_rene','juan_pablo','erick_uriel','jose_maria','app_web','app_movil') group by r.rolname order by 1;"
$P -c "select rolname, rolcanlogin from pg_roles where rolname in ('superadmin','admin','seller','buyer','support','common','not_registered') order by 1;"
echo "== MySQL: db_test conserva sus datos =="
docker exec -i mysql40166 mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N -e "select count(*) tablas from information_schema.tables where table_schema='db_test' and table_type='BASE TABLE'; select count(*) productos from db_test.tb_products;" 2>/dev/null
echo "== pgAdmin =="; curl -s -o /dev/null -w "HTTP %{http_code} en puerto 40167\n" http://127.0.0.1:40167/login
