#!/usr/bin/env bash
# Fix Caelestia session menu Shut down / Reboot (silent no-op via SessionManager).
set -euo pipefail

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/session-power"
[ -f "$SRC/install-session-power.sh" ] || \
  SRC="$(cd "$(dirname "$0")/../../session-power" && pwd)"

[ -f "$SRC/install-session-power.sh" ] || exit 0
sh "$SRC/install-session-power.sh"
