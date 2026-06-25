# WordPress / WPBakery (Salient) Prompt – GolfTrack Landing Page

Diesen Text komplett in Claude oder ChatGPT einfügen.

---

## PROMPT (zum Einfügen):

---

Erstelle den vollständigen WPBakery Page Builder Shortcode für eine Landing Page der iOS-App **GolfTrack**. Die Ausgabe soll ausschließlich aus WPBakery-Shortcodes bestehen, die ich direkt in den WordPress Text-Editor (Backend-Editor) einfügen kann und danach im WPBakery Visual Builder (Salient-Theme) Element für Element bearbeiten kann.

### Technische Anforderungen:
- Nur Standard WPBakery (`vc_*`) und Salient/Nectar (`nectar_*`) Shortcodes verwenden
- Jede Sektion ist eine eigene `[vc_row]` – dadurch ist jeder Abschnitt einzeln verschiebbar und bearbeitbar
- Keine Inline-CSS-Blöcke außerhalb von Shortcode-Attributen
- Farben, Texte, Abstände immer als Shortcode-Attribute, nie als style-Tags
- Alle Text-Inhalte direkt im Shortcode als Attribut oder Content-Bereich, nicht als separates HTML

### Design-System (diese Werte exakt verwenden):
- Haupthintergrund: `#0E2718`
- Karten-/Sektion-Hintergrund: `#163421`
- Dunklere Karte: `#112D1C`
- Akzentfarbe Gold: `#C9A035`
- Sekundäres Gold: `#A27F27`
- Primärtext: `#FFFFFF`
- Sekundärtext: `rgba(255,255,255,0.60)` → als Hex näherungsweise `#99B3A3`
- Button-Textfarbe (auf Gold): `#112D1C`
- Keine Serifenschrift, System-Font (SF Pro / sans-serif)

---

### Seitenstruktur – erstelle genau diese Sektionen in dieser Reihenfolge:

---

**SEKTION 1 – Hero**

Vollbreite, Hintergrundfarbe `#0E2718`, vertikales Padding oben/unten 120px.
- Zentriert
- Kleines Badge oben: Text „iOS & Apple Watch App", Hintergrund `#163421`, Textfarbe Gold `#C9A035`, abgerundet
- Hauptüberschrift (H1): „Dein persönlicher **Golfbegleiter**" – das Wort „Golfbegleiter" in Gold hervorheben (nectar_highlighted_text oder nectar_gradient_text)
- Untertitel: „GolfTrack begleitet dich auf dem Platz – von der ersten Runde bis zum offiziellen WHS-Handicap. Rundenerfassung, GPS-Schlagtracking, Apple Watch, 9 Spielmodi und tägliche Coaching-Tipps."
- Zwei Buttons nebeneinander:
  - Primär: „App Store – Kostenlos laden" Hintergrund `#C9A035`, Text `#112D1C`
  - Sekundär: „Features entdecken" Outline-Stil, Rand und Text `#C9A035`

---

**SEKTION 2 – App-Vorteile (3 Spalten)**

Hintergrund `#0E2718`, Padding 80px oben/unten.
- Sektions-Label oben zentriert: „WARUM GOLFTRACK" in Goldfarbe, Buchstabenabstand
- Headline zentriert: „Alles was du auf dem Platz brauchst"
- Darunter 3 gleichbreite Spalten (vc_row mit 3x vc_column 1/3), je ein Vorteilsblock:

  **Spalte 1:**
  - Icon: `figure.golf` (oder SF Symbol Äquivalent) in Gold
  - Titel: „Rundenerfassung"
  - Text: „Erfasse Schläge, Fairways, Greens in Regulation und Putts. 9 Spielmodi – von Zählspiel bis Irish Rumble."

  **Spalte 2:**
  - Icon: `applewatch` / Uhr-Symbol in Gold
  - Titel: „Apple Watch"
  - Text: „Schlagzähler am Handgelenk. Automatische Schwungerkennung via CoreMotion. GPS-Schlagkette direkt auf der Uhr."

  **Spalte 3:**
  - Icon: `chart.line.uptrend.xyaxis` / Diagramm-Symbol in Gold
  - Titel: „WHS-Handicap"
  - Text: „Automatische Handicap-Berechnung nach WHS-Formel. Score-Differentials, Bestleistungen, Trendanalyse."

---

**SEKTION 3 – Feature-Highlight: Rundenerfassung (Bild links, Text rechts)**

Hintergrund `#112D1C`, Padding 80px.
- 2 Spalten: links 1/2 Bild-Placeholder (`vc_single_image` oder leeres Image-Element mit Platzhalter), rechts 1/2 Text
- Badge rechts: „SCORECARD & SCORING"
- Überschrift: „Jede Runde. Jedes Loch. Jeder Modus."
- Text: „Spiele alleine oder mit bis zu 4 Mitspielern. Wähle aus 9 Spielmodi: Zählspiel, Stableford, Matchplay, Skins, Better Ball, Scramble, Erado und mehr. Die Live-Scorecard zeigt dir den Spielstand in Echtzeit – farbcodiert nach Par."
- Feature-Liste (4 Punkte mit Checkmark-Icons in Gold):
  - „9 Spielmodi – Einzel, Partner & Team"
  - „Farbcodierte Scorecard (unter/auf/über Par)"
  - „Fairway, GIR & Putts pro Loch"
  - „Schütteln → Spielregeln sofort nachschlagen"

---

**SEKTION 4 – Feature-Highlight: Apple Watch (Text links, Bild rechts)**

Hintergrund `#0E2718`, Padding 80px.
- 2 Spalten: links 1/2 Text, rechts 1/2 Bild-Placeholder
- Badge links: „APPLE WATCH"
- Überschrift: „Dein Score am Handgelenk"
- Text: „Die GolfTrack Watch App läuft eigenständig auf der Apple Watch. Schlagzähler mit − und + Buttons, automatische Schwungerkennung per Bewegungssensor, GPS-Schlagtracking und sofortige Synchronisierung mit dem iPhone."
- Feature-Liste (4 Punkte):
  - „Automatische Schwungerkennung (CoreMotion)"
  - „GPS: Abschlag & Auftreffpunkt messen"
  - „Haptisches Feedback bei erkanntem Schwung"
  - „Undo-Funktion für Fehlerkennungen"

---

**SEKTION 5 – Spielmodi Grid (6 Kacheln)**

Hintergrund `#112D1C`, Padding 80px.
- Sektions-Label: „SPIELMODI"
- Headline: „9 Spielmodi für jeden Anlass"
- 3-spaltiges Grid (2 Zeilen × 3 Spalten = 6 Kacheln), Hintergrund der einzelnen Kacheln `#163421`, abgerundete Ecken, Gold-Icons:
  1. Icon Einzelperson + „Zählspiel" + „Der Klassiker – Gesamtschlagzahl zählt"
  2. Icon Stern + „Stableford" + „Punkte nach Abstand zu Par"
  3. Icon 2 Personen + „Matchplay" + „Loch für Loch gegen den Gegner"
  4. Icon Geldbeutel + „Skins" + „Jedes Loch hat einen Einsatz"
  5. Icon 2 Personen + „Better Ball" + „Der beste Score im Team zählt"
  6. Icon 4 Personen + „Scramble" + „Alle spielen vom besten Auftreffpunkt"

---

**SEKTION 6 – Stats/Handicap Feature**

Hintergrund `#0E2718`, Padding 80px.
- Zentriert, max. Breite 800px
- Badge: „WHS HANDICAP"
- Headline: „Dein offizielles Handicap – automatisch berechnet"
- Text: „GolfTrack berechnet deinen WHS-Handicap-Index vollautomatisch nach der offiziellen Formel. Nach 3 gespielten Runden erhältst du deinen Index – ab 20 Runden ist er voll qualifiziert. Score-Differentials, Trendchart der letzten 10 Runden und alle Statistiken auf einen Blick."
- 4-spaltiger Stats-Streifen darunter:
  - „Ø Score vs. Par"
  - „Fairways Treffer %"
  - „Greens in Regulation %"
  - „Ø Putts / Runde"

---

**SEKTION 7 – Tipps & Coaching**

Hintergrund `#163421`, Padding 80px.
- 2 Spalten: links Text, rechts 2×2 Kacheln
- Badge links: „TIPPS & COACHING"
- Headline: „Täglich besser werden"
- Text: „Ein täglicher Pro-Tipp wechselt jeden Tag automatisch. 50 Expertentipps zu Technik, Mentale Stärke, Strategie und Kurzspiel. Dazu ein interaktives Platzreife-Quiz und ein vollständiges Regelwerk."
- Rechts 4 Kacheln (2×2) Hintergrund `#112D1C`:
  - Gold-Icon + „Pro Tipp des Tages" + „Wechselt täglich"
  - Gehirn-Icon + „Mental Game" + „Fokus & Konzentration"
  - Karte-Icon + „Strategie" + „Platz-Management"
  - Buch-Icon + „Spielregeln" + „Immer griffbereit"

---

**SEKTION 8 – Game Center / Achievements**

Hintergrund `#0E2718`, Padding 80px.
- Zentriert
- Badge: „GAME CENTER"
- Headline: „Messe dich mit Freunden"
- Text: „GolfTrack ist vollständig mit Apple Game Center integriert. Klettere in den Bestenlisten für Zählspiel und Stableford, schalte Achievements frei und vergleiche dich mit Freunden."
- 3 nebeneinander liegende Punkte mit Icon + Text:
  - Trophy-Icon + „Bestenlisten" + „Zählspiel & Stableford"
  - Stern-Icon + „Achievements" + „Meilensteine freischalten"
  - Person-2-Icon + „Freunde" + „Direkter Vergleich"

---

**SEKTION 9 – CTA (Call to Action)**

Vollbreite, Hintergrund Verlauf von `#0E2718` nach `#163421`, Padding 100px oben/unten.
- Zentriert
- Headline (groß): „Bereit für die nächste Runde?"
- Untertitel: „GolfTrack – kostenlos im App Store. Für iPhone und Apple Watch."
- Button groß zentriert: „Jetzt kostenlos laden" – Hintergrund `#C9A035`, Text `#112D1C`, padding großzügig
- Kleiner Text darunter: „Erfordert iOS 17 oder neuer · Apple Watch mit watchOS 11"

---

### Wichtige Hinweise für die Shortcode-Ausgabe:

1. **Jede Sektion = ein `[vc_row]`-Block** mit `css`-Attribut für Hintergrundfarbe und Padding, z.B.:
   ```
   [vc_row css=".vc_custom_123{background-color: #0E2718 !important; padding-top: 80px !important; padding-bottom: 80px !important;}"]
   ```

2. **Badges** als `[vc_column_text]` mit einer CSS-Klasse oder inline-styled `<span>`:
   ```
   [vc_column_text]<span style="background:#163421;color:#C9A035;padding:6px 16px;border-radius:20px;font-size:12px;letter-spacing:1.5px;font-weight:600;">BADGE TEXT</span>[/vc_column_text]
   ```

3. **Hervorgehobener Text** (Headline) mit `[nectar_highlighted_text]` oder `<span style="color:#C9A035;">`:
   ```
   [vc_column_text]<h1 style="color:#fff;">Dein persönlicher <span style="color:#C9A035;">Golfbegleiter</span></h1>[/vc_column_text]
   ```

4. **Feature-Listen** mit `[nectar_icon_list]` oder `[vc_column_text]` mit HTML-Liste und Gold-Checkmarks

5. **Buttons** mit `[nectar_btn]` (Salient) oder `[vc_btn]`:
   ```
   [nectar_btn size="large" button_style="regular" color="extra-color-1" url="https://apps.apple.com/app/id6767996957" text="App Store – Kostenlos laden"]
   ```

6. **Kacheln/Cards** als `[vc_column]` mit Hintergrundfarbe im `css`-Attribut + `border-radius`

7. **Icons** mit `[nectar_icon icon_family="fontawesome" icon_fontawesome="fa fa-golf-ball" color="Extra-Color-1" size="40px"]` oder SVG-Icons

8. **Bild-Platzhalter** als `[vc_single_image image="0" img_size="full" css=".vc_custom_xyz{background-color:#163421 !important;min-height:400px !important;border-radius:16px !important;}"]`

9. **Spaltenabstände** zwischen Feature-Spalten: `[vc_column_inner width="1/3" css=".vc_custom_xyz{padding: 24px !important;}"]`

10. Gib nur den **fertigen Shortcode** aus – kein erklärender Text drumherum, kein Markdown, kein HTML außerhalb der Shortcodes. Der Output muss direkt in das WordPress Text-Editor-Feld eingefügt werden können.

---

Starte jetzt mit der Ausgabe des vollständigen WPBakery Shortcodes.
