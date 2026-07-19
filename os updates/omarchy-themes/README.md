# Omarchy themes for HyperWebster

Brings Omarchy's theme catalog + community git installs + wallpaper theme
generation into HyperWebster's **caelestia** colour system (not a second
Waybar/Walker theme engine).

## What you get

| Feature | How |
|---------|-----|
| Extra stock themes | matte-black, hackerman, miasma, kanagawa, osaka-jade, ethereal, lumon, vantablack, ristretto, retro-82, flexoki-light, white, last-horizon, solitude |
| Overlap with caelestia | tokyo-night → `tokyonight`, rose-pine → `rosepine`, catppuccin / nord / gruvbox / everforest already present |
| Community Omarchy packs | `hyperwebster-theme install <git-url>` (same repos as [Extra themes](https://learn.omacom.io/2/the-omarchy-manual/90/extra-themes)) |
| Omarchy wallpapers | `hyperwebster-theme sync-wallpapers` — downloads stock theme backgrounds into `~/.config/omarchy/backgrounds/<theme>/` and symlinks them into `~/Pictures/Wallpapers` so **Settings → Wallpaper & style** lists them as categories |
| Wallpaper generator | `hyperwebster-theme generate [image] [name]` — applies Material You **dynamic** from the image, then snapshots a named user scheme (needs the caelestia user-scheme overlay to appear in Colours) |

| Colours settings UI | Settings → Wallpaper & style → Colours |
| Hotkey | `Super+Ctrl+Shift+Space` (Omarchy theme-picker chord) |

## Layout

| Path | Role |
|------|------|
| `~/.local/share/caelestia/schemes/<name>/` | User schemes visible to `caelestia scheme list` |
| `~/.config/omarchy/themes/<name>/` | Kept Omarchy pack layout (git pull / community tools) |
| `~/.config/omarchy/backgrounds/<theme>/` | Omarchy stock + pack backgrounds ([Backgrounds](https://learn.omacom.io/2/the-omarchy-manual/89/backgrounds)) |
| `~/Pictures/Wallpapers/<theme>/` | Symlinks into the above so Caelestia's wallpaper picker sees them |
| `/etc/xdg/...` Colours page | Install / generate / remove actions |

## Credit

- [Omarchy themes](https://learn.omacom.io/2/the-omarchy-manual/52/themes) & [extra themes](https://learn.omacom.io/2/the-omarchy-manual/90/extra-themes)
- [Omarchy backgrounds](https://learn.omacom.io/2/the-omarchy-manual/89/backgrounds) from [basecamp/omarchy](https://github.com/basecamp/omarchy)
- [keyd](https://github.com/rvaiya/keyd) is separate; colour schemes + wallpaper sync are this layer
