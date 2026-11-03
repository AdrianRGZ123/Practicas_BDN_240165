# Diccionario de datos de `db_test`

Documentación derivada de `Respaldo 28-10-26 .sql`. Se procesaron definiciones DDL; no se consultaron ni incluyeron sentencias `INSERT`.

## Archivos

- [diccionario_datos.md](diccionario_datos.md): documento principal con índice, tablas, columnas, objetos programables y observaciones.
- [diccionario_datos.xlsx](diccionario_datos.xlsx): hojas Resumen, Tablas, Columnas, Relaciones, Vistas, Triggers, Procedimientos y Observaciones.
- [diagrama_er.mmd](diagrama_er.mmd): modelo entidad-relación completo (27 entidades y 42 relaciones FK) en Mermaid `erDiagram`; también incluido al final del diccionario.
- [schema.dbml](schema.dbml): esquema DBML.

## Resumen ejecutivo

El DDL contiene 27 tablas, 29 vistas, 85 triggers, 15 procedimientos y 6 funciones. Se insertaron masivamente **10 222 usuarios** (`sp_generate_bulk_users`, 3 lotes) de un total de 10 239 en `tb_users`. Los conteos proporcionados para seis tablas no se pueden recalcular desde el DDL. El dump indica MySQL 8.0.42 frente a 8.0.36 en la solicitud. La semántica ausente queda marcada como `No especificado` y se lista en Pendientes por confirmar.
