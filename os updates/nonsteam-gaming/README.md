# nonsteam-gaming - Epic, emulators, Decky, Millennium for gamescope SteamUI

Gamescope / Starman shows **Steam Game Mode**. Epic, GOG, Amazon, and emulator
ROMs are not native SteamUI tabs - they appear as **Non-Steam** shortcuts that
Steam launches inside the same session.

## Additions (Settings → Additions → Gaming)

| Item | What it installs | How it shows in Starman |
|------|------------------|-------------------------|
| **Heroic** | Official Heroic `.pacman` from GitHub releases | Heroic → Add to Steam (or auto-add) → Non-Steam |
| **Steam ROM Manager** | Official AppImage → `~/.local/bin/steam-rom-manager` | Parse emulators → Save to Steam → Non-Steam |
| **Decky Loader** | Official Decky `install_release.sh` | Quick Access plugins in Game Mode (experimental) |
| **Millennium** | Official `https://steambrew.app/install.sh` | Steam themes/plugins + Lua backends (experimental) |

Sources policy: official upstream installers / release assets only (no Flatpak).

## Recommended flow

1. Install **Deckify / Chimera** (or DeckShift) so Starman / Super+Shift+S works.
2. **Heroic** on the desktop → log in → enable **Add games to Steam automatically**.
3. Optional: **Steam ROM Manager** for RetroArch / emulator libraries.
4. Reboot into **Starman** or Super+Shift+S - play from Non-Steam.

Point libraries at stable `/mnt/<label>/...` paths (System tools → Drives) so
desktop and gamescope see the same folders.

## Millennium vs Decky vs gamescope

- **gamescope** is the session compositor. Neither Millennium nor Decky patches it.
- **Decky** targets Game Mode Quick Access (Deck-style plugins).
- **Millennium** mods the Steam client (CSS/JS + Lua plugin backends), including
  Big Picture / GamepadUI themes with some caveats. It is **not** a gamescope
  Lua runtime.
- Do **not** stack Decky and Millennium casually - both inject into Steam and
  can fight each other.

## Manual install

```sh
sh ~/.local/share/hyperwebster/nonsteam-gaming/install-nonsteam-gaming.sh
hyperwebster-install-heroic
hyperwebster-install-steam-rom-manager
# experimental:
hyperwebster-install-decky
hyperwebster-install-millennium
```

## Credit

- [Heroic Games Launcher](https://heroicgameslauncher.com/)
- [Steam ROM Manager](https://github.com/SteamGridDB/steam-rom-manager) (SteamGridDB)
- [Decky Loader](https://github.com/SteamDeckHomebrew/decky-loader)
- [Millennium](https://steambrew.app/) (SteamClientHomebrew)
