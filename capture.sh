#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
RUNTIME="${RUNTIME_DIR:-/home/runner/work/_temp/omgithub-runtime}"
if /usr/bin/time -p test -z "${CAPTURE_URL:-}"; then
  echo "Set CAPTURE_URL and CAPTURE_DIR." >&2
  exit 1
fi
if /usr/bin/time -p test -z "${CAPTURE_DIR:-}"; then
  echo "Set CAPTURE_URL and CAPTURE_DIR." >&2
  exit 1
fi
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p test -f "$RUNTIME/scripts/default-capture.mjs"
/usr/bin/time -p node "$RUNTIME/scripts/default-capture.mjs"
