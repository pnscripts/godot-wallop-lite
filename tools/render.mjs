#!/usr/bin/env node
// Renders store images at exact pixel sizes with headless Google Chrome.
// Usage: node render.mjs spec.mjs  (spec default-exports [{ out, width, height, html }])
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

const spec = (await import(pathToFileURL(path.resolve(process.argv[2])).href)).default;
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'storeimg-'));
for (const item of spec) {
  const html = path.join(tmp, 'page.html');
  fs.writeFileSync(html, `<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;width:${item.width}px;height:${item.height}px;overflow:hidden}</style></head><body>${item.html}</body></html>`);
  const png = path.join(tmp, 'shot.png');
  fs.rmSync(png, { force: true });
  execFileSync(process.env.CHROME || 'google-chrome', ['--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-first-run', '--no-default-browser-check',
    `--user-data-dir=${path.join(tmp, 'profile')}`, '--force-device-scale-factor=1', `--window-size=${item.width},${item.height}`, `--screenshot=${png}`, pathToFileURL(html).href], { stdio: 'ignore' });
  fs.mkdirSync(path.dirname(item.out), { recursive: true });
  // Crop to the exact size (Chrome can add pixels on some builds) and convert by extension.
  execFileSync('convert', [png, '-crop', `${item.width}x${item.height}+0+0`, '+repage', ...(item.out.endsWith('.jpg') ? ['-quality', '90', '-background', 'white', '-flatten'] : []), item.out]);
  const got = execFileSync('identify', ['-format', '%wx%h', item.out]).toString();
  if (got !== `${item.width}x${item.height}`) throw new Error(`${item.out}: ${got}`);
  console.log(item.out.replace(process.cwd() + '/', ''), got);
}
fs.rmSync(tmp, { recursive: true, force: true });
