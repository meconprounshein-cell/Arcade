#!/usr/bin/env bash
# RetroVanta: recupera controles por defecto del menu MAME4ALL (incluido UI Down).
# MAME4ALL recrea default.cfg automaticamente al iniciarse.
# Conserva el archivo modificado renombrado. No cambia PiFBA, RetroArch ni ROMs.
set -euo pipefail
if pgrep -f '/mame4all-pi/mame|/mame-mame4all/mame' >/dev/null 2>&1; then
  echo "Cierra el juego MAME4ALL antes de ejecutar este reparador."
  exit 1
fi
found=0
for f in /opt/retropie/configs/mame-mame4all/cfg/default.cfg /opt/retropie/emulators/mame4all-pi/cfg/default.cfg; do
 if [ -f "$f" ]; then
   dir="$(dirname "$f")"
   if [ ! -w "$dir" ]; then
      echo "Sin permiso para $f; ejecuta con sudo: sudo bash scripts/mame4all-restaurar.sh"
      exit 1
   fi
   target="$dir/default-retrovanta-anterior-$(date +%Y%m%d-%H%M%S).cfg"
   mv "$f" "$target"
   echo "Configuracion anterior conservada: $target"
   found=1
 fi
done
if [ "$found" -eq 0 ]; then
 echo "No encontre default.cfg modificado. Los controles generales ya parecen estar por defecto."
else
 echo "LISTO. Al abrir MAME4ALL se recuperaran los controles predeterminados."
fi
echo "No se tocan los ajustes especificos de cada juego (por ejemplo simpsons.cfg)."
echo "Si la flecha sigue sin funcionar, revisaremos esa configuracion individual."
