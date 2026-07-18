#!/bin/sh
# patch-colours-page.sh — overlay HyperWebster ColourSelect.qml onto the
# upstream under-construction stub. Idempotent. Runs as root (installer or
# pacman hook after nosignal-shell / caelestia-shell upgrades).
#
# No PageCompRegistry edit — Colours is already registered as Wallpaper &
# style sub-page index 3.
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/modules/nexus/pages/wallandstyle/ColourSelect.qml}
SRC="$SELF_DIR/ColourSelect.qml"

[ -f "$SRC" ] || { echo "ColourSelect.qml missing next to $(basename "$0")" >&2; exit 1; }

if [ ! -f "$TARGET" ]; then
  echo "caelestia-shell ColourSelect.qml not found at $TARGET — nothing to patch"
  exit 0
fi

# Keep one upstream backup for easy revert.
cp -n "$TARGET" "$TARGET.pre-hyperwebster" 2>/dev/null || true
install -m 0644 "$SRC" "$TARGET"
echo ":: installed $TARGET (HyperWebster Colours page)"
