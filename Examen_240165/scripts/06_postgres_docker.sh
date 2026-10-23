#!/bin/bash
# PostgreSQL 17 en Docker, puerto 40165 (sin sudo, usuario en el grupo docker)
docker run -d --name postgres40165 --restart unless-stopped \
  -e POSTGRES_PASSWORD=Postgres240165 -p 40165:40165 \
  -v $HOME/postgres_data:/var/lib/postgresql/data \
  postgres:17 -c port=40165 -c listen_addresses='*'
