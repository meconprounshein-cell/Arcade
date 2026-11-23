#!/usr/bin/env bash
# Paso seguro: obtener fuente PiFBA y ubicar el efecto scanlines sin instalar nada.
set -euo pipefail
SRC="$HOME/RetroVanta-pifba-src"
OUT="$HOME/RetroPie/roms/retrovanta-pifba-diagnostico.txt"
mkdir -p "$(dirname "$OUT")"
{
 echo "RETROVANTA - DIAGNOSTICO PIFBA"
 echo "Fecha: $(date)"
 echo "Ejecutable instalado:"
 ls -l /opt/retropie/emulators/pifba/fba2x 2>&1 || true
 echo "Compiler:"
 command -v gcc || true
 command -v make || true
 echo "Version:"
 gcc --version 2>/dev/null | head -1 || true
} > "$OUT"
if [ ! -d "$SRC/.git" ]; then
 echo "Descargando codigo fuente original, sin tocar el emulador instalado..."
 if ! git clone --depth 1 https://github.com/squidrpi/pifba.git "$SRC"; then
  echo "No se pudo descargar fuente de GitHub." | tee -a "$OUT"
  exit 1
 fi
fi
{
 echo ""
 echo "Archivos con referencias a scanlines y DisplayEffect:"
 grep -RniE 'DisplayEffect|scanline|Scanline|scanLine' "$SRC/rpi" "$SRC/FBAcapex_src" --include='*.c' --include='*.cpp' --include='*.h' --include='*.glsl' --include='*.fsh' 2>/dev/null | head -65 || true
 echo ""
 echo "Archivos de construccion:"
 find "$SRC" -maxdepth 2 -iname '*makefile*' -print
 echo ""
 echo "NO se alteraron juegos, controles ni ejecutable PiFBA."
} >> "$OUT"
echo "Listo. Desde Cx Explorador entra a roms y comparti:"
echo "retrovanta-pifba-diagnostico.txt"
