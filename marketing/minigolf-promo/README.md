# GolfTrack · Werbefilm für Minigolf-Anlagen

20,0 s · 720×1280 (9:16) · 30 fps · dunkler Neon-Look.

## Dateien
- `golftrack-minigolf-20s.mp4` – fertiger Film **mit Ton**
- `golftrack-minigolf-20s-stumm.mp4` – dieselbe Bildspur ohne Ton (für Feeds, die stumm autoplayen)
- `golftrack-minigolf-20s.html` – Player zum Scrubben, Ton eingebettet (eine Datei, offline lauffähig)
- `engine.js` – die gesamte Animation, eine reine Funktion `drawFrame(ctx, t)`
- `render.js` – Frame-Renderer (resumierbar)
- `score.py` – die Tonspur, komplett synthetisiert
- `score.wav` / `score.mp3` – gerenderte Tonspur
- `build_html.py` – setzt Player aus `engine.js` + `score.mp3` zusammen

## Beat-Sheet
| Zeit | Shot | Inhalt |
|---|---|---|
| 0,00–4,20 | LIT-FORM | Bleistift-Silhouette auf glühendem Baldachin · „ZETTEL." / „BLEISTIFT." / „Das war einmal." |
| 4,20–7,40 | SHOCKWAVE + WORDMARK-SNAP | violette Druckwelle, GOLFTRACK snappt weiß · „Die digitale Scorekarte" |
| 7,40–11,60 | QUERY-PILL | „Bahn 7 · 3 Schläge" / „8 Spieler, 1 Karte" / „Sieger steht fest" |
| 11,60–15,60 | SLAB-RING | acht Glaskacheln öffnen sich (u. a. durchgestrichener Zettel) · „Alles im Handy." |
| 15,60–20,00 | HERO-PEEL + SYMBOL-MORPH | Kachel zentriert, Scorekarte wird zur Fahne · „App laden, losspielen. Fertig." |

Farbbogen: warm (das Alte) → violett (Marke) → elektrisch (Bedienung) → violett → magenta (Finale).

## Neu rendern
```bash
npm i @napi-rs/canvas
node render.js frames all 0 150 & node render.js frames all 150 300 & \
node render.js frames all 300 450 & node render.js frames all 450 600 & wait
node render.js frames missing            # muss missing:0 melden
ffmpeg -y -framerate 30 -i frames/f_%04d.png -c:v libx264 -pix_fmt yuv420p \
  -crf 18 -preset medium -movflags +faststart golftrack-minigolf-20s.mp4
```

Texte und Timing stehen oben in `engine.js` (`BRAND`, `TIMELINE`). Nach einer
Änderung nur den betroffenen Frame-Bereich löschen und neu rendern.

## Ton

Komplett synthetisiert (numpy/scipy) statt Stock-Material — damit gibt es keine
Lizenzfrage und jedes Ereignis sitzt exakt auf dem Bildschnitt. Die Zeiten in
`score.py` sind aus `engine.js` abgelesen.

- **Fläche**: Akkordbogen entlang des Farbbogens — Am (dumpf, das Papier) → F → C → G → Am (aufgelöst)
- **Puls**: Achtel ab dem Marken-Snap, fällt zum Finale weg
- **Impacts**: auf jedem der vier Schnitte, Riser davor
- **Ticks**: synchron zu jedem getippten Zeichen, auch in den Pills
- **Dings**: auf den Häkchen und den acht Kacheln

Gemessen: **−14,0 LUFS integriert**, **−1,57 dBTP**, LRA 3,4 LU. Alle vier
Schnitte und der Wortmarken-Snap liegen bei 0 ms Versatz.

`alimiter` von ffmpeg taugte dafür nicht: die Option `level` ist per Default an
und hebt den Pegel nach dem Limiten wieder auf den Zielwert, das Limit greift
also nie. `score.py` bringt deshalb einen eigenen Look-ahead-Limiter mit, der die
nötige Absenkung auf dem **4-fach überabgetasteten** Signal bestimmt — die
Klick-Anteile erzeugen sonst Inter-Sample-Spitzen rund 1,9 dB über dem Sample-Peak.

```bash
python3 score.py score.wav
ffmpeg -y -i score.wav -c:a libmp3lame -b:a 128k score.mp3
ffmpeg -y -i golftrack-minigolf-20s-stumm.mp4 -i score.wav \
  -c:v copy -c:a aac -b:a 192k -movflags +faststart -shortest golftrack-minigolf-20s.mp4
python3 build_html.py
```
