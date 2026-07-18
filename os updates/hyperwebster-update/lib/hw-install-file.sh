# shellcheck shell=sh
# hw-install-file.sh — copy/install a file, no-op when src and dest are the same
# path (live layer checkout: HYPERWEBSTER_SRC == ~/.local/share/hyperwebster).
#
# Usage (from an installer):
#   . "$HYPERWEBSTER_SRC/hyperwebster-update/lib/hw-install-file.sh"
#   hw_install_file "$SRC/foo" "$DEST/foo" 0644
#
# Or resolve lib next to this file when HYPERWEBSTER_SRC is unset:
#   . "$(dirname "$0")/../hyperwebster-update/lib/hw-install-file.sh"

hw_install_file() {
  # hw_install_file SRC DEST [MODE]
  # MODE defaults to 0644. Uses install(1) when copying; chmod-only on same file.
  _hw_src=$1
  _hw_dest=$2
  _hw_mode=${3:-0644}
  [ -f "$_hw_src" ] || return 0
  _hw_src_r=$(readlink -f "$_hw_src" 2>/dev/null || realpath "$_hw_src" 2>/dev/null || echo "$_hw_src")
  _hw_dest_r=
  if [ -e "$_hw_dest" ]; then
    _hw_dest_r=$(readlink -f "$_hw_dest" 2>/dev/null || realpath "$_hw_dest" 2>/dev/null || echo "$_hw_dest")
  fi
  if [ -n "$_hw_dest_r" ] && [ "$_hw_src_r" = "$_hw_dest_r" ]; then
    chmod "$_hw_mode" "$_hw_dest" 2>/dev/null || true
    return 0
  fi
  mkdir -p "$(dirname -- "$_hw_dest")"
  install -m "$_hw_mode" "$_hw_src" "$_hw_dest"
}
