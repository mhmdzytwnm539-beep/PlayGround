#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
CAPTURE_URL="${CAPTURE_URL:-}"
CAPTURE_DIR="${CAPTURE_DIR:-}"
if [ -z "$CAPTURE_URL" ]; then
  echo "capture.sh: CAPTURE_URL is required" >&2
  exit 1
fi
if [ -z "$CAPTURE_DIR" ]; then
  echo "capture.sh: CAPTURE_DIR is required" >&2
  exit 1
fi
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p test -n "$CAPTURE_URL"
/usr/bin/time -p node --version
RUNNER_TMP="${RUNNER_TEMP:-/tmp}"
/usr/bin/time -p mkdir -p "$RUNNER_TMP"
HELPER_PATH="$RUNNER_TMP/fracture-capture.mjs"
/usr/bin/time -p tee "$HELPER_PATH" >/dev/null <<'NODEJS'
import { readFileSync, mkdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { createRequire } from 'node:module';
const url = process.env.CAPTURE_URL, output = process.env.CAPTURE_DIR;
if (!url || !output) { console.error('Set CAPTURE_URL and CAPTURE_DIR.'); process.exit(1); }
mkdirSync(output, { recursive: true });
const runtime = join(process.env.HOME || '/home/runner', '.local/share/omgithub-playwright');
const req = createRequire(join(runtime, 'wip-screenshots.cjs'));
const { chromium } = req('playwright');
let cfg = { browser: { launchOptions: {} } };
try { cfg = JSON.parse(readFileSync(join(runtime, 'linux.json'), 'utf8')); } catch {}
if (process.platform === 'linux') {
  try { process.env.DISPLAY ||= ':' + readFileSync(join(runtime, 'display'), 'utf8').trim(); } catch {}
}
const transient = (e) => { throw Object.assign(e instanceof Error ? e : new Error(String(e)), { exitCode: 75 }); };
const defect = (msg) => { throw Object.assign(new Error(msg), { exitCode: 1 }); };
let browser;
try {
  try {
    browser = await chromium.launch({ ...(cfg.browser?.launchOptions || {}), timeout: 30000 });
  } catch (e) { console.error('browser launch failed:', e?.message || e); transient(e); }
  for (const [name, width, height] of [['desktop', 1440, 900], ['mobile', 390, 844]]) {
    let page;
    try { page = await browser.newPage({ viewport: { width, height } }); }
    catch (e) { console.error('newPage failed:', e?.message || e); transient(e); }
    page.setDefaultTimeout(30000);
    page.on('pageerror', (e) => console.error('pageerror:', e?.message || e));
    let response;
    try { response = await page.goto(url, { waitUntil: 'load', timeout: 45000 }); }
    catch (e) { console.error(`goto ${name} failed:`, e?.message || e); transient(e); }
    const status = response?.status();
    if (!response || !response.ok()) {
      const transientCodes = [408, 429, 500, 502, 503, 504];
      if (!status || transientCodes.includes(status)) { console.error(`HTTP ${status} loading preview (transient)`); transient(new Error(`HTTP ${status} loading preview`)); }
      else { console.error(`HTTP ${status} loading preview (defect)`); defect(`HTTP ${status} loading preview`); }
    }
    try { await page.locator('body').waitFor({ state: 'visible', timeout: 15000 }); }
    catch (e) { console.error('body not visible:', e?.message || e); defect('rendering defect: body not visible'); }
    try { await page.waitForFunction(() => document.fonts.status === 'loaded', null, { timeout: 10000 }); } catch {}
    // Try to auto-start game if a Start/Play button exists (exact English label), else continue with menu view.
    try {
      const cand = page.locator('button, input[type="button"], input[type="submit"], [role="button"]');
      const n = await cand.count();
      for (let i = 0; i < Math.min(n, 20); i++) {
        const el = cand.nth(i);
        let label = '';
        try { label = ((await el.getAttribute('aria-label')) || (await el.textContent()) || '').trim(); } catch { continue; }
        if (/^(?:start|play)(?:\s+(?:game|now))?$/i.test(label)) {
          try { await el.click({ timeout: 2000, noWaitAfter: true }); console.log(`auto-start clicked: ${label}`); } catch {}
          break;
        }
      }
    } catch {}
    try { await page.waitForTimeout(1500); } catch (e) { transient(e); }
    const dest = join(output, `final-${name}.png`);
    try { await page.screenshot({ path: dest, timeout: 30000 }); }
    catch (e) {
      console.error(`screenshot ${name} failed:`, e?.message || e);
      if (e?.name === 'TimeoutError' || !browser.isConnected()) transient(e);
      throw Object.assign(e, { exitCode: 1 });
    }
    try {
      const st = statSync(dest);
      if (st.size < 5000) defect(`rendering defect: ${dest} too small (${st.size} bytes)`);
    } catch (e) { if (e.exitCode) throw e; defect(`rendering defect: missing ${dest}`); }
    console.log(`captured ${name}: ${dest}`);
    await page.close().catch(() => {});
  }
} catch (e) { console.error(e?.message || e); process.exitCode = e?.exitCode || 1; }
finally { try { await browser?.close(); } catch (e) { console.error('browser close:', e?.message || e); process.exitCode ||= 75; } }
NODEJS
# fix helper path variable typo above: move file into place
if [ -f "$RUNNER_TMP/fracture-capture.mjs" ]; then
  /usr/bin/time -p test -f "$RUNNER_TMP/fracture-capture.mjs"
else
  /usr/bin/time -p ls -la "$RUNNER_TMP"
  echo "capture.sh: failed to write helper script (defect)" >&2
  exit 1
fi
/usr/bin/time -p node "$RUNNER_TMP/fracture-capture.mjs"
status=$?
/usr/bin/time -p ls -lh "$CAPTURE_DIR"
/usr/bin/time -p test -f "$CAPTURE_DIR/final-desktop.png"
/usr/bin/time -p test -f "$CAPTURE_DIR/final-mobile.png"
if [ $status -ne 0 ]; then
  exit $status
fi
echo "capture done: $CAPTURE_DIR"
