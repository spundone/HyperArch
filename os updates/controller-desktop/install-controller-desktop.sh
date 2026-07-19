#!/bin/sh
# install-controller-desktop.sh — gamepad → Hyprland desktop actions.
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
    mkdir -p "$(dirname -- "$_d")"
    install -m "$_m" "$_s" "$_d"
  }
fi

BIN="${HOME}/.local/bin"
LAYER="${HOME}/.local/share/hyperwebster/controller-desktop"

mkdir -p "$LAYER" "$BIN"
hw_install_file "$HERE/hyperwebster-controller-desktop" "$BIN/hyperwebster-controller-desktop" 0755
hw_install_file "$HERE/hyperwebster-controller-desktop-toggle" "$BIN/hyperwebster-controller-desktop-toggle" 0755
hw_install_file "$HERE/profile.json" "$LAYER/profile.json" 0644
hw_install_file "$HERE/hyperwebster-controller-desktop.service" "$LAYER/hyperwebster-controller-desktop.service" 0644
hw_install_file "$HERE/README.md" "$LAYER/README.md" 0644

# Enable by default — TV / couch desktop UX.
"$BIN/hyperwebster-controller-desktop-toggle" enable

echo "controller-desktop: Guide opens launcher; Guide+Start enters Starman gaming"
echo "  Tip: GameSir Cyclone must be in X-Input / Xbox mode for Linux to see buttons."
