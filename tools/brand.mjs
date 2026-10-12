// Shared PN Scripts store-image templates (Lite editions).
const font = `system-ui, 'DejaVu Sans', sans-serif`;
const mono = `ui-monospace, 'DejaVu Sans Mono', monospace`;
export const C = { ink: '#14211b', green: '#2f7d5b', mint: '#cfe8db', paper: '#f4f6f3', mute: '#5d6762' };

/** Square icon: rounded tile, glyph text, small LITE tag when lite. */
export function icon(size, glyph, accent = C.green, lite = true) {
  const r = Math.round(size * 0.2), pad = size >= 256 ? Math.round(size * 0.06) : 0;
  const tag = lite && size >= 96 ? `<div style="position:absolute;right:${Math.round(size*0.08)}px;bottom:${Math.round(size*0.08)}px;background:#fff;color:${accent};font:800 ${Math.round(size*0.11)}px ${font};padding:${Math.round(size*0.015)}px ${Math.round(size*0.04)}px;border-radius:${Math.round(size*0.04)}px;letter-spacing:.5px">LITE</div>` : '';
  return `<div style="position:absolute;inset:${pad}px;border-radius:${r}px;background:linear-gradient(145deg,${accent},${C.ink});display:flex;align-items:center;justify-content:center;color:#fff;font:800 ${Math.round(size*0.42)}px ${font};letter-spacing:-1px">${glyph}${tag}</div>`;
}

/** Banner / promo tile: name, tagline, bullet chips, PN Scripts byline. */
export function banner(w, h, { name, tagline, chips = [], glyph, accent = C.green, kicker = 'Free · Lite edition' }) {
  const s = Math.min(w / 772, h / 250);
  const k = (n) => Math.max(8, Math.round(n * s));
  return `<div style="position:absolute;inset:0;background:radial-gradient(circle at 85% 20%, ${accent}55, transparent 55%), linear-gradient(120deg, ${C.ink}, #1d3229);color:#fff;font-family:${font}">
  <div style="position:absolute;left:${k(36)}px;top:${k(30)}px;right:${k(220)}px">
    <div style="font:700 ${k(12)}px ${font};letter-spacing:${k(2)}px;text-transform:uppercase;color:${C.mint}">${kicker}</div>
    <div style="font:800 ${k(46)}px ${font};letter-spacing:-1px;margin-top:${k(6)}px">${name}</div>
    <div style="font:400 ${k(17)}px/1.35 ${font};color:#dfeee6;margin-top:${k(8)}px">${tagline}</div>
    <div style="display:flex;flex-wrap:wrap;gap:${k(6)}px;margin-top:${k(14)}px">${chips.map((c) => `<span style="font:600 ${k(12)}px ${font};background:#ffffff1f;border:1px solid #ffffff33;border-radius:${k(20)}px;padding:${k(4)}px ${k(10)}px">${c}</span>`).join('')}</div>
  </div>
  <div style="position:absolute;right:${k(40)}px;top:50%;transform:translateY(-50%);width:${k(150)}px;height:${k(150)}px">${icon(k(150), glyph, accent, false).replace('position:absolute;inset:0px', 'position:absolute;inset:0')}</div>
  <div style="position:absolute;right:${k(40)}px;bottom:${k(12)}px;font:600 ${k(11)}px ${font};color:#b9d3c6">by PN Scripts · pnscripts.com</div>
</div>`;
}

/** Screenshot-style slide: title + a code/terminal or list panel. */
export function slide(w, h, { kicker, title, body, accent = C.green }) {
  const s = w / 1280;
  const k = (n) => Math.round(n * s);
  return `<div style="position:absolute;inset:0;background:${C.paper};color:${C.ink};font-family:${font}">
  <div style="position:absolute;left:${k(56)}px;top:${k(44)}px;right:${k(56)}px">
    <div style="font:700 ${k(15)}px ${font};letter-spacing:${k(2)}px;text-transform:uppercase;color:${accent}">${kicker}</div>
    <div style="font:800 ${k(38)}px/1.15 ${font};margin-top:${k(8)}px;letter-spacing:-.5px">${title}</div>
  </div>
  <div style="position:absolute;left:${k(56)}px;right:${k(56)}px;top:${k(170)}px;bottom:${k(44)}px;border-radius:${k(14)}px;background:#fff;box-shadow:0 ${k(14)}px ${k(40)}px rgba(20,40,30,.14);overflow:hidden;padding:${k(28)}px ${k(34)}px;font:${k(20)}px/1.55 ${mono};white-space:pre;color:#22302a">${body}</div>
</div>`;
}
export const esc = (t) => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
