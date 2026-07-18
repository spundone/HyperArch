#!/bin/sh
# install-btrfs-snapshot-manager.sh - snapper timeline + btrfs-assistant helpers.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -f "$HERE/../hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$HERE/../hyperwebster-update/lib/hw-install-file.sh"
elif [ -f "${HYPERWEBSTER_SRC:-}/hyperwebster-update/lib/hw-install-file.sh" ]; then
  # shellcheck source=/dev/null
  . "$HYPERWEBSTER_SRC/hyperwebster-update/lib/hw-install-file.sh"
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

BIN="${HOME}/.local/bin"
LAYER="${HOME}/.local/share/hyperwebster/btrfs-snapshot-manager"
HYPRUSER="${HOME}/.config/caelestia/hypr-user.conf"
MARK_BEGIN='# >>> btrfs-snapshot-manager >>>'
MARK_END='# <<< btrfs-snapshot-manager <<<'

install_user() {
  mkdir -p "$BIN" "$LAYER"
  hw_install_file "$HERE/hyperwebster-snapshots" "$BIN/hyperwebster-snapshots" 0755
  hw_install_file "$HERE/README.md" "$LAYER/README.md" 0644

  if [ -f "$HYPRUSER" ] && ! grep -qF "$MARK_BEGIN" "$HYPRUSER"; then
    cat >> "$HYPRUSER" <<EOF

$MARK_BEGIN
bind = Super+Ctrl+Shift, B, exec, hyperwebster-snapshots
$MARK_END
EOF
    echo ":: appended snapshot keybind -> $HYPRUSER"
  fi
}

install_root() {
  if command -v snapper >/dev/null 2>&1 && snapper --no-dbus list-configs 2>/dev/null | grep -q root; then
    snapper --no-dbus -c root set-config \
      TIMELINE_CREATE=yes \
      TIMELINE_CLEANUP=yes \
      TIMELINE_LIMIT_HOURLY=10 \
      TIMELINE_LIMIT_DAILY=7 \
      TIMELINE_LIMIT_WEEKLY=0 \
      TIMELINE_LIMIT_MONTHLY=0 \
      TIMELINE_LIMIT_YEARLY=0 \
      2>/dev/null || true
  fi
  if [ -d /.snapshots ]; then
    chmod 750 /.snapshots 2>/dev/null || true
  fi
  systemctl enable --now snapper-timeline.timer snapper-cleanup.timer 2>/dev/null \
    && echo ":: snapper timeline + cleanup timers enabled" \
    || echo "NOTE: snapper timers not enabled (snapper missing?)"
}

if [ "$(id -u)" -eq 0 ]; then
  install_root
else
  install_user
fi

echo "btrfs-snapshot-manager: run btrfs-assistant or hyperwebster-snapshots"
