# Manual_VPS_BDs_Relacionales

Examen práctico · Unidad 1 · Optativa I: Bases de Datos en la Nube
UTXJ · Ingeniería en Tecnologías de la Información e Innovación Digital

| Dato | Valor |
|---|---|
| Estudiante | Adrian Rios Gomez |
| Matrícula | 240165 |
| Grupo / equipo | 7A / Nexus Software |
| Proveedor del VPS | Hostinger |
| Puerto PostgreSQL | 40165 (cinco dígitos de la matrícula) |
| Puerto MySQL | 40166 (matrícula + 1) |
| pgAdmin Web | 40167 |

## Contenido

```
Manual_VPS_BDs_Relacionales/
    Reporte_Unidad1_240165.pdf   reporte técnico individual
    docker-compose.yml           PostgreSQL 17 + MySQL 8.4 + pgAdmin Web
    .env.example                 variables (el .env real NO se sube)
    sql/
        postgresql.sql           roles, cuentas, base db_test, tablas, triggers, vistas, privilegios
        mysql.sql                igual, para MySQL
    scripts/                     despliegue, carga, casos de prueba y verificación
    evidencias/                  logs de ejecución de cada prueba
    seeds/                       CSV de categorías y de 5000 productos
```

## Despliegue

```bash
cp .env.example .env            # completar contraseñas
docker compose up -d            # postgres40165, mysql40166, pgadmin240165
bash scripts/02_cargar_postgres.sh
sed -e "s/__PW_PERSONAL__/$PW_PERSONAL/g" -e "s/__PW_APP__/$PW_APP/g" sql/mysql.sql \
  | docker exec -i mysql40166 mysql -uroot -p"$MYSQL_ROOT_PASSWORD"
```

Los datos de PostgreSQL y MySQL se guardan en `${DATA_DIR}/postgres_data` y `${DATA_DIR}/mysql_data`
(persisten al recrear los contenedores); pgAdmin usa el volumen `pgadmin_data`.

## Roles y cuentas (ambos motores)

Roles: `superadmin`, `admin`, `seller`, `buyer`, `support`, `common`, `not_registered`.

| Cuenta MySQL | Cuenta PostgreSQL | Rol |
|---|---|---|
| adrian.rios | adrian_rios | superadmin |
| marco.ramirez | marco_ramirez | admin |
| juan.pablo | juan_pablo | seller |
| erick.uriel | erick_uriel | seller |
| carlos.rene | carlos_rene | support |
| jose.maria | jose_maria | sin rol (solo INSERT en tb_users y tb_people) |
| app_web, app_movil | app_web, app_movil | not_registered |

## Casos de prueba (tb_users y tb_products)

1. Superadmin inserta 3 usuarios.
2. Usuario sin rol inserta 3 usuarios.
3. Support inserta 3 usuarios (procedimiento/función de registro).
4. Superadmin modifica y elimina un usuario ajeno.
5. Usuario sin rol intenta modificar y eliminar: se deniega.
6. Support modifica; eliminar se deniega.
7. Superadmin inserta 2 productos.
8. Seller 1 inserta 5 productos.
9. Seller 2 importa 5000 productos desde CSV.

Cada ejecución queda registrada en `evidencias/` y en la tabla `tb_logs` (vistas `vw_trazabilidad_*`).

## Seguridad

No se incluyen contraseñas, claves privadas ni secretos en el repositorio: las contraseñas se leen del
archivo `.env` (ignorado por Git) y se entregan al docente por un canal autorizado.
