#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
/usr/bin/time -p pwd
PROJECT_ROOT="$(pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
PORT="${PORT:-3000}"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$DIST_DIR" "$WEB_DIR"
/usr/bin/time -p test -f "$PROJECT_ROOT/index.html"
/usr/bin/time -p cp "$PROJECT_ROOT/index.html" "$DIST_DIR/index.html"
/usr/bin/time -p test -f "$DIST_DIR/index.html"
if [ -f "$PROJECT_ROOT/package.json" ]; then
  /usr/bin/time -p npm install --no-audit --no-fund
  /usr/bin/time -p npm run build --if-present
else
  /usr/bin/time -p echo "no package.json: static site, skipping npm install/build"
fi
/usr/bin/time -p python3 -c "import json,os,pathlib; root='$PROJECT_ROOT'; d='$DIST_DIR'; w=os.environ.get('OPENCODE_WEB_DIR','/home/runner/work/_temp/omgithub-web'); pathlib.Path(w).mkdir(parents=True,exist_ok=True); open(w+'/deployment-output.json','w').write(json.dumps({'project':root,'directory':d}))"
/usr/bin/time -p cat "$WEB_DIR/deployment-output.json"
echo "Serving $DIST_DIR on PORT=$PORT (project=$PROJECT_ROOT)"
/usr/bin/time -p python3 -m http.server "$PORT" --directory "$DIST_DIR" --bind 0.0.0.0
