#!/usr/bin/env bash
# Migration: System tools / Super+Ctrl+I — absolute path for input-remap.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"

SRC="$HYPERWEBSTER_SRC/input-remap"
TOOLS="$HYPERWEBSTER_SRC/system-tools"

if [ -f "$SRC/install-input-remap.sh" ]; then
  sh "$SRC/install-input-remap.sh" || true
fi

if [ -f "$TOOLS/install-system-tools.sh" ]; then
  sh "$TOOLS/install-system-tools.sh" || true
elif [ -f "$TOOLS/patch-system-tools-page.sh" ]; then
  sudo sh "$TOOLS/patch-system-tools-page.sh" || true
fi

echo ":: input-remap + System tools PATH fix"
