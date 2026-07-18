#!/bin/sh
# install-updates-panel.sh — fill in the settings app's "Updates" page.
#
#   - hyperwebster-update-check        -> ~/.local/bin (JSON status cache writer)
#   - systemd user timer         -> checks every 6h (+5min after boot)
#   - UpdatesPage.qml            -> patched into caelestia-shell (sudo)
#   - pacman hook                -> re-applies the patch after shell upgrades
#
# Safe to re-run (idempotent). Needs sudo for the QML patch + hook + pacman-contrib.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/hyperwebster/updates-panel"
UNITS="$HOME/.config/systemd/user"

# Live layer: SRC is often already SHARE — never install a file onto itself.
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

# 1. Status checker + user timer.
mkdir -p "$BIN" "$UNITS" "$SHARE"
hw_install_file "$SRC/hyperwebster-update-check" "$BIN/hyperwebster-update-check" 0755
hw_install_file "$SRC/hyperwebster-update-check.service" "$UNITS/hyperwebster-update-check.service" 0644
hw_install_file "$SRC/hyperwebster-update-check.timer" "$UNITS/hyperwebster-update-check.timer" 0644
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user daemon-reload
  systemctl --user enable --now hyperwebster-update-check.timer 2>/dev/null \
    && echo ":: hyperwebster-update-check.timer enabled (every 6h)" \
    || echo "NOTE: enable later with: systemctl --user enable --now hyperwebster-update-check.timer"
else
  echo "NOTE: no user systemd session — enable the timer after login."
fi

# 2. checkupdates lives in pacman-contrib.
command -v checkupdates >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm pacman-contrib

# 3. Stable on-system copy of the patch (the pacman hook points here).
hw_install_file "$SRC/UpdatesPage.qml" "$SHARE/UpdatesPage.qml" 0644
hw_install_file "$SRC/patch-updates-page.sh" "$SHARE/patch-updates-page.sh" 0755

# 4. Apply the QML patch now.
sudo sh "$SHARE/patch-updates-page.sh"

# 5. Pacman hook: caelestia-shell upgrades revert PageCompRegistry.qml — re-patch.
HOOK=/etc/pacman.d/hooks/hyperwebster-updates-panel.hook
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
Description = Re-applying HyperWebster Updates settings page...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-updates-page.sh
EOF
echo ":: pacman hook installed -> $HOOK"

# 6. Seed the cache so the page has data on first open.
"$BIN/hyperwebster-update-check" >/dev/null 2>&1 || true

echo "Done. Restart the shell (Ctrl+Super+Alt+R) to see Settings -> Updates."
