#!/bin/sh
# Migration: keyd + gum TUI for keyboard/mouse remaps (Additions + Super+Ctrl+I).
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/input-remap"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../input-remap" && pwd)"

sh "$SRC/install-input-remap.sh"

# Refresh Additions manifest so the new row appears without a full re-patch skip.
if [ -x "${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/additions-installer/install-additions-installer.sh" ]; then
  env HYPERWEBSTER_SKIP_SHELL_PATCH=1 \
    sh "${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/additions-installer/install-additions-installer.sh" || true
fi
