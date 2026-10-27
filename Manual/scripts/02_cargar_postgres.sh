#!/bin/bash
# Uso (en el VPS): bash scripts/02_cargar_postgres.sh
# Carga sql/postgresql.sql usando las contrasenas del archivo .env (que no se sube a GitHub).
set -e
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
docker exec -i -e PGPASSWORD="$POSTGRES_PASSWORD" postgres40165 \
  psql -U postgres -p 40165 -v ON_ERROR_STOP=1 \
  -v pw_personal="$PW_PERSONAL" -v pw_app="$PW_APP" < sql/postgresql.sql
