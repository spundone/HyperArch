#!/bin/bash
# Container entrypoint for HyperWebster ISO builds.
# Nested systemd-nspawn (mkarchroot / arch-nspawn / makechrootpkg) needs:
#   1. a host /etc/machine-id (archlinux image often has none)
#   2. a writable /run/systemd/nspawn/propagate (tmpfs)
#   3. --keep-unit (no systemd as PID 1 to allocate a scope via D-Bus)
set -euo pipefail

if [ ! -s /etc/machine-id ]; then
  if command -v systemd-machine-id-setup >/dev/null 2>&1; then
    systemd-machine-id-setup >/dev/null 2>&1 || true
  fi
  if [ ! -s /etc/machine-id ]; then
    tr -d '-' </proc/sys/kernel/random/uuid > /etc/machine-id
  fi
fi
ln -sfn /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true

mkdir -p /run/systemd/nspawn/propagate
if ! mountpoint -q /run/systemd/nspawn/propagate 2>/dev/null; then
  mount -t tmpfs tmpfs /run/systemd/nspawn/propagate
fi

# Prefer /usr/local/bin so sudo's secure_path picks this up over /usr/bin.
cat > /usr/local/bin/systemd-nspawn <<'EOF'
#!/bin/bash
exec /usr/bin/systemd-nspawn --keep-unit "$@"
EOF
chmod 755 /usr/local/bin/systemd-nspawn

exec "$@"
