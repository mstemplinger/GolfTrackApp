import SwiftUI

struct GameModePickerView: View {
    @Binding var selectedMode: GameMode
    @Environment(\.dismiss) private var dismiss

    @State private var showDetail: GameMode?

    private let availableModes = GameMode.allCases.filter(\.isAvailable)

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            List {
                ForEach(availableModes, id: \.rawValue) { mode in
                    HStack(spacing: 0) {
                        Button {
                            selectedMode = mode
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(selectedMode == mode ? AppTheme.gold.opacity(0.15) : AppTheme.cardAlt)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: mode.sfSymbol)
                                        .font(.system(size: 17))
                                        .foregroundStyle(selectedMode == mode ? AppTheme.gold : AppTheme.textSec)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(mode.displayName)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.text)
                                    Text(shortDesc(mode))
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSec)
                                }
                                Spacer()
                                if selectedMode == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.gold)
                                        .font(.title3)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Button {
                            showDetail = mode
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.body)
                                .foregroundStyle(AppTheme.textSec)
                                .padding(.horizontal, 12)
                                .frame(height: 44)
                        }
                        .buttonStyle(.borderless)
                    }
                    .listRowBackground(selectedMode == mode ? AppTheme.gold.opacity(0.10) : AppTheme.card)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Spielmodus wählen")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $showDetail) { mode in
                NavigationStack { GameModeDetailView(mode: mode) }
            }
        }
    }

    private func shortDesc(_ mode: GameMode) -> String {
        switch mode {
        case .strokePlay:          return "Klassisches Zählspiel – jeder Schlag zählt"
        case .stableford:          return "Punkte statt Schläge – Birdie=3, Par=2, Bogey=1"
        case .matchplay:           return "Loch für Loch gegen einen Gegner"
        case .skins:               return "Niedrigster Score gewinnt den Skin – Unentschieden trägt über"
        case .erado:               return "Zählspiel – die schlechtesten Löcher werden gestrichen"
        case .betterBallStroke:    return "Bester Score pro Loch zählt für das 2er-Team"
        case .betterBallStableford: return "Beste Stableford-Punkte pro Loch für das Team"
        case .scramble2Mann:       return "Beide schlagen ab – bester Abschlag wird gespielt"
        case .vierer:              return "Ein Ball, zwei Spieler – abwechselnd schlagen"
        case .greensome:           return "Beide schlagen ab, bester Teeshot – dann Wechselschlag"
        case .betterBallMatchplay: return "2 gegen 2 – bester Ball pro Team, Matchplay-Wertung"
        case .bestBallStroke:      return "3–4 Spieler – bester Score pro Loch zählt"
        case .bestBallStableford:  return "3–4 Spieler – beste Stableford-Punkte pro Loch"
        case .scrambleTeam:        return "3–4 Spieler – alle schlagen ab, bester Abschlag gespielt"
        default:                   return String(mode.description.prefix(60))
        }
    }
}
