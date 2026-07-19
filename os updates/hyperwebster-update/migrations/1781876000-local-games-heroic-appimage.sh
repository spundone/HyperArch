#!/usr/bin/env bash
# Migration: repair Heroic AppImage install + ship local-games importer.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"

SRC="$HYPERWEBSTER_SRC/nonsteam-gaming"
ADD="$HYPERWEBSTER_SRC/additions-installer"

if [ -f "$SRC/install-nonsteam-gaming.sh" ]; then
  bash "$SRC/install-nonsteam-gaming.sh"
fi

# Refresh Additions manifest so Local game library + Heroic check appear.
if [ -f "$ADD/install-additions-installer.sh" ]; then
  bash "$ADD/install-additions-installer.sh" || true
elif [ -f "$ADD/additions.json" ]; then
  mkdir -p "$HOME/.local/share/hyperwebster/additions-installer"
  install -m 0644 "$ADD/additions.json" \
    "$HOME/.local/share/hyperwebster/additions-installer/additions.json"
fi

echo ":: nonsteam local-games + Heroic AppImage repair"
