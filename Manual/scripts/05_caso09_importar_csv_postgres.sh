#!/bin/bash
# Uso (en el VPS): bash scripts/05_caso09_importar_csv_postgres.sh
# Caso 09: el seller erick_uriel importa los 5000 productos del CSV y se verifica la trazabilidad.
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
mkdir -p evidencias
exec > >(tee -a evidencias/postgresql_caso09_importar_csv.log) 2>&1
H=$(docker exec postgres40165 hostname -i | awk '{print $1}')
q() { echo; echo ">>> [$1] $2"; docker exec -i -e PGPASSWORD="$PW_PERSONAL" postgres40165 psql -X -h "$H" -p 40165 -U "$1" -d db_test -c "$2" 2>&1; }

echo "fecha: $(date '+%F %T')"
echo; echo "######## CASO 09: seller 2 (erick_uriel) importa los 5000 productos del CSV"
docker cp seeds/tb_products_5000.csv postgres40165:/tmp/tb_products_5000.csv
echo "(Si last_update viene vacio en el CSV se usa creation_date: la columna es NOT NULL)"
echo ">>> [erick_uriel] CREATE TEMP TABLE + \copy del CSV + INSERT ... SELECT"
docker exec -i -e PGPASSWORD="$PW_PERSONAL" postgres40165 psql -X -h "$H" -p 40165 -U erick_uriel -d db_test -v ON_ERROR_STOP=1 <<'SQL' 2>&1
CREATE TEMP TABLE stg (id int, sku varchar(50), name varchar(250), description text, current_price numeric(10,2), current_stock int, status int, creation_date timestamp, last_update timestamp);
\copy stg FROM '/tmp/tb_products_5000.csv' WITH (FORMAT csv, HEADER true)
INSERT INTO tb_products (sku,name,description,current_price,current_stock,status,creation_date,last_update)
  SELECT sku,name,description,current_price,current_stock,(status=1),COALESCE(creation_date,CURRENT_TIMESTAMP),COALESCE(last_update,creation_date,CURRENT_TIMESTAMP) FROM stg;
SQL

echo; echo "######## RESUMEN Y TRAZABILIDAD (adrian_rios)"
q adrian_rios "SELECT (SELECT count(*) FROM tb_users) AS usuarios, (SELECT count(*) FROM tb_people) AS personas, (SELECT count(*) FROM tb_products) AS productos;"
q adrian_rios "SELECT db_user, operation, table_name, count(*) FROM tb_logs GROUP BY 1,2,3 ORDER BY 1,3,2;"
q adrian_rios "SELECT count(*) AS productos_en_vista_trazabilidad FROM vw_trazabilidad_productos;"
