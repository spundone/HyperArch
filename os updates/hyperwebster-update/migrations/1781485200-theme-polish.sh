#!/bin/sh
# HyperWebster layer migration — theme polish (SDDM sync + sudoers).
# User half installs systemd user units; root half installs sudoers drop-in.
set -eu
SRC="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
[ -d "$SRC/theme-polish" ] || exit 0
sh "$SRC/theme-polish/install-theme-polish.sh"
sudo env HYPERWEBSTER_USER_HOME="$HOME" sh "$SRC/theme-polish/install-theme-polish.sh"
