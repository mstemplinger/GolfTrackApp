import SwiftData
import Foundation

@Model
final class Round {
    var date: Date
    var course: Course?
    var isComplete: Bool
    var notes: String
    var gameModeRaw: String = GameMode.strokePlay.rawValue
    var isWatchInitiated: Bool = false
    var bag: GolfBag?

    var playerNamesRaw: String = ""

    @Relationship(deleteRule: .cascade, inverse: \HoleScore.round)
    var holeScores: [HoleScore] = []

    @Relationship(deleteRule: .cascade, inverse: \PlayerHoleScore.round)
    var playerHoleScores: [PlayerHoleScore] = []

    init(date: Date = .now, course: Course? = nil, notes: String = "", gameMode: GameMode = .strokePlay) {
        self.date = date
        self.course = course
        self.isComplete = false
        self.notes = notes
        self.gameModeRaw = gameMode.rawValue
    }

    var gameMode: GameMode {
        get { GameMode(rawValue: gameModeRaw) ?? .strokePlay }
        set { gameModeRaw = newValue.rawValue }
    }

    var otherPlayerNames: [String] {
        get { playerNamesRaw.isEmpty ? [] : playerNamesRaw.components(separatedBy: "|") }
        set { playerNamesRaw = newValue.joined(separator: "|") }
    }

    func opponentScore(playerIndex: Int, holeNumber: Int) -> PlayerHoleScore? {
        playerHoleScores.first { $0.playerIndex == playerIndex && $0.holeNumber == holeNumber }
    }

    var sortedScores: [HoleScore] {
        holeScores.sorted { $0.holeNumber < $1.holeNumber }
    }

    var playedScores: [HoleScore] {
        sortedScores.filter { $0.strokes > 0 }
    }

    var totalStrokes: Int {
        playedScores.reduce(0) { $0 + $1.strokes }
    }

    var totalPutts: Int {
        playedScores.reduce(0) { $0 + $1.putts }
    }

    var scoreToPar: Int? {
        guard let course, !playedScores.isEmpty else { return nil }
        let parSum = playedScores.compactMap { score -> Int? in
            let idx = score.holeNumber - 1
            guard idx >= 0, idx < course.parValues.count else { return nil }
            return course.parValues[idx]
        }.reduce(0, +)
        return totalStrokes - parSum
    }

    var scoreLabel: String {
        guard let diff = scoreToPar else { return "-" }
        if diff == 0 { return "E" }
        return diff > 0 ? "+\(diff)" : "\(diff)"
    }

    var totalStablefordPoints: Int {
        guard let course else { return 0 }
        return playedScores.reduce(0) { sum, score in
            let idx = score.holeNumber - 1
            guard idx >= 0, idx < course.parValues.count else { return sum }
            return sum + GameMode.stablefordPoints(strokes: score.strokes, par: course.parValues[idx])
        }
    }

    var fairwaysHit: Int { holeScores.filter(\.fairwayHit).count }
    var greensInRegulation: Int { holeScores.filter(\.greenInRegulation).count }

    var fairwayOpportunities: Int {
        guard let course else { return 0 }
        return playedScores.filter { score in
            let idx = score.holeNumber - 1
            guard idx >= 0, idx < course.parValues.count else { return false }
            return course.parValues[idx] > 3
        }.count
    }

    var girOpportunities: Int { playedScores.count }
}
