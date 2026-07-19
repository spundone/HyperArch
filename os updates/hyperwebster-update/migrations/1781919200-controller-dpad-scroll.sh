#!/bin/bash
# D-pad U/D → mouse-wheel scroll + Up/Down arrow keys on Hyprland desktop.
set -euo pipefail

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/controller-desktop"
[ -f "$SRC/hyperwebster-controller-desktop" ] || \
  SRC="$(cd "$(dirname "$0")/../../controller-desktop" && pwd)"

[ -f "$SRC/hyperwebster-controller-desktop" ] || exit 0

install -Dm0755 "$SRC/hyperwebster-controller-desktop" \
  "$HOME/.local/bin/hyperwebster-controller-desktop"
install -Dm0755 "$SRC/hyperwebster-controller-desktop" \
  "$HOME/.local/share/hyperwebster/controller-desktop/hyperwebster-controller-desktop"

PROF="$HOME/.local/share/hyperwebster/controller-desktop/profile.json"
if [ -f "$SRC/profile.json" ]; then
  python3 - <<PY
import json
from pathlib import Path
src = json.loads(Path("$SRC/profile.json").read_text())
p = Path("$PROF")
data = json.loads(p.read_text()) if p.is_file() else {}
binds = dict(data.get("bindings") or {})
binds["ABS_HAT0Y:-1"] = "scroll_up"
binds["ABS_HAT0Y:1"] = "scroll_down"
data["bindings"] = binds
if "lock_bindings" not in data and "lock_bindings" in src:
    data["lock_bindings"] = src["lock_bindings"]
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(data, indent=2) + "\n")
print(":: d-pad U/D → scroll_up / scroll_down")
PY
fi

systemctl --user restart hyperwebster-controller-desktop.service 2>/dev/null || true
