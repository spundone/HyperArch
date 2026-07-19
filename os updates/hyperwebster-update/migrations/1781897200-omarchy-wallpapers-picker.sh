#!/usr/bin/env bash
# 1781897200-omarchy-wallpapers-picker.sh — link Omarchy backgrounds into
# Caelestia Settings → Wallpaper & style (~/Pictures/Wallpapers categories).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
BIN="${HOME}/.local/bin"
SHARE="${HOME}/.local/share/hyperwebster/omarchy-themes"
mkdir -p "$SHARE" "$BIN"
install -m 0755 "$HYPERWEBSTER_SRC/omarchy-themes/hyperwebster-theme" "$BIN/hyperwebster-theme"
install -m 0644 "$HYPERWEBSTER_SRC/omarchy-themes/README.md" "$SHARE/README.md" 2>/dev/null || true
# Refresh live additions manifest if present
if [ -f "$HYPERWEBSTER_SRC/additions-installer/additions.json" ]; then
  mkdir -p "${HOME}/.local/share/hyperwebster/additions-installer"
  install -m 0644 "$HYPERWEBSTER_SRC/additions-installer/additions.json" \
    "${HOME}/.local/share/hyperwebster/additions-installer/additions.json"
fi
"$BIN/hyperwebster-theme" sync-wallpapers
