# button-scroll - middle-button drag-to-scroll

Hold the **middle mouse button** (scroll-wheel click) and move the mouse to
scroll. Useful when the physical scroll wheel is broken or unreliable.

Uses Hyprland / libinput `scroll_method = on_button_down` with button `274`
(`BTN_MIDDLE`). Short middle-clicks still work for paste / middle-click actions.

## Toggle

```sh
hyperwebster-button-scroll-toggle enable
hyperwebster-button-scroll-toggle disable
hyperwebster-button-scroll-toggle status
```

Also: Nexus → Additions → **Middle-button scroll**.

## Options

Edit `~/.local/share/hyperwebster/button-scroll/hypr-button-scroll.conf`:

| Setting | Meaning |
|---------|---------|
| `scroll_button = 274` | Middle button (check with `wev` if different) |
| `scroll_button_lock = true` | Click once to enter scroll mode, click again to leave |
| `scroll_factor` (under `input`) | Scale scroll speed if drag feels too fast/slow |

Then: `hyprctl reload` or re-run `hyperwebster-button-scroll-toggle enable`.
