#!/usr/bin/env bash
# RetroVanta controller audit: read-only, no credentials or ROM metadata.
set -u
OUT="$HOME/retrovanta-controles-$(date +%Y%m%d-%H%M%S).txt"
{
 echo "RETROVANTA - AUDITORIA DE CONTROLES (solo lectura)"
 date -Is 2>/dev/null || date
 echo "== KERNEL / RAM / GPU =="
 uname -r
 awk '/MemTotal:/ {print}' /proc/meminfo
 command -v vcgencmd >/dev/null 2>&1 && vcgencmd get_mem gpu || true
 echo "== DISPOSITIVOS DE ENTRADA =="
 if [ -r /proc/bus/input/devices ]; then
   sed -n -E '/^(I: Bus=|N: Name=|H: Handlers=|B: EV=|B: KEY=|B: ABS=)/p' /proc/bus/input/devices
 fi
 echo "== NODOS JOYSTICK =="
 ls -l /dev/input/js* 2>/dev/null || true
 echo "== HERRAMIENTAS DISPONIBLES =="
 for c in jstest jstest-gtk evtest sdl2-jstest retroarch; do
  command -v "$c" || true
 done
 echo "== ARCHIVOS DE CONFIGURACION (solo nombres y tamaños) =="
 for d in /opt/retropie/configs /home/pi/.emulationstation /home/pi/.config/retroarch /opt/retropie/configs/all/retroarch-joypads; do
  if [ -d "$d" ]; then
    find "$d" -maxdepth 3 -type f \( -name '*joy*cfg' -o -name 'retroarch.cfg' -o -name 'es_input.cfg' -o -name 'emulators.cfg' \) -printf '%p (%s bytes)\n' 2>/dev/null | head -n 80
  fi
 done
 echo "== SERVICIOS DE MANDO =="
 ps -eo comm= 2>/dev/null | grep -Ei 'joy|xpad|retroarch|emulation|antimicro' | sort -u || true
 echo "== VOLTAJE (estado, no cambia configuración) =="
 command -v vcgencmd >/dev/null 2>&1 && vcgencmd get_throttled || true
} > "$OUT" 2>&1
echo "Auditoria guardada: $OUT"
echo "No se cambiaron configuraciones."
echo "Para comprobar pulsaciones: si tenes jstest, ejecuta: jstest /dev/input/js0"
