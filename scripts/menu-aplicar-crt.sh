#!/usr/bin/env bash
# RetroVanta CRT v1: tema funcional EmulationStation con fondo original optimizado.
# Requiere copiar retrovanta-fondo.png a la carpeta de red ROMs.
set -euo pipefail
SRC="$HOME/RetroPie/roms/retrovanta-fondo.png"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN="$HOME/RetroPie/roms/retrovanta-principal.png"
if [ ! -s "$MAIN" ]; then echo "FALTA IMAGEN: copia retrovanta-principal.png a la carpeta roms."; exit 1; fi
THEMEDIR="$HOME/.emulationstation/themes/retrovanta"
CONF="$HOME/.emulationstation/es_settings.cfg"
if [ ! -s "$SRC" ]; then
 echo "FALTA IMAGEN: copia retrovanta-fondo.png a la carpeta de red RETROPIE/roms."
 exit 1
fi
if pgrep -x emulationstation >/dev/null 2>&1; then
 echo "Cierra EmulationStation antes de ejecutar este instalador."
 exit 1
fi
BACK="$HOME/retrovanta-backups/crt-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACK"
[ ! -d "$THEMEDIR" ] || cp -a "$THEMEDIR" "$BACK/tema-anterior"
[ ! -f "$CONF" ] || cp -p "$CONF" "$BACK/es_settings.cfg"
export RV_SRC="$SRC" RV_MAIN="$MAIN" RV_DEST="$THEMEDIR"
python3 - <<'PY'
from pathlib import Path
import os, re, shutil
import xml.etree.ElementTree as ET
source=Path(os.environ['RV_SRC'])
principal=Path(os.environ['RV_MAIN'])
dest=Path(os.environ['RV_DEST'])
staging=dest.parent/'retrovanta-crt-temporal'
if staging.exists(): shutil.rmtree(str(staging))
staging.mkdir(parents=True)
shutil.copyfile(str(source),str(staging/'fondo.png'))
shutil.copyfile(str(principal),str(staging/'principal.png'))
with (staging/'fondo.png').open('rb') as fp:
    if fp.read(8) != bytes([137,80,78,71,13,10,26,10]):
        raise RuntimeError('La imagen no es un archivo PNG valido')
names=set('arcade fba mame-libretro mame-mame4all megadrive snes nes neogeo mastersystem fds psx ngp ngpc retropie'.split())
for candidate in [Path.home()/'.emulationstation/es_systems.cfg',Path('/etc/emulationstation/es_systems.cfg'),Path('/opt/retropie/configs/all/emulationstation/es_systems.cfg')]:
    if candidate.is_file():
        try:
            root=ET.parse(str(candidate)).getroot()
            for item in root.findall('.//system'):
                n=item.findtext('theme') or item.findtext('name')
                if n and re.fullmatch('[a-zA-Z0-9_.-]+',n): names.add(n)
        except ET.ParseError:
            pass
xml='''<theme>
 <formatVersion>3</formatVersion>
 <view name="system">
  <image name="background"><pos>0 0</pos><size>1 1</size><path>/home/pi/.emulationstation/themes/retrovanta/principal.png</path></image>
  <image name="rv_main" extra="true"><pos>0 0</pos><size>1 1</size><path>/home/pi/.emulationstation/themes/retrovanta/principal.png</path><zIndex>1</zIndex></image>
  <text name="logoText"><color>FFFFFF</color><fontSize>0.043</fontSize><forceUppercase>1</forceUppercase></text>
  <carousel name="systemcarousel">
   <type>horizontal</type><pos>0.18 0.775</pos><size>0.61 0.063</size>
   <logoSize>0.24 0.060</logoSize><logoScale>1.0</logoScale>
   <maxLogoCount>1</maxLogoCount><color>101B3200</color>
  </carousel>
  <text name="systemInfo"><pos>0.2 0.86</pos><size>0.6 0.025</size><color>FFFFFF00</color></text>
 </view>
 <view name="basic, detailed">
  <image name="background"><pos>0 0</pos><size>1 1</size><path>/home/pi/.emulationstation/themes/retrovanta/fondo.png</path></image>
  <image name="rv_crt" extra="true"><pos>0 0</pos><size>1 1</size><origin>0 0</origin><path>/home/pi/.emulationstation/themes/retrovanta/fondo.png</path><zIndex>1</zIndex></image>
  <textlist name="gamelist">
   <pos>0.17 0.425</pos><size>0.235 0.315</size>
   <primaryColor>FFFFFF</primaryColor><secondaryColor>A6B5CC</secondaryColor>
   <selectedColor>FFCA4A</selectedColor><selectorColor>263F68</selectorColor>
   <fontSize>0.025</fontSize>
  </textlist>
  <helpsystem name="help">
   <pos>0.17 0.835</pos><textColor>DEE6EF</textColor>
   <iconColor>FFB342</iconColor><fontSize>0.020</fontSize>
  </helpsystem>
 </view>
 <view name="detailed">
  <image name="md_image"><pos>0.438 0.43</pos><maxSize>0.336 0.275</maxSize></image>
  <text name="md_description"><pos>0.441 0.71</pos><size>0.33 0.063</size><fontSize>0.018</fontSize><color>D7E2F3</color></text>
 </view>
</theme>'''
for name in sorted(names):
    folder=staging/name
    folder.mkdir()
    (folder/'theme.xml').write_text(xml,encoding='utf8')
    ET.parse(str(folder/'theme.xml'))
if dest.exists(): shutil.rmtree(str(dest))
staging.rename(dest)
print('RetroVanta CRT instalado. Sistemas:',len(names))
print('Imagen:',source.stat().st_size,'bytes')
print('Pantalla principal:',principal.stat().st_size,'bytes')
PY
echo "LISTO. Copia de seguridad: $BACK"
echo "Inicia EmulationStation. START > UI SETTINGS > THEME SET: RETROVANTA"
echo "En UI SETTINGS cambia GAMELIST VIEW STYLE a DETAILED para mostrar las capturas."
echo "Para restaurar respaldo: copia los archivos desde $BACK (no se tocaron ROMs ni controles)."
