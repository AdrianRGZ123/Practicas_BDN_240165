#!/usr/bin/env python3
"""Genera el diccionario de datos de db_test a partir de un respaldo mysqldump.

Uso:  python generar_diccionario.py "<respaldo.sql>" "<carpeta_salida>"
Produce: diccionario_datos.md, diccionario_datos.xlsx, diagrama_er.mmd, schema.dbml, README.md
"""
import re, sys, os
from collections import OrderedDict

SRC, OUT = sys.argv[1], sys.argv[2]
sql = open(SRC, encoding="utf-8", errors="replace").read()
fname = os.path.basename(SRC)
ver = (re.search(r"Server version\s+(\S+)", sql) or [0, "?"])[1]
dumped = (re.search(r"Dump completed on (\S+)", sql) or [0, "?"])[1]

# ---------------------------------------------------------------- tablas
tables = OrderedDict()
for m in re.finditer(r"CREATE TABLE `(\w+)` \((.*?)\n\) ENGINE=(\w+)([^;]*);", sql, re.S):
    name, body, engine, tail = m.groups()
    t = dict(name=name, engine=engine, cols=[], pk=[], uks=[], idx=[], fks=[], checks=[], ai=None)
    am = re.search(r"AUTO_INCREMENT=(\d+)", tail)
    t["ai"] = int(am.group(1)) if am else None
    cs = re.search(r"CHARSET=(\w+)", tail); co = re.search(r"COLLATE=(\w+)", tail)
    t["charset"], t["collation"] = (cs.group(1) if cs else ""), (co.group(1) if co else "")
    for line in body.split("\n"):
        line = line.strip().rstrip(",")
        if not line:
            continue
        if line.startswith("`"):
            cm = re.match(r"`(\w+)` (.+)", line)
            cname, rest = cm.groups()
            typ = re.match(r"([a-z]+(?:\([^)]*\))?(?: unsigned)?)", rest).group(1)
            low = rest.lower()
            d = re.search(r"DEFAULT (\(.*?\)|'[^']*'|b'[01]+'|[\w.()]+)", rest)
            gen = re.search(r"GENERATED ALWAYS AS \((.*)\) (STORED|VIRTUAL)", rest)
            com = re.search(r"COMMENT '((?:[^']|'')*)'", rest)
            extras = []
            if "auto_increment" in low: extras.append("AUTO_INCREMENT")
            if "on update current_timestamp" in low: extras.append("ON UPDATE CURRENT_TIMESTAMP")
            if gen: extras.append(f"GENERADA {gen.group(2)}: {gen.group(1)}")
            t["cols"].append(dict(name=cname, type=typ, null="NOT NULL" not in rest and not gen or ("NOT NULL" not in rest),
                                  default=d.group(1) if d else None, extras=extras,
                                  comment=com.group(1).replace("''", "'") if com else ""))
        elif line.startswith("PRIMARY KEY"):
            t["pk"] = re.findall(r"`(\w+)`", line)
        elif line.startswith("UNIQUE KEY"):
            n, c = re.match(r"UNIQUE KEY `(\w+)` \((.*)\)", line).groups()
            t["uks"].append((n, re.findall(r"`(\w+)`", c)))
        elif line.startswith("KEY"):
            n, c = re.match(r"KEY `(\w+)` \((.*)\)", line).groups()
            t["idx"].append((n, re.findall(r"`(\w+)`", c)))
        elif line.startswith("CONSTRAINT") and "FOREIGN KEY" in line:
            fm = re.match(r"CONSTRAINT `(\w+)` FOREIGN KEY \((.*?)\) REFERENCES `(\w+)` \((.*?)\)(.*)", line)
            n, c, rt, rc, act = fm.groups()
            t["fks"].append(dict(name=n, cols=re.findall(r"`(\w+)`", c), rtable=rt,
                                 rcols=re.findall(r"`(\w+)`", rc), actions=act.strip()))
        elif line.startswith("CONSTRAINT") and "CHECK" in line:
            n = re.match(r"CONSTRAINT `(\w+)`", line).group(1)
            expr = re.sub(r"_utf8mb4", "", line.split("CHECK", 1)[1]).strip()
            t["checks"].append((n, expr))
    tables[name] = t

# marcar llaves
for t in tables.values():
    fkcols = {c for f in t["fks"] for c in f["cols"]}
    for c in t["cols"]:
        c["pk"] = c["name"] in t["pk"]
        c["fk"] = c["name"] in fkcols

# ---------------------------------------------------------------- registros (conteo de INSERT)
def count_rows(table):
    n = 0
    for m in re.finditer(r"^INSERT INTO `%s` VALUES (.*);$" % table, sql, re.M):
        s = m.group(1); inq = False; i = 0; depth = 0
        while i < len(s):
            ch = s[i]
            if inq:
                if ch == "\\": i += 1
                elif ch == "'":
                    if i + 1 < len(s) and s[i + 1] == "'": i += 1
                    else: inq = False
            else:
                if ch == "'": inq = True
                elif ch == "(":
                    if depth == 0: n += 1
                    depth += 1
                elif ch == ")": depth -= 1
            i += 1
    return n
for t in tables.values():
    t["rows"] = count_rows(t["name"])

# ---------------------------------------------------------------- triggers
triggers = []
for m in re.finditer(r"TRIGGER `(\w+)` (BEFORE|AFTER) (INSERT|UPDATE|DELETE) ON `(\w+)` FOR EACH ROW(.*?)\n?(?: ;;|;;)", sql, re.S):
    n, when, ev, tb, body = m.groups()
    logt = re.search(r"INSERT INTO `?tb_logs`?", body) is not None
    ops = re.findall(r"'(Create|Read|Update|Delete)'", body)
    triggers.append(dict(name=n, when=when, event=ev, table=tb, logs=logt, op=ops[0] if ops else ""))

# ---------------------------------------------------------------- vistas
views = OrderedDict()
for m in re.finditer(r"/\*!50001 VIEW `(\w+)` AS (select .*?)\*/;", sql, re.S | re.I):
    n, body = m.groups()
    base = sorted(set(re.findall(r"`(tb\w*)`", body)) - {n})
    cols = re.findall(r" AS `(\w+)`", body)
    views[n] = dict(name=n, base=base, cols=cols, body=body)
for n in re.findall(r"CREATE VIEW `(\w+)` AS SELECT", sql):   # por si alguna no tiene definicion final
    views.setdefault(n, dict(name=n, base=[], cols=[], body=""))

# ---------------------------------------------------------------- eventos
events = []
for m in re.finditer(r"EVENT `(\w+)` ON SCHEDULE (.*?) ON COMPLETION (NOT PRESERVE|PRESERVE) (ENABLE|DISABLE)(?: COMMENT '([^']*)')? DO (.*?) \*/ ;;", sql, re.S):
    events.append(dict(name=m.group(1), schedule=m.group(2), status=m.group(4), comment=m.group(5) or "", body=re.sub(r"\s+", " ", m.group(6))))

# ---------------------------------------------------------------- rutinas
routines = []
for m in re.finditer(r"CREATE DEFINER=`[^`]+`@`[^`]+` (PROCEDURE|FUNCTION) `(\w+)`\((.*?)\)(\s*RETURNS [^\n]+)?\n(?=\s*(?:NO SQL|DETERMINISTIC|READS|MODIFIES|CONTAINS|BEGIN|SQL SECURITY|COMMENT))(.*?)END ;;", sql, re.S):
    kind, n, params, ret, body = m.groups()
    ps = [re.sub(r"\s+", " ", p.strip()) for p in params.split(",") if p.strip()]
    touched = sorted(set(re.findall(r"(?:FROM|INTO|UPDATE|JOIN)\s+`?(tb\w*)`?", body, re.I)))
    calls = sorted(set(re.findall(r"CALL\s+`?(\w+)`?", body, re.I)))
    routines.append(dict(kind=kind, name=n, params=ps, ret=(ret or "").strip(), body=body, touched=touched, calls=calls))

# ---------------------------------------------------------------- utilidades de texto
def prefix(n):
    return "tbc_" if n.startswith("tbc_") else "tbd_" if n.startswith("tbd_") else "tb_"
PREF_TXT = {"tb_": "principal", "tbc_": "catálogo", "tbd_": "detalle/asociación"}

def human(n):
    return n.replace("tbd_", "").replace("tbc_", "").replace("tb_", "").replace("_", " ")

def fk_target(t, col):
    for f in t["fks"]:
        if col in f["cols"]:
            return f["rtable"], f["rcols"][f["cols"].index(col)]
    return None

def describe(t, c):
    n = c["name"]; l = n.lower(); h = human(t["name"])
    if c["comment"]: return c["comment"]
    if c["pk"] and "AUTO_INCREMENT" in c["extras"]: return f"Identificador autogenerado del registro de {h}."
    ft = fk_target(t, n)
    if ft: return f"Referencia a `{ft[0]}.{ft[1]}`; vincula el registro de {h} con su entidad relacionada."
    if c["extras"] and any(e.startswith("GENERADA") for e in c["extras"]): return "Valor calculado automáticamente por el motor a partir de otras columnas."
    table = {
        "status": "Estado lógico del registro (1 = activo, 0 = inactivo).",
        "creation_date": "Fecha y hora de creación del registro.",
        "last_update": "Fecha y hora de la última modificación.",
        "email": "Correo electrónico (único).", "nickname": "Alias público de la cuenta (único).",
        "password": "Contraseña almacenada de la cuenta.", "last_login": "Fecha y hora del último inicio de sesión.",
        "sku": "Código de inventario del producto (único).", "name": f"Nombre de {h}.",
        "description": f"Descripción de {h}.", "current_price": "Precio vigente del producto.",
        "current_stock": "Existencias disponibles.", "quantity": "Cantidad de unidades.",
        "unit_price": "Precio unitario al momento de la operación.", "subtotal": "Importe parcial (sin envío).",
        "shipping_cost": "Costo de envío.", "total": "Importe total.", "amount": "Monto de la operación.",
        "currency": "Moneda del importe.", "provider": "Proveedor externo del servicio/medio.",
        "table_name": "Tabla origen del evento auditado.", "operation": "Tipo de operación registrada.",
        "db_user": "Usuario de base de datos que ejecutó la acción.", "operation_date": "Fecha y hora del evento.",
        "operation_status": "Resultado del evento (1 = correcto, 0 = fallido).",
        "latitude": "Latitud geográfica.", "longitude": "Longitud geográfica.",
        "is_default": "Marca de elemento predeterminado (1 = sí).", "birth_date": "Fecha de nacimiento.",
        "phone": "Teléfono de contacto.", "country_code": "Código de país (ISO de 2 letras).",
        "given_names": "Nombre(s) de pila.", "family_names": "Apellidos.", "code": "Código corto identificador (único).",
    }
    if l in table: return table[l]
    if l.endswith("_status") or l == "fulfillment_status": return f"Estado del flujo de {h}."
    if l.endswith("_date") or l.endswith("_at"): return f"Fecha/hora asociada a {human(l)} en {h}."
    if "reference" in l or l.endswith("_ref"): return "Referencia externa asignada por el proveedor."
    if "reason" in l: return "Motivo registrado."
    return f"Atributo «{n.replace('_', ' ')}» de {h}."

def nature(c):
    ty = c["type"]
    if c["pk"] or c["fk"]: return "Identificador"
    if re.match(r"(date|time|timestamp)", ty): return "Temporal"
    if re.match(r"(tiny|small|medium|big)?int|decimal|float|double", ty): return "Cuantitativa"
    if ty.startswith("bit") or ty.startswith("enum"): return "Cualitativa nominal"
    return "Cualitativa"

def keyname(c):
    return "PK+FK" if c["pk"] and c["fk"] else "PK" if c["pk"] else "FK" if c["fk"] else "—"

def dflt(c):
    return "—" if c["default"] is None else c["default"]

def esc(s): return str(s).replace("|", "\\|").replace("\n", " ")

# relaciones
rels = []   # (padre, hijo, etiqueta, uno_a_uno)
for t in tables.values():
    for f in t["fks"]:
        uniq = any(set(f["cols"]) == set(c) for _, c in t["uks"]) or set(f["cols"]) == set(t["pk"])
        rels.append(dict(parent=f["rtable"], child=t["name"], cols=f["cols"], rcols=f["rcols"], name=f["name"], one=uniq and len(f["cols"]) == len(t["pk"]) and False or any(set(f["cols"]) == set(c) for _, c in t["uks"])))
children = {n: [] for n in tables}
for r in rels: children.setdefault(r["parent"], []).append(r)
trig_by_table = {}
for tr in triggers: trig_by_table.setdefault(tr["table"], []).append(tr)

# ---------------------------------------------------------------- Markdown
L = []; A = L.append
A("# Diccionario de datos — `db_test`\n")
A(f"> Fuente: `{fname}`. Generado automáticamente desde el DDL del respaldo (MySQL {ver}, volcado {dumped}). Los conteos de registros se obtuvieron contando las sentencias `INSERT` del mismo respaldo; no se reproducen datos.\n")
A("## Índice\n")
for i, s in enumerate(["Resumen ejecutivo", "Tablas y columnas", "Vistas", "Triggers", "Procedimientos almacenados", "Funciones almacenadas", "Eventos programados", "Dominios y convenciones", "Observaciones de diseño", "Pendientes por confirmar"], 1):
    A(f"{i}. [{s}](#{s.lower().replace(' ', '-').replace('í','i').replace('ó','o')})")
procs = [r for r in routines if r["kind"] == "PROCEDURE"]; funcs = [r for r in routines if r["kind"] == "FUNCTION"]
A("\n## Resumen ejecutivo\n")
A("| Elemento | Conteo |\n|---|---:|")
for k, v in [("Tablas", len(tables)), ("Vistas", len(views)), ("Triggers", len(triggers)), ("Procedimientos", len(procs)), ("Funciones", len(funcs)), ("Eventos", len(events)), ("Relaciones FK", len(rels))]:
    A(f"| {k} | {v} |")
A("\nRegistros por tabla (según los `INSERT` del respaldo):\n")
A("| Tabla | Registros |\n|---|---:|")
for t in sorted(tables.values(), key=lambda x: -x["rows"]):
    A(f"| `{t['name']}` | {t['rows']:,} |".replace(",", " "))
A("\n## Tablas y columnas\n")
for t in tables.values():
    n = t["name"]
    A(f"### `{n}`\n")
    A(f"- **Prefijo/tipo:** {prefix(n)} ({PREF_TXT[prefix(n)]}). **Motor:** {t['engine']}. **Charset/collation:** {t['charset']} / {t['collation']}. **Registros:** {t['rows']}.\n")
    A("| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |\n|---:|---|---|:---:|---|---|---|---|---|")
    for i, c in enumerate(t["cols"], 1):
        A(f"| {i} | `{c['name']}` | `{c['type']}` | {'SÍ' if c['null'] else 'NO'} | {esc(dflt(c))} | {esc('; '.join(c['extras']) or '—')} | {keyname(c)} | {esc(describe(t, c))} | {'Obligatorio' if not c['null'] else 'Opcional'}; {nature(c)} |")
    cons = [f"PK (`{'`, `'.join(t['pk'])}`)"] if t["pk"] else []
    cons += [f"UNIQUE `{a}` (`{'`, `'.join(b)}`)" for a, b in t["uks"]]
    cons += [f"ÍNDICE `{a}` (`{'`, `'.join(b)}`)" for a, b in t["idx"]]
    for f in t["fks"]:
        cons.append(f"FK `{f['name']}` (`{'`, `'.join(f['cols'])}`) → `{f['rtable']}` (`{'`, `'.join(f['rcols'])}`) {f['actions']}".strip())
    cons += [f"CHECK `{a}`: `{esc(b)}`" for a, b in t["checks"]]
    A("\n**Restricciones/índices:** " + "; ".join(cons))
    rl = [f"`{r['name']}`: `{n}` ({', '.join(r['cols'])}) → `{r['parent']}` ({', '.join(r['rcols'])})" for r in rels if r["child"] == n]
    rl += [f"Tabla hija `{r['child']}` mediante `{r['name']}`" for r in children.get(n, [])]
    A("**Relaciones:** " + ("; ".join(rl) if rl else "No hay relaciones FK declaradas."))
    A("**Triggers asociados:** " + (", ".join(f"`{x['name']}`" for x in trig_by_table.get(n, [])) or "Ninguno.") + "\n")

# N:M
assoc = [t for t in tables.values() if len(t["fks"]) >= 2 and t["name"].startswith("tbd_") and set(t["pk"]) <= {c for f in t["fks"] for c in f["cols"]}]
if assoc:
    A("### Relaciones N:M mediante tablas de asociación\n")
    for t in assoc:
        A(f"- `{t['name']}` resuelve la relación entre " + " y ".join(f"`{f['rtable']}`" for f in t["fks"][:2]) + ".")
    A("")

A("## Vistas\n")
A("| Vista | Propósito | Tablas base | Columnas expuestas |\n|---|---|---|---|")
for v in views.values():
    purpose = "Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad." if v["name"].startswith("vw_trazabilidad") else "Vista de reporte con agregaciones sobre las tablas base."
    A(f"| `{v['name']}` | {purpose} | {', '.join('`'+b+'`' for b in v['base']) or '—'} | {', '.join('`'+c+'`' for c in v['cols']) or '—'} |")

A("\n## Triggers\n")
A("| Trigger | Tabla destino | Evento | Momento | Registra en `tb_logs` |\n|---|---|---|---|---|")
for tr in triggers:
    A(f"| `{tr['name']}` | `{tr['table']}` | {tr['event']} | {tr['when']} | {('Sí (' + tr['op'] + ')') if tr['logs'] and tr['op'] else ('Sí' if tr['logs'] else 'No')} |")

A("\n## Procedimientos almacenados\n")
for r in procs:
    A(f"### `{r['name']}`\n")
    A("**Parámetros:** " + ("; ".join(f"`{p}`" for p in r["params"]) or "Ninguno") + "\n")
    if r["touched"]: A("**Tablas consultadas/modificadas:** " + ", ".join(f"`{x}`" for x in r["touched"]) + "\n")
    if r["calls"]: A("**Invoca:** " + ", ".join(f"`{x}`" for x in r["calls"]) + "\n")
    A("**Ejemplo:** `CALL " + r["name"] + "(" + ", ".join("/* " + re.sub(r"^(IN|OUT|INOUT) ", "", p).split(" ")[0] + " */" for p in r["params"]) + ");`\n")
A("## Funciones almacenadas\n")
for r in funcs:
    A(f"### `{r['name']}`\n")
    A("**Parámetros:** " + ("; ".join(f"`{p}`" for p in r["params"]) or "Ninguno") + "\n")
    A(f"**Retorna:** `{r['ret'].replace('RETURNS','').strip()}`\n")

A("## Eventos programados\n")
A("| Evento | Programación | Estado | Descripción | Sentencia |\n|---|---|---|---|---|")
for e in events:
    A(f"| `{e['name']}` | {esc(e['schedule'])} | {e['status']} | {esc(e['comment'])} | `{esc(e['body'][:160])}` |")
if not events:
    A("| — | — | — | No hay eventos definidos. | — |")
A("")
A("## Dominios y convenciones\n")
A("**ENUM y campos de estado:**")
for t in tables.values():
    for c in t["cols"]:
        if c["type"].startswith("enum"):
            A(f"- `{t['name']}.{c['name']}`: " + ", ".join(re.findall(r"'([^']*)'", c["type"])) + ".")
        elif c["name"] == "status":
            A(f"- `{t['name']}.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.")
        elif c["name"] == "is_default":
            A(f"- `{t['name']}.is_default`: 1 = predeterminado; 0 = no predeterminado.")
A("\n**Prefijos de tabla:** `tb_` entidades principales; `tbc_` catálogos; `tbd_` tablas de detalle/asociación.")

A("\n## Observaciones de diseño\n")
obs = []
if any("md5" in r["body"].lower() for r in routines):
    obs.append("- **Alta:** `sp_register_user_with_person` aplica MD5 a la contraseña; MD5 no es adecuado para almacenar contraseñas. Recomendación: Argon2id, bcrypt o scrypt con sal.")
dupe = [n for n, l in trig_by_table.items() if len({(x['event'], x['when']) for x in l}) < len(l)]
if dupe:
    obs.append("- **Media:** " + ", ".join(f"`{d}`" for d in dupe) + " tienen más de un trigger para el mismo evento y momento; pueden duplicar el historial en `tb_logs`.")
for t in tables.values():
    for f in t["fks"]:
        pass
for t in tables.values():
    sep = [f for f in t["fks"] if f["rtable"] == "tbd_products_users_providers"]
    if len(sep) >= 2:
        obs.append(f"- **Media:** `{t['name']}` referencia por separado `provider_ID` y `product_ID` a `tbd_products_users_providers`; dos FK independientes no garantizan que el par exista como vínculo.")
nolog = [t["name"] for t in tables.values() if t["name"] != "tb_logs" and t["name"] not in trig_by_table]
if nolog: obs.append("- **Baja:** tablas sin triggers de auditoría: " + ", ".join(f"`{x}`" for x in nolog) + ".")
vv = [v["name"] for v in views.values() if v["name"].endswith("1")]
if vv: obs.append("- **Baja:** posible vista duplicada: " + ", ".join(f"`{x}`" for x in vv) + ".")
A("\n".join(obs) or "- Sin observaciones.")
A("\n## Pendientes por confirmar\n")
A("- Significado funcional de ENUM y banderas sin comentario explícito en el DDL.\n- Moneda, zona horaria y validaciones de formato no expresadas en el DDL.\n- Los conteos de registros corresponden al momento del respaldo y deben validarse en el servidor.")
open(os.path.join(OUT, "diccionario_datos.md"), "w", encoding="utf-8", newline="\n").write("\n".join(L) + "\n")

# ---------------------------------------------------------------- Mermaid (con entidades)
M = ["erDiagram"]
seen = set()
for r in rels:
    key = (r["parent"], r["child"], r["cols"][0])
    if key in seen: continue
    seen.add(key)
    M.append(f'    {r["parent"]} {"||--||" if r["one"] else "||--o{"} {r["child"]} : "{", ".join(r["cols"])}"')
for t in tables.values():
    M.append(f"    {t['name']} {{")
    for c in t["cols"]:
        ty = re.sub(r"[^\w]", "_", c["type"]).strip("_")
        k = " PK" if c["pk"] else " FK" if c["fk"] else ""
        if c["pk"] and c["fk"]: k = " PK"
        M.append(f"        {ty} {c['name']}{k}")
    M.append("    }")
open(os.path.join(OUT, "diagrama_er.mmd"), "w", encoding="utf-8", newline="\n").write("\n".join(M) + "\n")

# ---------------------------------------------------------------- DBML
D = ['Project db_test {', '  database_type: "MySQL"', f'  Note: "Generado desde {fname} (MySQL {ver})"', '}', '']
for t in tables.values():
    D.append(f"Table {t['name']} {{")
    for c in t["cols"]:
        attrs = []
        if c["pk"]: attrs.append("pk")
        if not c["null"]: attrs.append("not null")
        if "AUTO_INCREMENT" in c["extras"]: attrs.append("increment")
        if c["default"] is not None: attrs.append("default: " + (c["default"] if c["default"].startswith(("b'", "(")) else "'" + c["default"].strip("'") + "'"))
        D.append(f"  {c['name']} {c['type']}" + (f" [{', '.join(attrs)}]" if attrs else ""))
    if t["uks"] or t["idx"]:
        D.append("  Indexes {")
        for n, c in t["uks"]: D.append(f"    ({', '.join(c)}) [unique, name: '{n}']")
        for n, c in t["idx"]: D.append(f"    ({', '.join(c)}) [name: '{n}']")
        D.append("  }")
    D.append("}")
D.append("")
for r in rels:
    a = r["child"] + "." + (r["cols"][0] if len(r["cols"]) == 1 else "(" + ", ".join(r["cols"]) + ")")
    b = r["parent"] + "." + (r["rcols"][0] if len(r["rcols"]) == 1 else "(" + ", ".join(r["rcols"]) + ")")
    D.append(f"Ref: {a} {'-' if r['one'] else '>'} {b}")
open(os.path.join(OUT, "schema.dbml"), "w", encoding="utf-8", newline="\n").write("\n".join(D) + "\n")

# ---------------------------------------------------------------- README
open(os.path.join(OUT, "README.md"), "w", encoding="utf-8", newline="\n").write(f"""# Diccionario de datos de `db_test`

Documentación derivada de `{fname}` (MySQL {ver}). Se procesaron definiciones DDL y se contaron las filas de los `INSERT`; no se incluyen datos.

## Archivos

- [diccionario_datos.md](diccionario_datos.md): documento principal con tablas, columnas, vistas, triggers, rutinas y observaciones.
- [diccionario_datos.xlsx](diccionario_datos.xlsx): hojas Resumen, Tablas, Columnas, Relaciones, Vistas, Triggers, Rutinas.
- [diagrama_er.mmd](diagrama_er.mmd): modelo entidad-relación en Mermaid `erDiagram`.
- [schema.dbml](schema.dbml): esquema DBML.

## Resumen ejecutivo

El DDL contiene {len(tables)} tablas, {len(views)} vistas, {len(triggers)} triggers, {len(procs)} procedimientos y {len(funcs)} funciones. Se regenera con `Practica03/scripts/generar_diccionario.py`.
""")

# ---------------------------------------------------------------- XLSX
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment
wb = openpyxl.Workbook(); wb.remove(wb.active)
def sheet(title, header, rows):
    ws = wb.create_sheet(title); ws.append(header)
    for r in rows: ws.append(list(r))
    for c in ws[1]:
        c.font = Font(bold=True, color="FFFFFF"); c.fill = PatternFill("solid", fgColor="1F3A5F")
    ws.freeze_panes = "A2"
    for i, col in enumerate(ws.columns, 1):
        w = max(len(str(c.value or "")) for c in col)
        ws.column_dimensions[openpyxl.utils.get_column_letter(i)].width = min(60, max(10, w + 2))
        for c in col: c.alignment = Alignment(wrap_text=True, vertical="top")
sheet("Resumen", ["Métrica", "Valor"], [("Base de datos", "db_test"), ("Fuente", fname), ("Versión MySQL", ver), ("Tablas", len(tables)), ("Vistas", len(views)), ("Triggers", len(triggers)), ("Procedimientos", len(procs)), ("Funciones", len(funcs)), ("Eventos", len(events)), ("Relaciones FK", len(rels))])
sheet("Tablas", ["Tabla", "Prefijo/tipo", "Motor", "Charset", "Collation", "Registros", "Columnas"], [(t["name"], PREF_TXT[prefix(t["name"])], t["engine"], t["charset"], t["collation"], t["rows"], len(t["cols"])) for t in tables.values()])
sheet("Columnas", ["Tabla", "#", "Columna", "Tipo", "¿Acepta NULL?", "Valor por defecto", "Extras", "Llave", "Descripción"], [(t["name"], i, c["name"], c["type"], "SÍ" if c["null"] else "NO", dflt(c), "; ".join(c["extras"]), keyname(c), describe(t, c)) for t in tables.values() for i, c in enumerate(t["cols"], 1)])
sheet("Relaciones", ["Constraint", "Tabla hija", "Columnas", "Tabla padre", "Columnas padre", "Cardinalidad"], [(r["name"], r["child"], ", ".join(r["cols"]), r["parent"], ", ".join(r["rcols"]), "1:1" if r["one"] else "1:N") for r in rels])
sheet("Vistas", ["Vista", "Tablas base", "Columnas"], [(v["name"], ", ".join(v["base"]), ", ".join(v["cols"])) for v in views.values()])
sheet("Triggers", ["Trigger", "Tabla", "Evento", "Momento", "Registra en tb_logs"], [(x["name"], x["table"], x["event"], x["when"], "Sí" if x["logs"] else "No") for x in triggers])
sheet("Eventos", ["Evento", "Programación", "Estado", "Descripción"], [(e["name"], e["schedule"], e["status"], e["comment"]) for e in events])
sheet("Rutinas", ["Tipo", "Nombre", "Parámetros", "Tablas tocadas", "Invoca"], [(r["kind"], r["name"], "; ".join(r["params"]), ", ".join(r["touched"]), ", ".join(r["calls"])) for r in routines])
wb.save(os.path.join(OUT, "diccionario_datos.xlsx"))

print(f"tablas={len(tables)} vistas={len(views)} triggers={len(triggers)} procs={len(procs)} funcs={len(funcs)} fks={len(rels)}")
print({t['name']: t['rows'] for t in tables.values()})
