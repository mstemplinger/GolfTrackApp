# GolfTrack · „Von Anfang bis Ende dabei“ (onetake, 60 s, 9:16)

Konzept A: **ein goldener Punkt geht den ganzen Weg** – Haken im Quiz → Ball auf der Range → Ball auf der Runde → Ball im App-Icon.
Look: die App-eigenen Farben (Nachtgrün #0d2419, Karten #163421, Gold #c9a035), Inter. UI aus den Screenshots in `marketing/screenshots/de-69` nachgebaut, Quizfragen echt aus `PlatzreifeQuizData.swift` (`quiz.json`).
Musik (ab Entwurf 2): „Mechanism Pilot“ (Tonebox) vom Nutzer, Kopie in `music/` — **nicht ins Repo** (öffentlich). 110 BPM (Beat 0,5455 s).
Track-Drop 87,234 s = Film **19,45 s** (erster Abschlag); Musik ab Film 0 (Track 67,78, Kick ab Film 2,0, Drop 87,234), Pause im Rückschwung (18,9–19,45), Stille während des Putts, auf dem Endbild Schnitt auf dem Taktstrich in das ruhige Outro (Track 314,162 = 416 Beats nach dem Drop, Film B(53)).
Raster: `B(n) = 19,45 + (n + Zusatzbeats)·0,5455`, Zusatzbeats in den Ruhephasen (`STEPS` in comp.html), damit der Film bei 60 s bleibt. Entwurf 1 mit „Body Language“: `comp-v1-bodylanguage.html` / `draft.mp4`.

## Beat-Sheet

| t (s) | Beat | der Punkt | was in den nächsten Beat trägt |
|---|---|---|---|
| 0,6 | Punkt auf Nachtgrün | ploppt auf | der Punkt |
| 1,0–2,6 | „Vom ersten Schritt“ (Ruhe 1,7–2,6) | still | der Punkt |
| 2,75–3,9 | Lernrunde-Fortschrittskarte wächst aus dem Punkt | gleitet zum Haken-Icon | der Punkt als Haken |
| 3,9–6,1 | Kategorie-Chip, Frage „GIR?“ tippt sich, 4 Antworten steigen | ruht | — |
| 6,2–7,5 | zögert auf D, springt auf A → richtig | ist der Cursor, füllt A gold | der Punkt |
| 7,9–9,6 | „Richtig!“ + Erklärung, Ruhe | ruht in A | der Punkt |
| 10,0 | drückt „Nächste Frage“ | Druck | der Punkt |
| 10,35–12,15 | **Burst**: 7 echte Fragen (AUS, Suchzeit, Double Bogey, Eagle, Albatross, Birdie, 18 Löcher), 3→20 von 20 | fährt auf dem Fortschrittsbalken | der Balken |
| 12,55–14,2 | Balken rollt sich zum Ring: 100 % · Prüfungsreife | sitzt am Ringkopf | der Ring |
| 14,6–16,0 | „Lernen.“ – Ruhe | — | der Punkt |
| 16,0–17,6 | Ring zieht sich in den Punkt, der wird zum Ball und fällt auf das Tee | Ball | der Ball |
| 17,75–18,9 | Schlägerwahl, Ball springt auf „Driver“ | Ball | der Ball |
| **19,45** | **Drop**: Abschlag, Flug mit Meterzähler 0→220 m | fliegt | Zähler |
| 23,3–23,85 | Ruhe auf 220 m | liegt | Zähler |
| 23,85–25,1 | Zähler wird zur Karte „Wie weit hast du geschlagen?“, Ball drückt „Schlag speichern“ | Druck | der Ball |
| 25,7–28,2 | **Burst**: je Beat ein Schlag, Liste wächst | hüpft auf dem Knopf | die Liste |
| 28,9–30,7 | Diagramm „Entwicklung“: der Ball zeichnet die Linie | zeichnet | die Karte |
| 31,4–32,6 | „Üben.“ – Ruhe | — | die Karte |
| 32,6–33,9 | Diagrammkarte wird zur Empfehlung „Driver · Ø 215 m“ auf der Live-Scorecard | reist mit | die Karte |
| 33,9–36,4 | Loch „01“, Par 4, „Noch 350 m“ | liegt auf dem Tee | — |
| 36,4 / 39,5 | Abschlag, zweiter Schlag (7 Eisen); Fairway ✓, **GIR ✓ = Green in Regulation** (die Quizfrage) | fliegt | der Ball |
| 42,7–44,5 | Kamera taucht aufs Grün, Putt fällt → **Birdie = 1 unter Par** (die Quizfrage) | rollt, fällt | — |
| 46,4–49,1 | **Burst**: Loch 2–18, Score zählt bis 82 | im Loch | Lochreihe |
| 49,5 | „Spielen.“ | — | der Ball |
| 50,8–53 | Ball springt aus dem Loch, fliegt zum Schluss | fliegt | der Ball |
| 52,7–54 | „Lernen. Üben. Spielen.“ / „Vom ersten Schritt bis zum letzten Putt.“ | — | der Ball |
| 54,9–56 | Ball wird weiß und groß, das App-Icon öffnet sich um ihn | wird Logo-Ball | Ende |
| 55,2–60 | GolfTrack · Jetzt im App Store, still | — | — |
