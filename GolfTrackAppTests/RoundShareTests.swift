import Foundation
import Testing
import UIKit
@testable import GolfTrackApp

/// Zahlen und Text, die am Ende einer Runde geteilt werden. Die Prüfungen
/// hängen nicht an deutschen Wörtern – der Simulator läuft nicht immer auf
/// Deutsch.
struct RoundShareTests {

    @Test func golfZaehltSchlaegeUndStandGegenPar() {
        let summary = RoundShareSummary.golf(courseName: "Bayerwald", date: nil,
                                             strokes: [5, 3, 4, 0], pars: [4, 3, 5, 4])
        #expect(summary.totalStrokes == 12)
        #expect(summary.holesPlayed == 3)
        #expect(summary.holesTotal == 4)
        // Nur gespielte Löcher zählen gegen Par: +1, 0, −1.
        #expect(summary.scoreToPar == 0)
    }

    @Test func golfOhneParLaesstStandWeg() {
        let summary = RoundShareSummary.golf(courseName: nil, date: nil,
                                             strokes: [5, 6], pars: [])
        #expect(summary.scoreToPar == nil)
    }

    @Test func minigolfMehrspielerTeiltPlaetzeBeiGleichstand() {
        let summary = RoundShareSummary.minigolf(
            playerNames: ["Anna", "Ben", "Cem"],
            scores: [[2, 3], [1, 4], [3, 3]],
            numberOfHoles: 2, courseName: "Sankt Englmar", date: nil)
        #expect(summary.isGroup)
        #expect(summary.ranking.map(\.name) == ["Anna", "Ben", "Cem"])
        #expect(summary.ranking.map(\.place) == [0, 0, 2])
        #expect(summary.holeStrokes.isEmpty)
    }

    @Test func minigolfAlleinZeigtBahnen() {
        let summary = RoundShareSummary.minigolf(
            playerNames: ["Anna"], scores: [[2, 1, 0]],
            numberOfHoles: 3, courseName: nil, date: nil)
        #expect(!summary.isGroup)
        #expect(summary.totalStrokes == 3)
        #expect(summary.holesPlayed == 2)
        #expect(summary.holeStrokes == [2, 1, 0])
    }

    @Test func textNenntPlatzSchlaegeUndLink() {
        let summary = RoundShareSummary.golf(courseName: "Bayerwald", date: nil,
                                             strokes: [5, 4], pars: [4, 4])
        let text = RoundShareText.message(for: summary)
        #expect(text.contains("Bayerwald"))
        #expect(text.contains("9"))
        #expect(text.contains("+1"))
        #expect(text.contains(RoundShareText.downloadURL.absoluteString))
    }

    @Test func textListetRanglisteMitMedaillen() {
        let summary = RoundShareSummary.minigolf(
            playerNames: ["Anna", "Ben"], scores: [[2, 2], [3, 3]],
            numberOfHoles: 2, courseName: "Sankt Englmar", date: nil)
        let text = RoundShareText.message(for: summary)
        #expect(text.contains("🥇 Anna"))
        #expect(text.contains("🥈 Ben"))
        #expect(text.contains("Sankt Englmar"))
    }

    @MainActor
    @Test func karteLaesstSichRendern() {
        let summary = RoundShareSummary.minigolf(
            playerNames: ["Anna"], scores: [[2, 1, 3]],
            numberOfHoles: 3, courseName: "Sankt Englmar", date: Date())
        let image = RoundShareCard.image(for: summary)
        #expect(image != nil)
        #expect((image?.size.width ?? 0) == RoundShareCard.width)
    }
}
