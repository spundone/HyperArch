# additions-extra (Settings → Additions: 7 new items)

Merges seven items into `additions.json` (8 → 15 items).

Adds seven curated optional apps to Settings → Additions. All follow the
manifest policy (**official repos `[extra]`/`[omarchy]`, or official upstream
installers - no AUR, no Flatpak**) and are **GPU-agnostic** in wording and
behaviour (so they're correct on AMD boxes too).

| id | name | source | notes |
|----|------|--------|-------|
| `ollama` | Ollama | `[extra]` | install picks `ollama-cuda` (NVIDIA) / `ollama-rocm` (AMD) / `ollama` (CPU) by detecting the GPU vendor via `lspci` - stays agnostic |
| `lmstudio` | LM Studio | `[omarchy]` | `lmstudio-bin` (Provides/Conflicts `lmstudio`) |
| `dropbox` | Dropbox | `[omarchy]` | daemon + cli + nautilus-dropbox; enables the user service; links account on first start |
| `tailscale` | Tailscale | `[extra]` | installs + enables `tailscaled`; user runs `sudo tailscale up` |
| `pinta` | Pinta | `[omarchy]` | Paint.NET-style image editor |
| `kdenlive` | Kdenlive | `[extra]` | video editor; hardware-accelerated export via ffmpeg |
| `pi` | Pi Coding Agent | `curl pi.dev/install.sh` | AI coding-agent CLI, same family as claude-code/codex/opencode |

## Files
- `additions.json` - the **full merged manifest** (15 items) for the builder to
  ship as the canonical Settings→Additions manifest.
- `merge-additions.sh` - idempotent merge of the 7 new items (by id) into an
  already-installed system's manifest (skips ones already present). No root.
- `migrations/1781449200-additions-extra.sh` - delegates to it.

## Builder integration
Replace the layer's `additions-installer/additions.json` with the bundled
15-item file (or cherry-pick the 7 new entries). The merge script covers
already-installed machines on `hyperwebster-update`.

## Icon note
Icons are Material Symbol **names** looked up in nosignal-shell `Glyphs.qml`
(Nerd Font codepoints). Prefer names already in that map (`movie_edit`,
`robot_2`, `sports_esports`, …). Unmapped names show as `?` in Settings.
