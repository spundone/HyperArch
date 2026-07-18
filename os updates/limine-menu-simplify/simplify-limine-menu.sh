#!/bin/sh
# simplify-limine-menu.sh — shrink Limine to desktop UKI + Starman (+ Snapshots).
# Idempotent. REQUIRES ROOT. Backs up limine.conf and /etc/default/limine first.
#
# Drops manual protocol:linux fallbacks, nested auto OS clutter drivers
# (ENABLE_LIMINE_FALLBACK / FIND_BOOTLOADERS), and rewrites the menu seed so
# limine-entry-tool targets the desktop entry via machine-id comment.
set -eu

ESP_PATH=/boot
UKI_NAME=hyperwebster
DEFAULTS=/etc/default/limine

[ "$(id -u)" -eq 0 ] || { echo "must run as root" >&2; exit 1; }

[ -r "$DEFAULTS" ] && . "$DEFAULTS" 2>/dev/null || true
[ -n "${ESP_PATH:-}" ] || ESP_PATH=/boot
[ -n "${CUSTOM_UKI_NAME:-}" ] && UKI_NAME="$CUSTOM_UKI_NAME"

CONF="$ESP_PATH/limine.conf"
UKI_REL="/EFI/Linux/${UKI_NAME}_linux.efi"
UKI_ABS="$ESP_PATH$UKI_REL"
MACHINE_ID=$(tr -d '[:space:]' </etc/machine-id 2>/dev/null || true)

[ -f "$CONF" ] || { echo "no $CONF" >&2; exit 1; }
[ -f "$UKI_ABS" ] || { echo "UKI not found at $UKI_ABS — aborting" >&2; exit 1; }
[ -n "$MACHINE_ID" ] || { echo "no /etc/machine-id — aborting" >&2; exit 1; }

stamp=$(date +%Y%m%d%H%M%S)
cp -a "$CONF" "$CONF.bak.$stamp"
[ -f "$DEFAULTS" ] && cp -a "$DEFAULTS" "$DEFAULTS.bak.$stamp"

# Preserve LUKS/root cmdline from the current desktop (or Starman) entry.
extract_cmdline() {
  awk '
    /^\/HyperWebster/ && /hyperarch|Arch Linux/ { inblk=1; next }
    /^\/Starman/ { if (!found) inblk=1; next }
    inblk && /^[^[:space:]\/]/ { inblk=0 }
    inblk && /^[[:space:]]*cmdline:[[:space:]]*/ {
      sub(/^[[:space:]]*cmdline:[[:space:]]*/, "")
      # Strip Starman flag if we grabbed that entry
      gsub(/[[:space:]]*hyperwebster\.starman=1/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      print
      found=1
      exit
    }
  ' "$CONF"
}

CMDLINE=$(extract_cmdline)
if [ -z "$CMDLINE" ] && [ -f "$DEFAULTS" ]; then
  # Fallback: first KERNEL_CMDLINE[default]+= line after the =
  CMDLINE=$(grep -E '^KERNEL_CMDLINE\[default\]\+=' "$DEFAULTS" | head -1 \
    | sed 's/^KERNEL_CMDLINE\[default\]+=//' | sed 's/^"//;s/"$//')
fi
[ -n "$CMDLINE" ] || CMDLINE="rw quiet splash"

# Quiet limine-entry-tool: no EFI-fallback menu row, no bootloader scan clutter.
# Keep UKI + Snapshots. BOOT_ORDER drops *fallback.
if [ -f "$DEFAULTS" ]; then
  tmp=$(mktemp)
  awk '
    BEGIN { saw_fb=0; saw_find=0; saw_order=0 }
    /^ENABLE_LIMINE_FALLBACK=/ { print "ENABLE_LIMINE_FALLBACK=no"; saw_fb=1; next }
    /^FIND_BOOTLOADERS=/ { print "FIND_BOOTLOADERS=no"; saw_find=1; next }
    /^BOOT_ORDER=/ { print "BOOT_ORDER=\"*, Snapshots\""; saw_order=1; next }
    { print }
    END {
      if (!saw_fb) print "ENABLE_LIMINE_FALLBACK=no"
      if (!saw_find) print "FIND_BOOTLOADERS=no"
      if (!saw_order) print "BOOT_ORDER=\"*, Snapshots\""
    }
  ' "$DEFAULTS" > "$tmp"
  mv "$tmp" "$DEFAULTS"
else
  cat > "$DEFAULTS" <<EOF
TARGET_OS_NAME="HyperWebster"
ESP_PATH="$ESP_PATH"
KERNEL_CMDLINE[default]+="$CMDLINE"
ENABLE_UKI=yes
CUSTOM_UKI_NAME="$UKI_NAME"
ENABLE_LIMINE_FALLBACK=no
FIND_BOOTLOADERS=no
BOOT_ORDER="*, Snapshots"
MAX_SNAPSHOT_ENTRIES=5
SNAPSHOT_FORMAT_CHOICE=5
EOF
fi

# Preserve branding / timeout / default_entry from existing conf when present.
TIMEOUT=$(grep -E '^timeout:' "$CONF" | head -1 | awk '{print $2}')
[ -n "$TIMEOUT" ] || TIMEOUT=10
BRANDING=$(grep -E '^interface_branding:' "$CONF" | head -1 | sed 's/^interface_branding:[[:space:]]*//')
[ -n "$BRANDING" ] || BRANDING="HyperWebster · hyperarch"

cat > "$CONF" <<EOF
timeout: $TIMEOUT
default_entry: 1
interface_branding: $BRANDING

/HyperWebster · hyperarch (Arch Linux)
    comment: machine-id=$MACHINE_ID
    protocol: efi
    path: boot():$UKI_REL
    cmdline: $CMDLINE

/Starman (Gaming / Steam)
    protocol: efi
    path: boot():$UKI_REL
    cmdline: $CMDLINE hyperwebster.starman=1
EOF

sync

if command -v limine-update >/dev/null 2>&1; then
  echo ":: running limine-update to refresh UKI / Snapshots entries..."
  limine-update || echo ":: limine-update failed — manual menu seed is in place" >&2
else
  echo ":: limine-update not found — menu seed written; install limine-mkinitcpio-hook to refresh"
fi

echo "Limine menu simplified: desktop + Starman (backups: *.$stamp)"
