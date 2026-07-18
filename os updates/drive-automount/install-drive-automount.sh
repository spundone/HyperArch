#!/bin/sh
# install-drive-automount.sh — idempotent. Needs root.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

install -Dm0755 "$HERE/hyperwebster-drive-automount" /usr/local/bin/hyperwebster-drive-automount
install -Dm0755 "$HERE/hyperwebster-drives" /usr/local/bin/hyperwebster-drives
install -Dm0644 "$HERE/hyperwebster-drive-automount.service" \
  /etc/systemd/system/hyperwebster-drive-automount.service
install -Dm0644 "$HERE/README.md" /usr/local/share/hyperwebster/drive-automount/README.md
install -d -m 755 /mnt
install -d -m 755 /etc/hyperwebster
[ -f /etc/hyperwebster/drive-automount-ignore ] || : > /etc/hyperwebster/drive-automount-ignore

# NOPASSWD so Nexus System tools can remount / ignore without a prompt.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
cat > "$TMP" <<'SUDO'
# HyperWebster — secondary drive automount helpers (System tools → Drives).
%wheel ALL=(ALL) NOPASSWD: /usr/local/bin/hyperwebster-drive-automount, /usr/local/bin/hyperwebster-drives
SUDO
if visudo -cf "$TMP" >/dev/null 2>&1; then
  install -m0440 "$TMP" /etc/sudoers.d/hyperwebster-drive-automount
  echo "drive-automount sudoers: /etc/sudoers.d/hyperwebster-drive-automount"
else
  echo "WARNING: drive-automount sudoers validation failed" >&2
fi
rm -f "$TMP"
trap - EXIT

systemctl daemon-reload
systemctl enable hyperwebster-drive-automount.service
echo "drive-automount: enabled (non-system drives -> /mnt/<label>, FAT/NTFS uid=desktop user)"
