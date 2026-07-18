#!/usr/bin/env bash
# Migration: fix Settings opener (caelestia nexus -> hyperwebster-settings).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/omarchy-launcher"
[ -d "$SRC" ] || exit 0
sh "$SRC/install-omarchy-launcher.sh"
