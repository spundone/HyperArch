#!/usr/bin/env bash
# pull-layer.sh — refresh ~/.local/share/hyperwebster from the public GitHub repo.
# Safe to run standalone or from hyperwebster-update. Preserves migration state
# (~/.local/state/hyperwebster/applied). Skips download/sync when the remote
# commit and on-disk tree are already current.
set -euo pipefail

DEST="${HYPERWEBSTER_LAYER:-$HOME/.local/share/hyperwebster}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyperwebster"
VERSION_FILE="$STATE_DIR/layer-version"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/hyperwebster/layer-source.conf"
LAYER_URL="${HYPERWEBSTER_LAYER_URL:-https://github.com/spundone/HyperWebster-OS/archive/refs/heads/main.tar.gz}"
FORCE_PULL="${HYPERWEBSTER_LAYER_FORCE_PULL:-0}"

for a in "$@"; do
  case "$a" in
    --force) FORCE_PULL=1 ;;
    -h|--help)
      cat <<EOF
Usage: pull-layer.sh [--force]
  --force   re-download and sync even when commit and files match

Env: HYPERWEBSTER_LAYER, HYPERWEBSTER_LAYER_URL, HYPERWEBSTER_LAYER_FORCE_PULL=1
EOF
      exit 0 ;;
  esac
done

[ -f "$CONFIG" ] && . "$CONFIG"

log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m::\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

for cmd in curl tar cp rm mkdir chmod ln; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd is required to pull the HyperWebster layer"
done

read_local_commit() {
  [ -f "$VERSION_FILE" ] || return 0
  sed -n 's/^commit=//p' "$VERSION_FILE" | head -1
}

fetch_remote_commit() {
  curl -fsSL --proto '=https' --tlsv1.2 --max-time 15 \
    https://api.github.com/repos/spundone/HyperWebster-OS/commits/main \
    | sed -n 's/^[[:space:]]*"sha":[[:space:]]*"\([0-9a-f]\{7,40\}\)".*/\1/p' \
    | head -1 || true
}

write_version_file() {
  local commit="$1"
  local fetched mig
  fetched=$(date -Is)
  mig=$(find "$DEST/hyperwebster-update/migrations" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
  {
    echo "fetched_at=$fetched"
    echo "url=$LAYER_URL"
    [ -n "$commit" ] && echo "commit=$commit"
    echo "migrations=$mig"
  } > "$VERSION_FILE"
}

ensure_symlinks() {
  mkdir -p "$HOME/.local/bin"
  ln -sf "$DEST/hyperwebster-update/bin/hyperwebster-update" "$HOME/.local/bin/hyperwebster-update"
  ln -sf "$DEST/hyperwebster-update/bin/pull-layer.sh" "$HOME/.local/bin/hyperwebster-layer-pull"
}

# True when dest exists and every file matches src (no rsync/cp needed).
layer_trees_equal() {
  local src="$1" dest="$2"
  [ -d "$dest" ] || return 1
  if command -v rsync >/dev/null 2>&1; then
    # Empty itemize output => identical trees (modulo delete-only drift).
    [ -z "$(rsync -a --delete --dry-run --itemize-changes "$src/" "$dest/" 2>/dev/null | grep -v '^$' || true)" ]
    return $?
  fi
  if command -v diff >/dev/null 2>&1; then
    diff -qr "$src" "$dest" >/dev/null 2>&1
    return $?
  fi
  # No comparison tool — assume sync is needed.
  return 1
}

sync_layer_tree() {
  local src="$1" dest="$2"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/" "$dest/"
    return
  fi
  warn "rsync not found — replacing layer with cp -a (install rsync for faster sync)"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -a "$src/." "$dest/"
}

finish_unchanged() {
  local commit="$1"
  ensure_symlinks
  if [ -n "$commit" ] && [ "$(read_local_commit)" != "$commit" ]; then
    write_version_file "$commit"
  fi
  if [ -n "$commit" ]; then
    log "layer unchanged (already at ${commit:0:7})"
  else
    log "layer unchanged (files match remote)"
  fi
}

mkdir -p "$(dirname -- "$DEST")" "$STATE_DIR"

local_commit=$(read_local_commit)
remote_commit=$(fetch_remote_commit)

if [ "$FORCE_PULL" != 1 ] && [ -n "${local_commit:-}" ] && [ -n "${remote_commit:-}" ] \
   && [ "$local_commit" = "$remote_commit" ] && [ -d "$DEST/hyperwebster-update" ]; then
  finish_unchanged "$remote_commit"
  exit 0
fi

tmpdir=$(mktemp -d)
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

log "fetching layer from ${LAYER_URL##*//}"
curl -fSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 2 \
  -o "$tmpdir/layer.tar.gz" "$LAYER_URL" \
  || die "failed to download layer (check network and HYPERWEBSTER_LAYER_URL)"

tar -xzf "$tmpdir/layer.tar.gz" -C "$tmpdir"
top=$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -1)
[ -n "${top:-}" ] || die "unexpected tarball layout (no top-level directory)"
src="$top/os updates"
[ -d "$src" ] || die "tarball missing 'os updates/' (wrong URL or repo layout?)"

if [ "$FORCE_PULL" != 1 ] && layer_trees_equal "$src" "$DEST"; then
  finish_unchanged "${remote_commit:-$local_commit}"
  exit 0
fi

sync_layer_tree "$src" "$DEST"

chmod +x "$DEST/hyperwebster-update/bin/hyperwebster-update" \
  "$DEST/hyperwebster-update/bin/pull-layer.sh" \
  "$DEST/hyperwebster-update/migrations/"*.sh 2>/dev/null || true

ensure_symlinks
write_version_file "${remote_commit:-}"

mig=$(sed -n 's/^migrations=//p' "$VERSION_FILE" | head -1)
if [ -n "$remote_commit" ]; then
  log "layer refreshed (${remote_commit:0:7}, ${mig:-?} migrations in tree)"
else
  log "layer refreshed (${mig:-?} migrations in tree)"
fi
