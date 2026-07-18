#!/bin/sh
# patch-locksurface.sh — overlay HyperWebster frosted lock UI.
# Idempotent. Runs as root (installer or pacman hook).
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/modules/lock/LockSurface.qml}
SRC="$SELF_DIR/LockSurface.qml"

[ -f "$SRC" ] || { echo "LockSurface.qml missing next to $(basename "$0")" >&2; exit 1; }

if [ ! -f "$TARGET" ]; then
  echo "caelestia lock surface not found at $TARGET — skipping"
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-hyperwebster" 2>/dev/null || true
install -m 0644 "$SRC" "$TARGET"
echo ":: installed $TARGET (HyperWebster frosted lock)"
