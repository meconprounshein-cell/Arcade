#!/usr/bin/env bash
# RetroVanta: corregir encuadre de capturas en la pantalla detallada.
# Solo toca theme.xml; no modifica fotos, ROMs, gamelists ni controles.
set -euo pipefail
if pgrep -x emulationstation >/dev/null 2>&1; then
 echo "Cierra EmulationStation antes de cambiar el tema."
 exit 1
fi
THEME="$HOME/.emulationstation/themes/retrovanta"
[ -d "$THEME" ] || { echo "No existe tema RetroVanta"; exit 1; }
export THEME
python3 - <<'PY'
from pathlib import Path
import xml.etree.ElementTree as ET
import os
base=Path(os.environ['THEME'])
n=0
for file in base.glob('*/theme.xml'):
 try:
  tree=ET.parse(str(file))
  changed=False
  for view in tree.getroot().findall('view'):
   names={x.strip() for x in (view.get('name') or '').split(',')}
   if 'detailed' not in names:continue
   img=view.find("./image[@name='md_image']")
   if img is None:continue
   # Legacy EmulationStation defaults position of metadata image to center
   # when origin is omitted. Set top-left origin explicitly.
   props={'origin':'0 0','pos':'0.445 0.438',
          'maxSize':'0.315 0.267','zIndex':'8'}
   for tag,val in props.items():
    node=img.find(tag)
    if node is None:node=ET.SubElement(img,tag)
    if node.text!=val:node.text=val;changed=True
   desc=view.find("./text[@name='md_description']")
   if desc is not None:
    # Keep description within picture frame instead of overlapping lower bar.
    for tag,val in {'pos':'0.443 0.718','size':'0.326 0.038',
                    'fontSize':'0.012','zIndex':'8'}.items():
     node=desc.find(tag)
     if node is None:node=ET.SubElement(desc,tag)
     if node.text!=val:node.text=val;changed=True
  if changed:
   tree.write(str(file),encoding='utf-8',xml_declaration=True)
   ET.parse(str(file))
   n+=1
 except ET.ParseError:
  print('Omitido XML invalido:',file)
print('LISTO: corregido el encuadre en',n,'sistemas')
print('No se han redimensionado ni cargado mas imagenes.')
PY
