#!/bin/sh
# patch-colours-nsbar-blur.sh — point Colours.reloadHyprRules at nsbar/nspanels.
# Upstream still keywords caelestia-drawers (old vertical bar). Idempotent.
set -eu

TARGET=${TARGET:-/etc/xdg/quickshell/caelestia/services/Colours.qml}
[ -f "$TARGET" ] || { echo "Colours.qml not found at $TARGET — skipping"; exit 0; }

if grep -q 'match:namespace nsbar' "$TARGET" 2>/dev/null; then
  echo ":: Colours.qml already targets nsbar blur"
  exit 0
fi

if ! grep -q 'caelestia-drawers' "$TARGET" 2>/dev/null; then
  echo "WARNING: Colours.qml has no caelestia-drawers layerrule — nothing to patch" >&2
  exit 0
fi

cp -n "$TARGET" "$TARGET.pre-hyperwebster-nsbar-blur" 2>/dev/null || true

python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
old = '''    function reloadHyprRules(): void {
        const str = "keyword layerrule %1 %2, match:namespace caelestia-drawers";
        Hypr.extras.batchMessage([str.arg("blur").arg(transparency.enabled ? 1 : 0), str.arg("ignore_alpha").arg(transparency.base - 0.03)]);
    }'''
new = '''    function reloadHyprRules(): void {
        // HyperWebster: NoSignal NsBar uses nsbar / nspanels (not only caelestia-drawers).
        const on = transparency.enabled ? "on" : "off";
        const alpha = Math.max(0, Math.min(1, transparency.base - 0.03));
        const nss = ["nsbar", "nspanels", "caelestia-drawers"];
        const msgs = [];
        for (let i = 0; i < nss.length; i++) {
            const ns = nss[i];
            msgs.push(`keyword layerrule blur ${on}, match:namespace ${ns}`);
            msgs.push(`keyword layerrule ignore_alpha ${alpha}, match:namespace ${ns}`);
        }
        Hypr.extras.batchMessage(msgs);
    }'''
if old not in text:
    print("WARNING: Colours.qml reloadHyprRules shape changed — patch skipped", file=sys.stderr)
    sys.exit(0)
path.write_text(text.replace(old, new, 1))
print(f":: patched {path} (nsbar/nspanels blur)")
PY
