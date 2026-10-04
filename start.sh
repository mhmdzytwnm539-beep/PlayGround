#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)"
export PROJECT_DIR
DIST="$PROJECT_DIR/dist"
export DIST
PORT="${PORT:-3000}"
DIST="$PROJECT_DIR/dist"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$DIST" "$WEB_DIR"
/usr/bin/time -p test -f "$PROJECT_DIR/index.html"
/usr/bin/time -p cp -f "$PROJECT_DIR/index.html" "$DIST/index.html"
if [ -f "$PROJECT_DIR/style.css" ]; then
  /usr/bin/time -p cp -f "$PROJECT_DIR/style.css" "$DIST/style.css"
fi
if [ -f "$PROJECT_DIR/package.json" ]; then
  /usr/bin/time -p npm install --prefix "$PROJECT_DIR" --no-audit --no-fund
  if /usr/bin/time -p node -e "const p=require(process.env.PROJECT_DIR+'/package.json');process.exit(p.scripts&&p.scripts.build?0:1)"; then
    /usr/bin/time -p npm run --prefix "$PROJECT_DIR" build
  fi
fi
/usr/bin/time -p test -f "$DIST/index.html"
/usr/bin/time -p node -e "const fs=require('fs');const path=require('path');const web=process.env.OPENCODE_WEB_DIR||'/home/runner/work/_temp/omgithub-web';fs.mkdirSync(web,{recursive:true});fs.writeFileSync(path.join(web,'deployment-output.json'),JSON.stringify({project:process.env.PROJECT_DIR,directory:process.env.DIST}));console.log('wrote deployment-output.json');"
/usr/bin/time -p cat "$WEB_DIR/deployment-output.json"
/usr/bin/time -p echo "Serving $DIST on port $PORT"
/usr/bin/time -p python3 --version
exec python3 -m http.server "$PORT" --directory "$DIST"
