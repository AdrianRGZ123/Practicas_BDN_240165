#!/bin/bash
# Ejecuta los 5 casos de prueba de la Práctica 04 en orden, cada parte con el usuario de
# conexión que corresponde (app_web para el comprador, adrian.rios para el sistema) y guarda
# la salida de cada parte en resultados/.
#   Uso: HOST=127.0.0.1 PORT=40165 ./ejecutar_casos.sh
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-3306}"
MYSQL="${MYSQL:-mysql}"
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/resultados"
mkdir -p "$OUT"

run() {  # run <usuario> <password> <archivo.sql>
  local f="$3"
  echo ">> $f  (usuario: $1)"
  "$MYSQL" -u"$1" -p"$2" -h"$HOST" -P"$PORT" --default-character-set=utf8mb4 -t < "$DIR/$f" > "$OUT/${f%.sql}.txt" 2>&1 \
    || { echo "   ERROR en $f"; grep -i "error" "$OUT/${f%.sql}.txt"; exit 1; }
}

WEB=(app_web Web123)
SYS=(adrian.rios 240165)

run "${WEB[@]}" caso1_01_app_web.sql
run "${SYS[@]}" caso1_02_sistema.sql

run "${WEB[@]}" caso2_01_app_web.sql
run "${SYS[@]}" caso2_02_sistema.sql
run "${WEB[@]}" caso2_03_app_web_reclamacion.sql
run "${SYS[@]}" caso2_04_sistema_reenvio.sql

run "${WEB[@]}" caso3_01_app_web.sql
run "${SYS[@]}" caso3_02_sistema_atencion.sql
run "${WEB[@]}" caso3_03_app_web_cancelacion.sql
run "${SYS[@]}" caso3_04_sistema_ajuste_reembolso_envio.sql

run "${WEB[@]}" caso4_01_app_web.sql
run "${SYS[@]}" caso4_02_sistema.sql

run "${SYS[@]}" caso5_01_sistema_cupon.sql
run "${WEB[@]}" caso5_02_app_web.sql
run "${SYS[@]}" caso5_03_sistema_sin_inventario.sql

echo "Listo. Resultados en $OUT"
