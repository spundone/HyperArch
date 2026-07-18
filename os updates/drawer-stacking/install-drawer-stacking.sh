#!/bin/sh
# install-drawer-stacking.sh - raise dashboard/launcher above nspanels.
# Idempotent. Copies component files, patches shell drawers, installs Hyprland
# layerrule order, and registers a pacman hook to re-apply after shell upgrades.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SHARE="$HOME/.local/share/hyperwebster/drawer-stacking"
HYPRUSER="$HOME/.config/caelestia/hypr-user.conf"
MARK_BEGIN='# >>> hyperwebster-drawer-stack >>>'
MARK_END='# <<< hyperwebster-drawer-stack <<<'

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
hw_install_file "$SRC/ContentWindow.qml" "$SHARE/ContentWindow.qml" 0644
hw_install_file "$SRC/Panels.qml" "$SHARE/Panels.qml" 0644
hw_install_file "$SRC/patch-drawer-stacking.sh" "$SHARE/patch-drawer-stacking.sh" 0755
hw_install_file "$SRC/README.md" "$SHARE/README.md" 0644

if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  echo ":: skipping drawer-stacking patch (HYPERWEBSTER_SKIP_SHELL_PATCH)"
else
  sudo sh "$SHARE/patch-drawer-stacking.sh"
fi

# Hyprland layer order: remove old marker block if present, then insert.
mkdir -p "$(dirname -- "$HYPRUSER")"
touch "$HYPRUSER"
if grep -qF "$MARK_BEGIN" "$HYPRUSER" 2>/dev/null; then
  # portable delete of marked block (GNU/BSD sed)
  if sed --version >/dev/null 2>&1; then
    sed -i "/$MARK_BEGIN/,/$MARK_END/d" "$HYPRUSER"
  else
    sed -i '' "/$MARK_BEGIN/,/$MARK_END/d" "$HYPRUSER"
  fi
  echo ":: removed previous hyperwebster-drawer-stack block"
fi
{
  printf '\n%s\n' "$MARK_BEGIN"
  cat <<'RULES'
# Higher order = closer to screen edge within the same WlrLayer.
# Drawers promote to Overlay when dashboard/launcher open; keep above nspanels.
layerrule = order 10, match:namespace nsbar
layerrule = order 20, match:namespace nspanels
layerrule = order 40, match:namespace caelestia-drawers
RULES
  printf '%s\n' "$MARK_END"
} >> "$HYPRUSER"
echo ":: installed drawer stacking layerrules -> $HYPRUSER"

if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 && echo ":: reloaded Hyprland"
fi

HOOK=/etc/pacman.d/hooks/hyperwebster-drawer-stacking.hook
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
Description = Re-applying HyperWebster drawer stacking fix...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-drawer-stacking.sh
EOF
echo ":: pacman hook installed -> $HOOK"
echo "Done. Restart the shell (Ctrl+Super+Alt+R) to apply drawer stacking."
