#!/bin/bash
# 1781913200-controller-desktop-stale-flag.sh — Unblock Hyprland gamepad mapper
# after unclean Starman exits leave /tmp/.gaming-session-active behind.
set -euo pipefail
SRC="${HYPERWEBSTER_SRC}/controller-desktop"
LAYER="${HOME}/.local/share/hyperwebster/controller-desktop"
BIN="${HOME}/.local/bin"
mkdir -p "$LAYER" "$BIN" "${HOME}/.config/systemd/user"
install -m 0755 "$SRC/hyperwebster-controller-desktop" "$BIN/hyperwebster-controller-desktop"
install -m 0755 "$SRC/hyperwebster-controller-desktop" "$LAYER/hyperwebster-controller-desktop"
install -m 0644 "$SRC/hyperwebster-controller-desktop.service" \
  "$LAYER/hyperwebster-controller-desktop.service"
install -m 0644 "$SRC/hyperwebster-controller-desktop.service" \
  "${HOME}/.config/systemd/user/hyperwebster-controller-desktop.service"
if [ -f "${HYPERWEBSTER_SRC}/chimera-deckify-gaming/hyperwebster-exit-gaming" ]; then
  if sudo -n true 2>/dev/null; then
    sudo install -m 0755 \
      "${HYPERWEBSTER_SRC}/chimera-deckify-gaming/hyperwebster-exit-gaming" \
      /usr/local/bin/hyperwebster-exit-gaming
  else
    echo "NOTE: run later: sudo install -m 0755 ${HYPERWEBSTER_SRC}/chimera-deckify-gaming/hyperwebster-exit-gaming /usr/local/bin/hyperwebster-exit-gaming"
  fi
fi
# Drop stale marker now if Starman is not running.
pgrep -x gamescope >/dev/null 2>&1 || pgrep -x gamescope-wl >/dev/null 2>&1 \
  || rm -f /tmp/.gaming-session-active
systemctl --user daemon-reload
systemctl --user enable hyperwebster-controller-desktop.service 2>/dev/null || true
systemctl --user restart hyperwebster-controller-desktop.service
echo "controller-desktop restarted (stale gaming-session flag cleared if needed)"
