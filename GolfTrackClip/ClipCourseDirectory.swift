import CoreLocation
import Foundation

/// Plätze nachschlagen, die nicht im Programm stecken.
///
/// Eine eigene, kleine Fassung statt `CourseCatalogService`: der bringt den
/// gesamten Platzkatalog mit, und der Clip darf entpackt nur 15 MB groß sein.
/// Hier wird genau ein Platz gesucht, ohne Cache – der Clip lebt ohnehin nur
/// für diese eine Runde.
///
/// Golfplätze stecken **nie** im Programm: 97 Stück mit Par-, HCP- und
/// Längenwerten wären zu viel für den Clip. Sie kommen immer von hier.
enum ClipCourseDirectory {

    private static func feedURL(kind: CourseLinkKind) -> URL {
        URL(string: "https://golftrack.app/api/v1/courses?kind=\(kind.rawValue)")!
    }

    private static func courseURL(id: String) -> URL? {
        guard let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return URL(string: "https://golftrack.app/api/v1/courses/\(encoded)")
    }

    private static func fetch(kind: CourseLinkKind) async -> [Course] {
        var request = URLRequest(url: feedURL(kind: kind))
        request.timeoutInterval = 12

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let feed = try? JSONDecoder().decode(Feed.self, from: data) else { return [] }
        return feed.courses
    }

    static func minigolfCourse(id: String) async -> MinigolfCourseEntry? {
        await fetch(kind: .minigolf).first { $0.id == id }?.minigolfEntry
    }

    static func golfCourse(id: String) async -> GolfLiteCourse? {
        await fetch(kind: .golf).first { $0.id == id }?.golfEntry
    }

    /// Ein Platz, dessen Art nicht im Link stand – der Fall der Kurzform
    /// `play.golftrack.app/p/<kennung>`.
    ///
    /// Holt gezielt **einen** Platz statt der ganzen Liste: die Antwort trägt
    /// die Art selbst, und der Clip lädt nicht 97 Golfplätze, um einen zu
    /// finden.
    static func course(id: String) async -> ClipCourse? {
        guard let url = courseURL(id: id) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let course = try? JSONDecoder().decode(Course.self, from: data),
              let kind = course.kind.flatMap(CourseLinkKind.init(rawValue:))
        else { return nil }

        switch kind {
        case .minigolf: return .minigolf(course.minigolfEntry)
        case .golf:     return .golf(course.golfEntry)
        }
    }

    /// Plätze in der Umgebung für die Startseite – Minigolf und Golf, die
    /// eingebauten Anlagen eingeschlossen, die nächsten zuerst.
    ///
    /// Hier lädt der Clip ausnahmsweise die ganzen Listen: Eine Umkreissuche
    /// bietet die API nicht, und die Startseite erscheint nur, wenn jemand
    /// ohne Link gekommen ist – nicht bei jedem Scan.
    static func nearby(to location: CLLocation,
                       within meters: CLLocationDistance = 50_000,
                       limit: Int = 6) async -> [ClipNearbyCourse] {
        async let minigolf = fetch(kind: .minigolf)
        async let golf = fetch(kind: .golf)

        var found: [ClipNearbyCourse] = []
        var seen = Set<String>()
        func add(_ course: ClipCourse, id: String, name: String, location place: String, lat: Double?, lon: Double?) {
            guard let lat, let lon, lat != 0 || lon != 0, seen.insert(id).inserted else { return }
            let distance = CLLocation(latitude: lat, longitude: lon).distance(from: location)
            guard distance <= meters else { return }
            found.append(ClipNearbyCourse(id: id, name: name, location: place, distance: distance, course: course))
        }

        for course in await minigolf {
            add(.minigolf(course.minigolfEntry), id: course.id, name: course.name, location: course.location, lat: course.lat, lon: course.lon)
        }
        for entry in MinigolfCourses.all {
            add(.minigolf(entry), id: entry.id, name: entry.name, location: entry.location, lat: entry.lat, lon: entry.lon)
        }
        for course in await golf {
            add(.golf(course.golfEntry), id: course.id, name: course.name, location: course.location, lat: course.lat, lon: course.lon)
        }
        return Array(found.sorted { $0.distance < $1.distance }.prefix(limit))
    }

    // MARK: – Format der API

    /// Nur die Felder, die der Clip braucht. Alles andere ignoriert der Decoder.
    private struct Feed: Decodable {
        let courses: [Course]
    }

    private struct Course: Decodable {
        let id: String
        /// Nur die Einzelabfrage liefert die Art mit; in den nach Art
        /// gefilterten Listen steht sie ohnehin fest.
        var kind: String? = nil
        let name: String
        let location: String
        let holes: Int
        let lat: Double?
        let lon: Double?
        let welcome: String
        let facilityNotes: String
        /// Fehlt bei Plätzen, die vor der Einführung freigegeben wurden.
        let facilityHints: [CourseHint]?
        /// Leer, wenn im Verzeichnis nicht für jedes Loch ein Par steht – die
        /// API liefert bewusst lieber nichts als eine halbe Reihe.
        let parValues: [Int]

        var minigolfEntry: MinigolfCourseEntry {
            MinigolfCourseEntry(
                id: id,
                name: name,
                location: location,
                holes: holes,
                lat: lat ?? 0,
                lon: lon ?? 0,
                welcome: welcome.isEmpty
                    ? String(localized: "Willkommen! Ab jetzt zählen wir für dich mit – Bahn für Bahn.")
                    : welcome,
                notes: facilityNotes,
                hints: facilityHints ?? []
            )
        }

        var golfEntry: GolfLiteCourse {
            GolfLiteCourse(
                id: id,
                name: name,
                location: location,
                holes: holes,
                parValues: parValues.count == holes ? parValues : [],
                hints: facilityHints ?? []
            )
        }
    }
}

/// Ein nachgeschlagener Platz, dessen Art erst die Antwort verraten hat.
enum ClipCourse {
    case minigolf(MinigolfCourseEntry)
    case golf(GolfLiteCourse)
}

/// Ein Platz in der Umgebung, wie ihn die Startseite des Clips zeigt.
struct ClipNearbyCourse: Identifiable {
    let id: String
    let name: String
    let location: String
    let distance: CLLocationDistance
    let course: ClipCourse

    var isGolf: Bool {
        if case .golf = course { return true }
        return false
    }
}
