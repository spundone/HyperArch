# session-power

Makes the Caelestia / Hyprland session menu (Super+Escape) **Shut down** /
**Reboot** / **Hibernate** buttons actually power the machine.

## Why

Caelestia's `SessionManager` intercepts `poweroff` / `systemctl poweroff` and
issues a logind `PowerOff` D-Bus call. It reports success before the call
finishes. If polkit cannot prompt or an inhibitor blocks, the click is a
silent no-op (no fallback).

HyperWebster points the session buttons at `hyperwebster-session-power`, which
SessionManager does not claim, so Quickshell runs `systemctl … -i` directly.

## Commands

| Menu button | Command |
|---|---|
| Logout | `hyperwebster-session-power logout` (`uwsm stop`) |
| Shut down | `hyperwebster-session-power shutdown` |
| Reboot | `hyperwebster-session-power reboot` |
| Hibernate | `hyperwebster-session-power hibernate` |

Wired in `~/.config/caelestia/shell.json` → `session.commands`.
