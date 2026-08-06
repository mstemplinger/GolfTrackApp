import Testing
import Foundation
import CoreLocation
import SwiftData
@testable import GolfTrackApp

/// Prüft die Ableitung des Fairway-Korridors sowie die Zusicherung, dass das
/// Ergebnisformat weder Zeit noch Kennung enthält.
@MainActor
struct FairwayCorridorInferenceTests {

    private let tee = CLLocationCoordinate2D(latitude: 48.6148, longitude: 13.1000)

    // MARK: - Hilfen

    private func offset(_ base: CLLocationCoordinate2D, north: Double, east: Double) -> CLLocationCoordinate2D {
        let mLat = 111_320.0
        let mLon = 111_320.0 * cos(base.latitude * .pi / 180)
        return CLLocationCoordinate2D(latitude: base.latitude + north / mLat,
                                      longitude: base.longitude + east / mLon)
    }

    private func container() throws -> ModelContainer {
        try ModelContainer(
            for: Course.self, Round.self, HoleScore.self, Shot.self,
                 PlayerHoleScore.self, QuizResult.self, GolfClub.self, GolfBag.self, RoundTrack.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// Platz mit gesetzter Abschlag-/Grünposition für Loch 1 (Par 4, Achse exakt Nord).
    private func makeCourse(in context: ModelContext,
                            axisLength: Double = 340,
                            par: Int = 4) -> (Course, CLLocationCoordinate2D) {
        var pars = Array(repeating: 4, count: 18)
        pars[0] = par
        let course = Course(name: "Testplatz", numberOfHoles: 18, parValues: pars,
                            holeLengths: [Int(axisLength)] + Array(repeating: 0, count: 17))
        context.insert(course)
        let green = offset(tee, north: axisLength, east: 0)
        course.setTeeCoordinate(tee, forHole: 1)
        course.setFlagCoordinate(green, forHole: 1)
        return (course, green)
    }

    /// Hängt eine Runde mit Laufspur an – `lateral(axial)` bestimmt den Seitenversatz.
    @discardableResult
    private func addWalk(to course: Course,
                         context: ModelContext,
                         axisLength: Double,
                         hole: Int = 1,
                         step: Double = 5,
                         lateral: (Double) -> Double) -> Round {
        let round = Round(course: course)
        context.insert(round)
        course.rounds.append(round)
        let track = RoundTrack()
        context.insert(track)
        track.round = round
        round.track = track

        var points: [TrackPoint] = []
        var axial: Double = 0
        var time: Double = 0
        while axial <= axisLength {
            let coord = offset(tee, north: axial, east: lateral(axial))
            points.append(TrackPoint(latitude: coord.latitude, longitude: coord.longitude,
                                     timeOffset: time, accuracy: 6, holeNumber: hole))
            axial += step
            time += 6
        }
        track.append(points)
        return round
    }

    // MARK: - Achsen-Mathematik

    @Test func axisFrameProjectsAndInverts() {
        let green = offset(tee, north: 300, east: 0)
        let frame = AxisFrame(tee: tee, green: green)
        #expect(abs(frame.length - 300) < 1)

        // 100 m Richtung Grün, 20 m nach Osten → rechts der Achse (Blick nach Norden)
        let point = offset(tee, north: 100, east: 20)
        let (axial, lat) = frame.project(point)
        #expect(abs(axial - 100) < 1)
        #expect(abs(lat - 20) < 1)

        // Rücktransformation trifft wieder denselben Punkt
        let back = frame.coordinate(axial: axial, lateral: lat)
        let distance = CLLocation(latitude: back.latitude, longitude: back.longitude)
            .distance(from: CLLocation(latitude: point.latitude, longitude: point.longitude))
        #expect(distance < 1)
    }

    @Test func weightedPercentileRespectsWeights() {
        // Ein schwerer Wert bei 0 gegen zwei leichte bei 30 → Median bleibt bei 0
        let samples: [(value: Double, weight: Double)] = [(0, 10), (30, 1), (30, 1)]
        #expect(FairwayCorridorInference.weightedPercentile(samples, 0.5) == 0)
        #expect(FairwayCorridorInference.weightedPercentile(samples, 0.9) == 30)
    }

    // MARK: - Gerades Loch

    @Test func derivesStraightCorridorCenteredOnAxis() throws {
        let context = ModelContext(try container())
        let (course, _) = makeCourse(in: context)

        // Drei Runden, Seitenversatz ±8 m um die Achse
        for (i, side) in [-8.0, 0.0, 8.0].enumerated() {
            addWalk(to: course, context: context, axisLength: 340, step: 5) { _ in side + Double(i) * 0.5 }
        }

        let corridor = try #require(FairwayCorridorInference.corridor(forHole: 1, course: course))
        #expect(corridor.roundCount == 3)
        #expect(corridor.bins.count >= 20)

        // Mittellinie liegt nahe der Achse
        let maxCenter = corridor.bins.map { abs($0.centerOffset) }.max() ?? 99
        #expect(maxCenter < 6)
        // Korridor ist etwa so breit wie die Streuung, nicht beliebig
        #expect(corridor.averageWidthMeters > 8)
        #expect(corridor.averageWidthMeters < 30)
        // Polygon ist geschlossen nutzbar
        #expect(corridor.corridorPolygon.count == corridor.bins.count * 2)
        #expect(corridor.centerline.count == corridor.bins.count)
    }

    @Test func followsDoglegInsteadOfStraightLine() throws {
        let context = ModelContext(try container())
        let (course, _) = makeCourse(in: context, axisLength: 360)

        // Dogleg rechts: ab 150 m wandert der Weg auf +45 m und kommt zum Grün zurück
        for _ in 0..<3 {
            addWalk(to: course, context: context, axisLength: 360, step: 5) { axial in
                if axial < 150 { return 0 }
                if axial < 260 { return (axial - 150) / 110 * 45 }
                return 45 - (axial - 260) / 100 * 45
            }
        }

        let corridor = try #require(FairwayCorridorInference.corridor(forHole: 1, course: course))
        let bend = corridor.bins.first { $0.index == 22 }   // ~225 m
        let start = corridor.bins.first { $0.index == 5 }   // ~55 m

        #expect(abs(try #require(start).centerOffset) < 6)
        #expect(try #require(bend).centerOffset > 20)
    }

    // MARK: - Abgrenzungen

    @Test func skipsPar3Holes() throws {
        let context = ModelContext(try container())
        let (course, _) = makeCourse(in: context, axisLength: 150, par: 3)
        addWalk(to: course, context: context, axisLength: 150, step: 5) { _ in 0 }

        #expect(FairwayCorridorInference.isFairwayHole(1, course: course) == false)
        #expect(FairwayCorridorInference.corridor(forHole: 1, course: course) == nil)
        #expect(FairwayCorridorInference.corridors(for: course).isEmpty)
    }

    @Test func ignoresPointsFarOffTheAxis() throws {
        let context = ModelContext(try container())
        let (course, _) = makeCourse(in: context)

        addWalk(to: course, context: context, axisLength: 340, step: 5) { _ in 0 }
        // Nachbarloch: 120 m seitlich – darf den Korridor nicht aufblähen
        addWalk(to: course, context: context, axisLength: 340, step: 5) { _ in 120 }

        let corridor = try #require(FairwayCorridorInference.corridor(forHole: 1, course: course))
        #expect(corridor.averageWidthMeters < 10)
        #expect((corridor.bins.map { abs($0.rightOffset) }.max() ?? 99) < FairwayCorridorInference.maxLateralMeters)
    }

    @Test func needsTeeAndGreenPositions() throws {
        let context = ModelContext(try container())
        let course = Course(name: "Ohne Positionen", numberOfHoles: 18)
        context.insert(course)
        addWalk(to: course, context: context, axisLength: 340, step: 5) { _ in 0 }

        #expect(FairwayCorridorInference.corridor(forHole: 1, course: course) == nil)
    }

    @Test func singleRoundIsMarkedAsVeryThin() throws {
        let context = ModelContext(try container())
        let (course, _) = makeCourse(in: context)
        addWalk(to: course, context: context, axisLength: 340, step: 5) { _ in 0 }

        let corridor = try #require(FairwayCorridorInference.corridor(forHole: 1, course: course))
        #expect(corridor.roundCount == 1)
        #expect(corridor.reliability == .veryThin)
    }

    @Test func trackedBallPositionsPullCorridorTowardsThem() throws {
        let context = ModelContext(try container())
        let (course, _) = makeCourse(in: context)

        // Gelaufen wird 25 m links (Weg am Rand), gespielt wird auf der Achse.
        let round = addWalk(to: course, context: context, axisLength: 340, step: 5) { _ in -25 }
        let holeScore = HoleScore(holeNumber: 1, strokes: 4, putts: 2)
        context.insert(holeScore)
        round.holeScores.append(holeScore)
        for i in 0..<3 {
            let from = offset(tee, north: Double(i) * 100, east: 0)
            let to = offset(tee, north: Double(i + 1) * 100, east: 0)
            let shot = Shot(shotNumber: i + 1, from: from, to: to, club: "Eisen")
            context.insert(shot)
            shot.holeScore = holeScore
        }

        let corridor = try #require(FairwayCorridorInference.corridor(forHole: 1, course: course))
        // In den Abschnitten mit Ballpositionen zieht die Mittellinie zur Achse.
        let atBall = try #require(corridor.bins.first { $0.index == 10 })   // ~105 m
        #expect(atBall.centerOffset > -25)
    }

    // MARK: - Persistenz & Payload

    @Test func corridorsSurviveSaveAndReload() throws {
        let context = ModelContext(try container())
        let (course, _) = makeCourse(in: context)
        for _ in 0..<3 { addWalk(to: course, context: context, axisLength: 340, step: 5) { _ in 0 } }

        let computed = FairwayCorridorInference.corridors(for: course)
        #expect(!computed.isEmpty)
        course.setFairwayCorridors(computed)

        #expect(course.fairwayComputedAt != nil)
        let restored = course.fairwayCorridors
        #expect(restored == computed)
        #expect(course.corridor(forHole: 1)?.bins.count == computed.first?.bins.count)
    }

    /// Zusicherung für einen späteren Upload: das Format enthält keine Zeit,
    /// keine Kennung und keine Einzelmesspunkte.
    @Test func payloadContainsNoTimeOrIdentity() throws {
        let context = ModelContext(try container())
        let (course, _) = makeCourse(in: context)
        for _ in 0..<3 { addWalk(to: course, context: context, axisLength: 340, step: 5) { _ in 4 } }

        let corridors = FairwayCorridorInference.corridors(for: course)
        let data = try JSONEncoder().encode(corridors)
        let json = try #require(String(data: data, encoding: .utf8)).lowercased()

        for forbidden in ["date", "time", "timestamp", "id\"", "uuid", "device", "player", "name", "score"] {
            #expect(!json.contains(forbidden), "Payload enthält \(forbidden)")
        }

        // Und die Werte sind auf Dezimeter gerundet – keine Scheingenauigkeit.
        for bin in try #require(corridors.first).bins {
            #expect((bin.centerOffset * 10).rounded() == bin.centerOffset * 10)
        }
    }
}
