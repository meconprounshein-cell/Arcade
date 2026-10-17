#!/usr/bin/env bash
# RetroVanta Diagnose v0.1 - inventario de solo lectura para Raspberry Pi / RetroPie.
# No instala paquetes, no cambia configuraciones y no copia ROMs, BIOS ni credenciales.
set -u
umask 077
export LC_ALL=C
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${HOME}/retrovanta-diagnostico-${STAMP}"
mkdir -p "$OUT" || exit 1
LOG="$OUT/diagnostico.txt"
: > "$LOG"
section() { printf '\n===== %s =====\n' "$1" >> "$LOG"; }
run() { printf '\n$ %s\n' "$1" >> "$LOG"; bash -c "$1" >> "$LOG" 2>&1 || printf '(no disponible o acceso denegado)\n' >> "$LOG"; }
section "RETROVANTA DIAGNOSE v0.1"
printf 'Fecha: %s\n' "$(date -Is 2>/dev/null || date)" >> "$LOG"
printf 'Usuario: %s\n' "$(id -un)" >> "$LOG"
section "PLACA Y SISTEMA"
for f in /proc/device-tree/model /proc/cpuinfo /etc/os-release /etc/debian_version; do
  if [ -r "$f" ]; then
    echo "--- $f" >> "$LOG"
    if [ "$f" = /proc/cpuinfo ]; then
      grep -E '^(model name|Processor|Hardware|Revision|Serial|BogoMIPS|Features|CPU architecture)' "$f" | sed -E 's/^(Serial[[:space:]]*:[[:space:]]*).*/\1[OCULTO]/' >> "$LOG" || :
    elif [ "$f" = /proc/device-tree/model ]; then
      tr -d '\000' < "$f" >> "$LOG"; echo >> "$LOG"
    else cat "$f" >> "$LOG"; fi
  fi
done
run "uname -a"
run "getconf LONG_BIT"
run "free -m"
run "uptime"
section "ALMACENAMIENTO"
run "lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,RO"
run "df -hT"
section "VIDEO Y AUDIO"
run "command -v tvservice >/dev/null && tvservice -s"
run "command -v vcgencmd >/dev/null && vcgencmd get_mem gpu"
run "command -v aplay >/dev/null && aplay -l"
run "command -v amixer >/dev/null && amixer scontrols"
section "USB Y ENTRADAS"
run "lsusb"
run "lsusb -t"
if [ -r /proc/bus/input/devices ]; then
  sed -E 's/(Uniq=).*/\1[OCULTO]/' /proc/bus/input/devices >> "$LOG"
fi
for p in /dev/input/by-id /dev/input/by-path; do
  if [ -d "$p" ]; then
    echo "--- $p" >> "$LOG"
    find "$p" -maxdepth 1 -type l -printf '%f -> %l\n' 2>/dev/null >> "$LOG" || :
  fi
done
section "EMULADORES Y FRONTEND"
for exe in emulationstation retroarch retroarch-joyconfig mame4all pifba fba2x advmame pcsx-rearmed mupen64plus fceux picodrive snes9x; do
  command -v "$exe" >> "$LOG" 2>/dev/null || :
done
for d in /opt/retropie/emulators /opt/retropie/libretrocores /opt/retropie/supplementary /usr/local/bin; do
  if [ -d "$d" ]; then
    echo "--- $d" >> "$LOG"
    find "$d" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | sort >> "$LOG"
  fi
done
section "CONFIGURACIONES: EXISTENCIA Y TAMANOS (SIN CONTENIDO)"
for d in /opt/retropie/configs /home/pi/.emulationstation /home/pi/.config/retroarch /boot; do
  if [ -d "$d" ]; then
    echo "--- $d" >> "$LOG"
    find "$d" -maxdepth 2 -type f \( -name '*.cfg' -o -name '*.ini' -o -name '*.xml' -o -name 'config.txt' -o -name 'cmdline.txt' \) -printf '%P (%s bytes)\n' 2>/dev/null | head -n 180 >> "$LOG"
  fi
done
section "ARRANQUE Y APAGADO: NOMBRES DE SERVICIOS"
run "systemctl list-unit-files --type=service --no-pager 2>/dev/null | grep -Ei 'retro|emulation|power|shutdown|gpio|autostart' | head -n 60"
for f in /etc/rc.local /home/pi/.bash_profile /home/pi/.profile /opt/retropie/configs/all/autostart.sh; do
  if [ -f "$f" ]; then printf '%s existe (%s bytes)\n' "$f" "$(wc -c < "$f")" >> "$LOG"; fi
done
section "ROMs: CANTIDAD Y NOMBRES DE ARCHIVOS, NUNCA CONTENIDO"
ROMS=""
for d in /home/pi/RetroPie/roms /opt/retropie/roms /home/pi/roms; do
  if [ -d "$d" ]; then ROMS="$d"; break; fi
done
if [ -n "$ROMS" ]; then
  echo "Carpeta: $ROMS" >> "$LOG"
  find "$ROMS" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort > "$OUT/sistemas.txt"
  find "$ROMS" -type f -printf '%P\t%s bytes\n' 2>/dev/null | sort > "$OUT/listado-roms.txt"
  printf 'Archivos encontrados: %s\n' "$(wc -l < "$OUT/listado-roms.txt")" >> "$LOG"
  printf 'Sistemas encontrados: %s\n' "$(wc -l < "$OUT/sistemas.txt")" >> "$LOG"
else echo "No se encontro una carpeta ROM habitual." >> "$LOG"; fi
section "CAPTURAS: CANTIDADES, NO IMAGENES"
for d in /home/pi/.emulationstation/downloaded_images /home/pi/.emulationstation/gamelists /home/pi/RetroPie/roms; do
  if [ -d "$d" ]; then
    n="$(find "$d" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | wc -l)"
    printf '%s: %s imagenes\n' "$d" "$n" >> "$LOG"
  fi
done
cat > "$OUT/LEEME.txt" <<'NOTE'
RETROVANTA DIAGNOSTICO v0.1
Este informe es de solo lectura y no contiene ROMs, BIOS ni contrasenas.
Incluye nombres de archivos de juegos, informacion del sistema y dispositivos USB.
REVISA los TXT antes de compartirlos: nombres de archivos o rutas pueden ser privados.
No publiques el ZIP en un repositorio publico.
NOTE
ZIP="${OUT}.tar.gz"
tar -czf "$ZIP" -C "$(dirname "$OUT")" "$(basename "$OUT")" || exit 1
printf '\nDiagnostico terminado. Archivo: %s\n' "$ZIP"
printf 'Para revisar: less "%s"\n' "$LOG"
printf 'No se modificaron configuraciones ni archivos del sistema.\n'
