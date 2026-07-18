#!/bin/sh
# install-tv-gaming-display.sh - ship 4K HDR TV hyprmoncfg profile + HDR hints.
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

HYPRUSER="${HOME}/.config/caelestia/hypr-user.conf"
PROFILE_DIR="${HOME}/.config/hyprmoncfg/profiles"
BIN="${HOME}/.local/bin"
LAYER="${HOME}/.local/share/hyperwebster/tv-gaming-display"
MARK='tv-gaming-display: TV HDR/VRR profile'

mkdir -p "$PROFILE_DIR" "$LAYER" "$BIN"
hw_install_file "$HERE/profiles/tv-gaming-4k" "$PROFILE_DIR/tv-gaming-4k" 0644
hw_install_file "$HERE/hypr-tv-gaming.conf" "$LAYER/hypr-tv-gaming.conf" 0644
hw_install_file "$HERE/hyperwebster-tv-gaming-toggle" "$BIN/hyperwebster-tv-gaming-toggle" 0755
hw_install_file "$HERE/README.md" "$LAYER/README.md" 0644

if [ -f "$HYPRUSER" ] && ! grep -qF "$MARK" "$HYPRUSER"; then
  cat >> "$HYPRUSER" <<EOF

# >>> tv-gaming-display: TV HDR/VRR profile >>>
# hyprmoncfg apply tv-gaming-4k - edit HDMI output in the profile first.
source = $LAYER/hypr-tv-gaming.conf
# <<< tv-gaming-display: TV HDR/VRR profile <<<
EOF
  echo ":: appended TV gaming hypr fragment to $HYPRUSER"
fi

echo "tv-gaming-display: profile installed - run: hyprmoncfg apply tv-gaming-4k"
