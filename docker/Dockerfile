# Arch Linux image with HyperWebster OS ISO-builder dependencies.
# Used by scripts/build-in-container.sh (./build.sh on macOS / WSL / non-Arch).
#
# Force linux/amd64: the official archlinux image is x86_64-only. Apple Silicon
# (OrbStack / Docker Desktop) runs it under qemu/Rosetta emulation.
FROM --platform=linux/amd64 archlinux:latest

# pacman 7's DownloadUser/sandbox fails under qemu-user ("switching to sandbox
# user 'alpm' failed"). Disable for image build; the build chroot is separate.
RUN sed -i 's/^DownloadUser/#DownloadUser/' /etc/pacman.conf \
    && printf '\n# HyperWebster container build (qemu-safe)\nDisableSandbox\n' >> /etc/pacman.conf \
    && pacman-key --init \
    && pacman-key --populate archlinux \
    && pacman -Syu --noconfirm \
    && pacman -S --noconfirm --needed \
        base-devel \
        git \
        libisoburn \
        squashfs-tools \
        coreutils \
        devtools \
        btrfs-progs \
        pacman-contrib \
        reflector \
        util-linux \
        sudo \
        curl \
        wget \
        which \
    && pacman -Scc --noconfirm

# makepkg / makechrootpkg refuse UID 0. hyperwebster.sh also creates this user
# on the fly when missing; pre-seed it so container builds are ready.
RUN useradd -m -U hwbuilder \
    && echo 'hwbuilder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/90-hwbuilder \
    && chmod 0440 /etc/sudoers.d/90-hwbuilder

WORKDIR /build
# Preserve argv (plain `bash -lc` ate extra args after the script name).
ENTRYPOINT ["/bin/bash", "-c", "exec \"$@\"", "--"]
CMD ["./hyperwebster.sh"]
