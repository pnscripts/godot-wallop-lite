// Copyright (c) 2026 PN Scripts. MIT licence.
// Wallop Lite web export in Chrome: clicks and two-finger taps, probe output, frames for the preview GIF.
const { chromium } = await import(process.env.PN_PLAYWRIGHT || 'playwright-core');
const out = process.argv[2];
const b = await chromium.launch({ channel: 'chrome', headless: true, args: ['--enable-unsafe-swiftshader', '--use-angle=swiftshader', '--ignore-gpu-blocklist'] });
const ctx = await b.newContext({ viewport: { width: 1280, height: 720 }, hasTouch: true });
const page = await ctx.newPage();
const logs = []; page.on('console', (m) => logs.push(m.text())); page.on('pageerror', (e) => logs.push('PAGEERROR ' + e));
await page.goto('http://127.0.0.1:8494/index.html');
for (let i = 0; i < 120 && !logs.some((l) => l.startsWith('PROBE')); i++) await page.waitForTimeout(500);
await page.waitForTimeout(1000);
const probes = (from) => logs.slice(from).filter((l) => l.startsWith('PROBE')).map((l) => Object.fromEntries(l.slice(6).split(' ').map((kv) => kv.split('=')).map(([k, v]) => [k, +v])));
// 1) A mouse click: one hit, trauma up, a short freeze, time scale back to 1.
let mark = logs.length;
await page.keyboard.down('Shift');
await page.mouse.click(900, 300);
await page.keyboard.up('Shift');
await page.waitForTimeout(700);
let p = probes(mark);
const click = { hits: Math.max(...p.map((x) => x.hits)), maxTrauma: Math.max(...p.map((x) => x.trauma)), minScale: Math.min(...p.map((x) => x.scale)), endScale: p.at(-1).scale, maxOffset: Math.max(...p.map((x) => x.offset)) };
// 2) A tap and a second finger: two hits (light, then heavy), none doubled by mouse emulation.
const cdp = await ctx.newCDPSession(page);
mark = logs.length;
await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 900, y: 300, id: 0 }] });
await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 900, y: 300, id: 0 }, { x: 980, y: 320, id: 1 }] });
await page.waitForTimeout(60);
await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
await page.waitForTimeout(900);
p = probes(mark);
const tap = { hits: p.at(-1).hits, maxTrauma: Math.max(...p.map((x) => x.trauma)), endScale: p.at(-1).scale };
// 3) Frames for the preview: three hits, 24 frames each.
let n = 0;
for (const heavy of [false, true, false]) {
  if (heavy) await page.keyboard.down('Shift');
  await page.mouse.click(900, 300);
  if (heavy) await page.keyboard.up('Shift');
  for (let i = 0; i < 24; i++) { await page.screenshot({ path: `${out}/frame-${String(n++).padStart(3, '0')}.png` }); }
}
console.log(JSON.stringify({ click, tap, errors: logs.filter((l) => /error/i.test(l)).slice(0, 5) }));
await b.close();
