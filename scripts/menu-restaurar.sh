#!/usr/bin/env bash
# Revierte la ultima instalacion de tema RetroVanta.
set -euo pipefail
if pgrep -x emulationstation >/dev/null 2>&1; then echo "Cierra EmulationStation antes de restaurar."; exit 1; fi
BASE="$HOME/retrovanta-backups"
B="$(find "$BASE" -mindepth 1 -maxdepth 1 -type d -name 'menu-*' 2>/dev/null | sort | tail -n 1)"
if [ -z "$B" ]; then echo "No existe copia de seguridad."; exit 1; fi
THEMES="$HOME/.emulationstation/themes"
if [ -d "$B/retrovanta-anterior" ]; then
  rm -rf "$THEMES/retrovanta"
  cp -a "$B/retrovanta-anterior" "$THEMES/retrovanta"
else
  rm -rf "$THEMES/retrovanta"
fi
if [ -f "$B/es_settings.cfg" ]; then cp -p "$B/es_settings.cfg" "$HOME/.emulationstation/es_settings.cfg"; else
  echo "Aviso: no habia archivo de ajustes previo; selecciona otro tema desde EmulationStation."
fi
echo "Tema anterior restaurado. Inicia EmulationStation."
