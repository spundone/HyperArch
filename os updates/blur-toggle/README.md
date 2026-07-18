# blur-toggle - optional frosted glass

HyperWebster can run a **flat** desktop (no blur) or Raycast-style frosted
panels. The NoSignal top bar is a Wayland layer with namespace **`nsbar`**
(popouts: **`nspanels`**). Blur layerrules must match those names — older
`caelestia-.*` rules never blurred the bar.

## Usage

```sh
hyperwebster-blur-toggle enable    # blur + transparency (rounding is separate)
hyperwebster-blur-toggle disable   # restore flat opaque panels
hyperwebster-blur-toggle toggle
hyperwebster-blur-toggle status
```

Touches:

- `~/.config/caelestia/hypr-vars.conf` - `$blurEnabled`, opacity
- `~/.config/caelestia/shell.json` - transparency block
- `~/.config/quickshell/overview/config.json` - overview glass
- `~/.config/caelestia/hypr-user.conf` - `nsbar` / `nspanels` layer blur rules
- `/etc/xdg/quickshell/caelestia/services/Colours.qml` - shell-driven blur keywords

State: `~/.local/state/hyperwebster/blur-enabled`

After enabling, restart the shell if needed: **Ctrl+Super+Alt+R**.
