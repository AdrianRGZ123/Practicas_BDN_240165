#!/bin/bash
# Uso (en el VPS): bash ~/scripts/03_cargar_y_verificar.sh
M="docker exec -i mysql40166 mysql -uroot -pRoot240165"
echo "== Preparando (8.4 vs dump 8.0) =="; $M -e "SET GLOBAL restrict_fk_on_non_standard_key=OFF; DROP DATABASE IF EXISTS db_test;"
echo "== Cargando tablas limpias =="; $M < ~/scripts/01_db_test_tablas_limpias.sql
echo "== Cargando usuarios y permisos =="; $M < ~/permisos/remote_users_privileges_creation.sql
echo "== Verificacion =="
$M -e "USE db_test;
SELECT table_name, auto_increment, table_rows FROM information_schema.tables WHERE table_schema='db_test' AND table_type='BASE TABLE';
SELECT COUNT(*) AS triggers FROM information_schema.triggers WHERE trigger_schema='db_test';
SELECT user, host FROM mysql.user WHERE host='%';"
