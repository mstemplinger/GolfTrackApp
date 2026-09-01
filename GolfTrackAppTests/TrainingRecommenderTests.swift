import Testing
import Foundation
@testable import GolfTrackApp

/// Prüft die Audio-Lektions-Empfehlungen, die nach dem Rundenabschluss
/// im `RoundCompleteSheet` erscheinen.
@MainActor
struct TrainingRecommenderTests {

    /// Runde mit gleichmäßigen Löchern – über die Parameter lassen sich gezielt
    /// einzelne Schwächen erzeugen, alles andere bleibt unauffällig.
    private func round(
        holes: Int = 18,
        par: Int = 4,
        strokes: Int = 4,
        putts: Int = 1,
        fairwayHit: Bool = true,
        gir: Bool = true
    ) -> Round {
        let course = Course(
            name: "Testplatz",
            numberOfHoles: holes,
            parValues: Array(repeating: par, count: holes)
        )
        let round = Round(date: Date(timeIntervalSince1970: 1_700_000_000), course: course)
        round.isComplete = true
        round.holeScores = (1...holes).map { number in
            HoleScore(
                holeNumber: number,
                strokes: strokes,
                putts: putts,
                fairwayHit: fairwayHit,
                greenInRegulation: gir
            )
        }
        return round
    }

    // MARK: Schwächen

    @Test func manyPuttsRecommendsDistanceControl() {
        // 3 Putts auf jedem der 18 Löcher → Ø 3,0, weit über dem Schwellwert 1,9.
        let recs = TrainingRecommender.recommendations(forRound: round(strokes: 6, putts: 3))
        #expect(recs.first?.lesson.id == "06")
        // Kennzahl wird locale-abhängig formatiert ("3,0" bzw. "3.0") – deshalb
        // gegen dieselbe Formatierung prüfen statt gegen einen festen Text.
        let expected = 3.0.formatted(.number.precision(.fractionLength(1)))
        #expect(recs.first?.statLabel?.contains(expected) == true)
    }

    @Test func slightlyManyPuttsRecommendsGreenReading() {
        // Ø 1,8 Putts/Loch – zwischen den Schwellwerten 1,75 und 1,9.
        var scores: [HoleScore] = []
        for number in 1...18 {
            scores.append(HoleScore(holeNumber: number, strokes: 5,
                                    putts: number <= 14 ? 2 : 1,
                                    fairwayHit: true, greenInRegulation: true))
        }
        let r = round()
        r.holeScores = scores
        let recs = TrainingRecommender.recommendations(forRound: r)
        #expect(recs.contains { $0.lesson.id == "17" })
        #expect(recs.contains { $0.lesson.id == "06" } == false)
    }

    @Test func fewFairwaysRecommendsStance() {
        let recs = TrainingRecommender.recommendations(forRound: round(fairwayHit: false))
        #expect(recs.first?.lesson.id == "02")
    }

    @Test func blowUpHolesRecommendCourseManagement() {
        // Jedes Loch 3 über Par → Blow-up-Rate 100 %.
        let recs = TrainingRecommender.recommendations(forRound: round(strokes: 7))
        #expect(recs.contains { $0.lesson.id == "09" })
    }

    // MARK: Reihenfolge und Umfang

    @Test func mostUrgentWeaknessComesFirst() {
        // Putt-Problem (severity 0,9) schlägt Fairway-Problem (severity 0,75).
        let recs = TrainingRecommender.recommendations(forRound: round(strokes: 6, putts: 3, fairwayHit: false))
        #expect(recs.first?.lesson.id == "06")
        #expect(recs.count <= 2)
    }

    // MARK: Randfälle

    @Test func cleanRoundStillOffersALesson() {
        // Keine Schwäche → „Dranbleiben"-Empfehlung ohne Kennzahl.
        let recs = TrainingRecommender.recommendations(forRound: round())
        #expect(recs.isEmpty == false)
        #expect(recs.allSatisfy { $0.statLabel == nil })
    }

    @Test func tooFewHolesGivesNoRecommendation() {
        let r = round(holes: 4)
        #expect(TrainingRecommender.recommendations(forRound: r).isEmpty)
    }

    @Test func untrackedPuttsNeverTriggerPuttLessons() {
        // Wer keine Putts erfasst, soll keine Putt-Empfehlung bekommen.
        let recs = TrainingRecommender.recommendations(forRound: round(putts: 0, fairwayHit: false))
        #expect(recs.contains { $0.lesson.id == "06" || $0.lesson.id == "17" } == false)
    }

    @Test func everyRecommendedLessonHasAudio() {
        let recs = TrainingRecommender.recommendations(forRound: round(strokes: 7, putts: 3, fairwayHit: false, gir: false))
        #expect(recs.isEmpty == false)
        #expect(recs.allSatisfy { $0.lesson.isAvailable })
    }
}
