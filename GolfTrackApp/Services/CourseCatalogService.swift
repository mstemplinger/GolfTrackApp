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
    /// eingebaute Eintrag – der ist geprüft und enthält oft mehr Details.
    var allGolfCourses: [BundledCourseEntry] {
        let known = Set(BundledCourses.all.map { $0.name.lowercased() })
        return BundledCourses.all + remoteGolfCourses.filter { !known.contains($0.name.lowercased()) }
    }

    var allMinigolfCourses: [MinigolfCourseEntry] {
        let known = Set(MinigolfCourses.all.map { $0.id })
        return MinigolfCourses.all + remoteMinigolfCourses.filter { !known.contains($0.id) }
    }

    func minigolfCourse(id: String) -> MinigolfCourseEntry? {
        MinigolfCourses.course(id: id) ?? remoteMinigolfCourses.first { $0.id == id }
    }

    /// Anlage hinter einem QR-Code oder Universal Link – erst die eingebauten,
    /// dann die von der Website nachgeladenen.
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
        remoteGolfCourses = feed.courses.filter { $0.kind == "golf" }.map(\.bundledEntry)
        remoteMinigolfCourses = feed.courses.filter { $0.kind == "minigolf" }.map(\.minigolfEntry)
        lastUpdated = Date()
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
        remoteGolfCourses = feed.courses.filter { $0.kind == "golf" }.map(\.bundledEntry)
        remoteMinigolfCourses = feed.courses.filter { $0.kind == "minigolf" }.map(\.minigolfEntry)
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
    let parValues: [Int]
    let hcpValues: [Int]
    let holeLengths: [Int]
    let courseRating: Double?
    let slopeRating: Int?
    let facilityNotes: String
    let welcome: String
    let teeLatitudes: [Double]
    let teeLongitudes: [Double]
    let flagLatitudes: [Double]
    let flagLongitudes: [Double]

    /// Als Golfplatz für die Platzauswahl.
    var bundledEntry: BundledCourseEntry {
        BundledCourseEntry(
            name: name,
            location: location,
            holes: holes,
            lat: lat ?? 0,
            lon: lon ?? 0,
            parValues: parValues,
            hcpValues: hcpValues,
            holeLengths: holeLengths,
            courseRating: courseRating ?? 72.0,
            slopeRating: slopeRating ?? 113,
            facilityNotes: facilityNotes,
            teeLatitudes: teeLatitudes,
            teeLongitudes: teeLongitudes,
            flagLatitudes: flagLatitudes,
            flagLongitudes: flagLongitudes
        )
    }

    /// Als Minigolfanlage für QR-Start und Anlagenliste.
    var minigolfEntry: MinigolfCourseEntry {
        MinigolfCourseEntry(
            id: id,
            name: name,
            location: location,
            holes: holes,
            lat: lat ?? 0,
            lon: lon ?? 0,
            welcome: welcome.isEmpty
                ? "Willkommen! Ab jetzt zählen wir für dich mit – Bahn für Bahn."
                : welcome,
            notes: facilityNotes
        )
    }
}
