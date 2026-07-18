#!/usr/bin/env bash
# Migration: ASCII-safe key labels in Super+K cheatsheet (fix broken …/arrow glyphs).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/hyperwebster"
BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
mkdir -p "$DEST" "$BIN"

# HYPERWEBSTER_SRC is often already ~/.local/share/hyperwebster — never cp/install a file onto itself.
install_if_different() {
  local src=$1 dest=$2 mode=$3
  [ -f "$src" ] || return 0
  local src_r dest_r
  src_r=$(readlink -f "$src")
  dest_r=$(readlink -f "$dest" 2>/dev/null || true)
  if [ -n "$dest_r" ] && [ "$src_r" = "$dest_r" ]; then
    chmod "$mode" "$dest" 2>/dev/null || true
    return 0
  fi
  install -m "$mode" "$src" "$dest"
}

install_if_different "$SRC/HyperWebster-keybindings.md" "$DEST/HyperWebster-keybindings.md" 644
install_if_different "$SRC/hyperwebster-keybinds-gen" "$BIN/hyperwebster-keybinds-gen" 755
install_if_different "$SRC/hyperwebster-keybinds" "$BIN/hyperwebster-keybinds" 755
install_if_different "$SRC/hyperwebster-keybinds-gen" "$DEST/hyperwebster-keybinds-gen" 755
install_if_different "$SRC/hyperwebster-keybinds" "$DEST/hyperwebster-keybinds" 755

rm -f "$DEST/keybinds.list"
if [ -x "$BIN/hyperwebster-keybinds-gen" ]; then
  "$BIN/hyperwebster-keybinds-gen" > "$DEST/keybinds.list" 2>/dev/null || true
elif [ -x "$DEST/hyperwebster-keybinds-gen" ]; then
  "$DEST/hyperwebster-keybinds-gen" > "$DEST/keybinds.list" 2>/dev/null || true
fi
