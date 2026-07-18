#!/usr/bin/env bash
# Migration: simplify Limine to desktop UKI + Starman (drop fallback clutter).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/limine-menu-simplify"
[ -f "$SRC/simplify-limine-menu.sh" ] || exit 0
sudo sh "$SRC/simplify-limine-menu.sh"
