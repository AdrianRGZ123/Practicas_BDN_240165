# Diccionario de datos de `db_test`

Documentación derivada de `Respaldo 21-10-26.sql`. Se procesaron definiciones DDL; no se consultaron ni incluyeron sentencias `INSERT`.

## Archivos

- [diccionario_datos.md](diccionario_datos.md): documento principal con índice, tablas, columnas, objetos programables y observaciones.
- [diccionario_datos.xlsx](diccionario_datos.xlsx): hojas Resumen, Tablas, Columnas, Relaciones, Vistas, Triggers, Procedimientos y Observaciones.
- [diagrama_er.mmd](diagrama_er.mmd): relaciones FK en Mermaid `erDiagram`.
- [schema.dbml](schema.dbml): esquema DBML.

## Resumen ejecutivo

El DDL contiene 16 tablas, 18 vistas, 51 triggers y 4 procedimientos. Los conteos proporcionados para seis tablas no se pueden recalcular desde el DDL. El dump indica MySQL 8.0.42 frente a 8.0.36 en la solicitud. La semántica ausente queda marcada como `No especificado` y se lista en Pendientes por confirmar.
