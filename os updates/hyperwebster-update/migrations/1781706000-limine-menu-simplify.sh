#!/usr/bin/env bash
# Migration: simplify Limine to desktop UKI + Starman (drop fallback clutter).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/limine-menu-simplify"
[ -f "$SRC/simplify-limine-menu.sh" ] || exit 0
# bash: script uses bashisms; never invoke via plain sh.
sudo bash "$SRC/simplify-limine-menu.sh"
