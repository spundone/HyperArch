# Caelestia config repair

Resets broken `~/.config/caelestia` / scheme state to HyperWebster glass defaults
after migration cascades leave light-mode Nexus, wrong bar fonts, or flat blur.

## Usage

```bash
hyperwebster-caelestia-repair           # soft: dark + glass + fonts + blur + restart
hyperwebster-caelestia-repair --hard    # also rewrite shell.json / shell-tokens from defaults
hyperwebster-caelestia-repair --reseed-scheme   # replace scheme.json with dark shadotheme seed
```

Backups land in `~/.local/state/hyperwebster/caelestia-repair-<timestamp>/`.

Does **not** delete wallpapers under `~/Pictures/Wallpapers/` or user-named schemes
under `~/.local/share/caelestia/schemes/` unless you pass `--reseed-scheme` (only
replaces active `scheme.json`).

## What it fixes

| Symptom | Fix |
|---------|-----|
| White Wallpaper & style | Force `scheme.json` mode=dark; disable smartScheme |
| Bar glyphs show as "A" | JetBrainsMono NF in shell.json + Theme.qml patch |
| Flat / no frost bar | `hyperwebster-blur-toggle enable` + Colours/Theme patches |
| Missing / corrupt shell.json | Create or `--hard` rewrite from defaults |
