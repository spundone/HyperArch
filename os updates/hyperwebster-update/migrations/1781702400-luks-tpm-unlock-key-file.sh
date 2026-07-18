#!/usr/bin/env bash
# Migration: fix TPM enroll helper (use --unlock-key-file, not bogus --unlock-passphrase).
set -euo pipefail
: "${HYPERWEBSTER_SRC:?HYPERWEBSTER_SRC must point at the HyperWebster source root}"
SRC="$HYPERWEBSTER_SRC/luks-tpm-unlock"
[ -d "$SRC" ] || exit 0
sudo sh "$SRC/install-luks-tpm-unlock.sh"
