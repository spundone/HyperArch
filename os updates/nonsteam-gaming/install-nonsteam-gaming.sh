#!/bin/sh
# install-nonsteam-gaming.sh — install CLI helpers into ~/.local/bin (user).
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
SHARE="${HOME}/.local/share/hyperwebster/nonsteam-gaming"

mkdir -p "$BIN" "$SHARE"
for s in \
  hyperwebster-install-heroic \
  hyperwebster-install-steam-rom-manager \
  hyperwebster-install-decky \
  hyperwebster-install-millennium
do
  install -m 0755 "$HERE/$s" "$BIN/$s"
  install -m 0755 "$HERE/$s" "$SHARE/$s"
done
install -m 0644 "$HERE/README.md" "$SHARE/README.md"
echo "nonsteam-gaming: helpers → $BIN"
