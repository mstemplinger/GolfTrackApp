import Testing
import Foundation
@testable import GolfTrackApp

/// Prüft die Erkennung nachgetragener Runden: eine Aufzeichnung von wenigen
/// Minuten kann keine gespielte Runde sein.
struct BackfilledRoundTests {

    /// Track mit gesetzter Dauer und einem Punkt je Minute.
    private func track(minutes: Double, points: Int = 10) -> RoundTrack {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let track = RoundTrack(startedAt: start)
        track.endedAt = start.addingTimeInterval(minutes * 60)
        track.append((0..<points).map { i in
            TrackPoint(latitude: 48.6 + Double(i) * 1e-5, longitude: 13.5,
                       timeOffset: Double(i) * 60, accuracy: 5, holeNumber: (i % 18) + 1)
        })
        return track
    }

    @Test func realRoundIsNotFlagged() {
        // 18 Löcher in 4 Stunden – normal.
        let t = track(minutes: 240)
        #expect(t.minutesPerHole(playedHoles: 18)! > 13)
        #expect(t.looksBackfilled(playedHoles: 18) == false)
    }

    @Test func quickNineIsNotFlagged() {
        // 9 Löcher in 2 Stunden.
        #expect(track(minutes: 120).looksBackfilled(playedHoles: 9) == false)
    }

    @Test func backfilledRoundIsFlagged() {
        // 18 Löcher in 20 Minuten – am Schreibtisch eingetragen.
        let t = track(minutes: 20)
        #expect(abs(t.minutesPerHole(playedHoles: 18)! - 20.0 / 18.0) < 0.001)
        #expect(t.looksBackfilled(playedHoles: 18))
    }

    @Test func thresholdIsThreeMinutesPerHole() {
        // Genau an der Grenze: 18 × 3 min = 54 min zählt noch als gespielt.
        #expect(track(minutes: 54).looksBackfilled(playedHoles: 18) == false)
        #expect(track(minutes: 53).looksBackfilled(playedHoles: 18))
        #expect(RoundTrack.minimumMinutesPerHole == 3)
    }

    @Test func singleHoleNeedsThreeMinutesToo() {
        // Ein Loch nachgetragen: 30 Sekunden Aufzeichnung.
        #expect(track(minutes: 0.5).looksBackfilled(playedHoles: 1))
        #expect(track(minutes: 8).looksBackfilled(playedHoles: 1) == false)
    }

    @Test func emptyTrackIsNeverFlagged() {
        // Ohne Punkte gibt es nichts zu verwerfen – die Abfrage darf nicht kommen.
        let empty = track(minutes: 1, points: 0)
        #expect(empty.pointCount == 0)
        #expect(empty.looksBackfilled(playedHoles: 18) == false)
    }

    @Test func noPlayedHolesIsNeverFlagged() {
        // Runde geöffnet, aber kein Score eingetragen: keine Aussage möglich.
        #expect(track(minutes: 1).looksBackfilled(playedHoles: 0) == false)
        #expect(track(minutes: 1).minutesPerHole(playedHoles: 0) == nil)
    }
}
