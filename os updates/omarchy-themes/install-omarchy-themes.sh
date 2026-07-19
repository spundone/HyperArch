#!/bin/sh
# install-omarchy-themes.sh — Omarchy theme packs + wallpaper generator for HyperWebster.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/hyperwebster/omarchy-themes"
USER_SCHEMES="$HOME/.local/share/caelestia/schemes"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK_BEGIN='# >>> omarchy-themes >>>'
MARK_END='# <<< omarchy-themes <<<'

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

mkdir -p "$BIN" "$SHARE/lib" "$SHARE/schemes" "$SHARE/omarchy-colors" "$USER_SCHEMES"
hw_install_file "$SRC/hyperwebster-theme" "$BIN/hyperwebster-theme" 0755
hw_install_file "$SRC/patch-caelestia-scheme-overlay.sh" "$SHARE/patch-caelestia-scheme-overlay.sh" 0755
hw_install_file "$SRC/lib/omarchy-to-caelestia.py" "$SHARE/lib/omarchy-to-caelestia.py" 0755
hw_install_file "$SRC/README.md" "$SHARE/README.md" 0644
hw_install_file "$SRC/hyprland-omarchy-themes.conf" "$SHARE/hyprland-omarchy-themes.conf" 0644

# Sync bundled schemes + source tomls into the layer share and user schemes.
if [ -d "$SRC/schemes" ]; then
  cp -a "$SRC/schemes/." "$SHARE/schemes/"
  cp -a "$SRC/schemes/." "$USER_SCHEMES/"
fi
if [ -d "$SRC/omarchy-colors" ]; then
  cp -a "$SRC/omarchy-colors/." "$SHARE/omarchy-colors/"
fi

# Patch caelestia-cli so scheme list/set see ~/.local/share/caelestia/schemes
if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  echo ":: skipping caelestia overlay patch (HYPERWEBSTER_SKIP_SHELL_PATCH)"
else
  sudo sh "$SHARE/patch-caelestia-scheme-overlay.sh" \
    || sudo sh "$SRC/patch-caelestia-scheme-overlay.sh" || true
fi

HOOK=/etc/pacman.d/hooks/hyperwebster-scheme-overlay.hook
sudo mkdir -p /etc/pacman.d/hooks
sudo tee "$HOOK" > /dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = caelestia-cli
Target = caelestia

[Action]
Description = Re-applying HyperWebster caelestia user-scheme overlay...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-caelestia-scheme-overlay.sh
EOF
echo ":: pacman hook -> $HOOK"

# Keybinds: theme TUI + Omarchy-like theme picker chord
if [ -f "$HYPRUSER" ] && ! grep -qF "$MARK_BEGIN" "$HYPRUSER"; then
  {
    printf '\n%s\n' "$MARK_BEGIN"
    cat "$SRC/hyprland-omarchy-themes.conf"
    printf '%s\n' "$MARK_END"
  } >> "$HYPRUSER"
  echo ":: appended theme keybinds -> $HYPRUSER"
  if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
else
  echo ":: theme keybinds already present or no hypr-user.conf"
fi

# Re-patch Colours page if present
if [ -x "$HOME/.local/share/hyperwebster/colours-page/patch-colours-page.sh" ]; then
  sudo sh "$HOME/.local/share/hyperwebster/colours-page/patch-colours-page.sh" || true
elif [ -x "$SRC/../colours-page/patch-colours-page.sh" ]; then
  sudo sh "$SRC/../colours-page/patch-colours-page.sh" || true
fi

echo "Done. Themes: hyperwebster-theme · Super+Ctrl+Shift+Space · Settings → Colours"
echo "Wallpapers: hyperwebster-theme sync-wallpapers → Settings → Wallpaper & style"

# Best-effort: link any pack backgrounds already present; full Omarchy pack
# download is opt-in (network + ~80MB) via sync-wallpapers / Additions.
if [ -x "$BIN/hyperwebster-theme" ]; then
  "$BIN/hyperwebster-theme" sync-wallpapers 2>/dev/null \
    || echo ":: skip wallpaper sync (offline or git missing) — run: hyperwebster-theme sync-wallpapers"
fi
