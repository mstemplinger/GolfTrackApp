import Testing
import Foundation
import CoreLocation
import SwiftData
@testable import GolfTrackApp

/// Crowd-Positionen: was die App nach einer Runde schickt, wie sie lückenhafte
/// Positionen aus dem Verzeichnis liest und wann sie lokale Positionen durch
/// bessere aus dem Verzeichnis ersetzt.
@MainActor
struct CrowdGeometryTests {

    // MARK: - Hilfen

    private let base = CLLocationCoordinate2D(latitude: 48.83215, longitude: 13.37012)

    private func offset(_ c: CLLocationCoordinate2D, north: Double, east: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: c.latitude + north / 111_320,
                               longitude: c.longitude + east / (111_320 * cos(c.latitude * .pi / 180)))
    }

    private func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    private func container() throws -> ModelContainer {
        try ModelContainer(
            for: Course.self, Round.self, HoleScore.self, Shot.self,
                 PlayerHoleScore.self, QuizResult.self, GolfClub.self, GolfBag.self, RoundTrack.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// 60 s am Abschlag, Gehen, 50 s am Grün – wie in `CourseGeometryInferenceTests`.
    private func points(tee: CLLocationCoordinate2D, green: CLLocationCoordinate2D,
                        hole: Int, start: Double) -> [TrackPoint] {
        var result: [TrackPoint] = []
        var time = start
        func add(_ c: CLLocationCoordinate2D) {
            result.append(TrackPoint(latitude: c.latitude, longitude: c.longitude,
                                     timeOffset: time, accuracy: 5, holeNumber: hole))
        }
        for i in 0..<7 { add(offset(tee, north: Double(i % 3) - 1, east: Double(i % 2))); time += 10 }
        for i in 1..<30 {
            let f = Double(i) / 30
            add(CLLocationCoordinate2D(latitude: tee.latitude + (green.latitude - tee.latitude) * f,
                                       longitude: tee.longitude + (green.longitude - tee.longitude) * f))
            time += 8
        }
        for i in 0..<6 { add(offset(green, north: Double(i % 3) - 1, east: Double(i % 2) - 1)); time += 10 }
        return result
    }

    // MARK: - Nutzlast

    @Test("Nach einer Runde gehen nur gerundete Punkte je Loch raus – keine Zeit, keine Kennung")
    func payloadContainsOnlyPoints() throws {
        let context = ModelContext(try container())
        let course = Course(name: "Testplatz", numberOfHoles: 2, holeLengths: [300, 150],
                            latitude: base.latitude, longitude: base.longitude)
        context.insert(course)
        let round = Round(course: course)
        context.insert(round)
        course.rounds.append(round)
        round.teeColor = .yellow
        round.isComplete = true

        let tee1 = base, green1 = offset(base, north: 300, east: 0)
        let tee2 = offset(green1, north: 10, east: 20), green2 = offset(tee2, north: 0, east: 150)
        let track = RoundTrack()
        context.insert(track)
        round.track = track
        track.append(points(tee: tee1, green: green1, hole: 1, start: 0)
                     + points(tee: tee2, green: green2, hole: 2, start: 1000))

        let payload = try #require(CrowdGeometryService.payload(for: round))
        #expect(payload.version == 1)
        #expect(payload.teeColor == "yellow")
        #expect(payload.holes.map(\.hole) == [1, 2])

        let first = try #require(payload.holes.first?.tee)
        #expect(distance(CLLocationCoordinate2D(latitude: first.lat, longitude: first.lon), tee1) < 5)
        // Auf 5 Nachkommastellen gerundet.
        #expect((first.lat * 100_000).rounded() == first.lat * 100_000)

        // Nur diese Feldnamen dürfen im JSON vorkommen.
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(payload))
        var keys = Set<String>()
        func collect(_ value: Any) {
            if let dict = value as? [String: Any] {
                keys.formUnion(dict.keys)
                dict.values.forEach(collect)
            } else if let array = value as? [Any] {
                array.forEach(collect)
            }
        }
        collect(json)
        #expect(keys.isSubset(of: ["version", "teeColor", "holes", "hole", "tee", "green", "lat", "lon", "confidence"]))
    }

    @Test("Punkte weit weg vom Platz (Runde nachgetragen, falscher Platz) werden nicht gesendet")
    func farAwayPointsAreDropped() throws {
        let context = ModelContext(try container())
        // Platzmittelpunkt 50 km entfernt von der Laufspur.
        let course = Course(name: "Woanders", numberOfHoles: 1, holeLengths: [300],
                            latitude: base.latitude + 0.45, longitude: base.longitude)
        context.insert(course)
        let round = Round(course: course)
        context.insert(round)
        course.rounds.append(round)
        let track = RoundTrack()
        context.insert(track)
        round.track = track
        track.append(points(tee: base, green: offset(base, north: 300, east: 0), hole: 1, start: 0))

        #expect(CrowdGeometryService.payload(for: round) == nil)
    }

    // MARK: - Lückenhafte Positionen aus dem Verzeichnis

    @Test("Positionen mit Lücken füllen nur die bekannten Löcher, den Rest der eingebaute Platz")
    func partialPositionsMerge() throws {
        let json = """
        {"version":1,"courses":[{"id":"testplatz","kind":"golf","name":"Testplatz","location":"",
        "holes":3,"lat":48.8,"lon":13.3,"parValues":[],"hcpValues":[],"holeLengths":[],
        "facilityNotes":"","welcome":"","teeLatitudes":[],"teeLongitudes":[],
        "flagLatitudes":[],"flagLongitudes":[],
        "teePositions":[[48.81,13.31],null,null],"flagPositions":[null,null,[48.83,13.33]]}]}
        """
        let remote = try #require(try JSONDecoder().decode(RemoteCourseFeed.self, from: Data(json.utf8)).courses.first)

        let alone = remote.bundledEntry()
        #expect(alone.teeLatitudes.count == 3)
        #expect(alone.teeLatitudes[0] == 48.81)
        #expect(alone.teeLatitudes[1].isNaN)

        let eingebaut = BundledCourseEntry(name: "Testplatz", location: "", holes: 3, lat: 48.8, lon: 13.3,
                                           teeLatitudes: [1, 2, 3], teeLongitudes: [4, 5, 6],
                                           flagLatitudes: [7, 8, 9], flagLongitudes: [10, 11, 12])
        let merged = remote.bundledEntry(fallback: eingebaut)
        #expect(merged.teeLatitudes == [48.81, 2, 3])
        #expect(merged.flagLatitudes == [7, 8, 48.83])
    }

    @Test("Ältere Website ohne die neuen Felder liest sich wie bisher")
    func feedWithoutPositionsStillDecodes() throws {
        let json = """
        {"version":1,"courses":[{"id":"x","kind":"golf","name":"X","location":"","holes":1,
        "lat":48.8,"lon":13.3,"parValues":[],"hcpValues":[],"holeLengths":[],"facilityNotes":"",
        "welcome":"","teeLatitudes":[48.81],"teeLongitudes":[13.31],"flagLatitudes":[],"flagLongitudes":[]}]}
        """
        let remote = try #require(try JSONDecoder().decode(RemoteCourseFeed.self, from: Data(json.utf8)).courses.first)
        #expect(remote.bundledEntry().teeLatitudes == [48.81])
    }

    // MARK: - Übernehmen in den eigenen Platz

    private func entry(tee: [CLLocationCoordinate2D?], flag: [CLLocationCoordinate2D?]) -> BundledCourseEntry {
        BundledCourseEntry(name: "Testplatz", location: "", holes: tee.count,
                           lat: base.latitude, lon: base.longitude,
                           teeLatitudes: tee.map { $0?.latitude ?? .nan },
                           teeLongitudes: tee.map { $0?.longitude ?? .nan },
                           flagLatitudes: flag.map { $0?.latitude ?? .nan },
                           flagLongitudes: flag.map { $0?.longitude ?? .nan })
    }

    @Test("Bessere Positionen ersetzen nur, was noch vom Verzeichnis stammt")
    func syncReplacesOnlyCatalogValues() throws {
        let context = ModelContext(try container())
        let falsch = offset(base, north: 400, east: 0)       // geschätzter Altwert
        let eigen = offset(base, north: 50, east: 50)        // vom Spieler gesetzt
        let richtig1 = offset(base, north: 3, east: 0)
        let richtig2 = offset(base, north: 0, east: 3)
        let richtig3 = offset(base, north: -3, east: 0)

        let original = entry(tee: [falsch, falsch, nil], flag: [nil, nil, nil])
        let course = Course(name: "Testplatz", numberOfHoles: 3,
                            teeLatitudes: original.teeLatitudes, teeLongitudes: original.teeLongitudes)
        context.insert(course)
        course.setTeeCoordinate(eigen, forHole: 2)            // Loch 2 hat der Spieler korrigiert

        let crowd = entry(tee: [richtig1, richtig2, richtig3], flag: [nil, nil, richtig1])
        let changed = CourseGeometrySync.update(course, from: crowd, original: original)

        #expect(changed == 3)
        #expect(distance(try #require(course.teeCoordinate(forHole: 1)), richtig1) < 0.5)
        #expect(distance(try #require(course.teeCoordinate(forHole: 2)), eigen) < 0.5)
        #expect(distance(try #require(course.teeCoordinate(forHole: 3)), richtig3) < 0.5)
        #expect(distance(try #require(course.flagCoordinate(forHole: 3)), richtig1) < 0.5)

        // Zweiter Abgleich: das Verzeichnis zieht Loch 1 weiter nach – lokal steht
        // noch dessen letzter Wert, also folgt der Platz.
        let nochBesser = offset(base, north: 1, east: 1)
        let crowd2 = entry(tee: [nochBesser, richtig2, richtig3], flag: [nil, nil, richtig1])
        #expect(CourseGeometrySync.update(course, from: crowd2) == 1)
        #expect(distance(try #require(course.teeCoordinate(forHole: 1)), nochBesser) < 0.5)
        #expect(distance(try #require(course.teeCoordinate(forHole: 2)), eigen) < 0.5)

        // Unverändertes Verzeichnis → nichts zu tun.
        #expect(CourseGeometrySync.update(course, from: crowd2) == 0)
    }
}
