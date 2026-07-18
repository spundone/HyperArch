#!/bin/sh
# fix-limine-uki-entry.sh — idempotent. REQUIRES ROOT when a rewrite is needed.
#
# With ENABLE_UKI=yes, limine removes /boot/vmlinuz-linux and
# /boot/initramfs-linux.img (UKI-only), but the installer-seeded first entry
# "/HyperWebster (Arch Linux)" in limine.conf still uses `protocol: linux` ->
# boot():/vmlinuz-linux. That entry is the default auto-boot target and now
# dead-boots to a TTY. This converts it to a `protocol: efi` entry that boots
# the UKI, keeping the same label (so it stays first = default) and cmdline.
#
# Soft-exits (0) when limine/UKI are absent — never abort hyperwebster-update
# on non-Limine boxes or before the first UKI build.
#
# Do NOT `source` /etc/default/limine — bash array syntax aborts POSIX sh.
set -eu

ESP_PATH=/boot
UKI_NAME=hyperwebster
DEFAULTS=/etc/default/limine

[ "$(id -u)" -eq 0 ] || { echo "must run as root (edits limine.conf)" >&2; exit 1; }

# Parse limine defaults without sourcing.
if [ -f "$DEFAULTS" ]; then
  esp_line=$(grep -E '^ESP_PATH=' "$DEFAULTS" | head -1 || true)
  if [ -n "$esp_line" ]; then
    ESP_PATH=${esp_line#ESP_PATH=}
    ESP_PATH=${ESP_PATH#\"}
    ESP_PATH=${ESP_PATH%\"}
  fi
  uki_line=$(grep -E '^CUSTOM_UKI_NAME=' "$DEFAULTS" | head -1 || true)
  if [ -n "$uki_line" ]; then
    UKI_NAME=${uki_line#CUSTOM_UKI_NAME=}
    UKI_NAME=${UKI_NAME#\"}
    UKI_NAME=${UKI_NAME%\"}
  fi
fi
[ -n "${ESP_PATH:-}" ] || ESP_PATH=/boot
[ -n "${UKI_NAME:-}" ] || UKI_NAME=hyperwebster

CONF="$ESP_PATH/limine.conf"
UKI_REL="/EFI/Linux/${UKI_NAME}_linux.efi"
UKI_ABS="$ESP_PATH$UKI_REL"

if [ ! -f "$CONF" ]; then
  echo "no $CONF — skipping (not a Limine install)"
  exit 0
fi

if [ ! -f "$UKI_ABS" ]; then
  found=$(find "$ESP_PATH/EFI/Linux" -maxdepth 1 -type f \( -name '*_linux.efi' -o -name '*_Linux.efi' \) 2>/dev/null | head -1 || true)
  if [ -n "$found" ]; then
    UKI_ABS=$found
    UKI_REL=${UKI_ABS#"$ESP_PATH"}
    echo ":: using UKI $UKI_REL"
  else
    echo "WARNING: UKI not found under $ESP_PATH/EFI/Linux — skipping (run limine-update later)" >&2
    exit 0
  fi
fi

# Already fixed? (no dead vmlinuz path left)
if ! grep -q 'path: boot():/vmlinuz-linux' "$CONF"; then
  echo "limine.conf has no dead vmlinuz entry — nothing to do"
  exit 0
fi

cp -a "$CONF" "$CONF.bak.$(date +%Y%m%d%H%M%S)"

# Rewrite the HyperWebster / hyperarch manual entry body: protocol:linux +
# vmlinuz + module_path → protocol:efi + UKI. Keep cmdline. Match several
# historical labels so older ISOs still repair.
awk -v uki="$UKI_REL" '
  /^\/HyperWebster/ || /^\/hyperarch/ { print; inblk=1; next }
  inblk && /^[^[:space:]]/      { inblk=0 }
  inblk && /^[[:space:]]*protocol:[[:space:]]*linux/ { print "    protocol: efi"; next }
  inblk && /^[[:space:]]*path:[[:space:]]*boot\(\):\/vmlinuz-linux/ { print "    path: boot():" uki; next }
  inblk && /^[[:space:]]*module_path:/ { next }
  { print }
' "$CONF" > "$CONF.tmp"

if ! grep -q "path: boot():$UKI_REL" "$CONF.tmp" || grep -q 'boot():/vmlinuz-linux' "$CONF.tmp"; then
  echo "WARNING: rewrite did not clear vmlinuz entry — leaving limine.conf untouched" >&2
  echo "         (entry label may have drifted; inspect $CONF manually)" >&2
  rm -f "$CONF.tmp"
  exit 0
fi

mv "$CONF.tmp" "$CONF"
sync
echo "fixed: HyperWebster entry now protocol:efi -> $UKI_REL (backup kept)"
