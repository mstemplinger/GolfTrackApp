import Testing
import Foundation
import CoreLocation
import SwiftData
@testable import GolfTrackApp

/// Prüft die Ableitung von Abschlag- und Grünposition aus synthetischen Laufspuren.
@MainActor
struct CourseGeometryInferenceTests {

    // MARK: - Hilfen

    /// Verschiebt eine Koordinate um `north`/`east` Meter.
    private func offset(_ base: CLLocationCoordinate2D, north: Double, east: Double) -> CLLocationCoordinate2D {
        let metersPerDegreeLat = 111_320.0
        let metersPerDegreeLon = 111_320.0 * cos(base.latitude * .pi / 180)
        return CLLocationCoordinate2D(latitude: base.latitude + north / metersPerDegreeLat,
                                      longitude: base.longitude + east / metersPerDegreeLon)
    }

    private func container() throws -> ModelContainer {
        try ModelContainer(
            for: Course.self, Round.self, HoleScore.self, Shot.self,
                 PlayerHoleScore.self, QuizResult.self, GolfClub.self, GolfBag.self, RoundTrack.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// Baut eine realistische Laufspur für ein Loch: 60 s Stillstand am Abschlag,
    /// Gehen bis zum Grün, 50 s Stillstand am Grün (Putten).
    private func syntheticPoints(tee: CLLocationCoordinate2D,
                                 green: CLLocationCoordinate2D,
                                 hole: Int,
                                 startTime: Double = 0,
                                 jitter: Double = 0) -> [TrackPoint] {
        var points: [TrackPoint] = []
        var time = startTime

        func add(_ coord: CLLocationCoordinate2D) {
            let jittered = jitter == 0 ? coord : offset(coord, north: jitter, east: -jitter)
            points.append(TrackPoint(latitude: jittered.latitude,
                                     longitude: jittered.longitude,
                                     timeOffset: time,
                                     accuracy: 6,
                                     holeNumber: hole))
        }

        // Abschlag: 7 Punkte über 60 s, ±2 m Streuung
        for i in 0..<7 {
            add(offset(tee, north: Double(i % 3) - 1, east: Double(i % 2)))
            time += 10
        }
        // Gehen zum Grün
        let steps = 30
        for i in 1..<steps {
            let f = Double(i) / Double(steps)
            add(CLLocationCoordinate2D(
                latitude: tee.latitude + (green.latitude - tee.latitude) * f,
                longitude: tee.longitude + (green.longitude - tee.longitude) * f))
            time += 8
        }
        // Grün: 6 Punkte über 50 s
        for i in 0..<6 {
            add(offset(green, north: Double(i % 3) - 1, east: Double(i % 2) - 1))
            time += 10
        }
        return points
    }

    private func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    // MARK: - Codec

    @Test func codecRoundTripsPointsExactly() {
        let points = (0..<500).map { i in
            TrackPoint(latitude: 48.6 + Double(i) * 1e-5,
                       longitude: 13.1 + Double(i) * 1e-5,
                       timeOffset: Double(i) * 7,
                       accuracy: 5,
                       holeNumber: (i % 18) + 1)
        }
        let data = TrackPointCodec.encode(points)
        #expect(data.count == points.count * TrackPointCodec.recordSize)

        let decoded = TrackPointCodec.decode(data)
        #expect(decoded.count == points.count)
        for (original, restored) in zip(points, decoded) {
            #expect(original.latitude == restored.latitude)
            #expect(original.longitude == restored.longitude)
            #expect(original.timeOffset == restored.timeOffset)
            #expect(original.holeNumber == restored.holeNumber)
        }
    }

    @Test func trackAppendKeepsCountInSync() throws {
        let track = RoundTrack()
        track.append([TrackPoint(latitude: 48.6, longitude: 13.1, timeOffset: 0, accuracy: 5, holeNumber: 1)])
        track.append([TrackPoint(latitude: 48.61, longitude: 13.11, timeOffset: 10, accuracy: 5, holeNumber: 1)])
        #expect(track.pointCount == 2)
        #expect(track.points.count == 2)
        #expect(track.recordedHoles == [1])
    }

    // MARK: - Ableitung

    @Test func derivesTeeAndGreenFromSingleWalk() throws {
        let container = try container()
        let context = ModelContext(container)

        let tee = CLLocationCoordinate2D(latitude: 48.6148, longitude: 13.1000)
        let green = offset(tee, north: 340, east: 40)   // ~342 m Luftlinie

        let course = Course(name: "Testplatz", numberOfHoles: 18,
                            holeLengths: [342] + Array(repeating: 0, count: 17))
        context.insert(course)

        let round = Round(course: course)
        context.insert(round)
        course.rounds.append(round)

        let track = RoundTrack()
        context.insert(track)
        track.round = round
        round.track = track
        track.append(syntheticPoints(tee: tee, green: green, hole: 1))

        let suggestions = CourseGeometryInference.suggestions(for: course)
        let hole1 = try #require(suggestions.first { $0.holeNumber == 1 })

        let derivedTee = try #require(hole1.tee)
        let derivedGreen = try #require(hole1.green)

        // Beide Positionen müssen im Bereich der Stillstands-Cluster liegen.
        #expect(distance(derivedTee, tee) < 8)
        #expect(distance(derivedGreen, green) < 8)
        #expect(hole1.isPlausible)
        #expect(hole1.roundCount == 1)
        // Eine einzelne Laufspur allein darf keine hohe Konfidenz erzeugen.
        #expect(hole1.teeConfidence < 0.7)
    }

    @Test func moreRoundsRaiseConfidence() throws {
        let container = try container()
        let context = ModelContext(container)

        let tee = CLLocationCoordinate2D(latitude: 48.6148, longitude: 13.1000)
        let green = offset(tee, north: 340, east: 40)

        let course = Course(name: "Testplatz", numberOfHoles: 18,
                            holeLengths: [342] + Array(repeating: 0, count: 17))
        context.insert(course)

        for i in 0..<3 {
            let round = Round(course: course)
            context.insert(round)
            course.rounds.append(round)
            let track = RoundTrack()
            context.insert(track)
            track.round = round
            round.track = track
            // Jede Runde leicht verschoben – so entsteht eine realistische Streuung.
            track.append(syntheticPoints(tee: tee, green: green, hole: 1, jitter: Double(i) * 2))
        }

        let hole1 = try #require(CourseGeometryInference.suggestions(for: course).first)
        #expect(hole1.roundCount == 3)
        #expect(hole1.teeConfidence >= 0.7)
        #expect(distance(try #require(hole1.tee), tee) < 10)
    }

    @Test func trackedShotsOutweighWalkingPath() throws {
        let container = try container()
        let context = ModelContext(container)

        let tee = CLLocationCoordinate2D(latitude: 48.6148, longitude: 13.1000)
        let green = offset(tee, north: 340, east: 40)
        // Der Spieler ist am Abschlag 25 m abseits stehen geblieben (Wartezeit),
        // der getrackte Schlag kennt die richtige Position.
        let wrongStand = offset(tee, north: -25, east: 0)

        let course = Course(name: "Testplatz", numberOfHoles: 18,
                            holeLengths: [342] + Array(repeating: 0, count: 17))
        context.insert(course)

        let round = Round(course: course)
        context.insert(round)
        course.rounds.append(round)

        let holeScore = HoleScore(holeNumber: 1, strokes: 4, putts: 2)
        context.insert(holeScore)
        round.holeScores.append(holeScore)
        let shot = Shot(shotNumber: 1, from: tee, to: offset(tee, north: 200, east: 10), club: "Driver")
        context.insert(shot)
        shot.holeScore = holeScore

        let track = RoundTrack()
        context.insert(track)
        track.round = round
        round.track = track
        track.append(syntheticPoints(tee: wrongStand, green: green, hole: 1))

        let hole1 = try #require(CourseGeometryInference.suggestions(for: course).first)
        let derivedTee = try #require(hole1.tee)
        // Gewicht 2 (Schlag) gegen 1 (Laufspur) → Ergebnis liegt näher am Schlagpunkt.
        #expect(distance(derivedTee, tee) < distance(derivedTee, wrongStand))
    }

    @Test func flagsImplausibleLengthAgainstScorecard() throws {
        let container = try container()
        let context = ModelContext(container)

        let tee = CLLocationCoordinate2D(latitude: 48.6148, longitude: 13.1000)
        let green = offset(tee, north: 120, east: 0)

        // Scorecard sagt 342 m, die Laufspur ergibt nur 120 m → unplausibel.
        let course = Course(name: "Testplatz", numberOfHoles: 18,
                            holeLengths: [342] + Array(repeating: 0, count: 17))
        context.insert(course)

        let round = Round(course: course)
        context.insert(round)
        course.rounds.append(round)
        let track = RoundTrack()
        context.insert(track)
        track.round = round
        round.track = track
        track.append(syntheticPoints(tee: tee, green: green, hole: 1))

        let hole1 = try #require(CourseGeometryInference.suggestions(for: course).first)
        #expect(!hole1.isPlausible)

        // Unplausible Vorschläge dürfen nicht automatisch übernommen werden.
        let applied = CourseGeometryInference.apply([hole1], to: course, minConfidence: 0.4)
        #expect(applied == 0)
        #expect(course.flagCoordinate(forHole: 1) == nil)
    }

    @Test func applyWritesOnlySelectedHoles() throws {
        let container = try container()
        let context = ModelContext(container)

        let tee = CLLocationCoordinate2D(latitude: 48.6148, longitude: 13.1000)
        let green = offset(tee, north: 340, east: 40)

        let course = Course(name: "Testplatz", numberOfHoles: 18,
                            holeLengths: [342] + Array(repeating: 0, count: 17))
        context.insert(course)

        let round = Round(course: course)
        context.insert(round)
        course.rounds.append(round)
        let track = RoundTrack()
        context.insert(track)
        track.round = round
        round.track = track
        track.append(syntheticPoints(tee: tee, green: green, hole: 7))

        let suggestions = CourseGeometryInference.suggestions(for: course)
        CourseGeometryInference.apply(suggestions, to: course, minConfidence: 0.2)

        // Nur Loch 7 hat Daten – alle anderen bleiben leer.
        #expect(course.teeCoordinate(forHole: 7) != nil)
        #expect(course.flagCoordinate(forHole: 7) != nil)
        #expect(course.teeCoordinate(forHole: 1) == nil)
        #expect(course.teeCoordinate(forHole: 18) == nil)
        #expect(course.holePositionCount == 1)
    }
}
