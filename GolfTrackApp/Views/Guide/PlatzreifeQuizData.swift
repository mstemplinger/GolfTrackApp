import SwiftUI

// MARK: - Category

enum QuizCategory: String, CaseIterable, Codable {
    case regeln         = "Regeln"
    case etikette       = "Etikette"
    case scoring        = "Wertung"
    case platz          = "Platz & Ausrüstung"
    case regelanwendung = "Regelanwendung"
    case handicap       = "Handicap & Platzreife"

    var icon: String {
        switch self {
        case .regeln:         return "book.closed.fill"
        case .etikette:       return "person.2.fill"
        case .scoring:        return "list.number"
        case .platz:          return "mappin.and.ellipse"
        case .regelanwendung: return "checklist"
        case .handicap:       return "chart.bar.fill"
        }
    }

    var color: Color {
        switch self {
        case .regeln:         return .red
        case .etikette:       return .blue
        case .scoring:        return AppTheme.gold
        case .platz:          return .orange
        case .regelanwendung: return .purple
        case .handicap:       return .teal
        }
    }

    /// Ob diese Kategorie zu den "Regelkenntnisse"-Fragen der Prüfung gehört
    var isRulesCategory: Bool {
        self == .regeln || self == .regelanwendung
    }
}

// MARK: - Question

struct QuizQuestion: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let category: QuizCategory
}

// MARK: - Question Bank

enum PlatzreifeQuestions {

    static let all: [QuizQuestion] = regeln + etikette + scoring + platz + regelanwendung + handicap

    // MARK: - Golfregeln (35 Fragen)
    static let regeln: [QuizQuestion] = [
        QuizQuestion(
            question: "Welche Farbe haben Markierungen für AUS (Out of Bounds)?",
            options: ["Weiß", "Gelb", "Rot", "Blau"],
            correctIndex: 0,
            explanation: "AUS wird immer mit weißen Stöcken oder weißen Linien auf dem Boden markiert. Weiß = AUS – der Ball muss erneut gespielt werden.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Welche Strafe gilt, wenn der Ball AUS liegt?",
            options: [
                "Kein Strafschlag – Ball am Eintrittspunkt droppen",
                "1 Strafschlag + erneut vom selben Ort spielen (Stroke and Distance)",
                "2 Strafschläge + Ball am nächsten Punkt droppen",
                "Disqualifikation vom Loch"
            ],
            correctIndex: 1,
            explanation: "„Stroke and Distance”: 1 Strafschlag und erneutes Spielen vom ursprünglichen Ort. Abschlag AUS = nächster Schlag ist der 3. Schlag.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Wie lange darf ein Ball gesucht werden?",
            options: ["5 Minuten", "2 Minuten", "3 Minuten", "Unbegrenzt"],
            correctIndex: 2,
            explanation: "Seit 2019 beträgt die Suchzeit 3 Minuten (Regel 18.2). Vorher waren es 5 Minuten. Nach Ablauf gilt der Ball als verloren.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was bedeutet ein „provisorischer Ball”?",
            options: [
                "Ein zweiter Ball für Übungszwecke",
                "Ein Ball, der gespielt wird, wenn der erste verloren sein könnte oder AUS liegt",
                "Ein Ersatzball nach einem Penalty-Area-Schlag",
                "Ein Reserveball für das nächste Loch"
            ],
            correctIndex: 1,
            explanation: "Der provisorische Ball spart Zeit: Er wird gespielt, wenn der erste Ball möglicherweise verloren ist oder AUS liegt. Wird der erste gefunden, muss der provisorische aufgenommen werden.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Welche Farbe haben Markierungen für ein normales Penalty Area (früher: Wasserhindernis)?",
            options: ["Rot", "Blau", "Gelb", "Weiß"],
            correctIndex: 2,
            explanation: "Gelbe Markierungen = normales Penalty Area. Optionen: Ball spielen wie er liegt, 1 Strafschlag + Droppen hinter dem Hindernis, oder Stroke and Distance.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Welche Farbe haben Markierungen für ein seitliches Penalty Area?",
            options: ["Gelb", "Weiß", "Rot", "Blau"],
            correctIndex: 2,
            explanation: "Rote Markierungen = seitliches Penalty Area. Bietet als Zusatzoption seitliches Droppen innerhalb 2 Schlägerlängen vom Eintrittspunkt.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Wie weit hinter den vorderen Abschlagsmarkierungen darf man den Ball aufteen?",
            options: ["1 Schlägerlänge", "2 Schlägerlängen", "3 Schlägerlängen", "Beliebig weit"],
            correctIndex: 1,
            explanation: "Der Abschlagsbereich reicht bis maximal 2 Schlägerlängen hinter den vorderen Abschlagsmarkierungen. Der Ball darf nicht vor den Markierungen liegen.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Darf der Fahnenstock im Loch bleiben, wenn man vom Grün puttet?",
            options: [
                "Nein – der Fahnenstock muss immer entfernt werden",
                "Nur wenn ein Mitspieler ihn hält",
                "Ja, seit 2019 ist das erlaubt (Regel 13.2a)",
                "Nur auf Par-3-Löchern"
            ],
            correctIndex: 2,
            explanation: "Seit Januar 2019 darf der Fahnenstock beim Putten im Loch bleiben. Trifft der Ball den Fahnenstock, gibt es keinen Strafschlag.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was bedeutet „GUR” auf einem Golfplatz?",
            options: [
                "Golfregel und Recht",
                "Grund in Ausbesserung – straffreie Erleichterung ist erlaubt",
                "Geringer Untergrund Richtwert",
                "Grüne Umgebungsregel"
            ],
            correctIndex: 1,
            explanation: "GUR = Grund in Ausbesserung (Ground Under Repair). Liegt der Ball in GUR, darf der Spieler straflos an der nächsten spielbaren Stelle droppen.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Darf man im Bunker den Sand mit dem Schläger vor dem Schlag berühren?",
            options: [
                "Ja, immer erlaubt",
                "Nur wenn es technisch nötig ist",
                "Nein – 1 Strafschlag",
                "Nur auf der Übungsanlage"
            ],
            correctIndex: 2,
            explanation: "Regel 12.2b: Im Bunker darf der Schläger den Sand vor dem Schlag nicht berühren. Strafe: 1 Strafschlag. Ausnahme: natürliche Stützung beim Stand.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was ist bei einem Ball in einem gelb markierten Penalty Area möglich?",
            options: [
                "Ball muss immer gespielt werden wie er liegt",
                "Straffreies Droppen hinter dem Hindernis",
                "1 Strafschlag + Droppen auf Linie hinter Eintrittspunkt ODER Stroke and Distance",
                "2 Strafschläge + seitliches Droppen"
            ],
            correctIndex: 2,
            explanation: "Optionen bei gelbem Penalty Area: (1) Ball spielen wie er liegt, (2) 1 Strafschlag + Droppen auf einer Linie rückwärts, (3) Stroke and Distance.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was passiert, wenn man versehentlich den eigenen Ball auf dem Grün bewegt?",
            options: [
                "1 Strafschlag – Ball bleibt liegen",
                "Kein Strafschlag – Ball muss zurückgelegt werden",
                "2 Strafschläge, Ball bleibt liegen",
                "Disqualifikation vom Loch"
            ],
            correctIndex: 1,
            explanation: "Seit 2019 (Regel 13.1d): Ball auf dem Grün versehentlich bewegt → kein Strafschlag, Ball zurücklegen.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Wann gilt ein Ball als offiziell „in Spiel”?",
            options: [
                "Wenn der Spieler das Tee einsteckt",
                "Sobald der Spieler auf dem Abschlag einen Schlag macht – auch bei einem Fehlschlag",
                "Wenn der Ball das Grün erreicht",
                "Wenn der Ball mehr als 20 Meter geflogen ist"
            ],
            correctIndex: 1,
            explanation: "Der Ball ist in Spiel, sobald der Spieler einen Schlag macht. Ein Fehlschlag (Air Shot) zählt als 1 Schlag – der Ball bleibt auf dem Tee in Spiel.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Darf man einen losen Gegenstand (z.B. Stein) in einem Bunker entfernen?",
            options: [
                "Nein – im Bunker darf nichts bewegt werden",
                "Ja, lose Gegenstände dürfen auch im Bunker straflos entfernt werden",
                "Nur wenn der Gegenstand den Schlag direkt behindert",
                "Nur nach dem Schlag"
            ],
            correctIndex: 1,
            explanation: "Regel 15.2a: Lose Gegenstände dürfen überall, auch im Bunker, straflos entfernt werden. Der Schläger darf den Sand dabei aber nicht berühren.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Darf man einen Ball auf dem Grün markieren, aufnehmen und reinigen?",
            options: [
                "Nein – der Ball muss liegen bleiben",
                "Ja, auf dem Grün darf der Ball immer markiert, aufgenommen und gereinigt werden",
                "Nur wenn der Ball im Weg eines Mitspielers liegt",
                "Nur bei Turnieren mit Schiedsrichter"
            ],
            correctIndex: 1,
            explanation: "Auf dem Grün darf der Ball immer markiert, aufgenommen und gereinigt werden (Regel 13.1b). Er muss genau an der Originalstelle zurückgelegt werden.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Wie viele Schläger darf ein Golfer maximal im Bag mitführen?",
            options: ["12", "14", "16", "Unbegrenzt"],
            correctIndex: 1,
            explanation: "Regel 4.1b: Maximal 14 Schläger. Für jeden zusätzlichen Schläger gibt es 2 Strafschläge pro Loch (max. 4 Schläge Gesamtstrafe).",
            category: .regeln
        ),
        QuizQuestion(
            question: "Wie wird seit 2019 ein Ball gedroppt?",
            options: [
                "Aus Schulterhöhe fallen lassen",
                "Aus Kniehöhe fallen lassen",
                "Den Ball auf den Boden legen",
                "Den Ball an einer markierten Stelle platzieren"
            ],
            correctIndex: 1,
            explanation: "Seit 2019 (Regel 14.3b): Der Ball wird aus Kniehöhe fallengelassen. Vorher war Schulterhöhe die Regel.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was passiert, wenn ein Spieler einen Doppeltreffer macht (Ball zweimal trifft)?",
            options: [
                "2 Schläge zählen (Schlag + Strafschlag)",
                "1 Strafschlag zusätzlich",
                "Nur 1 Schlag zählt – kein Strafschlag seit 2019",
                "Disqualifikation vom Loch"
            ],
            correctIndex: 2,
            explanation: "Seit 2019 (Regel 10.1a): Ein versehentlicher Doppeltreffer zählt nur als 1 Schlag – kein Strafschlag mehr. Früher gab es dafür 1 Strafschlag.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was ist die Regel bei einem Ball auf dem falschen Grün (Wrong Putting Green)?",
            options: [
                "Ball spielen wie er liegt",
                "1 Strafschlag + Ball droppen",
                "Straffreie Erleichterung – Ball muss außerhalb des falschen Grüns gedroppt werden",
                "2 Strafschläge + Ball auf eigenes Grün droppen"
            ],
            correctIndex: 2,
            explanation: "Regel 13.1f: Ball auf einem falschen Grün muss straflos außerhalb des falschen Grüns an der nächsten spielbaren Stelle gedroppt werden.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Wann muss ein provisorischer Ball aufgenommen werden?",
            options: [
                "Immer nach dem Finden des ersten Balls",
                "Wenn der erste Ball gefunden wird und gespielt werden muss (innerhalb der Suchzeit)",
                "Wenn der provisorische Ball näher am Loch liegt",
                "Nach 3 Schlägen mit dem provisorischen Ball"
            ],
            correctIndex: 1,
            explanation: "Wird der erste Ball innerhalb der Suchzeit gefunden und liegt er in Spiel (nicht AUS, nicht verloren), muss der provisorische Ball aufgenommen werden.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Darf man einen Ball auf dem Fairway (außerhalb des Grüns) reinigen?",
            options: [
                "Ja, immer erlaubt",
                "Nein, nur auf dem Grün darf der Ball gereinigt werden",
                "Nur wenn eine lokale Platzregel (Preferred Lies) dies erlaubt",
                "Ja, aber nur einmal pro Loch"
            ],
            correctIndex: 1,
            explanation: "Außerhalb des Grüns darf der Ball grundsätzlich nicht aufgenommen und gereinigt werden – außer es gilt eine lokale Platzregel (z.B. Winterregeln/Preferred Lies).",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was gilt, wenn der Ball nach dem Droppen aus der Drop-Zone rollt?",
            options: [
                "Ball liegt wo er zur Ruhe kommt",
                "Erneut droppen",
                "Ball an der Außengrenze der Drop-Zone platzieren",
                "1 Strafschlag + erneut droppen"
            ],
            correctIndex: 1,
            explanation: "Rollt der Ball nach dem Droppen aus der erlaubten Zone heraus, wird erneut gedroppt (Regel 14.3c). Nach dem zweiten Mal aus der Zone rollen wird der Ball platziert.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was ist die Regel bei einem eingebetteten Ball (Plugged Ball) im eigenen Gelände?",
            options: [
                "1 Strafschlag + Ball droppen",
                "Straffreie Erleichterung – Ball aufnehmen und direkt neben der Einschlagsstelle droppen",
                "Ball spielen wie er liegt",
                "2 Strafschläge + Ball auf dem Fairway droppen"
            ],
            correctIndex: 1,
            explanation: "Regel 16.3: Ein eingebetteter Ball im eigenen Gelände (z.B. nasses Fairway) bietet straffreie Erleichterung. Ball aufnehmen und direkt neben der Einschlagsstelle (nicht im Bunker) droppen.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was ist die Regel für einen Ball in einem Tierloch (z.B. Maulwurfshügel)?",
            options: [
                "1 Strafschlag + Ball droppen",
                "Ball spielen wie er liegt",
                "Straffreie Erleichterung – abnormale Platzverhältnisse",
                "2 Strafschläge + freie Wahl des Droppoints"
            ],
            correctIndex: 2,
            explanation: "Tierlöcher sind abnormale Platzverhältnisse (Regel 16.1) – straffreie Erleichterung ist erlaubt. Nächste straffreie Stelle ermitteln und innerhalb 1 Schlägerlänge droppen.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Darf man einen Ball für unspielbar erklären und welche Optionen gibt es?",
            options: [
                "Ja, überall außer im Penalty Area – 3 Optionen à 1 Strafschlag",
                "Nur im Rough, nicht auf dem Fairway",
                "Nein, unspielbar gilt nur im Bunker",
                "Ja, überall – 2 Strafschläge + freie Wahl"
            ],
            correctIndex: 0,
            explanation: "Regel 19: Unspielbar ist überall außer im Penalty Area möglich (1 Strafschlag). Die 3 Optionen: Stroke and Distance, 2 Schlägerlängen seitlich, oder auf einer Linie hinter dem Ball zurückdroppen.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was passiert, wenn ein Spieler aus der falschen Abschlagszone schlägt?",
            options: [
                "Kein Strafschlag – Ball wird gespielt wo er liegt",
                "Im Zählspiel: 2 Strafschläge + Schlag von der richtigen Abschlagszone wiederholen",
                "1 Strafschlag + Wiederholung",
                "Disqualifikation"
            ],
            correctIndex: 1,
            explanation: "Regel 6.1b: Im Zählspiel gibt es 2 Strafschläge und der Schlag muss von der richtigen Abschlagszone wiederholt werden. Im Matchplay: kein Strafschlag, der Gegner darf den Schlag annullieren.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Darf man das Grün abtasten, um die Beschaffenheit oder Neigung zu prüfen?",
            options: [
                "Ja, immer erlaubt",
                "Nur mit dem Finger, nicht mit dem Schläger",
                "Nein – das Grün darf nicht zum Testen der Oberfläche abgetastet werden",
                "Nur wenn der Caddie es macht"
            ],
            correctIndex: 2,
            explanation: "Regel 13.1e: Das Abtasten des Grüns zum Testen der Oberfläche (Rollrichtung, Härte) ist verboten. Strafe: 2 Strafschläge. Man darf das Grün aber anfassen um z.B. Schmutz zu entfernen.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was ist die Regel wenn der Ball beim Putten auf dem Grün den Ball eines Mitspielers trifft?",
            options: [
                "Kein Strafschlag – beide Bälle werden zurückgelegt",
                "Im Zählspiel: 2 Strafschläge für den Puttenden, der Mitspieler-Ball wird zurückgelegt",
                "1 Strafschlag für den Puttenden",
                "Der Mitspieler bekommt 2 Strafschläge"
            ],
            correctIndex: 1,
            explanation: "Regel 11.1b: Wird auf dem Grün ein ruhender Ball getroffen, gibt es im Zählspiel 2 Strafschläge für den Puttenden. Der Mitspieler-Ball wird an seine ursprüngliche Stelle zurückgelegt.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Darf ein Spieler während einer Runde neue Schläger hinzufügen, wenn er weniger als 14 hat?",
            options: [
                "Nein, die Anzahl ist zu Beginn der Runde festgelegt",
                "Ja, sofern das Spiel dadurch nicht verzögert wird",
                "Nur wenn ein Schläger beschädigt wurde",
                "Nur mit Genehmigung des Schiedsrichters"
            ],
            correctIndex: 1,
            explanation: "Regel 4.1b(2): Spieler dürfen Schläger hinzufügen, wenn sie noch unter 14 Schlägern sind – solange das Hinzufügen das Spiel nicht verzögert und der Schläger nicht von einem Mitspieler geliehen wird.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was ist bei einem Ball in einem roten Penalty Area (seitliches Wasserhindernis) die Zusatzoption gegenüber einem gelben?",
            options: [
                "Ball ist straflos zu spielen",
                "Seitliches Droppen innerhalb 2 Schlägerlängen vom Eintrittspunkt auf gleicher Seite",
                "Ball darf 1 Schlägerlänge vor dem Hindernis gedroppt werden",
                "Es gibt keinen Unterschied"
            ],
            correctIndex: 1,
            explanation: "Beim roten (seitlichen) Penalty Area gibt es als Zusatzoption: 1 Strafschlag + Ball seitlich innerhalb 2 Schlägerlängen vom Eintrittspunkt droppen (auf beiden Seiten möglich).",
            category: .regeln
        ),
        QuizQuestion(
            question: "Darf man vor dem Abschlag eine Probe-Schwungübung auf der Abschlagszone machen?",
            options: [
                "Nein, keine Übungsschwünge erlaubt",
                "Ja, Übungsschwünge (ohne den Ball zu treffen) sind auf dem Abschlag erlaubt",
                "Nur 1 Probschwung",
                "Nur wenn alle Mitspieler einverstanden sind"
            ],
            correctIndex: 1,
            explanation: "Übungsschwünge ohne Ballkontakt sind vor jedem Schlag erlaubt. Ein Fehlschlag (Air Shot mit Schlagabsicht) zählt aber als Schlag.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Welche Bereiche gehören zum „Allgemeinen Gelände” (General Area)?",
            options: [
                "Nur das Fairway",
                "Alle Bereiche des Platzes außer Abschlagszone, Grün, Bunker und Penalty Areas",
                "Fairway und Rough",
                "Alles außerhalb der Bunker"
            ],
            correctIndex: 1,
            explanation: "Das Allgemeine Gelände umfasst alles außer den 4 besonderen Bereichen: Abschlagszone des aktuellen Lochs, Penalty Areas, Bunker und Grün.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was ist die Regel, wenn der Ball nach einem Abschlag auf dem Abschlagsbereich liegen bleibt?",
            options: [
                "Ball muss gespielt werden wie er liegt – neu aufteen verboten",
                "Ball darf erneut auf einem Tee im Abschlagsbereich gespielt werden",
                "1 Strafschlag für den Fehlschlag",
                "Der Schlag zählt nicht – erneuter Versuch"
            ],
            correctIndex: 1,
            explanation: "Regel 6.2b(2): Bleibt der Ball nach dem Abschlag noch im Abschlagsbereich liegen, darf er erneut auf einem Tee gespielt werden. Der Schlag zählt natürlich.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was gilt, wenn der Ball durch Wind nach dem Adressieren bewegt wird?",
            options: [
                "1 Strafschlag + Ball zurücklegen",
                "Kein Strafschlag – Ball liegt wo er zur Ruhe kommt",
                "2 Strafschläge",
                "Ball zurücklegen ohne Strafschlag"
            ],
            correctIndex: 1,
            explanation: "Seit 2019: Bewegt Wind den Ball nach dem Adressieren, gibt es keinen Strafschlag – der Ball wird gespielt wo er zur Ruhe kommt (Regel 9.3). Früher war das ein Strafschlag.",
            category: .regeln
        ),
        QuizQuestion(
            question: "Was ist die maximale Strafstrafe pro Runde für zu viele Schläger im Bag?",
            options: ["2 Strafschläge", "4 Strafschläge", "6 Strafschläge", "Disqualifikation"],
            correctIndex: 1,
            explanation: "Für jeden überzähligen Schläger gibt es 2 Strafschläge pro Loch, auf dem der Verstoß bemerkt wird – jedoch maximal 4 Strafschläge pro Runde.",
            category: .regeln
        ),
    ]

    // MARK: - Etikette (25 Fragen)
    static let etikette: [QuizQuestion] = [
        QuizQuestion(
            question: "Was bedeutet „Ehre” auf dem Abschlag?",
            options: [
                "Der älteste Spieler schlägt zuerst",
                "Der Spieler mit dem niedrigsten Score auf dem vorigen Loch schlägt zuerst",
                "Der Gastgeber schlägt immer zuerst",
                "Der Spieler mit dem besten Handicap schlägt zuerst"
            ],
            correctIndex: 1,
            explanation: "Die Ehre hat der Spieler, der das vorige Loch mit der wenigsten Schlagzahl beendet hat. Beim ersten Loch wird die Reihenfolge vereinbart oder ausgelost.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Wofür ruft man „Fore!”?",
            options: [
                "Um anzukündigen, dass man abschlägt",
                "Als Warnung für Personen in oder nahe der Schlagrichtung",
                "Um einen verlorenen Ball zu melden",
                "Um die Gruppe dahinter zum Aufholen zu animieren"
            ],
            correctIndex: 1,
            explanation: "„Fore!” ist ein international verstandener Warnruf. Er wird gerufen, wenn ein geschlagener Ball in Richtung anderer Personen fliegt – zur Sicherheit aller.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Wie verhält man sich beim Putten eines Mitspielers am besten?",
            options: [
                "Direkt hinter ihm stehen um die Linie zu sehen",
                "Auf der verlängerten Putt-Linie stehen",
                "Seitlich stehen – weder auf der Putt-Linie noch störend",
                "Direkt neben dem Loch stehen"
            ],
            correctIndex: 2,
            explanation: "Man steht niemals auf der Spiellinie eines Mitspielers und stört ihn nicht durch Bewegung, Schatten oder Geräusche. Respektvoller Abstand ist Pflicht.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was soll man mit einem Ballpitchmark auf dem Grün tun?",
            options: [
                "Ignorieren – das ist Aufgabe des Greenpflegers",
                "Mit dem Pitchmark-Werkzeug ausbessern",
                "Mit dem Putterkopf abkratzen",
                "Nur den eigenen Pitchmark ausbessern"
            ],
            correctIndex: 1,
            explanation: "Ballpitchmarks sollen mit dem Pitchgabelwerkzeug ausgebessert werden – auch fremde. Richtiges Ausbessern erhält die Grünqualität für alle Spieler.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was muss man nach einem Schlag aus dem Bunker tun?",
            options: [
                "Den Bunker sofort verlassen und Spuren hinterlassen",
                "Den Bunker harken – alle Spuren sorgfältig beseitigen",
                "Den Caddie oder Mitspieler harken lassen",
                "Nichts – der Greenkeeper pflegt den Bunker"
            ],
            correctIndex: 1,
            explanation: "Nach dem Bunker-Schlag muss der Spieler alle Fußspuren und Schlagspuren mit dem Rechen beseitigen. Der Rechen liegt am Bunkerrand.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Wann soll man die nachfolgende Gruppe „durchwinken”?",
            options: [
                "Niemals – das ist unhöflich",
                "Wenn man beim Suchen Zeit verliert und die Gruppe dahinter wartet",
                "Immer wenn man einen schlechten Tag hat",
                "Nur auf dem 18. Loch"
            ],
            correctIndex: 1,
            explanation: "Verliert man Zeit beim Suchen und die Gruppe dahinter muss warten, soll man sie mit einem Handzeichen einladen vorzuziehen.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was soll man nach einem Eisenschlag auf dem Fairway tun?",
            options: [
                "Nichts – Divots gehören zum Spiel",
                "Den Divot zurücklegen oder mit Sand-/Saatgut-Gemisch auffüllen",
                "Den Divot wegwerfen",
                "Den Greenkeeper rufen"
            ],
            correctIndex: 1,
            explanation: "Divots (herausgeschlagene Rasenstücke) sollen zurückgelegt oder – falls ein Sand-/Saatgutbehälter vorhanden – damit aufgefüllt werden.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was bedeutet „Ready Golf”?",
            options: [
                "Immer schlägt der Spieler mit dem kürzesten Weg zum Ball zuerst",
                "Jeder Spieler schlägt, wenn er bereit ist – unabhängig von der Entfernung",
                "Nur erfahrene Spieler spielen nach dieser Methode",
                "Der schnellste Spieler auf dem Platz schlägt immer zuerst"
            ],
            correctIndex: 1,
            explanation: "Ready Golf: Wer bereit ist, schlägt als nächstes – unabhängig von der Entfernung. Das beschleunigt das Spiel und ist auf vielen Plätzen erwünscht.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Darf man auf dem Grün über die Putt-Linie eines Mitspielers steigen?",
            options: [
                "Ja, es ist egal wo man steht",
                "Nein – die Putt-Linie sollte nicht betreten werden",
                "Nur wenn man Golfschuhe trägt",
                "Nur wenn der Mitspieler einverstanden ist"
            ],
            correctIndex: 1,
            explanation: "Die Putt-Linie (Linie zwischen Ball und Loch) darf nicht betreten werden – Fußabdrücke können die Rollbahn beeinflussen.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Wo sollte man sein Trolley oder Bag auf dem Grün abstellen?",
            options: [
                "Direkt am Grünrand wo man hineingekommen ist",
                "Abseits des Grüns in Richtung des nächsten Abschlags",
                "Mitten auf dem Grün für kurze Wege",
                "Egal – Hauptsache nicht auf dem Fairway"
            ],
            correctIndex: 1,
            explanation: "Bag oder Trolley stellt man abseits des Grüns so ab, dass man nach dem Einlochen direkt Richtung nächsten Abschlag kann. Das beschleunigt den Spielfluss.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was ist „Slow Play” und was sind die Konsequenzen?",
            options: [
                "Ein Spielstil für Anfänger – erlaubt und normal",
                "Spielen deutlich langsamer als die Gruppe vor einem – kann zu Zeitstrafen führen",
                "Nur relevant bei Profiturnieren",
                "Ein Spielmodus mit mehr Bedenkzeit pro Schlag"
            ],
            correctIndex: 1,
            explanation: "Slow Play bedeutet, wesentlich langsamer als die Gruppe vor einem zu spielen. Es stört den Spielfluss aller und kann bei Turnieren zu Strafschlägen oder Disqualifikation führen.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Wie verhält man sich, wenn ein Mitspieler auf dem Abschlag steht?",
            options: [
                "Man kann ruhig schon zur eigenen Tasche gehen",
                "Hinter dem Spieler und seitlich stehen, still sein und nicht ablenken",
                "Man darf den Ball schon vorplatzieren",
                "In der Abschlagszone neben ihm stehen"
            ],
            correctIndex: 1,
            explanation: "Beim Abschlag eines Mitspielers steht man still, hinter ihm und seitlich (nie auf der Spiellinie), bewegt sich nicht und macht keine Geräusche.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Wann trägt man die Scorekarte aus?",
            options: [
                "Direkt nach dem Einlochen auf dem Grün",
                "Am nächsten Abschlag oder in Ruhe danach – nicht auf dem Grün",
                "Im Clubhaus nach der Runde",
                "Zwischen jedem Schlag"
            ],
            correctIndex: 1,
            explanation: "Die Scorekarte wird am nächsten Abschlag oder auf dem Weg dorthin ausgefüllt – nie auf dem Grün, da das nachfolgende Gruppen aufhält.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Darf man während einer Runde auf dem Platz Ratschläge geben oder annehmen?",
            options: [
                "Ja, von jedem beliebigen Spieler",
                "Nein, Rat darf nur innerhalb des eigenen Teams gegeben oder angenommen werden",
                "Nur der Caddie darf Rat geben",
                "Rat ist nur beim Regelbetreff erlaubt"
            ],
            correctIndex: 1,
            explanation: "Regel 10.2a: Rat (Tipps zur Schlägerwahl, Technik etc.) darf nur innerhalb des eigenen Teams gegeben oder angenommen werden. Rat von Mitspielern aus gegnerischen Teams gibt Strafschläge.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was bedeutet der Begriff „Spirit of the Game” im Golf?",
            options: [
                "Ein bestimmter Golfschlag für Fortgeschrittene",
                "Golf basiert auf Ehrlichkeit, Integrität und Respekt – meist ohne Schiedsrichter",
                "Der erste Schluck nach der Runde im Clubhaus",
                "Ein spezielles Trainingsformat"
            ],
            correctIndex: 1,
            explanation: "Golf ist der einzige Sport, in dem Spieler sich selbst disqualifizieren. Der „Spirit of the Game” steht für Ehrlichkeit, Respekt vor Mitspielern und fairer Spielweise.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was sollte man tun, wenn man sich bei einer Regel unsicher ist?",
            options: [
                "Das günstigere Ergebnis annehmen",
                "Im Zählspiel einen zweiten Ball spielen (Regelball) und danach beim Komitee klären",
                "Das Loch aufgeben",
                "Einfach weiterspielen und nichts sagen"
            ],
            correctIndex: 1,
            explanation: "Im Zählspiel: Regelball spielen (Regel 20.1c) – beide Bälle spielen und danach beim Komitee/Schiedsrichter klären. So verliert man keine Schläge durch eine falsche Entscheidung.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Darf man auf dem Platz Musik hören?",
            options: [
                "Ja, über laute Lautsprecher",
                "Nein, das ist auf allen Plätzen verboten",
                "Leise mit Kopfhörern – wenn es Mitspieler und die Platzordnung erlauben",
                "Nur auf dem Fairway, nicht auf dem Grün"
            ],
            correctIndex: 2,
            explanation: "Viele Plätze erlauben leises Musikhören mit Kopfhörern, solange Mitspieler nicht gestört werden. Laute Musik über Lautsprecher ist fast überall unerwünscht.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was ist bei einem Gewitter auf dem Golfplatz zu tun?",
            options: [
                "Unter dem nächsten Baum Schutz suchen",
                "Sofort das Spiel unterbrechen und ins Clubhaus oder unter ein Schutzdach gehen",
                "Schnell die restlichen Löcher spielen",
                "Weiterspielen – Blitz trifft selten"
            ],
            correctIndex: 1,
            explanation: "Bei Gewitter/Blitz: Sofort aufhören! Niemals unter einem Baum Schutz suchen. Zum Clubhaus, Unterstand oder flach ins Gelände legen. Golfschläger sind Blitzleiter.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Wie verhält sich ein Spieler, wenn er eine Gruppe überholen möchte?",
            options: [
                "Einfach an der Gruppe vorbeigehen",
                "Warten bis die Gruppe das Loch beendet hat und sie um Erlaubnis fragen",
                "Die Gruppe zur Seite drängen",
                "Den Platzwart rufen"
            ],
            correctIndex: 1,
            explanation: "Man überholt eine Gruppe nur mit deren Einverständnis. In der Regel wartet man bis sie das Loch vollendet haben und fragt dann höflich ob man vorgehen darf.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was sollte man tun, bevor man das Grün nach dem Einlochen verlässt?",
            options: [
                "Sofort zum nächsten Abschlag gehen",
                "Fahnenstock zurückstecken, Pitchmarks ausbessern, Grün so hinterlassen wie man es vorgefunden hat",
                "Noch eine Runde üben",
                "Auf die anderen Spieler warten und Scorekarte ausfüllen"
            ],
            correctIndex: 1,
            explanation: "Nach dem Einlochen: Fahnenstock zurückstecken, eigene und fremde Pitchmarks ausbessern und das Grün schnell verlassen – andere warten auf dem Fairway.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was ist die korrekte Schuhart für den Golfplatz?",
            options: [
                "Normale Sportschuhe mit Gummiprofil",
                "Golfschuhe mit Softspikes oder spikelos",
                "Fußballschuhe mit Kunststoffstollen",
                "Barfuß ist auf manchen Plätzen erlaubt"
            ],
            correctIndex: 1,
            explanation: "Golfschuhe mit Softspikes oder spikelos sind Standard. Metallspikes sind auf den meisten Plätzen verboten, da sie das Grün beschädigen. Fußballschuhe sind überall untersagt.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was bedeutet es, wenn ein Spieler seinen Ball für unspielbar erklärt?",
            options: [
                "Das entscheidet der Schiedsrichter",
                "Der Spieler selbst erklärt den Ball für unspielbar und nimmt 1 Strafschlag",
                "Der Ball gilt als verloren",
                "Mitspieler müssen bestätigen, dass der Ball unspielbar ist"
            ],
            correctIndex: 1,
            explanation: "Jeder Spieler darf seinen Ball jederzeit für unspielbar erklären (außer im Penalty Area) – das ist allein seine Entscheidung. Es gibt 1 Strafschlag.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was ist beim Verlassen des Bunkers zu beachten?",
            options: [
                "Durch den nächsten Ausgang verlassen, Spuren ignorieren",
                "Durch den flachsten Bereich (Ein-/Ausgang) verlassen und alle Spuren harken",
                "Über die Bunkerkante klettern",
                "Schläger im Bunker lassen damit der Greenkeeper harkt"
            ],
            correctIndex: 1,
            explanation: "Bunker durch den Ein-/Ausgang (flachste Stelle) verlassen – nicht über die Kante klettern. Alle Schlagspuren und Fußabdrücke sorgfältig harken.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Wie verhält man sich gegenüber einem Mitspieler der einen guten Schlag macht?",
            options: [
                "Ignorieren und zum nächsten Schlag übergehen",
                "Glückwunsch aussprechen – das gehört zum Sportsgeist im Golf",
                "Sich verstellen und nichts sagen",
                "Kommentare über seinen Glück machen"
            ],
            correctIndex: 1,
            explanation: "Golf lebt vom respektvollen Miteinander. Ein Glückwunsch nach einem guten Schlag ist fester Bestandteil des golferischen Sportsgeistes.",
            category: .etikette
        ),
        QuizQuestion(
            question: "Was sollte man tun, wenn man einen Ball findet, der nicht der eigene ist?",
            options: [
                "Ball aufnehmen und in der Tasche behalten",
                "Ball liegen lassen oder an eine Sammelstelle legen",
                "Ball in den nächsten Bunker werfen",
                "Ball dem Greenkeeper übergeben"
            ],
            correctIndex: 1,
            explanation: "Fremde Bälle lässt man liegen oder legt sie sichtbar seitlich des Platzes ab. Ball für sich behalten wäre wie Diebstahl.",
            category: .etikette
        ),
    ]

    // MARK: - Wertung / Scoring (25 Fragen)
    static let scoring: [QuizQuestion] = [
        QuizQuestion(
            question: "Was bedeutet „Par” bei einem Golfloch?",
            options: [
                "Die Mindestanzahl von Schlägen eines Profis",
                "Die Sollanzahl von Schlägen inkl. 2 Putts auf dem Grün",
                "Die maximale Schlagzahl vor Disqualifikation",
                "Der Durchschnittswert aller Spieler auf diesem Loch"
            ],
            correctIndex: 1,
            explanation: "Par ist die Sollanzahl von Schlägen (inkl. 2 Putts). Par 3 = kurze Löcher, Par 4 = mittlere Löcher, Par 5 = lange Löcher.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist ein „Birdie”?",
            options: ["2 über Par", "1 über Par", "1 unter Par", "2 unter Par"],
            correctIndex: 2,
            explanation: "Birdie = 1 Schlag unter Par. Auf einem Par-4: 3 Schläge. Der Begriff kommt aus dem Amerikanischen (bird = etwas Tolles).",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist ein „Eagle”?",
            options: ["1 unter Par", "2 unter Par", "3 unter Par", "Hole in One auf Par-3"],
            correctIndex: 1,
            explanation: "Eagle = 2 Schläge unter Par. Auf einem Par-5: 3 Schläge bis ins Loch. Sehr selten für Amateure.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist ein „Bogey”?",
            options: ["1 unter Par", "1 über Par", "2 über Par", "Einlochung vom Abschlag"],
            correctIndex: 1,
            explanation: "Bogey = 1 Schlag über Par. Auf einem Par-4: 5 Schläge. Double Bogey = 2 über Par, Triple Bogey = 3 über Par.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist ein „Hole in One” (As)?",
            options: [
                "Den Ball direkt vom Abschlag in einem Schlag einlochen",
                "Den Ball in genau 2 Schlägen einlochen",
                "Den ersten Schlag direkt aufs Grün spielen",
                "Einen Fehlschlag und dann direkt einlochen"
            ],
            correctIndex: 0,
            explanation: "Hole in One (As) = Der Ball wird direkt vom Abschlag in einem einzigen Schlag eingelocht. Das Seltenste im Golfsport!",
            category: .scoring
        ),
        QuizQuestion(
            question: "Wie viele Punkte erhält man beim Stableford für ein Par?",
            options: ["1 Punkt", "2 Punkte", "3 Punkte", "4 Punkte"],
            correctIndex: 1,
            explanation: "Stableford-Punkte: 0 = 2+ über Par, 1 = Bogey, 2 = Par, 3 = Birdie, 4 = Eagle, 5 = Albatross.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Wie viele Punkte erhält man beim Stableford für ein Birdie?",
            options: ["2 Punkte", "3 Punkte", "4 Punkte", "5 Punkte"],
            correctIndex: 1,
            explanation: "Birdie = 3 Punkte beim Stableford. Das ist der attraktivste Wert für Freizeitspieler.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Wie viele Punkte erhält man beim Stableford für einen Bogey?",
            options: ["0 Punkte", "1 Punkt", "2 Punkte", "3 Punkte"],
            correctIndex: 1,
            explanation: "Bogey = 1 Punkt beim Stableford. Damit trägt jedes Loch mit Bogey positiv zum Ergebnis bei.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Wann nimmt man beim Stableford den Ball auf (Pick Up)?",
            options: [
                "Wenn man 1 über Par liegt",
                "Wenn man das Grün noch nicht erreicht hat",
                "Wenn man die Schlagzahl erreicht hat, die 0 Punkte ergibt (2+ über Par)",
                "Immer nach 2 Putts"
            ],
            correctIndex: 2,
            explanation: "Beim Stableford: Hat man die Schlagzahl für 0 Punkte erreicht (Double Bogey oder schlechter), nimmt man den Ball auf – mehr Schläge bringen keine weiteren Punkte.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist das Ziel beim Zählspiel (Stroke Play)?",
            options: [
                "Pro Loch möglichst viele Stableford-Punkte",
                "Die Gesamtanzahl der Schläge minimieren",
                "Jedes Loch gegen den Gegner gewinnen",
                "Möglichst schnell spielen"
            ],
            correctIndex: 1,
            explanation: "Beim Zählspiel zählt jeder einzelne Schlag über alle 18 Löcher. Wer am Ende die wenigsten Schläge hat, gewinnt.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist das Ziel beim Matchplay?",
            options: [
                "Die niedrigste Gesamtschlagzahl",
                "Möglichst viele einzelne Löcher gegen den Gegner gewinnen",
                "Mehr Stableford-Punkte als der Gegner",
                "Kürzeste Gesamtzeit"
            ],
            correctIndex: 1,
            explanation: "Beim Matchplay gewinnt der Spieler, der mehr Löcher (nicht Schläge) als der Gegner gewinnt. „3 und 2” = 3 Löcher Vorsprung, noch 2 ausstehend.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was bedeutet „Netto-Score”?",
            options: [
                "Score ohne Strafschläge",
                "Brutto-Score minus der Spielvorgabe",
                "Score nur auf Par-3-Löchern",
                "Score ohne die drei schlechtesten Löcher"
            ],
            correctIndex: 1,
            explanation: "Netto-Score = Brutto-Score minus Spielvorgabe (Course Handicap). Macht Spieler unterschiedlicher Stärke vergleichbar.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist ein „Albatross” (auch Double Eagle)?",
            options: ["1 unter Par", "2 unter Par", "3 unter Par", "4 unter Par"],
            correctIndex: 2,
            explanation: "Albatross = 3 Schläge unter Par. Beispiel: ein Par-5-Loch in 2 Schlägen einlochen. Äußerst selten – seltener als ein Hole-in-One bei Par-4.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was bedeutet „All Square” im Matchplay?",
            options: [
                "Ein Spieler hat alle Löcher gewonnen",
                "Gleichstand – kein Spieler führt",
                "Das Spiel ist vorzeitig beendet",
                "Ein Loch wurde geteilt (Half)"
            ],
            correctIndex: 1,
            explanation: "„All Square” bedeutet Gleichstand im Matchplay – keiner der Spieler führt. Ein geteiltes Einzelloch nennt man „Half”.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was bedeutet „Dormie” im Matchplay?",
            options: [
                "Man liegt 1 Loch zurück",
                "Man führt genauso viele Löcher wie noch zu spielen sind",
                "Das Spiel wird nach 9 Löchern abgebrochen",
                "Man hat alle Löcher gewonnen"
            ],
            correctIndex: 1,
            explanation: "„Dormie” = man führt genauso viele Löcher wie noch zu spielen sind. Der Führende kann nicht mehr verlieren – im schlimmsten Fall ein Unentschieden.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist beim Stableford-Spiel mit Vorgabe der Effekt auf einem Vorgabeloch?",
            options: [
                "Man schlägt zwei Bälle und zählt den besseren",
                "Man erhält 1 Extraschlag – das effektive Par verschiebt sich um 1 Schlag",
                "Man bekommt 2 Strafschläge weniger",
                "Die Vorgabe gilt nur für das Gesamtergebnis, nicht pro Loch"
            ],
            correctIndex: 1,
            explanation: "Auf Vorgabelöchern erhält der Spieler 1 extra Schlag. Wer 18er Vorgabe hat, bekommt auf allen 18 Löchern 1 Schlag Vorgabe – Bogey entspricht dann 2 Punkten statt 1.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist der Unterschied beim Zählen von Schlägen bei Matchplay vs. Stroke Play?",
            options: [
                "Bei Matchplay zählen alle Schläge der Runde, bei Stroke Play nur pro Loch",
                "Bei Stroke Play zählen alle Schläge, beim Matchplay zählt nur ob man das Loch gewonnen hat",
                "Kein Unterschied",
                "Beim Matchplay gibt es Strafschläge, beim Stroke Play nicht"
            ],
            correctIndex: 1,
            explanation: "Beim Matchplay ist nur entscheidend, wer ein Loch mit weniger Schlägen spielt (Gewinner des Lochs). Die absolute Schlagzahl spielt keine Rolle für den Gesamtsieg.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist ein „Double Bogey”?",
            options: ["1 über Par", "2 über Par", "3 über Par", "Fehlschlag + Bogey"],
            correctIndex: 1,
            explanation: "Double Bogey = 2 Schläge über Par. Auf einem Par-4: 6 Schläge. Triple Bogey = 3 über Par.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Wie viele Punkte gibt es beim Stableford für ein Eagle?",
            options: ["3 Punkte", "4 Punkte", "5 Punkte", "6 Punkte"],
            correctIndex: 1,
            explanation: "Eagle = 4 Punkte beim Stableford (2 unter Par). Albatross wären 5 Punkte (3 unter Par).",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was bedeutet „1 up” im Matchplay?",
            options: [
                "Man hat 1 Schlag Vorsprung",
                "Man führt mit 1 Loch Vorsprung",
                "Man hat 1 Loch weniger gespielt",
                "Man hat 1 Strafschlag erhalten"
            ],
            correctIndex: 1,
            explanation: "„1 up” im Matchplay bedeutet: Man hat 1 Loch mehr gewonnen als der Gegner. Der Vorsprung zählt in Löchern, nicht in Schlägen.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist beim „Scramble” (Vierer-Format) die Spielweise?",
            options: [
                "Alle spielen abwechselnd denselben Ball",
                "Alle schlagen ab – bester Abschlag wird gewählt, alle spielen von dort weiter",
                "Der beste Spieler spielt alle Schläge",
                "Jeder spielt seinen eigenen Ball"
            ],
            correctIndex: 1,
            explanation: "Beim Scramble (Texas Scramble) schlagen alle Teammitglieder ab, der beste Ball wird ausgewählt, alle spielen vom nächsten Schlag vom gleichen Ort weiter.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist beim „Vierer” (Foursomes) die Spielweise?",
            options: [
                "Jeder spielt seinen eigenen Ball",
                "Beide Partner spielen abwechselnd mit einem Ball (Wechselschlag)",
                "Der beste Score pro Loch zählt",
                "Beide schlagen ab, bester Abschlag wird gespielt, dann Wechselschlag"
            ],
            correctIndex: 1,
            explanation: "Beim Vierer (Foursomes) spielen zwei Partner abwechselnd mit einem Ball – Wechselschlag. Der Abwechselschlag gilt auch beim Abschlag (Loch 1: Spieler A, Loch 2: Spieler B).",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist der „Better Ball” (Besser-Ball) im Team-Golf?",
            options: [
                "Beide Spieler teilen sich einen Ball",
                "Jeder spielt seinen eigenen Ball – der bessere Score pro Loch zählt für das Team",
                "Nur der Spieler mit dem besseren Handicap schlägt",
                "Der Ball der weiter fliegt wird gespielt"
            ],
            correctIndex: 1,
            explanation: "Beim Better Ball spielt jeder Partner seinen eigenen Ball. Pro Loch zählt der bessere (niedrigere) Score der beiden Partner als Teamergebnis.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist bei einem Stableford-Turnier die Mindestpunktzahl die man einreichen muss?",
            options: [
                "36 Punkte",
                "Es gibt keine Mindestpunktzahl – man reicht ein was man hat",
                "1 Punkt insgesamt",
                "Mindestens 1 Punkt pro Loch"
            ],
            correctIndex: 1,
            explanation: "Es gibt keine Mindestpunktzahl beim Stableford. Auf schlechten Löchern nimmt man den Ball auf (0 Punkte) und spielt weiter. Die Gesamtpunktzahl wird eingereicht.",
            category: .scoring
        ),
        QuizQuestion(
            question: "Was ist ein „Par” für den gesamten Platz?",
            options: [
                "Die Anzahl der Bunker auf dem Platz",
                "Die Summe der Par-Werte aller 18 Löcher (typisch 70–72)",
                "Die niedrigste je gespielte Runde",
                "Das Durchschnitts-Handicap aller Mitglieder"
            ],
            correctIndex: 1,
            explanation: "Platz-Par ist die Summe der Par-Werte aller 18 Löcher – typischerweise 70, 71 oder 72 Schläge für einen Scratch-Spieler.",
            category: .scoring
        ),
    ]

    // MARK: - Platz & Ausrüstung (20 Fragen)
    static let platz: [QuizQuestion] = [
        QuizQuestion(
            question: "Wie viele Löcher hat ein Standard-Golfplatz?",
            options: ["9", "12", "18", "24"],
            correctIndex: 2,
            explanation: "Ein Standardgolfplatz hat 18 Löcher. Manche Anlagen bieten auch 9-Loch-Kurse an.",
            category: .platz
        ),
        QuizQuestion(
            question: "Wie viele Schläger darf ein Golfer maximal im Bag mitführen?",
            options: ["12", "14", "16", "Unbegrenzt"],
            correctIndex: 1,
            explanation: "Regel 4.1b: Maximal 14 Schläger. Für jeden zusätzlichen gibt es 2 Strafschläge pro Loch (max. 4 Schläge gesamt).",
            category: .platz
        ),
        QuizQuestion(
            question: "Welche Teefarbe ist typischerweise die kürzeste und für Einsteiger geeignet?",
            options: ["Blau", "Gelb", "Schwarz", "Rot"],
            correctIndex: 3,
            explanation: "Die roten Tees sind die kürzesten. Schwarz = längste (Championship), Blau = Herren-Standard, Gelb = vordere Herren-Tees, Rot = Damen/Senioren/Einsteiger.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist ein „Driver” (1-Holz)?",
            options: [
                "Ein kurzes Eisen für Präzisionsschläge",
                "Der Schläger mit dem niedrigsten Loft für maximale Distanz",
                "Ein spezieller Putter für schnelle Grüns",
                "Ein Holz für Bunker-Schläge"
            ],
            correctIndex: 1,
            explanation: "Der Driver (1-Holz) hat den niedrigsten Loft (ca. 8–12°) und ist für maximale Distanz beim Abschlag auf langen Löchern gedacht.",
            category: .platz
        ),
        QuizQuestion(
            question: "Wofür wird ein Putter verwendet?",
            options: [
                "Für Abschläge auf Par-3-Löchern",
                "Für Annäherungsschläge ums Grün",
                "Primär zum Rollen des Balls auf dem Grün",
                "Für Schläge aus flachen Bunkern"
            ],
            correctIndex: 2,
            explanation: "Der Putter hat keinen oder fast keinen Loft und ist für das kontrollierte Rollen des Balls auf dem Grün Richtung Loch konzipiert.",
            category: .platz
        ),
        QuizQuestion(
            question: "Aus welchen Hauptbereichen besteht ein Golfloch?",
            options: [
                "Nur Abschlag und Grün",
                "Abschlagsbereich, Fairway, Rough, Hindernisse und Grün",
                "Abschlag, Bunker und Grün",
                "Nur Fairway und Grün"
            ],
            correctIndex: 1,
            explanation: "Jedes Loch besteht aus: Abschlagsbereich (Tee), Fairway (kurz gemäht), Rough (langes Gras), Hindernisse (Bunker, Wasser) und Grün mit Fahnenstock.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist ein „Sand Wedge”?",
            options: [
                "Annäherungsschläger für 100–130 m",
                "Schläger mit hohem Loft (54–58°) für Bunker und kurze Schläge",
                "Hybrid-Schläger für langes Rough",
                "Holz-Schläger für Rough-Schläge"
            ],
            correctIndex: 1,
            explanation: "Das Sand Wedge (SW) hat hohen Loft (ca. 54–58°) und breiten Bounce – speziell für Sandbucker und kurze Lob-Schläge entwickelt.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was bedeutet die Abkürzung „GIR”?",
            options: [
                "Green in Regulation – das Grün in der Soll-Schlagzahl treffen",
                "Golf International Rating",
                "General Impact Rule",
                "Green Improvement Rate"
            ],
            correctIndex: 0,
            explanation: "GIR = Green in Regulation: Das Grün in Par minus 2 Schlägen getroffen (für 2 Putts). Bei Par 4: Grün in Schlag 2. Wichtige Statistikgröße.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist ein „Hybrid”-Schläger?",
            options: [
                "Ein elektrisch angetriebener Golfkart",
                "Eine Kreuzung aus Holz und Eisen – leichter zu spielen als lange Eisen",
                "Ein Schläger speziell für nasses Wetter",
                "Ein Putter mit breitem Kopf"
            ],
            correctIndex: 1,
            explanation: "Hybrid-Schläger kombinieren die Einfachheit eines Holzes mit der Präzision eines Eisens. Sie sind einfacher zu spielen als lange Eisen (3–5 Eisen) und werden besonders im Rough empfohlen.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist „Loft” bei einem Golfschläger?",
            options: [
                "Das Gewicht des Schlägers in Gramm",
                "Der Winkel der Schlagfläche – beeinflusst Flugtrajektorie und Distanz",
                "Die Länge des Griffs",
                "Die Härte des Schlägerschafts"
            ],
            correctIndex: 1,
            explanation: "Loft ist der Winkel der Schlagfläche zur Vertikalen. Hoher Loft (z.B. Sand Wedge 54°) = hohe, kurze Flugbahn. Niedriger Loft (Driver 9°) = flache, weite Flugbahn.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist ein „Approach” (Annäherungsschlag)?",
            options: [
                "Der erste Abschlag auf einem Loch",
                "Ein Schlag Richtung Grün von Fairway oder Rough aus",
                "Ein Putt-Schlag von der Grünkante",
                "Ein Schlag aus dem Bunker"
            ],
            correctIndex: 1,
            explanation: "Ein Approach (Annäherungsschlag) ist jeder Schlag, der den Ball Richtung Grün bringen soll – vom Fairway, Rough oder kurzer Distanz aus.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist ein „Chip”-Schlag?",
            options: [
                "Ein langer Abschlag mit dem Driver",
                "Ein kurzer, niedriger Schlag von der Seite des Grüns – Ball soll schnell rollen",
                "Ein hoher Lob-Schlag über ein Hindernis",
                "Ein Schlag aus dem Bunker"
            ],
            correctIndex: 1,
            explanation: "Der Chip ist ein kurzer, niedriger Schlag von nahe am Grün. Der Ball fliegt kurz und rollt dann auf dem Grün zum Loch. Meist mit 7-Eisen bis PW gespielt.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was bedeutet „Lay Up”?",
            options: [
                "Den Ball so weit wie möglich schlagen",
                "Bewusst kurz schlagen, um eine Gefahr (Wasser, Bunker) zu umgehen",
                "Den Ball auf dem Grün markieren",
                "Ein Schlag aus dem Bunker"
            ],
            correctIndex: 1,
            explanation: "Lay Up bedeutet, den Ball bewusst kurz zu schlagen und eine Gefahr zu umgehen (z.B. Wasser vor dem Grün) – statt das Risiko einzugehen.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist eine „Driving Range”?",
            options: [
                "Ein spezieller Bereich auf dem Platz für Anfänger",
                "Eine Übungsanlage zum Schlagen und Trainieren",
                "Der erste Abschlag auf einem Golfplatz",
                "Ein Bereich für Annäherungsschläge"
            ],
            correctIndex: 1,
            explanation: "Die Driving Range ist eine Übungsanlage, auf der Golfer ihre Schläge trainieren können – ohne auf dem Platz zu sein.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist ein „Caddie”?",
            options: [
                "Ein elektrischer Golfkart",
                "Eine Person, die dem Golfer die Schlägertasche trägt und Rat geben darf",
                "Ein Platzwart der die Fahnen setzt",
                "Ein Scorekeeper beim Turnier"
            ],
            correctIndex: 1,
            explanation: "Ein Caddie trägt die Schlägertasche und darf dem Spieler Ratschläge zu Schlägerwahl, Strategie und Linien geben. Er ist Teil des Teams des Spielers.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist ein „Pitch”-Schlag?",
            options: [
                "Ein langer Holz-Schlag vom Abschlag",
                "Ein hoher, kurzer Schlag mit Rückspin auf das Grün",
                "Ein Putt von der Grünkante",
                "Ein Schlag unter einem Baum hindurch"
            ],
            correctIndex: 1,
            explanation: "Der Pitch ist ein hoher, kurzer Schlag (meist mit SW oder LW) der den Ball mit etwas Rückspin auf das Grün bringt. Weniger Roll als beim Chip.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was bezeichnet man als „19. Loch”?",
            options: [
                "Ein extra Loch bei Gleichstand",
                "Die Gaststätte / das Clubhaus nach der Runde",
                "Das schwierigste Loch auf dem Platz",
                "Ein Übungsloch für Anfänger"
            ],
            correctIndex: 1,
            explanation: "Das „19. Loch” ist ein scherzhafter Begriff für die Gaststätte oder die Clubhausbar – der gesellige Teil nach der Runde.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist ein „Pitching Wedge” (PW)?",
            options: [
                "Ein Eisen für lange Annäherungsschläge (150–170 m)",
                "Ein Wedge mit ca. 44–48° Loft für Schläge von ca. 100–130 m",
                "Ein Putter mit breiter Sole",
                "Ein Spezialschläger für nassen Boden"
            ],
            correctIndex: 1,
            explanation: "Das Pitching Wedge (PW) hat ca. 44–48° Loft und wird für Annäherungsschläge von ca. 100–130 m und Chip-Schläge verwendet.",
            category: .platz
        ),
        QuizQuestion(
            question: "Welche Farbe haben typischerweise die Markierungen für Penalty Areas auf einer deutschen Golfanlage?",
            options: [
                "Immer rot",
                "Immer gelb",
                "Gelb (normales Penalty Area) oder Rot (seitliches Penalty Area)",
                "Blau und Weiß"
            ],
            correctIndex: 2,
            explanation: "Penalty Areas können gelb (normales Penalty Area, 2 Erleichterungsoptionen) oder rot (seitliches Penalty Area, 3 Optionen) markiert sein.",
            category: .platz
        ),
        QuizQuestion(
            question: "Was ist ein „Tee” (Abschlagshilfe)?",
            options: [
                "Eine Grenzmarkierung für AUS",
                "Ein kleiner Stift auf dem der Ball beim Abschlag aufgesteckt wird",
                "Eine Befestigungsvorrichtung für den Fahnenstock",
                "Das Schlagflächenmaterial eines Holzes"
            ],
            correctIndex: 1,
            explanation: "Ein Tee ist ein kleiner Holz- oder Kunststoffstift, auf dem der Ball beim Abschlag aufgesteckt werden kann. Er darf nur im Abschlagsbereich verwendet werden.",
            category: .platz
        ),
    ]

    // MARK: - Regelanwendung (25 Fragen)
    static let regelanwendung: [QuizQuestion] = [
        QuizQuestion(
            question: "Dein Ball liegt in einer Pfütze auf dem Fairway (temporäres Wasser). Was machst du?",
            options: [
                "Ball aus der Pfütze spielen",
                "1 Strafschlag + Ball droppen",
                "Straffreie Erleichterung – nächste straffreie Stelle ermitteln und droppen",
                "Ball aufnehmen und Loch als verloren werten"
            ],
            correctIndex: 2,
            explanation: "Temporäres Wasser = straffreie Erleichterung nach Regel 16.1. Nächste spielbare Stelle ohne Behinderung ermitteln, innerhalb 1 Schlägerlänge droppen.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Abschlag-Ball landet AUS. Was ist dein nächster Schlag?",
            options: [
                "Dein 1. Schlag (Fehlschlag zählt nicht)",
                "Dein 2. Schlag (1 Strafschlag)",
                "Dein 3. Schlag (1. Abschlag + 1 Strafschlag = 2, nächster ist 3)",
                "Dein 4. Schlag"
            ],
            correctIndex: 2,
            explanation: "Stroke and Distance: Erster Abschlag (1) + 1 Strafschlag = 2 gezählte Einheiten. Du spielst also deinen 3. Schlag – erneut vom Abschlag.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Ein Mitspieler bewegt versehentlich deinen Ball auf dem Grün. Was passiert?",
            options: [
                "Du bekommst 1 Strafschlag",
                "Ball wird zurückgelegt – kein Strafschlag",
                "Der Mitspieler bekommt 2 Strafschläge",
                "Der Ball wird gespielt wo er liegt"
            ],
            correctIndex: 1,
            explanation: "Seit 2019: Wird ein Ball auf dem Grün versehentlich durch einen Mitspieler bewegt, wird er zurückgelegt – ohne Strafschlag für irgendjemanden (Regel 9.4).",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt nahe einem Wegweiser-Schild (unbewegliches Hemmnis). Hast du Anrecht auf Erleichterung?",
            options: [
                "Nein – nur natürliche Hindernisse bieten Erleichterung",
                "Ja – straffreie Erleichterung von unbeweglichen Hemmnissen",
                "Nur wenn der Schläger das Schild berühren würde",
                "Nur beim Anspiel, nicht beim Stand"
            ],
            correctIndex: 1,
            explanation: "Unbewegliche Hemmnisse (Wegweiser, Golfkart-Wege, Brunnen) bieten straffreie Erleichterung (Regel 16.1), wenn sie Schwung, Stand oder Spiellinie behindern.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du spielst einen Abschlag und schlägst den Ball nicht (Air Shot). Wie viele Schläge hast du gemacht?",
            options: [
                "0 Schläge – ein Fehlschlag zählt nicht",
                "1 Schlag – jeder Schwung mit Schlagabsicht zählt",
                "0,5 Schläge – wird aufgerundet",
                "Das entscheidet der Mitspieler"
            ],
            correctIndex: 1,
            explanation: "Jeder Versuch, den Ball zu schlagen (Schwung mit Schlagabsicht), zählt als 1 Schlag – auch ein vollständiger Fehlschlag (Air Shot). Der Ball bleibt in Spiel.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt in einem Bunker der durch Regen überflutet ist. Was kannst du tun?",
            options: [
                "Nur aus dem Bunker spielen – keine Erleichterung",
                "Straffreies Droppen im Bunker ODER 1 Strafschlag + außerhalb des Bunkers droppen",
                "Automatisch straffreie Erleichterung außerhalb",
                "Ball aufnehmen und Loch aufgeben"
            ],
            correctIndex: 1,
            explanation: "Temporäres Wasser im Bunker: Option 1 = straffreies Droppen an bester Stelle im Bunker. Option 2 = 1 Strafschlag + außerhalb hinter dem Bunker droppen (Regel 16.1c).",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du möchtest einen provisorischen Ball spielen. Was musst du vorher tun?",
            options: [
                "Nichts – einfach zweiten Ball spielen",
                "Den Mitspielern ankündigen, dass du einen provisorischen Ball spielst",
                "Den Schiedsrichter informieren",
                "3 Minuten warten"
            ],
            correctIndex: 1,
            explanation: "Vor dem provisorischen Ball muss angekündigt werden, dass es ein provisorischer Ball ist (Regel 18.3b). Ohne Ankündigung gilt der zweite Ball als der Ball in Spiel – der erste ist verloren.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt auf einem Kiesweg (Gravel Path). Hast du Anrecht auf straffreie Erleichterung?",
            options: [
                "Nein – natürliche Materialien bieten keine Erleichterung",
                "Ja – Kieswege sind unbewegliche Hemmnisse, straffreie Erleichterung",
                "Nur wenn der Weg offiziell markiert ist",
                "1 Strafschlag für straffreie Erleichterung"
            ],
            correctIndex: 1,
            explanation: "Kieswege, Golfkart-Wege und befestigte Wege sind unbewegliche Hemmnisse. Straffreie Erleichterung nach Regel 16.1: nächste straffreie Stelle + 1 Schlägerlänge droppen.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du puttest auf dem Grün und dein Ball trifft den Ball eines Mitspielers. Was passiert?",
            options: [
                "Kein Strafschlag – beide Bälle zurücklegen",
                "2 Strafschläge für dich im Zählspiel, Mitspieler-Ball wird zurückgelegt",
                "1 Strafschlag für dich",
                "Mitspieler bekommt 2 Strafschläge"
            ],
            correctIndex: 1,
            explanation: "Regel 11.1b: Wird auf dem Grün ein ruhender Ball getroffen, gibt es im Zählspiel 2 Strafschläge für den Puttenden. Der getroffene Ball wird zurückgelegt.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt auf einem Sprinklerkopf. Was gilt?",
            options: [
                "Ball spielen wie er liegt",
                "1 Strafschlag + Ball droppen",
                "Straffreie Erleichterung – Sprinklerköpfe sind unbewegliche Hemmnisse",
                "2 Strafschläge + freie Platzierung"
            ],
            correctIndex: 2,
            explanation: "Sprinklerköpfe sind unbewegliche Hemmnisse (Regel 16.1). Straffreie Erleichterung ist erlaubt: nächste straffreie Stelle ermitteln, innerhalb 1 Schlägerlänge droppen.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du findest nach 3 Minuten Suchen deinen Ball nicht. Was machst du?",
            options: [
                "Nochmal 2 Minuten suchen",
                "Ball gilt als verloren: Stroke and Distance – zurück zum Schlagort, 1 Strafschlag",
                "Ball auf dem Fairway droppen ohne Strafschlag",
                "Nächstes Loch beginnen"
            ],
            correctIndex: 1,
            explanation: "Nach Ablauf der 3-Minuten-Suchzeit gilt der Ball als verloren. Regel: Stroke and Distance – 1 Strafschlag + erneut vom letzten Schlagort spielen.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt so nahe an einem Busch, dass du keinen normalen Schwung machen kannst. Was tust du?",
            options: [
                "Ball spielen wie er liegt – auch mit eingeschränktem Schwung",
                "1 Strafschlag und Ball unspielbar erklären, dann Erleichterungsoption wählen",
                "Straffreie Erleichterung vom Busch",
                "Den Busch entfernen"
            ],
            correctIndex: 1,
            explanation: "Wachsende Gewächse sind Teil des Platzes – kein Anrecht auf straffreie Erleichterung. Option: Ball unspielbar erklären (1 Strafschlag) und eine der 3 Erleichterungsoptionen wählen.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du stößt versehentlich deinen Ball auf dem Fairway mit dem Fuß an. Was gilt?",
            options: [
                "Kein Strafschlag, Ball liegt wo er jetzt ist",
                "1 Strafschlag + Ball zurücklegen",
                "2 Strafschläge",
                "Ball spielen wie er jetzt liegt, kein Strafschlag"
            ],
            correctIndex: 1,
            explanation: "Regel 9.4: Bewegt ein Spieler versehentlich seinen eigenen Ball im Spiel (außer auf dem Grün), gibt es 1 Strafschlag und der Ball wird zurückgelegt.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du spielst versehentlich einen falschen Ball. Was gilt?",
            options: [
                "Kein Strafschlag, wenn der Ball einem Mitspieler gehört",
                "2 Strafschläge + du musst deinen eigenen Ball suchen und spielen",
                "1 Strafschlag + weiter mit dem falschen Ball",
                "Disqualifikation"
            ],
            correctIndex: 1,
            explanation: "Regel 6.3c: Falschen Ball spielen = 2 Strafschläge. Du musst dann deinen richtigen Ball finden und spielen. Vor Abschluss des Lochs nicht korrigiert = Disqualifikation.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt in einem alten Tierloch auf dem Fairway. Hast du straffreie Erleichterung?",
            options: [
                "Nein – Tierlöcher sind Teil des Platzes",
                "1 Strafschlag + Ball droppen",
                "Ja – Tierlöcher sind abnormale Platzverhältnisse, straffreie Erleichterung",
                "Nur wenn das Tier noch im Loch ist"
            ],
            correctIndex: 2,
            explanation: "Tierlöcher sind abnormale Platzverhältnisse (Regel 16.1). Straffreie Erleichterung: nächste straffreie Stelle, innerhalb 1 Schlägerlänge droppen.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du addressierst deinen Ball und er bewegt sich durch den Wind. Was gilt?",
            options: [
                "1 Strafschlag + Ball zurücklegen",
                "Kein Strafschlag – Ball liegt wo er zur Ruhe kommt",
                "2 Strafschläge",
                "Ball zurücklegen ohne Strafschlag"
            ],
            correctIndex: 1,
            explanation: "Seit 2019: Wind ist eine äußere Einwirkung. Bewegt Wind den Ball nach dem Adressieren, kein Strafschlag – Ball wird gespielt wo er liegt (Regel 9.3).",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt im Abschlagsbereich des falschen Lochs. Was tust du?",
            options: [
                "Von dort spielen – wo der Ball liegt",
                "Straffreies Droppen außerhalb des fremden Abschlagsbereichs",
                "Zurück zum eigenen Abschlag, 1 Strafschlag",
                "Loch überspringen"
            ],
            correctIndex: 1,
            explanation: "Der Abschlagsbereich des in Spiel befindlichen Lochs ist nicht der aktuelle. Straffreie Erleichterung nach Regel 13.1f – außerhalb droppen, nächste straffreie Stelle.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du kannst deinen Ball im Penalty Area nicht finden. Darf du die Penalty-Area-Erleichterung nutzen?",
            options: [
                "Nein – nur wenn der Ball gesehen wurde wie er ins Penalty Area ging",
                "Ja – wenn bekannt oder praktisch sicher ist, dass der Ball im Penalty Area liegt",
                "Nur wenn 3 Mitspieler es bestätigen",
                "Nein – unbekannter Aufenthaltsort gilt als verloren"
            ],
            correctIndex: 1,
            explanation: "Regel 17.1c: Ist es bekannt oder praktisch sicher, dass der Ball im Penalty Area liegt (auch wenn nicht gefunden), darf die Penalty-Area-Erleichterung genutzt werden.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt hinter einer Ausbesserungsmarke (GUR) und du hast bei deinem Schlag Beeinträchtigung. Was tust du?",
            options: [
                "Ball spielen wie er liegt",
                "1 Strafschlag + Ball droppen",
                "Straffreie Erleichterung – nächste straffreie Stelle außerhalb von GUR",
                "Schiedsrichter rufen und warten"
            ],
            correctIndex: 2,
            explanation: "GUR = Grund in Ausbesserung. Straffreie Erleichterung (Regel 16.1): nächste straffreie Stelle vom GUR ermitteln, innerhalb 1 Schlägerlänge droppen.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball trifft beim Abschlag einen Baum und kommt hinter die Abschlagsmarkierungen zurück. Was gilt?",
            options: [
                "Ball gilt als AUS – Stroke and Distance",
                "Ball neu aufteen – Abschlagsbereich gilt noch",
                "Ball liegt wo er ist und muss gespielt werden",
                "1 Strafschlag + erneut abschlagen"
            ],
            correctIndex: 2,
            explanation: "Liegt der Ball nach dem Abschlag außerhalb des Abschlagsbereichs (auch hinter den Markierungen), muss er gespielt werden wo er liegt. Kein Neu-Aufteen außerhalb des Abschlagsbereichs.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du spielst deinen Abschlag und der Ball bleibt im Abschlagsbereich liegen. Darf man neu aufteen?",
            options: [
                "Nein, immer vom Boden spielen",
                "Ja – Ball darf im Abschlagsbereich erneut auf einem Tee gespielt werden",
                "Nur wenn der Ball noch auf dem Tee liegt",
                "Nein, das gilt als zweiter Versuch"
            ],
            correctIndex: 1,
            explanation: "Regel 6.2b(2): Bleibt der Ball nach dem Abschlag noch im Abschlagsbereich liegen, darf er erneut auf einem Tee gespielt werden. Der Schlag zählt natürlich.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Ein Ast ist auf deinen Ball gefallen. Darf du den Ast entfernen?",
            options: [
                "Nein – natürliche Gegenstände dürfen nicht bewegt werden",
                "Ja – natürliche lose Hemmnisse dürfen straflos entfernt werden",
                "1 Strafschlag für das Entfernen",
                "Nur wenn der Ast den Schlag direkt blockiert"
            ],
            correctIndex: 1,
            explanation: "Regel 15.1a: Natürliche lose Hemmnisse (Äste, Blätter, Steine etc.) dürfen überall straflos entfernt werden – außer in speziellen Fällen im Bunker.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt direkt neben einem Sprinkler (am Rand des Grüns) und du willst putten. Hast du Erleichterung?",
            options: [
                "Nein – Erleichterung nur wenn der Ball auf dem Sprinkler liegt",
                "Ja – wenn der Sprinkler deinen Stand oder Schwung beim Putten behindert",
                "Nur außerhalb des Grüns",
                "Nein – immer spielen wie er liegt"
            ],
            correctIndex: 1,
            explanation: "Straffreie Erleichterung von unbeweglichen Hemmnissen (Regel 16.1) gilt auch wenn das Hemmnis nur den Stand oder Schwung behindert – nicht nur wenn der Ball darauf liegt.",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Du spielst ein Par-3 und dein Abschlag-Ball trifft die Fahne und fällt ins Loch. Was gilt?",
            options: [
                "Kein Zählen – Fahne war im Loch, Schlag muss wiederholt werden",
                "Hole in One! Ball ist eingelocht – kein Strafschlag",
                "1 Strafschlag wegen Treffen der Fahne",
                "2 Strafschläge + Schlag wiederholen"
            ],
            correctIndex: 1,
            explanation: "Seit 2019 darf die Fahne im Loch bleiben. Trifft der Ball die Fahne und fällt ins Loch, ist der Ball eingelocht – kein Strafschlag (Regel 13.2a). Hole in One!",
            category: .regelanwendung
        ),
        QuizQuestion(
            question: "Dein Ball liegt auf dem Grün und du markierst ihn falsch (Ball liegt nach dem Zurücklegen nicht genau an der Originalstelle). Was gilt?",
            options: [
                "Kein Problem, wenn die Abweichung gering ist",
                "1 Strafschlag wenn der Ball nicht an exakt der Originalstelle zurückgelegt wurde",
                "2 Strafschläge",
                "Disqualifikation"
            ],
            correctIndex: 1,
            explanation: "Regel 14.1b: Der Ball muss genau an seiner ursprünglichen Position zurückgelegt werden. Wird er an einer anderen Stelle zurückgelegt und gespielt, gibt es 1 Strafschlag.",
            category: .regelanwendung
        ),
    ]

    // MARK: - Handicap & Platzreife (20 Fragen)
    static let handicap: [QuizQuestion] = [
        QuizQuestion(
            question: "Wofür benötigt man die Platzreife?",
            options: [
                "Um auf einer Driving Range üben zu dürfen",
                "Um auf regulären Golfplätzen spielen und ein Handicap erhalten zu dürfen",
                "Um an PGA-Tour-Turnieren teilzunehmen",
                "Um Golfschläger kaufen zu dürfen"
            ],
            correctIndex: 1,
            explanation: "Die Platzreife berechtigt zum Spielen auf regulären 18-Loch-Plätzen und ist Voraussetzung für das offizielle DGV-Handicap.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Welches Handicap erhält man nach bestandener Platzreife?",
            options: ["36.0", "54.0", "28.0", "Wird individuell errechnet"],
            correctIndex: 1,
            explanation: "Nach bestandener Platzreife wird automatisch Handicap-Index 54.0 eingetragen – das Maximalhandicap im World Handicap System (WHS).",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was ist ein „Handicap” im Golf?",
            options: [
                "Eine körperliche Einschränkung des Spielers",
                "Ein Maß für das Spielniveau – je niedriger, desto besser",
                "Die Anzahl erlaubter Wiederholungsschläge",
                "Die maximale Schlagzahl pro Loch"
            ],
            correctIndex: 1,
            explanation: "Das Handicap ist ein Maß für das Spielniveau. Handicap 0 (Scratch) = durchschnittlich Par spielen. Je niedriger das Handicap, desto besser.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was ist das maximale Handicap im World Handicap System (WHS)?",
            options: ["36", "45", "54", "72"],
            correctIndex: 2,
            explanation: "Das maximale Handicap-Index im WHS beträgt 54.0. Dieses System gilt seit 2020 weltweit einheitlich.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was ist die „Spielvorgabe” (Course Handicap)?",
            options: [
                "Der offizielle Handicap-Index",
                "Das für einen bestimmten Platz und Tees angepasste Spielhandicap",
                "Die maximale Schlagzahl pro Loch",
                "Das Handicap nach einem Turniersieg"
            ],
            correctIndex: 1,
            explanation: "Die Spielvorgabe (Course Handicap) ist das für einen bestimmten Platz und Tees angepasste Handicap – berechnet aus Handicap-Index, Course Rating und Slope Rating.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was ist der „Course Rating” (Platzrating)?",
            options: [
                "Die Bewertung durch Gäste",
                "Die erwartete Schlagzahl eines Scratch-Spielers (HCP 0) auf diesem Platz",
                "Die Anzahl der Bunker",
                "Das Durchschnitts-Handicap aller Mitglieder"
            ],
            correctIndex: 1,
            explanation: "Der Course Rating ist die Schlagzahl, die ein Scratch-Spieler (HCP 0) unter normalen Bedingungen erwartet wird zu spielen.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was beschreibt der „Slope Rating”?",
            options: [
                "Die durchschnittliche Hangneigung",
                "Wie viel schwieriger der Platz für einen Bogey-Spieler vs. einen Scratch-Spieler ist",
                "Die Anzahl der Schräglagen",
                "Die Spielgeschwindigkeit"
            ],
            correctIndex: 1,
            explanation: "Der Slope Rating (Standard: 113) beschreibt die relative Schwierigkeit für einen Bogey-Spieler vs. einen Scratch-Spieler. Höherer Slope = mehr Vorgabe für schwächere Spieler.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Wie entwickelt sich das Handicap nach gespielten Runden?",
            options: [
                "Es bleibt immer bei 54",
                "Es wird nach jeder Runde automatisch angepasst",
                "Nur nach Turnierteilnahmen",
                "Einmal jährlich vom Verein"
            ],
            correctIndex: 1,
            explanation: "Im WHS wird das Handicap nach jeder eingereichten Runde automatisch angepasst. Bessere Runden senken das Handicap, schlechtere erhöhen es leicht.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was ist ein „Scratch-Spieler”?",
            options: [
                "Ein Spieler der gerade angefangen hat",
                "Ein Spieler mit Handicap 0",
                "Ein Spieler der nur auf der Driving Range übt",
                "Ein Spieler ohne DGV-Mitgliedschaft"
            ],
            correctIndex: 1,
            explanation: "Ein Scratch-Spieler hat Handicap 0 – er spielt im Durchschnitt Par. Das ist die Bezugsgröße für Course und Slope Rating.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was ist ein „Plus-Handicap”?",
            options: [
                "Ein besonders hohes Handicap für Anfänger",
                "Ein Handicap besser als Scratch (unter 0) – Spieler gibt Schläge ab",
                "Das Handicap nach bestandener Platzreife",
                "Ein Bonus für Kinder und Junioren"
            ],
            correctIndex: 1,
            explanation: "Ein Plus-Handicap (z.B. +2) bedeutet, der Spieler ist besser als Scratch. Er muss beim Netto-Spiel Schläge abgeben, anstatt Schläge zu erhalten.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was bedeutet „Netto” bei einem Turnier?",
            options: [
                "Spielen ohne Schläger",
                "Das Ergebnis nach Abzug der Spielvorgabe (Handicap)",
                "Spielen ohne Strafschläge",
                "Das Ergebnis der besten 9 Löcher"
            ],
            correctIndex: 1,
            explanation: "Netto-Ergebnis = Brutto (tatsächliche Schlagzahl) minus Spielvorgabe. Damit können Spieler unterschiedlicher Stärke fair miteinander verglichen werden.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Welche Runden fließen in die WHS-Handicap-Berechnung ein?",
            options: [
                "Nur Turniere mit Schiedsrichter",
                "Alle offiziell eingereichten Runden auf zugelassenen Plätzen",
                "Nur 18-Loch-Runden",
                "Nur Runden bei gutem Wetter"
            ],
            correctIndex: 1,
            explanation: "Im WHS können alle Runden auf zugelassenen Plätzen eingereicht werden – auch Freizeitrunden, 9-Loch-Runden (als Paar). Die besten 8 der letzten 20 Ergebnisse zählen.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was sind die Theorieinhalte der Platzreife-Prüfung?",
            options: [
                "Nur Geschichte des Golfsports",
                "Golfregeln, Etikette, Wertung, Handicap und Platzkunde",
                "Nur physische Schlagtechnik",
                "Marktwerte von Golfausrüstung"
            ],
            correctIndex: 1,
            explanation: "Die Platzreife-Theorieprüfung umfasst: Golfregeln (R&A/USGA), Etikette und Verhalten, Wertungsmethoden (Stroke Play, Stableford), Handicap-System und allgemeine Platzkunde.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was ist ein „Net Double Bogey” und wofür wird er verwendet?",
            options: [
                "Ein Ergebnis von 2 über Par im Netto",
                "Das maximale Zählergebnis pro Loch für die Handicap-Berechnung",
                "Ein Stablefordergebnis von 0 Punkten",
                "Eine Disqualifikation auf einem Loch"
            ],
            correctIndex: 1,
            explanation: "Net Double Bogey (Par + 2 + eventuelle Vorgabeschläge auf dem Loch) ist das Maximum das für die Handicap-Berechnung zählt. Schlechtere Ergebnisse werden auf diesen Wert begrenzt.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was versteht man unter einem „Handicap-Index”?",
            options: [
                "Die Schlagzahl bei der letzten Runde",
                "Eine portable Maßzahl des Spielpotenzials, gültig auf allen Plätzen weltweit",
                "Die Anzahl der gespielten Runden",
                "Die Mitgliedsnummer im Golfclub"
            ],
            correctIndex: 1,
            explanation: "Der Handicap-Index ist eine einheitliche, portierbare Maßzahl im WHS. Er gilt weltweit und wird für jeden Platz in eine Spielvorgabe (Course Handicap) umgerechnet.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Wie nennt man die Vorgabe eines Lochs (z.B. Loch 1 hat Vorgabe 3)?",
            options: [
                "Par-Wert",
                "Stroke Index (SI) – gibt an auf welchen Löchern Vorgabeschläge gelten",
                "Slope-Wert des Lochs",
                "Handicap des Lochs"
            ],
            correctIndex: 1,
            explanation: "Der Stroke Index (SI) eines Lochs bestimmt, auf welchen Löchern ein Spieler seinen Vorgabeschlag erhält. SI 1 = schwierigster Loch (bekommt Vorgabeschlag zuerst).",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was passiert wenn man bei einem Turnier eine falsche (zu niedrige) Scorekarte einreicht?",
            options: [
                "Kein Problem – die Abweichung wird korrigiert",
                "Disqualifikation",
                "2 Strafschläge",
                "Die Karte wird ungültig"
            ],
            correctIndex: 1,
            explanation: "Regel 3.3b: Reicht ein Spieler eine Scorekarte mit zu niedrigen Schlagzahlen ein (auch versehentlich), ist er disqualifiziert. Zu hohe Zahlen sind nicht rückgängig zu machen.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Darf man als Platzreife-Inhaber direkt an offiziellen Clubturnieren teilnehmen?",
            options: [
                "Nein, man muss 6 Monate warten",
                "Ja, mit der Platzreife ist man turnierberechtigt",
                "Nur bei Anfängerturnieren",
                "Erst ab Handicap 36"
            ],
            correctIndex: 1,
            explanation: "Mit der bestandenen Platzreife und dem daraus resultierenden Handicap 54 ist man grundsätzlich turnierberechtigt und kann an offiziellen Club-Turnieren teilnehmen.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Was bedeutet „Brutto-Score”?",
            options: [
                "Der Score ohne Strafschläge",
                "Die tatsächliche Schlagzahl ohne Abzug des Handicaps",
                "Das Ergebnis nur auf Par-3-Löchern",
                "Der Score inkl. Bonus für besonders gute Schläge"
            ],
            correctIndex: 1,
            explanation: "Der Brutto-Score ist die tatsächliche Gesamtschlagzahl einer Runde ohne Handicap-Abzug. Netto-Score = Brutto minus Spielvorgabe.",
            category: .handicap
        ),
        QuizQuestion(
            question: "Welche Ausrüstung ist für die Platzreife-Prüfung (Praxis) mindestens erforderlich?",
            options: [
                "Mindestens 14 Schläger und Golfkart",
                "Mindestens ein Schläger, Golfbälle und geeignete Golfbekleidung",
                "Professionelle Schlägertasche mit Caddie",
                "Elektronisches Handicap-Gerät"
            ],
            correctIndex: 1,
            explanation: "Für die praktische Platzreife-Prüfung braucht man mindestens einige Schläger, Golfbälle und angemessene Kleidung. Viele Schulen verleihen Ausrüstung für die Prüfung.",
            category: .handicap
        ),
    ]
}
