import SwiftUI
import SwiftData

struct RoundsTabView: View {
    @Query(sort: \Round.date, order: .reverse) private var allRounds: [Round]
    @Environment(\.modelContext) private var context
    @State private var showNewRound = false

    private var incompleteRounds: [Round] { allRounds.filter { !$0.isComplete } }
    private var completedRounds:  [Round] { allRounds.filter(\.isComplete) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Runden")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                        Button { showNewRound = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.gold)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // New Round CTA
                            Button { showNewRound = true } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle().fill(AppTheme.gold).frame(width: 46, height: 46)
                                        Image(systemName: "plus")
                                            .font(.title3.bold())
                                            .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Neue Runde starten")
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.text)
                                        Text("Platz & Spielmodus wählen")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSec)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(AppTheme.textTer)
                                }
                                .padding(18)
                                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal)

                            // Active rounds
                            if !incompleteRounds.isEmpty {
                                roundSection(title: "Aktive Runden", icon: "play.circle.fill", color: AppTheme.gold, rounds: incompleteRounds)
                            }

                            // History
                            if !completedRounds.isEmpty {
                                roundSection(title: "Verlauf", icon: "clock.fill", color: AppTheme.textSec, rounds: completedRounds)
                            }

                            // Empty state
                            if allRounds.isEmpty {
                                emptyState
                            }

                            Spacer(minLength: 30)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNewRound) { NewRoundView().preferredColorScheme(.dark) }
        }
    }

    private func roundSection(title: String, icon: String, color: Color, rounds: [Round]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textSec)
            }
            .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(rounds) { round in
                    NavigationLink {
                        if round.isComplete {
                            RoundDetailView(round: round)
                                
                        } else {
                            ScorecardView(round: round)
                                
                        }
                    } label: {
                        DarkRoundRow(round: round)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.slash")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTer)
            Text("Noch keine Runden")
                .font(.headline)
                .foregroundStyle(AppTheme.textSec)
            Text("Starte deine erste Runde und\nverfolge deinen Fortschritt.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textTer)
                .multilineTextAlignment(.center)
            Button { showNewRound = true } label: {
                Label("Erste Runde starten", systemImage: "plus")
                    .goldButton()
                    .padding(.horizontal, 40)
            }
        }
        .padding(40)
    }
}
