import Foundation
import Testing
@testable import GolfTrackApp

/// Der Weg vom QR-Code am Abschlag bis zum Platz in der App.
struct GolfDeepLinkTests {

    @Test("Der QR-Code am Golfplatz wird als Golf-Link erkannt")
    func webLinkIsGolf() throws {
        let url = URL(string: "https://golftrack.app/golf/bella-vista-golfpark-bad-birnbach")!
        let link = try #require(CourseDeepLink.link(from: url))
        #expect(link.kind == .golf)
        #expect(link.slug == "bella-vista-golfpark-bad-birnbach")
    }

    @Test("Auch das eigene Schema führt zum selben Platz")
    func appLinkIsGolf() throws {
        let link = try #require(CourseDeepLink.link(from: URL(string: "golftrack://golf?platz=bayerwald")!))
        #expect(link.kind == .golf)
        #expect(link.slug == "bayerwald")
    }

    @Test("golftrack://home ist kein Platz")
    func homeIsNoCourse() {
        #expect(CourseDeepLink.link(from: URL(string: "golftrack://home")!) == nil)
    }

    /// Ohne diese Zuordnung findet die App den gescannten Platz nicht: die
    /// Kennung steckt im QR-Code, im Verzeichnis heißt sie `id`.
    @Test("Die Kennung aus dem Verzeichnis landet im Platz")
    func feedCarriesSlug() throws {
        let json = """
        {"version":1,"courses":[{"id":"mein-platz","kind":"golf","name":"Mein Platz",
        "location":"Teststadt","holes":18,"lat":48.0,"lon":12.0,
        "parValues":[4,3,5,4,4,3,4,5,4,4,4,3,5,4,3,4,5,4],"hcpValues":[],"holeLengths":[],
        "courseRating":71.4,"slopeRating":130,"facilityNotes":"","welcome":"",
        "teeLatitudes":[],"teeLongitudes":[],"flagLatitudes":[],"flagLongitudes":[]}]}
        """
        let feed = try JSONDecoder().decode(RemoteCourseFeed.self, from: Data(json.utf8))
        let entry = try #require(feed.courses.first).bundledEntry
        #expect(entry.slug == "mein-platz")
        #expect(entry.name == "Mein Platz")
        #expect(entry.parValues.reduce(0, +) == 72)
    }
}
