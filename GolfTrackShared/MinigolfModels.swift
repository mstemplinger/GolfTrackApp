import Foundation

/// Zustand einer Minigolfrunde und ihre Ablage.
///
/// Liegt getrennt von den Ansichten, weil der App Clip diese Typen braucht,
/// die Anlagenliste in `MinigolfView` aber nicht mitkommen soll.

// MARK: - Config

struct MinigolfConfig: Identifiable, Hashable {
    let id = UUID()
    let playerNames: [String]
    let numberOfHoles: Int
    var initialScores: [[Int]]? = nil
    var initialHole: Int = 0
    /// Anlage, an der gespielt wird (per QR-Code gestartet) – sonst `nil`.
    var courseName: String? = nil
    /// Kennung derselben Anlage. Der Name steht auf der Karte, die Kennung
    /// entscheidet, welche Werbung im freien Feld darunter läuft.
    var courseID: String? = nil
    /// Aktive Nebenwertungen (Serie, Asse, …)
    var challenges: [MinigolfChallenge] = []
}

// MARK: - Persistence

struct SavedMinigolfGame: Codable {
    var playerNames: [String]
    var numberOfHoles: Int
    var scores: [[Int]]
    var currentHole: Int
    var savedAt: Date? = nil
    var courseName: String? = nil
    var courseID: String? = nil
    /// Optional, damit ältere gespeicherte Spiele weiter geladen werden können.
    var challenges: [MinigolfChallenge]? = nil
}

struct MinigolfHistoryEntry: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var playerNames: [String]
    var numberOfHoles: Int
    var scores: [[Int]]
    var courseName: String? = nil
    var challenges: [MinigolfChallenge]? = nil
}

enum MinigolfGameStore {
    private static let gameKey = "minigolf.savedGame"
    private static let namesKey = "minigolf.savedPlayerNames"
    private static let historyKey = "minigolf.history"
    private static let challengesKey = "minigolf.challenges"

    static func load() -> SavedMinigolfGame? {
        guard let data = UserDefaults.standard.data(forKey: gameKey) else { return nil }
        return try? JSONDecoder().decode(SavedMinigolfGame.self, from: data)
    }

    static func save(_ game: SavedMinigolfGame) {
        if let data = try? JSONEncoder().encode(game) {
            UserDefaults.standard.set(data, forKey: gameKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: gameKey)
    }

    static func loadNames() -> [String]? {
        UserDefaults.standard.stringArray(forKey: namesKey)
    }

    static func saveNames(_ names: [String]) {
        UserDefaults.standard.set(names, forKey: namesKey)
    }

    /// Zuletzt gewählte Wettkämpfe – Vorschlag für die nächste Runde.
    static func loadChallenges() -> [MinigolfChallenge] {
        (UserDefaults.standard.stringArray(forKey: challengesKey) ?? [])
            .compactMap(MinigolfChallenge.init(rawValue:))
    }

    static func saveChallenges(_ challenges: [MinigolfChallenge]) {
        UserDefaults.standard.set(challenges.map(\.rawValue), forKey: challengesKey)
    }

    static func loadHistory() -> [MinigolfHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        return (try? JSONDecoder().decode([MinigolfHistoryEntry].self, from: data)) ?? []
    }

    static func saveHistory(_ entries: [MinigolfHistoryEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    static func appendToHistory(_ entry: MinigolfHistoryEntry) {
        var entries = loadHistory()
        entries.insert(entry, at: 0)
        if entries.count > 50 { entries = Array(entries.prefix(50)) }
        saveHistory(entries)
    }
}

