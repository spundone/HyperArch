# nonsteam-gaming - Epic, local libraries, emulators, Decky, Millennium

Gamescope / Starman shows **Steam Game Mode**. Epic, GOG, Amazon, offline
installs, and emulator ROMs are not native SteamUI tabs - they appear as
**Non-Steam** shortcuts that Steam launches inside the same session.

## Additions (Settings → Additions → Gaming)

| Item | What it installs | How it shows in Starman |
|------|------------------|-------------------------|
| **Heroic** | Official Heroic AppImage (user-local; repairs orphan `/opt` installs) | Heroic → Add to Steam (or auto-add) → Non-Steam |
| **Local game library** | `hyperwebster-local-games` CLI | Scan a folder → Non-Steam shortcuts (Proton for `.exe`) |
| **Steam ROM Manager** | Official AppImage → `~/.local/bin/steam-rom-manager` | Parse emulators → Save to Steam → Non-Steam |
| **Decky Loader** | Official Decky `install_release.sh` | Quick Access plugins in Game Mode (experimental) |
| **Millennium** | Official `https://steambrew.app/install.sh` | Steam themes/plugins + Lua backends (experimental) |

Sources policy: official upstream installers / release assets only (no Flatpak).

## Local game library

For owned offline installs (GOG offline, itch, Linux natives) under a stable
path like `/mnt/<label>/Games`:

```sh
hyperwebster-local-games roots add /mnt/sata-ssd/Games
hyperwebster-local-games scan
hyperwebster-local-games import          # writes Steam Non-Steam shortcuts
# Restart Steam / re-enter Starman to refresh tiles
```

Windows `.exe` titles launch through the newest Steam Proton found on the box.
Linux binaries launch directly. Re-run `import` after adding folders.

## Recommended flow

1. Install **Deckify / Chimera** (or DeckShift) so Starman / Super+Shift+S works.
2. **Heroic** on the desktop → log in → enable **Add games to Steam automatically**.
3. Optional: **Local game library** for offline folders; **Steam ROM Manager** for RetroArch.
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

### Decky tab missing in Quick Access

Two common causes on HyperWebster:

1. **Missing CEF marker** — Steam must expose DevTools for Decky inject:
   ```sh
   touch ~/.local/share/Steam/.cef-enable-remote-debugging
   ```
2. **Millennium stacked with Decky** — Millennium replaces `libXtst.so.6` inside
   Steam and Decky then crashes (`SP_JSX is not defined`). They cannot share
   Game Mode. `hyperwebster-install-decky` parks those Millennium hooks.

```sh
hyperwebster-install-decky    # CEF marker + disable Millennium hooks + plugin_loader
```

Then **fully restart Steam** (Power → Exit to Desktop, re-enter Starman — or
`systemctl --user restart steam-launcher`). Open Quick Access with **Guide+X** /
**⋯**; the Decky plug icon is at the bottom of that menu.

`hyperwebster-decky-cef-ensure.service` recreates the CEF marker before each
gamescope Steam start. PluginLoader logs saying `no connected socket` mean Steam
started without the CEF marker.

## Manual install

```sh
sh ~/.local/share/hyperwebster/nonsteam-gaming/install-nonsteam-gaming.sh
hyperwebster-install-heroic
hyperwebster-local-games roots add /mnt/.../Games
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
