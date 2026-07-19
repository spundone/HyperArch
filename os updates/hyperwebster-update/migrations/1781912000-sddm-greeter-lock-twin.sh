#!/bin/bash
# 1781912000-sddm-greeter-lock-twin.sh — Greeter UI matches lock screen twin.
LAYER="${HOME}/.local/share/hyperwebster/sddm-theme"
mkdir -p "$LAYER/caelestia"
install -m 0644 "$HYPERWEBSTER_SRC/sddm-theme/caelestia/Main.qml" "$LAYER/caelestia/Main.qml"
install -m 0644 "$HYPERWEBSTER_SRC/sddm-theme/caelestia/theme.conf" "$LAYER/caelestia/theme.conf"
install -m 0644 "$HYPERWEBSTER_SRC/sddm-theme/caelestia/metadata.desktop" \
  "$LAYER/caelestia/metadata.desktop" 2>/dev/null || true
install -m 0755 "$HYPERWEBSTER_SRC/sddm-theme/sddm-theme-sync" "$LAYER/sddm-theme-sync"
install -m 0755 "$HYPERWEBSTER_SRC/sddm-theme/install-sddm-theme.sh" \
  "$LAYER/install-sddm-theme.sh"
echo "SDDM lock-twin greeter staged. Apply with:"
echo "  sudo sh $LAYER/install-sddm-theme.sh"
if sudo -n true 2>/dev/null; then
  sudo env HYPERWEBSTER_SKIP_SHELL_PATCH=1 sh "$LAYER/install-sddm-theme.sh"
fi
