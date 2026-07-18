#!/usr/bin/env bash
# Migration: Starman/gamescope must beat leftover zz-steamos-autologin (Hyprland).
# After Switch-to-Desktop, that drop-in sorted after zz-gaming-session.conf and
# Starman cold boots landed in passwordless Hyprland instead of gamescope.
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"

STARMAN="$HYPERWEBSTER_SRC/starman-gaming-boot"
DECK="$HYPERWEBSTER_SRC/deckshift-login"
CHIMERA="$HYPERWEBSTER_SRC/chimera-deckify-gaming"

if [ -d "$STARMAN" ] && [ -x "$STARMAN/install-starman-gaming-boot.sh" ]; then
  sudo sh "$STARMAN/install-starman-gaming-boot.sh" || true
fi

if [ -f "$DECK/sddm-autologin-gate" ]; then
  sudo install -Dm0755 "$DECK/sddm-autologin-gate" /usr/local/bin/sddm-autologin-gate
fi

# Prefer chimera copy when present (same content as deckshift-login).
SWITCH_SRC=""
if [ -f "$CHIMERA/gaming-session-switch" ]; then
  SWITCH_SRC="$CHIMERA/gaming-session-switch"
elif [ -f "$DECK/gaming-session-switch" ]; then
  SWITCH_SRC="$DECK/gaming-session-switch"
fi
if [ -n "$SWITCH_SRC" ]; then
  sudo install -Dm0755 "$SWITCH_SRC" /usr/local/bin/gaming-session-switch
fi

# Clear sticky Hyprland autologin so the next Starman boot is not overridden.
# Safe on desktop: cold boot gate also removes this; live session is unaffected.
if [ -f /etc/sddm.conf.d/zz-steamos-autologin.conf ]; then
  sudo rm -f /etc/sddm.conf.d/zz-steamos-autologin.conf
  echo ":: removed sticky /etc/sddm.conf.d/zz-steamos-autologin.conf"
fi

echo ":: Starman vs zz-steamos-autologin clash fixed"
