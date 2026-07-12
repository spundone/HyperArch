#!/usr/bin/env bash
#
# build.sh — cross-platform entry for the HyperWebster OS ISO builder.
#
# Arch Linux with native tooling → ./hyperwebster.sh
# macOS (OrbStack / Docker Desktop / Podman) or Windows (WSL2 + Docker) →
# Arch container via scripts/build-in-container.sh
#
# Usage:
#   ./build.sh
#   HYPERWEBSTER_FORCE_CONTAINER=1 ./build.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_SCRIPT="$SCRIPT_DIR/scripts/build-in-container.sh"

hyperwebster_native_ready() {
  command -v pacman >/dev/null 2>&1 \
    && command -v mkarchroot >/dev/null 2>&1 \
    && command -v xorriso >/dev/null 2>&1 \
    && command -v unsquashfs >/dev/null 2>&1
}

container_runtime() {
  # Prefer OrbStack's docker when present (macOS), then Docker, then Podman.
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo docker
    return 0
  fi
  if command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then
    echo podman
    return 0
  fi
  return 1
}

usage_container_hint() {
  cat >&2 <<'EOF'

HyperWebster OS ISO builds need Arch tooling (pacman, devtools, xorriso).

macOS:
  - OrbStack (recommended): https://orbstack.dev/
  - or Docker Desktop: https://docs.docker.com/desktop/setup/install/mac-install/
  Then: ./build.sh

Windows:
  - WSL2 (Ubuntu) + Docker Desktop WSL integration, or Docker Engine in WSL
  Then from the repo inside WSL: ./build.sh

Arch Linux:
  sudo pacman -S --needed git libisoburn squashfs-tools coreutils devtools \
    pacman-contrib reflector util-linux
  ./hyperwebster.sh

Force container anywhere:
  HYPERWEBSTER_FORCE_CONTAINER=1 ./build.sh
EOF
}

if [ "${HYPERWEBSTER_FORCE_CONTAINER:-0}" = "1" ]; then
  exec "$CONTAINER_SCRIPT" "$@"
fi

if hyperwebster_native_ready; then
  exec "$SCRIPT_DIR/hyperwebster.sh" "$@"
fi

if container_runtime >/dev/null; then
  exec "$CONTAINER_SCRIPT" "$@"
fi

echo "ERROR: No suitable build environment found." >&2
usage_container_hint
exit 1
