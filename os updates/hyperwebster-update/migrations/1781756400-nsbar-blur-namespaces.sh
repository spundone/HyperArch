#!/usr/bin/env bash
# Migration: blur the NoSignal top bar (nsbar), not legacy caelestia-.* namespaces.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/blur-toggle"
[ -d "$SRC" ] || exit 0

sh "$SRC/install-blur-toggle.sh"

# Re-apply frosted glass with corrected namespaces if blur was/should be on.
STATE="${HOME}/.local/state/hyperwebster/blur-enabled"
if [ ! -f "$STATE" ] || [ "$(cat "$STATE" 2>/dev/null || true)" = "1" ]; then
  hyperwebster-blur-toggle enable || true
else
  # Still upgrade rules file if present, but leave disabled.
  true
fi

echo ":: bar blur: nsbar/nspanels layerrules — Ctrl+Super+Alt+R if the bar is still flat"
