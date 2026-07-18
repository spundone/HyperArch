#!/bin/sh
# install-colours-page.sh — Settings → Wallpaper & style → Colours.
#
# Replaces the upstream "Page under construction" stub with scheme / flavour /
# Material variant pickers, transparency sliders, and SDDM colour sync.
#
# Safe to re-run (idempotent). Needs sudo for the QML overlay + pacman hook.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHARE="$HOME/.local/share/hyperwebster/colours-page"

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

mkdir -p "$SHARE"
hw_install_file "$SRC/ColourSelect.qml" "$SHARE/ColourSelect.qml" 0644
hw_install_file "$SRC/patch-colours-page.sh" "$SHARE/patch-colours-page.sh" 0755
hw_install_file "$SRC/README.md" "$SHARE/README.md" 0644

if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  echo ":: skipping Colours QML patch (HYPERWEBSTER_SKIP_SHELL_PATCH)"
else
  sudo sh "$SHARE/patch-colours-page.sh"
fi

HOOK=/etc/pacman.d/hooks/hyperwebster-colours-page.hook
sudo mkdir -p /etc/pacman.d/hooks
sudo tee "$HOOK" > /dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyperwebster-shell
Target = caelestia-shell
Target = nosignal-shell

[Action]
Description = Re-applying HyperWebster Colours settings page...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-colours-page.sh
EOF
echo ":: pacman hook installed -> $HOOK"

echo "Done. Restart the shell (Ctrl+Super+Alt+R) to see Settings → Wallpaper & style → Colours."
