#!/usr/bin/env bash
#
# Run hyperwebster.sh inside an Arch Linux container with the repo bind-mounted.
# Works with OrbStack, Docker Desktop (macOS / Windows WSL2), and Podman.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_NAME="${HYPERWEBSTER_BUILD_IMAGE:-hyperwebster-builder:latest}"
DOCKERFILE="$SCRIPT_DIR/docker/Dockerfile"
# Official archlinux image is x86_64-only (ISO is amd64). Apple Silicon needs this.
PLATFORM="${HYPERWEBSTER_BUILD_PLATFORM:-linux/amd64}"

container_runtime() {
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo docker
    return 0
  fi
  if command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then
    echo podman
    return 0
  fi
  echo "ERROR: Docker, OrbStack, or Podman is required for container builds." >&2
  echo "  macOS: https://orbstack.dev/ or Docker Desktop" >&2
  echo "  Windows: WSL2 + Docker Desktop WSL integration" >&2
  exit 1
}

# shellcheck source=scripts/fetch-arch-iso.sh
source "$SCRIPT_DIR/scripts/fetch-arch-iso.sh"

RUNTIME="$(container_runtime)"

# Detect host for clearer logs (OrbStack reports as docker).
HOST_HINT="container"
if grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ]; then
  HOST_HINT="WSL2"
elif [ "$(uname -s)" = Darwin ]; then
  if docker info 2>/dev/null | grep -qi orbstack; then
    HOST_HINT="OrbStack"
  else
    HOST_HINT="macOS Docker"
  fi
fi

echo "==> Host: $HOST_HINT · runtime: $RUNTIME · platform: $PLATFORM"
if [ "$(uname -m)" = arm64 ] || [ "$(uname -m)" = aarch64 ]; then
  echo "==> Apple Silicon / ARM host: building amd64 Arch under emulation (slower)."
fi
echo "==> Building image $IMAGE_NAME (if needed)..."
"$RUNTIME" build --platform "$PLATFORM" -t "$IMAGE_NAME" -f "$DOCKERFILE" "$SCRIPT_DIR/docker"

hyperwebster_ensure_stock_iso "$SCRIPT_DIR" >/dev/null

BUILD_UID="$(id -u)"
BUILD_GID="$(id -g)"
BUILD_USER="$(id -un)"

# mkarchroot needs mount namespaces; --privileged is the reliable path on
# OrbStack, Docker Desktop (macOS/Windows), and Linux.
CONTAINER_ARGS=(
  run --rm
  --platform "$PLATFORM"
  --privileged
  --cap-add SYS_ADMIN
  --security-opt seccomp=unconfined
  -v "$SCRIPT_DIR:/build"
  # Keep the AUR clean-chroot off the macOS bind mount (mkarchroot needs a real
  # Linux FS for .arch-chroot / device nodes). Named volume persists across runs.
  -v hyperwebster-aur-chroot:/var/cache/hyperwebster/chroot
  # Unsquash work tree must be case-sensitive (macOS APFS bind mounts are not).
  -v hyperwebster-build-work:/var/cache/hyperwebster/work
  -w /build
  -e HYPERWEBSTER_BUILD_UID="$BUILD_UID"
  -e HYPERWEBSTER_BUILD_GID="$BUILD_GID"
  -e HYPERWEBSTER_BUILD_USER="$BUILD_USER"
  -e HYPERWEBSTER_CHROOT=/var/cache/hyperwebster/chroot
  -e HYPERWEBSTER_WORK=/var/cache/hyperwebster/work
)

# Allocate a TTY when stdin is a terminal (skip in CI / non-interactive).
if [ -t 0 ]; then
  CONTAINER_ARGS+=(-it)
fi

if [ -n "${HYPERWEBSTER_ARCH_ISO:-}" ]; then
  iso_basename="$(basename "$HYPERWEBSTER_ARCH_ISO")"
  CONTAINER_ARGS+=(-e "HYPERWEBSTER_ARCH_ISO=/build/$iso_basename")
  if [[ "$HYPERWEBSTER_ARCH_ISO" != "$SCRIPT_DIR/"* ]]; then
    CONTAINER_ARGS+=(-v "$HYPERWEBSTER_ARCH_ISO:/build/$iso_basename:ro")
  fi
fi

for var in SSH_PUBKEY HYPERWEBSTER_ARCH_ISO_URL HYPERWEBSTER_SKIP_ISO_DOWNLOAD \
           HYPERWEBSTER_REFRESH_MIRRORS; do
  if [ -n "${!var:-}" ]; then
    CONTAINER_ARGS+=(-e "$var=${!var}")
  fi
done

if [ -n "${HYPERWEBSTER_MIRRORLIST:-}" ]; then
  CONTAINER_ARGS+=(-v "$HYPERWEBSTER_MIRRORLIST:/build/.mirrorlist:ro")
  CONTAINER_ARGS+=(-e "HYPERWEBSTER_MIRRORLIST=/build/.mirrorlist")
fi

echo "==> Starting HyperWebster OS ISO build in Arch container..."
exec "$RUNTIME" "${CONTAINER_ARGS[@]}" "$IMAGE_NAME" ./hyperwebster.sh "$@"
