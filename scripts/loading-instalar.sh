#!/usr/bin/env bash
# RetroVanta: imagen de lanzamiento 640x480 para runcommand. No cambia emuladores.
set -euo pipefail
SRC="$HOME/RetroPie/roms/retrovanta-loading.png"
DEST="/opt/retropie/configs/all/launching.png"
CFG="/opt/retropie/configs/all/runcommand.cfg"
if [ ! -s "$SRC" ]; then
  echo "FALTA IMAGEN: $SRC"
  echo "Copia retrovanta-loading.png desde tu celular a la carpeta compartida roms."
  exit 1
fi
if ! file "$SRC" | grep -q 'PNG image data'; then
  echo "ERROR: la imagen no es un PNG valido."
  exit 1
fi
if [ ! -d "$(dirname "$DEST")" ]; then
  echo "ERROR: no existe /opt/retropie/configs/all"
  exit 1
fi
# No se tocan los archivos de configuracion ajenos a runcommand.
cp "$SRC" "$DEST"
export RV_RC="$CFG"
python3 - <<'PY'
import os,re
from pathlib import Path
p=Path(os.environ['RV_RC'])
txt=p.read_text(encoding='utf-8') if p.exists() else ''
# Mantener todas las demas opciones intactas; eliminar duplicados de estas claves.
for key,value in [('disable_menu','1'),('use_art','0'),('image_delay','2')]:
    txt=re.sub(r'^\s*'+re.escape(key)+r'\s*=.*(?:\n|$)','',txt,flags=re.M)
    txt+=f'{key} = "{value}"\n'
p.write_text(txt,encoding='utf-8')
PY
echo "LISTO: pantalla RetroVanta NOW LOADING instalada."
echo "Cartel de configuracion de runcommand desactivado."
echo "Si ves otra portada al lanzar un juego, puede existir una imagen especifica que tiene prioridad."
echo "Importante: la pantalla interna de carga de PiFBA no se reemplaza con este cambio."
