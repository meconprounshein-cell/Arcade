#!/usr/bin/env bash
# RetroVanta: instala ES-generic-shutdown de crcerror, boton GPIO3 + GND.
# Requiere cableado verificado en pines fisicos 5 y 6.
set -euo pipefail
AUTOSTART=/opt/retropie/configs/all/autostart.sh
TARGET=/home/pi/RetroPie/scripts/multi_switch.sh
if [ ! -f "$AUTOSTART" ]; then echo "ERROR: no existe autostart.sh"; exit 1; fi
if ! command -v raspi-gpio >/dev/null 2>&1; then
 echo "FALTA raspi-gpio. Instalalo con: sudo apt-get install raspi-gpio"
 echo "No se modifico nada."
 exit 1
fi
if [ -f "$TARGET" ] && grep -q 'Multi Switch Shutdown' "$TARGET"; then
 echo "Script original ya descargado: $TARGET"
else
 echo "DESCARGANDO script original de crcerror..."
 mkdir -p "$(dirname "$TARGET")"
 wget -q -O "$TARGET.nuevo" https://raw.githubusercontent.com/crcerror/ES-generic-shutdown/master/multi_switch.sh
 test -s "$TARGET.nuevo"
 if ! grep -q 'function GenericButton' "$TARGET.nuevo"; then
  echo "ERROR: descarga no corresponde al script esperado"; rm -f "$TARGET.nuevo"; exit 1
 fi
 mv "$TARGET.nuevo" "$TARGET"
fi
chmod +x "$TARGET"
# Confirmar lectura del pin sin forzar entrada ni apagar por accidente.
state=$(raspi-gpio get 3 2>&1 || true)
echo "GPIO3: $state"
if ! printf '%s' "$state" | grep -q 'level=1'; then
 echo "ATENCION: GPIO3 no marca HIGH. Revisar conexion antes de habilitar apagado."
 echo "No se cambio autostart."
 exit 1
fi
if grep -Eq 'multi_switch|gpio-shutdown|shutdown_button|powerbutton' "$AUTOSTART"; then
 echo "YA HAY una linea de apagado en autostart.sh. No se agrega otra."
 grep -En 'multi_switch|gpio-shutdown|shutdown_button|powerbutton' "$AUTOSTART"
 exit 0
fi
# Guardar copia y agregar el daemon antes de EmulationStation.
cp "$AUTOSTART" "$AUTOSTART.retroventa-antes-apagado-$(date +%Y%m%d-%H%M%S)"
export RV_AUTO="$AUTOSTART" RV_CMD="$TARGET --generic powerbtn=3 &"
python3 - <<'PY'
from pathlib import Path
import os
p=Path(os.environ['RV_AUTO'])
lines=p.read_text().splitlines()
cmd=os.environ['RV_CMD']
idx=next((i for i,x in enumerate(lines) if 'emulationstation' in x and not x.lstrip().startswith('#')),len(lines))
lines.insert(idx,cmd)
p.write_text('\n'.join(lines)+'\n')
PY
echo "CONFIGURADO: $TARGET --generic powerbtn=3"
echo "Reinicia para activarlo. El boton debe ir entre pin fisico 5 (GPIO3) y 6 (GND)."
echo "ADVERTENCIA: el GPIO3 debe corresponder al cableado real."
