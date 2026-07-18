# Colours settings page

Replaces the upstream Nexus **Colours** stub ("Page under construction") under
Settings → Wallpaper & style → Colours.

## What you get

- Live Material palette preview (primary / secondary / tertiary / surface)
- Colour scheme + flavour pickers (`caelestia scheme list` / `set`)
- Material You variant picker (tonal spot, vibrant, expressive, …)
- Dark theme and smart-scheme toggles
- Transparency on/off plus base and layer opacity sliders
- Sync login screen colours (`sddm-theme-sync`)

Frosted-glass blur and window rounding stay on **Additions** (existing toggles).

## Install

```sh
sh install-colours-page.sh
```

Or via `hyperwebster-update` (migration `1781760000-colours-page`).

Then **Ctrl+Super+Alt+R** to reload the shell.

## Layout

| File | Role |
|------|------|
| `ColourSelect.qml` | Settings sub-page UI |
| `patch-colours-page.sh` | Installs QML over `/etc/xdg/quickshell/caelestia/.../ColourSelect.qml` |
| `install-colours-page.sh` | Copies to `~/.local/share/hyperwebster/colours-page`, patches, pacman hook |

No `PageCompRegistry` edit — Colours is already stack index 3 under Wallpaper & style.
