import SwiftData
import Foundation

@Model
final class GolfClub {
    var name: String
    /// Voreingestellte Weite – wird nur verwendet solange keine eigenen Messungen vorliegen
    var defaultDistance: Int
    /// Alle gemessenen Schläge in Metern (automatisch aus ShotTracker befüllt)
    var measuredDistances: [Double]
    var order: Int

    init(name: String, averageDistance: Int, order: Int = 0) {
        self.name = name
        self.defaultDistance = averageDistance
        self.measuredDistances = []
        self.order = order
    }

    // MARK: - Computed

    /// True sobald mindestens ein eigener Schlag gemessen wurde
    var hasUserData: Bool { !measuredDistances.isEmpty }

    /// Anzahl der eigenen Messungen
    var shotCount: Int { measuredDistances.count }

    /// Kürzester gemessener Schlag
    var minDistance: Int { measuredDistances.isEmpty ? 0 : Int(measuredDistances.min()!.rounded()) }

    /// Weitester gemessener Schlag
    var maxDistance: Int { measuredDistances.isEmpty ? 0 : Int(measuredDistances.max()!.rounded()) }

    /// Durchschnittliche Weite:
    /// – mit eigenen Daten → Mittelwert der Messungen
    /// – ohne eigene Daten → Voreinstellung
    var averageDistance: Int {
        guard hasUserData else { return defaultDistance }
        let avg = measuredDistances.reduce(0, +) / Double(measuredDistances.count)
        return Int(avg.rounded())
    }

    // MARK: - Mutations

    /// Fügt eine neue Messung hinzu (nur sinnvolle Werte 5–450 m)
    func addMeasurement(_ meters: Double) {
        guard meters >= 5, meters <= 450 else { return }
        measuredDistances.append(meters)
    }

    /// Setzt alle Messungen zurück → fällt auf Voreinstellung zurück
    func clearMeasurements() {
        measuredDistances.removeAll()
    }
}
