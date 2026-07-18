#!/usr/bin/env bash
# Migration: keep top dashboard above nspanels / launcher / other overlays.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/drawer-stacking"
[ -f "$SRC/install-drawer-stacking.sh" ] || exit 0
bash "$SRC/install-drawer-stacking.sh"
echo ":: drawer stacking — Ctrl+Super+Alt+R to reload the shell"
