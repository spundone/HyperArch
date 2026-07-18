# drive-automount - premount data drives at boot

On boot, discovers **non-system** block devices with a supported filesystem and
mounts them under `/mnt/<label>` (or `/mnt/disk-<uuid8>` when unlabeled).

## Behaviour

- Writes `/etc/fstab.d/99-hyperwebster-automount.conf` (regenerated each boot).
- Uses `nofail` and `x-systemd.device-timeout=5` so a missing drive never blocks boot.
- Runs **before** SDDM / the display manager so Starman and gamescope see
  `/mnt/...` when the session starts.
- Skips: root, `/boot`, `/home`, snapshots, log subvolumes, swap, LUKS headers,
  loop/sr/zram, EFI vfat partitions, and UUIDs listed in
  `/etc/hyperwebster/drive-automount-ignore`.
- Supported types: `ext4`, `btrfs`, `xfs`, `vfat` (non-EFI), `exfat`, `ntfs`/`ntfs3`, `f2fs`.
- **exFAT / vfat / NTFS** mount with `uid=`/`gid=` of the primary desktop user
  (wheel member preferred) so Steam can write library metadata under `/mnt/...`.

Install `ntfs-3g` / `exfatprogs` from the repos if you attach NTFS/exFAT game libraries.

### Steam libraries

Point Steam at the stable path (e.g. `/mnt/games/SteamLibrary`), not a
session-specific `/run/media/...` path. Re-add the folder in Steam after the
first remount if you previously used a different mountpoint.

**exFAT caveat:** no real symlinks - fine for game payloads; Proton prefixes /
`compatdata` are more reliable on ext4 or btrfs.

## UI

Settings → **System tools** → **Drives** lists disks, remounts, and
ignore/include. Additions → **Secondary drive automount** is the master
enable/disable for the systemd unit.

## Files

```
hyperwebster-drive-automount          -> /usr/local/bin
hyperwebster-drives                   -> /usr/local/bin (status / remount / ignore)
hyperwebster-drive-automount.service  -> /etc/systemd/system
install-drive-automount.sh            idempotent installer (sudo)
```

## Manual refresh

```sh
sudo hyperwebster-drive-automount
# or
hyperwebster-drives remount
hyperwebster-drives status --json
```
