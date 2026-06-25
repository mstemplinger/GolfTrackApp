import SwiftUI
import SwiftData

// MARK: - Quiz Hub

struct PlatzreifeQuizView: View {
    @Query(sort: \QuizResult.date, order: .reverse) private var results: [QuizResult]
    @Environment(\.modelContext) private var context
    @State private var showSmartMode    = false
    @State private var showExamMode     = false
    @State private var selectedCategory: QuizCategory? = nil
    @State private var showCategoryPicker = false
    @State private var showDeleteAllConfirm = false
    @State private var showAllResults   = false

    private var examResults: [QuizResult] { results.filter { $0.mode == "exam" } }
    private var bestExam: QuizResult? { examResults.max(by: { $0.percentage < $1.percentage }) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero banner
                heroBanner

                // Stats row
                if !examResults.isEmpty {
                    statsRow
                }

                // Mode cards
                VStack(spacing: 14) {
                    modeCard(
                        title: "Smart-Modus",
                        subtitle: "Übe alle Fragen adaptiv",
                        description: "Falsch beantwortete Fragen wiederholen sich – bis du sie sicher beherrschst. Wie in der Fahrschule.",
                        icon: "brain.head.profile",
                        color: AppTheme.gold,
                        badge: "\(PlatzreifeQuestions.all.count) Fragen"
                    ) {
                        showCategoryPicker = true
                    }

                    modeCard(
                        title: "Probeprüfung",
                        subtitle: "30 Fragen · 30 Minuten",
                        description: "Simuliere die echte Platzreife-Theorieprüfung. Bestanden bei 75 % (23/30 Fragen).",
                        icon: "checkmark.seal.fill",
                        color: AppTheme.gold,
                        badge: "Bestanden ab 75 %"
                    ) {
                        showExamMode = true
                    }
                }
                .padding(.horizontal)

                // Results history
                if !results.isEmpty {
                    resultsSection
                }

                Spacer(minLength: 20)
            }
            .padding(.top)
        }
        .navigationTitle("Platzreife Quiz")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.bg)
        .confirmationDialog("Kategorie wählen", isPresented: $showCategoryPicker, titleVisibility: .visible) {
            Button("Alle Kategorien (\(PlatzreifeQuestions.all.count) Fragen)") {
                selectedCategory = nil
                showSmartMode = true
            }
            ForEach(QuizCategory.allCases, id: \.self) { cat in
                let count = PlatzreifeQuestions.all.filter { $0.category == cat }.count
                Button("\(cat.rawValue) (\(count) Fragen)") {
                    selectedCategory = cat
                    showSmartMode = true
                }
            }
            Button("Abbrechen", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showSmartMode) {
            SmartModeView(category: selectedCategory)
        }
        .fullScreenCover(isPresented: $showExamMode) {
            ExamModeView()
        }
    }

    // MARK: Hero
    private var heroBanner: some View {
        VStack(spacing: 10) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .padding(18)
                .background(
                    LinearGradient(colors: [AppTheme.gold, AppTheme.cardAlt], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )
                .shadow(color: AppTheme.gold.opacity(0.4), radius: 12, y: 4)

            Text("Platzreife Theorie")
                .font(.title2.bold())

            Text("Offizieller Fragenkatalog · \(PlatzreifeQuestions.all.count) Fragen · 6 Themengebiete")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: Stats
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCell(
                value: "\(examResults.count)",
                label: "Prüfungen",
                icon: "doc.text.fill",
                color: AppTheme.gold
            )
            statCell(
                value: examResults.filter(\.passed).count.description,
                label: "Bestanden",
                icon: "checkmark.circle.fill",
                color: AppTheme.gold
            )
            if let best = bestExam {
                statCell(
                    value: "\(Int(best.percentage)) %",
                    label: "Bestleistung",
                    icon: "star.fill",
                    color: .orange
                )
            }
        }
        .padding(.horizontal)
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Mode Card
    private func modeCard(
        title: String,
        subtitle: String,
        description: String,
        icon: String,
        color: Color,
        badge: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundStyle(color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(color.opacity(0.12), in: Capsule())
                    }
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(color)
                        .fontWeight(.semibold)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: Results
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ergebnisse")
                    .font(.headline)
                Spacer()
                Button {
                    showDeleteAllConfirm = true
                } label: {
                    Label("Alle löschen", systemImage: "trash")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .confirmationDialog("Alle Ergebnisse löschen?", isPresented: $showDeleteAllConfirm, titleVisibility: .visible) {
                    Button("Alle löschen", role: .destructive) {
                        results.forEach { context.delete($0) }
                    }
                    Button("Abbrechen", role: .cancel) {}
                }
            }
            .padding(.horizontal)

            let displayed = showAllResults ? results : Array(results.prefix(5))
            VStack(spacing: 0) {
                ForEach(Array(displayed.enumerated()), id: \.element.id) { i, result in
                    resultRow(result)
                    if i < displayed.count - 1 {
                        Divider().padding(.leading, 62)
                    }
                }
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)

            if results.count > 5 {
                Button {
                    withAnimation { showAllResults.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text(showAllResults ? "Weniger anzeigen" : "Alle \(results.count) Ergebnisse anzeigen")
                        Image(systemName: showAllResults ? "chevron.up" : "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.gold)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            }
        }
    }

    private func resultRow(_ result: QuizResult) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(result.mode == "exam"
                          ? (result.passed ? AppTheme.gold.opacity(0.15) : Color.red.opacity(0.12))
                          : AppTheme.gold.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: result.mode == "exam"
                      ? (result.passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                      : "brain.head.profile")
                .font(.system(size: 15))
                .foregroundStyle(result.mode == "exam"
                                 ? (result.passed ? AppTheme.gold : .red)
                                 : .blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(result.mode == "exam" ? "Probeprüfung" : "Smart-Modus")
                    .font(.subheadline.bold())
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                if result.mode == "exam" {
                    Text(result.passed ? "Bestanden ✓" : "Nicht bestanden")
                        .font(.caption2.bold())
                        .foregroundStyle(result.passed ? AppTheme.gold : .red)
                } else {
                    Text(result.durationFormatted)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSec)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(result.score)/\(result.total)")
                    .font(.subheadline.bold())
                    .foregroundStyle(result.mode == "exam"
                                     ? (result.passed ? AppTheme.gold : .red)
                                     : .blue)
                Text("\(Int(result.percentage)) %")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }

            Button {
                context.delete(result)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(8)
                    .background(Color.red.opacity(0.08), in: Circle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Smart Mode

struct SmartModeView: View {
    let category: QuizCategory?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // All questions filtered by category
    private var allQuestions: [QuizQuestion] {
        if let cat = category {
            return PlatzreifeQuestions.all.filter { $0.category == cat }
        }
        return PlatzreifeQuestions.all
    }

    @State private var queue: [QuizQuestion] = []
    @State private var masteredIDs: Set<UUID> = []
    // currentQuestion is stored as @State so it never changes mid-render
    @State private var currentQuestion: QuizQuestion? = nil
    @State private var selectedAnswer: Int? = nil
    @State private var showExplanation = false
    @State private var sessionCorrect = 0
    @State private var sessionTotal = 0
    @State private var startTime = Date()
    @State private var isFinished = false
    @State private var showQuitConfirm = false
    @State private var wrongAnswers: [(question: QuizQuestion, chosen: Int)] = []
    @State private var showWrongReview = false
    @State private var wrongReviewIndex = 0

    private var progress: Double { allQuestions.isEmpty ? 1 : Double(masteredIDs.count) / Double(allQuestions.count) }

    var body: some View {
        NavigationStack {
            Group {
                if isFinished {
                    smartFinishView
                } else if let q = currentQuestion {
                    smartQuestionView(q)
                } else {
                    ProgressView("Lädt…")
                }
            }
            .navigationTitle(category?.rawValue ?? "Smart-Modus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Beenden") { showQuitConfirm = true }
                }
            }
            .alert("Modus beenden?", isPresented: $showQuitConfirm) {
                Button("Abbrechen", role: .cancel) {}
                Button("Beenden", role: .destructive) { saveAndDismiss() }
            } message: {
                Text("Dein Fortschritt wird gespeichert.")
            }
        }
        .onAppear { setupQueue() }
    }

    // MARK: Question card
    private func smartQuestionView(_ q: QuizQuestion) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                // Progress header
                VStack(spacing: 6) {
                    HStack {
                        Label("\(masteredIDs.count) gelernt", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.gold)
                        Spacer()
                        Text("\(queue.count) verbleibend")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                    }
                    ProgressView(value: progress)
                        .tint(AppTheme.gold)
                }
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))

                // Category badge
                Label(q.category.rawValue, systemImage: q.category.icon)
                    .font(.caption.bold())
                    .foregroundStyle(q.category.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(q.category.color.opacity(0.12), in: Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Question
                Text(q.question)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Options
                VStack(spacing: 10) {
                    ForEach(Array(q.options.enumerated()), id: \.offset) { idx, option in
                        optionButton(text: option, index: idx, question: q)
                    }
                }

                // Explanation
                if showExplanation {
                    explanationCard(q)

                    Button(action: nextQuestion) {
                        Text(masteredIDs.count == allQuestions.count ? "Abschließen" : "Nächste Frage")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                selectedAnswer == q.correctIndex ? AppTheme.gold : Color.orange,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(AppTheme.bg)
    }

    private func optionButton(text: String, index: Int, question: QuizQuestion) -> some View {
        Button {
            guard selectedAnswer == nil else { return }
            selectedAnswer = index
            showExplanation = true
            sessionTotal += 1
            if index == question.correctIndex {
                sessionCorrect += 1
                masteredIDs.insert(question.id)
            } else {
                // Track first-time wrong answers only
                if !wrongAnswers.contains(where: { $0.question.id == question.id }) {
                    wrongAnswers.append((question: question, chosen: index))
                }
            }
            // Queue is only modified in nextQuestion() to avoid mid-render changes
        } label: {
            HStack(spacing: 12) {
                // Letter badge
                Text(["A", "B", "C", "D"][index])
                    .font(.caption.bold())
                    .frame(width: 28, height: 28)
                    .background(optionBadgeColor(index, question: question), in: Circle())
                    .foregroundStyle(.white)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if let sel = selectedAnswer {
                    if index == question.correctIndex {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.gold)
                    } else if sel == index {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .background(optionBackground(index, question: question), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(optionBorderColor(index, question: question), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedAnswer != nil)
    }

    private func optionBadgeColor(_ i: Int, question: QuizQuestion) -> Color {
        guard let sel = selectedAnswer else { return .secondary.opacity(0.5) }
        if i == question.correctIndex { return AppTheme.gold }
        if i == sel { return .red }
        return .secondary.opacity(0.3)
    }

    private func optionBackground(_ i: Int, question: QuizQuestion) -> Color {
        guard let sel = selectedAnswer else { return AppTheme.card }
        if i == question.correctIndex { return AppTheme.gold.opacity(0.08) }
        if i == sel { return .red.opacity(0.08) }
        return AppTheme.card
    }

    private func optionBorderColor(_ i: Int, question: QuizQuestion) -> Color {
        guard let sel = selectedAnswer else { return Color.secondary.opacity(0.2) }
        if i == question.correctIndex { return AppTheme.gold.opacity(0.6) }
        if i == sel { return .red.opacity(0.4) }
        return Color.secondary.opacity(0.1)
    }

    private func explanationCard(_ q: QuizQuestion) -> some View {
        let correct = selectedAnswer == q.correctIndex
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: correct ? "checkmark.circle.fill" : "arrow.uturn.right.circle.fill")
                .foregroundStyle(correct ? AppTheme.gold : .orange)
                .font(.title3)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(correct ? "Richtig!" : "Nicht ganz – die Frage kommt wieder")
                    .font(.caption.bold())
                    .foregroundStyle(correct ? AppTheme.gold : .orange)
                Text(q.explanation)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            (correct ? AppTheme.gold : Color.orange).opacity(0.1),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    // MARK: Finish
    private var smartFinishView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.gold)
                .shadow(color: .yellow.opacity(0.4), radius: 12, y: 4)

            VStack(spacing: 8) {
                Text("Alle Fragen gelernt!")
                    .font(.title.bold())
                Text("Du hast alle \(allQuestions.count) Fragen beherrscht.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSec)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(sessionCorrect)")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.gold)
                        Text("Richtig")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                    }
                    Divider().frame(height: 40)
                    VStack {
                        Text("\(sessionTotal - sessionCorrect)")
                            .font(.title2.bold())
                            .foregroundStyle(.orange)
                        Text("Wiederholt")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                    }
                    Divider().frame(height: 40)
                    VStack {
                        Text(durationString)
                            .font(.title2.bold())
                        Text("Zeit")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
                .padding()
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            VStack(spacing: 12) {
                if !wrongAnswers.isEmpty {
                    Button {
                        wrongReviewIndex = 0
                        showWrongReview = true
                    } label: {
                        Label("\(wrongAnswers.count) falsche Antworten ansehen", systemImage: "exclamationmark.circle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
                Button("Fertig") { saveAndDismiss() }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .background(AppTheme.bg)
        .sheet(isPresented: $showWrongReview) {
            WrongAnswerReviewSheet(
                wrongAnswers: wrongAnswers,
                currentIndex: $wrongReviewIndex
            )
        }
    }

    // MARK: Helpers
    private func setupQueue() {
        queue = allQuestions.shuffled()
        currentQuestion = queue.first
        startTime = Date()
    }

    private func nextQuestion() {
        guard let q = currentQuestion else { return }

        if selectedAnswer == q.correctIndex {
            // Correct: remove from queue permanently
            queue.removeAll { $0.id == q.id }
        } else {
            // Wrong: rotate to end of queue so it comes back later
            if let pos = queue.firstIndex(where: { $0.id == q.id }) {
                let item = queue.remove(at: pos)
                queue.append(item)
            }
        }

        selectedAnswer = nil
        showExplanation = false

        if queue.isEmpty {
            isFinished = true
        } else {
            currentQuestion = queue.first
        }
    }

    private var durationString: String {
        let s = Int(Date().timeIntervalSince(startTime))
        let m = s / 60; let sec = s % 60
        return m > 0 ? "\(m)m \(sec)s" : "\(sec)s"
    }

    private func saveAndDismiss() {
        let duration = Int(Date().timeIntervalSince(startTime))
        let result = QuizResult(mode: "smart", score: masteredIDs.count, total: allQuestions.count, durationSeconds: duration)
        context.insert(result)
        dismiss()
    }
}

// MARK: - Exam Mode

struct ExamModeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let examQuestions: [QuizQuestion] = {
        // 15 Golfregeln (regeln + regelanwendung) + 15 Allgemein (etikette, scoring, platz, handicap)
        let rulesQ   = Array(PlatzreifeQuestions.all.filter {  $0.category.isRulesCategory }.shuffled().prefix(15))
        let generalQ = Array(PlatzreifeQuestions.all.filter { !$0.category.isRulesCategory }.shuffled().prefix(15))
        return (rulesQ + generalQ).shuffled()
    }()

    @State private var currentIndex = 0
    @State private var answers: [Int?]
    @State private var timeRemaining = 30 * 60  // 30 minutes
    @State private var timer: Timer? = nil
    @State private var isFinished = false
    @State private var showQuitConfirm = false
    @State private var reviewMode = false
    @State private var reviewIndex = 0
    @State private var startTime = Date()

    init() {
        _answers = State(initialValue: Array(repeating: nil, count: 30))
    }

    private var correctCount: Int { answers.enumerated().filter { $0.element == examQuestions[$0.offset].correctIndex }.count }
    private var answeredCount: Int { answers.compactMap { $0 }.count }
    private var passed: Bool { correctCount >= 23 }

    var body: some View {
        NavigationStack {
            Group {
                if reviewMode {
                    reviewView
                } else if isFinished {
                    resultView
                } else {
                    questionView
                }
            }
            .navigationTitle("Probeprüfung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if reviewMode {
                        Button("Zurück") { withAnimation { reviewMode = false } }
                    } else if !isFinished {
                        Button("Abbrechen") { showQuitConfirm = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if reviewMode {
                        Button("Schließen") { dismiss() }
                            .fontWeight(.semibold)
                    } else if !isFinished {
                        timerBadge
                    }
                }
            }
            .alert("Prüfung abbrechen?", isPresented: $showQuitConfirm) {
                Button("Weitermachen", role: .cancel) {}
                Button("Abbrechen", role: .destructive) { stopTimer(); dismiss() }
            } message: {
                Text("Das Ergebnis wird nicht gespeichert.")
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    // MARK: Timer badge
    private var timerBadge: some View {
        let mins = timeRemaining / 60
        let secs = timeRemaining % 60
        let isLow = timeRemaining < 5 * 60
        return HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption.bold())
            Text(String(format: "%02d:%02d", mins, secs))
                .font(.caption.bold())
                .monospacedDigit()
        }
        .foregroundStyle(isLow ? .red : .primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isLow ? Color.red.opacity(0.1) : Color.secondary.opacity(0.1), in: Capsule())
    }

    // MARK: Question view
    private var questionView: some View {
        VStack(spacing: 0) {
            // Top progress
            VStack(spacing: 6) {
                HStack {
                    Text("Frage \(currentIndex + 1) von \(examQuestions.count)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textSec)
                    Spacer()
                    Text("\(answeredCount) beantwortet")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                ProgressView(value: Double(currentIndex + 1), total: Double(examQuestions.count))
                    .tint(AppTheme.gold)
            }
            .padding()

            ScrollView {
                let q = examQuestions[currentIndex]
                VStack(spacing: 16) {
                    // Category
                    Label(q.category.rawValue, systemImage: q.category.icon)
                        .font(.caption.bold())
                        .foregroundStyle(q.category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(q.category.color.opacity(0.12), in: Capsule())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Question
                    Text(q.question)
                        .font(.title3.bold())
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Options (no feedback!)
                    VStack(spacing: 10) {
                        ForEach(Array(q.options.enumerated()), id: \.offset) { idx, option in
                            examOptionButton(text: option, index: idx, qIndex: currentIndex)
                        }
                    }
                }
                .padding()
            }

            // Navigation buttons
            HStack(spacing: 14) {
                if currentIndex > 0 {
                    Button("Zurück") {
                        withAnimation { currentIndex -= 1 }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentIndex < examQuestions.count - 1 {
                    Button("Weiter") {
                        withAnimation { currentIndex += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
                } else {
                    Button("Prüfung abgeben") {
                        submitExam()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(answeredCount == examQuestions.count ? AppTheme.gold : .orange)
                }
            }
            .padding()
            .background(AppTheme.card)
        }
        .background(AppTheme.bg)
    }

    private func examOptionButton(text: String, index: Int, qIndex: Int) -> some View {
        let selected = answers[qIndex] == index
        return Button {
            answers[qIndex] = index
        } label: {
            HStack(spacing: 12) {
                Text(["A", "B", "C", "D"][index])
                    .font(.caption.bold())
                    .frame(width: 28, height: 28)
                    .background(selected ? AppTheme.gold : Color.secondary.opacity(0.25), in: Circle())
                    .foregroundStyle(.white)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.gold)
                }
            }
            .padding()
            .background(selected ? AppTheme.gold.opacity(0.08) : AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? AppTheme.gold.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Result view
    private var resultView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Result badge
                VStack(spacing: 12) {
                    Image(systemName: passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(passed ? AppTheme.gold : .red)
                        .shadow(color: (passed ? AppTheme.gold : Color.red).opacity(0.3), radius: 12, y: 4)

                    Text(passed ? "Bestanden!" : "Nicht bestanden")
                        .font(.title.bold())
                        .foregroundStyle(passed ? AppTheme.gold : .red)

                    Text(passed
                         ? "Herzlichen Glückwunsch! Du hast die Probeprüfung bestanden."
                         : "Übe noch etwas weiter und versuche es erneut.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Score ring + stats
                VStack(spacing: 16) {
                    // Big score
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(correctCount)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(passed ? AppTheme.gold : .red)
                            Text("Richtig")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                        }
                        Text("/")
                            .font(.system(size: 36, weight: .thin))
                            .foregroundStyle(AppTheme.textSec)
                        VStack {
                            Text("\(examQuestions.count)")
                                .font(.system(size: 48, weight: .bold))
                            Text("Gesamt")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                        }
                    }

                    // Percentage bar
                    VStack(spacing: 6) {
                        HStack {
                            Text("\(Int(Double(correctCount) / Double(examQuestions.count) * 100)) %")
                                .font(.headline)
                            Spacer()
                            Text("Mindestens 75 % (23/30)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(height: 12)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(passed ? AppTheme.gold : Color.red)
                                    .frame(width: geo.size.width * Double(correctCount) / Double(examQuestions.count), height: 12)
                                // Pass threshold marker
                                Rectangle()
                                    .fill(Color.primary.opacity(0.4))
                                    .frame(width: 2, height: 20)
                                    .offset(x: geo.size.width * 0.75 - 1, y: -4)
                            }
                        }
                        .frame(height: 12)
                    }

                    // Category breakdown
                    categoryBreakdown
                }
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Buttons
                VStack(spacing: 12) {
                    Button("Antworten durchsehen") {
                        reviewIndex = 0
                        reviewMode = true
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(AppTheme.gold)

                    Button("Fertig") { dismiss() }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
        }
        .background(AppTheme.bg)
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nach Kategorie")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSec)

            ForEach(QuizCategory.allCases, id: \.self) { cat in
                let catQ = examQuestions.indices.filter { examQuestions[$0].category == cat }
                let catCorrect = catQ.filter { answers[$0] == examQuestions[$0].correctIndex }.count
                let total = catQ.count
                if total > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: cat.icon)
                            .font(.caption)
                            .foregroundStyle(cat.color)
                            .frame(width: 18)
                        Text(cat.rawValue)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                        Spacer()
                        Text("\(catCorrect)/\(total)")
                            .font(.caption.bold())
                            .foregroundStyle(catCorrect == total ? AppTheme.gold : catCorrect >= total / 2 ? .orange : .red)
                    }
                }
            }
        }
    }

    // MARK: Review view
    private var reviewView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("Frage \(reviewIndex + 1)/\(examQuestions.count)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            ScrollView {
                let q = examQuestions[reviewIndex]
                let userAnswer = answers[reviewIndex]
                let isCorrect = userAnswer == q.correctIndex

                VStack(spacing: 16) {
                    // Status badge
                    HStack {
                        Label(
                            isCorrect ? "Richtig" : (userAnswer == nil ? "Nicht beantwortet" : "Falsch"),
                            systemImage: isCorrect ? "checkmark.circle.fill" : (userAnswer == nil ? "minus.circle" : "xmark.circle.fill")
                        )
                        .font(.caption.bold())
                        .foregroundStyle(isCorrect ? AppTheme.gold : (userAnswer == nil ? .secondary : .red))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background((isCorrect ? AppTheme.gold : (userAnswer == nil ? Color.secondary : Color.red)).opacity(0.12), in: Capsule())

                        Spacer()

                        Label(q.category.rawValue, systemImage: q.category.icon)
                            .font(.caption.bold())
                            .foregroundStyle(q.category.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(q.category.color.opacity(0.12), in: Capsule())
                    }

                    Text(q.question)
                        .font(.title3.bold())
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // All options with color coding
                    VStack(spacing: 10) {
                        ForEach(Array(q.options.enumerated()), id: \.offset) { idx, option in
                            let isRight = idx == q.correctIndex
                            let wasChosen = userAnswer == idx
                            HStack(spacing: 12) {
                                Text(["A", "B", "C", "D"][idx])
                                    .font(.caption.bold())
                                    .frame(width: 28, height: 28)
                                    .background(
                                        isRight ? AppTheme.gold : (wasChosen ? Color.red : Color.secondary.opacity(0.2)),
                                        in: Circle()
                                    )
                                    .foregroundStyle(isRight || wasChosen ? .white : .primary)

                                Text(option)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.text)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer()

                                if isRight {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.gold)
                                } else if wasChosen {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                                }
                            }
                            .padding()
                            .background(
                                isRight ? AppTheme.gold.opacity(0.08) : (wasChosen ? Color.red.opacity(0.08) : AppTheme.card),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isRight ? AppTheme.gold.opacity(0.5) : (wasChosen ? Color.red.opacity(0.3) : Color.secondary.opacity(0.15)),
                                        lineWidth: 1.5
                                    )
                            )
                        }
                    }

                    // Explanation
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppTheme.gold)
                            .font(.title3)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Erklärung")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSec)
                            Text(q.explanation)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }

            // Navigation
            HStack(spacing: 14) {
                if reviewIndex > 0 {
                    Button("Zurück") { withAnimation { reviewIndex -= 1 } }
                        .buttonStyle(.bordered)
                }
                Spacer()
                if reviewIndex < examQuestions.count - 1 {
                    Button("Nächste") { withAnimation { reviewIndex += 1 } }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.gold)
                } else {
                    Button("Fertig") { reviewMode = false }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.gold)
                }
            }
            .padding()
            .background(AppTheme.card)
        }
        .background(AppTheme.bg)
    }

    // MARK: Logic
    private func startTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                submitExam()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func submitExam() {
        stopTimer()
        let duration = Int(Date().timeIntervalSince(startTime))
        let result = QuizResult(mode: "exam", score: correctCount, total: examQuestions.count, durationSeconds: duration)
        context.insert(result)
        withAnimation { isFinished = true }
    }
}
