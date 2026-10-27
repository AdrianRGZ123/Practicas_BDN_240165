#!/bin/bash
# Uso (en el VPS, dentro de la carpeta del proyecto): bash scripts/01_deploy_compose.sh
# Reemplaza los contenedores creados con "docker run" por los de Docker Compose.
# Los datos se conservan porque viven en ${DATA_DIR}/postgres_data y ${DATA_DIR}/mysql_data.
set -e
cd "$(dirname "$0")/.."
chmod 600 .env
docker rm -f mysql40166 postgres40165 2>/dev/null || true
docker compose up -d
docker compose ps
