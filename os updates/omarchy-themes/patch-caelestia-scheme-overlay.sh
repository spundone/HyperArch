#!/bin/sh
# patch-caelestia-scheme-overlay.sh — let caelestia discover user schemes in
# ~/.local/share/caelestia/schemes (Omarchy / custom theme installs).
# Idempotent. Runs as root (installer or pacman hook).
set -eu

SCHEME_PY=${SCHEME_PY:-}
PATHS_PY=${PATHS_PY:-}

# Locate installed caelestia utils (any python version).
if [ -z "$SCHEME_PY" ] || [ -z "$PATHS_PY" ]; then
  for d in /usr/lib/python3.*/site-packages/caelestia/utils \
           /usr/lib/python3.*/site-packages/caelestia/utils; do
    for cand in $d; do
      [ -f "$cand/scheme.py" ] && [ -f "$cand/paths.py" ] || continue
      SCHEME_PY=$cand/scheme.py
      PATHS_PY=$cand/paths.py
      break 2
    done
  done
fi

if [ -z "${SCHEME_PY:-}" ] || [ ! -f "$SCHEME_PY" ]; then
  echo "caelestia-cli not found — skipping scheme overlay patch"
  exit 0
fi

python3 - "$PATHS_PY" "$SCHEME_PY" <<'PY'
import pathlib, sys

paths_py = pathlib.Path(sys.argv[1])
scheme_py = pathlib.Path(sys.argv[2])
marker = "HYPERWEBSTER_SCHEME_OVERLAY"

paths_txt = paths_py.read_text()
if marker not in paths_txt:
    needle = "scheme_data_dir: Path = cli_data_dir / \"schemes\""
    if needle not in paths_txt:
        print("WARNING: paths.py shape changed — overlay skipped", file=sys.stderr)
        sys.exit(0)
    insert = (
        needle
        + "\n"
        + f"# {marker}\n"
        + "user_scheme_data_dir: Path = c_data_dir / \"schemes\"\n"
    )
    paths_py.write_text(paths_txt.replace(needle, insert, 1))
    print(f":: patched {paths_py} (user_scheme_data_dir)")
else:
    print(f":: {paths_py.name} already has overlay")

scheme_txt = scheme_py.read_text()
if marker in scheme_txt:
    print(f":: {scheme_py.name} already has overlay")
    sys.exit(0)

# Broaden imports
old_imp = "from caelestia.utils.paths import atomic_dump, scheme_data_dir, scheme_path"
new_imp = (
    "from caelestia.utils.paths import atomic_dump, scheme_data_dir, scheme_path, user_scheme_data_dir  # "
    + marker
)
if old_imp not in scheme_txt:
    print("WARNING: scheme.py import shape changed — overlay skipped", file=sys.stderr)
    sys.exit(0)
scheme_txt = scheme_txt.replace(old_imp, new_imp, 1)

helpers = f'''

# {marker}
def _scheme_roots():
    roots = []
    try:
        if user_scheme_data_dir.is_dir():
            roots.append(user_scheme_data_dir)
    except NameError:
        pass
    roots.append(scheme_data_dir)
    return roots


def _resolve_scheme_file(name: str, flavour: str, mode: str):
    for root in _scheme_roots():
        p = (root / name / flavour / mode).with_suffix(".txt")
        if p.is_file():
            return p
    return (scheme_data_dir / name / flavour / mode).with_suffix(".txt")

'''

# Insert helpers before class Scheme
if "class Scheme:" not in scheme_txt:
    print("WARNING: Scheme class missing — overlay skipped", file=sys.stderr)
    sys.exit(0)
scheme_txt = scheme_txt.replace("class Scheme:", helpers + "class Scheme:", 1)

# Patch get_colours_path
old_gcp = '''    def get_colours_path(self) -> Path:
        return (scheme_data_dir / self.name / self.flavour / self.mode).with_suffix(".txt")'''
new_gcp = '''    def get_colours_path(self) -> Path:
        return _resolve_scheme_file(self.name, self.flavour, self.mode)'''
if old_gcp in scheme_txt:
    scheme_txt = scheme_txt.replace(old_gcp, new_gcp, 1)
else:
    print("WARNING: get_colours_path shape changed", file=sys.stderr)

old_names = '''def get_scheme_names() -> list[str]:
    return [*(f.name for f in scheme_data_dir.iterdir() if f.is_dir()), "dynamic"]'''
new_names = '''def get_scheme_names() -> list[str]:
    names: set[str] = set()
    for root in _scheme_roots():
        if root.is_dir():
            names.update(f.name for f in root.iterdir() if f.is_dir())
    ordered = sorted(names)
    if "dynamic" not in ordered:
        ordered.append("dynamic")
    return ordered'''
if old_names in scheme_txt:
    scheme_txt = scheme_txt.replace(old_names, new_names, 1)
else:
    print("WARNING: get_scheme_names shape changed", file=sys.stderr)

old_flav = '''    return (
        ["default", "hard"] if name == "dynamic" else [f.name for f in (scheme_data_dir / name).iterdir() if f.is_dir()]
    )'''
new_flav = '''    if name == "dynamic":
        return ["default", "hard"]
    flavours: set[str] = set()
    for root in _scheme_roots():
        d = root / name
        if d.is_dir():
            flavours.update(f.name for f in d.iterdir() if f.is_dir())
    return sorted(flavours)'''
if old_flav in scheme_txt:
    scheme_txt = scheme_txt.replace(old_flav, new_flav, 1)
else:
    print("WARNING: get_scheme_flavours shape changed", file=sys.stderr)

old_modes = '''    if name == "dynamic":
        return ["light", "dark"]
    else:
        return [f.stem for f in (scheme_data_dir / name / flavour).iterdir() if f.is_file()]'''
new_modes = '''    if name == "dynamic":
        return ["light", "dark"]
    modes: set[str] = set()
    for root in _scheme_roots():
        d = root / name / flavour
        if d.is_dir():
            modes.update(f.stem for f in d.iterdir() if f.is_file() and f.suffix == ".txt")
    return sorted(modes)'''
if old_modes in scheme_txt:
    scheme_txt = scheme_txt.replace(old_modes, new_modes, 1)
else:
    print("WARNING: get_scheme_modes shape changed", file=sys.stderr)

scheme_py.write_text(scheme_txt)
print(f":: patched {scheme_py} (user scheme overlay)")
PY
