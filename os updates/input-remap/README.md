# Input remap (keyd + gum TUI)

Remap **keyboard and mouse buttons** system-wide with [keyd](https://github.com/rvaiya/keyd)
(official Arch `extra` package). Works on Hyprland, other Wayland compositors, X11, and the TTY.

HyperWebster wraps it in a **gum** TUI that matches the live installer look.

## Open

| | |
|--|--|
| Key | `Super+Ctrl+I` (floating kitty) |
| CLI | `hyperwebster-input-remap` |
| Additions | Settings → Additions → Input remap |

## Features

- Keyboard presets (Caps→Esc, Caps Ctrl/Esc overload, swap Alt/Super, disable Caps, …)
- Mouse side-button wizard (`m:vid:pid` + btn → action)
- Device list + live key/button monitor (`keyd monitor`)
- Edit `/etc/keyd/hyperwebster.conf`, reload, start/stop daemon

## Notes

- Wildcard `[ids] *` matches **keyboards only**. Mice must be listed explicitly (`m:046d:…`).
- Mouse support in keyd is experimental; if the pointer breaks, clear remaps from the TUI.
- Hyprland binds (`bind = …`) are separate - this tool remaps at the **evdev** level.

## Credit

keyd by [rvaiya](https://github.com/rvaiya/keyd). Gum TUI styled after Omarchy / HyperWebster installers.
