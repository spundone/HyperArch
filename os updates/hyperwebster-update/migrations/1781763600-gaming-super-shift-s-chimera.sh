#!/usr/bin/env bash
# 1781763600-gaming-super-shift-s-chimera.sh
# Super+Shift+S silently no-op'd after Deckify/Chimera because the Hyprland
# guard only accepted DeckShift's gamescope-session-steam-nm.desktop. Also
# fix omarchy-pkg-add double -S ("only one operation may be used at a time")
# so a re-run of hyperwebster-deckify-install can finish.
set -euo pipefail

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}"

# 1. Refresh pkg-add shim (strips accidental -S).
if [ -x "$SRC/gaming-enablement/install-gaming-enablement.sh" ]; then
  sh "$SRC/gaming-enablement/install-gaming-enablement.sh" || true
fi

# 2. Widen Super+Shift+S in hypr-user.conf (+ reload).
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"

if [ -f "$HYPRUSER" ]; then
  if grep -qE 'bind = Super\+Shift, S, exec,.*switch-to-gaming' "$HYPRUSER"; then
    tmp=$(mktemp)
    while IFS= read -r line; do
      case "$line" in
        'bind = Super+Shift, S, exec,'*switch-to-gaming*)
          cat <<'BINDLINE'
bind = Super+Shift, S, exec, sh -c '[ -x /usr/local/bin/switch-to-gaming ] && { [ -f /usr/share/wayland-sessions/gamescope-session-steam-nm.desktop ] || [ -f /usr/share/wayland-sessions/gamescope-session-steam.desktop ] || [ -f /usr/share/wayland-sessions/gamescope-session-steam-plus.desktop ]; } && exec /usr/local/bin/switch-to-gaming'
BINDLINE
          ;;
        *)
          printf '%s\n' "$line"
          ;;
      esac
    done < "$HYPRUSER" > "$tmp"
    cat "$tmp" > "$HYPRUSER"
    rm -f "$tmp"
    echo ":: Super+Shift+S now accepts Chimera/Deckify session desktops"
  fi
  if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
fi

# 3. If gamescope session exists but switch helpers are missing (install aborted
#    on double -S), finish helper install without re-pulling AUR packages.
if { [ -f /usr/share/wayland-sessions/gamescope-session-steam.desktop ] \
  || [ -f /usr/share/wayland-sessions/gamescope-session-steam-nm.desktop ] \
  || [ -f /usr/share/wayland-sessions/gamescope-session-steam-plus.desktop ]; } \
  && [ ! -x /usr/local/bin/switch-to-gaming ]; then
  echo ":: gamescope session present but switch-to-gaming missing — installing helpers"
  LAYER="$SRC"
  sudo install -Dm0755 "$LAYER/chimera-deckify-gaming/switch-to-gaming" /usr/local/bin/switch-to-gaming
  sudo install -Dm0755 "$LAYER/chimera-deckify-gaming/switch-to-desktop" /usr/local/bin/switch-to-desktop
  sudo install -Dm0755 "$LAYER/chimera-deckify-gaming/gaming-session-switch" /usr/local/bin/gaming-session-switch
  sudo install -Dm0755 "$LAYER/chimera-deckify-gaming/os-session-select" /usr/lib/os-session-select
  sudo install -Dm0755 "$LAYER/chimera-deckify-gaming/hyperwebster-gaming-session" /usr/local/bin/hyperwebster-gaming-session
  if [ -x "$LAYER/deckshift-login/install-deckshift-login.sh" ]; then
    sh "$LAYER/deckshift-login/install-deckshift-login.sh" || true
  fi
fi

# 4. Refresh switch-to-gaming (notify on failure) even when already present.
if [ -f "$SRC/chimera-deckify-gaming/switch-to-gaming" ] && [ -x /usr/local/bin/switch-to-gaming ]; then
  sudo install -Dm0755 "$SRC/chimera-deckify-gaming/switch-to-gaming" /usr/local/bin/switch-to-gaming || true
fi

# 5. Re-patch Game Mode drawer if that component is installed.
if [ -x "$SRC/gamemode-toggle-deckshift/install-gamemode-toggle-deckshift.sh" ]; then
  sh "$SRC/gamemode-toggle-deckshift/install-gamemode-toggle-deckshift.sh" || true
fi

echo ":: If Deckify AUR packages never finished, re-run: hyperwebster-deckify-install"
echo "   Then Super+Shift+S should enter Steam Big Picture."
