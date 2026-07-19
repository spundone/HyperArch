#!/usr/bin/env bash
# Migration: fix drive-automount empty-field parse (bash IFS tab collapse).
# Idempotent — reinstalls drive-automount and remounts.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"

DRIVE="$HYPERWEBSTER_SRC/drive-automount"

if [ -d "$DRIVE" ] && [ -x "$DRIVE/install-drive-automount.sh" ]; then
  sudo sh "$DRIVE/install-drive-automount.sh"
fi

if [ -x /usr/local/bin/hyperwebster-drive-automount ]; then
  sudo /usr/local/bin/hyperwebster-drive-automount || true
fi

echo ":: drive-automount USV/IFS empty-field fix"
