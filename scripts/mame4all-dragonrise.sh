#!/usr/bin/env bash
# RetroVanta MAME4ALL / DragonRise x2, restauracion segura
# No toca otros emuladores, ni ROMs, ni teclas de EmulationStation.
set -euo pipefail
if pgrep -x mame >/dev/null 2>&1; then
 echo "ERROR: cierra Los Simpson / MAME4ALL primero."
 exit 1
fi
CFG="/opt/retropie/configs/mame-mame4all"
if [ ! -d "$CFG" ]; then echo "ERROR: no se encuentra $CFG"; exit 1; fi
if [ ! -e /dev/input/js0 ] || [ ! -e /dev/input/js1 ]; then
 echo "ERROR: conectar ambos DragonRise (js0 y js1)."; exit 1
fi
echo "DragonRise detectados: js0 y js1."
# preservar cfg anteriores por si necesitan reponerse
stamp=$(date +%Y%m%d-%H%M%S)
for f in "$CFG/cfg/default.cfg" "$CFG/cfg/simpsons.cfg" \
 "/opt/retropie/emulators/mame4all/cfg/default.cfg"; do
 if [ -f "$f" ]; then
  mv "$f" "$f.retro-anterior-$stamp"
  echo "Resguardado: $f"
 fi
done
export RV_MAME_CFG="$CFG/mame.cfg"
python3 - <<'PY'
from pathlib import Path
import os
p=Path(os.environ['RV_MAME_CFG'])
lines=p.read_text(errors='replace').splitlines() if p.is_file() else []
# Mantener las opciones actuales (audio, video, rutas). Solo [frontend].
vals={'K_START':'13','K_SELECT':'53','K_LEFT':'276','K_RIGHT':'275',
      'K_UP':'273','K_DOWN':'274','K_A':'306','K_QUIT':'27',
      'J_START':'9','J_SELECT':'8','J_A':'0','AXIS_LR':'0','AXIS_UD':'1'}
if not lines:lines=['[frontend]']
section=''
done=set()
out=[]
for line in lines:
 t=line.strip()
 if t.startswith('[') and t.endswith(']'):
  section=t.lower()
 if section=='[frontend]' and '=' in t and not t.startswith('#'):
  k=t.split('=',1)[0].strip()
  if k in vals:
   if k not in done:out.append(k+'='+vals[k]);done.add(k)
   continue
 out.append(line)
if '[frontend]' not in [x.strip().lower() for x in out]:
 out.extend(['','[frontend]'])
for k,v in vals.items():
 if k not in done:out.append(k+'='+v)
p.parent.mkdir(parents=True,exist_ok=True)
if p.exists():
 import shutil
 shutil.copy2(str(p),str(p)+'.retro-anterior')
p.write_text('\n'.join(out)+'\n')
print('Menu MAME4ALL: teclado restaurado; P1 SELECT=8 START=9; ejes 0/1.')
PY
echo
echo "INSTALACION PARCIAL COMPLETADA."
echo "Se resetearon configuraciones alteradas de MAME (tecla DOWN)."
echo "IMPORTANTE: mame.cfg [frontend] NO configura los botones DENTRO del juego."
echo "Para asignar 2 jugadores dentro del juego: TAB > Input (general)."
echo "P1: botones 0-5, SELECT 8, START 9."
echo "P2: botones 0-5, SELECT 10, START 9."
echo "Teclado: flechas, Enter, Tab y Esc se mantienen."
echo "SELECT+START para salir NO esta instalado; usa Esc hasta verificarlo."
