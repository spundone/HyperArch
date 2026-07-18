#!/usr/bin/env bash
# Migration: install + run caelestia config repair (dark/glass/fonts/blur).
set +e
: "${HYPERWEBSTER_SRC:?}"

SRC="$HYPERWEBSTER_SRC/caelestia-repair"
[ -d "$SRC" ] || exit 0

if [ -f "$SRC/install-caelestia-repair.sh" ]; then
  sh "$SRC/install-caelestia-repair.sh"
fi

# Soft repair during update (no interactive prompts). Skip shell restart so the
# updater's own Ctrl+Super+Alt+R hint stays authoritative.
if [ -x "$HOME/.local/bin/hyperwebster-caelestia-repair" ]; then
  "$HOME/.local/bin/hyperwebster-caelestia-repair" --no-restart
elif [ -f "$SRC/hyperwebster-caelestia-repair" ]; then
  sh "$SRC/hyperwebster-caelestia-repair" --no-restart
fi

echo ":: caelestia config repair applied - Ctrl+Super+Alt+R"
exit 0
