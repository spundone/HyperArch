#!/usr/bin/env bash
# Migration: harden caelestia dark repair (smartScheme + full dark seed).
# Soft #32 repair could leave light palettes / race wallpaper smart mode.
set +e
: "${HYPERWEBSTER_SRC:?}"

SRC="$HYPERWEBSTER_SRC/caelestia-repair"
[ -d "$SRC" ] || exit 0

if [ -f "$SRC/install-caelestia-repair.sh" ]; then
  sh "$SRC/install-caelestia-repair.sh"
fi

# Soft repair during update. Skip final restart so the updater hint stays clear.
if [ -x "$HOME/.local/bin/hyperwebster-caelestia-repair" ]; then
  "$HOME/.local/bin/hyperwebster-caelestia-repair" --no-restart
elif [ -f "$SRC/hyperwebster-caelestia-repair" ]; then
  sh "$SRC/hyperwebster-caelestia-repair" --no-restart
fi

echo ":: caelestia dark-stick repair applied - Ctrl+Super+Alt+R"
exit 0
