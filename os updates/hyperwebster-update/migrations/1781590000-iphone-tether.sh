#!/bin/sh
# Migration: ship omatether (iPhone USB tether) with NM coexistence.
set -eu
LAYER="${HYPERWEBSTER_LAYER:-${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}}"
SCRIPT="$LAYER/iphone-tether/install-iphone-tether.sh"
if [ ! -f "$SCRIPT" ]; then
  echo "iphone-tether: layer files missing — run hyperwebster-layer-pull" >&2
  exit 1
fi
sudo sh "$SCRIPT"
