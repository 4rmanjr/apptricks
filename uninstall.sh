#!/usr/bin/env bash
# apptricks uninstall.sh — hapus hasil install setup.sh.
#   ./uninstall.sh          hapus binary + integrasi desktop (data user aman)
#   ./uninstall.sh --purge  + hapus config/aliases DAN tawarkan hapus prefix
set -uo pipefail

PURGE=0
[[ "${1:-}" == "--purge" ]] && PURGE=1

if [[ $PURGE -eq 1 ]]; then echo "apptricks uninstall --purge"; else echo "apptricks uninstall"; fi
rm -fv "$HOME/.local/bin/apptricks" "$HOME/.local/bin/apptricks-gui"
rm -fv "$HOME/.local/share/applications/apptricks-gui.desktop"
rm -fv "$HOME/.local/share/kio/servicemenus/apptricks.desktop"

echo "-- launcher per-app (apptricks-*.desktop):"
GEN=(~/.local/share/applications/apptricks-*.desktop)
if [[ -e "${GEN[0]}" ]]; then
  printf '%s\n' "${GEN[@]}"
  read -r -p "hapus launcher per-app ini juga? [y/N]: " ans
  if [[ "$ans" == "y" || "$ans" == "Y" ]]; then rm -fv "${GEN[@]}"; fi
else
  echo "(tidak ada)"
fi

if [[ $PURGE -eq 1 ]]; then
  BASE=""
  [[ -f "$HOME/.config/apptricks/config" ]] && . "$HOME/.config/apptricks/config"
  rm -rfv "$HOME/.config/apptricks"
  if [[ -n "$BASE" && -d "$BASE" ]]; then
    read -r -p "hapus SELURUH prefix di $BASE? [y/N]: " ans2
    [[ "$ans2" == "y" || "$ans2" == "Y" ]] && rm -rfv "$BASE"
  fi
else
  echo "-- config & prefix dibiarkan (pakai --purge untuk hapus total)"
fi

(kbuildsycoca6 >/dev/null 2>&1 || kbuildsycoca5 >/dev/null 2>&1 || true)
echo "selesai."
