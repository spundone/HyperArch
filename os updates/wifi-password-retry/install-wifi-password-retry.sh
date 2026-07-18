#!/bin/sh
# install-wifi-password-retry.sh — let users recover from a wrong Wi-Fi
# password.
#
#   - patch-network-connection.sh -> ~/.local/share/hyperwebster/wifi-password-retry/
#     (stable on-system copy; the pacman hook points here)
#   - NetworkConnection.qml        -> patched in caelestia-shell (sudo)
#   - pacman hook                  -> re-applies the patch after shell upgrades
#
# Safe to re-run (idempotent). Needs sudo for the QML patch + hook.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHARE="$HOME/.local/share/hyperwebster/wifi-password-retry"

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

# 1. Stable on-system copy of the patch (the pacman hook points here).
mkdir -p "$SHARE"
hw_install_file "$SRC/patch-network-connection.sh" "$SHARE/patch-network-connection.sh" 0755

# 2. Apply the QML patch now.
sudo sh "$SHARE/patch-network-connection.sh"

# 3. Pacman hook: caelestia-shell upgrades revert NetworkConnection.qml — re-patch.
HOOK=/etc/pacman.d/hooks/hyperwebster-wifi-password-retry.hook
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
Description = Re-applying HyperWebster Wi-Fi wrong-password recovery patch...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-network-connection.sh
EOF
echo ":: pacman hook installed -> $HOOK"

echo "Done. Restart the shell (Ctrl+Super+Alt+R) to pick up the patch."
