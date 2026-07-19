#!/usr/bin/env bash
# 1781904400-sddm-greeter-starman.sh — Starman button + Guide+A on SDDM greeter.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
# Stage into the live layer so sddm-theme-sync picks up Main.qml even before
# a full layer pull.
LAYER="${HOME}/.local/share/hyperwebster/sddm-theme"
mkdir -p "$LAYER/caelestia"
install -m 0644 "$HYPERWEBSTER_SRC/sddm-theme/caelestia/Main.qml" "$LAYER/caelestia/Main.qml"
install -m 0644 "$HYPERWEBSTER_SRC/sddm-theme/caelestia/metadata.desktop" \
  "$LAYER/caelestia/metadata.desktop" 2>/dev/null || true
install -m 0755 "$HYPERWEBSTER_SRC/sddm-theme/hyperwebster-greeter-pad" \
  "$LAYER/hyperwebster-greeter-pad"
install -m 0644 "$HYPERWEBSTER_SRC/sddm-theme/hyperwebster-greeter-pad.service" \
  "$LAYER/hyperwebster-greeter-pad.service"
install -m 0755 "$HYPERWEBSTER_SRC/sddm-theme/install-sddm-theme.sh" \
  "$LAYER/install-sddm-theme.sh"
install -m 0755 "$HYPERWEBSTER_SRC/sddm-theme/sddm-theme-sync" \
  "$LAYER/sddm-theme-sync" 2>/dev/null || true
echo "SDDM Starman greeter staged. Apply with:"
echo "  sudo sh $LAYER/install-sddm-theme.sh"
# Best-effort if passwordless sudo is available.
if sudo -n true 2>/dev/null; then
  sudo env HYPERWEBSTER_SKIP_SHELL_PATCH=1 sh "$LAYER/install-sddm-theme.sh"
fi
