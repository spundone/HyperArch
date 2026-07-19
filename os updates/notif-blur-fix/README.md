# notif-blur-fix - frosted glass on notification toast cards

Notification popup cards stayed flat (no Hyprland blur) even with transparency
enabled. Dashboard panels frosted correctly.

## Root cause

Hyprland skips blur on pixels whose alpha is at or below `ignore_alpha`.
Caelestia sets that threshold from `transparency.base - 0.03` (about 0.40 when
base is ~0.43 after light-mode adjust, or higher when base is ~0.72).

`Colours.layer(c)` / most `tPalette` container roles use **layer 1**, which
applies `transparency.layers` alpha (about **0.35**). That sits **below**
`ignore_alpha`, so blur never runs on those card pixels.

Layer **0** uses `transparency.base` (about **0.72** / dashboard glass), which
is **above** `ignore_alpha`, so blur applies.

`Notification.qml` used `Colours.tPalette.m3surfaceContainer` (layer 1). Critical
cards used opaque `Colours.palette.m3secondaryContainer` (no frost either).

## Fix

Use layer-0 fills:

```qml
color: root.modelData.urgency === NotificationUrgency.Critical
    ? Colours.layer(Colours.palette.m3secondaryContainer, 0)
    : Colours.layer(Colours.palette.m3surfaceContainer, 0)
```

Utilities `ToastItem.qml` had opaque `Colours.palette.*` backgrounds; those now
use `Colours.layer(..., 0)` the same way so success/warning/error/default toasts
frost too.

## Integration

- **Fork (canonical):** patch
  `modules/notifications/Notification.qml` and
  `modules/utilities/toasts/ToastItem.qml` in the hyperwebster-shell /
  nosignal-shell fork, then rebuild the package.
- **Already-installed boxes:** `sudo sh install-notif-blur-fix.sh` (same-file
  safe; skips when content matches or src/dest resolve to one path). Migration
  `1781865200-notif-blur-fix.sh` runs it via `$HYPERWEBSTER_SRC`.
- Set `HYPERWEBSTER_SKIP_SHELL_PATCH` on ISO/package builds that already bake
  the fork fix.

Shell restart required (`Ctrl+Super+Alt+R`): quickshell often runs with `-n`
(no file watcher).

## Files

- `Notification.qml`, `ToastItem.qml`
- `install-notif-blur-fix.sh`
- Migration: `os updates/hyperwebster-update/migrations/1781865200-notif-blur-fix.sh`
