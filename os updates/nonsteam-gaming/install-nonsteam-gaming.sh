#!/bin/sh
# install-nonsteam-gaming.sh — install CLI helpers into ~/.local/bin (user).
# Safe when run from ~/.local/share/hyperwebster/nonsteam-gaming (layer copy).
set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="${HOME}/.local/bin"
SHARE="${HOME}/.local/share/hyperwebster/nonsteam-gaming"

# Never GNU-install a file onto itself (layer already lives under SHARE).
hw_install_file() {
  _s=$1; _d=$2; _m=${3:-0644}
  [ -f "$_s" ] || return 0
  _sr=$(readlink -f "$_s" 2>/dev/null || echo "$_s")
  _dr=
  [ -e "$_d" ] && _dr=$(readlink -f "$_d" 2>/dev/null || echo "$_d")
  if [ -n "$_dr" ] && [ "$_sr" = "$_dr" ]; then
    chmod "$_m" "$_d" 2>/dev/null || true
    return 0
  fi
  mkdir -p "$(dirname -- "$_d")"
  install -m "$_m" "$_s" "$_d"
}

mkdir -p "$BIN" "$SHARE"
for s in \
  hyperwebster-install-heroic \
  hyperwebster-install-steam-rom-manager \
  hyperwebster-install-decky \
  hyperwebster-install-millennium \
  hyperwebster-local-games \
  hyperwebster-decky-cef-ensure \
  install-nonsteam-gaming.sh
do
  [ -f "$HERE/$s" ] || continue
  hw_install_file "$HERE/$s" "$BIN/$s" 0755
  hw_install_file "$HERE/$s" "$SHARE/$s" 0755
done
hw_install_file "$HERE/README.md" "$SHARE/README.md" 0644
hw_install_file "$HERE/hyperwebster-decky-cef-ensure.service" \
  "$SHARE/hyperwebster-decky-cef-ensure.service" 0644

# User unit: recreate CEF marker before every Game Mode Steam start.
if [ -f "$SHARE/hyperwebster-decky-cef-ensure.service" ]; then
  mkdir -p "${HOME}/.config/systemd/user"
  hw_install_file "$SHARE/hyperwebster-decky-cef-ensure.service" \
    "${HOME}/.config/systemd/user/hyperwebster-decky-cef-ensure.service" 0644
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable hyperwebster-decky-cef-ensure.service 2>/dev/null || true
fi

# Best-effort CEF + PluginLoader repair if Decky is already installed.
if [ -x "$BIN/hyperwebster-install-decky" ] && [ -x "${HOME}/homebrew/services/PluginLoader" ]; then
  "$BIN/hyperwebster-install-decky" >/dev/null 2>&1 || true
fi

# Desktop entry for the local library importer.
APPDIR="${HOME}/.local/share/applications"
mkdir -p "$APPDIR"
cat > "$APPDIR/hyperwebster-local-games.desktop" <<EOF
[Desktop Entry]
Name=HyperWebster Local Games
Comment=Import a local game folder into Steam Non-Steam (gamescope / Starman)
Exec=kitty -e bash -lc 'hyperwebster-local-games roots list; echo; echo "Add a library: hyperwebster-local-games roots add /mnt/.../Games"; echo "Then: hyperwebster-local-games scan && hyperwebster-local-games import"; echo; bash'
Icon=steam
Terminal=true
Type=Application
Categories=Game;
EOF

# Prefer ~/.local/bin on PATH for Additions follow-up commands.
case ":${PATH}:" in
  *":${BIN}:"*) ;;
  *) export PATH="${BIN}:${PATH}" ;;
esac

echo "nonsteam-gaming: helpers → $BIN"
