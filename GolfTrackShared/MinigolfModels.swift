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

extension Notification.Name {
    /// Eine Minigolfrunde wurde abgeschlossen. Die volle App braucht das nicht;
    /// der App Clip hängt daran seinen Hinweis auf die richtige App.
    static let minigolfRoundFinished = Notification.Name("minigolf.roundFinished")
}

enum MinigolfGameStore {
    private static let gameKey = "minigolf.savedGame"
    private static let namesKey = "minigolf.savedPlayerNames"
    private static let historyKey = "minigolf.history"
    private static let challengesKey = "minigolf.challenges"
    private static let migratedKey = "minigolf.movedToAppGroup"

    /// Gemeinsamer Ablageort von App und App Clip.
    ///
    /// Ohne ihn schreibt der Clip in seinen eigenen Sandkasten: Wer eine Runde
    /// im Clip spielt und danach die App installiert, stünde vor einem leeren
    /// Verlauf. Genau der Übergang ist der Sinn eines App Clips.
    static let appGroup = "group.com.TobiasAufschlaeger.GolfTrackappnew"

    /// Fällt auf den app-eigenen Speicher zurück, falls die Gruppe fehlt –
    /// dann verhält sich alles wie vorher, statt gar nicht zu sichern.
    private static let defaults: UserDefaults = {
        guard let shared = UserDefaults(suiteName: appGroup) else { return .standard }
        adoptExistingValues(into: shared)
        return shared
    }()

    /// Einmalige Übernahme der Werte aus dem alten Speicher.
    ///
    /// Es wird **kopiert, nicht verschoben**: Der alte Stand bleibt liegen. Und
    /// die Merkfahne steht in der Gruppe – sollte die wider Erwarten nicht
    /// halten, läuft die Übernahme beim nächsten Start eben noch einmal, statt
    /// dass jemand ohne Verlauf dasteht.
    private static func adoptExistingValues(into shared: UserDefaults) {
        guard !shared.bool(forKey: migratedKey) else { return }
        let old = UserDefaults.standard
        for key in [gameKey, namesKey, historyKey, challengesKey] {
            guard shared.object(forKey: key) == nil,
                  let value = old.object(forKey: key) else { continue }
            shared.set(value, forKey: key)
        }
        shared.set(true, forKey: migratedKey)
    }

    static func load() -> SavedMinigolfGame? {
        guard let data = defaults.data(forKey: gameKey) else { return nil }
        return try? JSONDecoder().decode(SavedMinigolfGame.self, from: data)
    }

    static func save(_ game: SavedMinigolfGame) {
        if let data = try? JSONEncoder().encode(game) {
            defaults.set(data, forKey: gameKey)
        }
    }

    static func clear() {
        defaults.removeObject(forKey: gameKey)
    }

    static func loadNames() -> [String]? {
        defaults.stringArray(forKey: namesKey)
    }

    static func saveNames(_ names: [String]) {
        defaults.set(names, forKey: namesKey)
    }

    /// Zuletzt gewählte Wettkämpfe – Vorschlag für die nächste Runde.
    static func loadChallenges() -> [MinigolfChallenge] {
        (defaults.stringArray(forKey: challengesKey) ?? [])
            .compactMap(MinigolfChallenge.init(rawValue:))
    }

    static func saveChallenges(_ challenges: [MinigolfChallenge]) {
        defaults.set(challenges.map(\.rawValue), forKey: challengesKey)
    }

    static func loadHistory() -> [MinigolfHistoryEntry] {
        guard let data = defaults.data(forKey: historyKey) else { return [] }
        return (try? JSONDecoder().decode([MinigolfHistoryEntry].self, from: data)) ?? []
    }

    static func saveHistory(_ entries: [MinigolfHistoryEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: historyKey)
        }
    }

    static func appendToHistory(_ entry: MinigolfHistoryEntry) {
        var entries = loadHistory()
        entries.insert(entry, at: 0)
        if entries.count > 50 { entries = Array(entries.prefix(50)) }
        saveHistory(entries)
    }
}

