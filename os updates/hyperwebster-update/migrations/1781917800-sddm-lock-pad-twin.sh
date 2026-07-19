#!/bin/bash
# Mirror Caelestia lock pad UX onto the SDDM greeter (PIN + hints).
set -euo pipefail

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/sddm-theme"
[ -f "$SRC/caelestia/Main.qml" ] || SRC="$(cd "$(dirname "$0")/../../sddm-theme" && pwd)"

if [ ! -f "$SRC/caelestia/Main.qml" ]; then
  echo "NOTE: sddm-theme source missing — skip"
  exit 0
fi

mkdir -p "$HOME/.local/share/hyperwebster/sddm-theme/caelestia"
install -m 0644 "$SRC/caelestia/Main.qml" "$HOME/.local/share/hyperwebster/sddm-theme/caelestia/Main.qml"
install -m 0755 "$SRC/hyperwebster-greeter-pad" "$HOME/.local/share/hyperwebster/sddm-theme/hyperwebster-greeter-pad"
install -m 0644 "$SRC/hyperwebster-greeter-pad.service" \
  "$HOME/.local/share/hyperwebster/sddm-theme/hyperwebster-greeter-pad.service" 2>/dev/null || true

THEME=/usr/share/sddm/themes/caelestia
if sudo -n true 2>/dev/null; then
  sudo install -Dm0644 "$SRC/caelestia/Main.qml" "$THEME/Main.qml"
  sudo install -Dm0755 "$SRC/hyperwebster-greeter-pad" /usr/local/bin/hyperwebster-greeter-pad
  sudo install -Dm0644 "$SRC/hyperwebster-greeter-pad.service" \
    /etc/systemd/system/hyperwebster-greeter-pad.service
  sudo systemctl daemon-reload
  sudo systemctl restart hyperwebster-greeter-pad.service || true
  echo ":: SDDM greeter mirrored lock pad UX"
else
  echo "NOTE: run: sudo sh $SRC/install-sddm-theme.sh"
fi
