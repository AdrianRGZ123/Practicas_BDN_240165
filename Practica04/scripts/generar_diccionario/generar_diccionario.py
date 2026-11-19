# -*- coding: utf-8 -*-
"""Genera Practica04/diccionario_datos/ (schema.dbml, diagrama_er.mmd, diccionario_datos.md,
diccionario_datos.xlsx) leyendo la estructura real de db_test desde information_schema.

Uso:  python generar_diccionario.py            (variables opcionales: MYSQL_BIN, MYSQL_USER, MYSQL_PASS, MYSQL_HOST, MYSQL_PORT)
"""
import os, re, subprocess, sys, datetime
from collections import OrderedDict, defaultdict
sys.path.insert(0, os.path.dirname(__file__))
from descripciones import TABLAS, COMUN, ESP, PROCS, VR

BIN = os.environ.get("MYSQL_BIN", r"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe")
USER = os.environ.get("MYSQL_USER", "adrian.rios")
PWD = os.environ.get("MYSQL_PASS", "240165")
HOST = os.environ.get("MYSQL_HOST", "127.0.0.1")
PORT = os.environ.get("MYSQL_PORT", "40165")
DB = "db_test"
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "diccionario_datos"))
os.makedirs(OUT, exist_ok=True)
HOY = datetime.date.today().strftime("%d-%m-%Y")


def q(sql, header=False):
    cmd = [BIN, f"-u{USER}", f"-p{PWD}", f"-h{HOST}", f"-P{PORT}", "--default-character-set=utf8mb4",
           "-B", "--raw", DB, "-e", "SET SESSION group_concat_max_len=1000000; " + sql]
    if not header:
        cmd.insert(-3, "-N")
    r = subprocess.run(cmd, capture_output=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.decode("utf-8", "replace"))
    txt = r.stdout.decode("utf-8").replace("\r", "")
    return [l.split("\t") for l in txt.split("\n") if l != ""]


# ---------------------------------------------------------------- metadatos
tablas = [r[0] for r in q("SELECT table_name FROM information_schema.tables WHERE table_schema='db_test' AND table_type='BASE TABLE' ORDER BY table_name")]
vistas = [r[0] for r in q("SELECT table_name FROM information_schema.views WHERE table_schema='db_test' ORDER BY table_name")]
conteo_sql = " UNION ALL ".join(f"SELECT '{t}', COUNT(*) FROM `{t}`" for t in tablas)
conteos = {r[0]: int(r[1]) for r in q(conteo_sql)}
motor = {r[0]: (r[1], r[2]) for r in q("SELECT table_name, engine, table_collation FROM information_schema.tables WHERE table_schema='db_test' AND table_type='BASE TABLE'")}

cols = OrderedDict((t, []) for t in tablas)
for r in q("SELECT table_name, column_name, column_type, is_nullable, IFNULL(column_default,'@@NULL@@'), extra, column_key, IFNULL(generation_expression,'') "
           "FROM information_schema.columns WHERE table_schema='db_test' ORDER BY table_name, ordinal_position"):
    if r[0] in cols:
        dflt = None if r[4] == "@@NULL@@" else r[4]
        if dflt is not None and r[2].startswith("bit") and len(dflt) == 1 and ord(dflt) < 32:
            dflt = "b'%d'" % ord(dflt)
        cols[r[0]].append(dict(name=r[1], type=r[2], null=(r[3] == "YES"), default=dflt,
                               extra=r[5], key=r[6], gen=r[7]))

idx = defaultdict(lambda: OrderedDict())
for r in q("SELECT table_name, index_name, non_unique, column_name FROM information_schema.statistics WHERE table_schema='db_test' ORDER BY table_name, index_name, seq_in_index"):
    d = idx[r[0]].setdefault(r[1], dict(unique=(r[2] == "0"), cols=[]))
    d["cols"].append(r[3])

fks = OrderedDict()
for r in q("SELECT k.table_name, k.constraint_name, k.column_name, k.referenced_table_name, k.referenced_column_name, rc.delete_rule, rc.update_rule "
           "FROM information_schema.key_column_usage k JOIN information_schema.referential_constraints rc "
           "ON rc.constraint_schema=k.constraint_schema AND rc.constraint_name=k.constraint_name AND rc.table_name=k.table_name "
           "WHERE k.table_schema='db_test' AND k.referenced_table_name IS NOT NULL ORDER BY k.table_name, k.constraint_name, k.ordinal_position"):
    f = fks.setdefault((r[0], r[1]), dict(table=r[0], name=r[1], cols=[], rtable=r[3], rcols=[], dele=r[5], upd=r[6]))
    f["cols"].append(r[2]); f["rcols"].append(r[4])
fks = list(fks.values())

checks = defaultdict(list)
for r in q("SELECT tc.table_name, cc.constraint_name, cc.check_clause FROM information_schema.check_constraints cc "
           "JOIN information_schema.table_constraints tc ON tc.constraint_schema=cc.constraint_schema AND tc.constraint_name=cc.constraint_name "
           "WHERE tc.table_schema='db_test' AND tc.constraint_type='CHECK' ORDER BY 1,2"):
    checks[r[0]].append((r[1], r[2]))

trig = defaultdict(list)
for r in q("SELECT event_object_table, trigger_name, action_timing, event_manipulation FROM information_schema.triggers WHERE trigger_schema='db_test' ORDER BY 1,2"):
    trig[r[0]].append(r[1:])

rutinas = q("SELECT routine_type, routine_name FROM information_schema.routines WHERE routine_schema='db_test' ORDER BY routine_type, routine_name")
params = defaultdict(list)
for r in q("SELECT specific_name, parameter_mode, parameter_name, dtd_identifier FROM information_schema.parameters WHERE specific_schema='db_test' AND parameter_name IS NOT NULL ORDER BY specific_name, ordinal_position"):
    params[r[0]].append(f"{r[1]} {r[2]} {r[3]}")
ret_fn = {r[0]: r[1] for r in q("SELECT specific_name, dtd_identifier FROM information_schema.parameters WHERE specific_schema='db_test' AND ordinal_position=0")}

# ejemplos reales (primer valor no nulo de cada columna)
ejemplos = {}
for t in tablas:
    sel = ", ".join(f"(SELECT `{c['name']}` FROM `{t}` WHERE `{c['name']}` IS NOT NULL LIMIT 1)" for c in cols[t])
    row = q("SELECT " + sel)
    row = row[0] if row else []
    row += [""] * (len(cols[t]) - len(row))
    for c, v in zip(cols[t], row):
        ejemplos[(t, c["name"])] = v


def ej(t, c):
    v = ejemplos.get((t, c["name"]), "")
    if v in ("", "NULL"):
        return "NULL"
    if c["name"] == "password":
        return "`" + v[:12] + "…` (hash)"
    if c["type"].startswith("bit"):
        return "1" if ("\x01" in v or v == "1") else "0"
    v = v.replace("|", "/").replace("\\n", " ")
    return "`" + (v[:42] + "…" if len(v) > 43 else v) + "`"


def is_gen(c):
    return "STORED GENERATED" in c["extra"].upper() or "VIRTUAL GENERATED" in c["extra"].upper()


def desc(t, c):
    n = c["name"]
    if (t, n) in ESP:
        return ESP[(t, n)]
    if n in COMUN:
        return COMUN[n]
    return "Sin descripción " + VR


def base_tipo(ty):
    return re.match(r"[a-z]+", ty).group(0)


pk = {t: [c["name"] for c in cols[t] if c["key"] == "PRI"] for t in tablas}
pk_idx = {}
fk_por_col = defaultdict(list)
for f in fks:
    for a, b in zip(f["cols"], f["rcols"]):
        fk_por_col[(f["table"], a)].append(f"{f['rtable']}.{b}")
uq_cols = defaultdict(set)
for t in tablas:
    for n, d in idx[t].items():
        if d["unique"] and n != "PRIMARY":
            for c in d["cols"]:
                uq_cols[t].add(c)


def restricciones(t, c):
    r = []
    if c["name"] in pk[t]:
        r.append("PK")
    for ref in fk_por_col.get((t, c["name"]), []):
        r.append(f"FK→{ref}")
    if not c["null"]:
        r.append("NN")
    if c["name"] in uq_cols[t]:
        r.append("UQ")
    if "auto_increment" in c["extra"]:
        r.append("AI")
    if is_gen(c):
        r.append("GEN")
    if c["default"] is not None and "GENERATED" not in c["extra"].upper():
        r.append("DEF=" + c["default"])
    return ", ".join(r) if r else "—"


def clase(t):
    return {"tb_": "Transaccional / maestra", "tbc": "Catálogo", "tbd": "Detalle / asociativa"}[t[:3]]


# ---------------------------------------------------------------- relaciones
def cardinalidad(f):
    t, cs = f["table"], f["cols"]
    unico = any(d["unique"] and d["cols"] == cs for d in idx[t].values())
    nulo = any(c["null"] for c in cols[t] if c["name"] in cs)
    padre = "|o" if nulo else "||"
    hijo = "o|" if unico else "o{"
    return padre, hijo, unico, nulo


# ================================================================ schema.dbml
def dbml_default(c):
    d = c["default"]
    if d is None or is_gen(c):
        return None
    if "DEFAULT_GENERATED" in c["extra"] or d.startswith("b'") or d.upper().startswith("CURRENT_TIMESTAMP"):
        return f"`{d}`"
    if re.fullmatch(r"-?\d+(\.\d+)?", d):
        return d
    return "'" + d.replace("'", "\\'") + "'"


enums = OrderedDict()
lines = ["Project db_test {", '  database_type: "MySQL"',
         f'  Note: "Práctica 04 - Procesos de simulación de compra. Esquema generado desde db_test (MySQL 8.0.42) el {HOY}. Convención: tb_ maestras/transaccionales, tbc_ catálogos, tbd_ detalle y asociativas."', "}", ""]
cuerpo = []
for t in tablas:
    b = [f"Table {t} {{"]
    for c in cols[t]:
        ty = c["type"]
        m = re.match(r"enum\((.*)\)", ty)
        if m:
            vals = re.findall(r"'([^']*)'", m.group(1))
            en = f"{t}_{c['name']}"
            enums[en] = vals
            ty = en
        else:
            ty = ty.replace(" unsigned", "")
        at = []
        if c["name"] in pk[t] and len(pk[t]) == 1:
            at.append("pk")
        if not c["null"]:
            at.append("not null")
        if "auto_increment" in c["extra"]:
            at.append("increment")
        if len(idx[t]) and any(d["unique"] and d["cols"] == [c["name"]] and n != "PRIMARY" for n, d in idx[t].items()):
            at.append("unique")
        dv = dbml_default(c)
        if dv is not None:
            at.append(f"default: {dv}")
        nota = desc(t, c).replace("'", "’").replace("\n", " ")
        at.append(f"note: '{nota}'")
        b.append(f"  {c['name']} {ty} [{', '.join(at)}]")
    ix = []
    if len(pk[t]) > 1:
        ix.append(f"    ({', '.join(pk[t])}) [pk]")
    for n, d in idx[t].items():
        if n == "PRIMARY":
            continue
        if len(d["cols"]) == 1 and d["unique"]:
            continue
        cs = d["cols"][0] if len(d["cols"]) == 1 else "(" + ", ".join(d["cols"]) + ")"
        ix.append(f"    {cs} [{'unique, ' if d['unique'] else ''}name: '{n}']")
    if ix:
        b.append("  Indexes {"); b += ix; b.append("  }")
    b.append(f"  Note: '{TABLAS[t][1].replace(chr(39), chr(8217))}'")
    b.append("}")
    cuerpo.append("\n".join(b))
for en, vals in enums.items():
    lines.append(f"enum {en} {{")
    lines += [f'  "{v}"' for v in vals]
    lines += ["}", ""]
lines += [x + "\n" for x in cuerpo]
for f in fks:
    a = f["cols"][0] if len(f["cols"]) == 1 else "(" + ", ".join(f["cols"]) + ")"
    b = f["rcols"][0] if len(f["rcols"]) == 1 else "(" + ", ".join(f["rcols"]) + ")"
    _, _, unico, _ = cardinalidad(f)
    op = "-" if unico else ">"
    lines.append(f"Ref {f['name']}: {f['table']}.{a} {op} {f['rtable']}.{b} [delete: {f['dele'].lower().replace(' ', ' ')}]")
open(os.path.join(OUT, "schema.dbml"), "w", encoding="utf-8").write("\n".join(lines) + "\n")

# ================================================================ diagrama_er.mmd
mm = ["erDiagram"]
for f in fks:
    p, h, _, _ = cardinalidad(f)
    mm.append(f'    {f["rtable"]} {p}--{h} {f["table"]} : "{", ".join(f["cols"])}"')
mm.append("")
for t in tablas:
    mm.append(f"    {t} {{")
    fkc = {c for f in fks if f["table"] == t for c in f["cols"]}
    uq1 = {d["cols"][0] for n, d in idx[t].items() if d["unique"] and len(d["cols"]) == 1}
    for c in cols[t]:
        k = []
        if c["name"] in pk[t]:
            k.append("PK")
        if c["name"] in fkc:
            k.append("FK")
        if c["name"] in uq1 and "PK" not in k:
            k.append("UK")
        if k:  # el diagrama muestra solo atributos clave (PK / FK / UK)
            mm.append(f"        {base_tipo(c['type'])} {c['name']} {','.join(k)}")
    mm.append("    }")
MERMAID = "\n".join(mm) + "\n"
open(os.path.join(OUT, "diagrama_er.mmd"), "w", encoding="utf-8").write(MERMAID)

# ================================================================ diccionario_datos.md
def desc_vista(v):
    esp = {"vw_available_products": "Productos activos con proveedor activo y existencias > 0; base del catálogo para el carrito.",
           "vw_cart_to_order": "Une cada carrito con la orden que generó (si existe), con sus unidades y estado.",
           "vw_user_addresses_full": "Domicilios con la jerarquía vertical de tbd_address_components aplanada en columnas.",
           "vw_order_detail": "Trazabilidad orden → suborden de vendedor → producto con unidades canceladas y subtotal vigente.",
           "vw_total_products_by_category": "Conteo de productos por categoría.",
           "vw_total_products_by_category1": "Variante del conteo de productos por categoría."}
    if v in esp:
        return esp[v]
    return "Consulta de trazabilidad: operaciones de auditoría de `tb_logs` relativas a " + v.replace("vw_trazabilidad_", "") + "."

md = []
w = md.append
w("# Diccionario de datos — `db_test` (Práctica 04)\n")
w(f"> Fuente: estructura real de la base `db_test` (MySQL 8.0.42) leída de `information_schema` el {HOY} (equivale a `backups/Respaldo 18-11-26.sql`). Las marcas `{VR}` señalan reglas inferidas que el DDL no puede confirmar.\n")
w("## Índice\n")
for i, s in enumerate(["Análisis de nomenclatura y convenciones", "Resumen ejecutivo", "Entidades y relaciones", "Tablas y columnas", "Vistas", "Procedimientos y funciones", "Triggers", "Reglas de integridad y flujos de estado", "Pendientes por confirmar", "Diagrama entidad-relación"], 1):
    w(f"{i}. [{s}](#{re.sub(r'[^a-z0-9 áéíóúñ-]', '', s.lower()).replace(' ', '-')})")
w("\n## Análisis de nomenclatura y convenciones\n")
w("La base ya sigue una convención consistente que se **respeta** (no se renombran objetos):\n")
w("| Elemento | Convención | Ejemplos |\n|---|---|---|")
w("| Prefijo `tb_` | Tabla maestra o transaccional (entidad principal del negocio) | `tb_users`, `tb_orders`, `tb_payments` |")
w("| Prefijo `tbc_` | Tabla **c**atálogo (valores de referencia poco cambiantes) | `tbc_categories`, `tbc_payment_methods_types` |")
w("| Prefijo `tbd_` | Tabla de **d**etalle o asociativa N:M (depende de otra entidad) | `tbd_order_items`, `tbd_products_categories` |")
w("| Prefijo `vw_` / `sp_` / `fn_` / `trg_` | Vista / procedimiento / función / trigger | `vw_order_detail`, `sp_ship_order` |")
w("| Columnas | `snake_case` en minúsculas con sufijo `_date`/`_at` para fechas, `_status` para estados, `_ID` para llaves | `creation_date`, `shipment_status`, `buyer_order_ID` |")
w("| Llave primaria | `ID` autoincremental (excepciones: `tb_products.id`, `tb_people.person_ID`, PK compuestas en tablas asociativas) | `tb_orders.ID` |")
w("| Llave foránea | `<rol>_ID` apuntando a la PK de la entidad referenciada; el rol aclara el papel (`seller_ID`, `requested_by_user_ID`) | `cart_ID`, `address_sup_ID` |")
w("| Índices | `idx_<tabla/uso>` (no único), `uk_<uso>` (único), `fk_<...>` (FK), `chk_<...>` (CHECK) | `uk_orders_cart`, `chk_cart_quantity` |")
w("| Auditoría | `creation_date`, `last_update`, `status` (baja lógica) en casi todas las tablas | — |\n")
w("**Inconsistencias detectadas (no corregidas para no romper la base):** `tb_orders.User_ID` y `tb_products.id` usan capitalización distinta al resto; `tb_orders.status_string` guarda el estado y `status` la baja lógica; `tb_orders.key` usa una palabra reservada (requiere comillas invertidas). Las tablas `tb_` mezclan entidades transaccionales y de detalle.\n")
w("**Tipos de dato:** `int`/`bigint unsigned` para llaves; `decimal(12,2)` para importes de órdenes y `decimal(10,2)` en pagos; `bit(1)` para banderas de baja lógica; `enum` para estados cerrados; `varchar` con longitud acorde al dominio; `datetime` para marcas de tiempo.\n")

w("## Resumen ejecutivo\n")
w("| Elemento | Conteo |\n|---|---:|")
w(f"| Tablas | {len(tablas)} |\n| Vistas | {len(vistas)} |\n| Triggers | {sum(len(v) for v in trig.values())} |")
w(f"| Procedimientos | {sum(1 for r in rutinas if r[0]=='PROCEDURE')} |\n| Funciones | {sum(1 for r in rutinas if r[0]=='FUNCTION')} |\n| Llaves foráneas | {len(fks)} |\n")
w("Registros por tabla:\n")
w("| Tabla | Tipo | Registros |\n|---|---|---:|")
for t in sorted(tablas, key=lambda x: -conteos[x]):
    w(f"| `{t}` | {clase(t)} | {conteos[t]:,} |".replace(",", " "))
w("\nLos registros de las tablas de compra provienen de los 5 casos de prueba de la Práctica 04; `tb_seller_orders` es réplica de `tbd_buyer_orders` y `tbd_users_wishlist_products` tiene 3 registros de ejemplo.\n")

w("## Entidades y relaciones\n")
w("| Tabla padre | Columna(s) | Tabla hija | Columna(s) FK | Cardinalidad | ON DELETE |\n|---|---|---|---|---|---|")
for f in fks:
    p, h, unico, nulo = cardinalidad(f)
    card = ("1 : 0..1" if unico else "1 : N") if not nulo else ("0..1 : 0..1" if unico else "0..1 : N")
    w(f"| `{f['rtable']}` | `{', '.join(f['rcols'])}` | `{f['table']}` | `{', '.join(f['cols'])}` | {card} | {f['dele']} |")
w("")

w("## Tablas y columnas\n")
for t in tablas:
    w(f"### `{t}`\n")
    w(f"**Tipo:** {clase(t)} · **Rol:** {TABLAS[t][0]} · **Motor:** {motor[t][0]} · **Registros:** {conteos[t]:,}".replace(",", " "))
    w(f"\n{TABLAS[t][1]}\n")
    w("| Campo (Nomenclatura) | Tipo de dato | Restricciones | Descripción funcional y de negocio | Ejemplo de valor |\n|---|---|---|---|---|")
    for c in cols[t]:
        ty = c["type"] + (f" = {c['gen']}" if c["gen"] else "")
        w(f"| `{c['name']}` | `{ty}` | {restricciones(t, c)} | {desc(t, c).replace('|', '/')} | {ej(t, c)} |")
    extra = []
    for n, d in idx[t].items():
        if n == "PRIMARY":
            continue
        extra.append(f"- Índice {'único' if d['unique'] else 'no único'} `{n}` sobre ({', '.join(d['cols'])})")
    for n, cl in checks[t]:
        extra.append(f"- CHECK `{n}`: `{cl.replace(chr(10), ' ')}`")
    for f in fks:
        if f["table"] == t:
            extra.append(f"- FK `{f['name']}`: ({', '.join(f['cols'])}) → `{f['rtable']}` ({', '.join(f['rcols'])}), ON DELETE {f['dele']}")
    if trig[t]:
        extra.append(f"- Triggers: {len(trig[t])} ({', '.join(sorted({x[1].lower()+' '+x[2].lower() for x in trig[t]}))}) que registran la auditoría en `tb_logs`")
    if extra:
        w("\n" + "\n".join(extra))
    w("")

w("## Vistas\n")
w("| Vista | Propósito |\n|---|---|")
for v in vistas:
    w(f"| `{v}` | {desc_vista(v)} |")
w("")

w("## Procedimientos y funciones\n")
w("| Procedimiento | Quién lo ejecuta | Parámetros | Propósito |\n|---|---|---|---|")
for tp, n in rutinas:
    if tp == "PROCEDURE":
        quien, prop = PROCS.get(n, ("Administración", "Carga masiva o mantenimiento de datos de prueba (Práctica 03)."))
        w(f"| `{n}` | {quien} | {', '.join(params[n]) or '—'} | {prop} |")
w("\n| Función | Parámetros | Retorna |\n|---|---|---|")
for tp, n in rutinas:
    if tp == "FUNCTION":
        w(f"| `{n}` | {', '.join(params[n]) or '—'} | `{ret_fn.get(n, '')}` |")
w("")

w("## Triggers\n")
w(f"Hay {sum(len(v) for v in trig.values())} triggers. Casi todos son de auditoría (`AFTER INSERT/UPDATE/DELETE` → `tb_logs`). Triggers de validación del flujo de compra:\n")
w("- `trg_tbd_cart_items_before_insert`: exige carrito activo y producto disponible con existencias suficientes.\n- `trg_tbd_cart_items_before_update` / `before_delete`: impiden modificar un carrito ya convertido en orden.\n")
w("| Tabla | Triggers |\n|---|---:|")
for t in tablas:
    if trig[t]:
        w(f"| `{t}` | {len(trig[t])} |")
w("")

w("## Reglas de integridad y flujos de estado\n")
w("- **Carrito → orden:** `tb_orders.cart_ID` es UNIQUE; un usuario tiene como máximo un carrito activo (`tb_carts.active_user_ID` UNIQUE).")
w("- **Orden → suborden → línea:** `tb_orders` 1:N `tbd_buyer_orders` (UNIQUE `order_ID`+`seller_ID`) 1:N `tbd_order_items`; las líneas usan FK compuesta (`provider_ID`,`product_ID`) a `tbd_products_users_providers`.")
w("- **Ciclo de la orden (`tb_orders.status_string`):** `Registered → Payed → Attended → Sended → Delivered`; ramas `Canceled` (sin inventario o cancelación total) y `Devolved` (devolución en curso, regresa a `Delivered` tras el reenvío).")
w("- **Inventario:** se valida al agregar al carrito y al crear la orden, y se descuenta al atender la orden (`sp_process_order`); se repone con cancelaciones.")
w("- **Pagos:** `UNIQUE(order_ID, installment_number)`; solo la tarjeta de crédito admite hasta 12 mensualidades; el cupón de regalo se liquida al instante y se libera si la orden se cancela.")
w("- **Domicilios:** árbol de 10 niveles; FK compuesta `(address_ID, address_sup_ID)` → `(address_ID, ID)` garantiza que el superior pertenezca al mismo domicilio; la raíz (País) lleva `address_sup_ID` NULL.")
w("- **Cancelaciones:** `chk_cancellations_target` obliga a que `WholeOrder` use `order_ID` y `SellerOrder/Items` usen `buyer_order_ID`; `tb_refunds.chk_refunds_source` liga cada reembolso a su origen.")
w("- **Catálogos:** `tbc_payment_methods_types` (6 tipos), `tb_payment_methods` (6 formas, cada una ligada a un tipo), `tbc_categories` (100 categorías).")
w("- **Privilegios:** el comprador (`app_web`/`app_movil`) opera con roles `user_not_registered` y `buyer`; los pasos de sistema (autorizar, atender, enviar, reembolsar) los ejecuta `adrian.rios` (superadmin).\n")

w("## Pendientes por confirmar\n")
w(f"- `tb_people.gender_ID` no tiene tabla catálogo; significado de cada clave {VR}.")
w(f"- `tbc_categories.sup_id_category`: valor usado para categorías raíz (NULL o 0) {VR}.")
w(f"- Unicidad del domicilio predeterminado por usuario (`is_default`) no está forzada por el esquema {VR}.")
w(f"- `tb_seller_orders` no tiene FK hacia `tb_orders`; su relación depende del ID compartido con `tbd_buyer_orders` {VR}.")
w(f"- Almacenar la cuenta simulada de 16 dígitos completa en `tbd_user_payment_methods.provider_method_ref` es válido solo para pruebas; en producción debería guardarse un token {VR}.")
w(f"- Pagos en efectivo con método registrado de tarjeta Spin/SPEI (casos 3 y 4): la forma de pago efectiva se guarda en `tb_payments.payment_method_ID` {VR}.\n")

w("## Diagrama entidad-relación\n")
w("El mismo diagrama está en [diagrama_er.mmd](diagrama_er.mmd).\n")
w("```mermaid\n" + MERMAID + "```")
open(os.path.join(OUT, "diccionario_datos.md"), "w", encoding="utf-8").write("\n".join(md) + "\n")

# ================================================================ diccionario_datos.xlsx
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

wb = Workbook()
HDR = PatternFill("solid", fgColor="1F4E78")
thin = Side(style="thin", color="BFBFBF")


CLEAN = re.compile("[\x00-\x08\x0b\x0c\x0e-\x1f]")


def hoja(nombre, enc, filas, anchos):
    ws = wb.create_sheet(nombre)
    ws.append(enc)
    for f in filas:
        ws.append([CLEAN.sub("", x) if isinstance(x, str) else x for x in f])
    for c in ws[1]:
        c.font = Font(bold=True, color="FFFFFF"); c.fill = HDR
        c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    for i, a in enumerate(anchos, 1):
        ws.column_dimensions[get_column_letter(i)].width = a
    for row in ws.iter_rows(min_row=2):
        for c in row:
            c.alignment = Alignment(vertical="top", wrap_text=True)
            c.border = Border(top=thin, bottom=thin, left=thin, right=thin)
    ws.freeze_panes = "A2"
    ws.auto_filter.ref = ws.dimensions
    return ws


wb.remove(wb.active)
sal = defaultdict(list); ent = defaultdict(list)
for f in fks:
    sal[f["table"]].append(f["rtable"]); ent[f["rtable"]].append(f["table"])
hoja("Resumen_Entidades", ["Tabla", "Prefijo / tipo", "Rol", "Propósito de negocio", "Columnas", "Registros", "Llave primaria", "Referencia a (FK salientes)", "Referenciada por (FK entrantes)", "Triggers"],
     [[t, clase(t), TABLAS[t][0], TABLAS[t][1], len(cols[t]), conteos[t], ", ".join(pk[t]), ", ".join(sorted(set(sal[t]))) or "—", ", ".join(sorted(set(ent[t]))) or "—", len(trig[t])] for t in tablas],
     [30, 24, 16, 70, 10, 11, 20, 38, 44, 9])
filas = []
for t in tablas:
    for i, c in enumerate(cols[t], 1):
        filas.append([t, i, c["name"], c["type"] + (f" = {c['gen']}" if c["gen"] else ""), restricciones(t, c), "Sí" if c["null"] else "No",
                      c["default"] if c["default"] is not None else "", desc(t, c), ej(t, c).strip("`")])
hoja("Diccionario_Campos", ["Tabla", "#", "Campo", "Tipo de dato", "Restricciones", "Acepta NULL", "Valor por defecto", "Descripción funcional y de negocio", "Ejemplo de valor"],
     filas, [28, 5, 26, 24, 34, 9, 20, 80, 30])
filas = []
for f in fks:
    p, h, unico, nulo = cardinalidad(f)
    filas.append([f["name"], f["table"], ", ".join(f["cols"]), f["rtable"], ", ".join(f["rcols"]),
                  ("1 : 0..1" if unico else "1 : N") if not nulo else ("0..1 : 0..1" if unico else "0..1 : N"), f["dele"], f["upd"]])
hoja("Relaciones", ["Restricción", "Tabla hija", "Columna(s) FK", "Tabla padre", "Columna(s) referenciada(s)", "Cardinalidad", "ON DELETE", "ON UPDATE"], filas, [32, 28, 26, 28, 26, 14, 12, 12])
hoja("Vistas", ["Vista", "Propósito"], [[v, desc_vista(v)] for v in vistas], [40, 100])
hoja("Procedimientos", ["Procedimiento", "Quién lo ejecuta", "Parámetros", "Propósito"],
     [[n, *PROCS.get(n, ("Administración", "Carga masiva o mantenimiento de datos de prueba (Práctica 03).")) [:1], ", ".join(params[n]), PROCS.get(n, ("", "Carga masiva o mantenimiento de datos de prueba (Práctica 03)."))[1]] for tp, n in rutinas if tp == "PROCEDURE"],
     [32, 20, 70, 70])
hoja("Restricciones_CHECK", ["Tabla", "Restricción", "Condición"], [[t, n, cl] for t in tablas for n, cl in checks[t]], [28, 36, 90])
wb.save(os.path.join(OUT, "diccionario_datos.xlsx"))

# ================================================================ README.md
readme = f"""# Diccionario de datos de `db_test` — Práctica 04

Documentación de la base `db_test` tal como queda tras la Práctica 04 (procesos de simulación de compra), generada el {HOY} a partir de la base restaurada de `backups/Respaldo 18-11-26.sql`.

## Archivos

| Archivo | Contenido |
|---|---|
| [diccionario_datos.md](diccionario_datos.md) | Documento principal: convenciones de nomenclatura, resumen, relaciones, una tabla por entidad (campo, tipo, restricciones, descripción de negocio y ejemplo), vistas, procedimientos, triggers, reglas de integridad y pendientes. |
| [diccionario_datos.xlsx](diccionario_datos.xlsx) | Mismo contenido en hojas filtrables: `Resumen_Entidades`, `Diccionario_Campos`, `Relaciones`, `Vistas`, `Procedimientos` y `Restricciones_CHECK`. |
| [diagrama_er.mmd](diagrama_er.mmd) | Diagrama entidad-relación en Mermaid (`erDiagram`): {len(tablas)} entidades y {len(fks)} relaciones. |
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

`tb_` tabla maestra/transaccional · `tbc_` catálogo · `tbd_` detalle o asociativa · `vw_` vista · `sp_` procedimiento. Columnas en `snake_case`; llaves foráneas `<rol>_ID`. Las reglas inferidas se marcan como `{VR}`.
"""
open(os.path.join(OUT, "README.md"), "w", encoding="utf-8").write(readme)
print("OK", OUT, len(tablas), "tablas", len(fks), "FK")
sin = [(t, c["name"]) for t in tablas for c in cols[t] if desc(t, c).startswith("Sin descripción")]
print("sin descripción:", sin)
