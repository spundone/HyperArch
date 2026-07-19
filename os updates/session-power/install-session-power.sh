#!/usr/bin/env bash
# Idempotent: install helper + patch caelestia session.commands.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
SHELL_JSON="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/shell.json"

install -d -m 755 "$BIN"
install -m 755 "$HERE/hyperwebster-session-power" "$BIN/hyperwebster-session-power"

python3 - "$SHELL_JSON" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
cmds = {
    "logout": ["hyperwebster-session-power", "logout"],
    "shutdown": ["hyperwebster-session-power", "shutdown"],
    "reboot": ["hyperwebster-session-power", "reboot"],
    "hibernate": ["hyperwebster-session-power", "hibernate"],
}
data = {}
if path.is_file():
    try:
        data = json.loads(path.read_text())
    except Exception:
        data = {}
session = dict(data.get("session") or {})
existing = dict(session.get("commands") or {})
existing.update(cmds)
session["commands"] = existing
data["session"] = session
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2) + "\n")
print(f":: patched {path} session.commands")
PY

# Reload caelestia so the new commands take effect without a full re-login.
if command -v caelestia >/dev/null 2>&1; then
  caelestia shell -d >/dev/null 2>&1 || true
elif command -v qs >/dev/null 2>&1; then
  qs -c caelestia kill >/dev/null 2>&1 || true
  nohup qs -c caelestia >/dev/null 2>&1 &
  disown || true
fi

# Keep polkit prompts available for any remaining privileged paths.
systemctl --user enable --now hyprpolkitagent.service >/dev/null 2>&1 || \
  systemctl --user start hyprpolkitagent.service >/dev/null 2>&1 || true

echo "session-power: ok"
