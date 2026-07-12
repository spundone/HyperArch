# Arch Linux image with HyperWebster OS ISO-builder dependencies.
# Used by scripts/build-in-container.sh (./build.sh on macOS / WSL / non-Arch).
FROM archlinux:latest

RUN pacman -Syu --noconfirm \
    && pacman -S --noconfirm --needed \
        git \
        libisoburn \
        squashfs-tools \
        coreutils \
        devtools \
        pacman-contrib \
        reflector \
        util-linux \
        sudo \
        curl \
        wget \
        which \
    && pacman -Scc --noconfirm

WORKDIR /build
ENTRYPOINT ["/bin/bash", "-lc"]
