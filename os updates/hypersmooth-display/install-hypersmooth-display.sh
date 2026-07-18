#!/bin/sh
# install-hypersmooth-display.sh - high-refresh Hyprland + shell token tuning.
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
SHELLTOKENS="${HOME}/.config/caelestia/shell-tokens.json"
BIN="${HOME}/.local/bin"
LAYER="${HOME}/.local/share/hyperwebster/hypersmooth-display"
MARK_BEGIN='# >>> hypersmooth-display >>>'
MARK_END='# <<< hypersmooth-display <<<'

mkdir -p "$LAYER" "$BIN"
hw_install_file "$HERE/hypr-hypersmooth.conf" "$LAYER/hypr-hypersmooth.conf" 0644
hw_install_file "$HERE/shell-tokens.fragment.json" "$LAYER/shell-tokens.fragment.json" 0644
hw_install_file "$HERE/hyperwebster-hypersmooth-toggle" "$BIN/hyperwebster-hypersmooth-toggle" 0755
hw_install_file "$HERE/README.md" "$LAYER/README.md" 0644

if [ -f "$HYPRUSER" ] && ! grep -qF "$MARK_BEGIN" "$HYPRUSER"; then
  cat >> "$HYPRUSER" <<EOF

$MARK_BEGIN
source = $LAYER/hypr-hypersmooth.conf
$MARK_END
EOF
  echo ":: appended hypersmooth hypr fragment -> $HYPRUSER"
fi

if command -v jq >/dev/null 2>&1 && [ -f "$SHELLTOKENS" ] && [ -f "$LAYER/shell-tokens.fragment.json" ]; then
  tmp=$(mktemp)
  jq -s '.[0] * .[1]' "$SHELLTOKENS" "$LAYER/shell-tokens.fragment.json" > "$tmp" && mv "$tmp" "$SHELLTOKENS"
  echo ":: merged hypersmooth animDurations into $SHELLTOKENS"
fi

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo "hypersmooth-display: tuned for 120/144 Hz (vfr + snappier shell animations)"
