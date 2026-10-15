import SwiftUI
import SwiftData
import Combine

// MARK: - Übersicht

struct PlatzreifeQuizView: View {
    @Query(sort: \QuizResult.date, order: .reverse) private var results: [QuizResult]
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var store = PlatzreifeProgressStore.shared
    @State private var activeSession: QuizSessionRequest?
    @State private var showExamMode = false
    @State private var showDeleteAllConfirm = false
    @State private var showResetConfirm = false
    @State private var showAllResults = false

    private var isRegular: Bool { sizeClass == .regular }
    private var catalog: [QuizQuestion] { PlatzreifeQuestions.all }
    private var counts: QuizStatusCounts { store.counts(in: catalog) }
    private var examResults: [QuizResult] { results.filter { $0.mode == "exam" } }
    private var bestExam: QuizResult? { examResults.max(by: { $0.percentage < $1.percentage }) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isRegular {
                    HStack(alignment: .top, spacing: 20) {
                        readinessCard
                        learnActions
                    }
                    // Lässt die Prüfungsreife-Karte so hoch werden wie die Knopfspalte daneben.
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    readinessCard
                    learnActions
                }

                categorySection

                if !results.isEmpty {
                    historySection
                }

                rulesLink
            }
            .padding(isRegular ? 28 : 16)
            .readableWidth(1000)
        }
        .background(AppTheme.bg)
        .navigationTitle("Platzreife lernen")
        // Der große Titel bleibt unter der App-eigenen Navigationsleiste leer.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        Haptics.tap()
                        showResetConfirm = true
                    } label: {
                        Label("Lernfortschritt zurücksetzen", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Weitere Optionen")
            }
        }
        .confirmationDialog("Lernfortschritt zurücksetzen?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) {
                Haptics.warning()
                withAnimation { store.reset() }
            }
            Button("Abbrechen", role: .cancel) { Haptics.tap() }
        } message: {
            Text("Alle Fragen gelten danach wieder als neu. Deine Prüfungsergebnisse bleiben erhalten.")
        }
        .fullScreenCover(item: $activeSession) { request in
            PlatzreifeSessionView(request: request)
        }
        .fullScreenCover(isPresented: $showExamMode) {
            ExamModeView()
        }
    }

    // MARK: Prüfungsreife

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 20) {
                ReadinessRing(value: counts.readiness)
                    .frame(width: 112, height: 112)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Prüfungsreife")
                        .font(.caption.bold())
                        .textCase(.uppercase)
                        .foregroundStyle(AppTheme.textSec)
                    Text("\(counts.mastered) von \(counts.total) Fragen sitzen")
                        .font(.title3.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    hintText
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                statusChip(count: counts.mastered, label: Text("Sicher"), color: AppTheme.gold)
                statusChip(count: counts.toRepeat, label: Text("Wiederholen"), color: .orange)
                statusChip(count: counts.new, label: Text("Neu"), color: AppTheme.textSec)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: isRegular ? .infinity : nil, alignment: .topLeading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var hintText: Text {
        if counts.total == counts.new {
            return Text("Starte mit einer Lernrunde: 20 gemischte Fragen aus allen Themen.")
        }
        if counts.readiness >= 0.9 {
            return Text("Du bist gut vorbereitet. Teste dich jetzt in einer Probeprüfung.")
        }
        if counts.toRepeat > 0 {
            return Text("\(counts.toRepeat) Fragen solltest du noch einmal üben.")
        }
        return Text("Weiter so – jede Lernrunde bringt dich näher an die Prüfung.")
    }

    private func statusChip(count: Int, label: Text, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: "\(count)")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(color)
                .contentTransition(.numericText())
            label
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Lernen & Prüfen

    private var learnActions: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.medium()
                activeSession = QuizSessionRequest(category: nil, mistakesOnly: false)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(counts.total == counts.new ? "Erste Lernrunde starten" : "Weiterlernen")
                            .font(.headline)
                        Text("20 Fragen · Fehler kommen zuerst dran")
                            .font(.caption)
                            .opacity(0.8)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                .padding(18)
                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            if counts.toRepeat > 0 {
                actionRow(
                    icon: "arrow.uturn.backward.circle.fill",
                    color: .orange,
                    title: Text("Fehler üben"),
                    subtitle: Text("\(counts.toRepeat) Fragen, die noch wackeln")
                ) {
                    activeSession = QuizSessionRequest(category: nil, mistakesOnly: true)
                }
            }

            actionRow(
                icon: "checkmark.seal.fill",
                color: AppTheme.gold,
                title: Text("Probeprüfung"),
                subtitle: bestExam.map { Text("30 Fragen · 30 Minuten · Bestwert \(Int($0.percentage)) %") }
                    ?? Text("30 Fragen · 30 Minuten · bestanden ab 75 %")
            ) {
                showExamMode = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func actionRow(icon: String, color: Color, title: Text, subtitle: Text, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.medium()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(.headline)
                        .foregroundStyle(AppTheme.text)
                    subtitle
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textTer)
            }
            .padding(14)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: Themengebiete

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Themengebiete")
                .font(.headline)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: isRegular ? 210 : 150), spacing: 12)],
                spacing: 12
            ) {
                ForEach(QuizCategory.allCases, id: \.self) { category in
                    categoryCard(category)
                }
            }
        }
    }

    private func categoryCard(_ category: QuizCategory) -> some View {
        let catCounts = store.counts(in: catalog.filter { $0.category == category })
        return Button {
            Haptics.medium()
            activeSession = QuizSessionRequest(category: category, mistakesOnly: false)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.body)
                        .foregroundStyle(category.color)
                        .frame(width: 36, height: 36)
                        .background(category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    Spacer()
                    if catCounts.wrong > 0 {
                        Text(verbatim: "\(catCounts.wrong)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.orange, in: Capsule())
                            .accessibilityLabel(Text("\(catCounts.wrong) Fehler"))
                    }
                }
                Text(verbatim: category.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                Text("\(catCounts.mastered) von \(catCounts.total) sicher")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                ProgressSegments(counts: catCounts, tint: category.color)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: Ergebnisse

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ergebnisse")
                    .font(.headline)
                Spacer()
                Button {
                    Haptics.tap()
                    showDeleteAllConfirm = true
                } label: {
                    Label("Alle löschen", systemImage: "trash")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .confirmationDialog("Alle Ergebnisse löschen?", isPresented: $showDeleteAllConfirm, titleVisibility: .visible) {
                    Button("Alle löschen", role: .destructive) {
                        Haptics.warning()
                        results.forEach { context.delete($0) }
                    }
                    Button("Abbrechen", role: .cancel) { Haptics.tap() }
                }
            }

            if !examResults.isEmpty {
                HStack(spacing: 12) {
                    statCell(value: "\(examResults.count)", label: Text("Prüfungen"), icon: "doc.text.fill", color: AppTheme.gold)
                    statCell(value: "\(examResults.filter(\.passed).count)", label: Text("Bestanden"), icon: "checkmark.circle.fill", color: AppTheme.gold)
                    if let best = bestExam {
                        statCell(value: "\(Int(best.percentage)) %", label: Text("Bestleistung"), icon: "star.fill", color: .orange)
                    }
                }
            }

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

            if results.count > 5 {
                Button {
                    Haptics.tap()
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
            }
        }
    }

    private func statCell(value: String, label: Text, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text(verbatim: value)
                .font(.title3.bold())
            label
                .font(.caption2)
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func resultRow(_ result: QuizResult) -> some View {
        let isExam = result.mode == "exam"
        let tint: Color = isExam ? (result.passed ? AppTheme.gold : .red) : .blue
        return HStack(spacing: 14) {
            Image(systemName: isExam ? (result.passed ? "checkmark.seal.fill" : "xmark.seal.fill") : "brain.head.profile")
                .font(.system(size: 15))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(isExam ? "Probeprüfung" : "Lernrunde")
                    .font(.subheadline.bold())
                Text(result.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                if isExam {
                    Text(result.passed ? "Bestanden ✓" : "Nicht bestanden")
                        .font(.caption2.bold())
                        .foregroundStyle(tint)
                } else {
                    Text(verbatim: result.durationFormatted)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSec)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(verbatim: "\(result.score)/\(result.total)")
                    .font(.subheadline.bold())
                    .foregroundStyle(tint)
                Text(verbatim: "\(Int(result.percentage)) %")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }

            Button {
                Haptics.warning()
                context.delete(result)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(8)
                    .background(Color.red.opacity(0.08), in: Circle())
            }
            .accessibilityLabel("Löschen")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: Regeln

    private var rulesLink: some View {
        NavigationLink {
            GolfRulesView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "book.closed.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44)
                    .background(Color.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Golfregeln nachlesen")
                        .font(.headline)
                        .foregroundStyle(AppTheme.text)
                    Text("Das Regelwerk mit Diagrammen – zum Nachschlagen beim Lernen")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textTer)
            }
            .padding(14)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bausteine

extension View {
    /// Hält Fragen und Karten auf dem iPad auf einer gut lesbaren Breite, statt sie über
    /// den ganzen Bildschirm zu ziehen.
    func readableWidth(_ maxWidth: CGFloat = 720) -> some View {
        frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }
}

struct QuizSessionRequest: Identifiable {
    let id = UUID()
    let category: QuizCategory?
    let mistakesOnly: Bool
}

private struct ReadinessRing: View {
    let value: Double
    @State private var shown = 0.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 12)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(verbatim: "\(Int((value * 100).rounded())) %")
                .font(.title2.bold())
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { shown = value } }
        .onChange(of: value) { _, new in withAnimation(.easeOut(duration: 0.5)) { shown = new } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Prüfungsreife"))
        .accessibilityValue(Text(verbatim: "\(Int((value * 100).rounded())) %"))
    }
}

/// Fortschrittsbalken mit zwei Stufen: sicher (voll) und angefangen (blass).
private struct ProgressSegments: View {
    let counts: QuizStatusCounts
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let total = max(counts.total, 1)
            let mastered = geo.size.width * Double(counts.mastered) / Double(total)
            let started = geo.size.width * Double(counts.learning + counts.wrong) / Double(total)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule().fill(tint.opacity(0.35)).frame(width: mastered + started)
                Capsule().fill(tint).frame(width: mastered)
            }
        }
        .frame(height: 6)
    }
}

enum QuizOptionState {
    case idle, selected, correct, wrong, dimmed
}

/// Eine Antwortmöglichkeit – dieselbe Karte in Lernrunde, Prüfung und Auswertung.
struct QuizOptionRow: View {
    let index: Int
    let text: String
    let state: QuizOptionState

    static func letter(_ index: Int) -> String {
        String(UnicodeScalar(UInt8(65 + index)))
    }

    private var accent: Color {
        switch state {
        case .idle, .dimmed: return Color.white.opacity(0.25)
        case .selected, .correct: return AppTheme.gold
        case .wrong: return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(verbatim: Self.letter(index))
                .font(.caption.bold())
                .frame(width: 28, height: 28)
                .background(accent, in: Circle())
                .foregroundStyle(.white)

            Text(verbatim: text)
                .font(.body)
                .foregroundStyle(AppTheme.text.opacity(state == .dimmed ? 0.6 : 1))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            switch state {
            case .selected, .correct:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.gold)
            case .wrong:
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            case .idle, .dimmed:
                EmptyView()
            }
        }
        .padding()
        .frame(minHeight: 56)
        .background(background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(border, lineWidth: 1.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var background: Color {
        switch state {
        case .idle, .dimmed: return AppTheme.card
        case .selected, .correct: return AppTheme.gold.opacity(0.10)
        case .wrong: return Color.red.opacity(0.10)
        }
    }

    private var border: Color {
        switch state {
        case .idle: return Color.white.opacity(0.12)
        case .dimmed: return Color.white.opacity(0.06)
        case .selected, .correct: return AppTheme.gold.opacity(0.6)
        case .wrong: return Color.red.opacity(0.45)
        }
    }
}

struct QuizQuestionHeader: View {
    let question: QuizQuestion
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            QuizCategoryBadge(category: question.category)
            Text(verbatim: question.question)
                .font(sizeClass == .regular ? .title2.bold() : .title3.bold())
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct QuizCategoryBadge: View {
    let category: QuizCategory

    var body: some View {
        Label {
            Text(verbatim: category.rawValue)
        } icon: {
            Image(systemName: category.icon)
        }
        .font(.caption.bold())
        .foregroundStyle(category.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(category.color.opacity(0.12), in: Capsule())
    }
}

struct QuizExplanationCard: View {
    let question: QuizQuestion
    /// `nil` in der Auswertung – dort gibt es kein „Richtig/Falsch“, nur die Erklärung.
    var wasCorrect: Bool? = nil

    private var tint: Color {
        guard let wasCorrect else { return AppTheme.gold }
        return wasCorrect ? AppTheme.gold : .orange
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: wasCorrect == false ? "arrow.uturn.right.circle.fill"
                  : wasCorrect == true ? "checkmark.circle.fill" : "lightbulb.fill")
                .foregroundStyle(tint)
                .font(.title3)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    switch wasCorrect {
                    case true?:  Text("Richtig!")
                    case false?: Text("Nicht ganz – die Frage kommt gleich noch einmal")
                    case nil:    Text("Erklärung")
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(wasCorrect == nil ? AppTheme.textSec : tint)
                Text(verbatim: question.explanation)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Lernrunde

struct PlatzreifeSessionView: View {
    let request: QuizSessionRequest
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var store = PlatzreifeProgressStore.shared

    @State private var sessionQuestions: [QuizQuestion] = []
    /// Die aktuelle Frage ist immer `queue.first`. Falsch beantwortete Fragen
    /// werden drei Plätze weiter hinten wieder eingereiht.
    @State private var queue: [QuizQuestion] = []
    @State private var selectedAnswer: Int?
    @State private var answeredOnce: Set<String> = []
    @State private var firstTryCorrect: Set<String> = []
    @State private var wrongAnswers: [(question: QuizQuestion, chosen: Int)] = []
    @State private var masteredBefore = 0
    @State private var readinessBefore = 0.0
    @State private var startTime = Date()
    @State private var isFinished = false
    @State private var resultSaved = false
    @State private var showQuitConfirm = false
    @State private var showWrongReview = false
    @State private var wrongReviewIndex = 0
    @State private var didStart = false

    private var isRegular: Bool { sizeClass == .regular }

    private var pool: [QuizQuestion] {
        guard let category = request.category else { return PlatzreifeQuestions.all }
        return PlatzreifeQuestions.all.filter { $0.category == category }
    }

    private var titleText: Text {
        if request.mistakesOnly { return Text("Fehler üben") }
        if let category = request.category { return Text(verbatim: category.rawValue) }
        return Text("Lernrunde")
    }

    var body: some View {
        NavigationStack {
            Group {
                if isFinished {
                    finishView
                } else if let question = queue.first {
                    questionView(question)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.bg)
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isFinished {
                        Button("Schließen") {
                            Haptics.tap()
                            dismiss()
                        }
                    } else {
                        Button("Beenden") {
                            Haptics.tap()
                            if answeredOnce.isEmpty { dismiss() } else { showQuitConfirm = true }
                        }
                    }
                }
            }
            .alert("Lernrunde beenden?", isPresented: $showQuitConfirm) {
                Button("Weiterlernen", role: .cancel) { Haptics.tap() }
                Button("Beenden", role: .destructive) {
                    Haptics.tap()
                    saveResult()
                    dismiss()
                }
            } message: {
                Text("Was du bisher beantwortet hast, ist gespeichert.")
            }
        }
        .onAppear {
            guard !didStart else { return }
            didStart = true
            startSession()
        }
    }

    // MARK: Frage

    private func questionView(_ question: QuizQuestion) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    progressHeader

                    QuizQuestionHeader(question: question)

                    VStack(spacing: 10) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                            Button {
                                answer(index, for: question)
                            } label: {
                                QuizOptionRow(index: index, text: option, state: optionState(index, question))
                            }
                            .buttonStyle(.plain)
                            // Kein `.disabled`: das würde auch die richtige Antwort ausgrauen.
                            // `answer(_:for:)` ignoriert weitere Antippen ohnehin.
                            .keyboardShortcut(KeyEquivalent(Character(QuizOptionRow.letter(index).lowercased())), modifiers: [])
                        }
                    }

                    if let selected = selectedAnswer {
                        QuizExplanationCard(question: question, wasCorrect: selected == question.correctIndex)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))

                        Button {
                            Haptics.tap()
                            nextQuestion()
                        } label: {
                            Text(queue.count == 1 && selected == question.correctIndex ? "Runde abschließen" : "Nächste Frage")
                                .goldButton()
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.return, modifiers: [])
                        .id("next")
                    }
                }
                .padding(isRegular ? 32 : 16)
                .readableWidth()
            }
            .onChange(of: selectedAnswer) { _, new in
                guard new != nil else { return }
                withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo("next", anchor: .bottom) }
            }
        }
    }

    private var progressHeader: some View {
        let done = sessionQuestions.count - queue.count
        return VStack(spacing: 6) {
            HStack {
                Label("\(done) von \(sessionQuestions.count) geschafft", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.gold)
                Spacer()
                if !wrongAnswers.isEmpty {
                    Label("\(wrongAnswers.count) Fehler", systemImage: "arrow.uturn.backward")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            ProgressView(value: Double(done), total: Double(max(sessionQuestions.count, 1)))
                .tint(AppTheme.gold)
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func optionState(_ index: Int, _ question: QuizQuestion) -> QuizOptionState {
        guard let selected = selectedAnswer else { return .idle }
        if index == question.correctIndex { return .correct }
        if index == selected { return .wrong }
        return .dimmed
    }

    // MARK: Abschluss

    private var finishView: some View {
        let counts = store.counts(in: pool)
        let newlyMastered = max(counts.mastered - masteredBefore, 0)
        return ScrollView {
            VStack(spacing: 24) {
                if sessionQuestions.isEmpty {
                    finishHeader(
                        icon: "checkmark.seal.fill",
                        title: Text("Nichts zu wiederholen"),
                        subtitle: Text("Alle Fehler sind ausgebügelt. Starte eine normale Lernrunde oder eine Probeprüfung.")
                    )
                } else {
                    finishHeader(
                        icon: "star.fill",
                        title: Text("Lernrunde geschafft!"),
                        subtitle: Text("\(firstTryCorrect.count) von \(sessionQuestions.count) Fragen auf Anhieb richtig.")
                    )

                    HStack(spacing: 12) {
                        finishTile(value: "+\(newlyMastered)", label: Text("Neu sicher"), color: AppTheme.gold)
                        finishTile(
                            value: "\(Int((counts.readiness * 100).rounded())) %",
                            label: Text("Prüfungsreife"),
                            color: counts.readiness > readinessBefore ? AppTheme.gold : AppTheme.text
                        )
                        finishTile(value: durationString, label: Text("Zeit"), color: AppTheme.text)
                    }
                }

                VStack(spacing: 12) {
                    if !request.mistakesOnly || counts.toRepeat > 0 {
                        Button {
                            Haptics.medium()
                            startSession()
                        } label: {
                            Label("Nächste Lernrunde", systemImage: "arrow.right.circle.fill")
                                .goldButton()
                        }
                        .buttonStyle(.plain)
                    }

                    if !wrongAnswers.isEmpty {
                        Button {
                            Haptics.tap()
                            wrongReviewIndex = 0
                            showWrongReview = true
                        } label: {
                            Label("\(wrongAnswers.count) Fehler noch einmal ansehen", systemImage: "exclamationmark.circle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Text("Fertig")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(AppTheme.text)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(isRegular ? 40 : 20)
            .readableWidth(560)
        }
        .sheet(isPresented: $showWrongReview) {
            WrongAnswerReviewSheet(wrongAnswers: wrongAnswers, currentIndex: $wrongReviewIndex)
        }
    }

    private func finishHeader(icon: String, title: Text, subtitle: Text) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.gold)
                .shadow(color: AppTheme.gold.opacity(0.4), radius: 12, y: 4)
                .padding(.top, 24)
            title
                .font(.title.bold())
                .multilineTextAlignment(.center)
            subtitle
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
        }
    }

    private func finishTile(value: String, label: Text, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(verbatim: value)
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            label
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Ablauf

    private func startSession() {
        let counts = store.counts(in: pool)
        masteredBefore = counts.mastered
        readinessBefore = counts.readiness
        sessionQuestions = store.session(from: pool, mistakesOnly: request.mistakesOnly)
        queue = sessionQuestions
        selectedAnswer = nil
        answeredOnce = []
        firstTryCorrect = []
        wrongAnswers = []
        resultSaved = false
        startTime = .now
        withAnimation { isFinished = sessionQuestions.isEmpty }
    }

    private func answer(_ index: Int, for question: QuizQuestion) {
        guard selectedAnswer == nil else { return }
        let correct = index == question.correctIndex
        correct ? Haptics.success() : Haptics.error()
        withAnimation(.easeOut(duration: 0.2)) { selectedAnswer = index }
        store.record(question, correct: correct)
        if answeredOnce.insert(question.id).inserted {
            if correct {
                firstTryCorrect.insert(question.id)
            } else {
                wrongAnswers.append((question: question, chosen: index))
            }
        }
    }

    private func nextQuestion() {
        guard let question = queue.first else { return }
        queue.removeFirst()
        if selectedAnswer != question.correctIndex {
            queue.insert(question, at: min(3, queue.count))
        }
        selectedAnswer = nil

        if queue.isEmpty {
            Haptics.celebrate()
            saveResult()
            withAnimation { isFinished = true }
        }
    }

    private var durationString: String {
        let seconds = Int(Date().timeIntervalSince(startTime))
        let m = seconds / 60, s = seconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func saveResult() {
        guard !resultSaved, !answeredOnce.isEmpty else { return }
        resultSaved = true
        let duration = Int(Date().timeIntervalSince(startTime))
        context.insert(QuizResult(mode: "smart", score: firstTryCorrect.count, total: answeredOnce.count, durationSeconds: duration))
    }
}

// MARK: - Probeprüfung

struct ExamModeView: View {
    static let questionCount = 30
    static let passMark = 23

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var store = PlatzreifeProgressStore.shared

    /// Als State, damit ein Neuaufbau der Elternansicht nicht mitten in der Prüfung
    /// andere Fragen auslost.
    @State private var examQuestions: [QuizQuestion] = ExamModeView.makeExam()
    @State private var answers: [Int?] = Array(repeating: nil, count: ExamModeView.questionCount)
    @State private var currentIndex = 0
    @State private var timeRemaining = 30 * 60
    @State private var isFinished = false
    @State private var showQuitConfirm = false
    @State private var showSubmitConfirm = false
    @State private var showNavigator = false
    @State private var reviewMode = false
    @State private var reviewIndex = 0
    @State private var startTime = Date()
    @State private var practiceRequest: QuizSessionRequest?

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// 15 Regelfragen (Regeln + Regelanwendung) und 15 allgemeine Fragen, gemischt.
    static func makeExam() -> [QuizQuestion] {
        let half = questionCount / 2
        let rules   = PlatzreifeQuestions.all.filter {  $0.category.isRulesCategory }.shuffled().prefix(half)
        let general = PlatzreifeQuestions.all.filter { !$0.category.isRulesCategory }.shuffled().prefix(half)
        return Array(rules + general).shuffled()
    }

    private var isRegular: Bool { sizeClass == .regular }
    private var correctCount: Int { answers.indices.filter { answers[$0] == examQuestions[$0].correctIndex }.count }
    private var answeredCount: Int { answers.compactMap { $0 }.count }
    private var wrongCount: Int { answers.indices.filter { answers[$0] != nil && answers[$0] != examQuestions[$0].correctIndex }.count }
    private var passed: Bool { correctCount >= Self.passMark }

    var body: some View {
        NavigationStack {
            Group {
                if reviewMode {
                    reviewView
                } else if isFinished {
                    resultView
                } else if isRegular {
                    HStack(spacing: 0) {
                        navigator(showsTitle: true)
                            .frame(width: 300)
                            .background(AppTheme.cardDark)
                        questionView
                    }
                } else {
                    questionView
                }
            }
            .background(AppTheme.bg)
            .navigationTitle("Probeprüfung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Prüfung abbrechen?", isPresented: $showQuitConfirm) {
                Button("Weitermachen", role: .cancel) { Haptics.tap() }
                Button("Abbrechen", role: .destructive) {
                    Haptics.tap()
                    dismiss()
                }
            } message: {
                Text("Das Ergebnis wird nicht gespeichert.")
            }
            .alert("Prüfung abgeben?", isPresented: $showSubmitConfirm) {
                Button("Weiter beantworten", role: .cancel) { Haptics.tap() }
                Button("Abgeben") { submitExam() }
            } message: {
                Text("\(Self.questionCount - answeredCount) Fragen sind noch offen und zählen als falsch.")
            }
            .sheet(isPresented: $showNavigator) {
                NavigationStack {
                    ScrollView { navigator(showsTitle: false) }
                        .background(AppTheme.bg)
                        .navigationTitle("Übersicht")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Fertig") { showNavigator = false }
                            }
                        }
                }
                .presentationDetents([.fraction(0.7), .large])
            }
            .fullScreenCover(item: $practiceRequest) { request in
                PlatzreifeSessionView(request: request)
            }
        }
        .onReceive(ticker) { _ in
            guard !isFinished else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                submitExam()
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if reviewMode {
                Button("Zurück") {
                    Haptics.tap()
                    withAnimation { reviewMode = false }
                }
            } else if !isFinished {
                Button("Abbrechen") {
                    Haptics.tap()
                    showQuitConfirm = true
                }
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if reviewMode || isFinished {
                Button("Schließen") {
                    Haptics.tap()
                    dismiss()
                }
                .fontWeight(.semibold)
            } else {
                // Allein in der Leiste – neben einem zweiten Knopf kürzt iOS die Zeit zu „…“.
                timerBadge
                    .fixedSize()
            }
        }
    }

    private var timerBadge: some View {
        let isLow = timeRemaining < 5 * 60
        return HStack(spacing: 4) {
            Image(systemName: "clock")
            Text(verbatim: String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60))
                .monospacedDigit()
        }
        .font(.caption.bold())
        .foregroundStyle(isLow ? .red : .primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isLow ? Color.red.opacity(0.1) : Color.secondary.opacity(0.1), in: Capsule())
    }

    // MARK: Fragenübersicht

    /// Im Blatt auf dem iPhone steht „Übersicht“ schon in der Titelleiste.
    private func navigator(showsTitle: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                if showsTitle {
                    Text("Übersicht")
                        .font(.headline)
                }
                Text("\(answeredCount) von \(Self.questionCount) beantwortet")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(examQuestions.indices, id: \.self) { index in
                    let answered = answers[index] != nil
                    Button {
                        Haptics.selection()
                        withAnimation { currentIndex = index }
                        showNavigator = false
                    } label: {
                        Text(verbatim: "\(index + 1)")
                            .font(.subheadline.bold())
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .foregroundStyle(answered ? Color(red: 0.10, green: 0.22, blue: 0.13) : AppTheme.text)
                            .background(answered ? AppTheme.gold : AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: index == currentIndex ? 2 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                Haptics.tap()
                showNavigator = false
                requestSubmit()
            } label: {
                Text("Prüfung abgeben")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.gold.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(AppTheme.gold)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(20)
    }

    // MARK: Frage

    private var questionView: some View {
        let question = examQuestions[currentIndex]
        return VStack(spacing: 0) {
            VStack(spacing: 6) {
                HStack {
                    Text("Frage \(currentIndex + 1) von \(Self.questionCount)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textSec)
                    Spacer()
                    Text("\(answeredCount) beantwortet")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                ProgressView(value: Double(answeredCount), total: Double(Self.questionCount))
                    .tint(AppTheme.gold)
            }
            .padding()
            .readableWidth()

            ScrollView {
                VStack(spacing: 20) {
                    QuizQuestionHeader(question: question)

                    VStack(spacing: 10) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                            Button {
                                Haptics.selection()
                                answers[currentIndex] = index
                            } label: {
                                QuizOptionRow(
                                    index: index,
                                    text: option,
                                    state: answers[currentIndex] == index ? .selected : .idle
                                )
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut(KeyEquivalent(Character(QuizOptionRow.letter(index).lowercased())), modifiers: [])
                        }
                    }
                }
                .padding(isRegular ? 32 : 16)
                .readableWidth()
            }

            HStack(spacing: 14) {
                Button("Zurück") {
                    Haptics.selection()
                    withAnimation { currentIndex -= 1 }
                }
                .buttonStyle(.bordered)
                .disabled(currentIndex == 0)
                .keyboardShortcut(.leftArrow, modifiers: [])

                Spacer()

                if !isRegular {
                    Button {
                        Haptics.tap()
                        showNavigator = true
                    } label: {
                        Label("Übersicht", systemImage: "square.grid.3x3.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.gold)

                    Spacer()
                }

                if currentIndex < Self.questionCount - 1 {
                    Button("Weiter") {
                        Haptics.selection()
                        withAnimation { currentIndex += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
                    .keyboardShortcut(.rightArrow, modifiers: [])
                } else {
                    Button("Prüfung abgeben") { requestSubmit() }
                        .buttonStyle(.borderedProminent)
                        .tint(answeredCount == Self.questionCount ? AppTheme.gold : .orange)
                }
            }
            .padding()
            .readableWidth()
            .background(AppTheme.card)
        }
    }

    // MARK: Ergebnis

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 24) {
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

                VStack(spacing: 16) {
                    HStack(spacing: 30) {
                        VStack {
                            Text(verbatim: "\(correctCount)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(passed ? AppTheme.gold : .red)
                            Text("Richtig")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                        }
                        Text(verbatim: "/")
                            .font(.system(size: 36, weight: .thin))
                            .foregroundStyle(AppTheme.textSec)
                        VStack {
                            Text(verbatim: "\(Self.questionCount)")
                                .font(.system(size: 48, weight: .bold))
                            Text("Gesamt")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                        }
                    }

                    VStack(spacing: 6) {
                        HStack {
                            Text(verbatim: "\(Int(Double(correctCount) / Double(Self.questionCount) * 100)) %")
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
                                    .frame(width: geo.size.width * Double(correctCount) / Double(Self.questionCount), height: 12)
                                Rectangle()
                                    .fill(Color.primary.opacity(0.4))
                                    .frame(width: 2, height: 20)
                                    .offset(x: geo.size.width * Double(Self.passMark) / Double(Self.questionCount) - 1, y: -4)
                            }
                        }
                        .frame(height: 12)
                    }

                    categoryBreakdown
                }
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))

                VStack(spacing: 12) {
                    if wrongCount > 0 {
                        Button {
                            Haptics.medium()
                            practiceRequest = QuizSessionRequest(category: nil, mistakesOnly: true)
                        } label: {
                            Label("Fehler jetzt üben", systemImage: "arrow.uturn.backward.circle.fill")
                                .goldButton()
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        Haptics.tap()
                        reviewIndex = 0
                        reviewMode = true
                    } label: {
                        Text("Antworten durchsehen")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(AppTheme.gold)
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Text("Fertig")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(AppTheme.text)
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 20)
            }
            .padding(isRegular ? 32 : 16)
            .readableWidth(620)
        }
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nach Kategorie")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSec)

            ForEach(QuizCategory.allCases, id: \.self) { category in
                let indices = examQuestions.indices.filter { examQuestions[$0].category == category }
                let correct = indices.filter { answers[$0] == examQuestions[$0].correctIndex }.count
                if !indices.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(category.color)
                            .frame(width: 18)
                        Text(verbatim: category.rawValue)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                        Spacer()
                        Text(verbatim: "\(correct)/\(indices.count)")
                            .font(.caption.bold())
                            .foregroundStyle(correct == indices.count ? AppTheme.gold : correct * 2 >= indices.count ? .orange : .red)
                    }
                }
            }
        }
    }

    // MARK: Durchsicht

    private var reviewView: some View {
        let question = examQuestions[reviewIndex]
        let userAnswer = answers[reviewIndex]
        let isCorrect = userAnswer == question.correctIndex
        let statusColor: Color = isCorrect ? AppTheme.gold : (userAnswer == nil ? .secondary : .red)

        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        Label {
                            Text(isCorrect ? "Richtig" : (userAnswer == nil ? "Nicht beantwortet" : "Falsch"))
                        } icon: {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : (userAnswer == nil ? "minus.circle" : "xmark.circle.fill"))
                        }
                        .font(.caption.bold())
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor.opacity(0.12), in: Capsule())

                        Spacer()

                        Text("Frage \(reviewIndex + 1) von \(Self.questionCount)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                    }

                    QuizQuestionHeader(question: question)

                    VStack(spacing: 10) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                            QuizOptionRow(
                                index: index,
                                text: option,
                                state: index == question.correctIndex ? .correct : (index == userAnswer ? .wrong : .dimmed)
                            )
                        }
                    }

                    QuizExplanationCard(question: question)
                }
                .padding(isRegular ? 32 : 16)
                .readableWidth()
            }

            HStack(spacing: 14) {
                Button("Zurück") {
                    Haptics.selection()
                    withAnimation { reviewIndex -= 1 }
                }
                .buttonStyle(.bordered)
                .disabled(reviewIndex == 0)
                .keyboardShortcut(.leftArrow, modifiers: [])

                Spacer()

                if reviewIndex < Self.questionCount - 1 {
                    Button("Nächste") {
                        Haptics.selection()
                        withAnimation { reviewIndex += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
                    .keyboardShortcut(.rightArrow, modifiers: [])
                } else {
                    Button("Fertig") {
                        Haptics.tap()
                        reviewMode = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
                }
            }
            .padding()
            .readableWidth()
            .background(AppTheme.card)
        }
    }

    // MARK: Ablauf

    private func requestSubmit() {
        if answeredCount < Self.questionCount {
            Haptics.warning()
            showSubmitConfirm = true
        } else {
            submitExam()
        }
    }

    private func submitExam() {
        guard !isFinished else { return }
        for (index, question) in examQuestions.enumerated() {
            guard let answer = answers[index] else { continue }
            store.record(question, correct: answer == question.correctIndex)
        }
        let duration = Int(Date().timeIntervalSince(startTime))
        let result = QuizResult(mode: "exam", score: correctCount, total: Self.questionCount, durationSeconds: duration)
        result.passed ? Haptics.celebrate() : Haptics.warning()
        context.insert(result)
        withAnimation { isFinished = true }
    }
}
