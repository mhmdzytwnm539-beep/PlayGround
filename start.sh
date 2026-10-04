#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-3000}"
/usr/bin/time -p pwd
PROJECT_ROOT="$(/usr/bin/time -p pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$DIST_DIR" "$WEB_DIR"
if /usr/bin/time -p test -f "$PROJECT_ROOT/package.json"; then
  echo "package.json found: installing dependencies"
  if /usr/bin/time -p test -f "$PROJECT_ROOT/package-lock.json"; then
    /usr/bin/time -p npm ci --no-audit --no-fund
  else
    /usr/bin/time -p npm install --no-audit --no-fund
  fi
  if /usr/bin/time -p npm run --silent build --if-present; then
    echo "build step completed (if present)"
  fi
fi
if /usr/bin/time -p test ! -f "$DIST_DIR/index.html"; then
  if /usr/bin/time -p test -f "$PROJECT_ROOT/index.html"; then
    echo "copying index.html to dist/"
    /usr/bin/time -p cp "$PROJECT_ROOT/index.html" "$DIST_DIR/index.html"
  else
    echo "Static deployment output must contain index.html." >&2
    exit 1
  fi
fi
/usr/bin/time -p test -f "$DIST_DIR/index.html"
/usr/bin/time -p python3 -c 'import json,sys; json.dump({"project":sys.argv[1],"directory":sys.argv[2]}, open(sys.argv[3],"w"))' "$PROJECT_ROOT" "$DIST_DIR" "$WEB_DIR/deployment-output.json"
/usr/bin/time -p cat "$WEB_DIR/deployment-output.json"
echo "serving $DIST_DIR on port $PORT"
/usr/bin/time -p python3 -m http.server "$PORT" --directory "$DIST_DIR" --bind 0.0.0.0
