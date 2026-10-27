#!/bin/bash
# Uso (en el VPS): bash scripts/08_info_vps.sh   -> evidencias/vps_info.log (indicadores 1-12 y 19 de la lista)
cd "$(dirname "$0")/.."
mkdir -p evidencias
exec > >(tee evidencias/vps_info.log) 2>&1
echo "fecha: $(date '+%F %T')"
echo "== Sistema operativo =="; . /etc/os-release; echo "$PRETTY_NAME"; uname -sr; hostname
echo "== Direccion IP =="; hostname -I
echo "== Recursos =="; echo "CPU: $(nproc) nucleos"; free -h | sed -n '1,2p'; df -h / | sed -n '1,2p'
echo "== Cuentas del sistema operativo (uid >= 1000) y sus grupos =="
getent passwd | awk -F: '$3>=1000 && $3<65000 {print $1}' | while read u; do echo "$u: $(id -nG $u | tr ' ' ',')"; done
echo "== Sesion actual =="; id
echo "== Herramientas =="
git --version 2>&1; docker --version; docker compose version
echo "== Contenedores =="; docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
echo "== Volumenes y datos persistentes =="; docker volume ls --format '{{.Name}}' | grep bdn240165; ls -ld ~/mysql_data ~/postgres_data
echo "== Puertos publicados =="; ss -ltn | grep -E ':(40165|40166|40167) '
echo "== Firewall (ufw) =="; (ufw status 2>&1 | head -3) ; echo "(sin sudo no se puede listar ufw; Docker publica solo 40165, 40166 y 40167)"
echo "== Registros recientes (errores criticos) =="
for c in postgres40165 mysql40166 pgadmin240165; do echo "-- $c: $(docker logs --since 24h $c 2>&1 | grep -ci 'fatal\|panic\|critical')" lineas con FATAL/PANIC/CRITICAL; done
