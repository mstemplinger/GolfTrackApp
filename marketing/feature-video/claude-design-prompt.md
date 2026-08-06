# Prompt für Claude Design — Erklärvideo „Positions-Tracking"

Alles ab der Trennlinie in Claude Design einfügen.

---

Erstelle ein kurzes, animiertes Erklärvideo für die iOS-App **GolfTrack**, das das neue
Feature „Positions-Tracking" zeigt. Format **1080 × 1920 (9:16, Instagram Reel/Story)**,
Länge **rund 30 Sekunden**, 30 fps, Endlos-Loop mit sauberem Übergang vom letzten zum
ersten Frame. Sprache: **Deutsch**. Kein Voice-over, alles über Text und Bewegung.

## Design-System (bitte exakt einhalten, das ist das echte App-Theme)

Dunkelgrün, satt, hochwertig — keine hellen Hintergründe, kein Weiß als Fläche.

| Rolle | Hex |
|---|---|
| Hintergrund (tiefstes Grün) | `#0E2718` |
| Karte | `#163421` |
| Karte, Variante | `#1C4129` |
| Karte, dunkel | `#112D1C` |
| Akzent Gold (CTA, Highlights) | `#C9A035` |
| Gold gedrückt | `#A27F27` |
| Grün mittel | `#28824B` |
| Grün dunkel | `#1C6138` |
| Text primär | `#FFFFFF` |
| Text sekundär | Weiß 60 % |
| Text tertiär | Weiß 40 % |
| Warnung | `#E08A3C` |

- Schrift: **SF Pro / -apple-system**, sonst Inter. Headlines fett und eng
  (`letter-spacing: -0.02em`), Fließtext normal, Labels in Versalien mit weitem Sperrsatz.
- Karten: Radius **16 px**, Buttons Radius **14 px**, keine Schlagschatten, stattdessen
  Flächenkontrast und dünne Linien in Weiß 8 %.
- Gold ist knapp einzusetzen: Akzentlinien, aktive Zustände, genau ein CTA.
- Icons im Stil von SF Symbols (dünn, geometrisch), keine Emoji.
- Farbige Loch-Segmente auf der Karte in dieser Reihenfolge:
  `#3385F5`, `#F5851F`, `#38C761`, `#C74DF5`, `#F54747`, `#1ACCC7`, `#D9B333`.

## Inhalt — sechs Kapitel

**Intro (0–3 s)**
Wortmarke „GolfTrack" klein oben, Pille „Neu" in Gold. Headline groß: „Positions-Tracking".
Unterzeile: „Wie aus deiner Laufspur die Geometrie des Platzes entsteht."

**01 — Aufzeichnen (3–8,5 s)**
Kapitellabel „01 — AUFZEICHNEN" in Gold. Headline: „Die Runde zeichnet sich selbst auf."
Text: „Alle paar Meter ein GPS-Punkt — nur während einer laufenden Runde."
Chips: „~2.500 Punkte / 18 Loch", „≈ 70 KB".
Animation: In einer dunklen Kartenfläche zeichnet sich eine leicht schlingernde Laufspur
über einen 9-Loch-Rundkurs, von unten links nach oben und im Bogen zurück. Am
zeichnenden Ende ein pulsierender goldener Punkt.

**02 — Zuordnen (8,5–13 s)**
Label „02 — ZUORDNEN". Headline: „Jeder Punkt kennt sein Loch."
Text: „Die App weiß beim Lochwechsel Bescheid — die Spur wird live segmentiert, nicht
nachträglich geraten."
Animation: Die fertige Spur färbt sich Segment für Segment in die Loch-Farben ein,
kleine Labels „1" … „9" tauchen an den Segmenten auf.

**03 — Ableiten (13–19,5 s)**
Label „03 — ABLEITEN". Headline: „Stillstand verrät Abschlag und Grün."
Text: „Der erste lange Stillstand eines Lochs ist der Abschlag, der letzte das Grün.
Jede weitere Runde macht die Schätzung enger."
Animation: Kamera zoomt weich auf ein einzelnes Loch. Zwei weitere, blassere Laufspuren
derselben Bahn blenden ein (weitere Runden). An Abschlag und Grün erscheinen je drei
Einzelschätzungen als Punkte, die zu einem Mittelwert zusammenlaufen; ein gestrichelter
Streukreis schrumpft dabei. Am Ende stehen ein Abschlag-Marker (Quadrat) und ein
Grün-Marker mit goldener Fahne, dazwischen eine gestrichelte Achse.

**04 — Prüfen (19,5–24 s)**
Label „04 — PRÜFEN". Headline: „Du behältst das letzte Wort."
Text: „Jeder Vorschlag zeigt seine Konfidenz und den Abgleich mit der Scorecard-Länge."
Animation: Kartenliste im App-Stil, Zeilen staffeln sich von unten ein:
- Loch 3 · Badge „Konfidenz hoch" (grün) · „Länge 318 m · Scorecard 325 m · Abweichung 2 %" · Haken in Gold
- Loch 4 · Badge „Konfidenz hoch" · „Länge 164 m · Scorecard 158 m · Abweichung 4 %" · Haken in Gold
- Loch 7 · Badge „Konfidenz niedrig" (orange) · „Länge 212 m · Scorecard 318 m · Abweichung 33 % — auf der Karte prüfen"
Überschrift der Liste: „7 von 9 Löchern ableitbar".

**05 — Ergebnis (24–27,5 s)**
Label „05 — ERGEBNIS". Headline: „Entfernung zur Fahne. Ohne Pin zu setzen."
Animation: Große Zahl zählt von 0 auf **142** hoch, Einheit „m" kleiner daneben,
darunter „zur Fahne · Loch 4". Trennlinie, dann Zeile „Die Laufspur verlässt dein
iPhone nie. Löschbar mit einem Tap."

**Outro (27,5–30 s)**
Headline: „Alles bleibt auf dem iPhone." Unterzeile: „Einstellungen → Positions-Tracking
aktivieren." Wortmarke „GolfTrack" und „golftrack.app".

## Aufbau jedes Kapitels

Dreiteiliges, festes Raster, damit nichts springt:
oben Wortmarke + Pille, in der Mitte der Textblock (Kapitellabel, Headline, Fließtext,
optional Chips), darunter die Bühne mit Karte oder Liste, unten fünf Fortschrittspunkte,
die nacheinander in Gold umschlagen, plus „golftrack.app".

## Motion

- Ein- und Ausblenden über Deckkraft plus 30 px Versatz nach oben, `ease-out`, 500 ms.
- Nie mehr als eine Bewegung gleichzeitig im Vordergrund.
- Die Karte bleibt zwischen Kapitel 01 bis 03 stehen und wird nur weitergebaut —
  nicht neu einblenden.
- Kein Blinken, kein harter Schnitt, keine Zoom-Sprünge.

## Vorgaben

- Alles selbst enthalten: reines HTML/CSS/SVG mit JS-Animation, keine externen
  Schriften, Bibliotheken oder Bilder, kein Netzwerkzugriff.
- Steuere die Animation über eine Funktion `seek(t)` mit t in Sekunden, damit sich
  einzelne Frames deterministisch rendern lassen — keine CSS-Transitions.
- Keine erfundenen Zahlen über die oben genannten hinaus, keine Vergleiche mit
  anderen Apps, keine Versprechen zu Genauigkeit in Metern.
- Wenn kein Videoexport möglich ist: als animierte Seite ausliefern, die in einer
  Endlosschleife läuft und sich abfilmen lässt.
