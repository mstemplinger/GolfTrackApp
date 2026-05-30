import Foundation

/// WHS-konforme Handicap-Berechnung (World Handicap System)
enum HandicapCalculator {

    // MARK: - Score Differential

    /// WHS Score Differential = (113 / Slope) × (Brutto-Score − Course Rating)
    static func scoreDifferential(grossScore: Int, courseRating: Double, slopeRating: Int) -> Double {
        let slope = Double(max(55, min(155, slopeRating)))
        return (113.0 / slope) * (Double(grossScore) - courseRating)
    }

    // MARK: - Anzahl der besten Differentials (WHS-Tabelle)

    static func bestCount(for roundCount: Int) -> Int {
        switch roundCount {
        case 3...5:  return 1
        case 6...8:  return 2
        case 9...11: return 3
        case 12...14: return 4
        case 15...16: return 5
        case 17...18: return 6
        case 19:     return 7
        default:     return 8  // 20+
        }
    }

    // MARK: - Handicap Index

    /// Berechnet den WHS Handicap Index aus abgeschlossenen Runden.
    /// Benötigt mindestens 3 Runden mit Course Rating & Slope Rating.
    /// Gibt nil zurück, wenn nicht genug Daten vorhanden.
    static func handicapIndex(from rounds: [Round]) -> Double? {
        // Maximal die letzten 20 Runden verwenden
        let eligible = Array(rounds.prefix(20))
        guard eligible.count >= 3 else { return nil }

        let differentials: [Double] = eligible.compactMap { round -> Double? in
            guard let course = round.course,
                  round.totalStrokes > 0,
                  course.courseRating > 0,
                  course.slopeRating > 0 else { return nil }
            return scoreDifferential(
                grossScore: round.totalStrokes,
                courseRating: course.courseRating,
                slopeRating: course.slopeRating
            )
        }

        guard differentials.count >= 3 else { return nil }

        let count = bestCount(for: differentials.count)
        let sorted = differentials.sorted()
        let best = sorted.prefix(count)
        let avg = best.reduce(0, +) / Double(best.count)

        // Faktor 0.96, auf 1 Dezimalstelle gerundet
        let index = (avg * 0.96 * 10).rounded() / 10
        return max(0, index)
    }

    // MARK: - Formatierter Anzeigestring

    static func displayString(from rounds: [Round]) -> String {
        guard let index = handicapIndex(from: rounds) else { return "–" }
        return String(format: "%.1f", index)
    }

    // MARK: - Fortschrittsinfo

    struct ProgressInfo {
        let usedRounds: Int
        let eligibleRounds: Int
        let bestDifferentials: [Double]
        let allDifferentials: [Double]
        let handicapIndex: Double
    }

    static func progressInfo(from rounds: [Round]) -> ProgressInfo? {
        let eligible = Array(rounds.prefix(20))
        guard eligible.count >= 3 else { return nil }

        let differentials: [Double] = eligible.compactMap { round -> Double? in
            guard let course = round.course,
                  round.totalStrokes > 0,
                  course.courseRating > 0,
                  course.slopeRating > 0 else { return nil }
            return scoreDifferential(
                grossScore: round.totalStrokes,
                courseRating: course.courseRating,
                slopeRating: course.slopeRating
            )
        }
        guard differentials.count >= 3 else { return nil }

        let count = bestCount(for: differentials.count)
        let sorted = differentials.sorted()
        let best = Array(sorted.prefix(count))
        let avg = best.reduce(0, +) / Double(best.count)
        let index = max(0, (avg * 0.96 * 10).rounded() / 10)

        return ProgressInfo(
            usedRounds: count,
            eligibleRounds: differentials.count,
            bestDifferentials: best,
            allDifferentials: differentials,
            handicapIndex: index
        )
    }
}
