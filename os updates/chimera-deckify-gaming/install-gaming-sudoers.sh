#!/bin/sh
# install-gaming-sudoers.sh — NOPASSWD for session arm + desktop exit helpers.
set -eu

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
cat > "$TMP" <<'SUDO'
# HyperWebster — gamescope session switching without a password prompt.
%wheel ALL=(ALL) NOPASSWD: /usr/local/bin/gaming-session-switch, /usr/local/bin/hyperwebster-restart-sddm, /usr/local/bin/hyperwebster-set-desktop-session
SUDO

if ! visudo -cf "$TMP" >/dev/null 2>&1; then
  echo "WARNING: sudoers validation failed — session switch will prompt for sudo" >&2
  exit 1
fi

install -m0440 "$TMP" /etc/sudoers.d/hyperwebster-gaming-session
echo "gaming sudoers: installed (/etc/sudoers.d/hyperwebster-gaming-session)"
