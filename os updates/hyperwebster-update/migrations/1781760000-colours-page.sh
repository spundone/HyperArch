#!/bin/sh
# Migration: replace Wallpaper & style → Colours under-construction stub.
set -eu

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/colours-page"
[ -d "$SRC" ] || SRC="$(CDPATH= cd -- "$(dirname -- "$0")/../../colours-page" && pwd)"

sh "$SRC/install-colours-page.sh"
