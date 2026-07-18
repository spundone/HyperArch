#!/usr/bin/env bash
# Migration: Non-Steam gaming helpers (Heroic, SRM, Decky, Millennium) + Additions.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

SRC="$HYPERWEBSTER_SRC/nonsteam-gaming"
ADD="$HYPERWEBSTER_SRC/additions-installer"

if [ -f "$SRC/install-nonsteam-gaming.sh" ]; then
  bash "$SRC/install-nonsteam-gaming.sh"
fi

# Refresh Additions manifest (new gaming rows).
if [ -f "$ADD/install-additions-installer.sh" ]; then
  bash "$ADD/install-additions-installer.sh" || true
elif [ -f "$ADD/additions.json" ] && [ -f "$HOME/.local/share/hyperwebster/additions-installer/additions.json" ]; then
  install -m 0644 "$ADD/additions.json" \
    "$HOME/.local/share/hyperwebster/additions-installer/additions.json"
fi

echo ":: nonsteam-gaming helpers + Additions (Heroic / SRM / Decky / Millennium)"
