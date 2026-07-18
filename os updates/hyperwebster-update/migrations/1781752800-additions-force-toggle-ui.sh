#!/usr/bin/env bash
# Migration: force-refresh AdditionsPage so toggles are switches (no install popups).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/additions-installer"
[ -d "$SRC" ] || exit 0

# Always re-copy CLI + QML into the live shell (skip same-file where needed).
sh "$SRC/install-additions-installer.sh"

# install-additions-installer may skip the shell patch under SKIP; force it.
sudo sh "$HOME/.local/share/hyperwebster/additions-installer/patch-additions-page.sh" \
  2>/dev/null || sudo sh "$SRC/patch-additions-page.sh"

"$HOME/.local/bin/hyperwebster-additions" status >/dev/null 2>&1 || true
echo ":: Additions: toggles use switches — restart shell (Ctrl+Super+Alt+R) if chevrons remain"
