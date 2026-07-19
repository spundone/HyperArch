#!/bin/bash
# Lock-screen PIN mode never armed: Hyprland leaves LockedHint=no while
# Caelestia WlSessionLock is up, and session_locked() trusted LockedHint alone.
set -euo pipefail

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/controller-desktop"
[ -f "$SRC/hyperwebster-controller-desktop" ] || \
  SRC="$(cd "$(dirname "$0")/../../controller-desktop" && pwd)"

install -Dm0755 "$SRC/hyperwebster-controller-desktop" \
  "$HOME/.local/bin/hyperwebster-controller-desktop"
install -Dm0644 "$SRC/profile.json" \
  "$HOME/.local/share/hyperwebster/controller-desktop/profile.json" 2>/dev/null || true

systemctl --user restart hyperwebster-controller-desktop.service 2>/dev/null || true
echo ":: controller-desktop: lock detect via qs isLocked (not LockedHint alone)"
