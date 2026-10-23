#!/bin/bash
# Uso (en el VPS): bash 00_vps_setup_mysql.sh
# Cambia el puerto de MySQL a 40166 (en Ubuntu equivale a my.ini) y verifica.
set -e
PORT=40166
echo "== 1. MySQL instalado? =="
if ! command -v mysql >/dev/null; then
  echo "MySQL no esta instalado, instalando..."
  sudo apt update && sudo apt install -y mysql-server
fi
mysql --version
sudo systemctl enable --now mysql

echo "== 2. Configurar puerto $PORT y acceso remoto =="
CNF=/etc/mysql/mysql.conf.d/mysqld.cnf
sudo cp -n $CNF $CNF.bak
sudo sed -i '/^port\s*=/d;/^bind-address\s*=/d;/^mysqlx-bind-address\s*=/d' $CNF
sudo sed -i "/^\[mysqld\]/a port = $PORT\nbind-address = 0.0.0.0\nlocal_infile = 1" $CNF

echo "== 3. Firewall =="
if command -v ufw >/dev/null; then sudo ufw allow $PORT/tcp || true; fi

echo "== 4. Reiniciar y verificar =="
sudo systemctl restart mysql
sudo ss -ltnp | grep $PORT
sudo mysql -e "SHOW VARIABLES WHERE Variable_name IN ('port','bind_address','local_infile'); SELECT VERSION();"
