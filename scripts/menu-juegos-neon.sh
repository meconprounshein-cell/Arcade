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
'Y':["10001","10001","01010","00100","00100","00100","00100"],
' ':["00000"]*7,
}
def make_header(label,accent):
 # PNG RGB de 1000x125: misma proporcion que el rectangulo del CRT.
 # Neon rasterizado con brillo integrado, compatible con EmulationStation viejo.
 import struct,zlib
 W,H=1000,125
 rgb=tuple(int(accent[i:i+2],16) for i in (1,3,5))
 canvas=bytearray(W*H*3)
 for y in range(H):
  for x in range(W):
   idx=(y*W+x)*3
   canvas[idx:idx+3]=bytes((7,11,28))
 def draw(x,y,w,h,color,alpha=1.0):
  x0=max(0,int(x));y0=max(0,int(y))
  x1=min(W,int(x+w));y1=min(H,int(y+h))
  if x1<=x0 or y1<=y0:return
  rr,gg,bb=color
  for py in range(y0,y1):
   off=(py*W+x0)*3
   for px in range(x0,x1):
    if alpha>=1:
     canvas[off]=rr;canvas[off+1]=gg;canvas[off+2]=bb
    else:
     canvas[off]=int(canvas[off]*(1-alpha)+rr*alpha)
     canvas[off+1]=int(canvas[off+1]*(1-alpha)+gg*alpha)
     canvas[off+2]=int(canvas[off+2]*(1-alpha)+bb*alpha)
    off+=3
 # Lineas decorativas horizontales y horizonte neon sutil.
 for y in range(93,125,9):draw(0,y,1000,1,(88,41,151),0.6)
 for x in range(100,1000,100):draw(x,95,1,29,(71,38,125),0.4)
 draw(24,61,72,3,(238,57,235),0.8)
 draw(904,61,72,3,(238,57,235),0.8)
 cell=min(10,max(6,830//max(1,6*len(label)-1)))
 advance=cell*6
 total=(len(label)*6-1)*cell
 x0=(W-total)//2
 y0=14
 for i,ch in enumerate(label):
  for row,bits in enumerate(font.get(ch,font[' '])):
   for col,on in enumerate(bits):
    if on!='1':continue
    px=x0+i*advance+col*cell
    py=y0+row*cell
    # Halo tenue exterior, contorno rosa/azul y nucleo blanco.
    draw(px-6,py-6,cell+12,cell+12,rgb,0.10)
    draw(px-3,py-3,cell+6,cell+6,(241,62,224),0.26)
    draw(px-1,py-1,cell+2,cell+2,rgb,0.98)
    draw(px+2,py+2,max(1,cell-4),max(1,cell-4),(231,248,255),0.95)
 def chunk(tag,data):
  return struct.pack('!I',len(data))+tag+data+struct.pack('!I',zlib.crc32(tag+data)&0xffffffff)
 raw=b''.join(b'\\x00'+canvas[y*W*3:(y+1)*W*3] for y in range(H))
 return (b'\\x89PNG\\r\\n\\x1a\\n'+chunk(b'IHDR',struct.pack('!2I5B',W,H,8,2,0,0,0))
         +chunk(b'IDAT',zlib.compress(raw,6))+chunk(b'IEND',b''))
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
 (d/'juegos-header.png').write_bytes(make_header(label,accent))
 for view in theme.findall('view'):
  names={x.strip() for x in view.get('name','').split(',')}
  if not names.intersection({'basic','detailed'}):continue
  header=view.find("./image[@name='rv_juegos_header']")
  if header is None:header=ET.SubElement(view,'image',{'name':'rv_juegos_header','extra':'true'})
  setval(header,'pos','0.17 0.303')
  setval(header,'size','0.615 0.103')
  setval(header,'path','./juegos-header.png')
  setval(header,'zIndex','5')
  lst=view.find("./textlist[@name='gamelist']")
  if lst is not None:
   for k,v in {
    'pos':'0.17 0.434','size':'0.242 0.310',
    'fontSize':'0.030','primaryColor':'C6F4FF',
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
