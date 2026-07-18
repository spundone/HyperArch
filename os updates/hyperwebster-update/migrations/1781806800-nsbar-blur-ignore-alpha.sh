#!/usr/bin/env bash
# Migration: fix nsbar frost — ignore_alpha below Theme.barBg (~0.60).
# Theme.barBg stays fixed glass alpha (never Colours.transparency).
set +e
: "${HYPERWEBSTER_SRC:?}"
SRC="$HYPERWEBSTER_SRC/blur-toggle"
[ -d "$SRC" ] || exit 0

sh "$SRC/install-blur-toggle.sh" || true

STATE="${HOME}/.local/state/hyperwebster/blur-enabled"
if [ ! -f "$STATE" ] || [ "$(cat "$STATE" 2>/dev/null || true)" = "1" ]; then
  hyperwebster-blur-toggle enable || true
fi

echo ":: nsbar blur: ignore_alpha capped + fixed Theme.barBg 0.60 (no Colours bind)"
echo ":: Ctrl+Super+Alt+R if the top bar is still flat"
exit 0
