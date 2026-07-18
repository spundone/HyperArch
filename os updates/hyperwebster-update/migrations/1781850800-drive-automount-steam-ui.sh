#!/usr/bin/env bash
# Migration: Steam-ready drive automount + System tools Drives UI.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

DRIVE="$HYPERWEBSTER_SRC/drive-automount"
TOOLS="$HYPERWEBSTER_SRC/system-tools"

if [ -d "$DRIVE" ] && [ -x "$DRIVE/install-drive-automount.sh" ]; then
  sudo sh "$DRIVE/install-drive-automount.sh"
fi

# Remount with uid/gid for existing FAT/NTFS Steam libraries.
if [ -x /usr/local/bin/hyperwebster-drive-automount ]; then
  sudo /usr/local/bin/hyperwebster-drive-automount || true
fi

if [ -f "$TOOLS/install-system-tools.sh" ]; then
  # Refresh System tools page (Drives section) into the live shell.
  bash "$TOOLS/install-system-tools.sh" || true
fi

echo ":: drive automount Steam-ready + System tools Drives UI"
