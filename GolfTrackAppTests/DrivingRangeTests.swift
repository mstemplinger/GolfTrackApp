import Foundation
import Testing
@testable import GolfTrackApp

/// Kennzahlen und Bestweiten-Vergleich der Driving Range.
@MainActor
struct DrivingRangeTests {

    private func session(daysAgo: Int, _ shots: [(String, Double)]) -> RangeSession {
        let s = RangeSession(date: Date(timeIntervalSinceNow: -Double(daysAgo) * 86_400))
        s.shots = shots.map { RangeShot(clubName: $0.0, distanceMeters: $0.1) }
        return s
    }

    @Test func statsPerClub() {
        let s = session(daysAgo: 0, [("7 Eisen", 140), ("7 Eisen", 150), ("Driver", 210)])
        let stats = RangeClubStats.byClub(s.shots)
        #expect(stats["7 Eisen"]?.count == 2)
        #expect(stats["7 Eisen"]?.average == 145)
        #expect(stats["7 Eisen"]?.best == 150)
        #expect(stats["Driver"]?.best == 210)
    }

    @Test func firstSessionIsNoPersonalBest() {
        let s = session(daysAgo: 0, [("Driver", 200), ("Driver", 230)])
        #expect(!GameCenterManager.hasBeatenEarlierBest(sessions: [s]))
    }

    @Test func laterSessionBeatsEarlierBest() {
        let first = session(daysAgo: 3, [("Driver", 200)])
        let second = session(daysAgo: 0, [("Driver", 205)])
        #expect(GameCenterManager.hasBeatenEarlierBest(sessions: [second, first]))
    }

    @Test func otherClubDoesNotCount() {
        let first = session(daysAgo: 3, [("Driver", 200)])
        let second = session(daysAgo: 0, [("7 Eisen", 150), ("Driver", 190)])
        #expect(!GameCenterManager.hasBeatenEarlierBest(sessions: [first, second]))
    }

    @Test func driverDetection() {
        #expect(RangeClubDefaults.isDriver("Driver"))
        #expect(RangeClubDefaults.isDriver("Mein Driver 10,5°"))
        #expect(!RangeClubDefaults.isDriver("3 Wood"))
    }
}
