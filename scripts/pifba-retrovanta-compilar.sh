#!/usr/bin/env bash
# RetroVanta PiFBA: genera splash RGB565, parchea una copia de codigo fuente y compila prueba.
# No reemplaza el PiFBA instalado ni cambia emulators.cfg.
set -euo pipefail
SRC="$HOME/RetroVanta-pifba-src"
IMG="$HOME/RetroPie/roms/retrovanta-loading.png"
RAW="$HOME/RetroPie/roms/retrovanta-pifba.rgb565"
REPORT="$HOME/RetroPie/roms/retrovanta-pifba-compilacion.txt"
CPP="$SRC/rpi/fba_player.cpp"
if [ ! -f "$IMG" ]; then echo "Falta $IMG. Copia retrovanta-loading.png a roms."; exit 1; fi
if [ ! -f "$CPP" ]; then echo "Falta el codigo de PiFBA. Ejecuta pifba-preparar.sh."; exit 1; fi
export RV_IMAGE="$IMG" RV_RAW="$RAW" RV_CPP="$CPP"
python3 - <<'PY'
from pathlib import Path
import os,struct,zlib
png=Path(os.environ['RV_IMAGE']).read_bytes()
if png[:8]!=b'\x89PNG\r\n\x1a\n': raise SystemExit('No es PNG')
pos=8
palette=None
trns=None
stream=bytearray()
while pos<len(png):
    n=struct.unpack('>I',png[pos:pos+4])[0]
    typ=png[pos+4:pos+8]
    data=png[pos+8:pos+8+n]
    pos+=n+12
    if typ==b'IHDR':
        w,h,depth,col,comp,fil,inter=struct.unpack('>IIBBBBB',data)
    if typ==b'PLTE': palette=[tuple(data[i:i+3]) for i in range(0,len(data),3)]
    if typ==b'tRNS':trns=data
    if typ==b'IDAT':stream.extend(data)
    if typ==b'IEND':break
if depth!=8 or inter!=0 or col not in (2,6):
    raise SystemExit('Imagen PNG no compatible: usa una PNG RGB/RGBA sin entrelazado')
channels=3 if col==2 else 4
data=zlib.decompress(bytes(stream))
rows=[]
i=0
prev=bytearray(w*channels)
for y in range(h):
    filt=data[i];i+=1
    line=bytearray(data[i:i+w*channels]);i+=w*channels
    for j in range(len(line)):
        a=line[j-channels] if j>=channels else 0
        b=prev[j]
        c=prev[j-channels] if j>=channels else 0
        if filt==1: line[j]=(line[j]+a)&255
        elif filt==2: line[j]=(line[j]+b)&255
        elif filt==3: line[j]=(line[j]+((a+b)//2))&255
        elif filt==4:
            p=a+b-c
            pa,pb,pc=abs(p-a),abs(p-b),abs(p-c)
            line[j]=(line[j]+(a if pa<=pb and pa<=pc else b if pb<=pc else c))&255
        elif filt!=0: raise SystemExit('Filtro PNG no soportado')
    rows.append(line)
    prev=line
out=bytearray()
for y in range(240):
    src=rows[min(h-1,int((y+0.5)*h/240))]
    for x in range(320):
        sx=min(w-1,int((x+0.5)*w/320))
        idx=sx*channels
        r,g,b=src[idx:idx+3]
        color=((r>>3)<<11)|((g>>2)<<5)|(b>>3)
        out.extend(struct.pack('<H',color))
Path(os.environ['RV_RAW']).write_bytes(out)
assert len(out)==320*240*2
print('Imagen PiFBA generada: 320x240 RGB565,',len(out),'bytes')
p=Path(os.environ['RV_CPP'])
s=p.read_text()
if 'RETROVANTA_PIFBA_SPLASH' in s:
    print('Codigo PiFBA ya preparado: no se duplica el parche.')
else:
    needle='void show_rom_loading_text(char * szText, int nSize, int nTotalSize)\n{'
    if s.count(needle)!=1: raise SystemExit('La fuente tiene un formato diferente; no modificada.')
    helper='''// RETROVANTA_PIFBA_SPLASH: imagen de carga estatica, sin barra de progreso.
static bool rv_loading_image=false;
static bool rv_load_splash()
{
    FILE *f=fopen("/home/pi/RetroPie/roms/retrovanta-pifba.rgb565","rb");
    if (!f) return false;
    size_t n=fread(titlefb,1,320*240*2,f);
    fclose(f);
    return n==320*240*2;
}
'''
    s=s.replace(needle,helper+needle+'\n    if (rv_loading_image) return;',1)
    old='''	memset (titlefb, 0, 320*240*2);
	DrawString (build_version, (uint16*)&titlefb, 10, 20, 320);
	DrawString ("Based on FinalBurnAlpha", (uint16*)&titlefb, 10, 35, 320);
	DrawString ("Now loading ... ", (uint16 *)&titlefb, 10, 105, 320);	
	show_rom_loading_text("Open Zip", 0, 0);'''
    if old not in s: raise SystemExit('No encuentro el bloque de carga original; fuente sin modificar.')
    new='''	rv_loading_image=rv_load_splash();
    if (!rv_loading_image) {
        memset(titlefb,0,320*240*2);
        DrawString(build_version, (uint16*)&titlefb,10,20,320);
        DrawString("Based on FinalBurnAlpha", (uint16*)&titlefb,10,35,320);
        DrawString("Now loading ...", (uint16*)&titlefb,10,105,320);
        show_rom_loading_text("Open Zip",0,0);
    }'''
    s=s.replace(old,new,1)
    p.write_text(s)
    print('Codigo de pantalla interna modificado en copia de fuentes.')
PY
{
echo "RETROVANTA - COMPILACION PIFBA"
date
echo "No se modifica /opt/retropie/emulators/pifba/fba2x"
echo "Origen: $SRC"
echo "Imagen: $RAW"
echo "---"
} > "$REPORT"
cd "$SRC"
# PiFBA no crea automaticamente la carpeta de objetos.
mkdir -p "$SRC/.obj"
echo "Carpeta de compilacion: $SRC/.obj" >> "$REPORT"
if make -j1 CC=gcc CXX=g++ >> "$REPORT" 2>&1; then
  echo "COMPILACION FINALIZADA" | tee -a "$REPORT"
  find "$SRC" -maxdepth 3 -type f -name 'fba2x' -exec ls -lh {} \; | tee -a "$REPORT"
  echo "Aun NO se instalo ni se cambio el emulador predeterminado."
else
  echo "NO COMPILO. El emulador original sigue intacto." | tee -a "$REPORT"
  tail -25 "$REPORT"
fi
echo "Informe: roms/retrovanta-pifba-compilacion.txt"
