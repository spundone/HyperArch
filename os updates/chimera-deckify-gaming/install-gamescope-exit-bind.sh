#!/usr/bin/env bash
# install-gamescope-exit-bind.sh — Ctrl+Shift+F9 exits gamescope via Steam/CachyOS path.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "must run as root" >&2; exit 1; }

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

install -Dm0755 "$HERE/hyperwebster-set-desktop-session" /usr/local/bin/hyperwebster-set-desktop-session
install -Dm0755 "$HERE/hyperwebster-exit-gaming" /usr/local/bin/hyperwebster-exit-gaming
install -Dm0755 "$HERE/hyperwebster-gamescope-hotkeyd" /usr/local/bin/hyperwebster-gamescope-hotkeyd
install -Dm0755 "$HERE/switch-to-desktop" /usr/local/bin/switch-to-desktop
install -Dm0755 "$HERE/os-session-select" /usr/lib/os-session-select
# Overlay so Steam → Switch to Desktop also targets Hyprland.
install -Dm0755 "$HERE/steamos-session-select" /usr/bin/steamos-session-select
install -Dm0644 "$HERE/hyperwebster-gamescope-hotkeyd.service" \
  /usr/lib/systemd/user/hyperwebster-gamescope-hotkeyd.service

if [ -x "$HERE/install-gaming-sudoers.sh" ]; then
  sh "$HERE/install-gaming-sudoers.sh" || true
fi

DROP_DIR=/usr/lib/systemd/user/gamescope-session.service.wants
install -d "$DROP_DIR"
ln -sfn ../hyperwebster-gamescope-hotkeyd.service \
  "$DROP_DIR/hyperwebster-gamescope-hotkeyd.service"

if getent group input >/dev/null 2>&1; then
  u1000=$(getent passwd 1000 | cut -d: -f1 || true)
  [ -n "$u1000" ] && usermod -aG input "$u1000" 2>/dev/null || true
fi

if [ -f /etc/xbindkeysrc ]; then
  cat > /etc/xbindkeysrc <<'EOF'
# HyperWebster: use Ctrl+Shift+F9 (evdev hotkeyd), not xbindkeys.
EOF
fi

systemctl daemon-reload 2>/dev/null || true

echo "gamescope exit: Super+Shift+R (or Ctrl+Shift+F9) → Steam Switch-to-Desktop path (Hyprland)"
echo "  logs: /tmp/hyperwebster-gamescope-exit.log"
