import Foundation
import CoreLocation

// MARK: - Beitragen

/// Crowd-Positionen: Nach einer Runde mit Laufspur schickt die App die daraus
/// abgeleiteten Abschlag- und Grünpunkte je Loch an golftrack.app – nur mit
/// eigener Einwilligung, getrennt vom lokalen Tracking-Schalter.
///
/// Gesendet werden ausschließlich Punkte (auf ~1 m gerundet) mit einer
/// Sicherheit 0…1 und der gespielten Abschlagfarbe. Keine Laufspur, keine
/// Zeit, kein Name, keine Geräte- oder Runden-ID. Der Server übernimmt einen
/// Punkt erst, wenn mindestens fünf Beiträge übereinstimmen
/// (`web/src/lib/geometryConsensus.ts`).
///
/// Ohne Netz bleibt der Beitrag liegen und geht beim nächsten App-Start raus.
@MainActor
final class CrowdGeometryService {

    static let shared = CrowdGeometryService()

    // MARK: Einwilligung

    static let consentKey = "crowdGeometry.consent"
    static let askedKey = "crowdGeometry.asked"

    /// Vom Spieler erlaubt – Standard: aus.
    static var hasConsent: Bool {
        get { UserDefaults.standard.bool(forKey: consentKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: consentKey)
            UserDefaults.standard.set(true, forKey: askedKey)
        }
    }

    /// Ob die Frage schon einmal gestellt wurde (egal mit welcher Antwort).
    static var wasAsked: Bool { UserDefaults.standard.bool(forKey: askedKey) }

    // MARK: Konfiguration

    static func endpoint(slug: String) -> URL {
        CourseCatalogService.feedURL
            .appendingPathComponent(slug)
            .appendingPathComponent("geometry")
    }

    /// Unter dieser Sicherheit schickt das Gerät einen Punkt gar nicht erst.
    /// Eine einzelne Runde erreicht mit einem Stillstand in der Laufspur
    /// ~0,33, mit getracktem Schlag dazu 1,0; nur der Rand eines Segments
    /// (kein Stillstand erkannt) ~0,13 – der bleibt draußen.
    static let minConfidence = 0.3
    /// So viele Punkte muss die Laufspur mindestens haben – sonst war der
    /// Spieler nicht (lange genug) auf dem Platz.
    static let minTrackPoints = 30
    /// Punkte weiter als das vom Platzmittelpunkt sind Messfehler.
    static let maxDistanceFromCourse: CLLocationDistance = 4000
    /// Liegengebliebene Beiträge werden nach dieser Zeit verworfen.
    static let pendingLifetime: TimeInterval = 14 * 24 * 60 * 60

    private static let pendingKey = "crowdGeometry.pending"

    private var isFlushing = false

    private init() {}

    // MARK: Nutzlast

    struct Payload: Codable, Equatable {
        var version = 1
        var teeColor: String?
        var holes: [HolePayload]
    }

    struct HolePayload: Codable, Equatable {
        let hole: Int
        var tee: Point?
        var green: Point?
    }

    struct Point: Codable, Equatable {
        let lat: Double
        let lon: Double
        let confidence: Double
    }

    struct PendingUpload: Codable {
        let slug: String
        let payload: Payload
        let createdAt: Date
    }

    /// Kennung des Platzes im Verzeichnis – ohne sie gibt es nichts, wohin
    /// der Beitrag gehen könnte (selbst angelegte Plätze).
    static func catalogSlug(for course: Course) -> String? {
        let slug = CourseCatalogService.shared.golfCourse(matching: course)?.slug ?? ""
        return slug.isEmpty ? nil : slug
    }

    /// Ob diese Runde etwas beitragen kann – unabhängig von der Einwilligung.
    /// Nachgetragene Runden haben keine Laufspur mehr (`ScorecardView` löscht
    /// sie) und fallen damit heraus; ihre Schläge lägen am Küchentisch.
    static func canContribute(_ round: Round) -> Bool {
        guard round.isComplete, let course = round.course,
              (round.track?.pointCount ?? 0) >= minTrackPoints,
              catalogSlug(for: course) != nil else { return false }
        return payload(for: round) != nil
    }

    /// Die Punkte dieser einen Runde, gefiltert auf das Belastbare.
    static func payload(for round: Round) -> Payload? {
        guard let course = round.course else { return nil }
        let center: CLLocation? = course.latitude.flatMap { lat in
            course.longitude.map { CLLocation(latitude: lat, longitude: $0) }
        }
        func point(_ coordinate: CLLocationCoordinate2D?, _ confidence: Double) -> Point? {
            guard let coordinate, confidence >= minConfidence else { return nil }
            if let center,
               CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                .distance(from: center) > maxDistanceFromCourse { return nil }
            return Point(lat: rounded(coordinate.latitude),
                         lon: rounded(coordinate.longitude),
                         confidence: (confidence * 100).rounded() / 100)
        }

        let holes: [HolePayload] = CourseGeometryInference.suggestions(for: round).compactMap { s in
            // Unplausible Längen (Spieler hat ein Loch ausgelassen, falsche
            // Lochnummer) schicken wir gar nicht erst.
            guard s.isPlausible else { return nil }
            let entry = HolePayload(hole: s.holeNumber,
                                    tee: point(s.tee, s.teeConfidence),
                                    green: point(s.green, s.greenConfidence))
            return entry.tee == nil && entry.green == nil ? nil : entry
        }
        guard !holes.isEmpty else { return nil }
        return Payload(teeColor: round.teeColor?.rawValue, holes: holes)
    }

    /// Auf 5 Nachkommastellen (≈ 1 m).
    private static func rounded(_ value: Double) -> Double {
        (value * 100_000).rounded() / 100_000
    }

    // MARK: Senden

    /// Nach dem Abschluss einer Runde: Beitrag vormerken und senden, wenn
    /// erlaubt. Tut sonst nichts.
    func contribute(_ round: Round) {
        guard Self.hasConsent, Self.canContribute(round),
              let course = round.course,
              let slug = Self.catalogSlug(for: course),
              let payload = Self.payload(for: round) else { return }
        var pending = loadPending()
        pending.append(PendingUpload(slug: slug, payload: payload, createdAt: .now))
        savePending(pending)
        Task { await flushPending() }
    }

    /// Schickt liegengebliebene Beiträge. Wird nach dem Abschluss einer Runde
    /// und beim App-Start aufgerufen.
    func flushPending() async {
        guard !isFlushing else { return }
        isFlushing = true
        defer { isFlushing = false }

        // Einwilligung zurückgezogen → nichts mehr senden, auch nichts Altes.
        guard Self.hasConsent else {
            savePending([])
            return
        }

        var remaining: [PendingUpload] = []
        for upload in loadPending() where upload.createdAt.timeIntervalSinceNow > -Self.pendingLifetime {
            if await !send(upload) { remaining.append(upload) }
        }
        savePending(remaining)
    }

    /// `true`, wenn der Beitrag erledigt ist – angenommen oder endgültig
    /// abgelehnt. `false` heißt: später noch einmal versuchen.
    private func send(_ upload: PendingUpload) async -> Bool {
        var request = URLRequest(url: Self.endpoint(slug: upload.slug))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        guard let body = try? JSONEncoder().encode(upload.payload) else { return true }
        request.httpBody = body
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            // 429 (zu viele) und 5xx: später erneut. Alles andere ist erledigt –
            // ein 4xx wird auch beim zweiten Mal nicht besser.
            return !(status == 429 || status >= 500 || status == 0)
        } catch {
            return false
        }
    }

    private func loadPending() -> [PendingUpload] {
        guard let data = UserDefaults.standard.data(forKey: Self.pendingKey) else { return [] }
        return (try? JSONDecoder().decode([PendingUpload].self, from: data)) ?? []
    }

    private func savePending(_ uploads: [PendingUpload]) {
        if uploads.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.pendingKey)
        } else if let data = try? JSONEncoder().encode(Array(uploads.suffix(20))) {
            UserDefaults.standard.set(data, forKey: Self.pendingKey)
        }
    }
}

// MARK: - Übernehmen

/// Lochpositionen, wie das Verzeichnis sie zuletzt geliefert hat – je Loch
/// `[lat, lon]` oder `nil`.
struct CatalogGeometrySnapshot: Codable, Equatable {
    var tees: [[Double]?] = []
    var flags: [[Double]?] = []
    /// Abschläge je Farbe (`TeeColor.rawValue`).
    var colorTees: [String: [[Double]?]] = [:]
}

/// Holt bessere Positionen aus dem Verzeichnis in einen Platz, der schon in
/// der eigenen Datenbank liegt. Der wird beim ersten Spielen einmal kopiert
/// (`Course.stored(for:in:)`) und bekäme spätere Korrekturen sonst nie mit.
///
/// Regel je Loch: Eine lokale Position wird nur ersetzt, wenn sie fehlt oder
/// noch genau dem entspricht, was das Verzeichnis früher geliefert hat. Was
/// der Spieler selbst gesetzt oder aus seinen Runden übernommen hat, bleibt.
enum CourseGeometrySync {

    /// Abstand, unter dem zwei Werte als „derselbe“ gelten (Rundung).
    static let samePointMeters: CLLocationDistance = 1.5

    /// Gleicht einen Platz mit seinem Eintrag im Verzeichnis ab – Bezug für
    /// den allerersten Abgleich ist die eingebaute Fassung des Platzes.
    @MainActor @discardableResult
    static func updateFromCatalog(_ course: Course) -> Int {
        guard let entry = CourseCatalogService.shared.golfCourse(matching: course) else { return 0 }
        let name = CourseCatalogService.normalizedName(course.name)
        let original = BundledCourses.all.first { CourseCatalogService.normalizedName($0.name) == name }
        return update(course, from: entry, original: original)
    }

    /// Gibt zurück, wie viele Positionen sich geändert haben.
    @discardableResult
    static func update(_ course: Course, from entry: BundledCourseEntry,
                       original: BundledCourseEntry? = nil) -> Int {
        let holes = course.numberOfHoles
        let catalog = snapshot(of: entry, holes: holes)
        let previous: CatalogGeometrySnapshot = {
            if !course.catalogGeometryData.isEmpty,
               let decoded = try? JSONDecoder().decode(CatalogGeometrySnapshot.self, from: course.catalogGeometryData) {
                return decoded
            }
            // Noch nie abgeglichen: Bezug ist, was beim Anlegen kopiert wurde –
            // die eingebaute Fassung des Platzes.
            return original.map { snapshot(of: $0, holes: holes) } ?? CatalogGeometrySnapshot()
        }()

        var changed = 0
        for hole in 1...max(1, holes) {
            let i = hole - 1
            if let next = coordinate(catalog.tees, i),
               replaceable(local: course.teeCoordinate(forHole: hole), reference: coordinate(previous.tees, i), next: next) {
                course.setTeeCoordinate(next, forHole: hole)
                changed += 1
            }
            if let next = coordinate(catalog.flags, i),
               replaceable(local: course.flagCoordinate(forHole: hole), reference: coordinate(previous.flags, i), next: next) {
                course.setFlagCoordinate(next, forHole: hole)
                changed += 1
            }
            for (raw, values) in catalog.colorTees {
                guard let color = TeeColor(rawValue: raw), let next = coordinate(values, i) else { continue }
                let local = course.tee(color)?.coordinate(forHole: hole)
                if replaceable(local: local, reference: coordinate(previous.colorTees[raw] ?? [], i), next: next) {
                    var all = course.tees
                    if let index = all.firstIndex(where: { $0.color == color }) {
                        all[index].setCoordinate(next, forHole: hole, holeCount: holes)
                    } else {
                        var tee = CourseTee(color: color)
                        tee.setCoordinate(next, forHole: hole, holeCount: holes)
                        all.append(tee)
                    }
                    course.tees = all
                    changed += 1
                }
            }
        }

        if let data = try? JSONEncoder().encode(catalog), data != course.catalogGeometryData {
            course.catalogGeometryData = data
        }
        return changed
    }

    static func snapshot(of entry: BundledCourseEntry, holes: Int) -> CatalogGeometrySnapshot {
        func pairs(_ lat: [Double], _ lon: [Double]) -> [[Double]?] {
            (0..<holes).map { i in
                guard i < lat.count, i < lon.count, lat[i].isFinite, lon[i].isFinite,
                      !(lat[i] == 0 && lon[i] == 0) else { return nil }
                return [lat[i], lon[i]]
            }
        }
        var colors: [String: [[Double]?]] = [:]
        for tee in entry.tees {
            let values = pairs(tee.teeLatitudes, tee.teeLongitudes)
            if values.contains(where: { $0 != nil }) { colors[tee.color.rawValue] = values }
        }
        return CatalogGeometrySnapshot(tees: pairs(entry.teeLatitudes, entry.teeLongitudes),
                                       flags: pairs(entry.flagLatitudes, entry.flagLongitudes),
                                       colorTees: colors)
    }

    private static func coordinate(_ values: [[Double]?], _ index: Int) -> CLLocationCoordinate2D? {
        guard index >= 0, index < values.count, let pair = values[index], pair.count == 2 else { return nil }
        return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
    }

    private static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    /// Fehlt lokal etwas, oder steht dort noch der alte Wert des Verzeichnisses?
    static func replaceable(local: CLLocationCoordinate2D?, reference: CLLocationCoordinate2D?,
                            next: CLLocationCoordinate2D) -> Bool {
        guard let local else { return true }
        if distance(local, next) < samePointMeters { return false }
        guard let reference else { return false }
        return distance(local, reference) < samePointMeters
    }
}
