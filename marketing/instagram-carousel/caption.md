# Caption für den Carousel-Post (Update 2.2)

Reihenfolge der Slides: `out/slide-01.png` … `out/slide-06.png`

---

## Caption

Neu in GolfTrack 2.2: Dein Weg über den Platz 🏌️

Die App kann jetzt aufzeichnen, wo du während der Runde unterwegs warst – und daraus lernen, wie die Löcher liegen.

Wie das funktioniert:

📍 Laufspur – alle paar Meter ein Punkt. Nach der Runde siehst du deinen Weg auf der Karte, Loch für Loch.

⛳️ Abschlag & Grün – am Abschlag wartest du, am Grün puttest du. Aus dem ersten und letzten längeren Stillstand pro Loch schätzt die App beide Positionen. Danach steht die Entfernung zur Fahne von selbst da, ohne dass du den Pin setzen musst.

🟡 Fairway-Verlauf – alle Messpunkte werden auf die Achse Abschlag→Grün projiziert und in 10-Meter-Abschnitte geteilt. Der Median ergibt die Mittellinie, das 10.–90. Perzentil den Korridor. Doglegs kommen dabei von selbst heraus.

Und weil es um Standortdaten geht, ganz klar gesagt: Die Aufzeichnung ist standardmäßig aus. Du schaltest sie selbst ein, sie läuft nur während einer Runde, die Daten bleiben auf deinem iPhone und du kannst sie jederzeit löschen.

Ehrlich bleibt ehrlich: Der Fairway-Verlauf ist eine Schätzung, kein Platzplan. Eine Gehspur ist nicht das Fairway – man läuft zu seinem Ball, über Wege und ins Rough. Je mehr Runden aufgezeichnet sind, desto genauer wird es. Deshalb zeigt die App pro Loch an, wie belastbar die Schätzung ist.

Was würdest du damit zuerst anschauen? 👇

---

## Hashtags

#golftrack #golfapp #golfdeutschland #golfen #golfplatz #golfrunde #birdie #fairway
#golflife #golfliebe #golftraining #handicap #golfclub #iphoneapp #appstore #golfbayern
#golfsport #golferleben #neuesupdate #gpsgolf

---

## Erster Kommentar (optional, hält die Caption kürzer)

Technisch dahinter: Die Punkte liegen gepackt in der App, rund 70 KB pro Runde. Die
Ableitung läuft komplett auf dem Gerät – kein Server, keine Übertragung. Wer es
ausschalten will, findet den Schalter in Profil → Positions-Tracking, dort lassen sich
auch alle Aufzeichnungen mit einem Tipp löschen.

---

## Vor dem Posten prüfen

- **Zeitpunkt:** Slide 6 sagt „kommt in den nächsten Tagen". Erst **nach** der Freigabe
  im App Store mit `RELEASED=1 node generate.mjs` neu rendern, dann steht dort
  „ist im App Store". Vorher wäre die andere Formulierung falsch.
- **Slides 2, 3 und 5 sind Diagramme, keine Screenshots.** Sie erklären das Verfahren,
  geben aber nicht vor, App-Oberfläche zu sein. Slide 4 ist ein echter Screenshot.
- **Nach der Testrunde** lohnt es, die Diagramme durch echte Screenshots der Laufspur
  und des Fairway-Verlaufs zu ersetzen: Screenshot in `shots/` legen, Slide von
  `kind: "diagram"` auf `kind: "shot"` umstellen.
