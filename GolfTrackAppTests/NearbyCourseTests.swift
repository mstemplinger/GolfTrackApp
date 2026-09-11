import CoreLocation
import Foundation
import Testing
@testable import GolfTrackApp

/// Welcher Punkt entscheidet, dass jemand „am Platz" steht.
struct NearbyCourseTests {

    @Test("Der erste Abschlag geht der Adresse vor")
    func firstTeeWins() throws {
        let entry = BundledCourseEntry(
            name: "Testplatz", location: "Teststadt", holes: 18,
            lat: 48.0, lon: 12.0,
            slug: "testplatz", firstTeeLat: 48.5, firstTeeLon: 12.5
        )
        let punkt = try #require(entry.startCoordinate)
        #expect(punkt.latitude == 48.5)
        #expect(punkt.longitude == 12.5)
    }

    @Test("Ohne Abschlag zählt die Adresse")
    func fallsBackToVenue() throws {
        let entry = BundledCourseEntry(name: "Testplatz", location: "", holes: 18, lat: 48.0, lon: 12.0)
        let punkt = try #require(entry.startCoordinate)
        #expect(punkt.latitude == 48.0)
    }

    /// Ein Platz ohne jede Koordinate darf nicht bei 0/0 im Golf von Guinea
    /// landen – dort stünde sonst jeder Nutzer „am Platz".
    @Test("Ganz ohne Koordinaten gibt es keinen Punkt")
    func noCoordinatesNoPoint() {
        let entry = BundledCourseEntry(name: "Testplatz", location: "", holes: 18, lat: 0, lon: 0)
        #expect(entry.startCoordinate == nil)
    }

    @Test("Dasselbe gilt für Minigolfanlagen")
    func minigolfUsesFirstLane() throws {
        let mit = MinigolfCourseEntry(id: "a", name: "A", location: "", holes: 18,
                                      lat: 48.0, lon: 12.0, welcome: "",
                                      firstTeeLat: 49.0, firstTeeLon: 13.0)
        let punkt = try #require(mit.startCoordinate)
        #expect(punkt.latitude == 49.0)

        let ohne = MinigolfCourseEntry(id: "b", name: "B", location: "", holes: 18,
                                       lat: 0, lon: 0, welcome: "")
        #expect(ohne.startCoordinate == nil)
    }

    @Test("Der erste Abschlag kommt aus dem Verzeichnis an")
    func feedCarriesFirstTee() throws {
        let json = """
        {"version":1,"courses":[{"id":"mein-platz","kind":"golf","name":"Mein Platz",
        "location":"","holes":18,"lat":48.0,"lon":12.0,"firstTeeLat":48.111,"firstTeeLon":12.222,
        "parValues":[],"hcpValues":[],"holeLengths":[],"courseRating":72,"slopeRating":113,
        "facilityNotes":"","welcome":"","teeLatitudes":[],"teeLongitudes":[],
        "flagLatitudes":[],"flagLongitudes":[]}]}
        """
        let feed = try JSONDecoder().decode(RemoteCourseFeed.self, from: Data(json.utf8))
        let eintrag = try #require(feed.courses.first)
        let punkt = try #require(eintrag.bundledEntry.startCoordinate)
        #expect(punkt.latitude == 48.111)
    }

    /// Ältere Plätze im Verzeichnis haben das Feld noch nicht – das darf den
    /// ganzen Katalog nicht zu Fall bringen.
    @Test("Ein Platz ohne das neue Feld lädt weiterhin")
    func feedWithoutFirstTee() throws {
        let json = """
        {"version":1,"courses":[{"id":"alt","kind":"golf","name":"Alt","location":"","holes":18,
        "lat":48.0,"lon":12.0,"parValues":[],"hcpValues":[],"holeLengths":[],"courseRating":72,
        "slopeRating":113,"facilityNotes":"","welcome":"","teeLatitudes":[],"teeLongitudes":[],
        "flagLatitudes":[],"flagLongitudes":[]}]}
        """
        let feed = try JSONDecoder().decode(RemoteCourseFeed.self, from: Data(json.utf8))
        let entry = try #require(feed.courses.first).bundledEntry
        #expect(entry.firstTeeLat == nil)
        let punkt = try #require(entry.startCoordinate)
        #expect(punkt.latitude == 48.0)
    }
}
