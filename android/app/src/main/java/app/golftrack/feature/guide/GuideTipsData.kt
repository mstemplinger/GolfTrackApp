package app.golftrack.feature.guide

import androidx.compose.ui.graphics.Color
import app.golftrack.ui.theme.AppTheme

// Inhalte aus GolfGuideView.swift, TipsCategoryDetailView.swift und TipsView.swift (per Skript übertragen).

data class GuideStat(val label: String, val value: String, val color: Color)

data class GuideLesson(
    val title: String,
    val body: String,
    val tip: String? = null,
    val stats: List<GuideStat> = emptyList(),
)

data class GuideChapter(
    val number: Int,
    val title: String,
    val subtitle: String,
    val icon: String,
    val color: Color,
    val lessons: List<GuideLesson>,
)

object GolfGuideContent {
    val chapters: List<GuideChapter> = listOf(

        GuideChapter(
            number = 1,
            title = "Abschlag",
            subtitle = "Driver vs. 3-Holz, Genauigkeit & Strategie",
            icon = "figure.golf",
            color = AppTheme.gold,
            lessons = listOf(
                GuideLesson(
                    title = "Driver vs. 3-Holz",
                    body = "Ein weit verbreiteter Mythos ist, dass Golfer denken, sie schlagen weiter als sie es tatsächlich tun. Spieler verwechseln oft ihren längsten Schlag mit ihrem Durchschnitt.\n\nAuffällig ist, dass ein 3-Holz quer über alle Handicaps nur 1–2 % genauer ist als ein Driver – aber fast 30 Meter kürzer. Der Verzicht auf diese Distanz lohnt sich kaum.\n\nEmpfehlung: Schlag den Driver so oft wie möglich. Der minimale Genauigkeitsvorteil des 3-Holzes rechtfertigt den Distanzverlust von fast 30 Metern nicht.",
                    tip = "Verwende den Driver so oft wie möglich. Prüfe aber deine persönlichen Unterschiede zwischen Driver und 3-Holz.",
                    stats = listOf(
                        GuideStat(label = "Genauigkeitsvorteil 3-Holz", value = "1–2 %", color = IosColor.orange),
                        GuideStat(label = "Distanzverlust mit 3-Holz", value = "~27 m", color = IosColor.red)
                    )
                ),
                GuideLesson(
                    title = "Was 27 Meter mehr bringen",
                    body = "Wenn ein 14er-Handicapper statt des Durchschnittsdrivers seinen besten Drive schlägt, liegt er durchschnittlich 22 Meter näher an der Fahne.\n\nDiese 22 Meter näher erhöhen die Anzahl getroffener Grüns (GIR %) deutlich und verringern die durchschnittliche Nähe zur Fahne. Eine solche Verbesserung wirkt sich massiv auf das Scoring aus.\n\nDieselbe Logik gilt auch für den Vergleich Driver vs. 3-Holz: Mit dem Driver liegst du kürzer zum Grün, was einen genaueren Approach ermöglicht.",
                    tip = "Schlag den Driver so oft wie möglich – eine kürzere zweite Bahn bedeutet fast immer eine bessere Annäherung ans Grün.",
                    stats = listOf(
                        GuideStat(label = "Mehr Nähe durch längeren Drive", value = "22 m", color = AppTheme.gold)
                    )
                ),
                GuideLesson(
                    title = "Die Kosten von Ungenauigkeit",
                    body = "Shot-Scope-Daten zeigen genau, wie viele Schläge es kostet, in Bäume, Rough oder Bunker zu schlagen.\n\nDer schlimmste Ort für einen Amateurschlag ist der Fairway-Bunker – er kostet im Schnitt 1,4 Schläge pro Runde. Leichtes Rough oder Semi-Rough hingegen kostet kaum mehr als ein kürzerer Schlag vom Abschlag.\n\nDas bedeutet: Wer den Driver nimmt und leicht ins Semi-Rough trifft, steht nicht schlechter als jemand, der ein 3-Holz sauber auf das Fairway trifft.",
                    stats = listOf(
                        GuideStat(label = "Kostet Fairway-Bunker", value = "1,4 Schläge/Runde", color = IosColor.red),
                        GuideStat(label = "Kostet Semi-Rough", value = "~0 extra", color = AppTheme.gold)
                    )
                ),
                GuideLesson(
                    title = "Links, rechts oder beidseitig?",
                    body = "Einer der wichtigsten Erkenntnisse: Golfer überschätzen den Wert des Fairways.\n\nAuf einem Loch mit Wasser oder Bunker rechts lohnt es sich, auf das leichte Rough links zu zielen – das ergibt statistisch einen niedrigeren Score als auf die Mitte zu zielen.\n\n**Rechtsmisser:** Wer 25 Meter weiter links zielt (ins spielbare Rough), reduziert verlorene Schläge von 7 auf 2 aus 10 Drives.\n\n**Linksmisser:** Ziel 15 Meter nach rechts verschieben – Schlagverlust von 3,4 auf 0,9 senken.\n\n**Beidseitiger Misser:** Zielpunkt zwischen den Hindernissen wählen – spart 1,4 Schläge.",
                    tip = "Überschätze das Fairway nicht – leichtes Rough bietet oft genauso gute Bedingungen für den nächsten Schlag.",
                    stats = listOf(
                        GuideStat(label = "Ersparnis durch Zielpunktanpassung (Rechtsmisser)", value = "5 Schläge/10 Abschläge", color = AppTheme.gold)
                    )
                )
            )
        ),

        GuideChapter(
            number = 2,
            title = "Anspiel",
            subtitle = "Schlägerwahl, Genauigkeit & Distanzkontrolle",
            icon = "target",
            color = AppTheme.gold,
            lessons = listOf(
                GuideLesson(
                    title = "135-Meter-Schlag vom Fairway",
                    body = "Viele Golfer treffen Schlägerauswahl auf Basis ihrer gefühlten Distanz – nicht ihrer echten Durchschnittsdistanz. Das führt zu systematisch zu kurzen Annäherungen.\n\nEmpfehlung: Wähle immer einen längeren Schläger als du denkst, und orientiere dich an der GPS-Distanz zur Hinterkante des Grüns statt zur Mitte.\n\nShot-Scope-Daten zeigen: 72 % der Gefahrenzone liegt vor dem Grün (Bunker, Wasser). Nur 28 % liegt hinter dem Grün. Einen Schlag zu lang zu schlagen ist also deutlich besser als zu kurz.",
                    tip = "Orientiere dich beim Schläger wählen an der Distanz zur Hinterkante des Grüns – nicht zur Mitte.",
                    stats = listOf(
                        GuideStat(label = "Gefahr vor dem Grün", value = "72 %", color = IosColor.red),
                        GuideStat(label = "Gefahr hinter dem Grün", value = "28 %", color = IosColor.orange)
                    )
                ),
                GuideLesson(
                    title = "Innerhalb von 90 Metern",
                    body = "Innerhalb von 90 Metern werden Scores gemacht oder vernichtet. Wer diese Schläge gut spielt, verbessert sein Handicap deutlich.\n\nEin Schlag vom Fairway gibt bis zu 25 % mehr Chance, das Grün zu treffen – verglichen mit demselben Schlag aus dem Rough oder Bunker.\n\nTypischer Fehler bei 14ern: Die meisten Schläge missen kurz-rechts. Wer seinen Zielpunkt anpasst, kann die Anzahl getroffener Grüns mehr als verdoppeln und die durchschnittliche Nähe zur Fahne um 33 % verbessern.",
                    tip = "Justiere deinen Zielpunkt bei Wedge-Schlägen – bereits eine kleine Anpassung kann die Grüntreffquote mehr als verdoppeln.",
                    stats = listOf(
                        GuideStat(label = "Mehr Grüntreffer vom Fairway", value = "+25 %", color = AppTheme.gold),
                        GuideStat(label = "Weniger Nähe durch Zielpunktanpassung", value = "-33 %", color = AppTheme.gold)
                    )
                ),
                GuideLesson(
                    title = "Hybrid vs. Eisen",
                    body = "Über 180 Meter ist ein Hybrid fast doppelt so effektiv wie ein langes Eisen. Zwischen 165–180 Metern ist der Hybrid immer noch überlegen, aber der Abstand verringert sich.\n\nDie meisten Amateure sollten kein Eisen tragen, mit dem sie über 165 Meter schlagen – stattdessen einen Hybrid einsetzen.\n\nWer aus dem Bereich 145–200 Meter konsistentere Treffer erzielt, kann mehr als einen Schlag pro Runde sparen.",
                    tip = "Tausche Eisen, die du über 165 Meter schlagst, gegen Hybrids – du wirst konsistenter und triffst mehr Grüns.",
                    stats = listOf(
                        GuideStat(label = "Hybrid-Effektivität >180 m", value = "2× besser", color = AppTheme.gold),
                        GuideStat(label = "Score bei getroffem Grün", value = "2,2 Schläge bis Loch", color = AppTheme.gold),
                        GuideStat(label = "Score bei verfehlem Grün", value = "3,5 Schläge bis Loch", color = IosColor.red)
                    )
                )
            )
        ),

        GuideChapter(
            number = 3,
            title = "Kurzspiel",
            subtitle = "Schlägerwahl, Lob-Wedge & Bunker",
            icon = "figure.golf.circle",
            color = IosColor.orange,
            lessons = listOf(
                GuideLesson(
                    title = "Schlägerwahl im Kurzspiel",
                    body = "Kurzspiel erfordert viel Vorstellungskraft. Nicht jeder Schlag kann mit demselben Sand-Wedge gespielt werden.\n\nPGA-Tour-Profis kommen aus der Nähe des Grüns in 90 % der Fälle auf und ein – nicht weil sie besser putten, sondern weil sie den richtigen Schläger wählen.\n\nSchlechte Kurzspieler greifen 42 % der Zeit zum Lob-Wedge. Bessere Spieler nutzen ihn nur 8 % der Zeit – stattdessen verteilen sie ihre Schläge gleichmäßig auf 8-Eisen, 9-Eisen und PW.\n\nDas Ziel: den Ball so schnell wie möglich ins Rollen bringen.",
                    tip = "Wähle den Schläger, der den Ball am schnellsten zum Rollen auf dem Grün bringt – das ist fast immer ein niedriger loftiger Schläger.",
                    stats = listOf(
                        GuideStat(label = "Lob-Wedge-Nutzung schlechter Kurzspieler", value = "42 %", color = IosColor.red),
                        GuideStat(label = "Lob-Wedge-Nutzung guter Kurzspieler", value = "8 %", color = AppTheme.gold)
                    )
                ),
                GuideLesson(
                    title = "Die Lob-Wedge-Sucht",
                    body = "8–20 Handicapper greifen innerhalb von 20 Metern vom Grün in 38 % der Fälle zum Lob-Wedge – obwohl dieser Schläger nur für 8 % der erfolgreichen \"Up & Downs\" verantwortlich ist.\n\nWarum? Viele Golfer sehen Tour-Profis wie Phil Mickelson spektakuläre Lob-Wedge-Schläge spielen und denken: \"Das kann ich auch!\"\n\nDie harte Realität: Der Lob-Wedge erfordert einen präzisen Treff und eine exakte Technik. Ein leichter Fehler kostet mehrere Schläge.\n\nLösung: Beim nächsten Kurzspielschlag einen Schläger weniger nehmen als geplant.",
                    tip = "Nimmst du normalerweise das Sand-Wedge? Probiere das Pitching-Wedge. Nimmst du das PW? Nimm die 9. Dein Score wird es dir danken.",
                    stats = listOf(
                        GuideStat(label = "Lob-Wedge Up&Down Erfolg (8–20 HCP)", value = "~8 %", color = IosColor.red),
                        GuideStat(label = "Lob-Wedge-Nutzung (8–20 HCP)", value = "38 %", color = IosColor.orange)
                    )
                ),
                GuideLesson(
                    title = "Bunker-Spiel",
                    body = "Im Schnitt hast du 1–2 Grünside-Bunker-Schläge pro Runde. Schlechte Bunker-Technik kann den Score schnell in die Höhe treiben.\n\nFür höhere Handicapper: Das Ziel sollte immer sein, den Ball einfach aus dem Bunker und auf das Grün zu bringen. Ziele auf die Mitte des Grüns – das gibt die größte Fehlertoleranz.\n\nWichtig: Setze unterschiedliche Schläger rund ums Grün ein – du spielst fast nie denselben Schlag zweimal. Bring den Ball so früh wie möglich zum Rollen.",
                    tip = "Bunker-Spiel ist ein Bereich, den Amateure kaum üben. Nutze das nächste Mal am Platz die Bunker-Übungsanlage und baue Vertrauen auf.",
                    stats = listOf(
                        GuideStat(label = "Ø Bunker-Schläge pro Runde", value = "1–2", color = IosColor.orange)
                    )
                )
            )
        ),

        GuideChapter(
            number = 4,
            title = "Putten",
            subtitle = "Drei-Putt vermeiden, Distanzkontrolle & Linie",
            icon = "circle.fill",
            color = IosColor.purple,
            lessons = listOf(
                GuideLesson(
                    title = "Drei-Putt-Wahrscheinlichkeit",
                    body = "Schnellste Möglichkeit, den Score zu senken: Drei-Putts vermeiden.\n\n20er-Handicapper dreiputtens bei 19 % aller Löcher – das ist jedes 5. Loch. Selbst 8er-Handicapper dreiputtens noch auf jedem 10. Loch.\n\nDer Hauptgrund: schlechte Distanzkontrolle auf langen Putts. Ein 20er hinterlässt beim Drei-Putt einen zweiten Putt von durchschnittlich 2,7 Metern – und Jordan Spieth macht einen 2,7-Meter-Putt nur in 24 % der Fälle.",
                    tip = "Konzentriere dich vor dem Spiel darauf, lange Putts zu üben und ein Gefühl für Distanzkontrolle zu entwickeln.",
                    stats = listOf(
                        GuideStat(label = "Drei-Putt-Rate (20 HCP)", value = "19 %", color = IosColor.red),
                        GuideStat(label = "Drei-Putt-Rate (8 HCP)", value = "~10 %", color = IosColor.orange),
                        GuideStat(label = "Ø 2. Putt bei Drei-Putt (20 HCP)", value = "2,7 m", color = IosColor.red)
                    )
                ),
                GuideLesson(
                    title = "Putten: Kurz oder lang vorbei?",
                    body = "84 % aller Putts außerhalb von 1,5 Metern, die verfehlt werden, bleiben kurz. Das ist eine erschreckende Statistik – und du wirst es beim nächsten Runde bemerken.\n\nEinfach darauf achten, den Ball am Loch vorbeizubringen, verbessert die Einlochquote deutlich – und du kennst die Linie für den Rückputt besser.\n\nAb 1,5 Metern und darunter dreht sich das Bild: 86 % der verfehlten kurzen Putts gehen lang vorbei. Der typische Fehler: zu stark schlagen und einen gleich langen Rückputt hinterlassen.",
                    tip = "Sei mutig beim Putten – wer den Ball am Loch vorbeischlägt, gibt ihm zumindest eine Chance einzufallen. Und du kennst die Linie für den Rückputt.",
                    stats = listOf(
                        GuideStat(label = "Lange Putts (>1,5 m): Fehlschläge kurz", value = "84 %", color = IosColor.red),
                        GuideStat(label = "Kurze Putts (<1,5 m): Fehlschläge lang", value = "86 %", color = IosColor.orange)
                    )
                ),
                GuideLesson(
                    title = "Lag-Putten & Strategie",
                    body = "Die durchschnittliche erste Putt-Distanz für Handicap-Golfer ist 5,6 Meter vom Loch. Diese erste Putt-Distanz entscheidet, ob du einen Tipp-In oder einen schwierigen zweiten Putt bekommst.\n\nEffektiv entstehen die meisten Drei-Putts aus über 6 Metern. Ab ca. 6 Metern sollte das Ziel sein: \"Lag\" – also den Ball so nah wie möglich ans Loch heran zu bringen, um einen möglichst kurzen zweiten Putt zu hinterlassen.\n\nLag bedeutet nicht zu kurz lassen – sondern den zweiten Putt als Tipp-In zu planen.",
                    tip = "Denke ab 6 Metern in \"Lag\"-Modus: Ziel ist ein kurzer zweiter Putt, nicht unbedingt der erste ins Loch.",
                    stats = listOf(
                        GuideStat(label = "Ø erste Putt-Distanz (Handicap-Golfer)", value = "5,6 m", color = IosColor.purple),
                        GuideStat(label = "Meiste Drei-Putts ab", value = ">6 m", color = IosColor.red)
                    )
                ),
                GuideLesson(
                    title = "Das richtige Putter-Modell finden",
                    body = "Golfer wählen Putter oft nach Optik – aber Leistung ist entscheidend. Was für Jordan Spieth funktioniert, muss nicht für dich funktionieren.\n\nEmpfehlung: Tracke deine Performance mit verschiedenen Puttern über mehrere Runden. Ein klares Muster wird sich zeigen, welcher Putter für dich funktioniert.\n\nVertrauen in den Putter ist der Schlüssel. Nur ein Schläger, dem du vertraust, lässt dich in entscheidenden Momenten ruhig bleiben.",
                    tip = "Tracke deine Putt-Performance mit verschiedenen Puttern und wähle den, der dir die besten Ergebnisse liefert – nicht den, den dein Lieblingsprofi nutzt.",
                    stats = listOf()
                )
            )
        )
    )
}

data class GolfTip(val title: String, val body: String, val icon: String)

data class TipsCategory(val name: String, val icon: String, val color: Color)

object TipsCategoryContent {
    val categories = listOf(
        TipsCategory(name = "Anfänger", icon = "star", color = rgb(0.3f, 0.85f, 0.5f)),
        TipsCategory(name = "Technik", icon = "figure.golf", color = AppTheme.gold),
        TipsCategory(name = "Mental Game", icon = "brain.head.profile", color = rgb(0.6f, 0.5f, 1.0f)),
        TipsCategory(name = "Strategie", icon = "map", color = rgb(1.0f, 0.6f, 0.3f)),
    )

    val anfaenger: List<GolfTip> = listOf(
        GolfTip(
            title = "Griff entspannen",
            body = "Halte den Schläger wie ein Vogel – fest genug, damit er nicht wegfliegt, aber nicht so fest, dass du ihn erdrückst. Ein zu fester Griff blockiert die Handgelenke und kostet Distanz.",
            icon = "hand.raised.fill"
        ),
        GolfTip(
            title = "Standfläche prüfen",
            body = "Schulterbreiter Stand für normale Schläge. Die Füße zeigen leicht nach außen. Bei kurzen Eisen etwas enger stehen, bei Holz und Driver etwas breiter.",
            icon = "figure.stand"
        ),
        GolfTip(
            title = "Auge auf dem Ball",
            body = "Bewege den Kopf beim Schwung nicht. Fixiere einen konkreten Punkt auf dem Ball und behalte den Blick dort, bis der Schläger den Ball getroffen hat.",
            icon = "eye.fill"
        ),
        GolfTip(
            title = "Tempo ist alles",
            body = "Ein langsamer, gleichmäßiger Rückschwung erzeugt mehr Kraft als ein schneller. Verhältnis Rückschwung zu Durchschwung: 3:1. Eil dich nie beim Abschlag.",
            icon = "speedometer"
        ),
        GolfTip(
            title = "Chip-Technik",
            body = "Beim Chippen: Gewicht auf den vorderen Fuß, Ball in der Mitte des Stands, Handgelenke fest. Denke an eine Pendelbewegung vom Schultergelenk – kein Handgelenk-Flip.",
            icon = "arrow.down.right"
        ),
    )

    val technik: List<GolfTip> = listOf(
        GolfTip(
            title = "Schwungachse halten",
            body = "Die Wirbelsäule ist die Achse deines Schwungs. Bleib beim Rückschwung in der Vorbeuge und vermeide seitliches Wackeln. Eine stabile Achse = konsistente Trefferfläche.",
            icon = "arrow.up.arrow.down"
        ),
        GolfTip(
            title = "Hüftrotation",
            body = "Die Hüfte führt den Durchschwung an, nicht die Arme. Beginne den Durchschwung mit dem Drehen der Hüfte zur Zielseite. Die Arme folgen automatisch.",
            icon = "rotate.right"
        ),
        GolfTip(
            title = "Gewichtsverlagerung",
            body = "Im Rückschwung: 70% Gewicht aufs hintere Bein. Im Durchschwung: vollständige Verlagerung aufs vordere Bein. Am Ende: 90% Gewicht vorne, Zehen des hinteren Fußes am Boden.",
            icon = "scalemass.fill"
        ),
        GolfTip(
            title = "Flaches Anspiel",
            body = "Der Schläger sollte von innen auf den Ball treffen (Inside-Out-Bahn). Das erzeugt Draw-Spin und mehr Distanz. Verhindere ein Over-the-Top-Anspiel durch langsamen Beginn des Durchschwungs.",
            icon = "arrow.right.to.line"
        ),
        GolfTip(
            title = "Trefferfläche kontrollieren",
            body = "Triff die Mitte der Schlägerface. Off-Center-Hits kosten 10-15% Distanz. Übe mit Klebeband auf der Face, um dein Treffermuster zu sehen.",
            icon = "target"
        ),
    )

    val mentalGame: List<GolfTip> = listOf(
        GolfTip(
            title = "Pre-Shot Routine",
            body = "Entwickle eine feste Routine vor jedem Schlag: Stand hinter dem Ball, Ziellinie visualisieren, zwei Probeschwünge, einsteigen, Alignment checken, schlagen. Immer gleich – das beruhigt das Nervensystem.",
            icon = "repeat"
        ),
        GolfTip(
            title = "Einen Schlag nach dem anderen",
            body = "Golf besteht aus einzelnen, unabhängigen Schlägen. Ein Fehler beeinflusst den nächsten Schlag nicht – außer du lässt es zu. Atme tief durch und fokussiere dich nur auf den nächsten Schlag.",
            icon = "1.circle.fill"
        ),
        GolfTip(
            title = "Bogey akzeptieren",
            body = "Ein Bogey ist kein Fehler. Durchschnittliche Amateurspieler spielen konstant Bogey Golf. Wer Bogeys akzeptiert und Double Bogeys vermeidet, hat eine sehr gute Runde.",
            icon = "checkmark.circle.fill"
        ),
        GolfTip(
            title = "Visualisierung",
            body = "Stelle dir den idealen Flug des Balls vor, bevor du schlägst. Sieh das Ziel, sieh die Flugbahn, sieh den Ball landen. Dein Körper schlägt, was dein Geist sieht.",
            icon = "eye.fill"
        ),
        GolfTip(
            title = "Umgang mit Druck",
            body = "Wenn du nervös wirst: verlangsamter Schwung-Gedanke, tiefer Atemzug vor dem Schlag. Nervosität bedeutet, dass du dich kümmerst – nutze diese Energie positiv.",
            icon = "heart.fill"
        ),
    )

    val strategie: List<GolfTip> = listOf(
        GolfTip(
            title = "Course Management",
            body = "Spiele immer auf die große Fläche, nicht auf die Fahne. Ein Bogey von der Fairwaymitte ist besser als ein Triple vom Rough. Vermeide Hindernisse durch kluge Schlägerwahl.",
            icon = "map.fill"
        ),
        GolfTip(
            title = "Handicap klug nutzen",
            body = "Kenne deine Vorgabelöcher. Nutze deine Vorgabeschläge auf den schwierigsten Löchern strategisch. Ein Net Par auf Loch 1 (SI 1) ist sehr wertvoll.",
            icon = "trophy.fill"
        ),
        GolfTip(
            title = "Wind berücksichtigen",
            body = "Gegen den Wind: einen Schläger mehr, ruhiger schwingen, Ball tiefer halten. Mit dem Wind: Flugkurve wird länger, Kurzspiel wird schneller. Seitenwind: Ball auf die Windseite der Fahne zielen.",
            icon = "wind"
        ),
        GolfTip(
            title = "Putt-Strategie",
            body = "Beim ersten Putt: Ziel ist die Zone 50cm um den Ball – kein Dreiputtter. Beim zweiten Putt unter 1.5m: festes Tempo, schaue den Einloch-Punkt an, nicht den Ball. Vertraue deiner Linie.",
            icon = "circle.fill"
        ),
        GolfTip(
            title = "Risiko vs. Belohnung",
            body = "Frage dich vor jedem riskanten Schlag: Was ist das Worst-Case-Scenario? Wenn der Fehler einen Doppelbogey kostet, ist das Risiko meist nicht wert. Spiele sicher auf Score-Karte-Ziele.",
            icon = "exclamationmark.triangle.fill"
        ),
    )


    fun tips(category: TipsCategory): List<GolfTip> = when (category.name) {
        "Anfänger" -> anfaenger
        "Technik" -> technik
        "Mental Game" -> mentalGame
        "Strategie" -> strategie
        else -> emptyList()
    }
}

data class DailyTip(val title: String, val body: String, val icon: String) {
    companion object {
        val all: List<DailyTip> = listOf(
        DailyTip(title = "Ruhiger Griff", body = "Ein entspannter Griff sorgt für mehr Kontrolle und Konstanz.", icon = "hands.clap.fill"),
        DailyTip(title = "Vorschwung", body = "Nimm dir Zeit für den Vorschung – ein ruhiger Start verhindert Fehler im Abschwung.", icon = "arrow.up.circle.fill"),
        DailyTip(title = "Auge auf den Ball", body = "Halte den Kopf ruhig und den Blick auf den Ball bis nach dem Kontakt.", icon = "eye.fill"),
        DailyTip(title = "Standfestigkeit", body = "Schulterbreiter Stand gibt dir die beste Balance für kraftvolle Schläge.", icon = "figure.stand"),
        DailyTip(title = "Putting-Linie lesen", body = "Lies das Grün immer von hinter dem Ball und zusätzlich von der Seite.", icon = "scope"),
        DailyTip(title = "Windeinfluss", body = "Bei Gegenwind: weniger Schwung, mehr Schläger. Nicht gegen den Wind kämpfen.", icon = "wind"),
        DailyTip(title = "Kurzes Spiel", body = "70 % aller Schläge fallen innerhalb von 100 Metern. Übe Chip und Pitch täglich.", icon = "figure.golf"),
        DailyTip(title = "Platz-Management", body = "Spiele auf die sichere Seite, nicht auf die Fahne. Bogey ist besser als Doppelbogey.", icon = "map.fill"),
        DailyTip(title = "Pre-Shot-Routine", body = "Eine feste Routine vor jedem Schlag beruhigt die Nerven und verbessert die Konsistenz.", icon = "repeat.circle.fill"),
        DailyTip(title = "Mentale Stärke", body = "Vergiss den letzten schlechten Schlag sofort. Jeder Schlag ist ein Neuanfang.", icon = "brain.head.profile"),
        DailyTip(title = "Tempo beim Putten", body = "Das richtige Tempo ist wichtiger als die perfekte Linie. Übe Längenputts.", icon = "flag.fill"),
        DailyTip(title = "Abschwung", body = "Starte den Abschwung mit den Hüften, nicht mit den Armen – das gibt mehr Power.", icon = "arrow.down.circle.fill"),
        DailyTip(title = "Bunker-Strategie", body = "Im Bunker: offenes Clubface, offene Standfläche, schlage hinter den Ball – nicht auf ihn.", icon = "circle.dotted"),
        DailyTip(title = "Chip vs. Pitch", body = "Chip wenn möglich, pitch wenn nötig. Der Chip ist einfacher zu kontrollieren.", icon = "arrow.up.right.circle.fill"),
        DailyTip(title = "Körperdrehung", body = "Eine volle Schulter-Drehung im Rückschwung ist wichtiger als Armgeschwindigkeit.", icon = "arrow.clockwise.circle.fill"),
        DailyTip(title = "Spielplanung", body = "Plane jeden Loch rückwärts – von der Fahne zum Abschlag. Wo willst du einlochen?", icon = "map"),
        DailyTip(title = "Kurzspiel-Griff", body = "Halte den Putter und das Wedge fester als den Driver – mehr Kontrolle, weniger Fehlschläge.", icon = "hand.raised.fill"),
        DailyTip(title = "Augen über dem Ball", body = "Beim Putten sollten deine Augen direkt über dem Ball sein für die beste Linie.", icon = "eye.circle.fill"),
        DailyTip(title = "Atemtechnik", body = "Atme vor dem Schlag tief aus. Das entspannt die Muskeln und stabilisiert den Schwung.", icon = "lungs.fill"),
        DailyTip(title = "Downhill-Putts", body = "Bei Abwärtsputts: ziele einen Meter kürzer und schlage sanfter – das Grün macht den Rest.", icon = "arrow.down.right.circle.fill"),
        DailyTip(title = "Schläger-Auswahl", body = "Wähle immer einen Schläger mehr als du denkst. Die meisten Amateure spielen zu kurz.", icon = "slider.horizontal.3"),
        DailyTip(title = "Fairway-Bunker", body = "Im Fairway-Bunker: steile, saubere Bewegung. Treffe den Ball sauber, nicht den Sand zuerst.", icon = "arrow.up.and.down.circle.fill"),
        DailyTip(title = "Wasserhindernisse", body = "Zögere nicht zu lang bei Wasserhindernissen – spiele auf die sichere Seite.", icon = "drop.fill"),
        DailyTip(title = "Aufwärmen", body = "Beginne das Warm-up mit kurzen Schlägern und arbeite dich zum Driver vor.", icon = "flame.fill"),
        DailyTip(title = "Schlagfolge", body = "Übe die Reihenfolge: kurze Eisen → mittlere Eisen → Holz → Driver.", icon = "list.number"),
        DailyTip(title = "Regen & Nässe", body = "Bei Regen: trockene Handschuhe bereitstellen, langsamer schwingen, Ball tiefer tee-en.", icon = "cloud.rain.fill"),
        DailyTip(title = "Temposteuerung", body = "Ein gleichmäßiges Tempo – nicht Kraft – macht den guten Golfer aus.", icon = "speedometer"),
        DailyTip(title = "Rücken gerade", body = "Behalte die Wirbelsäulenneigung konstant durch den gesamten Schwung.", icon = "figure.walk"),
        DailyTip(title = "Spieltempo", body = "Spiele zügig. Schnelles Spiel entspannt und verbessert oft den Score.", icon = "timer"),
        DailyTip(title = "Driving Range", body = "Übe auf der Range mit Ziel, nicht nur zum Schlagen. Stelle dir immer ein Ziel vor.", icon = "target"),
        DailyTip(title = "3-Putt vermeiden", body = "Lage dich bei langen Putts auf 1 Meter ans Loch – vermisse nie die zweite Putt-Chance.", icon = "minus.circle.fill"),
        DailyTip(title = "Griff-Stärke", body = "Halte den Schläger wie ein rohes Ei – weder zu fest noch zu locker.", icon = "hand.thumbsup.fill"),
        DailyTip(title = "Ball-Position", body = "Driver: Ball an der linken Ferse. Kurze Eisen: Ballmitte des Stands.", icon = "arrow.left.and.right.circle.fill"),
        DailyTip(title = "Punch Shot", body = "Bei starkem Wind: kürzerer Rückschwung, Hands-ahead, weniger Loft.", icon = "bolt.circle.fill"),
        DailyTip(title = "Handicap verbessern", body = "Spiele öfter auf schwierigen Plätzen – das entwickelt dein Spiel schneller.", icon = "chart.line.uptrend.xyaxis"),
        DailyTip(title = "Mentale Vorbereitung", body = "Stelle dir jeden Schlag zuerst positiv vor, bevor du ihn ausführst.", icon = "lightbulb.fill"),
        DailyTip(title = "Tee-Höhe", body = "Driver: Ball sollte halb über der Clubkrone stehen. Eisen: nur leicht über dem Boden.", icon = "arrow.up.and.line.horizontal.and.arrow.down"),
        DailyTip(title = "Follow-Through", body = "Ein vollständiger Follow-Through zeigt, dass du korrekt durch den Ball gespielt hast.", icon = "checkmark.circle.fill"),
        DailyTip(title = "Platzregelkenntnisse", body = "Kenne die Grundregeln: kostenlose Erleichterung, Spielreihenfolge, markieren.", icon = "book.fill"),
        DailyTip(title = "Grünlesen", body = "Achte auf das Mährichtungsmuster des Grüns – es beeinflusst die Rollrichtung.", icon = "arrow.left.and.right"),
        DailyTip(title = "Schläger reinigen", body = "Saubere Schläger-Grooves geben mehr Spin und Kontrolle – besonders im Kurzspiel.", icon = "sparkles"),
        DailyTip(title = "Druck annehmen", body = "Übe unter Druck: Setze dir beim Üben kleine Wetten oder Regeln.", icon = "trophy.fill"),
        DailyTip(title = "Körpergewicht", body = "Im Rückschwung: Gewicht auf rechtes Bein. Im Durchschwung: Gewicht auf linkes Bein.", icon = "scalemass.fill"),
        DailyTip(title = "Distanzkontrolle", body = "Miss deine Schlagweiten mit GPS und passe sie ans Wetter und die Höhe an.", icon = "ruler.fill"),
        DailyTip(title = "Fehler analysieren", body = "Slice? Prüfe den offenen Clubface. Hook? Prüfe den zu starken Griff.", icon = "magnifyingglass.circle.fill"),
        DailyTip(title = "Chip-Technik", body = "Beim Chip: Hände führen den Schläger, kein Handgelenk-Break, Gewicht vorne.", icon = "arrow.right.circle.fill"),
        DailyTip(title = "Lob-Wedge", body = "Benutze das Lob-Wedge nur wenn nötig – es ist der schwierigste Schläger im Bag.", icon = "exclamationmark.triangle.fill"),
        DailyTip(title = "Gelassenheit", body = "Golf ist ein Marathon, kein Sprint. Ein schlechtes Loch ruiniert nicht die ganze Runde.", icon = "tortoise.fill"),
        DailyTip(title = "Griff-Typ", body = "Probiere Overlap- und Interlock-Griff aus – finde den, der sich natürlicher anfühlt.", icon = "hand.raised.fingers.spread.fill"),
        DailyTip(title = "Ziel-Ausrichten", body = "Richte Clubface zuerst auf das Ziel aus, dann stelle deinen Körper parallel dazu.", icon = "scope"),
    )
    }
}
