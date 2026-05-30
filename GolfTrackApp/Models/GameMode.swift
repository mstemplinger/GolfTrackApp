import Foundation

enum GameModeCategory: String {
    case individual = "Individuelle Spielformen"
    case partner = "Partner Spielformen"
    case team = "Team Spielformen"

    var icon: String {
        switch self {
        case .individual: return "person.fill"
        case .partner: return "person.2.fill"
        case .team: return "person.3.fill"
        }
    }
}

enum GameMode: String, CaseIterable, Codable {
    // Individual
    case strokePlay
    case stableford
    case erado
    case skins
    case duplicateStableford
    case matchplay
    // Partner
    case betterBallStroke
    case betterBallStableford
    case scramble2Mann
    case betterBallMatchplay
    case vierer
    case greensome
    case scrambleMatchplay
    // Team
    case bestBallStroke
    case bestBallStableford
    case scrambleTeam
    case matchNet
    case duplicateScramble
    case irishRumble

    var displayName: String {
        switch self {
        case .strokePlay: return "Zählspiel"
        case .stableford: return "Stableford"
        case .erado: return "Erado®"
        case .skins: return "Skins"
        case .duplicateStableford: return "Duplicate®"
        case .matchplay: return "Matchplay"
        case .betterBallStroke: return "Better Ball"
        case .betterBallStableford: return "Better Ball"
        case .scramble2Mann: return "2-Mann Scramble"
        case .betterBallMatchplay: return "Better Ball"
        case .vierer: return "Vierer"
        case .greensome: return "Greensome"
        case .scrambleMatchplay: return "Scramble"
        case .bestBallStroke: return "Best Ball"
        case .bestBallStableford: return "Best Ball"
        case .scrambleTeam: return "Scramble"
        case .matchNet: return "Match/Net"
        case .duplicateScramble: return "Duplicate® Scramble"
        case .irishRumble: return "Irish Rumble"
        }
    }

    var subtitle: String {
        switch self {
        case .strokePlay: return ""
        case .stableford: return ""
        case .erado: return "Zählspiel"
        case .skins: return "Zählspiel"
        case .duplicateStableford: return "Stableford"
        case .matchplay: return ""
        case .betterBallStroke: return "Zählspiel"
        case .betterBallStableford: return "Stableford"
        case .scramble2Mann: return "Zählspiel"
        case .betterBallMatchplay: return "Matchplay"
        case .vierer: return "Matchplay"
        case .greensome: return "Matchplay"
        case .scrambleMatchplay: return "Matchplay"
        case .bestBallStroke: return "Zählspiel"
        case .bestBallStableford: return "Stableford"
        case .scrambleTeam: return "Zählspiel"
        case .matchNet: return "Zählspiel"
        case .duplicateScramble: return "Stableford"
        case .irishRumble: return "Best Ball"
        }
    }

    var category: GameModeCategory {
        switch self {
        case .strokePlay, .stableford, .erado, .skins, .duplicateStableford, .matchplay:
            return .individual
        case .betterBallStroke, .betterBallStableford, .scramble2Mann,
             .betterBallMatchplay, .vierer, .greensome, .scrambleMatchplay:
            return .partner
        case .bestBallStroke, .bestBallStableford, .scrambleTeam,
             .matchNet, .duplicateScramble, .irishRumble:
            return .team
        }
    }

    var sfSymbol: String {
        switch self {
        case .strokePlay: return "figure.golf"
        case .stableford: return "star.circle.fill"
        case .erado: return "ticket.fill"
        case .skins: return "seal.fill"
        case .duplicateStableford: return "repeat.circle.fill"
        case .matchplay: return "person.2.fill"
        case .betterBallStroke, .betterBallStableford, .betterBallMatchplay: return "flame.fill"
        case .scramble2Mann: return "person.2.wave.2.fill"
        case .vierer: return "arrow.triangle.2.circlepath.circle.fill"
        case .greensome: return "person.2.circle.fill"
        case .scrambleMatchplay: return "person.3.sequence.fill"
        case .bestBallStroke, .bestBallStableford: return "flame.circle.fill"
        case .scrambleTeam: return "person.3.fill"
        case .matchNet: return "chart.bar.doc.horizontal.fill"
        case .duplicateScramble: return "repeat.1.circle.fill"
        case .irishRumble: return "leaf.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .strokePlay:
            return "Die klassische Spielform: Jeder Schlag zählt. Wer am Ende der Runde die wenigsten Schläge hat, gewinnt."
        case .stableford:
            return "Punkte statt Schläge: Albatross=5, Eagle=4, Birdie=3, Par=2, Bogey=1, Double+=0. Wer die meisten Punkte sammelt, gewinnt."
        case .erado:
            return "Wie Zählspiel, aber die schlechteste(n) Löcher werden gestrichen. Bei 18 Löchern werden 2 Streichlöcher angerechnet, bei 9 Löchern 1."
        case .skins:
            return "Jedes Loch hat einen Wert (Skin). Wer das Loch gewinnt, erhält den Skin. Bei Gleichstand wird der Skin übertragen."
        case .duplicateStableford:
            return "Stableford-Punkte werden multipliziert – bestimmte Löcher zählen doppelt oder dreifach."
        case .matchplay:
            return "Loch für Loch. Wer das Loch mit weniger Schlägen spielt, gewinnt es. Wer am Ende mehr Löcher hat, gewinnt die Runde."
        case .betterBallStroke:
            return "Zwei Spieler spielen gemeinsam – der bessere Score pro Loch zählt für das Team."
        case .betterBallStableford:
            return "Wie Better Ball, aber gewertet nach Stableford-Punkten. Die höheren Punkte pro Loch zählen für das Team."
        case .scramble2Mann:
            return "Beide Spieler schlagen ab. Der beste Abschlag wird gewählt und beide spielen von dort weiter."
        case .betterBallMatchplay:
            return "2 gegen 2: Pro Team zählt der bessere Score. Die Teams spielen Loch für Loch gegeneinander (Matchplay)."
        case .vierer:
            return "Zwei Spieler spielen abwechselnd mit einem Ball (Wechselschlag). Ein Team, ein Ball, ein Score."
        case .greensome:
            return "Beide Partner schlagen ab. Der beste Abschlag wird gewählt. Danach spielen beide abwechselnd bis zum Einlochen."
        case .scrambleMatchplay:
            return "Scramble-Format (bester Ball, alle spielen weiter) im Matchplay-Modus gegen ein anderes Team."
        case .bestBallStroke:
            return "3 oder 4 Spieler im Team – der beste Score pro Loch zählt für das Team (Zählspiel)."
        case .bestBallStableford:
            return "Best Ball mit Stableford-Wertung – der höchste Punktwert pro Loch zählt für das Team."
        case .scrambleTeam:
            return "3–4 Spieler: Alle schlagen ab, bester Abschlag wird gewählt. Alle spielen von dort weiter bis zum Einlochen."
        case .matchNet:
            return "Zählspiel gegen eine Netto-Zielvorgabe. Das Team spielt gegen einen vorgegebenen Netto-Score."
        case .duplicateScramble:
            return "Scramble mit Stableford-Wertung und Multiplikator auf bestimmten Löchern."
        case .irishRumble:
            return "Die ersten Löcher werden als Best Ball gespielt, dann wechselt das Format nach einem festen Schlüssel."
        }
    }

    var isAvailable: Bool {
        switch self {
        case .strokePlay, .stableford, .matchplay, .skins,
             .betterBallStroke, .betterBallStableford, .scramble2Mann,
             .erado, .vierer, .greensome,
             .betterBallMatchplay, .bestBallStroke, .bestBallStableford, .scrambleTeam:
            return true
        default:
            return false
        }
    }

    var minOtherPlayers: Int {
        switch self {
        case .matchplay, .betterBallStroke, .betterBallStableford,
             .scramble2Mann, .vierer, .greensome: return 1
        case .skins, .bestBallStroke, .bestBallStableford: return 1
        case .betterBallMatchplay: return 2
        case .scrambleTeam: return 2
        default: return 0
        }
    }

    var maxOtherPlayers: Int {
        switch self {
        case .skins, .bestBallStroke, .bestBallStableford: return 3
        case .matchplay, .betterBallStroke, .betterBallStableford,
             .scramble2Mann, .vierer, .greensome: return 1
        case .betterBallMatchplay: return 3
        case .scrambleTeam: return 3
        default: return 0
        }
    }

    var isMultiplayer: Bool { minOtherPlayers > 0 }

    // MARK: - Stableford

    static func stablefordPoints(strokes: Int, par: Int) -> Int {
        max(0, 2 - (strokes - par))
    }
}
