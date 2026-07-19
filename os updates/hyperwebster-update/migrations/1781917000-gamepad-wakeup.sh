#!/bin/bash
# Enable gamepad wake-from-sleep (USB host wakeup + no pad autosuspend).
set -euo pipefail

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/gamepad-wakeup"
[ -f "$SRC/install-gamepad-wakeup.sh" ] || \
  SRC="$(cd "$(dirname "$0")/../../gamepad-wakeup" && pwd)"

if [ ! -f "$SRC/hyperwebster-gamepad-wakeup" ]; then
  echo "NOTE: gamepad-wakeup source missing — skip"
  exit 0
fi

mkdir -p "$HOME/.local/share/hyperwebster/gamepad-wakeup"
install -m 0644 "$SRC/99-hyperwebster-gamepad-wakeup.rules" \
  "$HOME/.local/share/hyperwebster/gamepad-wakeup/99-hyperwebster-gamepad-wakeup.rules"
install -m 0755 "$SRC/hyperwebster-gamepad-wakeup" \
  "$HOME/.local/share/hyperwebster/gamepad-wakeup/hyperwebster-gamepad-wakeup"
install -m 0644 "$SRC/README.md" \
  "$HOME/.local/share/hyperwebster/gamepad-wakeup/README.md" 2>/dev/null || true

if sudo -n true 2>/dev/null; then
  sudo install -Dm0755 "$SRC/hyperwebster-gamepad-wakeup" /usr/local/bin/hyperwebster-gamepad-wakeup
  sudo install -Dm0644 "$SRC/99-hyperwebster-gamepad-wakeup.rules" \
    /etc/udev/rules.d/99-hyperwebster-gamepad-wakeup.rules
  sudo udevadm control --reload-rules
  sudo udevadm trigger --subsystem-match=usb --action=add
  sudo /usr/local/bin/hyperwebster-gamepad-wakeup
  echo ":: gamepad-wakeup installed"
else
  echo "NOTE: run: sudo sh $SRC/install-gamepad-wakeup.sh"
fi
