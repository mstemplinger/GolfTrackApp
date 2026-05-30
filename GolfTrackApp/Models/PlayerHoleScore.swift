import SwiftData

@Model
final class PlayerHoleScore {
    var playerIndex: Int
    var playerName: String
    var holeNumber: Int
    var strokes: Int
    var round: Round?

    init(playerIndex: Int, playerName: String, holeNumber: Int, strokes: Int) {
        self.playerIndex = playerIndex
        self.playerName = playerName
        self.holeNumber = holeNumber
        self.strokes = strokes
    }
}
