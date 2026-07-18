#!/bin/sh
# install-omarchy-launcher.sh — Omarchy Super+Alt+Space install menu for HyperWebster.
# Idempotent.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
LAYER="$HOME/.local/share/hyperwebster/omarchy-launcher"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK_BEGIN='# >>> hyperwebster-omarchy-launcher >>>'
MARK_END='# <<< hyperwebster-omarchy-launcher <<<'

mkdir -p "$BIN" "$LAYER"

# Layer checkout often IS ~/.local/share/hyperwebster — never install a file onto itself.
install_if_different() {
  src=$1 dest=$2 mode=$3
  [ -f "$src" ] || return 0
  src_r=$(readlink -f "$src")
  dest_r=$(readlink -f "$dest" 2>/dev/null || true)
  if [ -n "$dest_r" ] && [ "$src_r" = "$dest_r" ]; then
    chmod "$mode" "$dest" 2>/dev/null || true
    return 0
  fi
  install -m "$mode" "$src" "$dest"
}

for script in hyperwebster-omarchy-menu hyperwebster-pkg-install \
              hyperwebster-pkg-aur-install hyperwebster-pkg-remove \
              hyperwebster-settings; do
  install_if_different "$SRC/$script" "$BIN/$script" 0755
done
install_if_different "$SRC/README.md" "$LAYER/README.md" 0644
install_if_different "$SRC/omarchy-launcher-keys.conf" "$LAYER/omarchy-launcher-keys.conf" 0644
echo ":: installed omarchy-launcher scripts -> $BIN"

# Keep F10 / Settings bind pointing at the working opener (not bare `caelestia nexus`).
if [ -f "$HYPRUSER" ]; then
  sed -i 's|^bind = , F10, exec, caelestia nexus$|bind = , F10, exec, hyperwebster-settings|' "$HYPRUSER" 2>/dev/null || true
  sed -i 's|^bind = , F10, exec, caelestia shell nexus open$|bind = , F10, exec, hyperwebster-settings|' "$HYPRUSER" 2>/dev/null || true
fi

if [ ! -f "$HYPRUSER" ]; then
  echo "NOTE: $HYPRUSER not found — append omarchy-launcher-keys.conf manually."
elif grep -qF "$MARK_BEGIN" "$HYPRUSER" 2>/dev/null \
     || grep -q 'hyperwebster-omarchy-menu' "$HYPRUSER" 2>/dev/null; then
  # Refresh bind if an older image still pointed Super+Alt+Space at nexus.
  if grep -q 'Super+Alt, Space, global, caelestia:nexus' "$HYPRUSER" 2>/dev/null; then
    sed -i 's|^bind = Super+Alt, Space, global, caelestia:nexus|# moved to F10 — see hyperwebster-omarchy-launcher|' "$HYPRUSER"
    if ! grep -q 'hyperwebster-omarchy-menu' "$HYPRUSER" 2>/dev/null; then
      {
        printf '\n%s\n' "$MARK_BEGIN"
        cat "$SRC/omarchy-launcher-keys.conf"
        printf '%s\n' "$MARK_END"
      } >> "$HYPRUSER"
      echo ":: upgraded Super+Alt+Space bind -> $HYPRUSER"
    fi
  else
    echo ":: keybinds already present in $HYPRUSER"
  fi
else
  {
    printf '\n%s\n' "$MARK_BEGIN"
    cat "$SRC/omarchy-launcher-keys.conf"
    printf '%s\n' "$MARK_END"
  } >> "$HYPRUSER"
  # Drop the pre-launcher nexus bind when upgrading from an older hypr-user.conf.
  sed -i 's|^bind = Super+Alt, Space, global, caelestia:nexus|# moved to F10 — see hyperwebster-omarchy-launcher|' "$HYPRUSER" 2>/dev/null || true
  echo ":: appended omarchy-launcher keybinds -> $HYPRUSER"
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

echo "Done. Super+Alt+Space install menu · F10 Settings · hyperwebster-omarchy-menu"
