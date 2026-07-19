#!/bin/sh
# install-notif-blur-fix.sh — idempotent. REQUIRES ROOT (writes package-owned
# shell files under /etc/xdg).
#
# Raises notification/toast card fill alpha to Colours.layer(..., 0) so the fill
# sits above Hyprland ignore_alpha and frosted blur applies like dashboard panels.
#
# Canonical fix lives in the hyperwebster-shell fork. This fallback patches
# already-installed boxes; next shell package upgrade may revert until the fork
# ships the fix. Builder sets HYPERWEBSTER_SKIP_SHELL_PATCH to skip here.
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
NOTIF_TARGET=/etc/xdg/quickshell/caelestia/modules/notifications/Notification.qml
TOAST_TARGET=/etc/xdg/quickshell/caelestia/modules/utilities/toasts/ToastItem.qml

if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  echo ":: skipping notif-blur-fix shell patch (HYPERWEBSTER_SKIP_SHELL_PATCH)"
  exit 0
fi

[ "$(id -u)" -eq 0 ] || { echo "must run as root (writes /etc/xdg/quickshell/caelestia/...)" >&2; exit 1; }

hw_install_sudo() {
  # same-file safe install into package path
  _s=$1
  _d=$2
  [ -f "$_s" ] || return 0
  if [ ! -f "$_d" ]; then
    echo "WARNING: $_d not present — hyperwebster-shell not installed here; skip." >&2
    return 0
  fi
  _sr=$(readlink -f "$_s" 2>/dev/null || realpath "$_s" 2>/dev/null || echo "$_s")
  _dr=$(readlink -f "$_d" 2>/dev/null || realpath "$_d" 2>/dev/null || echo "$_d")
  if [ "$_sr" = "$_dr" ]; then
    chmod 0644 "$_d" 2>/dev/null || true
    echo ":: $_d already same file — nothing to copy"
    return 0
  fi
  if cmp -s "$_s" "$_d"; then
    echo ":: $_d already up to date — nothing to do"
    return 0
  fi
  [ -f "$_d.prefix.bak" ] || cp -a "$_d" "$_d.prefix.bak"
  install -m 0644 "$_s" "$_d"
  echo ":: patched $_d (backup: $_d.prefix.bak)"
}

hw_install_sudo "$SELF_DIR/Notification.qml" "$NOTIF_TARGET"
hw_install_sudo "$SELF_DIR/ToastItem.qml" "$TOAST_TARGET"

echo ":: notif blur: card fills use Colours.layer(..., 0) (above ignore_alpha)"
echo ":: restart the shell to apply: Ctrl+Super+Alt+R, or log out/in."
