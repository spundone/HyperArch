#!/usr/bin/env bash
# Migration: Super+Shift+R inside gamescope → desktop (xbindkeys + no-op fix).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/chimera-deckify-gaming"
[ -f "$SRC/install-gamescope-exit-bind.sh" ] || exit 0
sudo bash "$SRC/install-gamescope-exit-bind.sh"
# Also refresh switch-to-gaming (touches /tmp/.gaming-session-active).
if [ -f "$SRC/switch-to-gaming" ]; then
  sudo install -Dm0755 "$SRC/switch-to-gaming" /usr/local/bin/switch-to-gaming
fi
echo ":: gamescope Super+Shift+R exit bind (evdev + Steam/CachyOS desktop path)"
