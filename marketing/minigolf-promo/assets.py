#!/usr/bin/env python3
"""
Macht aus den Simulator-Screenshots die Datei `assets.js` fuer den Film.

    python3 assets.py shots/01-setup.png shots/02-scoring.png shots/03-ergebnis.png

Warum eine eigene Datei: `engine.js` soll eine reine Zeichenfunktion bleiben.
Die Bilder liegen deshalb als Data-URLs in `assets.js`, das sowohl der
Node-Renderer als auch der HTML-Player vor dem ersten Frame laedt.

Die Screenshots werden auf die Groesse skaliert, in der sie im Film wirklich
erscheinen (mal 2 fuer Schaerfe) — ungeschrumpfte 1206x2622-PNGs blaehen den
HTML-Player sonst auf mehrere Megabyte auf.
"""
import base64
import io
import pathlib
import sys

from PIL import Image

TARGET_W = 660          # 2x der Darstellungsbreite im Film (330 px)

here = pathlib.Path(__file__).parent
paths = [pathlib.Path(p) for p in sys.argv[1:]]
if not paths:
    sys.exit("Aufruf: python3 assets.py <screenshot.png> ...")

entries = []
for i, p in enumerate(paths):
    img = Image.open(p).convert("RGB")
    w, h = img.size
    img = img.resize((TARGET_W, round(h * TARGET_W / w)), Image.LANCZOS)
    buf = io.BytesIO()
    # Die App-Oberflaeche ist flaechig, PNG mit reduzierter Palette bleibt
    # scharf und deutlich kleiner als JPEG-Artefakte auf dunklem Grund.
    img.convert("P", palette=Image.ADAPTIVE, colors=192).save(buf, format="PNG", optimize=True)
    data = base64.b64encode(buf.getvalue()).decode("ascii")
    entries.append((p.stem, img.size, data))
    print(f"  {p.name}: {w}x{h} -> {img.size[0]}x{img.size[1]}, {len(data)/1024:.0f} KB base64")

js = ["/* Generiert von assets.py — nicht von Hand bearbeiten. */",
      "(function (root, factory) {",
      "  if (typeof module === 'object' && module.exports) module.exports = factory();",
      "  else root.PROMO_ASSETS = factory();",
      "})(typeof self !== 'undefined' ? self : this, function () {",
      "  'use strict';",
      "  return {",
      "    shots: ["]
for name, (w, h), data in entries:
    js.append(f"      {{ name: '{name}', w: {w}, h: {h},")
    js.append(f"        src: 'data:image/png;base64,{data}' }},")
js += ["    ]", "  };", "});", ""]

out = here / "assets.js"
out.write_text("\n".join(js), encoding="utf-8")
print(f"{out.name}  {out.stat().st_size/1024:.0f} KB  ({len(entries)} Screens)")
