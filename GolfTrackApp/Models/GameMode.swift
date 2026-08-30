import Foundation
import SwiftUI

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

// Die Namen, Untertitel und Beschreibungen sind uebersetzbar: als nackte
// Literale blieben sie in jeder Sprache deutsch.
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
        case .strokePlay: return String(localized: "Zählspiel")
        case .stableford: return String(localized: "Stableford")
        case .erado: return String(localized: "Erado®")
        case .skins: return String(localized: "Skins")
        case .duplicateStableford: return String(localized: "Duplicate®")
        case .matchplay: return String(localized: "Matchplay")
        case .betterBallStroke: return String(localized: "Better Ball")
        case .betterBallStableford: return String(localized: "Better Ball")
        case .scramble2Mann: return String(localized: "2-Mann Scramble")
        case .betterBallMatchplay: return String(localized: "Better Ball")
        case .vierer: return String(localized: "Vierer")
        case .greensome: return String(localized: "Greensome")
        case .scrambleMatchplay: return String(localized: "Scramble")
        case .bestBallStroke: return String(localized: "Best Ball")
        case .bestBallStableford: return String(localized: "Best Ball")
        case .scrambleTeam: return String(localized: "Scramble")
        case .matchNet: return String(localized: "Match/Net")
        case .duplicateScramble: return String(localized: "Duplicate® Scramble")
        case .irishRumble: return String(localized: "Irish Rumble")
        }
    }

    var subtitle: String {
        switch self {
        case .strokePlay: return ""
        case .stableford: return ""
        case .erado: return String(localized: "Zählspiel")
        case .skins: return String(localized: "Zählspiel")
        case .duplicateStableford: return String(localized: "Stableford")
        case .matchplay: return ""
        case .betterBallStroke: return String(localized: "Zählspiel")
        case .betterBallStableford: return String(localized: "Stableford")
        case .scramble2Mann: return String(localized: "Zählspiel")
        case .betterBallMatchplay: return String(localized: "Matchplay")
        case .vierer: return String(localized: "Matchplay")
        case .greensome: return String(localized: "Matchplay")
        case .scrambleMatchplay: return String(localized: "Matchplay")
        case .bestBallStroke: return String(localized: "Zählspiel")
        case .bestBallStableford: return String(localized: "Stableford")
        case .scrambleTeam: return String(localized: "Zählspiel")
        case .matchNet: return String(localized: "Zählspiel")
        case .duplicateScramble: return String(localized: "Stableford")
        case .irishRumble: return String(localized: "Best Ball")
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
            return String(localized: "Die klassische Spielform: Jeder Schlag zählt. Wer am Ende der Runde die wenigsten Schläge hat, gewinnt.")
        case .stableford:
            return String(localized: "Punkte statt Schläge: Albatross=5, Eagle=4, Birdie=3, Par=2, Bogey=1, Double+=0. Wer die meisten Punkte sammelt, gewinnt.")
        case .erado:
            return String(localized: "Wie Zählspiel, aber die schlechteste(n) Löcher werden gestrichen. Bei 18 Löchern werden 2 Streichlöcher angerechnet, bei 9 Löchern 1.")
        case .skins:
            return String(localized: "Jedes Loch hat einen Wert (Skin). Wer das Loch gewinnt, erhält den Skin. Bei Gleichstand wird der Skin übertragen.")
        case .duplicateStableford:
            return String(localized: "Stableford-Punkte werden multipliziert – bestimmte Löcher zählen doppelt oder dreifach.")
        case .matchplay:
            return String(localized: "Loch für Loch. Wer das Loch mit weniger Schlägen spielt, gewinnt es. Wer am Ende mehr Löcher hat, gewinnt die Runde.")
        case .betterBallStroke:
            return String(localized: "Zwei Spieler spielen gemeinsam – der bessere Score pro Loch zählt für das Team.")
        case .betterBallStableford:
            return String(localized: "Wie Better Ball, aber gewertet nach Stableford-Punkten. Die höheren Punkte pro Loch zählen für das Team.")
        case .scramble2Mann:
            return String(localized: "Beide Spieler schlagen ab. Der beste Abschlag wird gewählt und beide spielen von dort weiter.")
        case .betterBallMatchplay:
            return String(localized: "2 gegen 2: Pro Team zählt der bessere Score. Die Teams spielen Loch für Loch gegeneinander (Matchplay).")
        case .vierer:
            return String(localized: "Zwei Spieler spielen abwechselnd mit einem Ball (Wechselschlag). Ein Team, ein Ball, ein Score.")
        case .greensome:
            return String(localized: "Beide Partner schlagen ab. Der beste Abschlag wird gewählt. Danach spielen beide abwechselnd bis zum Einlochen.")
        case .scrambleMatchplay:
            return String(localized: "Scramble-Format (bester Ball, alle spielen weiter) im Matchplay-Modus gegen ein anderes Team.")
        case .bestBallStroke:
            return String(localized: "3 oder 4 Spieler im Team – der beste Score pro Loch zählt für das Team (Zählspiel).")
        case .bestBallStableford:
            return String(localized: "Best Ball mit Stableford-Wertung – der höchste Punktwert pro Loch zählt für das Team.")
        case .scrambleTeam:
            return String(localized: "3–4 Spieler: Alle schlagen ab, bester Abschlag wird gewählt. Alle spielen von dort weiter bis zum Einlochen.")
        case .matchNet:
            return String(localized: "Zählspiel gegen eine Netto-Zielvorgabe. Das Team spielt gegen einen vorgegebenen Netto-Score.")
        case .duplicateScramble:
            return String(localized: "Scramble mit Stableford-Wertung und Multiplikator auf bestimmten Löchern.")
        case .irishRumble:
            return String(localized: "Die ersten Löcher werden als Best Ball gespielt, dann wechselt das Format nach einem festen Schlüssel.")
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
