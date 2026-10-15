import SwiftUI

/// Sheet that shows all incorrectly answered questions from a Smart-Mode session,
/// with the correct answer highlighted and an explanation.
struct WrongAnswerReviewSheet: View {
    let wrongAnswers: [(question: QuizQuestion, chosen: Int)]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    private var current: (question: QuizQuestion, chosen: Int)? {
        guard wrongAnswers.indices.contains(currentIndex) else { return nil }
        return wrongAnswers[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                if let item = current {
                    VStack(spacing: 0) {
                        progressHeader
                        ScrollView {
                            questionCard(item: item)
                                .padding()
                                .readableWidth()
                        }
                        navigationBar
                    }
                }
            }
            .navigationTitle("Falsche Antworten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        Haptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.gold)
                }
            }
        }
    }

    // MARK: - Progress

    private var progressHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(currentIndex + 1) von \(wrongAnswers.count) falsch beantwortet")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSec)
                Spacer()
            }
            ProgressView(value: Double(currentIndex + 1), total: Double(wrongAnswers.count))
                .tint(.orange)
        }
        .padding()
        .background(AppTheme.card)
    }

    // MARK: - Question Card

    private func questionCard(item: (question: QuizQuestion, chosen: Int)) -> some View {
        let q = item.question
        return VStack(alignment: .leading, spacing: 18) {
            QuizQuestionHeader(question: q)

            VStack(spacing: 10) {
                ForEach(Array(q.options.enumerated()), id: \.offset) { idx, option in
                    QuizOptionRow(
                        index: idx,
                        text: option,
                        state: idx == q.correctIndex ? .correct : (idx == item.chosen ? .wrong : .dimmed)
                    )
                }
            }

            QuizExplanationCard(question: q)
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack(spacing: 14) {
            if currentIndex > 0 {
                Button("Zurück") {
                    Haptics.selection()
                    withAnimation { currentIndex -= 1 }
                }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.leftArrow, modifiers: [])
            }
            Spacer()
            if currentIndex < wrongAnswers.count - 1 {
                Button("Nächste") {
                    Haptics.selection()
                    withAnimation { currentIndex += 1 }
                }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
                    .keyboardShortcut(.rightArrow, modifiers: [])
            } else {
                Button("Fertig") {
                    Haptics.tap()
                    dismiss()
                }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
            }
        }
        .padding()
        .background(AppTheme.card)
    }
}
