#!/bin/sh
# patch-drawer-stacking.sh - raise dashboard above nspanels / sibling drawers.
# Idempotent. Runs as root (installer or pacman hook).
set -eu
SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
QS=${QS:-/etc/xdg/quickshell/caelestia}
DRAWERS="$QS/modules/drawers"
[ -d "$DRAWERS" ] || { echo "caelestia-shell drawers not found at $DRAWERS - skip"; exit 0; }

install -m 0644 "$SELF_DIR/ContentWindow.qml" "$DRAWERS/ContentWindow.qml"
install -m 0644 "$SELF_DIR/Panels.qml" "$DRAWERS/Panels.qml"
echo ":: patched $DRAWERS (dashboard Overlay + z-order)"
