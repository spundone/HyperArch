#!/bin/sh
# Migration: frosted lock screen (wallpaper blur + ambient motion + Starman).
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/lockscreen-polish"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../lockscreen-polish" && pwd)"

sh "$SRC/install-lockscreen-polish.sh"
