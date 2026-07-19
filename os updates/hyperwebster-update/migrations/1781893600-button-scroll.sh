#!/usr/bin/env bash
# 1781893600-button-scroll.sh — middle-button hold-to-scroll (broken wheel).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
sh "$HYPERWEBSTER_SRC/button-scroll/install-button-scroll.sh"
