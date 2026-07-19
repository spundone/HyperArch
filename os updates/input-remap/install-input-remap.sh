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

# Hyprland bind — always rewrite the marked block so PATH fixes apply.
if [ -f "$HYPRUSER" ]; then
  if grep -qF "$MARK_BEGIN" "$HYPRUSER"; then
    # Replace existing block in place.
    tmp=$(mktemp)
    awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
      $0 == begin { skip=1; print; system("cat \"'"$SRC"'/hyprland-input-remap.conf\""); next }
      $0 == end { skip=0; print; next }
      !skip { print }
    ' "$HYPRUSER" > "$tmp" && mv "$tmp" "$HYPRUSER"
    echo ":: refreshed Super+Ctrl+I bind in $HYPRUSER"
  else
    {
      printf '\n%s\n' "$MARK_BEGIN"
      cat "$SRC/hyprland-input-remap.conf"
      printf '%s\n' "$MARK_END"
    } >> "$HYPRUSER"
    echo ":: appended Super+Ctrl+I -> $HYPRUSER"
  fi
  if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
else
  echo "NOTE: $HYPRUSER missing — bind from hyprland-input-remap.conf manually."
fi

# Ensure TUI.float floats (System tools / Super+Ctrl+I).
# Do NOT use `focus` / `stayfocused` — invalid in Hyprland 0.55+ match: grammar.
if [ -f "$HYPRUSER" ] && ! grep -qE 'match:class TUI\\?\.float' "$HYPRUSER"; then
  {
    printf '\n# HyperWebster floating TUI terminals\n'
    printf 'windowrule = float true, match:class TUI\\.float\n'
    printf 'windowrule = size 1100 700, match:class TUI\\.float\n'
    printf 'windowrule = center true, match:class TUI\\.float\n'
  } >> "$HYPRUSER"
  echo ":: added TUI.float window rules"
fi

echo "Done. Open with Super+Ctrl+I or: Settings → System tools → Keyboard & mouse"
