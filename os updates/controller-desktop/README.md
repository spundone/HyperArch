# controller-desktop - gamepad navigation for Hyprland (Gamescope-like)

Maps an Xbox-layout gamepad to Hyprland / Caelestia actions so the couch / TV
session covers most of `HyperWebster-keybindings.md`. **Does not run under
Starman / gamescope** - Steam Input owns the pad there. While the **session
lock** is up, the pad enters PIN mode.

Hold a modifier for a layer; release it alone for the base action.

## Layers

| Hold | Layer | Release alone |
|------|--------|---------------|
| **Guide** | System / session | Launcher |
| **Select** | Shell (sidebar, clipboard, emoji…) | Dashboard |
| **Start** | Windows (move, float, resize…) | Overview |
| **Y** | Apps & media | Settings |

## Base (no modifier)

| Gamepad | Action |
|---------|--------|
| A / B / X | Enter / Esc / Tab |
| D-pad L / R | Focus window |
| D-pad U / D | Scroll (wheel + ↑/↓), hold to repeat |
| LB / RB | Workspace ± |
| L3 / R3 | Keybinds / fullscreen |
| Right stick | Mouse |
| Guide + left stick | Mouse |
| LT / RT | Right / left click |

## Guide+ (system)

| Chord | Action |
|-------|--------|
| Guide+Start | Starman / gamescope |
| Guide+Select | Session menu |
| Guide+B | Close window |
| Guide+Y | Lock |
| Guide+X | Omarchy / install menu |
| Guide+LB / RB | Screenshot region / output |
| Guide+D-pad U/D | Volume ± |
| Guide+D-pad L/R | Brightness ± |
| Guide+LT / RT | Mute / mic mute |
| Guide+L3 | Suspend |
| Guide+R3 | Fullscreen (bordered) |

## Select+ (shell)

| Chord | Action |
|-------|--------|
| Select+A | Sidebar |
| Select+B | Clear notifications |
| Select+X | Clipboard history |
| Select+Y | Emoji picker |
| Select+Start | Session menu |
| Select+L3 | Night light |
| Select+R3 | Special / scratchpad workspace |
| Select+D-pad | Focus U/D/L/R |
| Select+LT / RT | Paste / Copy |

## Start+ (windows)

| Chord | Action |
|-------|--------|
| Start+D-pad | Move window |
| Start+A | Toggle floating |
| Start+B | Close |
| Start+X | Toggle split |
| Start+Y | Pin window |
| Start+LB / RB | Resize narrower / wider |
| Start+L3 / R3 | Center / fullscreen bordered |
| Start+Select | Toggle group |
| Start+LT / RT | Move window to workspace ± |

## Y+ (apps & media)

| Chord | Action |
|-------|--------|
| Y+A | Terminal |
| Y+B | Browser |
| Y+X | Files |
| Y+Select | Editor |
| Y+Start | Music |
| Y+LB | Activity / sysmon |
| Y+RB | Audio (pavucontrol) |
| Y+L3 | Install menu |
| Y+R3 | To-do |
| Y+D-pad | Media prev / next |
| Y+LT / RT | Play / pause |

## Lock screen (PIN)

Caelestia lock via `qs lock isLocked`. Password via **qs IPC** (not uinput).

| Gamepad | Action |
|---------|--------|
| D-pad or LB/RB | Cycle digit 0–9 |
| A (or X) | Type pending digit |
| B | Backspace |
| Y | Type `0` |
| Start or Guide | Submit |
| Select | Clear |

Edit `~/.local/share/hyperwebster/controller-desktop/profile.json`, then:

```sh
hyperwebster-controller-desktop-toggle restart
```

Extra actions can use `hypr:dispatch args` or `exec:shell…` in the profile.

## Steam / gamescope safety

1. Daemon exits if `gamescope` is running (and clears a *stale*
   `/tmp/.gaming-session-active` left behind by unclean Game Mode exits)
2. `ExecStartPre` also drops that marker when gamescope is already gone
3. While a Steam game / Proton / gamescope window is focused, the daemon
   **releases** the pad grab so Steam Input works for desktop-launched games
4. `switch-to-gaming` stops the user service before SDDM restarts;
   `hyperwebster-exit-gaming` starts it again on the way back to Hyprland

Wake-from-sleep for the pad is handled separately by the `gamepad-wakeup`
layer (USB host wakeup + no pad autosuspend). See that component's README.

## GameSir Cyclone / similar

Linux needs an X-Input (Xbox) compatible interface. Put the pad in Xbox mode
(GameSir: typically hold **Home/Y** or the mode switch until the Xbox LED
pattern appears), then replug. Confirm with:

```sh
python -c "from evdev import list_devices,InputDevice,ecodes
for p in list_devices():
 d=InputDevice(p); k=set(d.capabilities().get(ecodes.EV_KEY,[]))
 if ecodes.BTN_SOUTH in k: print(p, d.name)"
```
