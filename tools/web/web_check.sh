#!/usr/bin/env bash
# Web export of the demo, driven in real Chrome: a Shift+click (heavy hit: trauma up, time scale 0,
# back to 1), a tap and a second finger (two hits, no doubled mouse emulation), 0 console errors,
# and 72 frames for the preview GIF. Needs GODOT (4.7.1 + web templates), Google Chrome, ffmpeg and
# PN_PLAYWRIGHT pointing at playwright-core's index.mjs. Copyright (c) 2026 PN Scripts. MIT licence.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/build/web-check"
rm -rf "$OUT" && mkdir -p "$OUT/out" "$OUT/frames"
mkdir -p "$OUT/project" && cp -r "$ROOT/addons" "$ROOT/demo" "$ROOT/project.godot" "$OUT/project/"
[ -f "$ROOT/icon.svg" ] && cp "$ROOT/icon.svg" "$OUT/project/" || true
cp "$ROOT/tools/web/web_probe.gd" "$ROOT/tools/web/export_presets.cfg" "$OUT/project/"
printf '\n[autoload]\n\nWebProbe="*res://web_probe.gd"\n' >> "$OUT/project/project.godot"
(cd "$OUT/project" && { "${GODOT:-godot}" --headless --import >/dev/null 2>&1 || true; "${GODOT:-godot}" --headless --export-release "Web" ../out/index.html >/dev/null; })
python3 -m http.server 8494 --bind 127.0.0.1 --directory "$OUT/out" >/dev/null 2>&1 & SRV=$!
trap 'kill $SRV' EXIT
sleep 1
node "$ROOT/tools/web/check.mjs" "$OUT/frames"
ffmpeg -y -loglevel error -framerate 15 -i "$OUT/frames/frame-%03d.png" -vf "scale=640:-1:flags=lanczos,palettegen=max_colors=96" "$OUT/palette.png"
ffmpeg -y -loglevel error -framerate 15 -i "$OUT/frames/frame-%03d.png" -i "$OUT/palette.png" -lavfi "scale=640:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=4" "$OUT/preview-demo.gif"
echo "preview: $OUT/preview-demo.gif"
