# Diccionario de datos de `db_test` — Práctica 04

Documentación de la base `db_test` tal como queda tras la Práctica 04 (procesos de simulación de compra), generada el 19-11-2026 a partir de la base restaurada de `backups/Respaldo 18-11-26.sql`.

## Archivos

| Archivo | Contenido |
|---|---|
| [diccionario_datos.md](diccionario_datos.md) | Documento principal: convenciones de nomenclatura, resumen, relaciones, una tabla por entidad (campo, tipo, restricciones, descripción de negocio y ejemplo), vistas, procedimientos, triggers, reglas de integridad y pendientes. |
| [diccionario_datos.xlsx](diccionario_datos.xlsx) | Mismo contenido en hojas filtrables: `Resumen_Entidades`, `Diccionario_Campos`, `Relaciones`, `Vistas`, `Procedimientos` y `Restricciones_CHECK`. |
| [diagrama_er.mmd](diagrama_er.mmd) | Diagrama entidad-relación en Mermaid (`erDiagram`): 29 entidades y 48 relaciones. |
| [schema.dbml](schema.dbml) | Esquema en DBML con tipos, llaves, enums, índices, notas y referencias. |

## Cómo consultarlos

- **Diagrama Mermaid:** abrir `diagrama_er.mmd` en VS Code (extensión *Mermaid Preview*) o pegarlo en <https://mermaid.live>. También está incrustado al final de `diccionario_datos.md`, que GitHub renderiza directamente.
- **DBML:** pegar `schema.dbml` en <https://dbdiagram.io/d> para obtener el diagrama interactivo, o importarlo con `dbml-cli`.
- **Diccionario:** abrir `diccionario_datos.md` y usar el índice; para filtrar por tabla o campo, usar `diccionario_datos.xlsx`.

## Regenerar

Los cuatro archivos se generan leyendo la base viva con `scripts/generar_diccionario/generar_diccionario.py` (descripciones en `descripciones.py`):

```bash
python Practica04/scripts/generar_diccionario/generar_diccionario.py
```

Variables opcionales: `MYSQL_BIN`, `MYSQL_USER`, `MYSQL_PASS`, `MYSQL_HOST`, `MYSQL_PORT`.

## Convención resumida

`tb_` tabla maestra/transaccional · `tbc_` catálogo · `tbd_` detalle o asociativa · `vw_` vista · `sp_` procedimiento. Columnas en `snake_case`; llaves foráneas `<rol>_ID`. Las reglas inferidas se marcan como `[Verificar regla de negocio]`.
