#!/usr/bin/env bash
# Migration: replace About-page NoSignal artwork with Starman hyperwebster-logo.png.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sudo sh "$HYPERWEBSTER_SRC/shell-branding/install-shell-branding.sh"
echo ":: About logo: restart the shell (Ctrl+Super+Alt+R) to refresh Settings → About"
