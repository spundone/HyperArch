#!/bin/bash
# Gamepad lock PIN: WlSessionLock ignores uinput — feed PAM via qs IPC.
# Prefer ~/.config/quickshell/caelestia overlay (no root) over /etc patch.
set -euo pipefail

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/lockscreen-polish"
[ -f "$SRC/Lock.qml" ] || SRC="$(cd "$(dirname "$0")/../../lockscreen-polish" && pwd)"

CTRL="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/controller-desktop"
[ -f "$CTRL/hyperwebster-controller-desktop" ] || \
  CTRL="$(cd "$(dirname "$0")/../../controller-desktop" && pwd)"

SYS_CFG="/etc/xdg/quickshell/caelestia"
USER_CFG="$HOME/.config/quickshell/caelestia"

install_user_overlay() {
  [ -f "$SRC/Lock.qml" ] && [ -f "$SRC/Pam.qml" ] || return 1
  [ -d "$SYS_CFG" ] || return 1
  rm -rf "$USER_CFG"
  mkdir -p "$USER_CFG"
  for item in "$SYS_CFG"/*; do
    [ -e "$item" ] || continue
    ln -s "$item" "$USER_CFG/$(basename "$item")"
  done
  rm -f "$USER_CFG/modules"
  mkdir -p "$USER_CFG/modules"
  for item in "$SYS_CFG/modules"/*; do
    [ -e "$item" ] || continue
    ln -s "$item" "$USER_CFG/modules/$(basename "$item")"
  done
  rm -f "$USER_CFG/modules/lock"
  mkdir -p "$USER_CFG/modules/lock"
  for item in "$SYS_CFG/modules/lock"/*; do
    [ -e "$item" ] || continue
    ln -s "$item" "$USER_CFG/modules/lock/$(basename "$item")"
  done
  rm -f "$USER_CFG/modules/lock/Lock.qml" "$USER_CFG/modules/lock/Pam.qml"
  install -m 0644 "$SRC/Lock.qml" "$USER_CFG/modules/lock/Lock.qml"
  install -m 0644 "$SRC/Pam.qml" "$USER_CFG/modules/lock/Pam.qml"
  echo ":: user quickshell overlay with lock IPC ($USER_CFG)"
}

if ! install_user_overlay; then
  if [ -f "$SRC/patch-lock-ipc.sh" ] && sudo -n true 2>/dev/null; then
    sudo sh "$SRC/patch-lock-ipc.sh"
  fi
fi

mkdir -p "$HOME/.local/share/hyperwebster/lockscreen-polish"
[ -f "$SRC/Lock.qml" ] && install -m 0644 "$SRC/Lock.qml" "$HOME/.local/share/hyperwebster/lockscreen-polish/Lock.qml"
[ -f "$SRC/Pam.qml" ] && install -m 0644 "$SRC/Pam.qml" "$HOME/.local/share/hyperwebster/lockscreen-polish/Pam.qml"
[ -f "$SRC/patch-lock-ipc.sh" ] && install -m 0755 "$SRC/patch-lock-ipc.sh" "$HOME/.local/share/hyperwebster/lockscreen-polish/patch-lock-ipc.sh"

if [ -f "$CTRL/hyperwebster-controller-desktop" ]; then
  install -Dm0755 "$CTRL/hyperwebster-controller-desktop" \
    "$HOME/.local/bin/hyperwebster-controller-desktop"
  install -Dm0644 "$CTRL/profile.json" \
    "$HOME/.local/share/hyperwebster/controller-desktop/profile.json"
fi

qs -c caelestia kill 2>/dev/null || true
sleep 0.5
setsid qs -c caelestia -n -d >/dev/null 2>&1 || setsid caelestia shell -d >/dev/null 2>&1 || true
systemctl --user restart hyperwebster-controller-desktop.service 2>/dev/null || true
echo ":: lock gamepad PIN via qs lock feed/submit IPC"
