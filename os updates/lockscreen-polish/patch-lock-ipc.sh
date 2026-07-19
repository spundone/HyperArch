#!/bin/sh
# patch-lock-ipc.sh — expose qs lock feed/backspace/clear/submit for gamepad PIN.
# Idempotent. Runs as root (installer or pacman hook).
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOCK_DIR=${LOCK_DIR:-/etc/xdg/quickshell/caelestia/modules/lock}

for f in Lock.qml Pam.qml; do
  SRC="$SELF_DIR/$f"
  TARGET="$LOCK_DIR/$f"
  [ -f "$SRC" ] || { echo "$f missing next to $(basename "$0")" >&2; exit 1; }
  if [ ! -f "$TARGET" ]; then
    echo "caelestia $f not found at $TARGET — skipping"
    continue
  fi
  cp -n "$TARGET" "$TARGET.pre-hyperwebster-ipc" 2>/dev/null || true
  install -m 0644 "$SRC" "$TARGET"
  echo ":: installed $TARGET (lock IPC feed for gamepad)"
done
