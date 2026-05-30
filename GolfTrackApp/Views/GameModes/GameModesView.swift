import SwiftUI

struct GameModesView: View {
    @State private var unavailableMode: GameMode?

    private let categories: [GameModeCategory] = [.individual, .partner, .team]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(categories, id: \.rawValue) { category in
                        VStack(spacing: 0) {
                            sectionHeader(category)
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                                spacing: 12
                            ) {
                                ForEach(modes(for: category), id: \.rawValue) { mode in
                                    if mode.isAvailable {
                                        NavigationLink {
                                            GameModeDetailView(mode: mode)
                                        } label: {
                                            ModeCard(mode: mode)
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        ModeCard(mode: mode)
                                            .onTapGesture { unavailableMode = mode }
                                    }
                                }
                            }
                            .padding(12)
                        }
                    }
                }
            }
            .navigationTitle("Spielmodi")
            .sheet(item: $unavailableMode) { mode in
                unavailableSheet(mode: mode)
            }
        }
    }

    private func sectionHeader(_ category: GameModeCategory) -> some View {
        HStack {
            Text(category.rawValue.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: category.icon)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.gold)
    }

    private func modes(for category: GameModeCategory) -> [GameMode] {
        GameMode.allCases.filter { $0.category == category }
    }

    private func unavailableSheet(mode: GameMode) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: mode.sfSymbol)
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
                Text(mode.displayName)
                    .font(.title2.bold())
                Text(mode.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge")
                        .foregroundStyle(.orange)
                    Text("Dieser Spielmodus kommt bald")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
                .padding(.top, 8)
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { unavailableMode = nil }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Mode Card

struct ModeCard: View {
    let mode: GameMode

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: mode.sfSymbol)
                    .font(.system(size: 36))
                    .foregroundStyle(mode.isAvailable ? AppTheme.gold : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                if !mode.isAvailable {
                    Text("Bald")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.orange, in: Capsule())
                        .padding(.trailing, 8)
                        .padding(.top, 4)
                }
            }

            VStack(spacing: 2) {
                Text(mode.displayName)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
                if !mode.subtitle.isEmpty {
                    Text(mode.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(mode.isAvailable ? AppTheme.gold.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}
