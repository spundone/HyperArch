#!/usr/bin/env bash
# Migration: richer HyperWebster/Starman SDDM greeter.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?}"

SRC="$HYPERWEBSTER_SRC/sddm-theme"
if [ -x "$SRC/install-sddm-theme.sh" ]; then
  sh "$SRC/install-sddm-theme.sh" || true
elif [ -x /usr/local/bin/sddm-theme-sync ]; then
  # Layer copy of Main.qml + sync (NOPASSWD on many installs).
  if [ -f "$SRC/caelestia/Main.qml" ]; then
    mkdir -p "$HOME/.local/share/hyperwebster/sddm-theme/caelestia"
    install -m 0644 "$SRC/caelestia/Main.qml" \
      "$HOME/.local/share/hyperwebster/sddm-theme/caelestia/Main.qml"
  fi
  sudo /usr/local/bin/sddm-theme-sync || true
fi

echo ":: SDDM Starman greeter polish"
