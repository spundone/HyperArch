#!/bin/sh
# Migration: Omarchy themes + wallpaper generator + Colours page actions.
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/omarchy-themes"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../omarchy-themes" && pwd)"

sh "$SRC/install-omarchy-themes.sh"

# Refresh omarchy launcher menu (Style entry).
if [ -x "${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/omarchy-launcher/install-omarchy-launcher.sh" ]; then
  sh "${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/omarchy-launcher/install-omarchy-launcher.sh" || true
fi
