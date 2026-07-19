#!/bin/sh
# install-sddm-theme.sh — SDDM greeter lock-screen twin (frosted wallpaper,
# Material palette from caelestia, Google Sans Flex, synced face/logo).
# Idempotent. Needs sudo.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
THEME=/usr/share/sddm/themes/caelestia

# 1. Theme files.
sudo install -d -m 0755 "$THEME" "$THEME/backgrounds" "$THEME/assets"
sudo install -m 0644 "$SRC/caelestia/Main.qml"         "$THEME/Main.qml"
sudo install -m 0644 "$SRC/caelestia/metadata.desktop" "$THEME/metadata.desktop"
# Default theme.conf only if none exists yet (sync overwrites it anyway).
[ -f "$THEME/theme.conf" ] || sudo install -m 0644 "$SRC/caelestia/theme.conf" "$THEME/theme.conf"

# Seed Starman logo into theme assets when present in the layer / shell.
for logo in \
  /etc/xdg/quickshell/caelestia/assets/hyperwebster-logo.png \
  "$SRC/../shell-branding/hyperwebster-logo.png" \
  "$HOME/.local/share/hyperwebster/shell-branding/hyperwebster-logo.png"
do
  if [ -f "$logo" ]; then
    sudo install -m 0644 "$logo" "$THEME/assets/hyperwebster-logo.png"
    break
  fi
done
echo ":: installed SDDM theme to $THEME"

# 1b. Greeter gamepad helper — Guide+A / Start → F12 while greeter is up.
sudo install -m 0755 "$SRC/hyperwebster-greeter-pad" /usr/local/bin/hyperwebster-greeter-pad
sudo install -m 0644 "$SRC/hyperwebster-greeter-pad.service" \
  /etc/systemd/system/hyperwebster-greeter-pad.service
sudo systemctl daemon-reload
sudo systemctl enable --now hyperwebster-greeter-pad.service 2>/dev/null \
  || sudo systemctl restart hyperwebster-greeter-pad.service || true
echo ":: greeter pad helper (lock-twin PIN + Guide+A Starman)"

# 2. Sync script + initial sync from the current scheme/wallpaper (best
#    effort: if there is no scheme yet — e.g. at image build time — the
#    shipped foam-sea defaults in theme.conf apply, but the background still
#    needs to be provided; see README builder notes).
sudo install -m 0755 "$SRC/sddm-theme-sync" /usr/local/bin/sddm-theme-sync
if sudo /usr/local/bin/sddm-theme-sync; then
  :
else
  echo "NOTE: initial sync failed (no caelestia scheme yet?) — shipped defaults kept."
  if [ ! -e "$THEME/backgrounds/wallpaper.png" ] && [ -f "$HOME/Pictures/Wallpapers/hyperwebster/foam-sea.png" ]; then
    sudo install -m 0644 "$HOME/Pictures/Wallpapers/hyperwebster/foam-sea.png" "$THEME/backgrounds/wallpaper.png"
    echo ":: seeded foam-sea.png as the greeter background"
  fi
fi

# 3. Point SDDM at the theme (drop-in, doesn't touch 10-hyperwebster.conf).
if [ ! -f /etc/sddm.conf.d/20-sddm-theme.conf ]; then
  sudo tee /etc/sddm.conf.d/20-sddm-theme.conf > /dev/null << 'EOF'
# Greeter theme matching the desktop scheme (sddm-theme component).
# Remove this file to fall back to SDDM's default greeter.
[Theme]
Current=caelestia
EOF
  echo ":: set SDDM theme to 'caelestia'"
fi

echo "Done. Preview without logging out:"
echo "  sddm-greeter-qt6 --test-mode --theme $THEME"
echo "Re-sync after a wallpaper change:  sudo sddm-theme-sync"
