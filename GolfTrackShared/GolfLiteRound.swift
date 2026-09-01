import Foundation

/// Die schlanke Golfrunde – das, was der App Clip kann.
///
/// Bewusst *nicht* das Rundenmodell der App: kein SwiftData, keine
/// Schlagerfassung, keine Karte, kein Positions-Tracking. Nur Schläge je Loch
/// gegen Par. Der Clip darf entpackt 15 MB groß sein, und eine vierstündige
/// Golfrunde mit allem Drum und Dran gehört ohnehin in die volle App.
///
/// Was hier gezählt wird, landet in derselben App-Gruppe wie die
/// Minigolfrunden. Wer nach der Runde installiert, findet sie wieder.

// MARK: - Platz

/// Ein Golfplatz, soweit ihn die Zählkarte braucht.
struct GolfLiteCourse: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let location: String
    let holes: Int
    /// Par je Loch. Leer, wenn der Platz im Verzeichnis keine Werte hat –
    /// dann wird ohne Par gezählt, statt falsche Zahlen zu zeigen.
    let parValues: [Int]

    var hasPar: Bool { parValues.count == holes }

    func par(at hole: Int) -> Int? {
        guard hasPar, parValues.indices.contains(hole) else { return nil }
        return parValues[hole]
    }

    var totalPar: Int? { hasPar ? parValues.reduce(0, +) : nil }
}

// MARK: - Runde

struct SavedGolfLiteRound: Codable {
    var courseID: String
    var courseName: String
    /// Par je Loch, so wie beim Start bekannt – damit die Auswertung auch
    /// stimmt, wenn sich der Eintrag im Verzeichnis später ändert.
    var parValues: [Int]
    var strokes: [Int]
    var currentHole: Int
    var savedAt: Date?

    var playedHoles: Int { strokes.filter { $0 > 0 }.count }
    var totalStrokes: Int { strokes.reduce(0, +) }

    /// Stand gegen Par – nur über die Löcher, die schon gespielt sind.
    var toPar: Int? {
        guard parValues.count == strokes.count else { return nil }
        var diff = 0
        for (index, value) in strokes.enumerated() where value > 0 {
            diff += value - parValues[index]
        }
        return diff
    }
}

// MARK: - Ablage

/// Liegt in derselben App-Gruppe wie die Minigolfrunden, damit die volle App
/// nach dem Installieren drankommt. Keine Übernahme alter Werte nötig – die
/// schlanke Golfrunde ist neu.
enum GolfLiteStore {
    private static let roundKey = "golflite.savedRound"
    private static let historyKey = "golflite.history"

    private static let defaults: UserDefaults =
        UserDefaults(suiteName: MinigolfGameStore.appGroup) ?? .standard

    static func load() -> SavedGolfLiteRound? {
        guard let data = defaults.data(forKey: roundKey) else { return nil }
        return try? JSONDecoder().decode(SavedGolfLiteRound.self, from: data)
    }

    static func save(_ round: SavedGolfLiteRound) {
        guard let data = try? JSONEncoder().encode(round) else { return }
        defaults.set(data, forKey: roundKey)
    }

    static func clear() {
        defaults.removeObject(forKey: roundKey)
    }

    static func loadHistory() -> [SavedGolfLiteRound] {
        guard let data = defaults.data(forKey: historyKey) else { return [] }
        return (try? JSONDecoder().decode([SavedGolfLiteRound].self, from: data)) ?? []
    }

    /// Fertige Runden warten hier darauf, dass die volle App sie übernimmt.
    static func appendToHistory(_ round: SavedGolfLiteRound) {
        var entries = loadHistory()
        entries.insert(round, at: 0)
        if entries.count > 20 { entries = Array(entries.prefix(20)) }
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: historyKey)
        }
    }

    /// Nach der Übernahme in die App aufräumen.
    static func clearHistory() {
        defaults.removeObject(forKey: historyKey)
    }
}
