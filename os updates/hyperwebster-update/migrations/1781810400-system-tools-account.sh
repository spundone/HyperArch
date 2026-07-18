#!/usr/bin/env bash
# Migration: Settings → System tools + circular lock avatar / ~/.face.
set +e
: "${HYPERWEBSTER_SRC:?}"

if [ -d "$HYPERWEBSTER_SRC/lockscreen-polish" ]; then
  sh "$HYPERWEBSTER_SRC/lockscreen-polish/install-lockscreen-polish.sh" || true
fi

if [ -d "$HYPERWEBSTER_SRC/system-tools" ]; then
  # Prefer direct page patch (avoids hw_install_file abort).
  if [ -f "$HYPERWEBSTER_SRC/system-tools/patch-system-tools-page.sh" ]; then
    sudo sh "$HYPERWEBSTER_SRC/system-tools/patch-system-tools-page.sh" || true
  fi
  sh "$HYPERWEBSTER_SRC/system-tools/install-system-tools.sh" || true
fi

echo ":: System tools + circular lock avatar - Ctrl+Super+Alt+R, then Settings → System tools"
exit 0
