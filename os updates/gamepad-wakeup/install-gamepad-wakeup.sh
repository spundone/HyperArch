#!/bin/sh
# install-gamepad-wakeup.sh — let a gamepad resume from sleep (s2idle + USB wake).
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHARE="$HOME/.local/share/hyperwebster/gamepad-wakeup"

mkdir -p "$SHARE"
install -m 0644 "$SRC/99-hyperwebster-gamepad-wakeup.rules" "$SHARE/99-hyperwebster-gamepad-wakeup.rules"
install -m 0755 "$SRC/hyperwebster-gamepad-wakeup" "$SHARE/hyperwebster-gamepad-wakeup"
install -m 0644 "$SRC/README.md" "$SHARE/README.md"

sudo install -Dm0755 "$SHARE/hyperwebster-gamepad-wakeup" /usr/local/bin/hyperwebster-gamepad-wakeup
sudo install -Dm0644 "$SHARE/99-hyperwebster-gamepad-wakeup.rules" \
  /etc/udev/rules.d/99-hyperwebster-gamepad-wakeup.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --action=add
sudo udevadm trigger --subsystem-match=input --action=add
sudo /usr/local/bin/hyperwebster-gamepad-wakeup

echo "gamepad-wakeup: USB hosts + pads can wake (s2idle). Deep sleep needs pad remote-wakeup hardware."
