# drawer-stacking

Fixes the top dashboard (and other interactive drawers) drawing **under** nsbar
popouts / nspanels and sibling drawer surfaces.

## Issue

Caelestia drawers normally sit on the Hyprland `Top` layer. The notifications /
status popouts (`nspanels`) use `Overlay`. When the dashboard opens from the top
edge, it can appear buried under those panels.

Within the drawers surface itself, the dashboard wrapper also needed a higher
`z` so launcher / popouts in the same window do not cover it.

## Fix

1. **`ContentWindow.qml`** - promote the drawers `WlrLayershell` to `Overlay`
   while dashboard, launcher, session, or sidebar is open (or fullscreen
   overlay is active). Comment marker: `HyperWebster: promote`.
2. **`Panels.qml`** - raise the dashboard wrapper `z` to `500` while the
   dashboard is visible.
3. **Hyprland `layerrule` order** in `~/.config/caelestia/hypr-user.conf`
   (marked `# >>> hyperwebster-drawer-stack >>>`) so `caelestia-drawers` sorts
   above `nspanels` / `nsbar` within the same layer.

## Apply

```sh
sh install-drawer-stacking.sh
# or via hyperwebster-update migration
```

Then **Ctrl+Super+Alt+R** (or log out/in).

`patch-drawer-stacking.sh` is re-run by a pacman hook after upgrades of
`hyperwebster-shell`, `caelestia-shell`, or `nosignal-shell`. Set
`HYPERWEBSTER_SKIP_SHELL_PATCH=1` when the fork already bakes these files.
