#!/usr/bin/env bash
# RetroVanta: vincular capturas existentes con juegos sin tocar ROMs o controles.
set -euo pipefail
if pgrep -x emulationstation >/dev/null 2>&1; then
  echo "Sali de EmulationStation antes de continuar."
  exit 1
fi
python3 - <<'PY'
from pathlib import Path
from collections import defaultdict
import xml.etree.ElementTree as ET
import re, shutil, datetime, unicodedata

home = Path.home()
rombase = home/'RetroPie'/'roms'
localbase = home/'.emulationstation'/'gamelists'
stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
backup = home/'retrovanta-backups'/('capturas-'+stamp)
image_ext = {'.png','.jpg','.jpeg','.webp'}
nonrom_ext = image_ext | {'.xml','.txt','.nfo','.md','.pdf','.sh','.cfg','.ini','.sav','.srm','.state'}
def key(s):
    s=unicodedata.normalize('NFKD',s).encode('ascii','ignore').decode().lower()
    return re.sub('[^a-z0-9]','',s)
def variants(name):
    base = Path(name).stem
    vals = {key(base)}
    for suf in ('-image','_image','-screenshot','_screenshot','-snap','_snap','-title','_title','-boxart','_boxart','-thumb','_thumb'):
        if base.lower().endswith(suf):
            vals.add(key(base[:-len(suf)]))
    return {v for v in vals if v}
def image_candidates(system):
    root=rombase/system
    # Incluye recursos dentro de la misma carpeta o en las carpetas de imagenes conocidas.
    folders=[root, home/'.emulationstation'/'downloaded_images'/system,
             home/'.emulationstation'/'downloaded_media'/system,
             home/'RetroPie'/'media'/system]
    img=[]
    for folder in folders:
        if folder.is_dir():
            img.extend(p for p in folder.rglob('*') if p.is_file() and p.suffix.lower() in image_ext)
    idx=defaultdict(list)
    for p in img:
        for k in variants(p.name):
            idx[k].append(p)
    return idx,len(img)
def priority(p):
    name=p.name.lower()
    # Preferir captura real a portada cuando estan ambas.
    return (0 if ('snap' in name or 'screenshot' in name or 'image' in name) else 1,
            0 if p.suffix.lower() in {'.png','.jpg'} else 1,
            len(str(p)))
def set_tag(node,tag,val):
    e=node.find(tag)
    if e is None: e=ET.SubElement(node,tag)
    e.text=val
def parse_existing(path):
    if not path.is_file():return None
    try:
        tree=ET.parse(str(path))
        if tree.getroot().tag != 'gameList':raise ValueError('Raiz XML inesperada')
        return tree
    except (ET.ParseError,ValueError) as e:
        print('SALTADO: lista invalida',path,e)
        return False

if not rombase.is_dir():
    raise SystemExit('No existe /home/pi/RetroPie/roms')
backup.mkdir(parents=True,exist_ok=True)
total=0
found_images=0
for folder in sorted(p for p in rombase.iterdir() if p.is_dir()):
    system=folder.name
    # Prioriza un gamelist existente en ~/.emulationstation. Si esta ausente,
    # conserva la ubicacion del gamelist original dentro de ROMs.
    opt1=localbase/system/'gamelist.xml'
    opt2=folder/'gamelist.xml'
    target=opt1 if opt1.is_file() or not opt2.is_file() else opt2
    parsed=parse_existing(target)
    if parsed is False:continue
    indexed, count=image_candidates(system)
    found_images+=count
    if not indexed:continue
    entries=[]
    if parsed is None:
        # Solo ROMs en esta carpeta; no tocar otros archivos.
        for p in sorted(folder.iterdir()):
            if not p.is_file() or p.suffix.lower() in nonrom_ext or p.name.startswith('.'):
                continue
            entries.append((p, None))
        root=ET.Element('gameList')
        tree=ET.ElementTree(root)
    else:
        tree=parsed
        root=tree.getroot()
        for node in root.findall('game'):
            raw=node.findtext('path') or ''
            p=(target.parent / raw).resolve() if raw else None
            if p and p.is_file():
                entries.append((p,node))
        # En caso de lista existente, no agregar juegos nuevos: solo fotos.
    changed=0
    for game, node in entries:
        if node is not None:
            previous=node.findtext('image') or ''
            if previous:
                resolved=(target.parent/previous).resolve()
                if resolved.is_file():continue
        ks=variants(game.name)
        if node is not None:
            ks |= variants(node.findtext('name') or '')
        paths=[]
        for k in ks:paths+=indexed.get(k,[])
        if not paths:continue
        path=min(set(paths),key=priority)
        if node is None:
            node=ET.SubElement(root,'game')
            set_tag(node,'path',str(game.resolve()))
            set_tag(node,'name',game.stem.replace('_',' ').replace('-',' '))
        set_tag(node,'image',str(path.resolve()))
        changed+=1
    if changed:
        if target.is_file():
            dest=backup/system/'gamelist.xml'
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(str(target),str(dest))
        target.parent.mkdir(parents=True,exist_ok=True)
        # Escribir de forma atomica y hacer una ultima validacion.
        tempfile=target.with_suffix('.tmp')
        tree.write(str(tempfile),encoding='utf-8',xml_declaration=True)
        ET.parse(str(tempfile))
        tempfile.replace(target)
    total+=changed
    print('{}: {} imagenes encontradas, {} juegos vinculados{}'.format(
        system,count,changed,' (sin modificaciones)' if changed==0 else ''))
print('')
print('VINCULACIONES REALIZADAS:',total)
print('Ficheros de imagen localizados:',found_images)
print('Copias de seguridad:',backup)
if total==0:
    print('No hubo coincidencias seguras de nombres. Necesitamos revisar estructura de imagenes y gamelists.')
else:
    print('LISTO. En EmulationStation: UI SETTINGS > GAMELIST VIEW STYLE > DETAILED.')
print('Las ROMs, los controles y los emuladores no se modificaron.')
PY