import Foundation

/// Anlagen nachschlagen, die nicht im Programm stecken.
///
/// Eine eigene, kleine Fassung statt `CourseCatalogService`: der zieht die
/// Golfplatz-Datenbank mit, und der Clip darf entpackt nur 15 MB groß sein.
/// Hier wird genau eine Anlage gesucht, ohne Cache – der Clip lebt ohnehin nur
/// für diese eine Runde.
enum ClipCourseDirectory {

    private static let feedURL = URL(string: "https://golftrack.app/api/v1/courses?kind=minigolf")!

    static func course(id: String) async -> MinigolfCourseEntry? {
        var request = URLRequest(url: feedURL)
        request.timeoutInterval = 12

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let feed = try? JSONDecoder().decode(Feed.self, from: data) else { return nil }

        return feed.courses.first { $0.id == id }?.entry
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

        var entry: MinigolfCourseEntry {
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
}
