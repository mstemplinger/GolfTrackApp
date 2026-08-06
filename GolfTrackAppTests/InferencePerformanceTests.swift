import Testing
import Foundation
import CoreLocation
import SwiftData
@testable import GolfTrackApp

@MainActor
struct InferencePerformanceTests {
    /// 20 Runden × 18 Löcher ≈ 50.000 GPS-Punkte. Beide Auswertungen laufen beim
    /// Öffnen der jeweiligen View auf dem MainActor – sie dürfen nicht in
    /// Sekundenbereiche rutschen. Gemessen: ~145 ms bzw. ~55 ms.
    @Test func staysFastOnACourseWithManyRounds() throws {
        let container = try ModelContainer(
            for: Course.self, Round.self, HoleScore.self, Shot.self,
                 PlayerHoleScore.self, QuizResult.self, GolfClub.self, GolfBag.self, RoundTrack.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let mLat = 111_320.0
        let base = CLLocationCoordinate2D(latitude: 48.6148, longitude: 13.1)
        let course = Course(name: "Perf", numberOfHoles: 18,
                            holeLengths: Array(repeating: 340, count: 18))
        context.insert(course)
        for h in 1...18 {
            course.setTeeCoordinate(CLLocationCoordinate2D(latitude: base.latitude + Double(h)*0.01, longitude: base.longitude), forHole: h)
            course.setFlagCoordinate(CLLocationCoordinate2D(latitude: base.latitude + Double(h)*0.01 + 340/mLat, longitude: base.longitude), forHole: h)
        }
        // 20 Runden × 18 Löcher × ~140 Punkte = 50.400 Punkte pro Platz
        for _ in 0..<20 {
            let round = Round(course: course); context.insert(round); course.rounds.append(round)
            let track = RoundTrack(); context.insert(track); track.round = round; round.track = track
            var pts: [TrackPoint] = []
            for h in 1...18 {
                for i in 0..<140 {
                    pts.append(TrackPoint(latitude: base.latitude + Double(h)*0.01 + Double(i)*2.5/mLat,
                                          longitude: base.longitude, timeOffset: Double(i)*6,
                                          accuracy: 6, holeNumber: h))
                }
            }
            track.append(pts)
        }
        var t0 = Date.now
        let geo = CourseGeometryInference.suggestions(for: course)
        let geoMs = Date.now.timeIntervalSince(t0) * 1000
        t0 = Date.now
        let cor = FairwayCorridorInference.corridors(for: course)
        let corMs = Date.now.timeIntervalSince(t0) * 1000
        #expect(!cor.isEmpty)
        #expect(geo.count == 18)
        #expect(geoMs < 2000, "Geometrie-Ableitung zu langsam: \(Int(geoMs)) ms")
        #expect(corMs < 2000, "Korridor-Ableitung zu langsam: \(Int(corMs)) ms")
    }
}
