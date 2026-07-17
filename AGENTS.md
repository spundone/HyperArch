## Learned User Preferences

- Prefers delegating large feature sets to background workers ("Start multitasking") rather than blocking the main chat.
- Expects logical git commits grouped by feature area and uses `cursor/` branch prefixes for PR branches.
- For HyperWebster-OS public docs: use hyphens instead of em dashes; omit personal hardware specs and model numbers.
- Public repo must include a vibecoded, personal-use-only disclaimer (untested, experimental).
- Wants tasteful Omarchy-inspired features layered in, not a wholesale Omarchy install.
- Requests keybinding conflict audits when adding Omarchy or other shortcut layers.
- Prefers detailed image-to-ASCII Starman art for boot and terminal branding over simple line-art logos.
- Wants Raycast-like themed search with Omarchy-style install menu (packages, AUR, apps like Steam) on Super+Alt+Space, optional frosted-glass blur when transparency is enabled, and a rounded-corners toggle in the shell.
- Wants Nexus Additions page toggles for all mod/layer components.
- Expects Nexus update controls to invoke `hyperwebster-update`, aliasing leftover `nosignal-update` calls when needed.
- Uses hyperarch naming alongside HyperWebster/Starman where easier to pronounce.
- Expects upstream credit (NoSignal OS, caelestia, Omarchy, CachyOS, etc.) in public documentation.

## Learned Workspace Facts

- HyperWebster-OS lives at `~/Projects/HyperWebster-OS`; public repo is `spundone/HyperWebster-OS` on GitHub.
- Personal Arch desktop ISO flavor forked from NoSignal-OS (`~/NoSignal-OS`); hyperarch / HyperWebster / Starman branding lineage.
- Live installer uses a HyperWebster OS-branded, Omarchy-inspired `gum` TUI with Starman art and stepwise install flow.
- ISO builds use `./build.sh` for Arch native or containerized OrbStack/Docker Desktop/WSL2; `hyperwebster.sh` auto-downloads the latest Arch ISO and uses mirror failover.
- Shell still builds from upstream `28allday/nosignal-shell` until a `hyperwebster-shell` fork exists.
- Layer components live under `os updates/`; `hyperwebster-update` pulls the layer from GitHub, skips rsync when trees already match, and supports `--force-migrations`; migrations must tolerate already-identical files.
- Gaming/TV focus: Limine Starman boot, Deckify/gamescope/Chimera, LUKS2 with TPM auto-unlock and Omarchy-style Plymouth fallback; public docs describe generic 4K HDR VRR TV gaming without personal hardware.
- CachyOS optimized kernel and kernel manager ship out-of-the-box by default.
- Tailscale is preloaded for remote access; iPhone USB tethering ships via `28allday/omatether` with NetworkManager + networkd coexistence.
- Keeps NoSignal/caelestia desktop look with light/dark theme polish (SDDM sync, GTK bridge).
- Secondary drives premount at boot via the `drive-automount` layer component.
- Real hardware install feedback drives fixes (LUKS/TPM unlock, Nexus About strings, blank Additions page).
