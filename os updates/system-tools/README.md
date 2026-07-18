# system-tools - Settings page for account photo and system apps

Adds **Settings → System tools** with:

| Section | Actions |
|---------|---------|
| Account | Change / reset profile photo (`~/.face`) - circular crop on lock + dashboard |
| Drives | List secondary disks, remount now, ignore/include for boot automount |
| Display & input | hyprmoncfg, keyboard/mouse remap, pavucontrol, Bluetooth |
| System | CachyOS kernel manager, btop, snapshots, maintenance menu |

## Install

```sh
sh ~/.local/share/hyperwebster/system-tools/install-system-tools.sh
```

Or via `hyperwebster-update` migration. Then **Ctrl+Super+Alt+R**.

## Drives

Requires `hyperwebster-drives` from the `drive-automount` component. Tap a drive
row to ignore or include it; use **Remount data drives now** after hot-plug or
to refresh exFAT/NTFS `uid=`/`gid=` for Steam.

## Lock screen

`lockscreen-polish` clips the avatar to a circle and prefers `~/.face` over the
Starman mark when a photo is set.
