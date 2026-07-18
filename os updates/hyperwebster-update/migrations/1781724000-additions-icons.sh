#!/usr/bin/env bash
# Migration: fix Additions page icons (Loader broke NsIcon bindings → "?").
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/additions-installer"
[ -d "$SRC" ] || exit 0

sh "$SRC/install-additions-installer.sh"

"$HOME/.local/bin/hyperwebster-additions" status >/dev/null 2>&1 || true
echo ":: Additions icons: restart the shell (Ctrl+Super+Alt+R) to refresh"
