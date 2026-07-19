#!/bin/sh
# install-button-scroll.sh — middle-button hold-to-scroll for broken wheels.
# Enables by default (toggle off via Additions or hyperwebster-button-scroll-toggle).
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
LAYER="${HOME}/.local/share/hyperwebster/button-scroll"

mkdir -p "$LAYER" "$BIN"
hw_install_file "$HERE/hypr-button-scroll.conf" "$LAYER/hypr-button-scroll.conf" 0644
hw_install_file "$HERE/hyperwebster-button-scroll-toggle" "$BIN/hyperwebster-button-scroll-toggle" 0755
hw_install_file "$HERE/README.md" "$LAYER/README.md" 0644

# Default on — broken scroll wheels are why this exists.
"$BIN/hyperwebster-button-scroll-toggle" enable

echo "button-scroll: hold middle mouse button and move to scroll"
