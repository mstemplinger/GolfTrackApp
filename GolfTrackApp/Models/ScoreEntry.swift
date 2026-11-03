import Foundation

/// Gemeinsame Scorekarte eines Lochs – für den eigenen Spieler (`HoleScore`)
/// und für Mitspieler (`PlayerHoleScore`). Damit bedient dieselbe Eingabe
/// Schläge, Putts, Fairway, GIR und die GPS-Schlagkette beider.
protocol ScoreEntry: AnyObject, Observable {
    var holeNumber: Int { get }
    var strokes: Int { get set }
    var putts: Int { get set }
    var fairwayHit: Bool { get set }
    var greenInRegulation: Bool { get set }
    var shots: [Shot] { get set }
}

extension ScoreEntry {
    var sortedShots: [Shot] {
        shots.sorted { $0.shotNumber < $1.shotNumber }
    }

    var totalDistanceMeters: Double {
        shots.reduce(0) { $0 + $1.distanceMeters }
    }
}
