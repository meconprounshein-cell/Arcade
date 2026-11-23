#!/usr/bin/env bash
# RetroVanta: instala ilustraciones neon en selector de sistemas.
# No modifica juegos, controles ni emuladores; no crea respaldos.
set -euo pipefail
ROOT="$HOME/.emulationstation/themes/retrovanta"
ZIP="$HOME/RetroPie/roms/retrovanta-selector-neon-6-consolas.zip"
if pgrep -x emulationstation >/dev/null 2>&1; then
 echo "Cerra EmulationStation antes de instalar el tema."
 exit 1
fi
if [ ! -s "$ZIP" ]; then
 echo "FALTA: $ZIP"
 echo "Copia retrovanta-selector-neon-6-consolas.zip a la carpeta roms desde el celular."
 exit 1
fi
if [ ! -d "$ROOT" ]; then
 echo "FALTA el tema RetroVanta: $ROOT"
 exit 1
fi
export RV_ROOT="$ROOT" RV_ZIP="$ZIP"
python3 - <<'PY'
import os
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile
root=Path(os.environ['RV_ROOT'])
archive=Path(os.environ['RV_ZIP'])
systems={
 'arcade':'arcade',
 'fba':'arcade',
 'mame-libretro':'arcade',
 'mame-mame4all':'arcade',
 'megadrive':'megadrive',
 'genesis':'megadrive',
 'snes':'snes',
 'nes':'nes',
 'neogeo':'neogeo',
 'mastersystem':'mastersystem',
 'mastersystem':'mastersystem',
}
with zipfile.ZipFile(archive) as z:
 for sys,base in systems.items():
  folder=root/sys
  xml=folder/'theme.xml'
  if not xml.is_file():
   print('SIN TEMA:',sys,'(se mantiene actual)')
   continue
  png=base+'.jpg'
  b=z.read(png)
  if b[:3]!=bytes.fromhex('ffd8ff'):
   raise SystemExit('Imagen incorrecta: '+png)
  path=folder/'selector-neon.jpg'
  path.write_bytes(b)
  tree=ET.parse(str(xml))
  modified=False
  for view in tree.getroot().findall('view'):
   if 'system' not in {v.strip() for v in (view.get('name') or '').split(',')}:
    continue
   image=view.find("./image[@name='rv_system_art']")
   if image is None:
    image=ET.SubElement(view,'image',{'name':'rv_system_art','extra':'true'})
   values={'pos':'0.172 0.294','size':'0.618 0.462','path':'./selector-neon.jpg','zIndex':'3'}
   for tag,value in values.items():
    node=image.find(tag)
    if node is None:node=ET.SubElement(image,tag)
    node.text=value
   modified=True
  if modified:
   tree.write(str(xml),encoding='utf-8',xml_declaration=True)
  print('INSTALADO:',sys, '-' if modified else '(sin vista de sistema)')
print('LISTO. Reinicia EmulationStation para ver los carteles.')
print('Master System incluido en los seis diseños.')
PY
