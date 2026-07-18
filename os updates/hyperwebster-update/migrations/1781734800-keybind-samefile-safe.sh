#!/usr/bin/env bash
# Migration: same-file-safe keybind installer (live layer no longer aborts on cp).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/install-keybinds-help.sh"
