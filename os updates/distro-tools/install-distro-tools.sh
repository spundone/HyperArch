#!/bin/sh
# install-distro-tools.sh - maintenance menu + keybind.
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
LAYER="${HOME}/.local/share/hyperwebster/distro-tools"
HYPRUSER="${HOME}/.config/caelestia/hypr-user.conf"
MARK_BEGIN='# >>> distro-tools >>>'
MARK_END='# <<< distro-tools <<<'

mkdir -p "$BIN" "$LAYER"
hw_install_file "$HERE/hyperwebster-maint" "$BIN/hyperwebster-maint" 0755
hw_install_file "$HERE/README.md" "$LAYER/README.md" 0644

if [ -f "$HYPRUSER" ] && ! grep -qF "$MARK_BEGIN" "$HYPRUSER"; then
  cat >> "$HYPRUSER" <<EOF

$MARK_BEGIN
bind = Super+Ctrl+Shift, M, exec, hyperwebster-maint
$MARK_END
EOF
  echo ":: appended maintenance menu keybind -> $HYPRUSER"
fi

echo "distro-tools: Super+Ctrl+Shift+M or hyperwebster-maint"
