import SwiftUI
import WatchKit
import WatchConnectivity

// MARK: - Farbkonstanten (dateiprivat)

private let mgGold   = Color(red: 0.79, green: 0.66, blue: 0.30)
private let mgDarkBg = Color(red: 0.06, green: 0.14, blue: 0.08)
private let mgRowBg  = Color(red: 0.10, green: 0.20, blue: 0.12)

// MARK: - Config

struct WatchMinigolfConfig: Equatable {
    var players: [String]
    var holes: Int
    var scores: [[Int]]
    var currentHole: Int

    static func new(playerCount: Int, holes: Int) -> WatchMinigolfConfig {
        let names = (1...playerCount).map { "Spieler \($0)" }
        return WatchMinigolfConfig(
            players: names,
            holes: holes,
            scores: Array(repeating: Array(repeating: 0, count: holes), count: playerCount),
            currentHole: 0
        )
    }
}

// MARK: - Setup (Löcher + Spielerzahl)

struct WatchMinigolfSetupView: View {
    var onStart: (WatchMinigolfConfig) -> Void

    @State private var holes = 9
    @State private var playerCount = 2

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                section("LÖCHER")
                HStack(spacing: 6) {
                    ForEach([6, 9, 18], id: \.self) { n in
                        pill("\(n)", selected: holes == n) { holes = n }
                    }
                }

                section("SPIELER")
                HStack(spacing: 6) {
                    ForEach(1...4, id: \.self) { n in
                        pill("\(n)", selected: playerCount == n) { playerCount = n }
                    }
                }

                Button {
                    WKInterfaceDevice.current().play(.click)
                    onStart(.new(playerCount: playerCount, holes: holes))
                } label: {
                    Text("Starten")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(mgGold)
                        .foregroundStyle(mgDarkBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .background(mgDarkBg)
    }

    private func section(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private func pill(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            WKInterfaceDevice.current().play(.click)
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(selected ? mgGold : mgRowBg)
                .foregroundStyle(selected ? mgDarkBg : .white)
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scoring (mit Live-Sync zum iPhone)

struct WatchMinigolfScoringView: View {
    let config: WatchMinigolfConfig
    var onExit: () -> Void

    @State private var scores: [[Int]]
    @State private var currentHole: Int
    @State private var showResults = false
    @State private var lastSynced: MinigolfSyncState?
    @ObservedObject private var wc = WatchConnectivityManager.shared

    init(config: WatchMinigolfConfig, onExit: @escaping () -> Void) {
        self.config = config
        self.onExit = onExit
        _scores = State(initialValue: config.scores)
        _currentHole = State(initialValue: config.currentHole)
    }

    private var playerCount: Int { config.players.count }
    private var holeCount: Int { config.holes }
    private func total(_ p: Int) -> Int { scores[p].reduce(0, +) }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                // Kopf: Loch x / n
                HStack {
                    Text("LOCH \(currentHole + 1)/\(holeCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(mgGold)
                    Spacer()
                    Button { showResults = true } label: {
                        Image(systemName: "list.number")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                .padding(.top, 2)

                ForEach(0..<playerCount, id: \.self) { i in
                    playerRow(i)
                }

                // Navigation
                HStack(spacing: 6) {
                    navButton(system: "chevron.left", enabled: currentHole > 0) {
                        if currentHole > 0 { currentHole -= 1 }
                    }
                    if currentHole < holeCount - 1 {
                        navButton(system: "chevron.right", enabled: true, filled: true) {
                            currentHole += 1
                        }
                    } else {
                        Button { showResults = true } label: {
                            Text("Ergebnis")
                                .font(.system(size: 12, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(mgGold)
                                .foregroundStyle(mgDarkBg)
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)

                Button { exit() } label: {
                    Text("Beenden")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .background(mgDarkBg)
        .sheet(isPresented: $showResults) {
            WatchMinigolfResultsView(players: config.players, scores: scores)
        }
        .onAppear { pushToPhone() }
        .onChange(of: scores) { pushToPhone() }
        .onChange(of: currentHole) { pushToPhone() }
        .onChange(of: wc.minigolfState) { _, newValue in applyFromPhone(newValue) }
    }

    // MARK: Rows

    private func playerRow(_ i: Int) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(config.players[i])
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("Σ \(total(i))")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            Button {
                if scores[i][currentHole] > 0 {
                    scores[i][currentHole] -= 1
                    WKInterfaceDevice.current().play(.click)
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(mgRowBg)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text("\(scores[i][currentHole])")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22)

            Button {
                if scores[i][currentHole] < 20 {
                    scores[i][currentHole] += 1
                    WKInterfaceDevice.current().play(.click)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(mgGold)
                    .foregroundStyle(mgDarkBg)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(mgRowBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
    }

    private func navButton(system: String, enabled: Bool, filled: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button {
            action()
            WKInterfaceDevice.current().play(.click)
        } label: {
            Image(systemName: system)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(filled ? mgGold : mgRowBg)
                .foregroundStyle(filled ? mgDarkBg : .white)
                .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }

    // MARK: Sync

    private func currentState(active: Bool) -> MinigolfSyncState {
        MinigolfSyncState(active: active, players: config.players,
                          holes: holeCount, scores: scores, currentHole: currentHole)
    }

    private func pushToPhone() {
        let state = currentState(active: true)
        guard state != lastSynced else { return }
        lastSynced = state
        wc.sendMinigolfState(state)
    }

    private func applyFromPhone(_ newValue: MinigolfSyncState?) {
        guard let s = newValue, s.active,
              s.players == config.players, s.holes == holeCount else {
            if let s = newValue, !s.active, s.players == config.players {
                onExit()
            }
            return
        }
        lastSynced = s
        if scores != s.scores { scores = s.scores }
        if currentHole != s.currentHole { currentHole = s.currentHole }
    }

    private func exit() {
        WKInterfaceDevice.current().play(.click)
        wc.sendMinigolfState(currentState(active: false))
        onExit()
    }
}

// MARK: - Results

struct WatchMinigolfResultsView: View {
    let players: [String]
    let scores: [[Int]]
    @Environment(\.dismiss) private var dismiss

    private var ranked: [(name: String, total: Int)] {
        players.indices
            .map { (players[$0], scores[$0].reduce(0, +)) }
            .sorted { $0.1 < $1.1 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("Ergebnis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(mgGold)
                    .padding(.top, 2)

                ForEach(Array(ranked.enumerated()), id: \.offset) { place, entry in
                    HStack(spacing: 8) {
                        Text(medal(place))
                            .font(.system(size: 13))
                            .frame(width: 22)
                        Text(entry.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text("\(entry.total)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(place == 0 ? mgGold : .white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(mgRowBg.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
                }

                Button { dismiss() } label: {
                    Text("Schließen")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(mgGold)
                        .foregroundStyle(mgDarkBg)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.horizontal, 4)
        }
        .background(mgDarkBg)
    }

    private func medal(_ place: Int) -> String {
        switch place {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(place + 1)."
        }
    }
}
