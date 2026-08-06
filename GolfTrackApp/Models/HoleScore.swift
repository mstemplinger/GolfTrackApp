import SwiftData
import Foundation

@Model
final class HoleScore {
    var holeNumber: Int
    var strokes: Int
    var putts: Int
    var fairwayHit: Bool
    var greenInRegulation: Bool
    var pinLatitude: Double?
    var pinLongitude: Double?
    /// true, wenn der Pin aus den abgeleiteten Platzpositionen vorbefüllt wurde
    /// und nicht vom Nutzer gesetzt ist. Wichtig, damit die Ableitung
    /// (`CourseGeometryInference`) sich nicht selbst bestätigt.
    var pinIsAutomatic: Bool = false
    /// Name des verwendeten Schlägers für dieses Loch (optional, vom Nutzer wählbar)
    var clubName: String? = nil
    var round: Round?

    @Relationship(deleteRule: .cascade, inverse: \Shot.holeScore)
    var shots: [Shot] = []

    init(
        holeNumber: Int,
        strokes: Int = 0,
        putts: Int = 0,
        fairwayHit: Bool = false,
        greenInRegulation: Bool = false
    ) {
        self.holeNumber = holeNumber
        self.strokes = strokes
        self.putts = putts
        self.fairwayHit = fairwayHit
        self.greenInRegulation = greenInRegulation
    }

    var hasPinLocation: Bool { pinLatitude != nil && pinLongitude != nil }

    var sortedShots: [Shot] {
        shots.sorted { $0.shotNumber < $1.shotNumber }
    }

    var totalDistanceMeters: Double {
        shots.reduce(0) { $0 + $1.distanceMeters }
    }

    var totalDistanceYards: Int {
        Int(totalDistanceMeters * 1.09361)
    }
}
