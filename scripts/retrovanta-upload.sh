#!/usr/bin/env bash
# Sube el ultimo informe RetroVanta al repositorio privado configurado.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if [ ! -d .git ]; then echo "ERROR: se necesita un clon Git de Arcade."; exit 1; fi
BRANCH="$(git symbolic-ref --quiet --short HEAD || true)"
if [ "$BRANCH" != "main" ]; then echo "ERROR: ejecuta desde la rama main (actual: $BRANCH)."; exit 1; fi
URL="$(git remote get-url origin)"
case "$URL" in
  https://github.com/meconprounshein-cell/Arcade|https://github.com/meconprounshein-cell/Arcade.git|git@github.com:meconprounshein-cell/Arcade.git) ;;
  *) echo "ERROR: origin no corresponde a meconprounshein-cell/Arcade"; exit 1;;
esac
REPORT="$(find "$HOME" -maxdepth 1 -type d -name 'retrovanta-diagnostico-*' -print | sort | tail -n 1)"
if [ -z "$REPORT" ] || [ ! -f "$REPORT/diagnostico.txt" ]; then
  echo "No hay diagnostico. Ejecuta: bash Arcade/scripts/retrovanta-diagnose.sh"
  exit 1
fi
ID="$(basename "$REPORT")"
DEST="diagnosticos/$ID"
mkdir -p "$DEST"
for f in diagnostico.txt listado-roms.txt sistemas.txt LEEME.txt; do
  [ ! -f "$REPORT/$f" ] || cp "$REPORT/$f" "$DEST/$f"
done
echo "Archivos preparados en $DEST"
echo "AVISO: se publicaran nombres de juegos, dispositivos, rutas y datos del sistema."
echo "Verifica que el repositorio sigue PRIVADO antes de continuar."
read -r -p "¿Subir al repositorio privado Arcade? [s/N] " ANSWER
case "$ANSWER" in s|S|si|SI|Si) ;; *) echo "Cancelado; archivos locales conservados."; exit 0;; esac
git add -- "$DEST"
if git diff --cached --quiet; then echo "El informe ya estaba registrado."; exit 0; fi
git -c user.name="RetroVanta Diagnose" -c user.email="retrovanta-diagnose@users.noreply.github.com" commit -m "Add Raspberry Pi diagnostic $ID"
echo "Subiendo a GitHub. Si pide autenticacion HTTPS, usa un token, NO tu contrasena."
git push origin main
echo "Listo: https://github.com/meconprounshein-cell/Arcade/tree/main/$DEST"
