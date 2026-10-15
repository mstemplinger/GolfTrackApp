import Foundation
import Observation

// MARK: - Fortschritt je Frage

/// Lernstand einer einzelnen Platzreife-Frage.
///
/// Wer eine Frage auf Anhieb richtig beantwortet, kann sie – sie gilt sofort als sicher.
/// Wer sich einmal vertan hat, muss sie danach zweimal in Folge richtig beantworten.
/// So wiederholt die App nur, was wirklich wackelt, statt alle 150 Fragen doppelt abzufragen.
struct QuestionProgress: Codable, Equatable {
    var streak = 0
    var timesAnswered = 0
    var timesWrong = 0
    var lastAnswered: Date?
    var lastWasWrong = false

    var requiredStreak: Int { timesWrong == 0 ? 1 : 2 }

    var status: QuestionStatus {
        if timesAnswered == 0 { return .new }
        if lastWasWrong { return .wrong }
        return streak >= requiredStreak ? .mastered : .learning
    }

    mutating func record(correct: Bool, at date: Date) {
        timesAnswered += 1
        lastAnswered = date
        lastWasWrong = !correct
        if correct {
            streak += 1
        } else {
            streak = 0
            timesWrong += 1
        }
    }
}

enum QuestionStatus {
    case new, wrong, learning, mastered
}

struct QuizStatusCounts: Equatable {
    var new = 0
    var wrong = 0
    var learning = 0
    var mastered = 0

    var total: Int { new + wrong + learning + mastered }
    /// Fragen, die noch einmal drankommen sollten.
    var toRepeat: Int { wrong + learning }

    /// Anteil, der für die Prüfung sitzt – halb gelernte Fragen zählen halb.
    var readiness: Double {
        total == 0 ? 0 : (Double(mastered) + Double(learning) * 0.5) / Double(total)
    }
}

// MARK: - Lernrunde zusammenstellen

enum QuizSessionBuilder {
    /// Fragen pro Lernrunde – kurz genug für die Bahnfahrt, lang genug für Fortschritt.
    static let sessionSize = 20

    /// Reihenfolge: zuerst Fehler (älteste zuerst), dann angefangene, dann neue,
    /// zum Auffüllen schließlich sichere Fragen, die am längsten nicht dran waren.
    static func session(
        from pool: [QuizQuestion],
        progress: [String: QuestionProgress],
        limit: Int = sessionSize,
        mistakesOnly: Bool = false
    ) -> [QuizQuestion] {
        func entry(_ q: QuizQuestion) -> QuestionProgress { progress[q.id] ?? QuestionProgress() }
        func oldestFirst(_ a: QuizQuestion, _ b: QuizQuestion) -> Bool {
            (entry(a).lastAnswered ?? .distantPast) < (entry(b).lastAnswered ?? .distantPast)
        }

        let wrong    = pool.filter { entry($0).status == .wrong }.sorted(by: oldestFirst)
        let learning = pool.filter { entry($0).status == .learning }.sorted(by: oldestFirst)
        var picked   = wrong + learning
        if !mistakesOnly {
            let fresh    = pool.filter { entry($0).status == .new }.shuffled()
            let mastered = pool.filter { entry($0).status == .mastered }.sorted(by: oldestFirst)
            picked += fresh + mastered
        }
        return Array(picked.prefix(limit)).shuffled()
    }
}

// MARK: - Speicher

/// Hält den Lernstand aller Platzreife-Fragen und legt ihn in den UserDefaults ab.
/// Schlüssel ist der Fragetext (siehe `QuizQuestion.id`).
@Observable
final class PlatzreifeProgressStore {
    static let shared = PlatzreifeProgressStore()

    private(set) var entries: [String: QuestionProgress]
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "platzreife.progress.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: QuestionProgress].self, from: data) {
            entries = decoded
        } else {
            entries = [:]
        }
    }

    func progress(for question: QuizQuestion) -> QuestionProgress {
        entries[question.id] ?? QuestionProgress()
    }

    func status(of question: QuizQuestion) -> QuestionStatus {
        progress(for: question).status
    }

    func record(_ question: QuizQuestion, correct: Bool, at date: Date = .now) {
        var entry = progress(for: question)
        entry.record(correct: correct, at: date)
        entries[question.id] = entry
        save()
    }

    func counts(in pool: [QuizQuestion]) -> QuizStatusCounts {
        var counts = QuizStatusCounts()
        for question in pool {
            switch status(of: question) {
            case .new:      counts.new += 1
            case .wrong:    counts.wrong += 1
            case .learning: counts.learning += 1
            case .mastered: counts.mastered += 1
            }
        }
        return counts
    }

    func session(from pool: [QuizQuestion], mistakesOnly: Bool = false) -> [QuizQuestion] {
        QuizSessionBuilder.session(from: pool, progress: entries, mistakesOnly: mistakesOnly)
    }

    func reset() {
        entries = [:]
        defaults.removeObject(forKey: storageKey)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
