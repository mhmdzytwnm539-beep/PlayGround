#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
/usr/bin/time -p pwd
if [ -z "${CAPTURE_URL:-}" ] || [ -z "${CAPTURE_DIR:-}" ]; then
  echo "Set CAPTURE_URL and CAPTURE_DIR." >&2
  exit 1
fi
/usr/bin/time -p echo "capturing URL: $CAPTURE_URL -> $CAPTURE_DIR"
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
if [ -n "${RUNTIME_DIR:-}" ] && [ -f "$RUNTIME_DIR/scripts/default-capture.mjs" ]; then
  /usr/bin/time -p node "$RUNTIME_DIR/scripts/default-capture.mjs"
  status=$?
  /usr/bin/time -p ls -la "$CAPTURE_DIR"
  /usr/bin/time -p test -f "$CAPTURE_DIR/final-desktop.png"
  /usr/bin/time -p test -f "$CAPTURE_DIR/final-mobile.png"
  exit $status
fi
echo "RUNTIME_DIR default-capture.mjs not found, using playwright-cli fallback" >&2
/usr/bin/time -p playwright-cli --help >/dev/null
SESSION="capture-$$"
/usr/bin/time -p playwright-cli -s="$SESSION" open "$CAPTURE_URL" || exit 75
/usr/bin/time -p playwright-cli -s="$SESSION" eval "document.fonts.status" || exit 75
/usr/bin/time -p sleep 2
/usr/bin/time -p playwright-cli -s="$SESSION" resize 1440 900 || exit 1
/usr/bin/time -p playwright-cli -s="$SESSION" screenshot --filename="$CAPTURE_DIR/final-desktop.png" || exit 75
/usr/bin/time -p playwright-cli -s="$SESSION" resize 390 844 || exit 1
/usr/bin/time -p playwright-cli -s="$SESSION" screenshot --filename="$CAPTURE_DIR/final-mobile.png" || exit 75
/usr/bin/time -p playwright-cli -s="$SESSION" close || true
/usr/bin/time -p test -f "$CAPTURE_DIR/final-desktop.png"
/usr/bin/time -p test -f "$CAPTURE_DIR/final-mobile.png"
