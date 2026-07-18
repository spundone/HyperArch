#!/usr/bin/env bash
# Migration: fix nonsteam-gaming same-file install when run from layer SHARE.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

SRC="$HYPERWEBSTER_SRC/nonsteam-gaming"
ADD="$HYPERWEBSTER_SRC/additions-installer"

if [ -f "$SRC/install-nonsteam-gaming.sh" ]; then
  bash "$SRC/install-nonsteam-gaming.sh"
fi

if [ -f "$ADD/install-additions-installer.sh" ]; then
  bash "$ADD/install-additions-installer.sh" || true
elif [ -f "$ADD/additions.json" ]; then
  mkdir -p "$HOME/.local/share/hyperwebster/additions-installer"
  install -m 0644 "$ADD/additions.json" \
    "$HOME/.local/share/hyperwebster/additions-installer/additions.json"
fi

echo ":: nonsteam-gaming same-file install fix"
