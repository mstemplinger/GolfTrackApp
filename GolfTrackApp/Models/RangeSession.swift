import SwiftData
import Foundation

/// Eine Einheit auf der Driving Range – alle Schläge zwischen „Start“ und „Beenden“.
@Model
final class RangeSession {
    var date: Date
    var endedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \RangeShot.session)
    var shots: [RangeShot] = []

    init(date: Date = .now) {
        self.date = date
    }

    var sortedShots: [RangeShot] {
        shots.sorted { $0.date < $1.date }
    }

    /// Schläger in der Reihenfolge, in der sie zum ersten Mal geschlagen wurden.
    var clubNames: [String] {
        var seen = Set<String>()
        return sortedShots.compactMap { seen.insert($0.clubName).inserted ? $0.clubName : nil }
    }
}

/// Ein Schlag auf der Range. Der Schläger hängt bewusst nur am Namen:
/// Bags dürfen gelöscht oder neu angelegt werden, ohne die Historie zu verlieren.
@Model
final class RangeShot {
    var clubName: String
    /// Immer in Metern gespeichert, angezeigt in der gewählten Einheit.
    var distanceMeters: Double
    var date: Date
    var session: RangeSession?

    init(clubName: String, distanceMeters: Double, date: Date = .now) {
        self.clubName = clubName
        self.distanceMeters = distanceMeters
        self.date = date
    }
}

// MARK: - Auswertung

/// Kennzahlen eines Schlägers über eine Menge von Range-Schlägen.
struct RangeClubStats: Identifiable {
    let clubName: String
    let count: Int
    let average: Double
    let best: Double

    var id: String { clubName }

    init?(clubName: String, distances: [Double]) {
        guard !distances.isEmpty else { return nil }
        self.clubName = clubName
        self.count = distances.count
        self.average = distances.reduce(0, +) / Double(distances.count)
        self.best = distances.max() ?? 0
    }

    static func byClub(_ shots: [RangeShot]) -> [String: RangeClubStats] {
        Dictionary(grouping: shots, by: \.clubName).compactMapValues {
            RangeClubStats(clubName: $0.first?.clubName ?? "", distances: $0.map(\.distanceMeters))
        }
    }
}

enum RangeClubDefaults {
    /// Auswahl ohne angelegtes Bag – dieselben Namen wie die Standardschläger im Profil.
    static let names = [
        "Driver", "3 Wood", "5 Wood", "Hybrid", "4 Eisen", "5 Eisen", "6 Eisen",
        "7 Eisen", "8 Eisen", "9 Eisen", "PW", "GW", "SW", "LW"
    ]

    /// Driver erkennen, egal wie der Spieler ihn im Bag benannt hat.
    static func isDriver(_ name: String) -> Bool {
        let n = name.lowercased()
        return n.contains("driver") || n == "1w" || n == "1 wood" || n == "holz 1"
    }
}
