#!/usr/bin/env bash
# Migration: fix drive automount for exFAT labels with spaces (lsblk JSON discovery).
# Idempotent — reinstalls drive-automount and remounts.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

DRIVE="$HYPERWEBSTER_SRC/drive-automount"

if [ -d "$DRIVE" ] && [ -x "$DRIVE/install-drive-automount.sh" ]; then
  sudo sh "$DRIVE/install-drive-automount.sh"
fi

if [ -x /usr/local/bin/hyperwebster-drive-automount ]; then
  sudo /usr/local/bin/hyperwebster-drive-automount || true
fi

echo ":: drive automount lsblk JSON (labels with spaces -> /mnt/<label>)"
