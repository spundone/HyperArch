#!/usr/bin/env bash
# Migration: rename layerrule ignorealpha → ignore_alpha (Hyprland 0.53+/0.55+).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

HYPRUSER="${HOME}/.config/caelestia/hypr-user.conf"
LAYER="${XDG_DATA_HOME:-$HOME/.local/share}/hyperwebster"

# Refresh blur-toggle CLI (same-file safe).
SRC="$HYPERWEBSTER_SRC/blur-toggle/hyperwebster-blur-toggle"
BIN="${HOME}/.local/bin/hyperwebster-blur-toggle"
if [ -f "$SRC" ]; then
  src_r=$(readlink -f "$SRC" 2>/dev/null || echo "$SRC")
  dest_r=$(readlink -f "$BIN" 2>/dev/null || true)
  if [ -z "$dest_r" ] || [ "$src_r" != "$dest_r" ]; then
    install -m 0755 "$SRC" "$BIN"
  else
    chmod 0755 "$BIN" 2>/dev/null || true
  fi
fi

fix_ignorealpha() {
  local f=$1
  [ -f "$f" ] || return 0
  grep -qE 'ignorealpha' "$f" 2>/dev/null || return 0
  cp -a "$f" "$f.bak.ignore-alpha.$(date +%Y%m%d%H%M%S)"
  sed -i 's/ignorealpha/ignore_alpha/g' "$f"
  echo ":: renamed ignorealpha → ignore_alpha in $f"
}

fix_ignorealpha "$HYPRUSER"
fix_ignorealpha "$LAYER/tv-gaming-display/hypr-tv-gaming.conf"

# Re-apply blur rules if blur is enabled (upgrades the marked block wording).
if [ -x "$BIN" ] && "$BIN" status >/dev/null 2>&1; then
  "$BIN" enable || true
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo ":: Hyprland layerrule: ignore_alpha (was ignorealpha)"
