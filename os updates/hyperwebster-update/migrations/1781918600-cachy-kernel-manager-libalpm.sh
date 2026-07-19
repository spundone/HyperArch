#!/bin/bash
# Stale IgnorePkg=pacman + stock libalpm breaks cachyos-kernel-manager.
# Refresh helper/sudoers and run fix-pacman when CachyOS is enabled.
set -euo pipefail

SRC="${HYPERWEBSTER_SRC:-$HOME/.local/share/hyperwebster}/cachyos-repo-switch"
[ -f "$SRC/hyperwebster-cachy-repo" ] || \
  SRC="$(cd "$(dirname "$0")/../../cachyos-repo-switch" && pwd)"

if [ ! -f "$SRC/hyperwebster-cachy-repo" ]; then
  echo "NOTE: cachyos-repo-switch source missing — skip"
  exit 0
fi

mkdir -p "$HOME/.local/share/hyperwebster/cachyos-repo-switch"
install -m 0755 "$SRC/hyperwebster-cachy-repo" \
  "$HOME/.local/share/hyperwebster/cachyos-repo-switch/hyperwebster-cachy-repo"
install -m 0644 "$SRC/02-hyperwebster-cachy" \
  "$HOME/.local/share/hyperwebster/cachyos-repo-switch/02-hyperwebster-cachy" 2>/dev/null || true

need_fix=0
if grep -qE '^\[cachyos' /etc/pacman.conf 2>/dev/null \
  && ! nm -D /usr/lib/libalpm.so.16 2>/dev/null | grep -q 'T alpm_pkg_get_installed_db$'; then
  need_fix=1
fi

if sudo -n true 2>/dev/null; then
  sudo install -Dm0755 "$SRC/hyperwebster-cachy-repo" /usr/local/bin/hyperwebster-cachy-repo
  if [ -f "$SRC/02-hyperwebster-cachy" ]; then
    tmp=$(mktemp)
    install -m 0440 "$SRC/02-hyperwebster-cachy" "$tmp"
    if visudo -cf "$tmp" >/dev/null 2>&1; then
      sudo install -m 0440 -o root -g root "$tmp" /etc/sudoers.d/02-hyperwebster-cachy
    fi
    rm -f "$tmp"
  fi
  if [ "$need_fix" -eq 1 ]; then
    sudo /usr/local/bin/hyperwebster-cachy-repo fix-pacman || true
  fi
  echo ":: cachyos-kernel-manager libalpm repair applied"
else
  echo "NOTE: need sudo to refresh hyperwebster-cachy-repo + fix-pacman"
fi
