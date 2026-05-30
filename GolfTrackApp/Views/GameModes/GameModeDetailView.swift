import SwiftUI

extension GameMode: Identifiable {
    var id: String { rawValue }
}

struct GameModeDetailView: View {
    let mode: GameMode
    @Environment(\.dismiss) private var dismiss
    @State private var showNewRound = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    AppTheme.gold.opacity(0.15)
                    Image(systemName: mode.sfSymbol)
                        .font(.system(size: 80))
                        .foregroundStyle(AppTheme.gold)
                }
                .frame(height: 180)

                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.displayName)
                                .font(.title2.bold())
                            if !mode.subtitle.isEmpty {
                                Text(mode.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Image(systemName: mode.category.icon)
                                .foregroundStyle(.secondary)
                            Text(categoryLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    Text(mode.description)
                        .font(.body)
                        .lineSpacing(4)

                    if mode == .stableford { stablefordTable }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationTitle(mode.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Schließen") { dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if mode.isAvailable {
                Button { showNewRound = true } label: {
                    Label("Runde starten – \(mode.displayName)", systemImage: "flag.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.gold)
                .padding()
                .background(.background)
            } else {
                HStack {
                    Image(systemName: "clock.badge").foregroundStyle(.orange)
                    Text("Dieses Spielformat wird bald verfügbar sein.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.background)
            }
        }
        .sheet(isPresented: $showNewRound) {
            NewRoundView(preselectedMode: mode)
        }
    }

    private var categoryLabel: String {
        switch mode.category {
        case .individual: return "Individuell"
        case .partner: return "Partner"
        case .team: return "Team"
        }
    }

    private var stablefordTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Punktetabelle").font(.headline)
            VStack(spacing: 0) {
                tableRow(name: "Albatross", diff: -3, points: 5)
                Divider()
                tableRow(name: "Eagle",     diff: -2, points: 4)
                Divider()
                tableRow(name: "Birdie",    diff: -1, points: 3)
                Divider()
                tableRow(name: "Par",       diff:  0, points: 2)
                Divider()
                tableRow(name: "Bogey",     diff:  1, points: 1)
                Divider()
                tableRow(name: "Double+",   diff:  2, points: 0)
            }
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func tableRow(name: String, diff: Int, points: Int) -> some View {
        HStack {
            Text(name).font(.subheadline)
            Spacer()
            Text(diff < 0 ? "\(diff)" : diff == 0 ? "E" : "+\(diff)")
                .font(.caption).foregroundStyle(.secondary)
            Text("\(points) Pkt.")
                .font(.subheadline.bold())
                .foregroundStyle(points >= 3 ? AppTheme.gold : points == 0 ? .secondary : .primary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
