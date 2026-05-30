import Foundation

// MARK: - Matchplay

struct MatchplayStatus {
    let holesUp: Int        // positive = main player / main team leads
    let holesPlayed: Int
    let totalHoles: Int
    let isFinished: Bool

    var holesRemaining: Int { totalHoles - holesPlayed }

    var statusLabel: String {
        guard holesPlayed > 0 else { return "Noch nicht gestartet" }
        if isFinished {
            if holesUp > 0 { return "\(holesUp)&\(holesRemaining) gewonnen" }
            if holesUp < 0 { return "\(abs(holesUp))&\(holesRemaining) verloren" }
            return "All Square – Stechen"
        }
        if holesUp == 0 { return "All Square nach \(holesPlayed)" }
        let ud = holesUp > 0 ? "Up" : "Down"
        return "\(abs(holesUp)) \(ud) nach \(holesPlayed)"
    }

    var playerLeads: Bool { holesUp > 0 }
    var opponentLeads: Bool { holesUp < 0 }
}

enum HoleOutcome {
    case player, opponent, halved, notPlayed

    var shortLabel: String {
        switch self {
        case .player: return "W"
        case .opponent: return "L"
        case .halved: return "H"
        case .notPlayed: return "·"
        }
    }
}

// MARK: - Skins

struct SkinsSummary {
    var skinsPerPlayer: [Int: Int] = [:]  // playerIndex -> total skins
    var holeWinners: [Int: Int] = [:]     // holeNumber -> winner index (-1 = tied/carried, absent = not played)
    var openSkins: Int = 0
}

// MARK: - Erado

struct EradoResult {
    let total: Int
    let scratchedHoles: Set<Int>
}

// MARK: - Engine

struct GameScoringEngine {

    // MARK: Matchplay

    static func matchplayHoleOutcome(playerStrokes: Int, opponentStrokes: Int) -> HoleOutcome {
        guard playerStrokes > 0, opponentStrokes > 0 else { return .notPlayed }
        if playerStrokes < opponentStrokes { return .player }
        if playerStrokes > opponentStrokes { return .opponent }
        return .halved
    }

    static func matchplayStatus(round: Round) -> MatchplayStatus {
        let sorted = round.sortedScores
        let totalHoles = sorted.count
        var holesUp = 0
        var holesPlayed = 0

        for holeScore in sorted {
            guard holeScore.strokes > 0,
                  let oppScore = round.playerHoleScores.first(where: {
                      $0.playerIndex == 1 && $0.holeNumber == holeScore.holeNumber
                  }), oppScore.strokes > 0 else { continue }

            holesPlayed += 1
            switch matchplayHoleOutcome(playerStrokes: holeScore.strokes, opponentStrokes: oppScore.strokes) {
            case .player:   holesUp += 1
            case .opponent: holesUp -= 1
            default: break
            }

            let remaining = totalHoles - holesPlayed
            if abs(holesUp) > remaining {
                return MatchplayStatus(holesUp: holesUp, holesPlayed: holesPlayed,
                                       totalHoles: totalHoles, isFinished: true)
            }
        }

        return MatchplayStatus(holesUp: holesUp, holesPlayed: holesPlayed,
                               totalHoles: totalHoles, isFinished: holesPlayed == totalHoles)
    }

    // MARK: Better Ball Matchplay (2v2)
    // playerIndex 1 = my partner, 2 = opponent1, 3 = opponent2 (optional)

    static func betterBallMatchplayStatus(round: Round) -> MatchplayStatus {
        let sorted = round.sortedScores
        let totalHoles = sorted.count
        var holesUp = 0
        var holesPlayed = 0

        for holeScore in sorted {
            let h = holeScore.holeNumber
            guard holeScore.strokes > 0 else { continue }

            let partner = round.opponentScore(playerIndex: 1, holeNumber: h)
            let opp1 = round.opponentScore(playerIndex: 2, holeNumber: h)
            guard let opp1, opp1.strokes > 0 else { continue }

            let myBest: Int
            if let p = partner, p.strokes > 0 {
                myBest = min(holeScore.strokes, p.strokes)
            } else {
                myBest = holeScore.strokes
            }

            let opp2 = round.opponentScore(playerIndex: 3, holeNumber: h)
            let oppBest: Int
            if let o2 = opp2, o2.strokes > 0 {
                oppBest = min(opp1.strokes, o2.strokes)
            } else {
                oppBest = opp1.strokes
            }

            holesPlayed += 1
            switch matchplayHoleOutcome(playerStrokes: myBest, opponentStrokes: oppBest) {
            case .player:   holesUp += 1
            case .opponent: holesUp -= 1
            default: break
            }

            let remaining = totalHoles - holesPlayed
            if abs(holesUp) > remaining {
                return MatchplayStatus(holesUp: holesUp, holesPlayed: holesPlayed,
                                       totalHoles: totalHoles, isFinished: true)
            }
        }

        return MatchplayStatus(holesUp: holesUp, holesPlayed: holesPlayed,
                               totalHoles: totalHoles, isFinished: holesPlayed == totalHoles)
    }

    // MARK: Skins

    static func skinsResult(round: Round) -> SkinsSummary {
        let sorted = round.sortedScores
        let opponentCount = round.otherPlayerNames.count
        guard opponentCount > 0 else { return SkinsSummary() }

        var summary = SkinsSummary()
        var carryover = 0

        for holeScore in sorted {
            let holeNumber = holeScore.holeNumber
            guard holeScore.strokes > 0 else { continue }

            var scores: [(idx: Int, strokes: Int)] = [(0, holeScore.strokes)]
            var allScored = true
            for i in 1...opponentCount {
                if let opp = round.playerHoleScores.first(where: {
                    $0.playerIndex == i && $0.holeNumber == holeNumber
                }), opp.strokes > 0 {
                    scores.append((i, opp.strokes))
                } else {
                    allScored = false
                    break
                }
            }
            guard allScored else { continue }

            let minStrokes = scores.map(\.strokes).min()!
            let winners = scores.filter { $0.strokes == minStrokes }

            if winners.count == 1 {
                let winner = winners[0].idx
                let won = 1 + carryover
                summary.skinsPerPlayer[winner, default: 0] += won
                summary.holeWinners[holeNumber] = winner
                carryover = 0
            } else {
                summary.holeWinners[holeNumber] = -1
                carryover += 1
            }
        }

        summary.openSkins = carryover
        return summary
    }

    // MARK: Better Ball (2 players)

    static func betterBallHoleValue(holeScore: HoleScore, partnerScore: PlayerHoleScore?,
                                     par: Int, stableford: Bool) -> Int {
        let ps = holeScore.strokes
        let pp = partnerScore?.strokes ?? 0

        if stableford {
            let pPts = ps > 0 ? GameMode.stablefordPoints(strokes: ps, par: par) : 0
            let pPts2 = pp > 0 ? GameMode.stablefordPoints(strokes: pp, par: par) : 0
            return max(pPts, pPts2)
        } else {
            if ps <= 0 { return pp }
            if pp <= 0 { return ps }
            return min(ps, pp)
        }
    }

    static func betterBallTeamTotal(round: Round, stableford: Bool) -> Int {
        guard let course = round.course else { return 0 }
        return round.sortedScores.reduce(0) { total, holeScore in
            guard holeScore.strokes > 0 else { return total }
            let idx = holeScore.holeNumber - 1
            guard idx < course.parValues.count else { return total }
            let partner = round.playerHoleScores.first {
                $0.playerIndex == 1 && $0.holeNumber == holeScore.holeNumber
            }
            return total + betterBallHoleValue(holeScore: holeScore, partnerScore: partner,
                                               par: course.parValues[idx], stableford: stableford)
        }
    }

    // MARK: Best Ball (2–4 players, playerIndex 1-3 are partners)

    static func bestBallHoleValue(round: Round, holeScore: HoleScore, par: Int, stableford: Bool) -> Int {
        var strokes: [Int] = []
        if holeScore.strokes > 0 { strokes.append(holeScore.strokes) }
        for i in 1...3 {
            if let opp = round.opponentScore(playerIndex: i, holeNumber: holeScore.holeNumber),
               opp.strokes > 0 {
                strokes.append(opp.strokes)
            }
        }
        guard !strokes.isEmpty else { return 0 }

        if stableford {
            return strokes.map { GameMode.stablefordPoints(strokes: $0, par: par) }.max() ?? 0
        } else {
            return strokes.min() ?? 0
        }
    }

    static func bestBallTeamTotal(round: Round, stableford: Bool) -> Int {
        guard let course = round.course else { return 0 }
        return round.sortedScores.reduce(0) { total, holeScore in
            let idx = holeScore.holeNumber - 1
            guard idx < course.parValues.count else { return total }
            let val = bestBallHoleValue(round: round, holeScore: holeScore,
                                        par: course.parValues[idx], stableford: stableford)
            return total + val
        }
    }

    // MARK: Erado (scratch N worst holes)

    static func eradoResult(round: Round) -> EradoResult {
        guard let course = round.course else { return EradoResult(total: round.totalStrokes, scratchedHoles: []) }
        let played = round.playedScores
        guard !played.isEmpty else { return EradoResult(total: 0, scratchedHoles: []) }

        let scratchCount = course.numberOfHoles >= 18 ? 2 : 1

        struct HoleDiff { let holeNumber: Int; let strokes: Int; let diff: Int }
        let holes = played.compactMap { s -> HoleDiff? in
            let idx = s.holeNumber - 1
            guard idx < course.parValues.count else { return nil }
            return HoleDiff(holeNumber: s.holeNumber, strokes: s.strokes,
                            diff: s.strokes - course.parValues[idx])
        }

        let scratched = Set(holes.sorted { $0.diff > $1.diff }.prefix(scratchCount).map(\.holeNumber))
        let total = holes.filter { !scratched.contains($0.holeNumber) }.reduce(0) { $0 + $1.strokes }
        return EradoResult(total: total, scratchedHoles: scratched)
    }
}
