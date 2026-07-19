#!/bin/bash
# 1781914000-controller-gamescope-bindings-lock-pin.sh — Gamescope-like pad map
# on Hyprland + lock-screen PIN entry via gamepad.
set -euo pipefail
SRC="${HYPERWEBSTER_SRC}/controller-desktop"
LAYER="${HOME}/.local/share/hyperwebster/controller-desktop"
BIN="${HOME}/.local/bin"
mkdir -p "$LAYER" "$BIN" "${HOME}/.config/systemd/user"
install -m 0755 "$SRC/hyperwebster-controller-desktop" "$BIN/hyperwebster-controller-desktop"
install -m 0755 "$SRC/hyperwebster-controller-desktop" "$LAYER/hyperwebster-controller-desktop"
install -m 0644 "$SRC/profile.json" "$LAYER/profile.json"
install -m 0644 "$SRC/hyperwebster-controller-desktop.service" \
  "$LAYER/hyperwebster-controller-desktop.service"
install -m 0644 "$SRC/hyperwebster-controller-desktop.service" \
  "${HOME}/.config/systemd/user/hyperwebster-controller-desktop.service"
install -m 0644 "$SRC/README.md" "$LAYER/README.md" 2>/dev/null || true

# Lock surface hint for pad PIN entry
LOCK_SRC="${HYPERWEBSTER_SRC}/lockscreen-polish"
if [ -f "$LOCK_SRC/LockSurface.qml" ] && [ -x "$LOCK_SRC/patch-locksurface.sh" ]; then
  sh "$LOCK_SRC/patch-locksurface.sh" || true
elif [ -f "$LOCK_SRC/LockSurface.qml" ]; then
  sudo -n install -m 0644 "$LOCK_SRC/LockSurface.qml" \
    /etc/xdg/quickshell/caelestia/modules/lock/LockSurface.qml 2>/dev/null || true
fi

pgrep -x gamescope >/dev/null 2>&1 || rm -f /tmp/.gaming-session-active
systemctl --user daemon-reload
systemctl --user enable hyperwebster-controller-desktop.service 2>/dev/null || true
systemctl --user restart hyperwebster-controller-desktop.service
echo "controller-desktop: Gamescope-like bindings + lock PIN mode enabled"
