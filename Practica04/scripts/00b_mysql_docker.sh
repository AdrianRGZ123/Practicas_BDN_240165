#!/bin/bash
# MySQL 8.4 en Docker, puerto 40166 (equivale a cambiar el puerto en my.ini; sin sudo el VPS no permite editar /etc/mysql)
docker run -d --name mysql40166 --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD=Root240165 -e MYSQL_ROOT_HOST=% -p 40166:40166 \
  -v $HOME/mysql_data:/var/lib/mysql \
  mysql:8.4 --port=40166 --local-infile=1 --mysql-native-password=ON
