# Caelestia config repair

Resets broken `~/.config/caelestia` / scheme state to HyperWebster glass defaults
after migration cascades leave light-mode Nexus, wrong bar fonts, or flat blur.

## Why Nexus goes white

`services.smartScheme` defaults to **true**. A bright wallpaper then makes
`caelestia wallpaper` pick **light** Material You (HCT tone > 60). Nexus fills
with `m3surface` (~white). Setting only `"mode": "dark"` while leaving a light
colour map still looks broken.

This repair kills the shell first, forces `smartScheme=false`, writes a **full
dark** scheme seed (not mode-only), re-applies the wallpaper with `--no-smart`,
then stamps the dark seed again last so nothing races it back to light.

## Usage

```bash
hyperwebster-caelestia-repair           # soft: dark seed + smartScheme off + glass + blur
hyperwebster-caelestia-repair --hard    # also rewrite shell.json / shell-tokens from defaults
hyperwebster-caelestia-repair --keep-scheme   # do not replace colour map (mode only)
```

Backups land in `~/.local/state/hyperwebster/caelestia-repair-<timestamp>/`.

Does **not** delete wallpapers under `~/Pictures/Wallpapers/` or user-named schemes
under `~/.local/share/caelestia/schemes/`.

## What it fixes

| Symptom | Fix |
|---------|-----|
| White Wallpaper & style | Full dark scheme seed + smartScheme false + wallpaper --no-smart |
| Bar glyphs show as "A" | JetBrainsMono NF in shell.json + Theme.qml patch |
| Flat / no frost bar | `hyperwebster-blur-toggle enable` + Colours/Theme patches |
| Missing / corrupt shell.json | Create or `--hard` rewrite from defaults |
