#!/usr/bin/env bash
# Migration: Settings → Appearance font family pickers.
# Theme.fontFamily stays JetBrainsMono Nerd Font (nsbar glyphs); UI fonts only
# write GlobalConfig for Tokens / GTK / kitty.
set +e
: "${HYPERWEBSTER_SRC:?}"

APP="$HYPERWEBSTER_SRC/appearance-page"
TOG="$HYPERWEBSTER_SRC/appearance-toggles"

if [ -d "$TOG" ] && [ -x "$TOG/install-appearance-toggles.sh" ]; then
  sh "$TOG/install-appearance-toggles.sh" || true
fi

if [ -d "$APP" ] && [ -x "$APP/install-appearance-page.sh" ]; then
  sh "$APP/install-appearance-page.sh" || true
fi

# Always force JetBrainsMono on Theme chrome after Appearance install.
if [ -f "$APP/patch-theme-font.sh" ]; then
  sudo sh "$APP/patch-theme-font.sh" || true
fi

echo ":: Appearance fonts - Typography pickers + JetBrainsMono Theme chrome"
echo ":: Ctrl+Super+Alt+R to apply; install a chosen font package if it is missing"
exit 0
