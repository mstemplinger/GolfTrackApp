import Foundation
import SwiftUI

/// Worauf sich die App konzentriert. Wird beim allerersten Start abgefragt
/// (vor dem Tutorial) und ist später im Profil änderbar.
///
/// - `.golf`: klassischer Ablauf mit Handicap, Runden und Tutorial.
/// - `.minigolf`: Startseite und Tab-Leiste stellen Minigolf in den Vordergrund,
///   das Tutorial wird übersprungen (es erklärt ausschließlich Golf-Features).
enum AppFocus: String, CaseIterable, Identifiable {
    case golf
    case minigolf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .golf:     return String(localized: "Golf")
        case .minigolf: return String(localized: "Minigolf")
        }
    }

    var subtitle: String {
        switch self {
        case .golf:
            return String(localized: "Runden auf dem Platz, Handicap & Schlagverfolgung")
        case .minigolf:
            return String(localized: "Schnelle Spiele mit Freunden, Schlag für Schlag gezählt")
        }
    }

    var icon: String {
        switch self {
        case .golf:     return "figure.golf"
        case .minigolf: return "flag.2.crossed.fill"
        }
    }

    /// Stichpunkte für den Auswahl-Screen beim ersten Start.
    var highlights: [String] {
        switch self {
        case .golf:
            return [
                String(localized: "WHS-Handicap wird automatisch berechnet"),
                String(localized: "Schläge, Distanzen und Laufwege auf der Karte"),
                String(localized: "Spielformen, Regeln und Platzreife-Training")
            ]
        case .minigolf:
            return [
                String(localized: "In Sekunden startklar – kein Tutorial nötig"),
                String(localized: "Bis zu 8 Spieler auf einer Scorekarte"),
                String(localized: "Golf-Funktionen bleiben jederzeit verfügbar")
            ]
        }
    }

    /// UserDefaults-Schlüssel, damit sich Views nicht vertippen.
    static let storageKey = "appFocus"
    /// Wurde die Auswahl schon getroffen? Steuert den Erststart-Screen.
    static let chosenKey = "hasChosenAppFocus"
}
