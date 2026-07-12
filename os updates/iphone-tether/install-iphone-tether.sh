#!/bin/sh
# install-iphone-tether.sh — iPhone USB tethering via omatether, adapted for
# HyperWebster's NetworkManager desktop (networkd coexists for ipheth only).
# Idempotent. Root for system files; user desktop/windowrules for the caller.
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
USER_HOME="${SUDO_USER:+$(getent passwd "$SUDO_USER" | cut -d: -f6)}"
USER_HOME="${USER_HOME:-$HOME}"
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
  RUN_AS_USER="$SUDO_USER"
else
  RUN_AS_USER="$(id -un)"
fi

install -Dm0755 "$HERE/omatether.sh" /usr/local/bin/omatether
install -Dm0755 "$HERE/omatether.sh" /usr/local/bin/hyperwebster-tether

# NetworkManager must not claim the iPhone USB NIC; systemd-networkd owns it.
install -Dm0644 /dev/stdin /etc/NetworkManager/conf.d/99-unmanaged-ipheth.conf <<'EOF'
[keyfile]
unmanaged-devices=driver:ipheth
EOF

install -d -m0755 /etc/systemd/network
if [ ! -f /etc/systemd/network/10-iphone-tether.network ]; then
  install -Dm0644 /dev/stdin /etc/systemd/network/10-iphone-tether.network <<'EOF'
[Match]
Driver=ipheth

[Link]
RequiredForOnline=no

[Network]
DHCP=yes

[DHCPv4]
UseDNS=no
RouteMetric=750

[IPv6AcceptRA]
UseDNS=no
RouteMetric=750
EOF
fi

systemctl enable systemd-networkd.service 2>/dev/null || true
systemctl restart NetworkManager.service 2>/dev/null || true
systemctl restart systemd-networkd.service 2>/dev/null || true
networkctl reload 2>/dev/null || true

# Per-user launcher + Hyprland float rule (kitty, not Walker/xdg-terminal-exec).
install_user_bits() {
  home="$1"
  mkdir -p "$home/.local/share/applications"
  cat > "$home/.local/share/applications/omatether.desktop" <<'EOF'
[Desktop Entry]
Name=iPhone Tether
Comment=Use an iPhone's internet over USB (HyperWebster / omatether)
Exec=kitty --class omatether -e omatether
Icon=phone
Terminal=false
Type=Application
Categories=Network;
EOF

  hypr="$home/.config/caelestia/hypr-user.conf"
  mkdir -p "$(dirname "$hypr")"
  touch "$hypr"
  if ! grep -q 'omatether' "$hypr" 2>/dev/null; then
    cat >> "$hypr" <<'EOF'

# iPhone USB tether TUI (omatether)
windowrule = float on, match:class ^(omatether)$
windowrule = center on, match:class ^(omatether)$
windowrule = size 520 400, match:class ^(omatether)$
EOF
  fi
}

if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
  install_user_bits "$USER_HOME"
  chown -R "$RUN_AS_USER:" "$USER_HOME/.local/share/applications/omatether.desktop" \
    "$USER_HOME/.config/caelestia/hypr-user.conf" 2>/dev/null || true
else
  install_user_bits "$HOME"
fi

echo "iphone-tether: omatether installed (omatether / hyperwebster-tether)"
echo "  Plug in iPhone → unlock → Trust → enable Personal Hotspot"
echo "  Then: omatether pair   or open 'iPhone Tether' from the launcher"
