#!/usr/bin/env bash
# Migration: drop obsolete misc:vfr (removed in Hyprland 0.55 — VFR is default).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

LAYER="${XDG_DATA_HOME:-$HOME/.local/share}/hyperwebster"
HYPRUSER="${HOME}/.config/caelestia/hypr-user.conf"

strip_vfr() {
  local f=$1
  [ -f "$f" ] || return 0
  grep -qE '^\s*vfr\s*=' "$f" 2>/dev/null || return 0

  local tmp
  tmp=$(mktemp)
  python3 - "$f" "$tmp" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src).read()
# Drop vfr assignments (any indent).
text = re.sub(r'(?m)^[ \t]*vfr[ \t]*=[^\n]*\n?', '', text)
# Drop now-empty misc { } blocks.
text = re.sub(r'(?m)^[ \t]*misc[ \t]*\{[ \t]*\n[ \t]*\}[ \t]*\n?', '', text)
open(dst, 'w').write(text)
PY

  if ! cmp -s "$f" "$tmp"; then
    cp -a "$f" "$f.bak.vfr-strip.$(date +%Y%m%d%H%M%S)"
    mv "$tmp" "$f"
    echo ":: stripped obsolete misc:vfr from $f"
  else
    rm -f "$tmp"
  fi
}

# Refresh layer fragments from source when present (skip same-file).
for pair in \
  "hypersmooth-display/hypr-hypersmooth.conf" \
  "tv-gaming-display/hypr-tv-gaming.conf"
do
  src="$HYPERWEBSTER_SRC/$pair"
  dest="$LAYER/$pair"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname -- "$dest")"
    src_r=$(readlink -f "$src" 2>/dev/null || echo "$src")
    dest_r=$(readlink -f "$dest" 2>/dev/null || true)
    if [ -z "$dest_r" ] || [ "$src_r" != "$dest_r" ]; then
      install -m 0644 "$src" "$dest"
    fi
  fi
  strip_vfr "$dest"
done

strip_vfr "$HYPRUSER"

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo ":: Hyprland 0.55+: misc:vfr removed (VFR is default)"
