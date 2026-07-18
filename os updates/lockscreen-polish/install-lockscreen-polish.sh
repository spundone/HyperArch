#!/bin/sh
# install-lockscreen-polish.sh — cooler Caelestia lock (blur + motion + Starman).
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHARE="$HOME/.local/share/hyperwebster/lockscreen-polish"

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
hw_install_file "$SRC/LockSurface.qml" "$SHARE/LockSurface.qml" 0644
hw_install_file "$SRC/patch-locksurface.sh" "$SHARE/patch-locksurface.sh" 0755
hw_install_file "$SRC/README.md" "$SHARE/README.md" 0644

# Ensure Starman logo exists for the lock avatar.
if [ -f "$SRC/../shell-branding/hyperwebster-logo.png" ]; then
  sudo install -d -m 0755 /etc/xdg/quickshell/caelestia/assets
  sudo install -m 0644 "$SRC/../shell-branding/hyperwebster-logo.png" \
    /etc/xdg/quickshell/caelestia/assets/hyperwebster-logo.png || true
fi

if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  echo ":: skipping lock surface patch (HYPERWEBSTER_SKIP_SHELL_PATCH)"
else
  sudo sh "$SHARE/patch-locksurface.sh"
fi

HOOK=/etc/pacman.d/hooks/hyperwebster-lockscreen-polish.hook
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
Description = Re-applying HyperWebster frosted lock screen...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-locksurface.sh
EOF
echo ":: pacman hook -> $HOOK"
echo "Done. Lock with Super+Ctrl+L (or idle) — Ctrl+Super+Alt+R if the shell was already running."
