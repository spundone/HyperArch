# cachyos-kernel-manager

HyperWebster ships **`cachyos-kernel-manager`** from the CachyOS repository out of
the box (alongside `linux-cachyos`). Launch it from System tools or:

```sh
cachyos-kernel-manager
```

Use it to install alternate CachyOS kernel variants (`linux-cachyos-lts`,
`linux-cachyos-bore`, etc.) or build custom kernels. Limine entries update via
`limine-mkinitcpio-hook` after package installs.

## Requirement: CachyOS pacman

The manager links against CachyOS libalpm (`alpm_pkg_get_installed_db`). While
CachyOS repos are enabled, HyperWebster installs that pacman via
`hyperwebster-cachy-repo enable` (or `fix-pacman`). If the app exits immediately
with `undefined symbol: alpm_pkg_get_installed_db`, run:

```sh
sudo hyperwebster-cachy-repo fix-pacman
```

Settings → Services → **CachyOS kernel & repos** still controls userspace repo
conversion via `hyperwebster-cachy-repo`.
