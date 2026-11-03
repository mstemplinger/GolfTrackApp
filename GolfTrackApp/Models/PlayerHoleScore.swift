import SwiftData

@Model
final class PlayerHoleScore {
    var playerIndex: Int
    var playerName: String
    var holeNumber: Int
    var strokes: Int
    // Mitspieler führen dieselbe Scorekarte wie der eigene Spieler.
    // Standardwerte, damit bestehende Runden ohne Migration weiterlaufen.
    var putts: Int = 0
    var fairwayHit: Bool = false
    var greenInRegulation: Bool = false
    var round: Round?

    /// Schlagpositionen des Mitspielers. Bewusst getrennt von `HoleScore.shots`,
    /// damit sie weder die eigene Schlägerstatistik noch die Platzableitung
    /// (`CourseGeometryInference`, `FairwayCorridorInference`) verfälschen.
    @Relationship(deleteRule: .cascade, inverse: \Shot.playerHoleScore)
    var shots: [Shot] = []

    init(playerIndex: Int, playerName: String, holeNumber: Int, strokes: Int) {
        self.playerIndex = playerIndex
        self.playerName = playerName
        self.holeNumber = holeNumber
        self.strokes = strokes
    }
}

extension PlayerHoleScore: ScoreEntry {}
