import SwiftUI

// MARK: - Diagram Enum

enum RuleDiagram {
    case teeBox
    case penaltyArea
    case bunker
    case unplayable
    case puttingGreen
    case outOfBounds
    case dropProcedure
    case ballSearch
    case scoringTable
    case matchplay
}

// MARK: - Rules Data Model

struct GolfRule: Identifiable {
    let id = UUID()
    let title: String
    let ruleNumber: String
    let body: String
    let penalty: String?
    let tip: String?
    let diagram: RuleDiagram?

    init(title: String, ruleNumber: String, body: String,
         penalty: String? = nil, tip: String? = nil, diagram: RuleDiagram? = nil) {
        self.title = title
        self.ruleNumber = ruleNumber
        self.body = body
        self.penalty = penalty
        self.tip = tip
        self.diagram = diagram
    }
}

struct GolfRulesCategory: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let rules: [GolfRule]
}

// MARK: - Content (Regelwerk 2023, R&A / USGA)

enum GolfRulesContent {
    static let categories: [GolfRulesCategory] = [

        // MARK: Abschlag
        GolfRulesCategory(
            title: "Abschlag",
            subtitle: "Abschlagsbereich, Tee & Startfehler",
            icon: "figure.golf",
            color: AppTheme.gold,
            rules: [
                GolfRule(
                    title: "Abschlagsbereich",
                    ruleNumber: "Regel 6.2",
                    body: """
Der Ball muss innerhalb des Abschlagsbereichs gespielt werden. Dieser Bereich beginnt an der Vorderkante der Abschlagmarkierungen und erstreckt sich zwei Schlägerlängen nach hinten.

Die Breite ergibt sich durch den Abstand der beiden Abschlagmarkierungen. Die Markierungen selbst gehören noch zum erlaubten Bereich.

Wichtig: Die Füße dürfen außerhalb des Abschlagsbereichs stehen – der Ball muss jedoch innerhalb liegen.

Ein Tee ist erlaubt und darf auf jede Höhe gesteckt werden. Der Ball darf auch ohne Tee auf dem Boden liegen.
""",
                    diagram: .teeBox
                ),
                GolfRule(
                    title: "Ball außerhalb des Abschlagsbereichs gespielt",
                    ruleNumber: "Regel 6.1b",
                    body: """
Zählspiel: Der Schlag zählt nicht und muss vom richtigen Ort innerhalb des Abschlagsbereichs wiederholt werden. Zusätzlich werden 2 Strafschläge hinzugefügt.

Matchplay: Der Gegner kann verlangen, dass der Schlag wiederholt wird. Wird nichts gesagt, zählt der Schlag ohne Strafschlag.

Beispiel: Spieler A schlägt vom falschen Abschlag. Im Zählspiel → Schlag ungültig, Wiederholung + 2 Strafschläge.
""",
                    penalty: "Zählspiel: 2 Strafschläge + Wiederholung vom richtigen Ort"
                ),
                GolfRule(
                    title: "Provisorischer Ball vom Abschlag",
                    ruleNumber: "Regel 18.3",
                    body: """
Wenn ein Ball möglicherweise außerhalb der Grenzen liegt oder verloren sein könnte (nicht in einem Penalty Area), darf ein provisorischer Ball gespielt werden.

Voraussetzungen:
• Ankündigung als „provisorischer Ball" vor dem Spielen
• Mitspieler müssen informiert werden
• Muss gespielt werden, bevor zur Suche gegangen wird

Wird der ursprüngliche Ball innerhalb der 3-Minuten-Suchzeit gefunden und liegt im Spiel, muss der provisorische Ball aufgegeben werden.

Liegt der ursprüngliche Ball im Aus oder wird nicht gefunden, wird der provisorische Ball zum Ball im Spiel.
""",
                    tip: "Immer einen provisorischen Ball spielen, bevor du zur Suche gehst – das spart Zeit für alle."
                ),
                GolfRule(
                    title: "Schlägeranzahl beim Start",
                    ruleNumber: "Regel 4.1",
                    body: """
Ein Spieler darf zu Beginn der Runde maximal 14 Schläger im Bag haben. Ein Schläger gilt als im Spiel, sobald die Runde begonnen hat.

Zu viele Schläger beim Start der Runde → Strafschläge für jedes gespielte Loch bis zum Maximum.

Strafschläger werden nach dem letzten gespielten Loch berechnet, an dem der Verstoß entdeckt wurde. Wird der überschüssige Schläger sofort aus dem Bag genommen, entstehen keine weiteren Strafschläge.

Während der Runde dürfen Schläger ersetzt werden, wenn sie während des normalen Spielbetriebs beschädigt wurden.
""",
                    penalty: "2 Strafschläge/Loch (max. 4) im Zählspiel; Lochverlust/Loch (max. 2 Löcher) im Matchplay"
                ),
                GolfRule(
                    title: "Wettbewerbsunterbrechung / Blitzgefahr",
                    ruleNumber: "Regel 5.7",
                    body: """
Bei Blitzgefahr oder auf Anweisung der Spielleitung muss das Spiel sofort unterbrochen werden.

Signal: Einmaliger langer Pfeifton = Spielunterbrechung durch Spielleitung
Signal: Dreimaliger kurzer Pfeifton = Spiel kann fortgesetzt werden

Bei Unterbrechung darf der Ball markiert und aufgenommen werden. Der Spieler muss das Spiel genau dort fortsetzen, wo er aufgehört hat.

Spielt ein Spieler trotz Unterbrechung weiter → allgemeiner Strafschlag (2 Schläge).
""",
                    tip: "Bei Gewitter sofort Schläger weglegen – Metallschläger sind Blitzableiter."
                )
            ]
        ),

        // MARK: Fairway & Rough
        GolfRulesCategory(
            title: "Fairway & Rough",
            subtitle: "Ball liegt wie er liegt, Erleichterungen",
            icon: "leaf.fill",
            color: Color(red: 0.2, green: 0.6, blue: 0.2),
            rules: [
                GolfRule(
                    title: "Ball liegt wie er liegt",
                    ruleNumber: "Regel 9.1",
                    body: """
Grundprinzip des Golfs: Der Ball muss gespielt werden, wie er liegt. Der Spieler darf weder seinen Stand, den Schwungbereich noch die Linie zum Loch verbessern.

Verbotene Verbesserungen:
✗ Gras hinter dem Ball niederdrücken oder biegen
✗ Äste aus dem Schwungbereich wegbiegen (außer bei erlaubter Standnahme)
✗ Boden vor dem Ball befestigen

Erlaubt ist das Entfernen von:
✓ Losen natürlichen Hemmnissen (Laub, Äste, Steine – sofern nicht als Hemmnisse markiert)
✓ Beweglichen künstlichen Hemmnissen (z.B. Abfalleimer)
"""
                ),
                GolfRule(
                    title: "Drop-Verfahren",
                    ruleNumber: "Regel 14.3",
                    body: """
Jeder Erleichterungsdrop muss korrekt durchgeführt werden:

1. Der Spieler hält den Ball in aufrechter Haltung und lässt ihn aus Kniehöhe fallen.
2. Der Ball muss die Erleichterungszone treffen und darin zum Liegen kommen.
3. Der Ball muss nicht näher zum Loch kommen als der Referenzpunkt.

Darf der Ball rollen? Ja, er darf innerhalb der Erleichterungszone rollen – aber er muss INNERHALB zum Liegen kommen.

Neu droppen wenn:
• Der Ball außerhalb der Erleichterungszone zum Liegen kommt
• Der Ball in einem Penalty Area oder Bunker landet (wenn nicht erlaubt)
• Beim dritten Versuch: Ball an der Stelle platzieren, wo er beim zweiten Drop aufkam.
""",
                    tip: "Der Drop muss aus Kniehöhe erfolgen – nicht von der Schulter wie früher (bis 2018).",
                    diagram: .dropProcedure
                ),
                GolfRule(
                    title: "Eingebetteter Ball",
                    ruleNumber: "Regel 16.3",
                    body: """
Ein Ball, der in seinem eigenen Einschlagloch im Boden eingebettet liegt (außer in Sand oder außerhalb des Allgemeinen Bereichs), darf straflos aufgenommen, gereinigt und gedroppt werden.

Vorgehen:
1. Marke die Ballposition
2. Nimm den Ball auf und reinige ihn
3. Droppe den Ball innerhalb einer Schlägerlänge direkt hinter dem ursprünglichen Ort (nicht näher zum Loch)

Gilt auf dem gesamten Platz außer in:
✗ Bunkern (dort gilt Regel 16.1c)
✗ Penalty Areas
✗ Auf dem Grün (dort normal mit Marker aufnehmen)
""",
                    tip: "Kein Strafschlag – diese Erleichterung ist straflos."
                ),
                GolfRule(
                    title: "Unnormale Platzverhältnisse (GUR, Wasser, Tierspuren)",
                    ruleNumber: "Regel 16.1",
                    body: """
Straflose Erleichterung bei unnormalen Platzverhältnissen:

1. Temporäres Wasser (Pfützen nach Regen, Schnee/Eis als Wasser)
2. Ground Under Repair (GUR) – als solches markierte Bereiche
3. Tierlöcher und Tierwege (Maulwurfhügel, Rehspuren etc.)
4. Unbewegliche künstliche Hemmnisse (Wege, Zäune, Schilder)

Erleichterungsverfahren:
• Nächsten Erleichterungspunkt bestimmen (kein Hindernis mehr für Stand + Schwung)
• Innerhalb einer Schlägerlänge vom Erleichterungspunkt droppen (max. 1 SL)
• Nicht näher zum Loch
• Der Ball muss im gleichen Bereich (Fairway/Rough/Bunker) bleiben

In einem Bunker gilt Erleichterung nur innerhalb des Bunkers (oder mit Strafschlag außerhalb).
""",
                    tip: "GUR-Bereiche sind oft mit weißen Linien markiert oder mit einem Schild ausgewiesen."
                ),
                GolfRule(
                    title: "Unspielbare Lage",
                    ruleNumber: "Regel 19",
                    body: """
Der Spieler darf jederzeit – außer in einem Penalty Area – seinen Ball als unspielbar erklären.

Drei Optionen (alle kosten 1 Strafschlag):

Option 1 – Schlag und Distanz:
Zurück zum Ort des vorherigen Schlags und von dort neu spielen.

Option 2 – Hintere Linie:
Beliebig weit hinter dem Ballort, auf der Linie Loch–Ballposition droppen. Je weiter hinten, desto leichter die Situation – aber immer auf der Lochseite.

Option 3 – Seitliche Erleichterung:
Innerhalb von 2 Schlägerlängen vom Ballort droppen, nicht näher zum Loch.

Im Bunker gilt Regel 19.3 – dort gibt es zusätzlich die Option außerhalb des Bunkers (2 Strafschläge).
""",
                    penalty: "1 Strafschlag (alle drei Optionen)",
                    tip: "Option 2 (hintere Linie) bietet die meiste Flexibilität beim Neuplatzieren.",
                    diagram: .unplayable
                )
            ]
        ),

        // MARK: Bunker
        GolfRulesCategory(
            title: "Bunker",
            subtitle: "Sandhindernis, Berühren & Erleichterung",
            icon: "circle.bottomhalf.filled",
            color: .yellow,
            rules: [
                GolfRule(
                    title: "Sand nicht berühren vor dem Schlag",
                    ruleNumber: "Regel 12.2b",
                    body: """
Vor dem Schlag darf der Schläger den Sand im Bunker nicht berühren – weder beim Ansprechen des Balls, beim Probeschwingen noch beim Rückschwung.

Verboten:
✗ Schläger auf dem Sand abstellen (aufsetzen)
✗ Probeschwung durch den Sand
✗ Sand mit der Hand oder dem Schläger berühren, um die Beschaffenheit zu prüfen

Erlaubt:
✓ Den Schläger in der Luft über dem Sand halten
✓ Sich im Sand abstützen (Standnahme)
✓ Schläger nach dem Schlag im Sand abstellen
✓ Im Sand nach einem Gegenstand suchen
✓ Bewegliche natürliche Hemmnisse entfernen (Äste, Steine – seit 2019 auch Steine)
""",
                    penalty: "Allgemeiner Strafschlag (2 Schläge Zählspiel, Lochverlust Matchplay)",
                    diagram: .bunker
                ),
                GolfRule(
                    title: "Bewegliche Hemmnisse im Bunker entfernen",
                    ruleNumber: "Regel 15.2a",
                    body: """
Bewegliche natürliche Hemmnisse (loses Naturmaterial) dürfen ohne Strafschlag entfernt werden, solange dabei der Ball nicht bewegt wird.

Erlaubt seit 2019: Steine in Bunkern entfernen, sofern keine abweichende Lokale Regel gilt.

Erlaubt:
✓ Blätter, Äste, Zapfen, Steine, Muscheln entfernen
✓ Rechen entfernen (bewegliches künstliches Hemmnis)

Verboten:
✗ Sand oder Erde wegbewegen, um die Lage des Balls zu verbessern
✗ Sand einebnen vor dem Schlag

Vorsicht: Wenn beim Entfernen eines Hemmnisses der Ball bewegt wird, muss er zurückgelegt werden (+1 Strafschlag wenn absichtlich aufgenommen).
"""
                ),
                GolfRule(
                    title: "Temporäres Wasser / GUR im Bunker",
                    ruleNumber: "Regel 16.1c",
                    body: """
Liegt der Ball in einem Bunker in temporärem Wasser (Pfütze) oder GUR, gibt es zwei Optionen:

Option 1 – Straflos, innerhalb des Bunkers:
Den nächsten Punkt ohne Beeinträchtigung innerhalb des Bunkers bestimmen und innerhalb einer Schlägerlänge davon droppen.

Option 2 – Mit Strafschlag, außerhalb des Bunkers:
Auf der hinteren Linie hinter dem Bunker droppen – 1 Strafschlag.

Sondersituation: Liegt der gesamte Bunker unter Wasser, darf direkt außerhalb gedroppt werden (1 Strafschlag auf der hinteren Linie).
""",
                    penalty: "Option 2: 1 Strafschlag"
                ),
                GolfRule(
                    title: "Unspielbar im Bunker",
                    ruleNumber: "Regel 19.3",
                    body: """
Bei unspielbar im Bunker stehen 4 Optionen zur Verfügung:

Option 1 – Schlag und Distanz (+1 Strafschlag):
Zurück zum vorherigen Ort und von dort neu spielen.

Option 2 – Hintere Linie im Bunker (+1 Strafschlag):
Auf der Linie Loch–Ball-Position innerhalb des Bunkers droppen.

Option 3 – Seitliche Erleichterung im Bunker (+1 Strafschlag):
Innerhalb von 2 Schlägerlängen im Bunker droppen.

Option 4 – Außerhalb des Bunkers (+2 Strafschläge, NEU seit 2019):
Auf der hinteren Linie außerhalb des Bunkers droppen. Dies ist die teuerste, aber oft praktischste Option bei sehr schwierigen Bunkerlagen.
""",
                    penalty: "1 oder 2 Strafschläge je nach Option",
                    tip: "Option 4 (+2) außerhalb des Bunkers ist teuer, spart aber oft viel Zeit und Nerven bei sehr schlechten Bunkerlagen."
                ),
                GolfRule(
                    title: "Bunker nach dem Spiel einrechen",
                    ruleNumber: "Regel 12 / Etikette",
                    body: """
Es ist zwar keine offizielle Strafenschlag-Regel, aber eine wichtige Etikette-Pflicht: Bunker müssen nach dem Spielen sorgfältig eingerecht werden.

Reihenfolge beim Verlassen des Bunkers:
1. Ball spielen
2. Fußabdrücke und Schlägerspuren einrechen
3. Rechen außerhalb des Bunkers ablegen (parallell zur Spiellinie)

Der Rechen sollte möglichst flach hingelegt werden, damit kein anderer Ball daran hängen bleibt.

In Turnieren: Ein nicht eingerecter Bunker kann bei hartnäckiger Wiederholung als Langsamspiel oder unhöfliches Verhalten geahndet werden.
""",
                    tip: "Auch bei fremden Spuren einrechen – das schätzen alle Mitspieler."
                )
            ]
        ),

        // MARK: Penalty Areas (Wasser)
        GolfRulesCategory(
            title: "Penalty Areas (Wasser)",
            subtitle: "Gelbe & rote Markierungen, Erleichterung",
            icon: "drop.fill",
            color: .blue,
            rules: [
                GolfRule(
                    title: "Ball im Penalty Area spielen",
                    ruleNumber: "Regel 17.1b",
                    body: """
Ein Ball in einem Penalty Area darf gespielt werden, wie er liegt – ohne Strafschlag.

Wichtig seit 2019: Der Schläger darf beim Ansprechen und beim Probeschwingen den Boden oder das Wasser berühren. Das war früher beim „Wasserhindernis" verboten.

Erlaubt:
✓ Schläger auf Wasser oder Boden im Penalty Area abstellen
✓ Probeschwung durch Wasser oder Gras
✓ Bewegliche Hemmnisse entfernen

Das Spielen aus dem Penalty Area ist zwar möglich, aber oft riskant – besonders bei tiefem Wasser.
""",
                    tip: "Wenn der Ball spielbar liegt (z.B. am Rand), lohnt es sich manchmal trotzdem zu spielen."
                ),
                GolfRule(
                    title: "Gelb markiertes Penalty Area",
                    ruleNumber: "Regel 17.1d(i)",
                    body: """
Liegt der Ball in einem gelb markierten Penalty Area oder ist dort verloren, gibt es drei Optionen:

Option 1 – Ball aus dem Penalty Area spielen (kein Strafschlag)

Option 2 – Schlag und Distanz (+1 Strafschlag):
Zurück zum Ort, von dem der Ball zuletzt gespielt wurde, und von dort neu spielen.

Option 3 – Hintere Linie (+1 Strafschlag):
Beliebig weit hinter dem Penalty Area auf der Linie Loch–Eintrittspunkt droppen. Je weiter hinten, desto klarer die Situation.

Eintrittspunkt = der Punkt, an dem der Ball zuletzt die Grenze des Penalty Area gekreuzt hat.
""",
                    penalty: "Option 2 & 3: je 1 Strafschlag",
                    diagram: .penaltyArea
                ),
                GolfRule(
                    title: "Rot markiertes Penalty Area",
                    ruleNumber: "Regel 17.1d(ii)",
                    body: """
Bei rot markierten Penalty Areas gelten alle drei Optionen wie beim gelben Penalty Area – plus eine zusätzliche Option:

Option 4 – Seitliche Erleichterung (+1 Strafschlag):
Innerhalb von 2 Schlägerlängen vom Eintrittspunkt droppen – nicht näher zum Loch.

Der Eintrittspunkt kann auf beiden Seiten des Penalty Area liegen – der Spieler wählt die günstigere Seite.

Rote Markierung = mehr Flexibilität beim Erleichterungspunkt.
Gelbe Markierung = nur die drei Basisoptionen.
""",
                    penalty: "1 Strafschlag für alle Erleichterungsoptionen"
                ),
                GolfRule(
                    title: "Ball nicht auffindbar – Penalty Area bekannt",
                    ruleNumber: "Regel 17.1c",
                    body: """
Wenn bekannt oder so gut wie sicher ist, dass der Ball in einem Penalty Area liegt (auch ohne ihn zu finden), darf der Spieler eine Erleichterung nach Regel 17.1d nehmen.

„So gut wie sicher" bedeutet: mind. 95% Wahrscheinlichkeit, dass der Ball dort liegt.

Damit wird das langwierige Schlag-und-Distanz-Verfahren (Rücklauf zum Abschlag) vermieden, wenn klar ist, dass der Ball ins Wasser gegangen ist.

Praxis: Ball war eindeutig im Wasser zu sehen/hören → Erleichterung ohne Suche erlaubt.
""",
                    tip: "Wenn der Ball ins Wasser gespritzt ist, kann direkt Erleichterung genommen werden – keine 3-Minuten-Suche nötig."
                ),
                GolfRule(
                    title: "Penalty Area als Erleichterungszone nutzen",
                    ruleNumber: "Regel 17.2",
                    body: """
Besondere Situation: Der Ball liegt in einem Penalty Area und der Spieler möchte Erleichterung nehmen – aber der Erleichterungspunkt liegt ebenfalls in einem Penalty Area.

In diesem Fall darf der Spieler den nächsten Erleichterungspunkt außerhalb beider Penalty Areas wählen (unter Anwendung von Regel 17.1d).

Erleichterung für den Ball im Penalty Area schließt NICHT ein, dass in einem anderen Penalty Area gedroppt wird.
"""
                )
            ]
        ),

        // MARK: Grün
        GolfRulesCategory(
            title: "Grün",
            subtitle: "Putten, Fahne, Marke & Beschädigungen",
            icon: "circle.fill",
            color: .mint,
            rules: [
                GolfRule(
                    title: "Ball markieren, aufnehmen und reinigen",
                    ruleNumber: "Regel 13.1b",
                    body: """
Auf dem Grün darf der Ball jederzeit markiert, aufgenommen und gereinigt werden.

Markierverfahren:
1. Platziere eine Marke (Münze, Ballmarker) direkt hinter dem Ball (in Richtung weg vom Loch)
2. Nimm den Ball auf und reinige ihn vollständig
3. Lege den Ball genau an die markierte Stelle zurück

Marke verschieben: Falls die Marke im Weg eines Mitspielers liegt, darf sie um eine oder mehrere Schlägerkopfbreiten zur Seite geschoben werden – aber exakt wieder zurückverschieben.

Wird der Ball ohne Marke aufgenommen: 1 Strafschlag.
""",
                    tip: "Immer eine Münze oder einen Ballmarker in der Tasche haben.",
                    diagram: .puttingGreen
                ),
                GolfRule(
                    title: "Fahne drin lassen oder herausnehmen",
                    ruleNumber: "Regel 13.2a",
                    body: """
Seit 2019 ist es straflos, die Fahne beim Putten im Loch zu lassen – egal ob vom Grün oder von außerhalb.

Drei Fahnen-Optionen:
1. Fahne im Loch belassen (neu straflos seit 2019)
2. Fahne herausnehmen und ablegen
3. Fahne von jemandem bedienen lassen (herausnehmen sobald Ball näher kommt)

Trifft der Ball die Fahne beim Putten → kein Strafschlag.

Vorteil Fahne drin: Bei schnellen Grüns oder bei Putts aus großer Entfernung kann die Fahne als Bremse wirken.

Achtung: Steckt die Fahne nicht ordnungsgemäß im Loch → +1 Strafschlag wenn der Ball sie trifft.
""",
                    tip: "Statistisch zeigen Studien: Die Fahne drin zu lassen verbessert die Ein-Putt-Rate leicht."
                ),
                GolfRule(
                    title: "Schadstellen auf dem Grün reparieren",
                    ruleNumber: "Regel 13.1c",
                    body: """
Folgende Schadstellen dürfen auf dem Grün repariert werden:

Erlaubt zu reparieren:
✓ Balleinschlagmarken (Pitchmarks, Ballmarken)
✓ Alte Lochmarkierungen (Plugs)
✓ Schuhabdrücke und Schäden durch Tierhufe/-füße
✓ Schäden durch Pflegemaschinen
✓ Schäden durch eingebettete Gegenstände

Nicht erlaubt zu reparieren:
✗ Normaler Verschleiß des Lochs (abgenutzte Ränder)
✗ Aeration-Löcher
✗ Narben durch Vertikutieren
✗ Absetzung des Bodens durch Regen/Beregnung

Tipp: Pitchmarks immer mit einem Marker-Werkzeug reparieren, nicht mit dem Schläger – das beschädigt das Grün.
""",
                    tip: "Pitchmarks reparieren ist Pflicht und wichtig für die Greenqualität aller Spieler."
                ),
                GolfRule(
                    title: "Ball bewegt sich auf dem Grün",
                    ruleNumber: "Regel 13.1d",
                    body: """
Bewegt sich der Ball auf dem Grün durch natürliche Kräfte (Wind, Schwerkraft, Wasser), muss er vom neuen Ort gespielt werden – kein Strafschlag.

Ausnahme – Ball wurde vorher markiert und aufgenommen:
Wird der Ball nach dem Aufnehmen durch Wind bewegt, bevor er zurückgelegt wird, muss er immer an den ursprünglichen Ort zurückgelegt werden.

Sonderfall beim Putten: Bewegt sich der Ball während des Schwungs, gilt der Schlag als gespielt, wenn der Schläger getroffen hat.

Absichtliches Einwirken: Bewegt der Spieler seinen Ball absichtlich oder fahrlässig → 1 Strafschlag und Ball zurücklegen.
"""
                ),
                GolfRule(
                    title: "Falsches Grün",
                    ruleNumber: "Regel 13.1f",
                    body: """
Liegt der Ball auf einem falschen Grün (Abschlagsgrün oder Grün eines anderen Lochs), muss straflose Erleichterung genommen werden – der Ball darf nicht von dort gespielt werden.

Vorgehen:
1. Nächsten Erleichterungspunkt außerhalb des falschen Grüns bestimmen
2. Innerhalb einer Schlägerlänge vom Erleichterungspunkt droppen
3. Nicht näher zum Loch

Auch wenn die Spiellinie oder der Stand auf ein falsches Grün reicht, muss Erleichterung genommen werden.

Kein Strafschlag – diese Erleichterung ist straflos.
"""
                ),
                GolfRule(
                    title: "Putten: Spielreihenfolge auf dem Grün",
                    ruleNumber: "Regel 6.4",
                    body: """
Grundregel: Es spielt zunächst, wer am weitesten vom Loch entfernt ist (furthest from the hole).

Ready Golf im Turnier: Viele Turniere erlauben (und empfehlen) „Ready Golf" – spielen, sobald man bereit ist, auch wenn man nicht an der Reihe ist. Das beschleunigt das Spiel.

Ausnahme Matchplay: Die Reihenfolge wird strenger eingehalten – sie kann taktisch genutzt werden (Gegner „geben" lassen).

Gegenseitiges Konzedieren (Matchplay): Kurze Putts können zugesprochen werden – der Gegner muss nicht einlochen.
""",
                    tip: "Im Zählspiel gilt Ready Golf: Spielen wenn bereit spart enorm Zeit."
                )
            ]
        ),

        // MARK: Ball suchen
        GolfRulesCategory(
            title: "Ball suchen",
            subtitle: "Suchzeit, Identifikation & provisorischer Ball",
            icon: "magnifyingglass",
            color: .orange,
            rules: [
                GolfRule(
                    title: "3-Minuten-Suchzeit",
                    ruleNumber: "Regel 18.2",
                    body: """
Ein Ball gilt als verloren, wenn er nach 3 Minuten Suchen nicht gefunden wurde.

Zeitbeginn: Die 3 Minuten starten, wenn der Spieler oder sein Caddie beginnt, aktiv nach dem Ball zu suchen – nicht erst beim Ankommen.

Nach Ablauf der 3 Minuten:
→ Ball gilt als verloren
→ Folge: Schlag und Distanz (+1 Strafschlag)
→ Zurück zum Ort des vorherigen Schlags

Vor Beginn der Suche: Unbedingt einen provisorischen Ball spielen, um Zeit zu sparen.

Hinweis: Selbst wenn der Ball nach Ablauf der 3 Minuten gefunden wird, darf er nicht mehr gespielt werden – er gilt als verloren.
""",
                    penalty: "Schlag und Distanz: 1 Strafschlag",
                    tip: "Immer einen provisorischen Ball spielen, bevor du zur Suche gehst!",
                    diagram: .ballSearch
                ),
                GolfRule(
                    title: "Ball identifizieren",
                    ruleNumber: "Regel 7.2",
                    body: """
Der Spieler ist verpflichtet, seinen Ball zu identifizieren. Kann der Ball nicht identifiziert werden, gilt er als nicht gefunden.

Identifikationsverfahren:
1. Mitspieler/Marker informieren, dass Ball aufgenommen wird
2. Marke hinter dem Ball platzieren
3. Ball aufnehmen und nur soweit reinigen, wie für die Identifikation nötig
4. Ball zurücklegen

Eigener Ball: Jeder Spieler sollte seinen Ball mit einer eindeutigen Markierung versehen (Punkt, Initials).

Ohne Ankündigung aufgenommen: 1 Strafschlag.

Wichtig: Die Identifikationsregel gilt nicht auf dem Grün – dort darf der Ball immer markiert und aufgenommen werden.
""",
                    penalty: "1 Strafschlag ohne Ankündigung"
                ),
                GolfRule(
                    title: "Beim Suchen: Ball nicht bewegen",
                    ruleNumber: "Regel 7.3 & 9.4",
                    body: """
Beim Suchen des Balls dürfen Sand, Wasser und loses Gras zur Seite geschoben werden, um den Ball sehen zu können.

Wird dabei der Ball bewegt:
• Vor 2019: Strafschlag
• Ab 2019: Kein Strafschlag – aber der Ball muss an seinen ursprünglichen Ort zurückgelegt werden

Kein Strafschlag bei zufälliger Bewegung beim Suchen, solange der Ball sofort zurückgelegt wird.

Strafschlag (1) gibt es nur wenn der Spieler:
→ Den Ball absichtlich aufgehoben hat (ohne Erlaubnis)
→ Den Ball vorsätzlich bewegt hat, um die Lage zu verbessern
"""
                ),
                GolfRule(
                    title: "Falscher Ball gespielt",
                    ruleNumber: "Regel 6.3c",
                    body: """
Spielt ein Spieler einen falschen Ball (Fremdball), muss er den Fehler korrigieren und seinen eigenen Ball spielen.

Zählspiel: 2 Strafschläge + Korrektur
• Die mit dem falschen Ball gespielten Schläge zählen nicht
• Wird der Fehler nicht korrigiert: Disqualifikation

Matchplay: Verlust des Lochs

Ausnahme: Ball im Bunker oder Penalty Area – kein Strafschlag beim versehentlichen Spielen eines falschen Balls im Bunker, wenn es zur Suche diente.

Sonderfall: Beim Putten auf dem Grün und ein anderer Ball rollt in den Weg → kein falscher Ball-Verstoß, Ball wird zurückgelegt.
""",
                    penalty: "2 Strafschläge (Zählspiel) / Lochverlust (Matchplay)"
                ),
                GolfRule(
                    title: "Lokale Regel: Alternative zu Schlag & Distanz",
                    ruleNumber: "Lokale Regel E-5",
                    body: """
Viele Plätze erlauben als Lokale Regel: Statt Schlag und Distanz (zurück zum Abschlag) kann der Ball in der geschätzten Einschlagszone gedroppt werden – mit 2 Strafschlägen.

Voraussetzungen:
• Die Lokale Regel muss auf der Scorekarte oder am Platz ausgewiesen sein
• Die geschätzte Einschlagszone muss auf dem Platz liegen (kein Penalty Area, nicht außerhalb)
• Der Ball wird innerhalb 2 Schlägerlängen der geschätzten Zone gedroppt

Diese Regel soll besonders für Freizeitrunden das Spiel beschleunigen.

Turnierbedingungen: Nur gültig wenn auf der offiziellen Turnierausschreibung angegeben.
""",
                    penalty: "2 Strafschläge (nur bei aktivierter lokaler Regel)",
                    tip: "Frag beim Check-in, ob diese lokale Regel gilt – viele Plätze haben sie."
                )
            ]
        ),

        // MARK: Ball außerhalb Grenzen
        GolfRulesCategory(
            title: "Ball außerhalb Grenzen",
            subtitle: "Aus, Grenzen & Erleichterungsoptionen",
            icon: "xmark.circle.fill",
            color: .red,
            rules: [
                GolfRule(
                    title: "Was bedeutet ‚Außerhalb der Grenzen' (AUS)?",
                    ruleNumber: "Regel 18.2",
                    body: """
Außerhalb der Grenzen (AUS) wird durch weiße Markierungen definiert:
• Weiße Pfähle (stakes) – die innere Seite der Pfähle bildet die Grenzlinie
• Weiße Linien – die innere Kante der Linie ist die Grenzlinie

Ein Ball ist erst dann AUS, wenn er vollständig außerhalb der Grenzlinie liegt. Ein Ball, der die Grenzlinie berührt oder darauf liegt, ist noch im Spiel.

Teile des Spielers im AUS-Bereich: Der Spieler darf mit den Füßen im AUS stehen, sofern der Ball noch im Spiel liegt.

Feste Gegenstände im AUS (Mauern, Zäune): Gelten als Grenzmarkierungen und geben keine Erleichterung.
""",
                    diagram: .outOfBounds
                ),
                GolfRule(
                    title: "AUS-Ball: Schlag und Distanz",
                    ruleNumber: "Regel 18.2b",
                    body: """
Liegt der Ball außerhalb der Grenzen, gilt: 1 Strafschlag + Rückkehr zum vorherigen Ort.

Beispiele:
• Teeshot ins AUS → Ball liegt mit Schlag 3 (1 Teeshot + 1 Strafschlag + Wiederholung)
• Zweiter Schlag ins AUS → Ball liegt mit Schlag 4 (1+1+1+Wiederholung)

Procedere:
1. Zurück zum Ort des vorherigen Schlags
2. 1 Strafschlag addieren
3. Von dort neu spielen

Kein weiterer Schlag muss gespielt werden, solange noch ein Ball im Spiel ist (provisorischer Ball oder Rückkehr zum Tee).
""",
                    penalty: "1 Strafschlag + Wiederholung vom vorherigen Ort"
                ),
                GolfRule(
                    title: "Provisorischer Ball bei AUS-Verdacht",
                    ruleNumber: "Regel 18.3",
                    body: """
Wenn ein Ball möglicherweise ins AUS gegangen ist oder verloren sein könnte, sollte ein provisorischer Ball gespielt werden.

Ankündigungspflicht: „Ich spiele einen provisorischen Ball" – ohne diese Ankündigung gilt der zweite Ball automatisch als Ball im Spiel (mit Strafschlag und Distanz).

Was passiert dann:
• Ursprünglicher Ball gefunden & im Spiel → Provisorischer Ball aufgeben
• Ursprünglicher Ball AUS oder nicht gefunden → Provisorischer Ball wird Ball im Spiel
• Hat der Spieler bereits mit dem provisorischen Ball am Ort des ursprünglichen Balls gespielt → Provisorischer Ball ist zwingend im Spiel

Der provisorische Ball spart enorm viel Zeit – immer spielen!
""",
                    tip: "Provisorischen Ball IMMER ankündigen – sonst gilt er als Ball im Spiel."
                ),
                GolfRule(
                    title: "Spezialfall: AUS-Grenze durch Gebäude",
                    ruleNumber: "Regel 18 / Lokale Regel",
                    body: """
Gebäude, Mauern und feste Zäune, die als AUS-Grenze dienen, geben keine straflose Erleichterung.

Liegt der Ball an einer Hauswand (die die AUS-Grenze bildet), muss entweder gespielt werden oder Schlag und Distanz in Anspruch genommen werden.

Manchmal erlauben Lokale Regeln eine Erleichterung von bestimmten Strukturen (z.B. bei Clubhaus-Wänden). Diese müssen auf der Scorekarte angegeben sein.

Tipp: Bei Turnieren auf der Platzübersicht prüfen, ob Lokale Regeln für bestimmte Grenzen gelten.
"""
                )
            ]
        ),

        // MARK: Ball bewegt
        GolfRulesCategory(
            title: "Ball bewegt",
            subtitle: "Absichtlich, zufällig & natürliche Kräfte",
            icon: "arrow.up.and.down.circle.fill",
            color: .purple,
            rules: [
                GolfRule(
                    title: "Ball durch natürliche Kräfte bewegt",
                    ruleNumber: "Regel 9.3",
                    body: """
Bewegt sich der Ball im Spiel durch Wind, Wasser oder Schwerkraft (Hang), muss er vom neuen Ort gespielt werden – kein Strafschlag.

Ausnahmen – Ball muss zurückgelegt werden:
1. Ball auf dem Grün, der zuvor markiert und aufgenommen wurde → zurück zum ursprünglichen Ort
2. Ball wurde angesprochen (address position) und bewegt sich dann → Ball zurücklegen, kein Strafschlag (Regel 9.4)

Wichtig: „Natürliche Kräfte" umfasst auch: Wasser, das den Ball mitreißt, und Äste, die durch Wind fallen und den Ball bewegen.
"""
                ),
                GolfRule(
                    title: "Ball durch Spieler versehentlich bewegt",
                    ruleNumber: "Regel 9.4",
                    body: """
Bewegt der Spieler seinen Ball im Spiel versehentlich:

Ab 2019 (vereinfacht): Kein Strafschlag mehr bei zufälliger Bewegung in den meisten Situationen.

Kein Strafschlag (Ball zurücklegen):
• Beim Suchen des Balls
• Bei der Standnahme
• Beim Schwung (außer beim Schlag selbst)
• Auf dem Grün beim Entfernen von Hemmnissen

Strafschlag (1) gibt es nur noch wenn:
• Der Spieler den Ball absichtlich aufgenommen hat (ohne Erlaubnis)

Früher (vor 2019): Strafschlag bei jeder versehentlichen Bewegung. Die neue Regelung ist viel spielerfreundlicher.
""",
                    penalty: "1 Strafschlag nur bei absichtlichem Aufnehmen ohne Erlaubnis"
                ),
                GolfRule(
                    title: "Ball in Bewegung trifft Person oder Ausrüstung",
                    ruleNumber: "Regel 11.1",
                    body: """
Trifft ein Ball in Bewegung versehentlich eine Person, ein Tier oder Ausrüstung, gilt:

Grundregel: Der Schlag wird gewertet und der Ball von dort gespielt, wo er zum Liegen kommt – kein Strafschlag.

Ausnahmen (Strafschlag möglich):
• Spielt der Spieler absichtlich auf Ausrüstung oder Personen → allgemeiner Strafschlag
• Ball trifft eigene Ausrüstung (Bag, Wagen) auf dem Grün → 1 Strafschlag + Ball zurücklegen

Sonderfall Grün: Wenn der Ball beim Putten die Fahne trifft (seit 2019 straflos), oder wenn der Ball einen Mitspieler/Caddie trifft → kein Strafschlag.

Absichtliches Ablenken: Versucht der Spieler, einen fahrenden Ball abzulenken → Disqualifikation oder Lochverlust.
""",
                    penalty: "Kein Strafschlag bei unbeabsichtigtem Treffen"
                ),
                GolfRule(
                    title: "Ball zurücklegen – korrektes Verfahren",
                    ruleNumber: "Regel 14.2",
                    body: """
Ein Ball muss zurückgelegt werden, indem er auf den exakten Punkt gesetzt wird – nicht gedroppt.

Vorgehen:
1. Ball an denselben Punkt setzen, von dem er aufgenommen wurde
2. Kann der genaue Punkt nicht bestimmt werden → so nah wie möglich am geschätzten Punkt platzieren

Falsch zurückgelegt: 1 Strafschlag
• Ball gedroppt statt gesetzt (auf dem Grün)
• Ball neben anstatt auf den Marker gesetzt
• Ball an falschem Punkt zurückgelegt

Auf dem Grün: Der Marker wird erst entfernt, wenn der Ball platziert ist, nicht vorher.
""",
                    penalty: "1 Strafschlag bei falschem Verfahren"
                ),
                GolfRule(
                    title: "Schlag gespielt aber Ball bewegt sich noch",
                    ruleNumber: "Regel 9.1b",
                    body: """
Spielt ein Spieler einen Schlag, während sich der Ball noch bewegt, gibt es grundsätzlich einen Strafschlag.

Ausnahmen (kein Strafschlag):
• Ball bewegt sich nach einem Schlag, der ihn nur getroffen hat (normaler Ballflug)
• Ball bewegt sich durch einen anderen Ball, der ihn trifft
• Ball auf dem Grün: Spieler wartet nicht, bis der Ball aufgehört hat zu rollen → kein Strafschlag

Merke: Ein Spieler sollte warten, bis sein Ball vollständig zur Ruhe gekommen ist, bevor er den nächsten Schlag spielt.
""",
                    penalty: "1 Strafschlag (bei unerlaubtem Spielen des bewegten Balls)"
                )
            ]
        ),

        // MARK: Matchplay
        GolfRulesCategory(
            title: "Matchplay",
            subtitle: "Loch-für-Loch-Wertung, Zugestehen & Ergebnis",
            icon: "person.2.fill",
            color: Color(red: 0.3, green: 0.5, blue: 0.8),
            rules: [
                GolfRule(
                    title: "Wie Matchplay funktioniert",
                    ruleNumber: "Regel 3.2",
                    body: """
Im Matchplay (Lochspiel) werden nicht Schläge gezählt, sondern Löcher gewonnen oder verloren.

Grundprinzip:
• Niedrigerer Netto-Score → Loch gewonnen
• Höherer Score → Loch verloren
• Gleicher Score → Loch geteilt (halved)

Das Ergebnis wird in „Up/Down/All Square" angegeben:
• 2 up: Spieler führt mit 2 Löchern Vorsprung
• All square: gleichstand
• 3&2: Spieler hat 3 Löcher Vorsprung und es sind nur noch 2 zu spielen → Spiel vorbei

Das Spiel endet, wenn der Vorsprung größer ist als die verbleibenden Löcher.
""",
                    diagram: .matchplay
                ),
                GolfRule(
                    title: "Loch zugestehen (Concede)",
                    ruleNumber: "Regel 3.2b",
                    body: """
Im Matchplay darf der Gegner einen Schlag, ein Loch oder das gesamte Match „zugeben" (concede).

Anwendung:
• Schlag zugestehen: „Das Putt zählt" – der Gegner muss nicht mehr einlochen
• Loch zugestehen: Der Gegner gewinnt das Loch (jederzeit während des Lochs möglich)
• Match zugestehen: Der Gegner gewinnt das gesamte Spiel

Wichtig: Eine Zugestehen ist bindend und kann nicht widerrufen werden.

Kein Strafschlag wenn ein zugestandener Schlag dennoch gespielt wird – das Ergebnis zählt aber nicht.
""",
                    tip: "Kurze Putts im Matchplay zugeben ist üblich – aber strategisch kann es auch Sinn machen, nicht zuzugeben."
                ),
                GolfRule(
                    title: "Spielreihenfolge im Matchplay",
                    ruleNumber: "Regel 6.4a",
                    body: """
Im Matchplay hat die Spielreihenfolge strategische Bedeutung.

Abschlag: Wer das vorherige Loch gewonnen hat, hat die „Ehre" (spielt zuerst).
Beim ersten Loch: Wird ausgelost oder durch Vereinbarung bestimmt.

Weitere Schläge: Wer weiter vom Loch entfernt ist, spielt zuerst.

Falsche Reihenfolge: Der Gegner kann den Schlag annullieren und den Spieler auffordern, in der richtigen Reihenfolge zu spielen. Diese Entscheidung muss sofort getroffen werden.

Ready Golf: Im Matchplay weniger verbreitet als im Zählspiel – die Reihenfolge kann taktisch genutzt werden.
"""
                ),
                GolfRule(
                    title: "Handicap im Matchplay",
                    ruleNumber: "Regel 3.2c",
                    body: """
Im Handicap-Matchplay erhält der schwächere Spieler Vorgabeschläge auf den Löchern mit den niedrigsten Spielvorgaben (Stroke Index 1, 2, 3 …).

Berechnung:
• Differenz der beiden Handicaps = Anzahl der Vorgabeschläge
• Beispiel: Handicap 24 vs. 18 → 6 Vorgabeschläge auf den 6 schwierigsten Löchern (SI 1-6)

Auf einem Vorgabeloch: Spieler mit Vorgabe erhält 1 Schlag Gutschrift → sein Netto-Score ist 1 Schlag besser.

Vorgabeschläge nicht deklariert: Wenn das Handicap-Verhältnis nicht vor dem Start vereinbart wurde, gilt das Spiel ohne Handicap.
""",
                    tip: "Vor dem Matchplay immer die Handicaps und Vorgabeschläge besprechen und bestätigen."
                )
            ]
        ),

        // MARK: Turniere & Etikette
        GolfRulesCategory(
            title: "Turniere & Etikette",
            subtitle: "Wettspielregeln, Pace of Play & Verhalten",
            icon: "trophy.fill",
            color: Color(red: 0.8, green: 0.6, blue: 0.1),
            rules: [
                GolfRule(
                    title: "Scorecard – Pflichten und Fehler",
                    ruleNumber: "Regel 3.3b",
                    body: """
Im Zählspiel ist jeder Spieler für die Richtigkeit seiner Scorekarte verantwortlich.

Pflichten:
• Spieler und Zählkartenschreiber (Marker) müssen unterschreiben
• Scorekarte nach der Runde einreichen (kein Datum nötig, nur Score und Unterschrift)

Fehler auf der Scorekarte:
• Zu hoher Score eingetragen → gilt als gespielt (kein Strafschlag)
• Zu niedriger Score eingetragen → Disqualifikation
• Fehlende Unterschrift → Disqualifikation

Sonderfall Stableford: Zu niedriger Brutto-Score → 2 Strafpunkte werden abgezogen (keine Disqualifikation).
""",
                    tip: "Immer die Scorekarte gründlich prüfen, bevor unterschrieben wird.",
                    diagram: .scoringTable
                ),
                GolfRule(
                    title: "Pace of Play – Spielgeschwindigkeit",
                    ruleNumber: "Regel 5.6",
                    body: """
Spieler sind verpflichtet, in einem angemessenen Tempo zu spielen.

Richtwert für Turniergolf:
• Max. 40 Sekunden pro Schlag
• Erster Spieler auf dem Loch: max. 60 Sekunden

Die Gruppe soll stets in Kontakt zur vorherigen Gruppe bleiben.

Bei Langsamspiel:
1. Verwarnung durch Spielleitung
2. Erster Verstoß: 1 Strafschlag
3. Zweiter Verstoß: 2 Strafschläge
4. Dritter Verstoß: Disqualifikation

Ready Golf: Im Zählspiel empfohlen – spielen sobald man bereit ist, auch wenn man nicht an der Reihe ist (außer beim Abschlag mit Ehrenrecht).
""",
                    tip: "Bei Turnieren: Bereit spielen (ready golf) beschleunigt das Spiel erheblich."
                ),
                GolfRule(
                    title: "Ratschläge – Was ist erlaubt?",
                    ruleNumber: "Regel 10.2",
                    body: """
Im Wettspiel darf kein Rat eingeholt oder gegeben werden – außer vom eigenen Caddie.

Was gilt als verbotener Rat:
✗ Empfehlung welchen Schläger zu benutzen
✗ Hinweis auf Schlägerhaltung oder Schwungsgedanke
✗ Tipp zur Spiellinie beim Putten (außer eigener Caddie)
✗ Entfernungsangaben die einen Rat beinhalten

Was KEINE Ratschläge sind (erlaubt):
✓ Allgemeine Platzbeschreibung (Bunkerpositionen, Greenform)
✓ Entfernungsangaben (ohne Schläger-Empfehlung)
✓ Windrichtung abschätzen
✓ Lokale Regeln erklären

Caddie: Darf umfassend beraten und auf Wunsch bei Schlagauswahl helfen.
""",
                    penalty: "2 Strafschläge (Zählspiel) / Lochverlust (Matchplay)"
                ),
                GolfRule(
                    title: "Disqualifikationsgründe (Auswahl)",
                    ruleNumber: "Regel 1–4",
                    body: """
Häufige Disqualifikationsgründe im Turnier:

Scorekarte:
✗ Zu niedrigen Score auf der Scorekarte eingetragen
✗ Scorekarte nicht eingereicht

Regelverstoß:
✗ Falschen Ball gespielt und Fehler nicht korrigiert
✗ Schlag nicht am richtigen Ort wiederholt (wenn nötig)
✗ Angewendete Erleichterung war nicht erlaubt und Fehler nicht berichtigt

Verhalten:
✗ Vereinbarung zur Regelumgehung mit Mitspielern
✗ Spielunterbrechung ohne Genehmigung

Schutzmechanismus: Im Zweifel eine zweite Kugel spielen (Protest-Ball nach Regel 20.1c) und nach der Runde die Regelkommission befragen.
""",
                    tip: "Im Zweifel einen Protest-Ball spielen und nach der Runde die Regelkommission fragen – das schützt vor Disqualifikation."
                ),
                GolfRule(
                    title: "Schläger maximal 14 im Bag",
                    ruleNumber: "Regel 4.1a",
                    body: """
Ein Spieler darf maximal 14 Schläger im Bag haben. Überschreitung führt zu Strafschlägen.

Strafberechnung:
• Pro Loch, auf dem der Verstoß begangen wurde (max. 2 Löcher pro Runde)
• Muss der betreffende Schläger sofort für den Rest der Runde außer Betrieb genommen werden

Ersatz kaputte Schläger: Während der Runde darf ein durch normalen Spielbetrieb beschädigter Schläger ersetzt werden (kein Strafschlag).

Absichtliche Beschädigung zur Auswechslung: Nicht erlaubt → kein Anrecht auf Ersatz.

Tipp: Vor jeder Runde die Schlägerzahl zählen – 14 ist das Maximum.
""",
                    penalty: "2 Strafschläge/Loch (max. 4 Schläge) Zählspiel; Lochverlust/Loch (max. 2 Löcher) Matchplay"
                ),
                GolfRule(
                    title: "Etikette & Verhalten auf dem Platz",
                    ruleNumber: "Regel 1.2",
                    body: """
Grundregeln für respektvolles Verhalten auf dem Golfplatz:

Mitspieler:
✓ Ruhe beim Schwung anderer Spieler
✓ Nicht im Sichtfeld des Spielers stehen
✓ Schatten nicht auf die Spiellinie oder Puttlinie werfen

Platzpflege:
✓ Divots (Grassoden) einsetzen oder mit Sand füllen
✓ Pitchmarks auf dem Grün reparieren
✓ Bunker einrechen nach dem Spielen
✓ Fahne korrekt einsetzen

Tempo:
✓ Ready Golf spielen
✓ Schläger schon beim Gehen zum Ball auswählen
✓ Bag auf dem schnellsten Weg zum nächsten Abschlag

Sanktionen bei nachhaltig unhöflichem Verhalten: Disqualifikation durch die Spielleitung möglich.
""",
                    tip: "Gute Etikette macht das Spiel für alle besser – und wird von Mitspielern immer geschätzt."
                )
            ]
        )
    ]
}
