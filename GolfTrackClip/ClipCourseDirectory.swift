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

    // MARK: – Format der API

    /// Nur die Felder, die der Clip braucht. Alles andere ignoriert der Decoder.
    private struct Feed: Decodable {
        let courses: [Course]
    }

    private struct Course: Decodable {
        let id: String
        let name: String
        let location: String
        let holes: Int
        let lat: Double?
        let lon: Double?
        let welcome: String
        let facilityNotes: String
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
                    ? "Willkommen! Ab jetzt zählen wir für dich mit – Bahn für Bahn."
                    : welcome,
                notes: facilityNotes
            )
        }

        var golfEntry: GolfLiteCourse {
            GolfLiteCourse(
                id: id,
                name: name,
                location: location,
                holes: holes,
                parValues: parValues.count == holes ? parValues : []
            )
        }
    }
}
