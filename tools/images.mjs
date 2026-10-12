#!/usr/bin/env node
// Godot Asset Library icon (square, PNG) and preview images (rendered by tools/render.mjs).
import { icon, banner, slide, esc } from './brand.mjs';
const code = `<span style="color:#5d6762"># Camera2D
#  └ Shake    (WallopLiteShake2D)
# HitStop     (WallopLiteHitStop)</span>

func _on_enemy_hit(heavy: bool) -> void:
    $Camera2D/Shake.add_trauma(0.9 if heavy else 0.45)
    $HitStop.freeze(0.12 if heavy else 0.05)

<span style="color:#5d6762"># shake = trauma ^ 2, linear decay, seeded noise
# freeze restores your own Engine.time_scale afterwards</span>`;
export default [
  { out: 'listing/icon-256.png', width: 256, height: 256, html: icon(256, 'W') },
  { out: 'listing/preview-code-1280x720.png', width: 1280, height: 720, html: slide(1280, 720, { kicker: 'Two nodes, two lines', title: 'Camera shake and hit-stop for Godot 4', body: code }) },
  { out: 'listing/banner-1280x640.png', width: 1280, height: 640, html: banner(1280, 640, { name: 'Wallop Lite', tagline: 'Trauma camera shake (2D and 3D) and hit-stop for Godot 4.', chips: ['Shake 2D', 'Shake 3D', 'Hit-stop', 'Deterministic', 'MIT'], glyph: 'W', kicker: 'Free Godot addon' }) }
];
