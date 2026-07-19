#!/usr/bin/env bash
# 1781890000-cachy-pacman-kernel-manager.sh
# Older HyperWebster pinned stock pacman (IgnorePkg) while CachyOS was enabled.
# That broke cachyos-kernel-manager (undefined symbol: alpm_pkg_get_installed_db).
# Reinstall the corrected helper + sudoers, then fix-pacman when repos are on.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo env HYPERWEBSTER_SKIP_SHELL_PATCH=1 sh "$HYPERWEBSTER_SRC/cachyos-repo-switch/install-cachyos-repo-switch.sh"
