import SwiftUI

/// Alle gespeicherten Minigolf-Partien – Ziel des „Minigolf-Verlauf"-Buttons
/// auf der Startseite. Der Verlauf liegt in den UserDefaults
/// (`MinigolfGameStore`), nicht in SwiftData; deshalb keine `@Query`.
struct MinigolfHistoryView: View {
    @State private var history: [MinigolfHistoryEntry] = []
    @State private var selectedEntry: MinigolfHistoryEntry?
    @State private var showClearConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if history.isEmpty {
                    emptyState
                } else {
                    statsCard
                    ForEach(history) { entry in
                        Button {
                            Haptics.tap()
                            selectedEntry = entry
                        } label: {
                            row(entry)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                Haptics.warning()
                                delete(entry)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Minigolf-Verlauf")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !history.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Alle löschen", role: .destructive) {
                        Haptics.tap()
                        showClearConfirm = true
                    }
                        .foregroundStyle(.red)
                }
            }
        }
        .confirmationDialog("Ganzen Verlauf löschen?",
                            isPresented: $showClearConfirm,
                            titleVisibility: .visible) {
            Button("Alle Partien löschen", role: .destructive) {
                Haptics.warning()
                withAnimation(.spring(response: 0.3)) {
                    MinigolfGameStore.saveHistory([])
                    history = []
                }
            }
            Button("Abbrechen", role: .cancel) { Haptics.tap() }
        }
        .sheet(item: $selectedEntry) { entry in
            MinigolfResultsView(
                playerNames: entry.playerNames,
                numberOfHoles: entry.numberOfHoles,
                scores: entry.scores,
                challenges: entry.challenges ?? []
            )
            .preferredColorScheme(.dark)
        }
        .onAppear { history = MinigolfGameStore.loadHistory() }
    }

    // MARK: Kopf

    private var statsCard: some View {
        HStack(spacing: 12) {
            stat(title: "Partien", value: "\(history.count)")
            stat(title: "Bester Schnitt", value: bestAverage)
            stat(title: "Asse", value: "\(aces)")
        }
    }

    private func stat(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    /// Bester (niedrigster) Schnitt pro Bahn über alle Partien.
    private var bestAverage: String {
        let averages: [Double] = history.compactMap { entry in
            guard entry.numberOfHoles > 0,
                  let best = entry.scores.map({ $0.reduce(0, +) }).min(), best > 0 else { return nil }
            return Double(best) / Double(entry.numberOfHoles)
        }
        guard let best = averages.min() else { return "–" }
        return String(format: "%.1f", best)
    }

    /// Bahnen, die irgendwer mit einem Schlag gelocht hat.
    private var aces: Int {
        history.reduce(0) { sum, entry in
            sum + entry.scores.reduce(0) { $0 + $1.filter { $0 == 1 }.count }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.gold.opacity(0.6))
            Text("Noch keine Partie gespeichert")
                .font(.headline)
            Text("Sobald du ein Minigolf-Spiel beendest, landet es hier.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Zeile

    private func row(_ entry: MinigolfHistoryEntry) -> some View {
        let totals = entry.scores.map { $0.reduce(0, +) }
        let winner = totals.indices.min(by: { totals[$0] < totals[$1] })
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(winner.map { "🥇 \(entry.playerNames[$0])" } ?? "Partie")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Text("\(entry.playerNames.joined(separator: ", ")) · \(entry.numberOfHoles) Bahnen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    if let courseName = entry.courseName {
                        Label(courseName, systemImage: "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(winner.map { "\(totals[$0])" } ?? "–")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.gold)
                    Text("\(entry.date.formatted(date: .abbreviated, time: .shortened)) Uhr")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func delete(_ entry: MinigolfHistoryEntry) {
        withAnimation(.spring(response: 0.3)) {
            history.removeAll { $0.id == entry.id }
            MinigolfGameStore.saveHistory(history)
        }
    }
}

#Preview {
    NavigationStack { MinigolfHistoryView() }
        .preferredColorScheme(.dark)
}
