#!/bin/bash
# 1781912800-decky-qam-portal-fix.sh — Portal-aware Decky QAM tab inject for Game Mode.
set -euo pipefail
SRC="${HYPERWEBSTER_SRC}/nonsteam-gaming"
BIN="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"
install -d -m 0755 "$BIN" "$UNIT_DIR"
install -m 0755 "$SRC/hyperwebster-decky-qam-fix" "$BIN/hyperwebster-decky-qam-fix"
install -m 0644 "$SRC/hyperwebster-decky-qam-fix.service" \
  "$UNIT_DIR/hyperwebster-decky-qam-fix.service"
if [ -f "$SRC/hyperwebster-decky-cef-ensure" ]; then
  install -m 0755 "$SRC/hyperwebster-decky-cef-ensure" "$BIN/hyperwebster-decky-cef-ensure"
fi
if [ -f "$SRC/hyperwebster-decky-cef-ensure.service" ]; then
  install -m 0644 "$SRC/hyperwebster-decky-cef-ensure.service" \
    "$UNIT_DIR/hyperwebster-decky-cef-ensure.service"
  systemctl --user enable hyperwebster-decky-cef-ensure.service 2>/dev/null || true
fi
systemctl --user daemon-reload
systemctl --user enable --now hyperwebster-decky-qam-fix.service
echo "Decky QAM portal fix installed. Re-enter Starman, wait ~10s, open Guide+X."
