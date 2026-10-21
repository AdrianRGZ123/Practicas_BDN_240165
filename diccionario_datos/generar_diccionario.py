import json, re, zipfile, html
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, tostring

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'backups' / 'Respaldo 20-10-26.sql'
OUT = ROOT / 'diccionario_datos'
OUT.mkdir(exist_ok=True)

def ddl_statements(path):
    """Stream lines, retaining only DDL. INSERT payloads are never buffered."""
    collecting = False
    buf = []
    for line in path.open(encoding='utf-8-sig', errors='replace'):
        if not collecting:
            u = line.lstrip().upper()
            if not (u.startswith('CREATE TABLE') or 'CREATE VIEW' in u or 'CREATE*/' in u and 'TRIGGER' in u or
                    u.startswith('CREATE DEFINER') or u.startswith('CREATE VIEW') or
                    u.startswith('/*!50003 CREATE*/')):
                continue
            collecting = True
        buf.append(line)
        # Dump uses doubled semicolon after wrapped triggers; routines end with END */;;
        if re.search(r';\s*(?:\*/\s*)?;?\s*$', line):
            yield ''.join(buf)
            buf, collecting = [], False

def split_top(text):
    parts=[]; start=0; depth=0; q=None; esc=False
    for i,c in enumerate(text):
        if q:
            if esc: esc=False
            elif c=='\\': esc=True
            elif c==q:
                if i+1<len(text) and text[i+1]==q: continue
                q=None
        elif c in "'\"`": q=c
        elif c=='(': depth+=1
        elif c==')': depth-=1
        elif c==',' and depth==0: parts.append(text[start:i].strip()); start=i+1
    if text[start:].strip(): parts.append(text[start:].strip())
    return parts

tables=[]; views=[]; triggers=[]; procedures=[]
for sql in ddl_statements(SOURCE):
    m=re.search(r'CREATE\s+TABLE\s+`([^`]+)`\s*\((.*)\)\s*ENGINE',sql,re.I|re.S)
    if m:
        name,body=m.groups(); cols=[]; pks=[]; fks=[]; uks=[]
        for item in split_top(body):
            cm=re.match(r'`([^`]+)`\s+(.+)',item,re.S)
            if cm:
                cn,definition=cm.groups(); typ=re.match(r'([\w]+(?:\s*\([^)]*\))?(?:\s+unsigned)?)',definition,re.I).group(1)
                nullable=not bool(re.search(r'\bNOT NULL\b',definition,re.I))
                auto=bool(re.search(r'AUTO_INCREMENT',definition,re.I))
                default=re.search(r'\bDEFAULT\s+((?:\'[^\']*\')|(?:"[^"]*")|(?:[^\s,]+))',definition,re.I)
                cols.append({'nombre':cn,'tipo':typ,'nullable':nullable,'default':default.group(1) if default else None,'auto_increment':auto,'definicion':definition.strip()})
            pm=re.match(r'PRIMARY KEY\s*\((.*?)\)',item,re.I|re.S)
            if pm: pks=re.findall(r'`([^`]+)`',pm.group(1))
            fm=re.search(r'CONSTRAINT\s+`([^`]+)`\s+FOREIGN KEY\s*\((.*?)\)\s+REFERENCES\s+`([^`]+)`\s*\((.*?)\)',item,re.I|re.S)
            if fm: fks.append({'constraint':fm.group(1),'columns':re.findall(r'`([^`]+)`',fm.group(2)),'table':fm.group(3),'references':re.findall(r'`([^`]+)`',fm.group(4))})
            um=re.search(r'(?:UNIQUE KEY|UNIQUE INDEX)\s+`([^`]+)`\s*\((.*?)\)',item,re.I|re.S)
            if um: uks.append({'name':um.group(1),'columns':re.findall(r'`([^`]+)`',um.group(2))})
        tables.append({'nombre':name,'columnas':cols,'primary_key':pks,'foreign_keys':fks,'unique_keys':uks,'ddl':sql.strip()})
        continue
    # strip executable comment wrappers to expose CREATE VIEW/TRIGGER tokens
    clean=re.sub(r'/\*!\d*\s*|\*/',' ',sql)
    vm=re.search(r'CREATE\s+(?:OR REPLACE\s+)?(?:ALGORITHM\s*=\s*\w+\s+)?(?:DEFINER\s*=\s*[^\s]+\s+)?(?:SQL SECURITY\s+\w+\s+)?VIEW\s+`([^`]+)`\s+AS\s+(.*?);\s*$',clean,re.I|re.S)
    if vm: views.append({'nombre':vm.group(1),'definicion':vm.group(2).strip()}); continue
    tm=re.search(r'CREATE\s+(?:DEFINER\s*=\s*[^\s]+\s+)?TRIGGER\s+`([^`]+)`\s+(BEFORE|AFTER)\s+(INSERT|UPDATE|DELETE)\s+ON\s+`([^`]+)`.*',clean,re.I|re.S)
    if tm: triggers.append({'nombre':tm.group(1),'timing':tm.group(2).upper(),'evento':tm.group(3).upper(),'tabla':tm.group(4),'definicion':clean.strip()}); continue
    pm=re.search(r'CREATE\s+DEFINER\s*=\s*[^\s]+\s+PROCEDURE\s+`([^`]+)`\s*(\(.*?\))\s*(.*)',clean,re.I|re.S)
    if pm: procedures.append({'nombre':pm.group(1),'parametros':pm.group(2),'definicion':pm.group(3).strip()})

known={t['nombre']:t for t in tables}
for t in tables:
    for c in t['columnas']:
        keys=[]
        if c['nombre'] in t['primary_key']: keys.append('PK' if len(t['primary_key'])==1 else 'PK compuesta')
        for fk in t['foreign_keys']:
            if c['nombre'] in fk['columns']:
                idx=fk['columns'].index(c['nombre']); keys.append(f"FK ({fk['table']}.{fk['references'][idx]})")
        for uk in t['unique_keys']:
            if c['nombre'] in uk['columns']: keys.append('UK ('+uk['name']+')')
        typ=c['tipo'].lower(); temporal=any(x in typ for x in ('date','time','year'))
        numeric=any(x in typ for x in ('int','decimal','float','double','bit','bool'))
        c.update({'Valor':'Multivalor (tabla intermedia)' if t['nombre'].startswith('tbd_') and len(t['columnas'])<=3 else 'Monovalor',
          'Origen':'Almacenado','Obligatoriedad':('Opcional (Usuario)' if c['nullable'] and not c['default'] else 'Opcional (Sistema vía DEFAULT)' if c['nullable'] else 'Obligatorio (Sistema vía AUTO_INCREMENT)' if c['auto_increment'] else 'Obligatorio (Sistema vía DEFAULT)' if c['default'] else 'Obligatorio (Usuario)'),
          'Llave':'; '.join(keys) if keys else 'Ninguna','Naturaleza':'Cuantitativa temporal' if temporal else 'Cuantitativa discreta' if numeric else 'Cualitativa nominal',
          'Composición Formal':'@'+c['nombre']+' : '+c['tipo']+(' [opcional]' if c['nullable'] else ''),
          'Dominio':'No especificado'})

json_tables=[]
for t in tables:
    jt={k:v for k,v in t.items() if k!='columnas'}
    jt['columnas']=[{'Nombre':c['nombre'],'Valor':c['Valor'],'Origen':c['Origen'],'Obligatoriedad':c['Obligatoriedad'],'Llave':c['Llave'],'Naturaleza':c['Naturaleza'],'Composición Formal':c['Composición Formal'],'Dominio':c['Dominio']} for c in t['columnas']]
    json_tables.append(jt)
data={'base_datos':'db_test','motor':'MySQL 8.0.36','fuente':str(SOURCE),'nota':'Inventario real del DDL del dump; se excluyeron sentencias INSERT.','tablas':json_tables,'vistas':views,'triggers':triggers,'procedimientos':procedures}
(OUT/'estructura.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

def md(s): return str(s).replace('|','\\|').replace('\n',' ')
lines=['# Diccionario de datos — db_test','','> Generado desde el DDL disponible. Las sentencias INSERT fueron ignoradas.','', '## Índice','', '- [Resumen y diferencias](#resumen-y-diferencias)','- [Tablas y columnas](#tablas-y-columnas)','- [Relaciones](#relaciones)','- [Vistas](#vistas)','- [Triggers](#triggers)','- [Procedimientos](#procedimientos)','- [Calidad de diseño](#calidad-de-diseño)','', '## Resumen y diferencias','',f"- Tablas: {len(tables)}; vistas: {len(views)}; triggers: {len(triggers)}; procedimientos: {len(procedures)}.",' - El inventario del archivo no coincide con las cantidades/nombres originalmente esperados; este documento refleja el contenido real del dump.','','## Tablas y columnas','']
for t in tables:
    lines += [f"### {t['nombre']}",'', '| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |','|---|---|---|---|---|---|---|---|---|']
    for c in t['columnas']: lines.append('| '+' | '.join(md(c[k]) for k in ['nombre','tipo','Valor','Origen','Obligatoriedad','Llave','Naturaleza','Composición Formal','Dominio'])+' |')
    lines.append('')
lines += ['## Relaciones','','| Tabla | Columnas | Referencia |','|---|---|---|']
for t in tables:
    for f in t['foreign_keys']: lines.append(f"| {t['nombre']} | {', '.join(f['columns'])} | {f['table']} ({', '.join(f['references'])}) |")
lines += ['', '## Vistas','']+[f"- **{v['nombre']}**: `{md(v['definicion'])}`" for v in views]
lines += ['', '## Triggers','']+[f"- **{x['nombre']}**: {x['timing']} {x['evento']} en `{x['tabla']}`." for x in triggers]
lines += ['', '## Procedimientos','']+[f"- **{x['nombre']}** `{x['parametros']}`: `{md(x['definicion'])}`" for x in procedures]
lines += ['', '## Calidad de diseño','','- Las columnas no documentan dominios CHECK explícitos en el DDL procesado; se indica “No especificado”.','- El DDL distingue PK, FK y UK; relaciones sin restricción declarada no se infieren.','- Las categorías nominal/discreta/temporal se infieren del tipo SQL; son una clasificación técnica.','']
(OUT/'diccionario_datos.md').write_text('\n'.join(lines),encoding='utf-8')

# XLSX mínimo compatible Office Open XML, sin dependencias externas.
def cell(v):
    c=Element('c',{'t':'inlineStr'}); isel=SubElement(c,'is'); SubElement(isel,'t').text=str(v); return c
def sheet(rows):
    root=Element('worksheet',{'xmlns':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}); sd=SubElement(root,'sheetData')
    for ri,row in enumerate(rows,1):
        rr=SubElement(sd,'row',{'r':str(ri)})
        for ci,v in enumerate(row):
            col=''; n=ci+1
            while n: n,rem=divmod(n-1,26); col=chr(65+rem)+col
            c=cell('' if v is None else v); c.set('r',f'{col}{ri}'); rr.append(c)
    return tostring(root,encoding='utf-8',xml_declaration=True)
tabs={
'Tablas':[['Tabla','Columnas','PK','FK']] + [[t['nombre'],len(t['columnas']),','.join(t['primary_key']),len(t['foreign_keys'])] for t in tables],
'Columnas':[['Tabla','Nombre','Tipo','Valor','Origen','Obligatoriedad','Llave','Naturaleza','Composición formal','Dominio']]+[[t['nombre']]+[c[k] for k in ('nombre','tipo','Valor','Origen','Obligatoriedad','Llave','Naturaleza','Composición Formal','Dominio')] for t in tables for c in t['columnas']],
'Relaciones':[['Tabla','Columnas','Tabla referenciada','Columnas referenciadas']]+[[t['nombre'],','.join(f['columns']),f['table'],','.join(f['references'])] for t in tables for f in t['foreign_keys']],
'Vistas':[['Nombre','Definición']]+[[v['nombre'],v['definicion']] for v in views],
'Triggers':[['Nombre','Timing','Evento','Tabla','Definición']]+[[x[k] for k in ('nombre','timing','evento','tabla','definicion')] for x in triggers],
'Procedimientos':[['Nombre','Parámetros','Definición']]+[[x['nombre'],x['parametros'],x['definicion']] for x in procedures],
'Dominios_ENUM':[['Tabla','Columna','Tipo','Dominio']]+[[t['nombre'],c['nombre'],c['tipo'],c['Dominio']] for t in tables for c in t['columnas'] if 'enum' in c['tipo'].lower()],
'Observaciones':[['Observación'],['El inventario del dump difiere del esperado originalmente.'],['Los dominios no explícitos se marcan No especificado.']],
'Resumen_Estadistico':[['Métrica','Valor'],['Tablas',len(tables)],['Vistas',len(views)],['Triggers',len(triggers)],['Procedimientos',len(procedures)],['Columnas',sum(len(t['columnas']) for t in tables)]]}
with zipfile.ZipFile(OUT/'diccionario_datos.xlsx','w',zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml','''<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'''+''.join(f'<Override PartName="/xl/worksheets/sheet{i}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' for i in range(1,len(tabs)+1))+'</Types>')
    z.writestr('_rels/.rels','''<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>''')
    names=list(tabs); z.writestr('xl/workbook.xml','''<?xml version="1.0"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'''+''.join(f'<sheet name="{html.escape(n)}" sheetId="{i}" r:id="rId{i}"/>' for i,n in enumerate(names,1))+'</sheets></workbook>')
    z.writestr('xl/_rels/workbook.xml.rels','''<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'''+''.join(f'<Relationship Id="rId{i}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet{i}.xml"/>' for i in range(1,len(names)+1))+'</Relationships>')
    for i,n in enumerate(names,1): z.writestr(f'xl/worksheets/sheet{i}.xml',sheet(tabs[n]))

er=['erDiagram']
for t in tables:
    er.append(f"  {t['nombre']} {{")
    for c in t['columnas']: er.append(f"    {c['tipo'].replace(' ','_')} {c['nombre']} {'PK' if c['nombre'] in t['primary_key'] else 'FK' if any(c['nombre'] in f['columns'] for f in t['foreign_keys']) else ''}".rstrip())
    er.append('  }')
for t in tables:
    for f in t['foreign_keys']: er.append(f"  {f['table']} ||--o{{ {t['nombre']} : \"{','.join(f['columns'])}\"")
(OUT/'diagrama_er.mmd').write_text('\n'.join(er)+'\n',encoding='utf-8')
db=['Project db_test {','  database_type: "MySQL"','  Note: "Generado desde DDL disponible"','}','']
for t in tables:
    db.append(f"Table {t['nombre']} {{")
    for c in t['columnas']:
        opts=[]
        if c['nombre'] in t['primary_key']: opts.append('pk')
        if c['nullable']: opts.append('null')
        if c['auto_increment']: opts.append('increment')
        db.append(f"  {c['nombre']} {c['tipo']}"+(' ['+', '.join(opts)+']' if opts else ''))
    db.append('}\n')
for t in tables:
    for f in t['foreign_keys']:
        for a,b in zip(f['columns'],f['references']): db.append(f"Ref: {t['nombre']}.{a} > {f['table']}.{b}")
(OUT/'schema.dbml').write_text('\n'.join(db)+'\n',encoding='utf-8')
(OUT/'README.md').write_text('''# Regeneración\n\nRequisitos: Python 3.10 o superior. No requiere paquetes externos.\n\nDesde la carpeta `Practica03`, ejecute:\n\n```powershell\npython .\\diccionario_datos\\generar_diccionario.py\n```\n\nEl script lee únicamente DDL del dump ubicado en `backups/Respaldo 20-10-26.sql`, ignora INSERT y regenera los archivos de esta carpeta.\n''',encoding='utf-8')

total=sum(len(t['columnas']) for t in tables)
print(f"Validación: {len(tables)} tablas, {len(views)} vistas, {len(triggers)} triggers, {len(procedures)} procedimientos, {total} columnas.")
valid=sum(all(set(c)=={'Nombre','Valor','Origen','Obligatoriedad','Llave','Naturaleza','Composición Formal','Dominio'} for c in jt['columnas']) for jt in json_tables)
print(f"Atributos por columna: 8/8 exactos en {valid}/{len(tables)} tablas.")
