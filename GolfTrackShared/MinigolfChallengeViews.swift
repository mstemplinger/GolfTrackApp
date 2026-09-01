import SwiftUI

// MARK: - Auswahl

/// Liste zum An- und Abwählen der Wettkämpfe. Wird beim Einrichten der Runde
/// und im Sheet während der Runde verwendet.
struct MinigolfChallengeSelectionList: View {
    @Binding var selection: [MinigolfChallenge]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(MinigolfChallenge.allCases) { challenge in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        toggle(challenge)
                    }
                } label: {
                    row(challenge)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggle(_ challenge: MinigolfChallenge) {
        if let index = selection.firstIndex(of: challenge) {
            selection.remove(at: index)
        } else {
            selection.append(challenge)
        }
    }

    private func row(_ challenge: MinigolfChallenge) -> some View {
        let isOn = selection.contains(challenge)
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: challenge.sfSymbol)
                .font(.subheadline)
                .foregroundStyle(isOn ? .white : AppTheme.gold)
                .frame(width: 30, height: 30)
                .background(isOn ? AppTheme.gold : AppTheme.gold.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(challenge.displayName)
                    .font(.subheadline.bold())
                Text(challenge.rule)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isOn ? AppTheme.gold : Color.secondary.opacity(0.4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            isOn ? AppTheme.gold.opacity(0.12) : AppTheme.cardAlt,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isOn ? AppTheme.gold.opacity(0.5) : .clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

/// Karte für den Einrichten-Bildschirm.
struct MinigolfChallengeSetupCard: View {
    @Binding var selection: [MinigolfChallenge]
    /// Eingeklappt starten (im QR-Ablauf soll die Karte nicht dominieren).
    @State private var isExpanded: Bool

    init(selection: Binding<[MinigolfChallenge]>, initiallyExpanded: Bool = true) {
        self._selection = selection
        self._isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Label("Wettkämpfe", systemImage: "trophy.fill")
                        .font(.headline)
                    Spacer()
                    if !selection.isEmpty {
                        Text("\(selection.count)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(AppTheme.gold, in: Circle())
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text("Nebenwertungen zusätzlich zur Schlagzahl – jede hat ihren eigenen Sieger. Lässt sich auch während der Runde noch ändern.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                MinigolfChallengeSelectionList(selection: $selection)
            } else if !selection.isEmpty {
                Text(selection.map(\.displayName).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Wettkämpfe mitten in der Runde ändern.
struct MinigolfChallengeSheet: View {
    @Binding var selection: [MinigolfChallenge]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Wettkämpfe zählen immer über die ganze Runde – auch wenn du sie erst jetzt einschaltest.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    MinigolfChallengeSelectionList(selection: $selection)
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Wettkämpfe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
    }
}

// MARK: - Live-Stand während der Runde

struct MinigolfChallengeLiveCard: View {
    let playerNames: [String]
    let scores: [[Int]]
    let challenges: [MinigolfChallenge]
    var onEdit: (() -> Void)? = nil

    private var results: [MinigolfChallengeResult] {
        MinigolfChallengeEngine.results(for: challenges, scores: scores, names: playerNames)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Wettkämpfe", systemImage: "trophy.fill")
                    .font(.subheadline.bold())
                Spacer()
                if let onEdit {
                    Button("Ändern") { onEdit() }
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.gold)
                        .buttonStyle(.plain)
                }
            }

            VStack(spacing: 6) {
                ForEach(results) { result in
                    HStack(spacing: 8) {
                        Text(result.challenge.trophy)
                            .font(.caption)
                        Text(result.challenge.displayName)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 4)
                        if let value = result.leaderValueText {
                            Text(result.leaderNames)
                                .font(.caption.bold())
                                .lineLimit(1)
                            Text(value)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AppTheme.gold)
                        } else {
                            Text("noch offen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Pokale im Ergebnis

struct MinigolfAwardsCard: View {
    let playerNames: [String]
    let scores: [[Int]]
    let challenges: [MinigolfChallenge]

    private var results: [MinigolfChallengeResult] {
        MinigolfChallengeEngine.results(for: challenges, scores: scores, names: playerNames)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pokale").font(.headline)

            VStack(spacing: 10) {
                ForEach(results) { result in
                    awardRow(result)
                }
            }
        }
    }

    private func awardRow(_ result: MinigolfChallengeResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(result.challenge.trophy)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.challenge.displayName)
                        .font(.subheadline.bold())
                    if result.leaders.isEmpty {
                        Text("Kein Sieger – niemand hat es geschafft.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(result.leaders.count > 1
                             ? "Geteilt: \(result.leaderNames)"
                             : result.leaderNames)
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.gold)
                    }
                }
                Spacer(minLength: 0)
                if let value = result.leaderValueText {
                    Text(value)
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(AppTheme.gold)
                }
            }

            // Vollständige Wertung, damit man den Abstand sieht
            VStack(spacing: 3) {
                ForEach(result.standings) { standing in
                    HStack(spacing: 8) {
                        Text(standing.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(result.valueText(for: standing))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading, 2)
        }
        .padding(12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            MinigolfChallengeLiveCard(
                playerNames: ["Tobi", "Lisa", "Max"],
                scores: [[2, 1, 2, 3], [3, 2, 2, 2], [4, 3, 1, 1]],
                challenges: [.streak, .aces, .holeWins],
                onEdit: {}
            )
            MinigolfAwardsCard(
                playerNames: ["Tobi", "Lisa", "Max"],
                scores: [[2, 1, 2, 3], [3, 2, 2, 2], [4, 3, 1, 1]],
                challenges: [.streak, .aces, .holeWins, .steady]
            )
        }
        .padding()
    }
    .appBackground()
    .preferredColorScheme(.dark)
}
