#!/bin/sh
# patch-theme-nsbar-blur.sh - Theme.barBg stays translucent for frost.
# IMPORTANT: do NOT bind Colours.transparency here. That circular init can
# leave Theme.size undefined (NsOverlay barHeight TypeError) and zero-byte
# Theme corruption risk during bad restores.
# Frost on/off is Hyprland layerrules + shell.json transparency.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/services/Theme.qml}
[ -f "$TARGET" ] || { echo "Theme.qml not found at $TARGET - skipping"; exit 0; }

if ! grep -q 'readonly property color barBg:' "$TARGET" 2>/dev/null; then
  echo "WARNING: Theme.qml has no barBg - nothing to patch" >&2
  exit 0
fi

if grep -q 'HyperWebster: barBg fixed glass alpha' "$TARGET" 2>/dev/null \
   && grep -q 'Qt.rgba(15 / 255, 18 / 255, 24 / 255, 0.60)' "$TARGET" 2>/dev/null \
   && ! grep -q 'Colours.transparency' "$TARGET" 2>/dev/null; then
  echo ":: Theme.qml barBg already safe fixed glass alpha"
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-hyperwebster-barbg" 2>/dev/null || true

# Never overwrite a non-empty Theme with an empty backup later.
if [ ! -s "$TARGET" ]; then
  echo "ERROR: Theme.qml is empty (0 bytes) - refusing to patch; restore stock Theme first" >&2
  exit 0
fi

python3 - "$TARGET" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
if not text.strip():
    print("ERROR: Theme.qml empty - abort", file=sys.stderr)
    sys.exit(0)
if "QtObject size" not in text and "property QtObject size" not in text:
    print("ERROR: Theme.qml missing size block - abort (refusing to patch corrupt Theme)", file=sys.stderr)
    sys.exit(0)

pat = re.compile(
    r"(?:    // HyperWebster: barBg[^\n]*\n)+"
    r"    readonly property color barBg: Qt\.rgba\(15 / 255, 18 / 255, 24 / 255, [^\n]+\)"
    r"|"
    r"    readonly property color barBg: Qt\.rgba\(15 / 255, 18 / 255, 24 / 255, [^\n]+\)",
)
new = (
    "    // HyperWebster: barBg fixed glass alpha (do not bind Colours.transparency).\n"
    "    // Frost on/off is Hyprland ignore_alpha + shell.json transparency.\n"
    "    readonly property color barBg: Qt.rgba(15 / 255, 18 / 255, 24 / 255, 0.60)"
)
if not pat.search(text):
    print("WARNING: Theme.qml barBg shape changed - patch skipped", file=sys.stderr)
    sys.exit(0)
path.write_text(pat.sub(new, text, count=1))
print(f":: patched {path} (barBg fixed 0.60 glass, no Colours.transparency)")
PY
