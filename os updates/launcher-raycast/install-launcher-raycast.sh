#!/bin/sh
# install-launcher-raycast.sh — Raycast-like caelestia launcher defaults.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -f "$HERE/../hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$HERE/../hyperwebster-update/lib/hw-install-file.sh"
elif [ -f "${HYPERWEBSTER_SRC:-}/hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$HYPERWEBSTER_SRC/hyperwebster-update/lib/hw-install-file.sh"
else
  hw_install_file() {
    _s=$1; _d=$2; _m=${3:-0644}
    [ -f "$_s" ] || return 0
    _sr=$(readlink -f "$_s" 2>/dev/null || echo "$_s")
    _dr=
    [ -e "$_d" ] && _dr=$(readlink -f "$_d" 2>/dev/null || echo "$_d")
    if [ -n "$_dr" ] && [ "$_sr" = "$_dr" ]; then
      chmod "$_m" "$_d" 2>/dev/null || true
      return 0
    fi
    mkdir -p "$(dirname -- "$_d")"
    install -m "$_m" "$_s" "$_d"
  }
fi

BIN="${HOME}/.local/bin"
DEST="${HOME}/.local/share/hyperwebster/launcher-raycast"

install -d -m755 "$BIN" "$DEST"
hw_install_file "$HERE/hyperwebster-launcher-raycast" "$BIN/hyperwebster-launcher-raycast" 0755
hw_install_file "$HERE/launcher-shell.fragment.json" "$DEST/launcher-shell.fragment.json" 0644
hw_install_file "$HERE/README.md" "$DEST/README.md" 0644

"$BIN/hyperwebster-launcher-raycast" || echo "NOTE: merge skipped (jq or shell.json missing)"

echo "launcher-raycast: Super+Space opens fuzzy keyboard-first launcher"
