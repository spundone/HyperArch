#!/usr/bin/env bash
# Migration: same-file-safe wifi-password-retry (+ other LAYER installers).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/wifi-password-retry"
[ -d "$SRC" ] || exit 0
sh "$SRC/install-wifi-password-retry.sh"
