#!/usr/bin/env bash
# Migration: fix Theme.size undefined (NsOverlay barHeight crash) caused by
# Theme.barBg binding Colours.transparency.
set +e
: "${HYPERWEBSTER_SRC:?}"

BLUR="$HYPERWEBSTER_SRC/blur-toggle"
TARGET=/etc/xdg/quickshell/caelestia/services/Theme.qml

# Prefer restoring a pre-patch backup, then re-apply the safe barBg + size patches.
if [ -f "$TARGET.pre-hyperwebster-barbg" ]; then
  sudo cp -a "$TARGET.pre-hyperwebster-barbg" "$TARGET"
  echo ":: restored Theme.qml from pre-hyperwebster-barbg backup"
elif [ -f "$TARGET.pre-hyperwebster-barsize" ]; then
  sudo cp -a "$TARGET.pre-hyperwebster-barsize" "$TARGET"
  echo ":: restored Theme.qml from pre-hyperwebster-barsize backup"
fi

# Strip any Colours.transparency binding from barBg even without backup.
if [ -f "$TARGET" ] && grep -q 'Colours.transparency' "$TARGET" 2>/dev/null; then
  sudo python3 - "$TARGET" <<'PY'
from pathlib import Path
import re, sys
path = Path(sys.argv[1])
text = path.read_text()
pat = re.compile(
    r"(?:    // HyperWebster: barBg[^\n]*\n)*"
    r"    readonly property color barBg: Qt\.rgba\(15 / 255, 18 / 255, 24 / 255, [^\n]+\)"
)
new = (
    "    // HyperWebster: barBg fixed glass alpha (do not bind Colours.transparency -\n"
    "    // that circular init leaves Theme.size undefined and breaks NsBar).\n"
    "    readonly property color barBg: Qt.rgba(15 / 255, 18 / 255, 24 / 255, 0.60)"
)
if pat.search(text):
    path.write_text(pat.sub(new, text, count=1))
    print(":: stripped Colours.transparency from Theme.barBg")
else:
    print("WARNING: could not rewrite Theme.barBg", file=sys.stderr)
PY
fi

if [ -f "$BLUR/patch-theme-nsbar-blur.sh" ]; then
  sudo sh "$BLUR/patch-theme-nsbar-blur.sh"
fi
if [ -f "$BLUR/patch-theme-nsbar-size.sh" ]; then
  # Size patch is optional; only apply if size QtObject is intact.
  if grep -q 'readonly property QtObject size:' "$TARGET" 2>/dev/null; then
    sudo sh "$BLUR/patch-theme-nsbar-size.sh"
  fi
fi

echo ":: Theme.size fix applied - Ctrl+Super+Alt+R (or qs -c caelestia kill; caelestia shell -d)"
exit 0
