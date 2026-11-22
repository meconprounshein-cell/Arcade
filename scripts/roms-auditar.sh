#!/usr/bin/env bash
# RetroVanta: audita ROMs sin modificarlas. Usa Python 3.
set -euo pipefail
BASE="${RETROPIE_ROMS:-/home/pi/RetroPie/roms}"
CAT="${RETROVANTA_CATALOGO:-$(cd "$(dirname "$0")/.." && pwd)/catalogo/megadrive-adicionales.tsv}"
OUT="${RETROVANTA_INFORME:-$BASE/retrovanta-roms-informe.csv}"
python3 - "$BASE" "$CAT" "$OUT" <<'PY'
import csv, os, re, sys, unicodedata, xml.etree.ElementTree as ET
from pathlib import Path
base, catalog, out = map(Path, sys.argv[1:])
if not base.is_dir():
    sys.exit("No existe la carpeta ROMs: " + str(base))
if not catalog.is_file():
    sys.exit("No existe el catalogo: " + str(catalog))
extensions = {'.zip','.7z','.md','.bin','.gen','.smd','.sfc','.smc','.nes','.sms','.gg','.rom'}
def norm(s):
    s=unicodedata.normalize('NFKD',s)
    s=''.join(c for c in s if not unicodedata.combining(c)).casefold()
    s=re.sub(r'\([^)]*\)|\[[^]]*\]',' ',s)
    return re.sub(r'[^a-z0-9]+','',s)
# Indexed by system and filename, only actual files count as installed
files={}
for system in sorted(p for p in base.iterdir() if p.is_dir()):
    table={}
    for root, dirs, names in os.walk(system):
        dirs[:]=[d for d in dirs if d.lower() not in ('media','images','videos','screenshots','marquees')]
        for name in names:
            p=Path(root)/name
            if p.suffix.lower() in extensions:
                table.setdefault(norm(p.stem),[]).append(p)
    files[system.name.lower()]=table
# XML metadata can disambiguate aliases but never prove existence on its own.
names={}
for system in files:
    xml=base/system/'gamelist.xml'
    if not xml.is_file(): continue
    try:
        tree=ET.parse(xml)
        for game in tree.findall('.//game'):
            path=(game.findtext('path') or '').replace('\\','/')
            title=game.findtext('name') or ''
            if not path or not title: continue
            key=norm(Path(path).stem)
            names.setdefault(system,{})[norm(title)]=key
    except (OSError,ET.ParseError): pass
rows=[]
with catalog.open(encoding='utf-8-sig',newline='') as f:
    reader=csv.DictReader(f,delimiter='\t')
    required={'sistema','juego','alias'}
    if not required.issubset(reader.fieldnames or []):
        sys.exit('El catalogo debe tener columnas: sistema, juego, alias (separadas por TAB)')
    for rec in reader:
        system=(rec['sistema'] or '').strip().lower()
        title=(rec['juego'] or '').strip()
        if not title or title.startswith('#'): continue
        aliases=[title]+[x.strip() for x in (rec.get('alias') or '').split('|') if x.strip()]
        found=[]
        table=files.get(system,{})
        for candidate in aliases:
            key=norm(candidate)
            found.extend(table.get(key,[]))
            linked=names.get(system,{}).get(key)
            if linked: found.extend(table.get(linked,[]))
        # Never take substring matches: 'Sonic' must not count as 'Sonic 2'.
        uniq=list(dict.fromkeys(found))
        rows.append({'sistema':system,'juego':title,'estado':'ENCONTRADO' if uniq else 'NO_ENCONTRADO',
                     'archivo':' | '.join(str(x.relative_to(base)) for x in uniq)})
out.parent.mkdir(parents=True,exist_ok=True)
with out.open('w',encoding='utf-8-sig',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=['sistema','juego','estado','archivo'])
    writer.writeheader()
    writer.writerows(rows)
print('RetroVanta: auditados',len(rows),'juegos de la seleccion cargada')
print('Encontrados:',sum(r['estado']=='ENCONTRADO' for r in rows))
print('No encontrados:',sum(r['estado']=='NO_ENCONTRADO' for r in rows))
print('Informe:',out)
print('No se modificaron, copiaron ni borraron ROMs.')
PY
