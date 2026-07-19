#!/bin/bash
# Guide+Start froze the pad: switch-to-gaming stopped controller-desktop while
# still inside that service's cgroup, so the SDDM restart never ran.
set -euo pipefail

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/chimera-deckify-gaming"
[ -f "$SRC/switch-to-gaming" ] || SRC="$(cd "$(dirname "$0")/../../chimera-deckify-gaming" && pwd)"

if [ ! -f "$SRC/switch-to-gaming" ]; then
  echo "NOTE: switch-to-gaming source missing — skip"
  exit 0
fi

if [ -w /usr/local/bin/switch-to-gaming ] || sudo -n true 2>/dev/null; then
  sudo install -Dm0755 "$SRC/switch-to-gaming" /usr/local/bin/switch-to-gaming \
    || install -Dm0755 "$SRC/switch-to-gaming" /usr/local/bin/switch-to-gaming
  echo ":: refreshed switch-to-gaming (cgroup-safe Starman enter)"
else
  echo "NOTE: cannot write /usr/local/bin/switch-to-gaming"
fi
