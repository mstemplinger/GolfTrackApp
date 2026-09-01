import SwiftUI
import GameKit

// MARK: - Runde abgeschlossen – Teilen-Sheet

struct RoundCompleteSheet: View {
    let round: Round
    var onDismiss: () -> Void

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @ObservedObject private var gc = GameCenterManager.shared
    @StateObject private var playerModel = TrainingPlayerModel()

    @State private var pulse = false
    @State private var showPlayer  = false
    @State private var showPaywall = false

    /// Audio-Lektionen, die zu genau dieser Runde passen (z. B. viele Putts →
    /// Distanzkontrolle). Einmal beim Erscheinen ermittelt, damit die Auswahl
    /// stabil bleibt und die Runde nicht bei jedem Body-Durchlauf ausgewertet wird.
    @State private var audioRecommendations: [TrainingRecommendation] = []

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                        scoreCard

                        if !audioRecommendations.isEmpty {
                            audioTrainingSection
                        }

                        gameCenterSection
                    }
                    .padding(.bottom, 24)
                }

                doneButton
            }
        }
        .sheet(isPresented: $showPlayer) {
            TrainingPlayerSheet(model: playerModel)
        }
        .sheet(isPresented: $showPaywall) {
            TrainingPaywallView()
                .environmentObject(subscriptionManager)
        }
        .onAppear {
            playerModel.onAppear()
            playerModel.isSubscribed = subscriptionManager.isSubscribed
            playerModel.onNeedsSubscription = { showPaywall = true }
            if audioRecommendations.isEmpty {
                audioRecommendations = TrainingRecommender.recommendations(forRound: round)
            }
        }
        .onChange(of: subscriptionManager.isSubscribed) { _, subscribed in
            playerModel.isSubscribed = subscribed
            if !subscribed { playerModel.stop() }
        }
    }

    // MARK: - Header

    private var header: some View {
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
    }

    // MARK: - Score-Karte

    private var scoreCard: some View {
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
    }

    private func scoreBox(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.gold)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
        }
    }

    // MARK: - Audio-Training zur Runde

    private var audioTrainingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "headphones")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.gold)
                Text("Passend zu dieser Runde")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                if !subscriptionManager.isSubscribed {
                    Label("Pro", systemImage: "crown.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.gold.opacity(0.15), in: Capsule())
                }
            }
            Text("Audio-Lektionen, die genau die Schwächen dieser Runde angehen")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)

            VStack(spacing: 0) {
                ForEach(Array(audioRecommendations.enumerated()), id: \.element.id) { i, rec in
                    Button { open(rec) } label: {
                        recommendationRow(rec)
                    }
                    .buttonStyle(.plain)
                    if i < audioRecommendations.count - 1 {
                        Divider().background(AppTheme.cardAlt).padding(.leading, 66)
                    }
                }
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))

            if !subscriptionManager.isSubscribed {
                Button { showPaywall = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                        Text("Alle Audio-Trainings freischalten")
                            .font(.subheadline.bold())
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .opacity(0.6)
                    }
                    .foregroundStyle(AppTheme.gold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.gold.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private func recommendationRow(_ rec: TrainingRecommendation) -> some View {
        let isActive = playerModel.currentLesson?.id == rec.lesson.id

        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(rec.lesson.category.color.opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: rec.lesson.category.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(rec.lesson.category.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(rec.lesson.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                Text(rec.reason)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    if let statLabel = rec.statLabel {
                        Text(statLabel)
                            .font(.caption2.bold())
                            .foregroundStyle(AppTheme.gold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.gold.opacity(0.12), in: Capsule())
                    }
                    Text(rec.lesson.durationLabel)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTer)
                }
                .padding(.top, 1)
            }
            Spacer()
            Image(systemName: playIcon(for: rec, isActive: isActive))
                .font(.system(size: canPlay(rec) ? 26 : 16))
                .foregroundStyle(canPlay(rec) ? rec.lesson.category.color : AppTheme.gold)
        }
        .padding(16)
        .contentShape(Rectangle())
    }

    private func playIcon(for rec: TrainingRecommendation, isActive: Bool) -> String {
        guard canPlay(rec) else { return "crown.fill" }
        return isActive && playerModel.isPlaying ? "pause.circle.fill" : "play.circle.fill"
    }

    /// Erste Lektion ist gratis, alles andere braucht das Training-Abo.
    private func canPlay(_ rec: TrainingRecommendation) -> Bool {
        subscriptionManager.isSubscribed || rec.lesson.id == "01"
    }

    private func open(_ rec: TrainingRecommendation) {
        guard canPlay(rec) else {
            showPaywall = true
            return
        }
        if playerModel.currentLesson?.id != rec.lesson.id {
            playerModel.load(rec.lesson)
        }
        playerModel.play()
        showPlayer = true
    }

    // MARK: - Game Center

    @ViewBuilder
    private var gameCenterSection: some View {
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
    }

    // MARK: - Fertig

    private var doneButton: some View {
        Button {
            // Wiedergabe endet mit dem Sheet – sonst läuft die Lektion unsichtbar weiter.
            playerModel.stop()
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
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(AppTheme.bg)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.1)
                .repeatForever(autoreverses: true)
            ) { pulse = true }
        }
    }
}
