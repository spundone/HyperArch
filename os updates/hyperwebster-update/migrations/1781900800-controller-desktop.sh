#!/usr/bin/env bash
# 1781900800-controller-desktop.sh — gamepad → Hyprland desktop actions.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/controller-desktop/install-controller-desktop.sh"
# Refresh switch-to-gaming so it stops the mapper before Starman.
if [ -f "$HYPERWEBSTER_SRC/chimera-deckify-gaming/switch-to-gaming" ]; then
  if [ -w /usr/local/bin/switch-to-gaming ] || sudo -n true 2>/dev/null; then
    sudo install -m 0755 "$HYPERWEBSTER_SRC/chimera-deckify-gaming/switch-to-gaming" \
      /usr/local/bin/switch-to-gaming 2>/dev/null \
      || install -m 0755 "$HYPERWEBSTER_SRC/chimera-deckify-gaming/switch-to-gaming" \
           "$HOME/.local/bin/switch-to-gaming" 2>/dev/null || true
  fi
fi
