package app.golftrack.feature.guide

import androidx.compose.ui.graphics.Color
import app.golftrack.ui.theme.AppTheme

// Entspricht GolfTrackApp/Views/Guide/GolfRulesData.swift (per Skript übertragen).

enum class RuleDiagram { teeBox, penaltyArea, bunker, unplayable, puttingGreen, outOfBounds, dropProcedure, ballSearch, scoringTable, matchplay }

data class GolfRule(
    val title: String,
    val ruleNumber: String,
    val body: String,
    val penalty: String? = null,
    val tip: String? = null,
    val diagram: RuleDiagram? = null,
)

data class GolfRulesCategory(
    val title: String,
    val subtitle: String,
    val icon: String,
    val color: Color,
    val rules: List<GolfRule>,
)

// Regelwerk 2023, R&A / USGA
object GolfRulesContent {
    val categories: List<GolfRulesCategory> = listOf(
        // MARK: Abschlag
        GolfRulesCategory(
            title = "Abschlag",
            subtitle = "Abschlagsbereich, Tee & Startfehler",
            icon = "figure.golf",
            color = AppTheme.gold,
            rules = listOf(
                GolfRule(
                    title = "Abschlagsbereich",
                    ruleNumber = "Regel 6.2",
                    body = "Der Ball muss innerhalb des Abschlagsbereichs gespielt werden. Dieser Bereich beginnt an der Vorderkante der Abschlagmarkierungen und erstreckt sich zwei Schlägerlängen nach hinten.\n\nDie Breite ergibt sich durch den Abstand der beiden Abschlagmarkierungen. Die Markierungen selbst gehören noch zum erlaubten Bereich.\n\nWichtig: Die Füße dürfen außerhalb des Abschlagsbereichs stehen – der Ball muss jedoch innerhalb liegen.\n\nEin Tee ist erlaubt und darf auf jede Höhe gesteckt werden. Der Ball darf auch ohne Tee auf dem Boden liegen.",
                    diagram = RuleDiagram.teeBox
                ),
                GolfRule(
                    title = "Ball außerhalb des Abschlagsbereichs gespielt",
                    ruleNumber = "Regel 6.1b",
                    body = "Zählspiel: Der Schlag zählt nicht und muss vom richtigen Ort innerhalb des Abschlagsbereichs wiederholt werden. Zusätzlich werden 2 Strafschläge hinzugefügt.\n\nMatchplay: Der Gegner kann verlangen, dass der Schlag wiederholt wird. Wird nichts gesagt, zählt der Schlag ohne Strafschlag.\n\nBeispiel: Spieler A schlägt vom falschen Abschlag. Im Zählspiel → Schlag ungültig, Wiederholung + 2 Strafschläge.",
                    penalty = "Zählspiel: 2 Strafschläge + Wiederholung vom richtigen Ort"
                ),
                GolfRule(
                    title = "Provisorischer Ball vom Abschlag",
                    ruleNumber = "Regel 18.3",
                    body = "Wenn ein Ball möglicherweise außerhalb der Grenzen liegt oder verloren sein könnte (nicht in einem Penalty Area), darf ein provisorischer Ball gespielt werden.\n\nVoraussetzungen:\n• Ankündigung als „provisorischer Ball\" vor dem Spielen\n• Mitspieler müssen informiert werden\n• Muss gespielt werden, bevor zur Suche gegangen wird\n\nWird der ursprüngliche Ball innerhalb der 3-Minuten-Suchzeit gefunden und liegt im Spiel, muss der provisorische Ball aufgegeben werden.\n\nLiegt der ursprüngliche Ball im Aus oder wird nicht gefunden, wird der provisorische Ball zum Ball im Spiel.",
                    tip = "Immer einen provisorischen Ball spielen, bevor du zur Suche gehst – das spart Zeit für alle."
                ),
                GolfRule(
                    title = "Schlägeranzahl beim Start",
                    ruleNumber = "Regel 4.1",
                    body = "Ein Spieler darf zu Beginn der Runde maximal 14 Schläger im Bag haben. Ein Schläger gilt als im Spiel, sobald die Runde begonnen hat.\n\nZu viele Schläger beim Start der Runde → Strafschläge für jedes gespielte Loch bis zum Maximum.\n\nStrafschläger werden nach dem letzten gespielten Loch berechnet, an dem der Verstoß entdeckt wurde. Wird der überschüssige Schläger sofort aus dem Bag genommen, entstehen keine weiteren Strafschläge.\n\nWährend der Runde dürfen Schläger ersetzt werden, wenn sie während des normalen Spielbetriebs beschädigt wurden.",
                    penalty = "2 Strafschläge/Loch (max. 4) im Zählspiel; Lochverlust/Loch (max. 2 Löcher) im Matchplay"
                ),
                GolfRule(
                    title = "Wettbewerbsunterbrechung / Blitzgefahr",
                    ruleNumber = "Regel 5.7",
                    body = "Bei Blitzgefahr oder auf Anweisung der Spielleitung muss das Spiel sofort unterbrochen werden.\n\nSignal: Einmaliger langer Pfeifton = Spielunterbrechung durch Spielleitung\nSignal: Dreimaliger kurzer Pfeifton = Spiel kann fortgesetzt werden\n\nBei Unterbrechung darf der Ball markiert und aufgenommen werden. Der Spieler muss das Spiel genau dort fortsetzen, wo er aufgehört hat.\n\nSpielt ein Spieler trotz Unterbrechung weiter → allgemeiner Strafschlag (2 Schläge).",
                    tip = "Bei Gewitter sofort Schläger weglegen – Metallschläger sind Blitzableiter."
                )
            )
        ),

        // MARK: Fairway & Rough
        GolfRulesCategory(
            title = "Fairway & Rough",
            subtitle = "Ball liegt wie er liegt, Erleichterungen",
            icon = "leaf.fill",
            color = rgb(0.2f, 0.6f, 0.2f),
            rules = listOf(
                GolfRule(
                    title = "Ball liegt wie er liegt",
                    ruleNumber = "Regel 9.1",
                    body = "Grundprinzip des Golfs: Der Ball muss gespielt werden, wie er liegt. Der Spieler darf weder seinen Stand, den Schwungbereich noch die Linie zum Loch verbessern.\n\nVerbotene Verbesserungen:\n✗ Gras hinter dem Ball niederdrücken oder biegen\n✗ Äste aus dem Schwungbereich wegbiegen (außer bei erlaubter Standnahme)\n✗ Boden vor dem Ball befestigen\n\nErlaubt ist das Entfernen von:\n✓ Losen natürlichen Hemmnissen (Laub, Äste, Steine – sofern nicht als Hemmnisse markiert)\n✓ Beweglichen künstlichen Hemmnissen (z.B. Abfalleimer)"
                ),
                GolfRule(
                    title = "Drop-Verfahren",
                    ruleNumber = "Regel 14.3",
                    body = "Jeder Erleichterungsdrop muss korrekt durchgeführt werden:\n\n1. Der Spieler hält den Ball in aufrechter Haltung und lässt ihn aus Kniehöhe fallen.\n2. Der Ball muss die Erleichterungszone treffen und darin zum Liegen kommen.\n3. Der Ball muss nicht näher zum Loch kommen als der Referenzpunkt.\n\nDarf der Ball rollen? Ja, er darf innerhalb der Erleichterungszone rollen – aber er muss INNERHALB zum Liegen kommen.\n\nNeu droppen wenn:\n• Der Ball außerhalb der Erleichterungszone zum Liegen kommt\n• Der Ball in einem Penalty Area oder Bunker landet (wenn nicht erlaubt)\n• Beim dritten Versuch: Ball an der Stelle platzieren, wo er beim zweiten Drop aufkam.",
                    tip = "Der Drop muss aus Kniehöhe erfolgen – nicht von der Schulter wie früher (bis 2018).",
                    diagram = RuleDiagram.dropProcedure
                ),
                GolfRule(
                    title = "Eingebetteter Ball",
                    ruleNumber = "Regel 16.3",
                    body = "Ein Ball, der in seinem eigenen Einschlagloch im Boden eingebettet liegt (außer in Sand oder außerhalb des Allgemeinen Bereichs), darf straflos aufgenommen, gereinigt und gedroppt werden.\n\nVorgehen:\n1. Marke die Ballposition\n2. Nimm den Ball auf und reinige ihn\n3. Droppe den Ball innerhalb einer Schlägerlänge direkt hinter dem ursprünglichen Ort (nicht näher zum Loch)\n\nGilt auf dem gesamten Platz außer in:\n✗ Bunkern (dort gilt Regel 16.1c)\n✗ Penalty Areas\n✗ Auf dem Grün (dort normal mit Marker aufnehmen)",
                    tip = "Kein Strafschlag – diese Erleichterung ist straflos."
                ),
                GolfRule(
                    title = "Unnormale Platzverhältnisse (GUR, Wasser, Tierspuren)",
                    ruleNumber = "Regel 16.1",
                    body = "Straflose Erleichterung bei unnormalen Platzverhältnissen:\n\n1. Temporäres Wasser (Pfützen nach Regen, Schnee/Eis als Wasser)\n2. Ground Under Repair (GUR) – als solches markierte Bereiche\n3. Tierlöcher und Tierwege (Maulwurfhügel, Rehspuren etc.)\n4. Unbewegliche künstliche Hemmnisse (Wege, Zäune, Schilder)\n\nErleichterungsverfahren:\n• Nächsten Erleichterungspunkt bestimmen (kein Hindernis mehr für Stand + Schwung)\n• Innerhalb einer Schlägerlänge vom Erleichterungspunkt droppen (max. 1 SL)\n• Nicht näher zum Loch\n• Der Ball muss im gleichen Bereich (Fairway/Rough/Bunker) bleiben\n\nIn einem Bunker gilt Erleichterung nur innerhalb des Bunkers (oder mit Strafschlag außerhalb).",
                    tip = "GUR-Bereiche sind oft mit weißen Linien markiert oder mit einem Schild ausgewiesen."
                ),
                GolfRule(
                    title = "Unspielbare Lage",
                    ruleNumber = "Regel 19",
                    body = "Der Spieler darf jederzeit – außer in einem Penalty Area – seinen Ball als unspielbar erklären.\n\nDrei Optionen (alle kosten 1 Strafschlag):\n\nOption 1 – Schlag und Distanz:\nZurück zum Ort des vorherigen Schlags und von dort neu spielen.\n\nOption 2 – Hintere Linie:\nBeliebig weit hinter dem Ballort, auf der Linie Loch–Ballposition droppen. Je weiter hinten, desto leichter die Situation – aber immer auf der Lochseite.\n\nOption 3 – Seitliche Erleichterung:\nInnerhalb von 2 Schlägerlängen vom Ballort droppen, nicht näher zum Loch.\n\nIm Bunker gilt Regel 19.3 – dort gibt es zusätzlich die Option außerhalb des Bunkers (2 Strafschläge).",
                    penalty = "1 Strafschlag (alle drei Optionen)",
                    tip = "Option 2 (hintere Linie) bietet die meiste Flexibilität beim Neuplatzieren.",
                    diagram = RuleDiagram.unplayable
                )
            )
        ),

        // MARK: Bunker
        GolfRulesCategory(
            title = "Bunker",
            subtitle = "Sandhindernis, Berühren & Erleichterung",
            icon = "circle.bottomhalf.filled",
            color = IosColor.yellow,
            rules = listOf(
                GolfRule(
                    title = "Sand nicht berühren vor dem Schlag",
                    ruleNumber = "Regel 12.2b",
                    body = "Vor dem Schlag darf der Schläger den Sand im Bunker nicht berühren – weder beim Ansprechen des Balls, beim Probeschwingen noch beim Rückschwung.\n\nVerboten:\n✗ Schläger auf dem Sand abstellen (aufsetzen)\n✗ Probeschwung durch den Sand\n✗ Sand mit der Hand oder dem Schläger berühren, um die Beschaffenheit zu prüfen\n\nErlaubt:\n✓ Den Schläger in der Luft über dem Sand halten\n✓ Sich im Sand abstützen (Standnahme)\n✓ Schläger nach dem Schlag im Sand abstellen\n✓ Im Sand nach einem Gegenstand suchen\n✓ Bewegliche natürliche Hemmnisse entfernen (Äste, Steine – seit 2019 auch Steine)",
                    penalty = "Allgemeiner Strafschlag (2 Schläge Zählspiel, Lochverlust Matchplay)",
                    diagram = RuleDiagram.bunker
                ),
                GolfRule(
                    title = "Bewegliche Hemmnisse im Bunker entfernen",
                    ruleNumber = "Regel 15.2a",
                    body = "Bewegliche natürliche Hemmnisse (loses Naturmaterial) dürfen ohne Strafschlag entfernt werden, solange dabei der Ball nicht bewegt wird.\n\nErlaubt seit 2019: Steine in Bunkern entfernen, sofern keine abweichende Lokale Regel gilt.\n\nErlaubt:\n✓ Blätter, Äste, Zapfen, Steine, Muscheln entfernen\n✓ Rechen entfernen (bewegliches künstliches Hemmnis)\n\nVerboten:\n✗ Sand oder Erde wegbewegen, um die Lage des Balls zu verbessern\n✗ Sand einebnen vor dem Schlag\n\nVorsicht: Wenn beim Entfernen eines Hemmnisses der Ball bewegt wird, muss er zurückgelegt werden (+1 Strafschlag wenn absichtlich aufgenommen)."
                ),
                GolfRule(
                    title = "Temporäres Wasser / GUR im Bunker",
                    ruleNumber = "Regel 16.1c",
                    body = "Liegt der Ball in einem Bunker in temporärem Wasser (Pfütze) oder GUR, gibt es zwei Optionen:\n\nOption 1 – Straflos, innerhalb des Bunkers:\nDen nächsten Punkt ohne Beeinträchtigung innerhalb des Bunkers bestimmen und innerhalb einer Schlägerlänge davon droppen.\n\nOption 2 – Mit Strafschlag, außerhalb des Bunkers:\nAuf der hinteren Linie hinter dem Bunker droppen – 1 Strafschlag.\n\nSondersituation: Liegt der gesamte Bunker unter Wasser, darf direkt außerhalb gedroppt werden (1 Strafschlag auf der hinteren Linie).",
                    penalty = "Option 2: 1 Strafschlag"
                ),
                GolfRule(
                    title = "Unspielbar im Bunker",
                    ruleNumber = "Regel 19.3",
                    body = "Bei unspielbar im Bunker stehen 4 Optionen zur Verfügung:\n\nOption 1 – Schlag und Distanz (+1 Strafschlag):\nZurück zum vorherigen Ort und von dort neu spielen.\n\nOption 2 – Hintere Linie im Bunker (+1 Strafschlag):\nAuf der Linie Loch–Ball-Position innerhalb des Bunkers droppen.\n\nOption 3 – Seitliche Erleichterung im Bunker (+1 Strafschlag):\nInnerhalb von 2 Schlägerlängen im Bunker droppen.\n\nOption 4 – Außerhalb des Bunkers (+2 Strafschläge, NEU seit 2019):\nAuf der hinteren Linie außerhalb des Bunkers droppen. Dies ist die teuerste, aber oft praktischste Option bei sehr schwierigen Bunkerlagen.",
                    penalty = "1 oder 2 Strafschläge je nach Option",
                    tip = "Option 4 (+2) außerhalb des Bunkers ist teuer, spart aber oft viel Zeit und Nerven bei sehr schlechten Bunkerlagen."
                ),
                GolfRule(
                    title = "Bunker nach dem Spiel einrechen",
                    ruleNumber = "Regel 12 / Etikette",
                    body = "Es ist zwar keine offizielle Strafenschlag-Regel, aber eine wichtige Etikette-Pflicht: Bunker müssen nach dem Spielen sorgfältig eingerecht werden.\n\nReihenfolge beim Verlassen des Bunkers:\n1. Ball spielen\n2. Fußabdrücke und Schlägerspuren einrechen\n3. Rechen außerhalb des Bunkers ablegen (parallell zur Spiellinie)\n\nDer Rechen sollte möglichst flach hingelegt werden, damit kein anderer Ball daran hängen bleibt.\n\nIn Turnieren: Ein nicht eingerecter Bunker kann bei hartnäckiger Wiederholung als Langsamspiel oder unhöfliches Verhalten geahndet werden.",
                    tip = "Auch bei fremden Spuren einrechen – das schätzen alle Mitspieler."
                )
            )
        ),

        // MARK: Penalty Areas (Wasser)
        GolfRulesCategory(
            title = "Penalty Areas (Wasser)",
            subtitle = "Gelbe & rote Markierungen, Erleichterung",
            icon = "drop.fill",
            color = IosColor.blue,
            rules = listOf(
                GolfRule(
                    title = "Ball im Penalty Area spielen",
                    ruleNumber = "Regel 17.1b",
                    body = "Ein Ball in einem Penalty Area darf gespielt werden, wie er liegt – ohne Strafschlag.\n\nWichtig seit 2019: Der Schläger darf beim Ansprechen und beim Probeschwingen den Boden oder das Wasser berühren. Das war früher beim „Wasserhindernis\" verboten.\n\nErlaubt:\n✓ Schläger auf Wasser oder Boden im Penalty Area abstellen\n✓ Probeschwung durch Wasser oder Gras\n✓ Bewegliche Hemmnisse entfernen\n\nDas Spielen aus dem Penalty Area ist zwar möglich, aber oft riskant – besonders bei tiefem Wasser.",
                    tip = "Wenn der Ball spielbar liegt (z.B. am Rand), lohnt es sich manchmal trotzdem zu spielen."
                ),
                GolfRule(
                    title = "Gelb markiertes Penalty Area",
                    ruleNumber = "Regel 17.1d(i)",
                    body = "Liegt der Ball in einem gelb markierten Penalty Area oder ist dort verloren, gibt es drei Optionen:\n\nOption 1 – Ball aus dem Penalty Area spielen (kein Strafschlag)\n\nOption 2 – Schlag und Distanz (+1 Strafschlag):\nZurück zum Ort, von dem der Ball zuletzt gespielt wurde, und von dort neu spielen.\n\nOption 3 – Hintere Linie (+1 Strafschlag):\nBeliebig weit hinter dem Penalty Area auf der Linie Loch–Eintrittspunkt droppen. Je weiter hinten, desto klarer die Situation.\n\nEintrittspunkt = der Punkt, an dem der Ball zuletzt die Grenze des Penalty Area gekreuzt hat.",
                    penalty = "Option 2 & 3: je 1 Strafschlag",
                    diagram = RuleDiagram.penaltyArea
                ),
                GolfRule(
                    title = "Rot markiertes Penalty Area",
                    ruleNumber = "Regel 17.1d(ii)",
                    body = "Bei rot markierten Penalty Areas gelten alle drei Optionen wie beim gelben Penalty Area – plus eine zusätzliche Option:\n\nOption 4 – Seitliche Erleichterung (+1 Strafschlag):\nInnerhalb von 2 Schlägerlängen vom Eintrittspunkt droppen – nicht näher zum Loch.\n\nDer Eintrittspunkt kann auf beiden Seiten des Penalty Area liegen – der Spieler wählt die günstigere Seite.\n\nRote Markierung = mehr Flexibilität beim Erleichterungspunkt.\nGelbe Markierung = nur die drei Basisoptionen.",
                    penalty = "1 Strafschlag für alle Erleichterungsoptionen"
                ),
                GolfRule(
                    title = "Ball nicht auffindbar – Penalty Area bekannt",
                    ruleNumber = "Regel 17.1c",
                    body = "Wenn bekannt oder so gut wie sicher ist, dass der Ball in einem Penalty Area liegt (auch ohne ihn zu finden), darf der Spieler eine Erleichterung nach Regel 17.1d nehmen.\n\n„So gut wie sicher\" bedeutet: mind. 95% Wahrscheinlichkeit, dass der Ball dort liegt.\n\nDamit wird das langwierige Schlag-und-Distanz-Verfahren (Rücklauf zum Abschlag) vermieden, wenn klar ist, dass der Ball ins Wasser gegangen ist.\n\nPraxis: Ball war eindeutig im Wasser zu sehen/hören → Erleichterung ohne Suche erlaubt.",
                    tip = "Wenn der Ball ins Wasser gespritzt ist, kann direkt Erleichterung genommen werden – keine 3-Minuten-Suche nötig."
                ),
                GolfRule(
                    title = "Penalty Area als Erleichterungszone nutzen",
                    ruleNumber = "Regel 17.2",
                    body = "Besondere Situation: Der Ball liegt in einem Penalty Area und der Spieler möchte Erleichterung nehmen – aber der Erleichterungspunkt liegt ebenfalls in einem Penalty Area.\n\nIn diesem Fall darf der Spieler den nächsten Erleichterungspunkt außerhalb beider Penalty Areas wählen (unter Anwendung von Regel 17.1d).\n\nErleichterung für den Ball im Penalty Area schließt NICHT ein, dass in einem anderen Penalty Area gedroppt wird."
                )
            )
        ),

        // MARK: Grün
        GolfRulesCategory(
            title = "Grün",
            subtitle = "Putten, Fahne, Marke & Beschädigungen",
            icon = "circle.fill",
            color = IosColor.mint,
            rules = listOf(
                GolfRule(
                    title = "Ball markieren, aufnehmen und reinigen",
                    ruleNumber = "Regel 13.1b",
                    body = "Auf dem Grün darf der Ball jederzeit markiert, aufgenommen und gereinigt werden.\n\nMarkierverfahren:\n1. Platziere eine Marke (Münze, Ballmarker) direkt hinter dem Ball (in Richtung weg vom Loch)\n2. Nimm den Ball auf und reinige ihn vollständig\n3. Lege den Ball genau an die markierte Stelle zurück\n\nMarke verschieben: Falls die Marke im Weg eines Mitspielers liegt, darf sie um eine oder mehrere Schlägerkopfbreiten zur Seite geschoben werden – aber exakt wieder zurückverschieben.\n\nWird der Ball ohne Marke aufgenommen: 1 Strafschlag.",
                    tip = "Immer eine Münze oder einen Ballmarker in der Tasche haben.",
                    diagram = RuleDiagram.puttingGreen
                ),
                GolfRule(
                    title = "Fahne drin lassen oder herausnehmen",
                    ruleNumber = "Regel 13.2a",
                    body = "Seit 2019 ist es straflos, die Fahne beim Putten im Loch zu lassen – egal ob vom Grün oder von außerhalb.\n\nDrei Fahnen-Optionen:\n1. Fahne im Loch belassen (neu straflos seit 2019)\n2. Fahne herausnehmen und ablegen\n3. Fahne von jemandem bedienen lassen (herausnehmen sobald Ball näher kommt)\n\nTrifft der Ball die Fahne beim Putten → kein Strafschlag.\n\nVorteil Fahne drin: Bei schnellen Grüns oder bei Putts aus großer Entfernung kann die Fahne als Bremse wirken.\n\nAchtung: Steckt die Fahne nicht ordnungsgemäß im Loch → +1 Strafschlag wenn der Ball sie trifft.",
                    tip = "Statistisch zeigen Studien: Die Fahne drin zu lassen verbessert die Ein-Putt-Rate leicht."
                ),
                GolfRule(
                    title = "Schadstellen auf dem Grün reparieren",
                    ruleNumber = "Regel 13.1c",
                    body = "Folgende Schadstellen dürfen auf dem Grün repariert werden:\n\nErlaubt zu reparieren:\n✓ Balleinschlagmarken (Pitchmarks, Ballmarken)\n✓ Alte Lochmarkierungen (Plugs)\n✓ Schuhabdrücke und Schäden durch Tierhufe/-füße\n✓ Schäden durch Pflegemaschinen\n✓ Schäden durch eingebettete Gegenstände\n\nNicht erlaubt zu reparieren:\n✗ Normaler Verschleiß des Lochs (abgenutzte Ränder)\n✗ Aeration-Löcher\n✗ Narben durch Vertikutieren\n✗ Absetzung des Bodens durch Regen/Beregnung\n\nTipp: Pitchmarks immer mit einem Marker-Werkzeug reparieren, nicht mit dem Schläger – das beschädigt das Grün.",
                    tip = "Pitchmarks reparieren ist Pflicht und wichtig für die Greenqualität aller Spieler."
                ),
                GolfRule(
                    title = "Ball bewegt sich auf dem Grün",
                    ruleNumber = "Regel 13.1d",
                    body = "Bewegt sich der Ball auf dem Grün durch natürliche Kräfte (Wind, Schwerkraft, Wasser), muss er vom neuen Ort gespielt werden – kein Strafschlag.\n\nAusnahme – Ball wurde vorher markiert und aufgenommen:\nWird der Ball nach dem Aufnehmen durch Wind bewegt, bevor er zurückgelegt wird, muss er immer an den ursprünglichen Ort zurückgelegt werden.\n\nSonderfall beim Putten: Bewegt sich der Ball während des Schwungs, gilt der Schlag als gespielt, wenn der Schläger getroffen hat.\n\nAbsichtliches Einwirken: Bewegt der Spieler seinen Ball absichtlich oder fahrlässig → 1 Strafschlag und Ball zurücklegen."
                ),
                GolfRule(
                    title = "Falsches Grün",
                    ruleNumber = "Regel 13.1f",
                    body = "Liegt der Ball auf einem falschen Grün (Abschlagsgrün oder Grün eines anderen Lochs), muss straflose Erleichterung genommen werden – der Ball darf nicht von dort gespielt werden.\n\nVorgehen:\n1. Nächsten Erleichterungspunkt außerhalb des falschen Grüns bestimmen\n2. Innerhalb einer Schlägerlänge vom Erleichterungspunkt droppen\n3. Nicht näher zum Loch\n\nAuch wenn die Spiellinie oder der Stand auf ein falsches Grün reicht, muss Erleichterung genommen werden.\n\nKein Strafschlag – diese Erleichterung ist straflos."
                ),
                GolfRule(
                    title = "Putten: Spielreihenfolge auf dem Grün",
                    ruleNumber = "Regel 6.4",
                    body = "Grundregel: Es spielt zunächst, wer am weitesten vom Loch entfernt ist (furthest from the hole).\n\nReady Golf im Turnier: Viele Turniere erlauben (und empfehlen) „Ready Golf\" – spielen, sobald man bereit ist, auch wenn man nicht an der Reihe ist. Das beschleunigt das Spiel.\n\nAusnahme Matchplay: Die Reihenfolge wird strenger eingehalten – sie kann taktisch genutzt werden (Gegner „geben\" lassen).\n\nGegenseitiges Konzedieren (Matchplay): Kurze Putts können zugesprochen werden – der Gegner muss nicht einlochen.",
                    tip = "Im Zählspiel gilt Ready Golf: Spielen wenn bereit spart enorm Zeit."
                )
            )
        ),

        // MARK: Ball suchen
        GolfRulesCategory(
            title = "Ball suchen",
            subtitle = "Suchzeit, Identifikation & provisorischer Ball",
            icon = "magnifyingglass",
            color = IosColor.orange,
            rules = listOf(
                GolfRule(
                    title = "3-Minuten-Suchzeit",
                    ruleNumber = "Regel 18.2",
                    body = "Ein Ball gilt als verloren, wenn er nach 3 Minuten Suchen nicht gefunden wurde.\n\nZeitbeginn: Die 3 Minuten starten, wenn der Spieler oder sein Caddie beginnt, aktiv nach dem Ball zu suchen – nicht erst beim Ankommen.\n\nNach Ablauf der 3 Minuten:\n→ Ball gilt als verloren\n→ Folge: Schlag und Distanz (+1 Strafschlag)\n→ Zurück zum Ort des vorherigen Schlags\n\nVor Beginn der Suche: Unbedingt einen provisorischen Ball spielen, um Zeit zu sparen.\n\nHinweis: Selbst wenn der Ball nach Ablauf der 3 Minuten gefunden wird, darf er nicht mehr gespielt werden – er gilt als verloren.",
                    penalty = "Schlag und Distanz: 1 Strafschlag",
                    tip = "Immer einen provisorischen Ball spielen, bevor du zur Suche gehst!",
                    diagram = RuleDiagram.ballSearch
                ),
                GolfRule(
                    title = "Ball identifizieren",
                    ruleNumber = "Regel 7.2",
                    body = "Der Spieler ist verpflichtet, seinen Ball zu identifizieren. Kann der Ball nicht identifiziert werden, gilt er als nicht gefunden.\n\nIdentifikationsverfahren:\n1. Mitspieler/Marker informieren, dass Ball aufgenommen wird\n2. Marke hinter dem Ball platzieren\n3. Ball aufnehmen und nur soweit reinigen, wie für die Identifikation nötig\n4. Ball zurücklegen\n\nEigener Ball: Jeder Spieler sollte seinen Ball mit einer eindeutigen Markierung versehen (Punkt, Initials).\n\nOhne Ankündigung aufgenommen: 1 Strafschlag.\n\nWichtig: Die Identifikationsregel gilt nicht auf dem Grün – dort darf der Ball immer markiert und aufgenommen werden.",
                    penalty = "1 Strafschlag ohne Ankündigung"
                ),
                GolfRule(
                    title = "Beim Suchen: Ball nicht bewegen",
                    ruleNumber = "Regel 7.3 & 9.4",
                    body = "Beim Suchen des Balls dürfen Sand, Wasser und loses Gras zur Seite geschoben werden, um den Ball sehen zu können.\n\nWird dabei der Ball bewegt:\n• Vor 2019: Strafschlag\n• Ab 2019: Kein Strafschlag – aber der Ball muss an seinen ursprünglichen Ort zurückgelegt werden\n\nKein Strafschlag bei zufälliger Bewegung beim Suchen, solange der Ball sofort zurückgelegt wird.\n\nStrafschlag (1) gibt es nur wenn der Spieler:\n→ Den Ball absichtlich aufgehoben hat (ohne Erlaubnis)\n→ Den Ball vorsätzlich bewegt hat, um die Lage zu verbessern"
                ),
                GolfRule(
                    title = "Falscher Ball gespielt",
                    ruleNumber = "Regel 6.3c",
                    body = "Spielt ein Spieler einen falschen Ball (Fremdball), muss er den Fehler korrigieren und seinen eigenen Ball spielen.\n\nZählspiel: 2 Strafschläge + Korrektur\n• Die mit dem falschen Ball gespielten Schläge zählen nicht\n• Wird der Fehler nicht korrigiert: Disqualifikation\n\nMatchplay: Verlust des Lochs\n\nAusnahme: Ball im Bunker oder Penalty Area – kein Strafschlag beim versehentlichen Spielen eines falschen Balls im Bunker, wenn es zur Suche diente.\n\nSonderfall: Beim Putten auf dem Grün und ein anderer Ball rollt in den Weg → kein falscher Ball-Verstoß, Ball wird zurückgelegt.",
                    penalty = "2 Strafschläge (Zählspiel) / Lochverlust (Matchplay)"
                ),
                GolfRule(
                    title = "Lokale Regel: Alternative zu Schlag & Distanz",
                    ruleNumber = "Lokale Regel E-5",
                    body = "Viele Plätze erlauben als Lokale Regel: Statt Schlag und Distanz (zurück zum Abschlag) kann der Ball in der geschätzten Einschlagszone gedroppt werden – mit 2 Strafschlägen.\n\nVoraussetzungen:\n• Die Lokale Regel muss auf der Scorekarte oder am Platz ausgewiesen sein\n• Die geschätzte Einschlagszone muss auf dem Platz liegen (kein Penalty Area, nicht außerhalb)\n• Der Ball wird innerhalb 2 Schlägerlängen der geschätzten Zone gedroppt\n\nDiese Regel soll besonders für Freizeitrunden das Spiel beschleunigen.\n\nTurnierbedingungen: Nur gültig wenn auf der offiziellen Turnierausschreibung angegeben.",
                    penalty = "2 Strafschläge (nur bei aktivierter lokaler Regel)",
                    tip = "Frag beim Check-in, ob diese lokale Regel gilt – viele Plätze haben sie."
                )
            )
        ),

        // MARK: Ball außerhalb Grenzen
        GolfRulesCategory(
            title = "Ball außerhalb Grenzen",
            subtitle = "Aus, Grenzen & Erleichterungsoptionen",
            icon = "xmark.circle.fill",
            color = IosColor.red,
            rules = listOf(
                GolfRule(
                    title = "Was bedeutet ‚Außerhalb der Grenzen' (AUS)?",
                    ruleNumber = "Regel 18.2",
                    body = "Außerhalb der Grenzen (AUS) wird durch weiße Markierungen definiert:\n• Weiße Pfähle (stakes) – die innere Seite der Pfähle bildet die Grenzlinie\n• Weiße Linien – die innere Kante der Linie ist die Grenzlinie\n\nEin Ball ist erst dann AUS, wenn er vollständig außerhalb der Grenzlinie liegt. Ein Ball, der die Grenzlinie berührt oder darauf liegt, ist noch im Spiel.\n\nTeile des Spielers im AUS-Bereich: Der Spieler darf mit den Füßen im AUS stehen, sofern der Ball noch im Spiel liegt.\n\nFeste Gegenstände im AUS (Mauern, Zäune): Gelten als Grenzmarkierungen und geben keine Erleichterung.",
                    diagram = RuleDiagram.outOfBounds
                ),
                GolfRule(
                    title = "AUS-Ball: Schlag und Distanz",
                    ruleNumber = "Regel 18.2b",
                    body = "Liegt der Ball außerhalb der Grenzen, gilt: 1 Strafschlag + Rückkehr zum vorherigen Ort.\n\nBeispiele:\n• Teeshot ins AUS → Ball liegt mit Schlag 3 (1 Teeshot + 1 Strafschlag + Wiederholung)\n• Zweiter Schlag ins AUS → Ball liegt mit Schlag 4 (1+1+1+Wiederholung)\n\nProcedere:\n1. Zurück zum Ort des vorherigen Schlags\n2. 1 Strafschlag addieren\n3. Von dort neu spielen\n\nKein weiterer Schlag muss gespielt werden, solange noch ein Ball im Spiel ist (provisorischer Ball oder Rückkehr zum Tee).",
                    penalty = "1 Strafschlag + Wiederholung vom vorherigen Ort"
                ),
                GolfRule(
                    title = "Provisorischer Ball bei AUS-Verdacht",
                    ruleNumber = "Regel 18.3",
                    body = "Wenn ein Ball möglicherweise ins AUS gegangen ist oder verloren sein könnte, sollte ein provisorischer Ball gespielt werden.\n\nAnkündigungspflicht: „Ich spiele einen provisorischen Ball\" – ohne diese Ankündigung gilt der zweite Ball automatisch als Ball im Spiel (mit Strafschlag und Distanz).\n\nWas passiert dann:\n• Ursprünglicher Ball gefunden & im Spiel → Provisorischer Ball aufgeben\n• Ursprünglicher Ball AUS oder nicht gefunden → Provisorischer Ball wird Ball im Spiel\n• Hat der Spieler bereits mit dem provisorischen Ball am Ort des ursprünglichen Balls gespielt → Provisorischer Ball ist zwingend im Spiel\n\nDer provisorische Ball spart enorm viel Zeit – immer spielen!",
                    tip = "Provisorischen Ball IMMER ankündigen – sonst gilt er als Ball im Spiel."
                ),
                GolfRule(
                    title = "Spezialfall: AUS-Grenze durch Gebäude",
                    ruleNumber = "Regel 18 / Lokale Regel",
                    body = "Gebäude, Mauern und feste Zäune, die als AUS-Grenze dienen, geben keine straflose Erleichterung.\n\nLiegt der Ball an einer Hauswand (die die AUS-Grenze bildet), muss entweder gespielt werden oder Schlag und Distanz in Anspruch genommen werden.\n\nManchmal erlauben Lokale Regeln eine Erleichterung von bestimmten Strukturen (z.B. bei Clubhaus-Wänden). Diese müssen auf der Scorekarte angegeben sein.\n\nTipp: Bei Turnieren auf der Platzübersicht prüfen, ob Lokale Regeln für bestimmte Grenzen gelten."
                )
            )
        ),

        // MARK: Ball bewegt
        GolfRulesCategory(
            title = "Ball bewegt",
            subtitle = "Absichtlich, zufällig & natürliche Kräfte",
            icon = "arrow.up.and.down.circle.fill",
            color = IosColor.purple,
            rules = listOf(
                GolfRule(
                    title = "Ball durch natürliche Kräfte bewegt",
                    ruleNumber = "Regel 9.3",
                    body = "Bewegt sich der Ball im Spiel durch Wind, Wasser oder Schwerkraft (Hang), muss er vom neuen Ort gespielt werden – kein Strafschlag.\n\nAusnahmen – Ball muss zurückgelegt werden:\n1. Ball auf dem Grün, der zuvor markiert und aufgenommen wurde → zurück zum ursprünglichen Ort\n2. Ball wurde angesprochen (address position) und bewegt sich dann → Ball zurücklegen, kein Strafschlag (Regel 9.4)\n\nWichtig: „Natürliche Kräfte\" umfasst auch: Wasser, das den Ball mitreißt, und Äste, die durch Wind fallen und den Ball bewegen."
                ),
                GolfRule(
                    title = "Ball durch Spieler versehentlich bewegt",
                    ruleNumber = "Regel 9.4",
                    body = "Bewegt der Spieler seinen Ball im Spiel versehentlich:\n\nAb 2019 (vereinfacht): Kein Strafschlag mehr bei zufälliger Bewegung in den meisten Situationen.\n\nKein Strafschlag (Ball zurücklegen):\n• Beim Suchen des Balls\n• Bei der Standnahme\n• Beim Schwung (außer beim Schlag selbst)\n• Auf dem Grün beim Entfernen von Hemmnissen\n\nStrafschlag (1) gibt es nur noch wenn:\n• Der Spieler den Ball absichtlich aufgenommen hat (ohne Erlaubnis)\n\nFrüher (vor 2019): Strafschlag bei jeder versehentlichen Bewegung. Die neue Regelung ist viel spielerfreundlicher.",
                    penalty = "1 Strafschlag nur bei absichtlichem Aufnehmen ohne Erlaubnis"
                ),
                GolfRule(
                    title = "Ball in Bewegung trifft Person oder Ausrüstung",
                    ruleNumber = "Regel 11.1",
                    body = "Trifft ein Ball in Bewegung versehentlich eine Person, ein Tier oder Ausrüstung, gilt:\n\nGrundregel: Der Schlag wird gewertet und der Ball von dort gespielt, wo er zum Liegen kommt – kein Strafschlag.\n\nAusnahmen (Strafschlag möglich):\n• Spielt der Spieler absichtlich auf Ausrüstung oder Personen → allgemeiner Strafschlag\n• Ball trifft eigene Ausrüstung (Bag, Wagen) auf dem Grün → 1 Strafschlag + Ball zurücklegen\n\nSonderfall Grün: Wenn der Ball beim Putten die Fahne trifft (seit 2019 straflos), oder wenn der Ball einen Mitspieler/Caddie trifft → kein Strafschlag.\n\nAbsichtliches Ablenken: Versucht der Spieler, einen fahrenden Ball abzulenken → Disqualifikation oder Lochverlust.",
                    penalty = "Kein Strafschlag bei unbeabsichtigtem Treffen"
                ),
                GolfRule(
                    title = "Ball zurücklegen – korrektes Verfahren",
                    ruleNumber = "Regel 14.2",
                    body = "Ein Ball muss zurückgelegt werden, indem er auf den exakten Punkt gesetzt wird – nicht gedroppt.\n\nVorgehen:\n1. Ball an denselben Punkt setzen, von dem er aufgenommen wurde\n2. Kann der genaue Punkt nicht bestimmt werden → so nah wie möglich am geschätzten Punkt platzieren\n\nFalsch zurückgelegt: 1 Strafschlag\n• Ball gedroppt statt gesetzt (auf dem Grün)\n• Ball neben anstatt auf den Marker gesetzt\n• Ball an falschem Punkt zurückgelegt\n\nAuf dem Grün: Der Marker wird erst entfernt, wenn der Ball platziert ist, nicht vorher.",
                    penalty = "1 Strafschlag bei falschem Verfahren"
                ),
                GolfRule(
                    title = "Schlag gespielt aber Ball bewegt sich noch",
                    ruleNumber = "Regel 9.1b",
                    body = "Spielt ein Spieler einen Schlag, während sich der Ball noch bewegt, gibt es grundsätzlich einen Strafschlag.\n\nAusnahmen (kein Strafschlag):\n• Ball bewegt sich nach einem Schlag, der ihn nur getroffen hat (normaler Ballflug)\n• Ball bewegt sich durch einen anderen Ball, der ihn trifft\n• Ball auf dem Grün: Spieler wartet nicht, bis der Ball aufgehört hat zu rollen → kein Strafschlag\n\nMerke: Ein Spieler sollte warten, bis sein Ball vollständig zur Ruhe gekommen ist, bevor er den nächsten Schlag spielt.",
                    penalty = "1 Strafschlag (bei unerlaubtem Spielen des bewegten Balls)"
                )
            )
        ),

        // MARK: Matchplay
        GolfRulesCategory(
            title = "Matchplay",
            subtitle = "Loch-für-Loch-Wertung, Zugestehen & Ergebnis",
            icon = "person.2.fill",
            color = rgb(0.3f, 0.5f, 0.8f),
            rules = listOf(
                GolfRule(
                    title = "Wie Matchplay funktioniert",
                    ruleNumber = "Regel 3.2",
                    body = "Im Matchplay (Lochspiel) werden nicht Schläge gezählt, sondern Löcher gewonnen oder verloren.\n\nGrundprinzip:\n• Niedrigerer Netto-Score → Loch gewonnen\n• Höherer Score → Loch verloren\n• Gleicher Score → Loch geteilt (halved)\n\nDas Ergebnis wird in „Up/Down/All Square\" angegeben:\n• 2 up: Spieler führt mit 2 Löchern Vorsprung\n• All square: gleichstand\n• 3&2: Spieler hat 3 Löcher Vorsprung und es sind nur noch 2 zu spielen → Spiel vorbei\n\nDas Spiel endet, wenn der Vorsprung größer ist als die verbleibenden Löcher.",
                    diagram = RuleDiagram.matchplay
                ),
                GolfRule(
                    title = "Loch zugestehen (Concede)",
                    ruleNumber = "Regel 3.2b",
                    body = "Im Matchplay darf der Gegner einen Schlag, ein Loch oder das gesamte Match „zugeben\" (concede).\n\nAnwendung:\n• Schlag zugestehen: „Das Putt zählt\" – der Gegner muss nicht mehr einlochen\n• Loch zugestehen: Der Gegner gewinnt das Loch (jederzeit während des Lochs möglich)\n• Match zugestehen: Der Gegner gewinnt das gesamte Spiel\n\nWichtig: Eine Zugestehen ist bindend und kann nicht widerrufen werden.\n\nKein Strafschlag wenn ein zugestandener Schlag dennoch gespielt wird – das Ergebnis zählt aber nicht.",
                    tip = "Kurze Putts im Matchplay zugeben ist üblich – aber strategisch kann es auch Sinn machen, nicht zuzugeben."
                ),
                GolfRule(
                    title = "Spielreihenfolge im Matchplay",
                    ruleNumber = "Regel 6.4a",
                    body = "Im Matchplay hat die Spielreihenfolge strategische Bedeutung.\n\nAbschlag: Wer das vorherige Loch gewonnen hat, hat die „Ehre\" (spielt zuerst).\nBeim ersten Loch: Wird ausgelost oder durch Vereinbarung bestimmt.\n\nWeitere Schläge: Wer weiter vom Loch entfernt ist, spielt zuerst.\n\nFalsche Reihenfolge: Der Gegner kann den Schlag annullieren und den Spieler auffordern, in der richtigen Reihenfolge zu spielen. Diese Entscheidung muss sofort getroffen werden.\n\nReady Golf: Im Matchplay weniger verbreitet als im Zählspiel – die Reihenfolge kann taktisch genutzt werden."
                ),
                GolfRule(
                    title = "Handicap im Matchplay",
                    ruleNumber = "Regel 3.2c",
                    body = "Im Handicap-Matchplay erhält der schwächere Spieler Vorgabeschläge auf den Löchern mit den niedrigsten Spielvorgaben (Stroke Index 1, 2, 3 …).\n\nBerechnung:\n• Differenz der beiden Handicaps = Anzahl der Vorgabeschläge\n• Beispiel: Handicap 24 vs. 18 → 6 Vorgabeschläge auf den 6 schwierigsten Löchern (SI 1-6)\n\nAuf einem Vorgabeloch: Spieler mit Vorgabe erhält 1 Schlag Gutschrift → sein Netto-Score ist 1 Schlag besser.\n\nVorgabeschläge nicht deklariert: Wenn das Handicap-Verhältnis nicht vor dem Start vereinbart wurde, gilt das Spiel ohne Handicap.",
                    tip = "Vor dem Matchplay immer die Handicaps und Vorgabeschläge besprechen und bestätigen."
                )
            )
        ),

        // MARK: Turniere & Etikette
        GolfRulesCategory(
            title = "Turniere & Etikette",
            subtitle = "Wettspielregeln, Pace of Play & Verhalten",
            icon = "trophy.fill",
            color = rgb(0.8f, 0.6f, 0.1f),
            rules = listOf(
                GolfRule(
                    title = "Scorecard – Pflichten und Fehler",
                    ruleNumber = "Regel 3.3b",
                    body = "Im Zählspiel ist jeder Spieler für die Richtigkeit seiner Scorekarte verantwortlich.\n\nPflichten:\n• Spieler und Zählkartenschreiber (Marker) müssen unterschreiben\n• Scorekarte nach der Runde einreichen (kein Datum nötig, nur Score und Unterschrift)\n\nFehler auf der Scorekarte:\n• Zu hoher Score eingetragen → gilt als gespielt (kein Strafschlag)\n• Zu niedriger Score eingetragen → Disqualifikation\n• Fehlende Unterschrift → Disqualifikation\n\nSonderfall Stableford: Zu niedriger Brutto-Score → 2 Strafpunkte werden abgezogen (keine Disqualifikation).",
                    tip = "Immer die Scorekarte gründlich prüfen, bevor unterschrieben wird.",
                    diagram = RuleDiagram.scoringTable
                ),
                GolfRule(
                    title = "Pace of Play – Spielgeschwindigkeit",
                    ruleNumber = "Regel 5.6",
                    body = "Spieler sind verpflichtet, in einem angemessenen Tempo zu spielen.\n\nRichtwert für Turniergolf:\n• Max. 40 Sekunden pro Schlag\n• Erster Spieler auf dem Loch: max. 60 Sekunden\n\nDie Gruppe soll stets in Kontakt zur vorherigen Gruppe bleiben.\n\nBei Langsamspiel:\n1. Verwarnung durch Spielleitung\n2. Erster Verstoß: 1 Strafschlag\n3. Zweiter Verstoß: 2 Strafschläge\n4. Dritter Verstoß: Disqualifikation\n\nReady Golf: Im Zählspiel empfohlen – spielen sobald man bereit ist, auch wenn man nicht an der Reihe ist (außer beim Abschlag mit Ehrenrecht).",
                    tip = "Bei Turnieren: Bereit spielen (ready golf) beschleunigt das Spiel erheblich."
                ),
                GolfRule(
                    title = "Ratschläge – Was ist erlaubt?",
                    ruleNumber = "Regel 10.2",
                    body = "Im Wettspiel darf kein Rat eingeholt oder gegeben werden – außer vom eigenen Caddie.\n\nWas gilt als verbotener Rat:\n✗ Empfehlung welchen Schläger zu benutzen\n✗ Hinweis auf Schlägerhaltung oder Schwungsgedanke\n✗ Tipp zur Spiellinie beim Putten (außer eigener Caddie)\n✗ Entfernungsangaben die einen Rat beinhalten\n\nWas KEINE Ratschläge sind (erlaubt):\n✓ Allgemeine Platzbeschreibung (Bunkerpositionen, Greenform)\n✓ Entfernungsangaben (ohne Schläger-Empfehlung)\n✓ Windrichtung abschätzen\n✓ Lokale Regeln erklären\n\nCaddie: Darf umfassend beraten und auf Wunsch bei Schlagauswahl helfen.",
                    penalty = "2 Strafschläge (Zählspiel) / Lochverlust (Matchplay)"
                ),
                GolfRule(
                    title = "Disqualifikationsgründe (Auswahl)",
                    ruleNumber = "Regel 1–4",
                    body = "Häufige Disqualifikationsgründe im Turnier:\n\nScorekarte:\n✗ Zu niedrigen Score auf der Scorekarte eingetragen\n✗ Scorekarte nicht eingereicht\n\nRegelverstoß:\n✗ Falschen Ball gespielt und Fehler nicht korrigiert\n✗ Schlag nicht am richtigen Ort wiederholt (wenn nötig)\n✗ Angewendete Erleichterung war nicht erlaubt und Fehler nicht berichtigt\n\nVerhalten:\n✗ Vereinbarung zur Regelumgehung mit Mitspielern\n✗ Spielunterbrechung ohne Genehmigung\n\nSchutzmechanismus: Im Zweifel eine zweite Kugel spielen (Protest-Ball nach Regel 20.1c) und nach der Runde die Regelkommission befragen.",
                    tip = "Im Zweifel einen Protest-Ball spielen und nach der Runde die Regelkommission fragen – das schützt vor Disqualifikation."
                ),
                GolfRule(
                    title = "Schläger maximal 14 im Bag",
                    ruleNumber = "Regel 4.1a",
                    body = "Ein Spieler darf maximal 14 Schläger im Bag haben. Überschreitung führt zu Strafschlägen.\n\nStrafberechnung:\n• Pro Loch, auf dem der Verstoß begangen wurde (max. 2 Löcher pro Runde)\n• Muss der betreffende Schläger sofort für den Rest der Runde außer Betrieb genommen werden\n\nErsatz kaputte Schläger: Während der Runde darf ein durch normalen Spielbetrieb beschädigter Schläger ersetzt werden (kein Strafschlag).\n\nAbsichtliche Beschädigung zur Auswechslung: Nicht erlaubt → kein Anrecht auf Ersatz.\n\nTipp: Vor jeder Runde die Schlägerzahl zählen – 14 ist das Maximum.",
                    penalty = "2 Strafschläge/Loch (max. 4 Schläge) Zählspiel; Lochverlust/Loch (max. 2 Löcher) Matchplay"
                ),
                GolfRule(
                    title = "Etikette & Verhalten auf dem Platz",
                    ruleNumber = "Regel 1.2",
                    body = "Grundregeln für respektvolles Verhalten auf dem Golfplatz:\n\nMitspieler:\n✓ Ruhe beim Schwung anderer Spieler\n✓ Nicht im Sichtfeld des Spielers stehen\n✓ Schatten nicht auf die Spiellinie oder Puttlinie werfen\n\nPlatzpflege:\n✓ Divots (Grassoden) einsetzen oder mit Sand füllen\n✓ Pitchmarks auf dem Grün reparieren\n✓ Bunker einrechen nach dem Spielen\n✓ Fahne korrekt einsetzen\n\nTempo:\n✓ Ready Golf spielen\n✓ Schläger schon beim Gehen zum Ball auswählen\n✓ Bag auf dem schnellsten Weg zum nächsten Abschlag\n\nSanktionen bei nachhaltig unhöflichem Verhalten: Disqualifikation durch die Spielleitung möglich.",
                    tip = "Gute Etikette macht das Spiel für alle besser – und wird von Mitspielern immer geschätzt."
                )
            )
        )
    )
}
