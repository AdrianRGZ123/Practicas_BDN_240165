#!/usr/bin/env python3
"""Aplica sobre un respaldo mysqldump los ajustes del script 00_ajuste_entregables.sql
(25 tablas, 72 triggers, 25 vistas, rutinas y eventos) y escribe el respaldo resultante.

Uso: python corregir_respaldo.py "<respaldo_original.sql>" "<respaldo_corregido.sql>"
NOTA: es una transformación de texto del dump; no sustituye a un mysqldump real del servidor.
"""
import re, sys, os

SRC, DST = sys.argv[1], sys.argv[2]
HERE = os.path.dirname(os.path.abspath(__file__))
lines = open(SRC, encoding="utf-8", errors="replace").read().split("\n")

DROP_TABLES = ["tb_seller_orders", "tb_payment_methods"]
DROP_VIEWS = ["vw_trazabilidad_seller_orders", "vw_trazabilidad_payment_methods",
              "vw_available_products", "vw_total_products_by_category1"]
DROP_TRIGGERS = ["trg_tb_users_after_insert", "trg_tb_users_after_update", "trg_tb_users_after_delete",
                 "trg_tb_products_after_insert", "trg_tb_products_after_update",
                 "trg_products_before_delete", "trg_tbd_cart_items_before_insert"]
DROP_ROUTINES = ["sp_bulk_insert_users", "sp_bulk_insert_persons", "sp_bulk_insert_full_users",
                 "sp_simulate_users_bulk", "sp_simulate_single_user",
                 "fn_simulate_gender_id", "fn_simulate_courtesy_title_id",
                 "fn_simulate_country_code", "fn_simulate_birthdate",
                 "fn_get_random_birth_date", "fn_get_phone_by_country", "sp_generate_bulk_users"]   # se reemplazan por 01_ y 02_

HDR = re.compile(r"^-- (Table structure for table|Temporary view structure for view|Final view structure for view|Dumping routines|Dumping events|Dumping data for table)")
RESTORE = "/*!50003 SET collation_connection  = @saved_col_connection */ ;"

remove = set()

def block_end_by_header(i):
    j = i + 1
    while j < len(lines) and not (HDR.match(lines[j]) and lines[j - 1] == "--" and not lines[j].startswith("-- Dumping data")):
        j += 1
    return j - 1          # excluye el "--" previo al siguiente encabezado

for i, l in enumerate(lines):
    m = re.match(r"^-- Table structure for table `(\w+)`", l)
    if m and m.group(1) in DROP_TABLES:
        remove.update(range(i - 1, block_end_by_header(i)))
    m = re.match(r"^-- (?:Temporary|Final) view structure for view `(\w+)`", l)
    if m and m.group(1) in DROP_VIEWS:
        remove.update(range(i - 1, block_end_by_header(i)))
    m = re.search(r"TRIGGER `(\w+)` (BEFORE|AFTER)", l)
    if m and m.group(1) in DROP_TRIGGERS:
        start = i - 9
        end = i
        while lines[end] != RESTORE:
            end += 1
        remove.update(range(start, end + 1))
    m = re.match(r"^/\*!50003 DROP (PROCEDURE|FUNCTION) IF EXISTS `(\w+)`", l)
    if m and m.group(2) in DROP_ROUTINES:
        end = i
        while lines[end] != RESTORE:
            end += 1
        remove.update(range(i, end + 1))

out = [l for i, l in enumerate(lines) if i not in remove]
text = "\n".join(out)

# tb_payments apunta ahora al catálogo tbc_payment_methods_types (mismos IDs 1-4)
text = text.replace("REFERENCES `tb_payment_methods` (`ID`)", "REFERENCES `tbc_payment_methods_types` (`ID`)")
# sp_register_payment: búsqueda del método por código en el catálogo
pm_old = re.compile(r"SELECT ID INTO v_pm FROM tb_payment_methods\s+WHERE name = CASE v_type.*?END;", re.S)
assert pm_old.search(text), "no se encontró la búsqueda en tb_payment_methods"
text = pm_old.sub("SELECT ID INTO v_pm FROM tbc_payment_methods_types WHERE code = v_type;", text)
assert "tb_payment_methods`" not in text.replace("tbc_payment_methods_types", "")

# rutinas nuevas (01_ y 02_) en formato de mysqldump
def routines_from(path):
    s = open(os.path.join(HERE, path), encoding="utf-8").read()
    out = []
    for m in re.finditer(r"CREATE (PROCEDURE|FUNCTION) (\w+)\(.*?\nEND ;;", s, re.S):
        kind, name = m.group(1), m.group(2)
        body = m.group(0).replace(f"CREATE {kind} {name}", f"CREATE DEFINER=`root`@`localhost` {kind} `{name}`", 1)
        out.append(f"/*!50003 DROP {kind} IF EXISTS `{name}` */;\n"
                   "/*!50003 SET @saved_cs_client      = @@character_set_client */ ;\n"
                   "/*!50003 SET @saved_cs_results     = @@character_set_results */ ;\n"
                   "/*!50003 SET @saved_col_connection = @@collation_connection */ ;\n"
                   "/*!50003 SET character_set_client  = utf8mb4 */ ;\n"
                   "/*!50003 SET character_set_results = utf8mb4 */ ;\n"
                   "/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;\n"
                   "/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;\n"
                   "/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;\n"
                   "DELIMITER ;;\n" + body + "\nDELIMITER ;\n"
                   "/*!50003 SET sql_mode              = @saved_sql_mode */ ;\n"
                   "/*!50003 SET character_set_client  = @saved_cs_client */ ;\n"
                   "/*!50003 SET character_set_results = @saved_cs_results */ ;\n"
                   f"{RESTORE}")
    return "\n".join(out) + "\n"

new_routines = routines_from("01_funciones_auxiliares.sql") + routines_from("02_procedimiento_simulacion_masiva.sql")
marker = re.search(r"-- Dumping routines for database 'db_test'\n--\n", text)
text = text[:marker.end()] + new_routines + text[marker.end():]

# eventos
ev_sql = open(os.path.join(HERE, "03_eventos.sql"), encoding="utf-8").read()
events = []
for m in re.finditer(r"CREATE EVENT (\w+)\s+ON SCHEDULE (.*?)\nON COMPLETION PRESERVE\nENABLE\nCOMMENT '([^']*)'\nDO\n(.*?);\n", ev_sql, re.S):
    n, sched, com, doo = m.groups()
    sched = sched.replace("STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY", "STARTS '2026-11-06 00:00:00'").replace("\n", " ")
    doo = re.sub(r"\s+", " ", doo)
    events.append(f"/*!50106 DROP EVENT IF EXISTS `{n}` */;\nDELIMITER ;;\n"
                  f"/*!50106 CREATE*/ /*!50117 DEFINER=`root`@`localhost`*/ /*!50106 EVENT `{n}` ON SCHEDULE {sched} ON COMPLETION PRESERVE ENABLE COMMENT '{com}' DO {doo} */ ;;\nDELIMITER ;")
assert len(events) == 2
NL = chr(10)
ev_block = ("/*!50106 SET @save_time_zone= @@TIME_ZONE */ ;" + NL
            + NL.join(events) + NL + "/*!50106 SET TIME_ZONE= @save_time_zone */ ;" + NL + NL)
hdr = "-- Dumping events for database 'db_test'" + NL + "--" + NL
k = text.index(hdr) + len(hdr)
text = text[:k] + ev_block + text[k:]

head = ("-- Respaldo db_test CORREGIDO (25 tablas, 72 triggers, 25 vistas, eventos y rutinas de simulacion)\n"
        f"-- Derivado de: {os.path.basename(SRC)} mediante scripts/corregir_respaldo.py\n"
        "-- Equivale a aplicar scripts/00_ajuste_entregables.sql y 01..03; no es un mysqldump directo del servidor.\n")
open(DST, "w", encoding="utf-8", newline="\n").write(head + text)
print("ok", len(remove), "lineas eliminadas")
