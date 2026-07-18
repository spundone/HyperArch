# limine-menu-simplify

Keeps the Limine boot menu to two primary entries:

1. **HyperWebster · hyperarch (Arch Linux)** - UKI desktop (default)
2. **Starman (Gaming / Steam)** - same UKI with `hyperwebster.starman=1`

**Snapshots** still appear when limine-snapper has any. Manual kernel fallbacks,
the nested auto `HyperWebster` group clutter, and the in-menu **EFI fallback**
row are removed. Firmware can still boot `\EFI\BOOT\BOOTX64.EFI` on disk; that
path is just not listed inside Limine.

## Apply on an installed system

```sh
sudo sh ~/.local/share/hyperwebster/limine-menu-simplify/simplify-limine-menu.sh
# or via hyperwebster-update (migration)
hyperwebster-update
```

Recovery if the UKI is missing: boot a Snapshots entry (if present) or the live USB.
