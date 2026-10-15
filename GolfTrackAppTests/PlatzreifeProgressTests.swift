import Testing
import Foundation
@testable import GolfTrackApp

/// Prüft den Lernstand der Platzreife-Fragen und wie daraus Lernrunden entstehen.
@MainActor
struct PlatzreifeProgressTests {

    private func question(_ text: String, category: QuizCategory = .regeln) -> QuizQuestion {
        QuizQuestion(question: text, options: ["A", "B", "C", "D"], correctIndex: 0, explanation: "", category: category)
    }

    private func freshDefaults() -> UserDefaults {
        let name = "PlatzreifeProgressTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func fragetexteSindEindeutig() {
        let ids = PlatzreifeQuestions.all.map(\.id)
        #expect(Set(ids).count == ids.count, "Doppelte Fragetexte teilen sich sonst einen Lernstand")
        #expect(PlatzreifeQuestions.all.count == 150, "Store-Text und App nennen 150 Fragen")
    }

    @Test func aufAnhiebRichtigIstSofortSicher() {
        var progress = QuestionProgress()
        #expect(progress.status == .new)
        progress.record(correct: true, at: .now)
        #expect(progress.status == .mastered)
    }

    @Test func nachEinemFehlerBrauchtEsZweiRichtigeInFolge() {
        var progress = QuestionProgress()
        progress.record(correct: false, at: .now)
        #expect(progress.status == .wrong)
        progress.record(correct: true, at: .now)
        #expect(progress.status == .learning)
        progress.record(correct: false, at: .now)
        #expect(progress.status == .wrong)
        progress.record(correct: true, at: .now)
        progress.record(correct: true, at: .now)
        #expect(progress.status == .mastered)
    }

    @Test func lernrundeNimmtFehlerZuerstUndSicheresZuletzt() {
        let pool = (1...30).map { question("Frage \($0)") }
        var entries: [String: QuestionProgress] = [:]
        var wrong = QuestionProgress(); wrong.record(correct: false, at: .now)
        var mastered = QuestionProgress(); mastered.record(correct: true, at: .now)
        for q in pool.prefix(5) { entries[q.id] = wrong }
        for q in pool.suffix(20) { entries[q.id] = mastered }

        let session = QuizSessionBuilder.session(from: pool, progress: entries, limit: 8)
        let ids = Set(session.map(\.id))

        #expect(session.count == 8)
        // 5 Fehler + 5 neue Fragen ergeben 10 Kandidaten vor den sicheren – 8 passen hinein.
        #expect(pool.prefix(5).allSatisfy { ids.contains($0.id) })
        #expect(pool.suffix(20).allSatisfy { !ids.contains($0.id) })
    }

    @Test func fehlerUebenEnthaeltNurWackeligeFragen() {
        let pool = (1...10).map { question("Frage \($0)") }
        var entries: [String: QuestionProgress] = [:]
        var wrong = QuestionProgress(); wrong.record(correct: false, at: .now)
        entries[pool[2].id] = wrong
        entries[pool[7].id] = wrong

        let session = QuizSessionBuilder.session(from: pool, progress: entries, mistakesOnly: true)
        #expect(Set(session.map(\.id)) == [pool[2].id, pool[7].id])

        let none = QuizSessionBuilder.session(from: pool, progress: [:], mistakesOnly: true)
        #expect(none.isEmpty)
    }

    @Test func fortschrittUeberstehtNeustart() {
        let defaults = freshDefaults()
        let q = question("Bleibt gespeichert?")

        let store = PlatzreifeProgressStore(defaults: defaults)
        store.record(q, correct: false)
        #expect(store.status(of: q) == .wrong)

        let reopened = PlatzreifeProgressStore(defaults: defaults)
        #expect(reopened.status(of: q) == .wrong)

        reopened.reset()
        #expect(PlatzreifeProgressStore(defaults: defaults).status(of: q) == .new)
    }

    @Test func pruefungsreifeZaehltAngefangeneHalb() {
        var counts = QuizStatusCounts()
        counts.mastered = 2
        counts.learning = 2
        counts.new = 4
        #expect(counts.readiness == 0.375)
        #expect(QuizStatusCounts().readiness == 0)
    }

    @Test func probepruefungHatHalbRegelnHalbAllgemeines() {
        let exam = ExamModeView.makeExam()
        #expect(exam.count == ExamModeView.questionCount)
        #expect(exam.filter(\.category.isRulesCategory).count == ExamModeView.questionCount / 2)
        #expect(Set(exam.map(\.id)).count == exam.count)
    }
}
