import Foundation
import Testing
@testable import GolfTrackApp

/// Was passiert, wenn ein Platz sowohl eingebaut ist als auch im Verzeichnis
/// der Website steht.
///
/// Gepflegt wird online – trägt der Betreiber dort Hinweise nach, müssen sie in
/// der App ankommen. Umgekehrt darf die Zusammenführung nicht die eingebaute
/// Scorecard verlieren, die das Verzeichnis oft gar nicht kennt.
struct CourseCatalogMergeTests {

    private func feed(_ json: String) throws -> RemoteCourse {
        let feed = try JSONDecoder().decode(RemoteCourseFeed.self, from: Data(json.utf8))
        return try #require(feed.courses.first)
    }

    // MARK: – Minigolf

    private let minigolfJSON = """
    {"version":1,"courses":[{"id":"sankt-englmar","kind":"minigolf","name":"Minigolf Sankt Englmar",
    "location":"Sankt Englmar","holes":12,"lat":48.9906,"lon":12.8114,
    "parValues":[],"hcpValues":[],"holeLengths":[],"facilityNotes":"",
    "facilityHints":[{"kind":"toilet","text":"Beim Eingang"}],
    "welcome":"","teeLatitudes":[],"teeLongitudes":[],"flagLatitudes":[],"flagLongitudes":[]}]}
    """

    @Test("Hinweise von der Website gewinnen gegen den eingebauten Platz")
    func hintsFromDirectoryWin() throws {
        let eingebaut = MinigolfCourseEntry(
            id: "sankt-englmar", name: "Minigolf Sankt Englmar", location: "Sankt Englmar",
            holes: 18, lat: 48.9906, lon: 12.8114,
            welcome: "Servus!", notes: "Schläger gibt es vor Ort"
        )
        let eintrag = try feed(minigolfJSON).minigolfEntry(fallback: eingebaut)

        #expect(eintrag.hints.map(\.kind) == [.toilet])
        // Auch die Bahnenzahl kommt jetzt von der Website – sonst zählt die
        // Runde sechs Bahnen mit, die es nicht gibt.
        #expect(eintrag.holes == 12)
    }

    @Test("Leere Felder im Verzeichnis behalten den eingebauten Wert")
    func emptyFieldsFallBack() throws {
        let eingebaut = MinigolfCourseEntry(
            id: "sankt-englmar", name: "Minigolf Sankt Englmar", location: "Sankt Englmar",
            holes: 18, lat: 48.9906, lon: 12.8114,
            welcome: "Servus!", notes: "Schläger gibt es vor Ort"
        )
        let eintrag = try feed(minigolfJSON).minigolfEntry(fallback: eingebaut)

        #expect(eintrag.welcome == "Servus!")
        #expect(eintrag.notes == "Schläger gibt es vor Ort")
    }

    /// Der Betreiber löscht alle Hinweise wieder: Dann soll auch keiner mehr
    /// erscheinen. `[]` ist eine Aussage, `nil` (Feld fehlt) dagegen nicht.
    @Test("Gelöschte Hinweise verschwinden, ein fehlendes Feld ändert nichts")
    func emptyListDiffersFromMissingField() throws {
        let eingebaut = MinigolfCourseEntry(
            id: "alt", name: "Alt", location: "", holes: 18, lat: 1, lon: 1,
            welcome: "", hints: [CourseHint(kind: .info, text: "Eingebaut")]
        )
        let geleert = """
        {"version":1,"courses":[{"id":"alt","kind":"minigolf","name":"Alt","location":"","holes":18,
        "lat":1,"lon":1,"parValues":[],"hcpValues":[],"holeLengths":[],"facilityNotes":"",
        "facilityHints":[],"welcome":"","teeLatitudes":[],"teeLongitudes":[],
        "flagLatitudes":[],"flagLongitudes":[]}]}
        """
        #expect(try feed(geleert).minigolfEntry(fallback: eingebaut).hints.isEmpty)

        let ohneFeld = """
        {"version":1,"courses":[{"id":"alt","kind":"minigolf","name":"Alt","location":"","holes":18,
        "lat":1,"lon":1,"parValues":[],"hcpValues":[],"holeLengths":[],"facilityNotes":"",
        "welcome":"","teeLatitudes":[],"teeLongitudes":[],"flagLatitudes":[],"flagLongitudes":[]}]}
        """
        #expect(try feed(ohneFeld).minigolfEntry(fallback: eingebaut).hints.count == 1)
    }

    // MARK: – Golf

    /// Das Verzeichnis liefert lieber gar keine Scorecard als eine halbe. Für
    /// die eingebauten Plätze wäre das ein Rückschritt – deshalb bleibt sie.
    @Test("Die eingebaute Scorecard überlebt die Hinweise von der Website")
    func scorecardSurvives() throws {
        let eingebaut = BundledCourseEntry(
            name: "Mein Platz", location: "Teststadt", holes: 18, lat: 48, lon: 12,
            parValues: Array(repeating: 4, count: 18),
            hcpValues: Array(1...18),
            holeLengths: Array(repeating: 300, count: 18),
            courseRating: 70.4, slopeRating: 135,
            facilityNotes: "Platzregeln am Aushang"
        )
        let json = """
        {"version":1,"courses":[{"id":"mein-platz","kind":"golf","name":"Mein Platz",
        "location":"Teststadt","holes":18,"lat":48.0,"lon":12.0,
        "parValues":[],"hcpValues":[],"holeLengths":[],"courseRating":null,"slopeRating":null,
        "facilityNotes":"","facilityHints":[{"kind":"shelter","text":"Hütte an Bahn 7"}],
        "welcome":"","teeLatitudes":[],"teeLongitudes":[],"flagLatitudes":[],"flagLongitudes":[]}]}
        """
        let eintrag = try feed(json).bundledEntry(fallback: eingebaut)

        #expect(eintrag.hints.map(\.kind) == [.shelter])
        #expect(eintrag.parValues.count == 18)
        #expect(eintrag.courseRating == 70.4)
        #expect(eintrag.slopeRating == 135)
        #expect(eintrag.facilityNotes == "Platzregeln am Aushang")
        // Die Kennung trägt nur das Verzeichnis – ohne sie gäbe es weder
        // Umkreis-Werbung noch QR-Start.
        #expect(eintrag.slug == "mein-platz")
    }

    @Test("Ohne eingebauten Platz bleiben die Standardwerte")
    func withoutFallback() throws {
        let json = """
        {"version":1,"courses":[{"id":"neu","kind":"golf","name":"Neu","location":"","holes":9,
        "lat":48.0,"lon":12.0,"parValues":[],"hcpValues":[],"holeLengths":[],
        "courseRating":null,"slopeRating":null,"facilityNotes":"","welcome":"",
        "teeLatitudes":[],"teeLongitudes":[],"flagLatitudes":[],"flagLongitudes":[]}]}
        """
        let eintrag = try feed(json).bundledEntry()
        #expect(eintrag.courseRating == 72.0)
        #expect(eintrag.slopeRating == 113)
        #expect(eintrag.hints.isEmpty)
    }
}
