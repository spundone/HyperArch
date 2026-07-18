#!/bin/sh
# install-caelestia-repair.sh - install hyperwebster-caelestia-repair. Idempotent.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
SHARE="${HOME}/.local/share/hyperwebster/caelestia-repair"

if [ -f "$HERE/../hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$HERE/../hyperwebster-update/lib/hw-install-file.sh"
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

install -d -m755 "$BIN" "$SHARE/defaults"
hw_install_file "$HERE/hyperwebster-caelestia-repair" "$BIN/hyperwebster-caelestia-repair" 0755
hw_install_file "$HERE/README.md" "$SHARE/README.md" 0644
hw_install_file "$HERE/defaults/shell.json" "$SHARE/defaults/shell.json" 0644
hw_install_file "$HERE/defaults/shell-tokens.json" "$SHARE/defaults/shell-tokens.json" 0644
hw_install_file "$HERE/defaults/scheme-shadotheme.json" "$SHARE/defaults/scheme-shadotheme.json" 0644

echo "caelestia-repair: run hyperwebster-caelestia-repair  (or --hard)"
