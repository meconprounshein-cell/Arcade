#!/usr/bin/env bash
# RetroVanta: diagnostico + publicacion de resumen tecnico en un solo paso.
# Solo publica datos tecnicos seleccionados. Nunca sube ROMs, IDs de dispositivos,
# contrasenas, IPs, nombres de juegos, configuraciones ni el informe completo.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if [ ! -d .git ]; then echo "ERROR: abre el clon Git de Arcade."; exit 1; fi
if [ "$(git symbolic-ref --quiet --short HEAD)" != "main" ]; then echo "ERROR: usa la rama main."; exit 1; fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: hay modificaciones locales. No se publicara nada para evitar mezclarlas."
  exit 1
fi
echo "1/3 Obteniendo diagnostico local (sin modificar RetroPie)..."
bash "$ROOT/scripts/retrovanta-diagnose.sh"
REPORT="$(find "$HOME" -maxdepth 1 -type d -name 'retrovanta-diagnostico-*' -print | sort | tail -n 1)"
if [ -z "$REPORT" ] || [ ! -f "$REPORT/diagnostico.txt" ]; then echo "ERROR: no se encontro el informe."; exit 1; fi
echo "2/3 Preparando resumen publico, sin datos privados..."
mkdir -p diagnosticos-publicos
DEST="diagnosticos-publicos/retrovanta-resumen-$(date +%Y%m%d-%H%M%S).txt"
{
 echo "RetroVanta OS - resumen tecnico publico"
 echo "Fecha: $(date -u +%Y-%m-%d)"
 echo "Arquitectura: $(uname -m)"
 echo "Kernel: $(uname -r)"
 if [ -r /proc/device-tree/model ]; then
   printf 'Placa: '; tr -d '\000\n' </proc/device-tree/model; printf '\n'
 fi
 if [ -r /etc/os-release ]; then
   . /etc/os-release
   echo "OS: ${PRETTY_NAME:-desconocido}"
 fi
 echo "RAM total (MiB): $(awk '/MemTotal:/ {printf "%d", $2/1024}' /proc/meminfo)"
 echo "Espacio libre de raiz (MiB): $(df -Pm / | awk 'NR==2 {print $4}')"
 echo "Emuladores/Frontend detectados:"
 for exe in emulationstation retroarch mame4all pifba fba2x advmame pcsx-rearmed mupen64plus fceux picodrive snes9x; do
  command -v "$exe" >/dev/null 2>&1 && printf '  %s\n' "$exe" || true
 done
 for d in /opt/retropie/emulators /opt/retropie/libretrocores; do
   if [ -d "$d" ]; then
     printf 'Componentes instalados en %s:\n' "$d"
     find "$d" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' 2>/dev/null | sort || true
   fi
 done
 if [ -f "$REPORT/sistemas.txt" ]; then
  echo "Sistemas de ROMs:"
  sed -n '1,100p' "$REPORT/sistemas.txt" | sed 's/^/  /'
 fi
 if [ -f "$REPORT/listado-roms.txt" ]; then
  echo "Cantidad de archivos de ROMs: $(wc -l < "$REPORT/listado-roms.txt")"
 fi
 for d in /home/pi/.emulationstation/downloaded_images /home/pi/.emulationstation/gamelists /home/pi/RetroPie/roms; do
  if [ -d "$d" ]; then
    echo "Cantidad de capturas en categoria $(basename "$d"): $(find "$d" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | wc -l)"
  fi
 done
 echo "Info sensible excluida: nombres de juegos, IP, hostname, dispositivos USB, claves, configuraciones."
} > "$DEST"
echo "3/3 Publicando solo el resumen tecnico..."
git add -- "$DEST"
git -c user.name="RetroVanta Diagnose" -c user.email="retrovanta-diagnose@users.noreply.github.com" commit -m "Add sanitized RetroVanta diagnostic summary"
if GIT_TERMINAL_PROMPT=0 git push origin main; then
 echo "LISTO. Resumen publicado en:"
 echo "https://github.com/meconprounshein-cell/Arcade/blob/main/$DEST"
else
 echo "NO SE PUDO SUBIR: GitHub requiere autenticacion para escribir, incluso en repositorios publicos."
 echo "El informe sigue guardado localmente. No compartas contrasenas."
 exit 2
fi
