import Foundation

/// Zusatzwertungen für eine Minigolf-Runde ("Wettkämpfe").
///
/// Sie laufen parallel zur normalen Schlagwertung: die Runde gewinnt weiterhin,
/// wer die wenigsten Schläge braucht – zusätzlich gibt es pro aktiviertem
/// Wettkampf einen eigenen Sieger. Wettkämpfe lassen sich vor dem Start und
/// jederzeit während der Runde an- und abschalten; gewertet wird immer die
/// komplette Scorecard, egal wann eingeschaltet wurde.
enum MinigolfChallenge: String, CaseIterable, Codable, Identifiable, Hashable {
    /// Längste Serie an Bahnen hintereinander mit höchstens zwei Schlägen.
    case streak
    /// Meiste Asse (Bahn mit einem Schlag).
    case aces
    /// Meiste alleine gewonnene Bahnen.
    case holeWins
    /// Wenigste Patzer (Bahnen mit vier Schlägen oder mehr).
    case steady
    /// Größte Steigerung zweite Hälfte gegenüber erster Hälfte.
    case comeback
    /// Beste letzte drei Bahnen.
    case finish

    var id: String { rawValue }

    /// Ab wie vielen Schlägen eine Bahn nicht mehr zur Serie zählt.
    static let streakLimit = 2
    /// Ab wie vielen Schlägen eine Bahn als Patzer gilt.
    static let blowUpLimit = 4
    /// Wie viele Bahnen der Schlussspurt umfasst.
    static let finishHoles = 3

    var displayName: String {
        switch self {
        case .streak:   return String(localized: "Serie")
        case .aces:     return String(localized: "Ass-Jäger")
        case .holeWins: return String(localized: "Bahnenduell")
        case .steady:   return String(localized: "Nervenstark")
        case .comeback: return String(localized: "Aufholjagd")
        case .finish:   return String(localized: "Schlussspurt")
        }
    }

    /// Die Regel in einem Satz – steht in der Auswahl unter dem Namen.
    var rule: String {
        switch self {
        case .streak:
            return String(localized: "Wer schafft die längste Serie an Bahnen hintereinander mit höchstens 2 Schlägen?")
        case .aces:
            return String(localized: "Wer locht am häufigsten mit dem ersten Schlag ein?")
        case .holeWins:
            return String(localized: "Wer gewinnt die meisten Bahnen allein? Bei Gleichstand auf einer Bahn bekommt sie niemand.")
        case .steady:
            return String(localized: "Wer leistet sich die wenigsten Patzer mit 4 Schlägen oder mehr?")
        case .comeback:
            return String(localized: "Wer spielt die zweite Hälfte am deutlichsten besser als die erste?")
        case .finish:
            return String(localized: "Wer braucht auf den letzten 3 Bahnen die wenigsten Schläge?")
        }
    }

    /// Einheit hinter dem Zahlenwert in der Tabelle.
    var unit: String {
        switch self {
        case .streak:   return String(localized: "in Folge")
        case .aces:     return String(localized: "Asse")
        case .holeWins: return String(localized: "Bahnen")
        case .steady:   return String(localized: "Patzer")
        case .comeback: return String(localized: "Schläge besser")
        case .finish:   return String(localized: "Schläge")
        }
    }

    var sfSymbol: String {
        switch self {
        case .streak:   return "flame.fill"
        case .aces:     return "target"
        case .holeWins: return "flag.checkered"
        case .steady:   return "shield.lefthalf.filled"
        case .comeback: return "chart.line.uptrend.xyaxis"
        case .finish:   return "hare.fill"
        }
    }

    var trophy: String {
        switch self {
        case .streak:   return "🔥"
        case .aces:     return "🎯"
        case .holeWins: return "🏁"
        case .steady:   return "🛡️"
        case .comeback: return "📈"
        case .finish:   return "🚀"
        }
    }
}

// MARK: - Auswertung

/// Ein Spieler in der Wertung eines Wettkampfs.
struct MinigolfChallengeStanding: Identifiable, Hashable {
    let playerIndex: Int
    let name: String
    /// Sortierwert – größer ist immer besser, auch wenn weniger besser ist
    /// (dann negativ). Nur für Reihenfolge und Sieger-Vergleich.
    let rank: Int
    /// Der Wert, den der Spieler erreicht hat (schon in Anzeigerichtung).
    let value: Int
    /// Zählt der Spieler überhaupt für die Wertung?
    let qualifies: Bool

    var id: Int { playerIndex }
}

/// Ergebnis eines Wettkampfs über die gesamte bisherige Scorecard.
struct MinigolfChallengeResult: Identifiable {
    let challenge: MinigolfChallenge
    /// Alle Spieler, bester zuerst.
    let standings: [MinigolfChallengeStanding]

    var id: String { challenge.rawValue }

    /// Aktuell führende Spieler (mehrere bei Gleichstand), leer solange
    /// niemand die Bedingung erfüllt.
    var leaders: [MinigolfChallengeStanding] {
        guard let best = standings.first(where: { $0.qualifies }) else { return [] }
        return standings.filter { $0.qualifies && $0.rank == best.rank }
    }

    var leaderNames: String {
        leaders.map(\.name).joined(separator: ", ")
    }

    /// Wert der Führenden inkl. Einheit, z. B. „4 in Folge".
    var leaderValueText: String? {
        guard let best = leaders.first else { return nil }
        return valueText(for: best)
    }

    /// Wert eines Spielers inkl. Einheit – „–", solange er nicht zählt.
    func valueText(for standing: MinigolfChallengeStanding) -> String {
        standing.qualifies ? "\(standing.value) \(challenge.unit)" : "–"
    }
}

enum MinigolfChallengeEngine {

    /// Rohwert einer Einzelwertung pro Spieler.
    private typealias Raw = (rank: Int, value: Int, qualifies: Bool)

    /// Wertet einen Wettkampf über die Scorecard aus.
    /// - Parameter scores: `scores[spieler][bahn]`, 0 = noch nicht gespielt.
    static func evaluate(_ challenge: MinigolfChallenge,
                         scores: [[Int]],
                         names: [String]) -> MinigolfChallengeResult {
        let raw: [Raw]
        switch challenge {
        case .streak:   raw = streak(scores)
        case .aces:     raw = aces(scores)
        case .holeWins: raw = holeWins(scores)
        case .steady:   raw = steady(scores)
        case .comeback: raw = comeback(scores)
        case .finish:   raw = finish(scores)
        }

        let standings = raw.enumerated().map { i, r in
            MinigolfChallengeStanding(
                playerIndex: i,
                name: i < names.count ? names[i] : "\(i + 1)",
                rank: r.rank,
                value: r.value,
                qualifies: r.qualifies
            )
        }
        .sorted { lhs, rhs in
            if lhs.qualifies != rhs.qualifies { return lhs.qualifies }
            if lhs.rank != rhs.rank { return lhs.rank > rhs.rank }
            return lhs.playerIndex < rhs.playerIndex
        }

        return MinigolfChallengeResult(challenge: challenge, standings: standings)
    }

    static func results(for challenges: [MinigolfChallenge],
                        scores: [[Int]],
                        names: [String]) -> [MinigolfChallengeResult] {
        challenges.map { evaluate($0, scores: scores, names: names) }
    }

    // MARK: Einzelwertungen

    private static func streak(_ scores: [[Int]]) -> [Raw] {
        scores.map { row in
            var best = 0
            var current = 0
            for s in row {
                if s > 0 && s <= MinigolfChallenge.streakLimit {
                    current += 1
                    best = max(best, current)
                } else {
                    current = 0
                }
            }
            return (best, best, best >= 2)
        }
    }

    private static func aces(_ scores: [[Int]]) -> [Raw] {
        scores.map { row in
            let count = row.filter { $0 == 1 }.count
            return (count, count, count > 0)
        }
    }

    private static func holeWins(_ scores: [[Int]]) -> [Raw] {
        let playerCount = scores.count
        let holeCount = scores.first?.count ?? 0
        var wins = Array(repeating: 0, count: playerCount)

        for hole in 0..<holeCount {
            let strokes = scores.map { $0[hole] }
            // Nur vollständig gespielte Bahnen werden gewertet.
            guard strokes.allSatisfy({ $0 > 0 }), let best = strokes.min() else { continue }
            let winners = strokes.indices.filter { strokes[$0] == best }
            // Geteilte Bahnen zählen für niemanden.
            if winners.count == 1 { wins[winners[0]] += 1 }
        }

        return wins.map { ($0, $0, $0 > 0) }
    }

    private static func steady(_ scores: [[Int]]) -> [Raw] {
        scores.map { row in
            let played = row.filter { $0 > 0 }
            let blowUps = played.filter { $0 >= MinigolfChallenge.blowUpLimit }.count
            // Weniger ist besser → negativer Sortierwert.
            return (-blowUps, blowUps, !played.isEmpty)
        }
    }

    private static func comeback(_ scores: [[Int]]) -> [Raw] {
        let holeCount = scores.first?.count ?? 0
        let half = holeCount / 2
        guard half > 0 else { return scores.map { _ in (0, 0, false) } }

        return scores.map { row in
            let first = Array(row.prefix(half))
            let second = Array(row.suffix(half))
            // Nur vergleichbar, wenn beide Hälften komplett gespielt sind.
            guard first.allSatisfy({ $0 > 0 }), second.allSatisfy({ $0 > 0 }) else {
                return (Int.min, 0, false)
            }
            let gain = first.reduce(0, +) - second.reduce(0, +)
            return (gain, gain, gain > 0)
        }
    }

    private static func finish(_ scores: [[Int]]) -> [Raw] {
        let holeCount = scores.first?.count ?? 0
        let count = min(MinigolfChallenge.finishHoles, holeCount)
        guard count > 0 else { return scores.map { _ in (0, 0, false) } }

        return scores.map { row in
            let last = Array(row.suffix(count))
            guard last.allSatisfy({ $0 > 0 }) else { return (Int.min, 0, false) }
            let total = last.reduce(0, +)
            // Weniger ist besser.
            return (-total, total, true)
        }
    }
}
