#!/usr/bin/env bash
# RetroVanta Theme v0.1 para EmulationStation / RetroPie
# Instalacion reversible. NO toca ROMs, mandos, emuladores ni arranque.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ES="$HOME/.emulationstation"
THEMES="$ES/themes"
DEST="$THEMES/retrovanta"
SETTINGS="$ES/es_settings.cfg"
BACKUP="$HOME/retrovanta-backups/menu-$(date +%Y%m%d-%H%M%S)"
if pgrep -x emulationstation >/dev/null 2>&1; then
  echo "ERROR: sali de EmulationStation antes de instalar el tema."
  exit 1
fi
mkdir -p "$BACKUP" "$THEMES"
[ ! -e "$DEST" ] || { cp -a "$DEST" "$BACKUP/retrovanta-anterior"; }
[ ! -f "$SETTINGS" ] || cp -p "$SETTINGS" "$BACKUP/es_settings.cfg"
echo "Respaldo: $BACKUP"
export RV_DEST="$DEST" RV_SETTINGS="$SETTINGS" RV_BACKUP="$BACKUP"
python3 - <<'PY'
import os, re, shutil, pathlib, xml.etree.ElementTree as ET
p=pathlib.Path(os.environ['RV_DEST'])
settings=pathlib.Path(os.environ['RV_SETTINGS'])
backup=pathlib.Path(os.environ['RV_BACKUP'])
# Detecta nombres de tema activos desde configuracion existente, sin cambiar el catalogo.
names={'arcade','fba','mame-libretro','mame-mame4all','megadrive','snes','nes','neogeo','mastersystem','fds','psx','ngp','ngpc'}
for cfg in [pathlib.Path('/opt/retropie/configs/all/emulationstation/es_systems.cfg'),
            pathlib.Path('/etc/emulationstation/es_systems.cfg'),
            pathlib.Path.home()/'.emulationstation/es_systems.cfg']:
    if cfg.is_file():
        try:
            root=ET.parse(str(cfg)).getroot()
            for item in root.findall('.//system'):
                s=item.findtext('theme') or item.findtext('name')
                if s and re.fullmatch(r'[A-Za-z0-9_.-]+', s): names.add(s)
        except ET.ParseError:
            pass
# Pequeños SVG sin videos, audio ni texturas grandes.
bg='''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720">
<rect width="1280" height="720" fill="#080b13"/>
<rect x="32" y="28" width="1216" height="664" rx="27" fill="#111723" stroke="#a78b57" stroke-width="3"/>
<rect x="47" y="43" width="1186" height="634" rx="16" fill="none" stroke="#343c4b" stroke-width="2"/>
<rect x="68" y="126" width="1144" height="2" fill="#a78b57"/>
<rect x="68" y="618" width="1144" height="2" fill="#a78b57"/>
<text x="79" y="96" fill="#e9d4a6" font-family="sans-serif" font-size="42" font-weight="bold" letter-spacing="5">RETROVANTA</text>
<text x="1009" y="94" fill="#81d3c5" font-family="sans-serif" font-size="18">ARCADE SYSTEM</text>
<text x="80" y="653" fill="#8a9aad" font-family="sans-serif" font-size="17">RETROVANTA  •  CLASSIC PLAY</text>
</svg>'''
# Evitar borrado del tema anterior hasta tener todos los archivos nuevos.
staging=p.with_name('retrovanta-nuevo')
if staging.exists(): shutil.rmtree(str(staging))
staging.mkdir(parents=True)
(staging/'background.svg').write_text(bg,encoding='utf-8')
xml='''<theme>
 <formatVersion>3</formatVersion>
 <view name="system">
  <image name="rv_background" extra="true"><pos>0 0</pos><size>1 1</size><path>../background.svg</path></image>
 </view>
 <view name="basic, detailed">
  <image name="background"><path>../background.svg</path></image>
  <text name="logoText"><color>E9D4A6</color><fontSize>0.055</fontSize><pos>0.07 0.17</pos><size>0.86 0.08</size></text>
  <textlist name="gamelist">
   <pos>0.07 0.27</pos><size>0.43 0.53</size>
   <primaryColor>E0E6EE</primaryColor><secondaryColor>8C9AA7</secondaryColor>
   <selectedColor>81D3C5</selectedColor><selectorColor>253C46</selectorColor>
   <fontSize>0.030</fontSize>
  </textlist>
  <helpsystem name="help"><pos>0.08 0.89</pos><textColor>E9D4A6</textColor><iconColor>81D3C5</iconColor></helpsystem>
 </view>
 <view name="detailed">
  <image name="md_image"><pos>0.57 0.30</pos><maxSize>0.32 0.30</maxSize></image>
  <text name="md_description"><pos>0.55 0.65</pos><size>0.36 0.16</size><fontSize>0.022</fontSize><color>C2CCD7</color></text>
 </view>
</theme>'''
for name in sorted(names):
    d=staging/name
    d.mkdir()
    (d/'theme.xml').write_text(xml,encoding='utf-8')
    ET.parse(str(d/'theme.xml'))
if p.exists(): shutil.rmtree(str(p))
staging.rename(p)
# Activacion segura: nunca reescribir ajustes XML defectuosos.
# EmulationStation permite elegir ThemeSet desde UI si hace falta.
if settings.is_file():
    original=settings.read_text(encoding='utf-8')
    try:
        ET.fromstring(original)
    except ET.ParseError as exc:
        print('AVISO: es_settings.cfg tiene XML no valido:',exc)
        print('No se modificaron ajustes. Elegi RetroVanta en START > UI SETTINGS > THEME SET.')
    else:
        pat=r'(<string\s+name="ThemeSet"\s+value=")[^"]*("\s*/>)'
        if re.search(pat,original):
            updated=re.sub(pat,lambda m:m.group(1)+'retrovanta'+m.group(2),original,count=1)
        elif '</config>' in original:
            updated=original.replace('</config>','    <string name="ThemeSet" value="retrovanta" />\n</config>',1)
        else:
            updated=original
        try:
            ET.fromstring(updated)
        except ET.ParseError:
            print('AVISO: no se pudieron validar los ajustes; selecciona el tema manualmente.')
        else:
            settings.write_text(updated,encoding='utf-8')
            print('Tema activado desde es_settings.cfg.')
else:
    print('No se encontró archivo de ajustes. Selecciona RetroVanta manualmente en UI SETTINGS.')
(backup/'README.txt').write_text('Tema anterior respaldado. Para volver atras: bash Arcade/scripts/menu-restaurar.sh\n',encoding='utf-8')
print('Tema RetroVanta instalado:',p)
print('Sistemas con tema:',len(names))
print('No se modificaron controles, ROMs ni emuladores.')
PY
echo "LISTO. Inicia EmulationStation normalmente para ver RetroVanta."
echo "Para deshacer: bash $ROOT/scripts/menu-restaurar.sh"
