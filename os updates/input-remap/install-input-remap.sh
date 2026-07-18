#!/bin/sh
# install-input-remap.sh — keyd + gum TUI for keyboard/mouse remaps.
# Idempotent. Needs sudo for pacman + keyd service.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/hyperwebster/input-remap"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK_BEGIN='# >>> input-remap >>>'
MARK_END='# <<< input-remap <<<'

if [ -f "$SRC/../hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$SRC/../hyperwebster-update/lib/hw-install-file.sh"
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

mkdir -p "$BIN" "$SHARE/presets"
hw_install_file "$SRC/hyperwebster-input-remap" "$BIN/hyperwebster-input-remap" 0755
hw_install_file "$SRC/README.md" "$SHARE/README.md" 0644
hw_install_file "$SRC/hyprland-input-remap.conf" "$SHARE/hyprland-input-remap.conf" 0644
for f in "$SRC"/presets/*.conf; do
  [ -f "$f" ] || continue
  hw_install_file "$f" "$SHARE/presets/$(basename "$f")" 0644
done

# Official repos only (extra/keyd).
if ! command -v keyd >/dev/null 2>&1; then
  echo ":: installing keyd"
  sudo pacman -S --needed --noconfirm keyd
fi
command -v gum >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm gum

sudo install -d -m 0755 /etc/keyd
sudo systemctl enable --now keyd 2>/dev/null \
  && echo ":: keyd enabled" \
  || echo "NOTE: enable later with: sudo systemctl enable --now keyd"

# Hyprland bind
if [ -f "$HYPRUSER" ]; then
  if grep -qF "$MARK_BEGIN" "$HYPRUSER"; then
    echo ":: Super+Ctrl+I bind already present"
  else
    {
      printf '\n%s\n' "$MARK_BEGIN"
      cat "$SRC/hyprland-input-remap.conf"
      printf '%s\n' "$MARK_END"
    } >> "$HYPRUSER"
    echo ":: appended Super+Ctrl+I -> $HYPRUSER"
    if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
      hyprctl reload >/dev/null 2>&1 || true
    fi
  fi
else
  echo "NOTE: $HYPRUSER missing — bind from hyprland-input-remap.conf manually."
fi

echo "Done. Open with Super+Ctrl+I or: hyperwebster-input-remap"
