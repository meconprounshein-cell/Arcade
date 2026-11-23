#!/usr/bin/env bash
# RETROVANTA - carteles neon 80s. SOLO cambia el encabezado del menu de juegos.
# No altera listas, capturas, fondos, controles ni emuladores.
set -euo pipefail
THEME="$HOME/.emulationstation/themes/retrovanta"
[ -d "$THEME" ] || { echo "No encuentro el tema RetroVanta"; exit 1; }
if pgrep -x emulationstation >/dev/null 2>&1; then
 echo "Cerra EmulationStation primero."; exit 1
fi
export RV_THEME="$THEME"
python3 - <<'PY'
import os,struct,zlib,xml.etree.ElementTree as ET
from pathlib import Path
theme=Path(os.environ['RV_THEME'])
labels={
 'arcade':'ARCADE','fba':'ARCADE','mame-libretro':'ARCADE',
 'mame-mame4all':'ARCADE','neogeo':'NEO GEO',
 'snes':'SUPER NINTENDO','nes':'NES',
 'megadrive':'MEGA DRIVE','genesis':'MEGA DRIVE',
 'mastersystem':'MASTER SYSTEM'
}
# Letras propias para usar si el sistema no trae Pillow.
FONT={
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
' ':["00000"]*7
}
W,H=960,144
def pillow_neon(label):
 from PIL import Image,ImageDraw,ImageFont,ImageFilter
 fontpaths=[
 '/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-BoldOblique.ttf',
 '/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf',
 '/usr/share/fonts/truetype/liberation2/LiberationSans-BoldItalic.ttf']
 fpath=next((s for s in fontpaths if Path(s).is_file()),None)
 if not fpath: raise RuntimeError('No hay fuente TrueType')
 font=None
 for size in range(100,25,-1):
  trial=ImageFont.truetype(fpath,size)
  bb=trial.getbbox(label,stroke_width=2)
  if bb[2]-bb[0]<710 and bb[3]-bb[1]<91:
   font=trial;break
 if font is None:font=trial
 bb=font.getbbox(label,stroke_width=2)
 x=(W-(bb[2]-bb[0]))/2-bb[0]
 y=(H-(bb[3]-bb[1]))/2-bb[1]-2
 # Fondo transparente. Solo se modifica el area del titulo.
 img=Image.new('RGBA',(W,H),(0,0,0,0))
 glow=Image.new('RGBA',(W,H),(0,0,0,0))
 g=ImageDraw.Draw(glow)
 g.text((x,y),label,font=font,fill=(255,55,183,255),stroke_width=3,stroke_fill=(255,48,205,255))
 # Brillo suave ya calculado: sin efectos durante la navegacion.
 outer=glow.filter(ImageFilter.GaussianBlur(14))
 outer.putalpha(outer.getchannel('A').point(lambda v:int(v*0.80)))
 img=Image.alpha_composite(img,outer)
 mid=glow.filter(ImageFilter.GaussianBlur(5))
 img=Image.alpha_composite(img,mid)
 d=ImageDraw.Draw(img)
 d.text((x,y),label,font=font,fill=(255,112,55,255),
        stroke_width=3,stroke_fill=(255,75,214,255))
 d.text((x,y),label,font=font,fill=(255,185,78,255),stroke_width=1,stroke_fill=(255,228,114,255))
 # Dos acentos laterales equilibrados, como el boceto aprobado.
 left=x-26
 right=x+bb[2]-bb[0]+26
 for a,b in ((max(40,left-68),max(45,left-12)),(min(W-45,right+12),min(W-40,right+68))):
  if b<=a:continue
  yy=H//2
  lg=Image.new('RGBA',(W,H),(0,0,0,0))
  ld=ImageDraw.Draw(lg)
  ld.line((a,yy,b,yy),fill=(255,38,217,255),width=5)
  img=Image.alpha_composite(img,lg.filter(ImageFilter.GaussianBlur(8)))
  dd=ImageDraw.Draw(img)
  dd.line((a,yy,b,yy),fill=(255,72,233,255),width=3)
  dd.line((a,yy,b,yy),fill=(255,215,254,255),width=1)
 return img
def pure_neon(label):
 # Alternativa sin dependencias: PNG RGBA 960x144 con letras neón rasterizadas.
 rgba=bytearray(W*H*4)
 def put(x,y,color,alpha):
  if not (0<=x<W and 0<=y<H):return
  j=(y*W+x)*4
  old=rgba[j+3]
  a=alpha/255.0
  new=old/255.0
  out=a+new*(1-a)
  if out<=0:return
  for c in range(3):
   rgba[j+c]=int((color[c]*a+rgba[j+c]*new*(1-a))/out)
  rgba[j+3]=int(out*255)
 def rct(x,y,w,h,color,a):
  for yy in range(max(0,y),min(H,y+h)):
   for xx in range(max(0,x),min(W,x+w)):put(xx,yy,color,a)
 unit=min(15,max(8,730//(6*len(label)-1)))
 total=(6*len(label)-1)*unit
 ox=(W-total)//2
 oy=(H-7*unit)//2
 for n,ch in enumerate(label):
  for row,bits in enumerate(FONT.get(ch,FONT[' '])):
   for col,on in enumerate(bits):
    if on!='1':continue
    # ligera inclinacion ochentosa + halo / núcleo
    xx=ox+(n*6+col)*unit+(6-row)//2
    yy=oy+row*unit
    rct(xx-5,yy-5,unit+10,unit+10,(250,55,179),25)
    rct(xx-2,yy-2,unit+4,unit+4,(255,63,203),100)
    rct(xx,yy,unit-1,unit-1,(255,131,58),255)
    rct(xx+2,yy+2,max(1,unit-5),max(1,unit-5),(255,224,124),255)
 for xx in (max(30,ox-85), min(W-95,ox+total+25)):
  rct(xx,H//2-2,65,5,(255,57,210),165)
  rct(xx,H//2,65,2,(255,207,254),255)
 return bytes(rgba)
def png_rgba(raw):
 def ch(t,b):return struct.pack('>I',len(b))+t+b+struct.pack('>I',zlib.crc32(t+b)&0xffffffff)
 rows=b''.join(b'\0'+raw[y*W*4:(y+1)*W*4] for y in range(H))
 return b'\x89PNG\r\n\x1a\n'+ch(b'IHDR',struct.pack('>IIBBBBB',W,H,8,6,0,0,0))+ch(b'IDAT',zlib.compress(rows,7))+ch(b'IEND',b'')
def modify(xml,newpath):
 tree=ET.parse(str(xml))
 changed=False
 for view in tree.getroot().findall('view'):
  types={s.strip() for s in view.get('name','').split(',')}
  if not types.intersection({'basic','detailed'}):continue
  el=view.find("./image[@name='rv_juegos_header']")
  if el is None:el=ET.SubElement(view,'image',{'name':'rv_juegos_header','extra':'true'});changed=True
  for tag,val in [('path',newpath),('pos','0.17 0.303'),
                  ('size','0.615 0.103'),('origin','0 0'),('zIndex','5')]:
   field=el.find(tag)
   if field is None:field=ET.SubElement(el,tag)
   if field.text!=val:field.text=val;changed=True
 if changed:
  tree.write(str(xml),encoding='utf-8',xml_declaration=True)
  ET.parse(str(xml))
 return changed
count=0
try:
 from PIL import Image
 use_pillow=True
except ImportError: use_pillow=False
for folder in sorted(theme.iterdir()):
 if not folder.is_dir() or folder.name not in labels:continue
 xml=folder/'theme.xml'
 if not xml.is_file():continue
 label=labels[folder.name]
 png=folder/'retrovanta-neon-80s.png'
 if use_pillow:
  try:
   im=pillow_neon(label)
   im.save(str(png),format='PNG',optimize=True)
  except Exception as e:
   print('Usando alternativa compatible en',folder.name,':',e)
   png.write_bytes(png_rgba(pure_neon(label)))
 else:
  png.write_bytes(png_rgba(pure_neon(label)))
 modify(xml,'./retrovanta-neon-80s.png')
 print('NEON:',folder.name,'=>',label)
 count+=1
print('TOTAL:',count,'temas. Sin tocar otros elementos.')
PY
