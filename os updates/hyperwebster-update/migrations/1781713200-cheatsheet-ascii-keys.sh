#!/usr/bin/env bash
# Migration: ASCII-safe key labels in Super+K cheatsheet (fix broken …/arrow glyphs).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/hyperwebster"
BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
mkdir -p "$DEST" "$BIN"
[ -f "$SRC/HyperWebster-keybindings.md" ] && cp -f "$SRC/HyperWebster-keybindings.md" "$DEST/"
[ -f "$SRC/hyperwebster-keybinds-gen" ] && install -m 755 "$SRC/hyperwebster-keybinds-gen" "$BIN/hyperwebster-keybinds-gen"
[ -f "$SRC/hyperwebster-keybinds" ] && install -m 755 "$SRC/hyperwebster-keybinds" "$BIN/hyperwebster-keybinds"
# also refresh copies living next to the layer tree (install-keybinds-help layout)
[ -f "$SRC/hyperwebster-keybinds-gen" ] && install -m 755 "$SRC/hyperwebster-keybinds-gen" "$DEST/hyperwebster-keybinds-gen"
[ -f "$SRC/hyperwebster-keybinds" ] && install -m 755 "$SRC/hyperwebster-keybinds" "$DEST/hyperwebster-keybinds"
rm -f "$DEST/keybinds.list"
"$BIN/hyperwebster-keybinds-gen" > "$DEST/keybinds.list" 2>/dev/null || true
