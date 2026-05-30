import SwiftUI
import GameKit

// MARK: - Runde abgeschlossen – Teilen-Sheet

struct RoundCompleteSheet: View {
    let round: Round
    var onDismiss: () -> Void

    @ObservedObject private var gc = GameCenterManager.shared
    @State private var pulse = false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 20) {

                // ── Header ─────────────────────────────────────────
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.gold.opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(AppTheme.gold)
                    }
                    .padding(.top, 32)
                    Text("Runde abgeschlossen!")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.text)
                    if let course = round.course {
                        Text(course.name)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSec)
                    }
                }

                // ── Score-Karte ─────────────────────────────────────
                HStack(spacing: 24) {
                    scoreBox(value: "\(round.totalStrokes)", label: "Schläge")
                    if round.totalPutts > 0 {
                        Divider().frame(height: 40)
                        scoreBox(value: "\(round.totalPutts)", label: "Putts")
                    }
                    Divider().frame(height: 40)
                    scoreBox(value: "\(round.holeScores.count)", label: "Löcher")
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // ── Game Center Aktionen ────────────────────────────
                if gc.isAuthenticated {
                    VStack(spacing: 10) {
                        // Bestenliste anzeigen
                        Button {
                            gc.showLeaderboard()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "list.number")
                                    .font(.system(size: 16, weight: .semibold))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Bestenliste")
                                        .font(.subheadline.bold())
                                    Text("Vergleiche dich mit Freunden")
                                        .font(.caption)
                                        .opacity(0.7)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .opacity(0.5)
                            }
                            .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)

                        // Game Center Dashboard
                        Button {
                            gc.showGameCenter()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 15))
                                Text("Game Center öffnen")
                                    .font(.subheadline.bold())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .opacity(0.5)
                            }
                            .foregroundStyle(AppTheme.text)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Nicht eingeloggt – Hinweis
                    HStack(spacing: 10) {
                        Image(systemName: "gamecontroller")
                            .foregroundStyle(AppTheme.textTer)
                        Text("Melde dich bei Game Center an, um deinen Score mit Freunden zu teilen.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(14)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                Spacer()

                // ── Fertig ─────────────────────────────────────────
                Button {
                    onDismiss()
                } label: {
                    Text("Fertig")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            AppTheme.gold.opacity(pulse ? 1.0 : 0.7),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(.black)
                        .scaleEffect(pulse ? 1.03 : 1.0)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.1)
                        .repeatForever(autoreverses: true)
                    ) { pulse = true }
                }
            }
        }
    }

    private func scoreBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.gold)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
        }
    }
}
