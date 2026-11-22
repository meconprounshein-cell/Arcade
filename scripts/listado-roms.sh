#!/usr/bin/env bash
# RetroVanta: solo lectura. Genera inventario que se puede compartir desde el telefono.
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET
from datetime import datetime
home=Path.home()
base=home/'RetroPie'/'roms'
out=base/'retrovanta-inventario.txt'
skip={'.png','.jpg','.jpeg','.webp','.gif','.xml','.txt','.md','.nfo','.cfg','.ini','.pdf','.srm','.sav','.state','.sh','.log','.bak'}
d=['RetroVanta - inventario REAL de archivos ROM',datetime.now().isoformat(timespec='seconds'),'']
names=set()
for cfg in [home/'.emulationstation/es_systems.cfg',Path('/etc/emulationstation/es_systems.cfg')]:
    if not cfg.exists():continue
    try:
        root=ET.parse(str(cfg)).getroot()
        names.update((e.findtext('name') or '').strip() for e in root.findall('system'))
    except Exception:pass
for folder in sorted(base.iterdir()):
    if not folder.is_dir():continue
    files=[]
    for p in sorted(folder.rglob('*')):
        if not p.is_file() or p.suffix.lower() in skip or p.name.startswith('.'):continue
        if any(part.lower() in ('images','media','screenshots','downloaded_images','boxart','videos') for part in p.relative_to(folder).parts[:-1]):continue
        files.append(p.relative_to(folder).as_posix())
    d.extend(['=== {} : {} archivos ==='.format(folder.name,len(files))])
    d.extend(files)
    d.append('')
out.write_text('\n'.join(d),encoding='utf-8')
print('LISTO:',out)
print('Compartime este archivo desde Cx Explorador > Red > roms.')
print('No modifique ROMs ni configuraciones.')
PY