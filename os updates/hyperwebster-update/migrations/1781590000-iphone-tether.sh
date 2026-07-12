#!/bin/sh
# Migration: ship omatether (iPhone USB tether) with NM coexistence.
set -eu
LAYER="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
SCRIPT="$LAYER/iphone-tether/install-iphone-tether.sh"
if [ -f "$SCRIPT" ]; then
  sh "$SCRIPT"
else
  echo "iphone-tether: layer files missing — run hyperwebster-layer-pull" >&2
fi
