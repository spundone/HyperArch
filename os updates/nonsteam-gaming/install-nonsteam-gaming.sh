#!/bin/sh
# install-nonsteam-gaming.sh — install CLI helpers into ~/.local/bin (user).
# Safe when run from ~/.local/share/hyperwebster/nonsteam-gaming (layer copy).
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
SHARE="${HOME}/.local/share/hyperwebster/nonsteam-gaming"

# Never GNU-install a file onto itself (layer already lives under SHARE).
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

mkdir -p "$BIN" "$SHARE"
for s in \
  hyperwebster-install-heroic \
  hyperwebster-install-steam-rom-manager \
  hyperwebster-install-decky \
  hyperwebster-install-millennium \
  install-nonsteam-gaming.sh
do
  [ -f "$HERE/$s" ] || continue
  hw_install_file "$HERE/$s" "$BIN/$s" 0755
  hw_install_file "$HERE/$s" "$SHARE/$s" 0755
done
hw_install_file "$HERE/README.md" "$SHARE/README.md" 0644

# Prefer ~/.local/bin on PATH for Additions follow-up commands.
case ":${PATH}:" in
  *":${BIN}:"*) ;;
  *) export PATH="${BIN}:${PATH}" ;;
esac

echo "nonsteam-gaming: helpers → $BIN"
