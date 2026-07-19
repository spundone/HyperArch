#!/usr/bin/env bash
# Migration: frost notification/toast cards (layer-0 fill above ignore_alpha).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/notif-blur-fix"
[ -f "$SRC/install-notif-blur-fix.sh" ] || exit 0
sudo sh "$SRC/install-notif-blur-fix.sh" || true
echo ":: notif blur fix — Ctrl+Super+Alt+R to reload the shell"
