# hypersmooth-display - 120/144 Hz UI tuning

Tuned **Hyprland** animation curves and **caelestia shell** token durations for
high-refresh displays. Ships OOB on fresh installs; safe to delete the sourced
fragment to revert Hyprland-side changes.

## What changes

- Shorter Hyprland animation multipliers (~2-3 frames at 144 Hz)
- `shell-tokens.json` `animDurations` scaled for snappier Quickshell transitions
- (Hyprland 0.55+ no longer exposes `misc:vfr`; VFR is the default)

## Files

- `hypr-hypersmooth.conf` - Hyprland misc + animations block
- Installed under `~/.local/share/hyperwebster/hypersmooth-display/`

## Note

Apply `hyprmoncfg apply tv-gaming-4k` for 4K144 HDR output (see `tv-gaming-display`).
