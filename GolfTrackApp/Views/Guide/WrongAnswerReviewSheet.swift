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
                        }
                        navigationBar
                    }
                }
            }
            .navigationTitle("Falsche Antworten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
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
        let chosen = item.chosen

        return VStack(alignment: .leading, spacing: 16) {
            // Category badge
            Label(q.category.rawValue, systemImage: q.category.icon)
                .font(.caption.bold())
                .foregroundStyle(q.category.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(q.category.color.opacity(0.12), in: Capsule())

            // Question
            Text(q.question)
                .font(.title3.bold())
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Answer options
            VStack(spacing: 10) {
                ForEach(Array(q.options.enumerated()), id: \.offset) { idx, option in
                    let isRight   = idx == q.correctIndex
                    let wasChosen = idx == chosen

                    HStack(spacing: 12) {
                        Text(["A", "B", "C", "D"][idx])
                            .font(.caption.bold())
                            .frame(width: 28, height: 28)
                            .background(
                                isRight ? AppTheme.gold : wasChosen ? Color.red : Color.secondary.opacity(0.2),
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
                        isRight ? AppTheme.gold.opacity(0.08) : wasChosen ? Color.red.opacity(0.08) : AppTheme.card,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isRight ? AppTheme.gold.opacity(0.5) : wasChosen ? Color.red.opacity(0.3) : Color.secondary.opacity(0.15),
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
            .background(AppTheme.gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack(spacing: 14) {
            if currentIndex > 0 {
                Button("Zurück") { withAnimation { currentIndex -= 1 } }
                    .buttonStyle(.bordered)
            }
            Spacer()
            if currentIndex < wrongAnswers.count - 1 {
                Button("Nächste") { withAnimation { currentIndex += 1 } }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
            } else {
                Button("Fertig") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
            }
        }
        .padding()
        .background(AppTheme.card)
    }
}
