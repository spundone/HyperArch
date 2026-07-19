# gamepad-wakeup - resume from sleep with a controller

Enables USB host-controller wakeup and keeps gamepads out of USB autosuspend
so a button press can wake the machine from **s2idle** (the default on
HyperWebster).

## Limits

Many Xbox-layout pads (including GameSir in X-Input mode) do **not** advertise
USB remote wakeup. They cannot wake from **deep** (`mem_sleep=deep`) suspend;
use s2idle (default), or wake with the keyboard/power button from deep sleep.

## Install

```sh
sh install-gamepad-wakeup.sh   # needs sudo once
```

Applies a udev rule plus `/usr/local/bin/hyperwebster-gamepad-wakeup`.
