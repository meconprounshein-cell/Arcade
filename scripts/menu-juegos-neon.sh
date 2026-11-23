#!/usr/bin/env bash
# RetroVanta: cabecera neon por consola + lista ampliada + area de capturas.
# Edita solamente vistas basic/detailed del tema existente. No cambia selector de consolas.
set -euo pipefail
THEME="$HOME/.emulationstation/themes/retrovanta"
if pgrep -x emulationstation >/dev/null 2>&1; then
 echo "Cerra EmulationStation antes de aplicar el tema."
 exit 1
fi
[ -d "$THEME" ] || { echo "Falta el tema RetroVanta"; exit 1; }
export RV_THEME="$THEME"
python3 - <<'PY'
from pathlib import Path
import os,xml.etree.ElementTree as ET
root=Path(os.environ['RV_THEME'])
systems={
'arcade':('ARCADE','#ff912f'),'fba':('ARCADE','#ff912f'),
'mame-libretro':('ARCADE','#ff912f'),'mame-mame4all':('ARCADE','#ff912f'),
'megadrive':('MEGA DRIVE','#26dfff'),'genesis':('MEGA DRIVE','#26dfff'),
'snes':('SUPER NINTENDO','#d17cff'),'nes':('NES','#fc70c7'),
'neogeo':('NEO GEO','#4deaca'),'mastersystem':('MASTER SYSTEM','#d36efc')
}
font={
'A':["01110","10001","10001","11111","10001","10001","10001"],
'B':["11110","10001","10001","11110","10001","10001","11110"],
'C':["01111","10000","10000","10000","10000","10000","01111"],
'D':["11110","10001","10001","10001","10001","10001","11110"],
'E':["11111","10000","10000","11110","10000","10000","11111"],
'G':["01111","10000","10000","10111","10001","10001","01111"],
'I':["11111","00100","00100","00100","00100","00100","11111"],
'M':["10001","11011","10101","10101","10001","10001","10001"],
'N':["10001","11001","10101","10011","10001","10001","10001"],
'O':["01110","10001","10001","10001","10001","10001","01110"],
'P':["11110","10001","10001","11110","10000","10000","10000"],
'R':["11110","10001","10001","11110","10100","10010","10001"],
'S':["01111","10000","10000","01110","00001","00001","11110"],
'T':["11111","00100","00100","00100","00100","00100","00100"],
'U':["10001","10001","10001","10001","10001","10001","01110"],
'V':["10001","10001","10001","10001","10001","01010","00100"],
' ':["00000"]*7,
}
def rect(x,y,w,h,fill,stroke='',sw=0):
 return '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"%s/>'%(x,y,w,h,fill,(' stroke="%s" stroke-width="%s"'%(stroke,sw)) if stroke else '')
def make_header(label,accent):
 # 1000x200 SVG: tipografia pixel neon, sin shaders, fuentes ni filtros SVG.
 n=len(label)
 cell=min(12, int(800/max(1,(6*n-1))))
 unit=6*cell
 total=n*unit-cell
 x0=(1000-total)//2
 y0=43
 shapes=[rect(0,0,1000,200,'#090e25'),
         '<path d="M0 125 L1000 125 M0 170 L1000 170 M150 198 L500 125 L850 198" stroke="#522584" stroke-width="2" fill="none"/>',
         '<path d="M70 95 L190 95 M810 95 L930 95" stroke="#e256ff" stroke-width="7"/>']
 for i,ch in enumerate(label):
  for y,bits in enumerate(font.get(ch,font[' '])):
   for x,on in enumerate(bits):
    if on=='1':
     xx=x0+i*unit+x*cell
     yy=y0+y*cell
     shapes.append(rect(xx-2,yy-2,cell+3,cell+3,'#54219a'))
     shapes.append(rect(xx,yy,cell-1,cell-1,accent))
     shapes.append(rect(xx+2,yy+2,max(1,cell-5),max(1,cell-5),'#d9f9ff'))
 return '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="200" viewBox="0 0 1000 200">'+''.join(shapes)+'</svg>'
def setval(node,tag,value):
 ch=node.find(tag)
 if ch is None:ch=ET.SubElement(node,tag)
 ch.text=str(value)
updated=0
for system,(label,accent) in systems.items():
 d=root/system
 xml=d/'theme.xml'
 if not xml.is_file():
  print('OMITIDO:',system,'(no existe theme.xml)')
  continue
 tree=ET.parse(str(xml))
 theme=tree.getroot()
 (d/'juegos-header.svg').write_text(make_header(label,accent),encoding='utf-8')
 for view in theme.findall('view'):
  names={x.strip() for x in view.get('name','').split(',')}
  if not names.intersection({'basic','detailed'}):continue
  header=view.find("./image[@name='rv_juegos_header']")
  if header is None:header=ET.SubElement(view,'image',{'name':'rv_juegos_header','extra':'true'})
  setval(header,'pos','0.17 0.303')
  setval(header,'size','0.615 0.103')
  setval(header,'path','./juegos-header.svg')
  setval(header,'zIndex','5')
  lst=view.find("./textlist[@name='gamelist']")
  if lst is not None:
   for k,v in {
    'pos':'0.17 0.434','size':'0.242 0.310',
    'fontSize':'0.029','primaryColor':'C6F4FF',
    'secondaryColor':'95D7F1','selectedColor':'FFE684',
    'selectorColor':'073E8AC0','zIndex':'7'
   }.items():setval(lst,k,v)
  if 'detailed' in names:
   img=view.find("./image[@name='md_image']")
   if img is None:img=ET.SubElement(view,'image',{'name':'md_image'})
   for k,v in {'pos':'0.441 0.424','maxSize':'0.331 0.305','zIndex':'7'}.items():setval(img,k,v)
   # Se conserva la descripcion si existe, debajo de la captura.
 tree.write(str(xml),encoding='utf-8',xml_declaration=True)
 ET.parse(str(xml))
 print('ACTUALIZADO:',label,'en',system)
 updated+=1
print('LISTO: '+str(updated)+' temas de consola. Imagenes: se mostraran cuando haya rutas validas en gamelist.xml.')
print('No se modificaron ROMs, controles, gamelists ni ilustraciones del selector.')
PY
