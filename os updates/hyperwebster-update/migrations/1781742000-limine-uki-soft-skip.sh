#!/usr/bin/env bash
# Migration: soft-fail Limine UKI repair (missing conf/UKI must not abort updates).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/limine-uki-dead-entry"
[ -f "$SRC/fix-limine-uki-entry.sh" ] || exit 0
sudo sh "$SRC/fix-limine-uki-entry.sh"
