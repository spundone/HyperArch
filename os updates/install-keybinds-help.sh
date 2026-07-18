#!/bin/sh
# install-keybinds-help.sh — install the HyperWebster on-screen keybinding cheatsheet.
#
# This component lives entirely in this folder (Downloads) so it survives a
# system wipe. Run this after rebuilding to put the pieces back in place:
#   - hyperwebster-keybinds-gen, hyperwebster-keybinds  -> ~/.local/bin/
#   - HyperWebster-keybindings.md (source of truth) -> ~/.local/share/hyperwebster/
#   - Super+/ and Super+F1 binds -> ~/.config/caelestia/hypr-user.conf
#
# Safe to re-run (idempotent). Deps: awk, fuzzel, optional wl-copy.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/hyperwebster"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"

# Live layer: SRC is often already SHARE — never cp/install a file onto itself.
if [ -f "$SRC/hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$SRC/hyperwebster-update/lib/hw-install-file.sh"
elif [ -f "$SHARE/hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$SHARE/hyperwebster-update/lib/hw-install-file.sh"
else
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
fi

mkdir -p "$BIN" "$SHARE"

hw_install_file "$SRC/hyperwebster-keybinds-gen" "$BIN/hyperwebster-keybinds-gen" 0755
hw_install_file "$SRC/hyperwebster-keybinds" "$BIN/hyperwebster-keybinds" 0755
echo "installed scripts -> $BIN"

# Canonical copy of the single source of truth, so the help works even if the
# Downloads doc is later moved/removed.
if [ -f "$SRC/HyperWebster-keybindings.md" ]; then
  hw_install_file "$SRC/HyperWebster-keybindings.md" "$SHARE/HyperWebster-keybindings.md" 0644
  echo "installed keymap doc -> $SHARE/HyperWebster-keybindings.md"
fi

# Add alias binds (Super+/ + Super+F1). omarchy-keys may already own Super+K —
# check each alias independently so install order never drops documented keys.
if [ -f "$HYPRUSER" ]; then
  appended=0
  if ! grep -qE 'Super, Slash, exec.*hyperwebster-keybinds' "$HYPRUSER"; then
    printf '\nbind = Super, Slash, exec, ~/.local/bin/hyperwebster-keybinds\n' >> "$HYPRUSER"
    appended=1
  fi
  if ! grep -qE 'Super, F1, exec.*hyperwebster-keybinds' "$HYPRUSER"; then
    printf 'bind = Super, F1, exec, ~/.local/bin/hyperwebster-keybinds\n' >> "$HYPRUSER"
    appended=1
  fi
  if [ "$appended" -eq 1 ]; then
    echo "appended missing cheatsheet alias binds -> $HYPRUSER"
  else
    echo "cheatsheet alias binds already present in $HYPRUSER"
  fi
else
  echo "NOTE: $HYPRUSER not found — add the lines from hyprland-keybinds-help.conf to your Hyprland user config."
fi

# PATH sanity.
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "NOTE: $BIN is not on PATH — add it (e.g. in ~/.bash_profile)." ;;
esac

# Apply immediately if Hyprland is running.
if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo "reloaded Hyprland"
fi

echo "Done. Press Super+/ to open the cheatsheet."
