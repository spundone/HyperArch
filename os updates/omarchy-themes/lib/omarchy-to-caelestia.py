#!/usr/bin/env python3
"""Convert Omarchy colors.toml (or accent hex) into a caelestia scheme .txt pack."""
from __future__ import annotations

import argparse
import colorsys
import re
import sys
from pathlib import Path


def strip_hash(h: str) -> str:
    h = h.strip().strip('"').strip("'")
    if h.startswith("#"):
        h = h[1:]
    return h.upper()


def parse_toml_colors(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = strip_hash(val)
        if re.fullmatch(r"[0-9A-Fa-f]{6}", val):
            out[key] = val
    return out


def luminance(hex6: str) -> float:
    r, g, b = int(hex6[0:2], 16) / 255, int(hex6[2:4], 16) / 255, int(hex6[4:6], 16) / 255
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def mix(a: str, b: str, t: float) -> str:
    def ch(h: str, i: int) -> int:
        return int(h[i : i + 2], 16)

    out = []
    for i in (0, 2, 4):
        v = int(round(ch(a, i) * (1 - t) + ch(b, i) * t))
        out.append(f"{max(0, min(255, v)):02X}")
    return "".join(out)


def contrast_on(bg: str) -> str:
    return "F5F5F5" if luminance(bg) < 0.45 else "1A1A1A"


def build_scheme(c: dict[str, str], mode: str | None = None) -> dict[str, str]:
    bg = c.get("background", "1A1B26")
    fg = c.get("foreground", "C0CAF5")
    accent = c.get("accent", c.get("color4", "7AA2F7"))
    cursor = c.get("cursor", fg)
    sel_bg = c.get("selection_background", accent)
    sel_fg = c.get("selection_foreground", bg)

    terms = [c.get(f"color{i}", mix(bg, fg, i / 15)) for i in range(16)]
    secondary = c.get("color2", terms[2] if len(terms) > 2 else accent)
    tertiary = c.get("color5", terms[5] if len(terms) > 5 else accent)
    error = c.get("color1", terms[1] if len(terms) > 1 else "F7768E")
    success = secondary

    if mode is None:
        mode = "light" if luminance(bg) > 0.55 else "dark"

    surface = mix(bg, fg, 0.06 if mode == "dark" else 0.04)
    surface_bright = mix(bg, fg, 0.14 if mode == "dark" else 0.10)
    surface_dim = mix(bg, "000000" if mode == "dark" else "FFFFFF", 0.25)
    outline = mix(bg, fg, 0.35)
    outline_var = mix(bg, fg, 0.22)

    on_bg = fg
    on_primary = contrast_on(accent)
    on_secondary = contrast_on(secondary)
    on_tertiary = contrast_on(tertiary)
    on_error = contrast_on(error)
    on_success = contrast_on(success)

    primary_c = mix(accent, bg, 0.55)
    secondary_c = mix(secondary, bg, 0.55)
    tertiary_c = mix(tertiary, bg, 0.55)
    error_c = mix(error, bg, 0.55)
    success_c = mix(success, bg, 0.55)

    roles = {
        "primary_paletteKeyColor": accent,
        "secondary_paletteKeyColor": secondary,
        "tertiary_paletteKeyColor": tertiary,
        "neutral_paletteKeyColor": bg,
        "neutral_variant_paletteKeyColor": surface,
        "background": bg,
        "onBackground": on_bg,
        "surface": surface,
        "surfaceDim": surface_dim,
        "surfaceBright": surface_bright,
        "surfaceContainerLowest": mix(bg, "000000" if mode == "dark" else "FFFFFF", 0.35),
        "surfaceContainerLow": mix(bg, fg, 0.08),
        "surfaceContainer": mix(bg, fg, 0.10),
        "surfaceContainerHigh": mix(bg, fg, 0.14),
        "surfaceContainerHighest": mix(bg, fg, 0.18),
        "onSurface": on_bg,
        "surfaceVariant": mix(bg, fg, 0.12),
        "onSurfaceVariant": mix(fg, bg, 0.25),
        "inverseSurface": on_bg,
        "inverseOnSurface": bg,
        "outline": outline,
        "outlineVariant": outline_var,
        "shadow": "000000",
        "scrim": "000000",
        "surfaceTint": accent,
        "primary": accent,
        "onPrimary": on_primary,
        "primaryContainer": primary_c,
        "onPrimaryContainer": accent,
        "inversePrimary": mix(accent, fg, 0.35),
        "secondary": secondary,
        "onSecondary": on_secondary,
        "secondaryContainer": secondary_c,
        "onSecondaryContainer": secondary,
        "tertiary": tertiary,
        "onTertiary": on_tertiary,
        "tertiaryContainer": tertiary_c,
        "onTertiaryContainer": tertiary,
        "error": error,
        "onError": on_error,
        "errorContainer": error_c,
        "onErrorContainer": error,
        "primaryFixed": mix(accent, "FFFFFF", 0.35),
        "primaryFixedDim": accent,
        "onPrimaryFixed": bg,
        "onPrimaryFixedVariant": mix(bg, accent, 0.3),
        "secondaryFixed": mix(secondary, "FFFFFF", 0.35),
        "secondaryFixedDim": secondary,
        "onSecondaryFixed": bg,
        "onSecondaryFixedVariant": mix(bg, secondary, 0.3),
        "tertiaryFixed": mix(tertiary, "FFFFFF", 0.35),
        "tertiaryFixedDim": tertiary,
        "onTertiaryFixed": bg,
        "onTertiaryFixedVariant": mix(bg, tertiary, 0.3),
        "success": success,
        "onSuccess": on_success,
        "successContainer": success_c,
        "onSuccessContainer": on_bg,
        "rosewater": mix(fg, accent, 0.15),
        "flamingo": mix(fg, error, 0.2),
        "pink": mix(tertiary, fg, 0.2),
        "mauve": tertiary,
        "red": error,
        "maroon": mix(error, bg, 0.2),
        "peach": c.get("color3", terms[3]),
        "yellow": c.get("color3", terms[3]),
        "green": secondary,
        "teal": c.get("color6", terms[6]),
        "sky": c.get("color4", accent),
        "sapphire": mix(accent, secondary, 0.4),
        "blue": accent,
        "lavender": tertiary,
        "klink": accent,
        "klinkSelection": sel_bg,
        "kvisited": tertiary,
        "kvisitedSelection": mix(tertiary, bg, 0.4),
        "knegative": error,
        "knegativeSelection": error_c,
        "kneutral": c.get("color3", terms[3]),
        "kneutralSelection": mix(c.get("color3", terms[3]), bg, 0.4),
        "kpositive": success,
        "kpositiveSelection": success_c,
        "text": on_bg,
        "subtext1": mix(fg, bg, 0.2),
        "subtext0": mix(fg, bg, 0.35),
        "overlay2": outline,
        "overlay1": outline_var,
        "overlay0": mix(bg, fg, 0.28),
        "surface2": mix(bg, fg, 0.12),
        "surface1": surface,
        "surface0": bg,
        "base": bg,
        "mantle": surface_dim,
        "crust": mix(bg, "000000" if mode == "dark" else "FFFFFF", 0.4),
        "cursor": cursor,
        "selectionBackground": sel_bg,
        "selectionForeground": sel_fg,
    }
    for i, t in enumerate(terms):
        roles[f"term{i}"] = t
    return roles


def write_scheme_txt(path: Path, roles: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"{k} {v}" for k, v in roles.items()]
    path.write_text("\n".join(lines) + "\n")


def convert_toml_file(toml_path: Path, out_root: Path, name: str, flavour: str = "default") -> str:
    c = parse_toml_colors(toml_path.read_text())
    if not c:
        raise SystemExit(f"no colours in {toml_path}")
    mode = "light" if luminance(c.get("background", "000000")) > 0.55 else "dark"
    roles = build_scheme(c, mode)
    write_scheme_txt(out_root / name / flavour / f"{mode}.txt", roles)
    return mode


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("toml", type=Path, help="Omarchy colors.toml")
    ap.add_argument("-o", "--out", type=Path, required=True, help="schemes root (…/schemes)")
    ap.add_argument("-n", "--name", required=True, help="scheme directory name")
    ap.add_argument("-f", "--flavour", default="default")
    args = ap.parse_args()
    mode = convert_toml_file(args.toml, args.out, args.name, args.flavour)
    print(f"wrote {args.out / args.name / args.flavour / (mode + '.txt')}")


if __name__ == "__main__":
    main()
