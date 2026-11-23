#!/usr/bin/env bash
# RetroVanta CRT suave: encender/apagar sin tocar juegos ni controles.
set -euo pipefail
MODE="${1:-}"
case "$MODE" in on|off|status) ;; *) echo "Uso: bash scripts/crt-filtro.sh on|off|status"; exit 2;; esac
ROOT="$HOME/.emulationstation/themes/retrovanta"
CFG="/opt/retropie/configs/all/retroarch.cfg"
export RV_MODE="$MODE" RV_THEME="$ROOT" RV_CFG="$CFG"
python3 - <<'PY'
from pathlib import Path
import os, struct, zlib, xml.etree.ElementTree as ET
mode=os.environ['RV_MODE']
root=Path(os.environ['RV_THEME'])
cfg=Path(os.environ['RV_CFG'])
marker='# RETROVANTA_CRT_BEGIN'
end='# RETROVANTA_CRT_END'
def menu_filter():
    if not root.is_dir():
        print('MENU: no encuentro el tema RetroVanta')
        return
    overlay=root/'crt-lineas.png'
    if mode=='on':
        # PNG RGBA 640x480: scanlines suaves solo sobre la pantalla interna.
        width,height=640,480
        raw=bytearray()
        for y in range(height):
            raw.append(0)
            for x in range(width):
                inside=(110 <= x <= 522 and 145 <= y <= 390)
                alpha=19 if inside and y%3==0 else 0
                raw.extend((0,0,0,alpha))
        def chunk(tag,payload):
            return struct.pack('!I',len(payload))+tag+payload+struct.pack('!I',zlib.crc32(tag+payload)&0xffffffff)
        data=(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',width,height,8,6,0,0,0))
              +chunk(b'IDAT',zlib.compress(bytes(raw),6))+chunk(b'IEND',b''))
        overlay.write_bytes(data)
    changed=0
    for xmlfile in root.glob('*/theme.xml'):
        try:
            tree=ET.parse(str(xmlfile))
            theme=tree.getroot()
            for view in theme.findall('view'):
                for node in list(view):
                    if node.tag=='image' and node.get('name')=='rv_scanlines':
                        view.remove(node)
                if mode=='on' and any(t in (view.get('name') or '').split(', ') for t in ('system','basic','detailed')):
                    node=ET.SubElement(view,'image',{'name':'rv_scanlines','extra':'true'})
                    ET.SubElement(node,'pos').text='0 0'
                    ET.SubElement(node,'size').text='1 1'
                    ET.SubElement(node,'path').text=str(overlay)
                    ET.SubElement(node,'zIndex').text='8'
            if mode!='status':
                tree.write(str(xmlfile),encoding='utf-8',xml_declaration=True)
                changed+=1
        except ET.ParseError:
            print('MENU: XML invalido:',xmlfile)
    if mode=='off' and overlay.exists():
        overlay.unlink()
    if mode!='status':
        print('MENU:', 'filtro CRT activado' if mode=='on' else 'filtro CRT desactivado',f'({changed} temas)')
def game_filter():
    if not cfg.is_file():
        print('JUEGOS: no se encuentra',cfg)
        return
    original=cfg.read_text(encoding='utf-8')
    start=original.find(marker)
    finish=original.find(end)
    if start!=-1 and finish>start:
        original=original[:start]+original[finish+len(end):]
    if mode=='status':
        active=marker in cfg.read_text(encoding='utf-8')
        print('JUEGOS:', 'activado por RetroVanta' if active else 'sin filtro RetroVanta')
        return
    if mode=='off':
        cfg.write_text(original,encoding='utf-8')
        print('JUEGOS: filtro RetroVanta desactivado')
        return
    # Prioridad: shader liviano crt-pi; no activar uno incompatible o inexistente.
    searches=[
        Path('/opt/retropie/configs/all/retroarch/shaders'),
        Path('/opt/retropie/emulators/retroarch/shader'),
        Path('/opt/retropie/emulators/retroarch/shaders')
    ]
    shaders=[]
    for folder in searches:
        if folder.is_dir():
            for pattern in ('crt-pi.glslp','crt-pi.glsl','scanlines.glslp','scanlines.glsl'):
                shaders.extend(folder.rglob(pattern))
    if not shaders:
        print('JUEGOS: no encontre shader liviano compatible; no cambio RetroArch.')
        print('El menu si tendra efecto. Avisame y preparamos una alternativa.')
        return
    selected=shaders[0]
    addition=('\n'+marker+'\nvideo_shader_enable = "true"\nvideo_shader = "'+
              str(selected)+'"\n'+end+'\n')
    cfg.write_text(original.rstrip('\n')+'\n'+addition,encoding='utf-8')
    print('JUEGOS: filtro activado:',selected)
if mode=='status':
    print('RetroVanta CRT: estado')
    game_filter()
    print('MENU:', 'activo' if (root/'crt-lineas.png').is_file() else 'inactivo')
else:
    menu_filter()
    game_filter()
print('No se modificaron ROMs ni controles.')
PY
