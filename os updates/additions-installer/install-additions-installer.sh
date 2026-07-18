#!/bin/sh
# install-additions-installer.sh — Settings → Additions page: install
# optional software on demand from official sources (no AUR, no Flatpak).
#
#   - hyperwebster-additions        -> ~/.local/bin (status cache + installer runner)
#   - additions.json          -> stable on-system copy (the manifest)
#   - AdditionsPage.qml       -> patched into caelestia-shell (sudo)
#   - pacman hook             -> re-applies the patch after shell upgrades
#
# Safe to re-run (idempotent). Needs sudo for the QML patch + hook.
set -eu

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN="$HOME/.local/bin"
SHARE="$HOME/.local/share/hyperwebster/additions-installer"

# HYPERWEBSTER_SRC is often already ~/.local/share/hyperwebster — never
# install a file onto itself (GNU install errors and aborts with set -e).
install_if_different() {
  src=$1 dest=$2 mode=$3
  [ -f "$src" ] || return 0
  src_r=$(readlink -f "$src")
  dest_r=$(readlink -f "$dest" 2>/dev/null || true)
  if [ -n "$dest_r" ] && [ "$src_r" = "$dest_r" ]; then
    chmod "$mode" "$dest" 2>/dev/null || true
    return 0
  fi
  install -m "$mode" "$src" "$dest"
}

# 1. Backend + manifest.
mkdir -p "$BIN" "$SHARE"
install_if_different "$SRC/hyperwebster-additions" "$BIN/hyperwebster-additions" 0755
install_if_different "$SRC/additions.json" "$SHARE/additions.json" 0644
install_if_different "$SRC/obs-extras.sh" "$SHARE/obs-extras.sh" 0755

# 2. Stable on-system copies for the pacman hook to point at.
install_if_different "$SRC/AdditionsPage.qml" "$SHARE/AdditionsPage.qml" 0644
install_if_different "$SRC/patch-additions-page.sh" "$SHARE/patch-additions-page.sh" 0755

# 3. QML registration — skipped when the ISO builder already branded nosignal-shell,
# but the pacman hook is always installed so a later shell upgrade re-applies the page.
if [ -n "${HYPERWEBSTER_SKIP_SHELL_PATCH:-}" ]; then
  echo ":: skipping Additions QML patch (HYPERWEBSTER_SKIP_SHELL_PATCH — fork ships the page)"
else
  sudo sh "$SHARE/patch-additions-page.sh"
fi

HOOK=/etc/pacman.d/hooks/hyperwebster-additions-page.hook
sudo mkdir -p /etc/pacman.d/hooks
sudo tee "$HOOK" > /dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyperwebster-shell
Target = caelestia-shell
Target = nosignal-shell

[Action]
Description = Re-applying HyperWebster Additions settings page...
When = PostTransaction
Exec = /bin/sh $SHARE/patch-additions-page.sh
EOF
echo ":: pacman hook installed -> $HOOK"

# 5. Seed the status cache so the page has data on first open.
"$BIN/hyperwebster-additions" status >/dev/null 2>&1 || true

echo "Done. Restart the shell (Ctrl+Super+Alt+R) to see Settings -> Additions."
