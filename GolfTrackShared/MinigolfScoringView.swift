import SwiftUI

/// Die Zählkarte und das Ergebnis – der Teil, den auch der App Clip zeigt.
///
/// Was im Clip fehlt, steht hinter `#if !APPCLIP`:
/// - **Werbung**, weil Apple sie dort untersagt (Richtlinie 2.5.16(a)).
/// - **Watch-Abgleich**, weil ein Clip keine Uhr-Gegenstelle hat und
///   `WatchConnectivity` dort nichts zu suchen hat.
///
/// Das Flag setzt das Clip-Ziel in `SWIFT_ACTIVE_COMPILATION_CONDITIONS`.

// MARK: - Scoring

struct MinigolfScoringView: View {
    let config: MinigolfConfig
    @State private var scores: [[Int]]
    @State private var currentHole = 0
    @State private var showResults = false
    @State private var challenges: [MinigolfChallenge]
    @State private var showChallenges = false
    @Environment(\.dismiss) private var dismiss
    #if !APPCLIP
    /// Zuletzt mit der Watch abgeglichener Zustand – verhindert Echo-Schleifen
    @State private var lastSynced: MinigolfSyncState?
    @ObservedObject private var wc = WatchConnectivityManager.shared
    #endif

    init(config: MinigolfConfig) {
        self.config = config
        _scores = State(initialValue:
            config.initialScores
                ?? Array(repeating: Array(repeating: 0, count: config.numberOfHoles),
                         count: config.playerNames.count)
        )
        _currentHole = State(initialValue: config.initialHole)
        _challenges = State(initialValue: config.challenges)
    }

    private var playerCount: Int { config.playerNames.count }
    private var holeCount: Int { config.numberOfHoles }

    private func total(for player: Int) -> Int {
        scores[player].reduce(0, +)
    }

    private var sortedPlayerIndices: [Int] {
        (0..<playerCount).sorted { total(for: $0) < total(for: $1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(0..<playerCount, id: \.self) { i in
                        playerCard(for: i)
                    }

                    if challenges.isEmpty {
                        addChallengesButton
                    } else {
                        MinigolfChallengeLiveCard(
                            playerNames: config.playerNames,
                            scores: scores,
                            challenges: challenges,
                            onEdit: { showChallenges = true }
                        )
                    }

                    #if !APPCLIP
                    MinigolfAdSlotView(courseID: config.courseID, rotation: currentHole)
                    #endif
                }
                .padding()
            }
            bottomNav
        }
        .appBackground()
        .navigationTitle("Loch \(currentHole + 1) / \(holeCount)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ergebnis") { showResults = true }
                    .foregroundStyle(AppTheme.gold)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showChallenges = true } label: {
                    Image(systemName: challenges.isEmpty ? "trophy" : "trophy.fill")
                }
                .foregroundStyle(AppTheme.gold)
            }
        }
        .sheet(isPresented: $showResults) {
            MinigolfResultsView(
                playerNames: config.playerNames,
                numberOfHoles: holeCount,
                scores: scores,
                challenges: challenges,
                onFinish: finishGame
            )
        }
        .sheet(isPresented: $showChallenges) {
            MinigolfChallengeSheet(selection: $challenges)
        }
        .onAppear { persist(); pushToWatch() }
        .onChange(of: scores) { persist(); pushToWatch() }
        .onChange(of: currentHole) { persist(); pushToWatch() }
        .onChange(of: challenges) { persist(); MinigolfGameStore.saveChallenges(challenges) }
        #if !APPCLIP
        // Live-Update von der Watch übernehmen
        .onChange(of: wc.minigolfState) { _, newValue in applyFromWatch(newValue) }
        .task { await AdCatalogService.shared.refreshIfNeeded() }
        .onDisappear {
            // Spiel auf dem iPhone verlassen → Watch informieren
            wc.sendMinigolfState(currentState(active: false))
            // Gesammelte Werbezähler abschicken – einmal je Runde statt bei
            // jeder Bahn.
            Task { await AdCatalogService.shared.flushCounters() }
        }
        #endif
    }

    #if !APPCLIP
    private func currentState(active: Bool) -> MinigolfSyncState {
        MinigolfSyncState(active: active,
                          players: config.playerNames,
                          holes: holeCount,
                          scores: scores,
                          currentHole: currentHole)
    }

    /// Sendet den aktuellen Stand an die Watch – aber nur, wenn er sich seit
    /// dem letzten Abgleich tatsächlich geändert hat (kein Echo).
    private func pushToWatch() {
        let state = currentState(active: true)
        guard state != lastSynced else { return }
        lastSynced = state
        wc.sendMinigolfState(state)
    }

    private func applyFromWatch(_ newValue: MinigolfSyncState?) {
        guard let s = newValue, s.active,
              s.players == config.playerNames, s.holes == holeCount else {
            // Watch hat das Spiel beendet → mitziehen
            if let s = newValue, !s.active, s.players == config.playerNames {
                dismiss()
            }
            return
        }
        // Als bereits abgeglichen markieren, damit das folgende onChange nicht zurücksendet
        lastSynced = s
        if scores != s.scores { scores = s.scores }
        if currentHole != s.currentHole { currentHole = s.currentHole }
    }
    #else
    /// Ohne Uhr am anderen Ende gibt es nichts abzugleichen.
    private func pushToWatch() {}
    #endif

    private func persist() {
        MinigolfGameStore.save(SavedMinigolfGame(
            playerNames: config.playerNames,
            numberOfHoles: holeCount,
            scores: scores,
            currentHole: currentHole,
            savedAt: Date(),
            courseName: config.courseName,
            courseID: config.courseID,
            challenges: challenges
        ))
    }

    private func finishGame() {
        MinigolfGameStore.appendToHistory(MinigolfHistoryEntry(
            date: Date(),
            playerNames: config.playerNames,
            numberOfHoles: holeCount,
            scores: scores,
            courseName: config.courseName,
            challenges: challenges
        ))
        MinigolfGameStore.clear()
        #if !APPCLIP
        wc.sendMinigolfState(currentState(active: false))
        #endif
        showResults = false
        dismiss()
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(.secondary.opacity(0.15))
                Rectangle()
                    .fill(AppTheme.gold)
                    .frame(width: geo.size.width * CGFloat(currentHole + 1) / CGFloat(holeCount))
                    .animation(.easeInOut(duration: 0.25), value: currentHole)
            }
        }
        .frame(height: 3)
    }

    private func playerCard(for i: Int) -> some View {
        let rank = sortedPlayerIndices.firstIndex(of: i) ?? i
        return HStack(spacing: 12) {
            Text("\(rank + 1)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(rankColor(rank), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(config.playerNames[i]).font(.headline)
                Text("Gesamt: \(total(for: i))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            HStack(spacing: 4) {
                Button {
                    if scores[i][currentHole] > 0 { scores[i][currentHole] -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(scores[i][currentHole] > 0 ? AppTheme.gold : Color.secondary.opacity(0.35))
                }
                .buttonStyle(.plain)

                Text("\(scores[i][currentHole])")
                    .font(.title.bold())
                    .monospacedDigit()
                    .frame(width: 40, alignment: .center)

                Button {
                    if scores[i][currentHole] < 20 { scores[i][currentHole] += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.gold)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    /// Hinweis, solange keine Nebenwertung läuft – man kann sie mitten in der
    /// Runde noch dazunehmen, gewertet wird dann trotzdem ab Bahn 1.
    private var addChallengesButton: some View {
        Button { showChallenges = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(AppTheme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wettkampf dazunehmen")
                        .font(.subheadline.bold())
                    Text("Serie, Asse, Bahnenduell – zählt rückwirkend ab Bahn 1.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 0: return Color(red: 0.85, green: 0.65, blue: 0.1)
        case 1: return .gray
        case 2: return Color(red: 0.72, green: 0.45, blue: 0.2)
        default: return .secondary
        }
    }

    private var bottomNav: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { currentHole -= 1 }
            } label: {
                Label("Zurück", systemImage: "chevron.left")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(currentHole == 0)
            .opacity(currentHole == 0 ? 0.3 : 1)
            .buttonStyle(.plain)

            if currentHole < holeCount - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { currentHole += 1 }
                } label: {
                    HStack(spacing: 6) {
                        Text("Weiter")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            } else {
                Button { showResults = true } label: {
                    Text("Ergebnis")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(AppTheme.bg)
    }
}

// MARK: - Results

struct MinigolfResultsView: View {
    let playerNames: [String]
    let numberOfHoles: Int
    let scores: [[Int]]
    var challenges: [MinigolfChallenge] = []
    var onFinish: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    private func total(for player: Int) -> Int {
        scores[player].reduce(0, +)
    }

    private var ranked: [(index: Int, name: String, total: Int)] {
        (0..<playerNames.count)
            .map { i in (i, playerNames[i], total(for: i)) }
            .sorted { $0.total < $1.total }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    rankingList

                    if !challenges.isEmpty {
                        MinigolfAwardsCard(playerNames: playerNames,
                                           scores: scores,
                                           challenges: challenges)
                    }

                    scorecardTable

                    if let onFinish {
                        Button { onFinish() } label: {
                            Label("Spiel beenden & speichern", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Ergebnis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private var rankingList: some View {
        VStack(spacing: 0) {
            ForEach(Array(ranked.enumerated()), id: \.offset) { place, entry in
                HStack(spacing: 12) {
                    Text(medal(for: place))
                        .font(place < 3 ? .title2 : .body)
                        .frame(width: 36)
                    Text(entry.name).font(.headline)
                    Spacer()
                    Text("\(entry.total)")
                        .font(.headline.bold())
                        .monospacedDigit()
                        .foregroundStyle(place == 0 ? Color(red: 0.85, green: 0.65, blue: 0.1) : .primary)
                    Text("Schl.").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                if place < ranked.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func medal(for place: Int) -> String {
        switch place {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(place + 1)."
        }
    }

    private var scorecardTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scorecard").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Spieler")
                            .frame(width: 80, alignment: .leading)
                            .font(.caption.bold())
                        ForEach(0..<numberOfHoles, id: \.self) { h in
                            Text("\(h + 1)")
                                .frame(width: 28)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("∑")
                            .frame(width: 36, alignment: .trailing)
                            .font(.caption.bold())
                    }
                    .frame(height: 26)

                    Divider()

                    ForEach(Array(ranked.enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: 0) {
                            Text(entry.name)
                                .frame(width: 80, alignment: .leading)
                                .font(.caption)
                                .lineLimit(1)
                            ForEach(0..<numberOfHoles, id: \.self) { h in
                                let s = scores[entry.index][h]
                                Text(s == 0 ? "–" : "\(s)")
                                    .frame(width: 28)
                                    .font(.caption)
                                    .foregroundStyle(s == 1 ? AppTheme.gold : (s == 0 ? .secondary : .primary))
                            }
                            Text("\(entry.total)")
                                .frame(width: 36, alignment: .trailing)
                                .font(.caption.bold())
                        }
                        .frame(height: 28)
                    }
                }
                .padding(12)
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

