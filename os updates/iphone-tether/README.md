# iPhone USB tethering (omatether)

Vendors [28allday/omatether](https://github.com/28allday/omatether) for HyperWebster OS.

HyperWebster uses **NetworkManager** for Wi-Fi/ethernet. omatether uses
**systemd-networkd** for the `ipheth` iPhone NIC only. The install script:

1. Marks `ipheth` unmanaged in NetworkManager
2. Ships `/etc/systemd/network/10-iphone-tether.network`
3. Enables `systemd-networkd` alongside NM
4. Adds a kitty launcher entry + Hyprland float rule (no Walker / Elephant)

## Usage

```sh
omatether                 # gum TUI
omatether pair            # Trust the iPhone
omatether status
omatether priority high   # prefer tether over ethernet/wifi
```

Alias: `hyperwebster-tether`.

## Additions toggle

Settings → Additions → **iPhone USB Tether** runs the install script and prints
pairing hints. Requires `usbmuxd`, `libimobiledevice`, `gum`, `usbutils`
(bundled in the ISO offline repo).
