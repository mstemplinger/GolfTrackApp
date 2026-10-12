import Foundation
import Observation

/// Plätze, die von golftrack.app nachgeladen werden.
///
/// Die App bringt weiterhin `BundledCourses` und `MinigolfCourses` mit – die
/// bleiben ohne Netz verfügbar und sind die Grundlage für den App Clip. Dieser
/// Dienst legt die freigegebenen Anlagen der Website obendrauf: einmal geladen,
/// liegen sie im Cache und stehen auch offline zur Verfügung.
@MainActor
@Observable
final class CourseCatalogService {

    static let shared = CourseCatalogService()

    /// Basisadresse der Platzdaten-API.
    static let feedURL = URL(string: "https://golftrack.app/api/v1/courses")!

    /// Frühestens nach dieser Zeit wird erneut geladen.
    private static let refreshInterval: TimeInterval = 6 * 60 * 60

    private(set) var remoteGolfCourses: [BundledCourseEntry] = []
    private(set) var remoteMinigolfCourses: [MinigolfCourseEntry] = []
    private(set) var lastUpdated: Date?
    private(set) var isLoading = false
    private(set) var lastError: String?

    private var loadedFromDisk = false

    private init() {}

    // MARK: – Zusammengeführte Listen

    /// Eingebaute und nachgeladene Golfplätze. Bei gleichem Namen gewinnt der
    /// Eintrag der Website: Den pflegt der Betreiber, er ist damit aktueller
    /// als die eingebaute Fassung. Was dort leer bleibt (Scorecard,
    /// Koordinaten), füllt beim Zusammenführen weiterhin der eingebaute Platz –
    /// siehe `RemoteCourse.bundledEntry(fallback:)`.
    var allGolfCourses: [BundledCourseEntry] {
        let ersetzt = Set(remoteGolfCourses.map { $0.name.lowercased() })
        return BundledCourses.all.filter { !ersetzt.contains($0.name.lowercased()) } + remoteGolfCourses
    }

    /// Dasselbe für die Minigolfanlagen, hier über die Kennung.
    var allMinigolfCourses: [MinigolfCourseEntry] {
        let ersetzt = Set(remoteMinigolfCourses.map { $0.id })
        return MinigolfCourses.all.filter { !ersetzt.contains($0.id) } + remoteMinigolfCourses
    }

    func minigolfCourse(id: String) -> MinigolfCourseEntry? {
        remoteMinigolfCourses.first { $0.id == id } ?? MinigolfCourses.course(id: id)
    }

    /// Anlage hinter einem QR-Code oder Universal Link – erst die eingebauten,
    /// dann die von der Website nachgeladenen.
    /// Golfplatz zu einer Kennung aus dem QR-Code.
    ///
    /// Nur das Verzeichnis kennt Kennungen – die eingebauten Plätze tragen
    /// keine. Steht der Platz noch nicht im Zwischenspeicher, lädt der
    /// Aufrufer einmal nach und fragt erneut.
    func golfCourse(slug: String) -> BundledCourseEntry? {
        remoteGolfCourses.first { $0.slug == slug }
    }

    func course(fromDeepLink url: URL) -> MinigolfCourseEntry? {
        guard let id = MinigolfDeepLink.courseID(from: url) else { return nil }
        return minigolfCourse(id: id)
    }

    // MARK: – Laden

    /// Lädt den Cache und stößt bei Bedarf eine Aktualisierung an.
    /// Gedacht für `.task { }` beim Öffnen der Platzauswahl.
    func refreshIfNeeded() async {
        if !loadedFromDisk { loadCache() }
        guard shouldRefresh else { return }
        await refresh()
    }

    private var shouldRefresh: Bool {
        guard let lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > Self.refreshInterval
    }

    /// Holt die Liste unabhängig vom Alter des Caches.
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        var request = URLRequest(url: Self.feedURL)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadRevalidatingCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                lastError = "Serverantwort ungültig"
                return
            }
            let feed = try JSONDecoder().decode(RemoteCourseFeed.self, from: data)
            apply(feed)
            saveCache(data)
            lastError = nil
        } catch {
            // Ohne Netz bleibt der Cache stehen – das ist kein Fehlerfall für die Oberfläche.
            lastError = error.localizedDescription
        }
    }

    private func apply(_ feed: RemoteCourseFeed) {
        adopt(feed)
        lastUpdated = Date()
    }

    /// Übernimmt den Feed in die beiden Listen – jeder Platz mit dem
    /// gleichnamigen eingebauten Eintrag als Rückfallebene.
    private func adopt(_ feed: RemoteCourseFeed) {
        remoteGolfCourses = feed.courses
            .filter { $0.kind == "golf" }
            .map { remote in
                remote.bundledEntry(fallback: BundledCourses.all.first {
                    $0.name.lowercased() == remote.name.lowercased()
                })
            }
        remoteMinigolfCourses = feed.courses
            .filter { $0.kind == "minigolf" }
            .map { remote in
                remote.minigolfEntry(fallback: MinigolfCourses.course(id: remote.id))
            }
    }

    // MARK: – Cache auf der Platte

    private var cacheURL: URL? {
        guard let directory = FileManager.default.urls(for: .applicationSupportDirectory,
                                                       in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("remote-courses.json")
    }

    private func loadCache() {
        loadedFromDisk = true
        guard let cacheURL, let data = try? Data(contentsOf: cacheURL),
              let feed = try? JSONDecoder().decode(RemoteCourseFeed.self, from: data) else { return }
        adopt(feed)
        lastUpdated = (try? cacheURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }

    private func saveCache(_ data: Data) {
        guard let cacheURL else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}

// MARK: – Format der API

/// Antwort von `/api/v1/courses`. Die Feldnamen entsprechen dem, was die
/// Website ausliefert; unbekannte Felder werden ignoriert.
struct RemoteCourseFeed: Decodable {
    let version: Int
    let generatedAt: String?
    let courses: [RemoteCourse]
}

struct RemoteCourse: Decodable {
    let id: String
    let kind: String
    let name: String
    let location: String
    let holes: Int
    let lat: Double?
    let lon: Double?
    /// Erster Abschlag – fehlt bei Plätzen, die vor der Einführung
    /// freigegeben wurden.
    let firstTeeLat: Double?
    let firstTeeLon: Double?
    let parValues: [Int]
    let hcpValues: [Int]
    let holeLengths: [Int]
    let courseRating: Double?
    let slopeRating: Int?
    let facilityNotes: String
    /// Fehlt bei Plätzen, die vor der Einführung freigegeben wurden.
    let facilityHints: [CourseHint]?
    let welcome: String
    let teeLatitudes: [Double]
    let teeLongitudes: [Double]
    let flagLatitudes: [Double]
    let flagLongitudes: [Double]

    /// Als Golfplatz für die Platzauswahl.
    ///
    /// `fallback` ist der gleichnamige eingebaute Platz, falls es ihn gibt.
    /// Der Eintrag der Website gewinnt – nur wo er nichts liefert (die API
    /// schickt lieber gar keine Scorecard als eine halbe), bleibt der geprüfte
    /// eingebaute Wert stehen.
    func bundledEntry(fallback: BundledCourseEntry? = nil) -> BundledCourseEntry {
        BundledCourseEntry(
            name: name,
            location: location.isEmpty ? (fallback?.location ?? "") : location,
            holes: holes > 0 ? holes : (fallback?.holes ?? holes),
            lat: lat ?? fallback?.lat ?? 0,
            lon: lon ?? fallback?.lon ?? 0,
            parValues: parValues.isEmpty ? (fallback?.parValues ?? []) : parValues,
            hcpValues: hcpValues.isEmpty ? (fallback?.hcpValues ?? []) : hcpValues,
            holeLengths: holeLengths.isEmpty ? (fallback?.holeLengths ?? []) : holeLengths,
            courseRating: courseRating ?? fallback?.courseRating ?? 72.0,
            slopeRating: slopeRating ?? fallback?.slopeRating ?? 113,
            facilityNotes: facilityNotes.isEmpty ? (fallback?.facilityNotes ?? "") : facilityNotes,
            hints: facilityHints ?? fallback?.hints ?? [],
            teeLatitudes: teeLatitudes.isEmpty ? (fallback?.teeLatitudes ?? []) : teeLatitudes,
            teeLongitudes: teeLongitudes.isEmpty ? (fallback?.teeLongitudes ?? []) : teeLongitudes,
            flagLatitudes: flagLatitudes.isEmpty ? (fallback?.flagLatitudes ?? []) : flagLatitudes,
            flagLongitudes: flagLongitudes.isEmpty ? (fallback?.flagLongitudes ?? []) : flagLongitudes,
            slug: id,
            firstTeeLat: firstTeeLat ?? fallback?.firstTeeLat,
            firstTeeLon: firstTeeLon ?? fallback?.firstTeeLon
        )
    }

    /// Als Minigolfanlage für QR-Start und Anlagenliste – wie oben mit dem
    /// eingebauten Eintrag als Rückfallebene.
    func minigolfEntry(fallback: MinigolfCourseEntry? = nil) -> MinigolfCourseEntry {
        let gruss = welcome.isEmpty ? (fallback?.welcome ?? "") : welcome
        return MinigolfCourseEntry(
            id: id,
            name: name,
            location: location.isEmpty ? (fallback?.location ?? "") : location,
            holes: holes > 0 ? holes : (fallback?.holes ?? holes),
            lat: lat ?? fallback?.lat ?? 0,
            lon: lon ?? fallback?.lon ?? 0,
            welcome: gruss.isEmpty
                ? "Willkommen! Ab jetzt zählen wir für dich mit – Bahn für Bahn."
                : gruss,
            notes: facilityNotes.isEmpty ? (fallback?.notes ?? "") : facilityNotes,
            hints: facilityHints ?? fallback?.hints ?? [],
            firstTeeLat: firstTeeLat ?? fallback?.firstTeeLat,
            firstTeeLon: firstTeeLon ?? fallback?.firstTeeLon
        )
    }
}
