import SwiftUI

/// Die Putt-Lektionen aus dem Training, direkt im Minigolf-Bereich.
///
/// Sichtbar nur mit dem Trainings-Abo. Das ist die Gegenleistung an der
/// gleichen Stelle, an der ohne Abo die Werbefläche steht
/// (`MinigolfAdSlotView` blendet sich für Abonnenten aus): Wer zahlt, bekommt
/// dort sein Putt-Training statt einer Anzeige.
struct PuttTrainingCard: View {
    /// Schmale Variante für die laufende Zählkarte.
    var compact: Bool = false

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var showLessons = false

    var body: some View {
        if subscriptionManager.isTrainingSubscribed && !PuttTraining.lessons.isEmpty {
            Button {
                Haptics.tap()
                showLessons = true
            } label: {
                if compact { compactLabel } else { fullLabel }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showLessons) {
                PuttTrainingSheet()
                    .environmentObject(subscriptionManager)
                    .preferredColorScheme(.dark)
            }
        }
    }

    private var badge: some View {
        Text("Im Abo")
            .font(.caption2.bold())
            .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(AppTheme.gold, in: Capsule())
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.gold.opacity(0.16))
            Image(systemName: "headphones")
                .font(.title3)
                .foregroundStyle(AppTheme.gold)
        }
        .frame(width: 44, height: 44)
    }

    private var compactLabel: some View {
        HStack(spacing: 12) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Putt-Training")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.text)
                    badge
                }
                Text("\(PuttTraining.lessons.count) Audios zum Putten – zwischen zwei Bahnen anhören")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.cardDark, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.gold.opacity(0.22), lineWidth: 1))
        .contentShape(Rectangle())
    }

    private var fullLabel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                icon
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Putt-Training")
                            .font(.headline)
                            .foregroundStyle(AppTheme.text)
                        badge
                    }
                    Text("Distanzkontrolle und Grün lesen – die Putt-Lektionen aus dem Training.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(PuttTraining.lessons) { lesson in
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.gold)
                        Text(lesson.title)
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                        Text(lesson.durationLabel)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSec)
                        Spacer(minLength: 0)
                    }
                }

                HStack(spacing: 4) {
                    Spacer(minLength: 0)
                    Text("Anhören")
                        .font(.caption.bold())
                    Image(systemName: "chevron.right")
                        .font(.caption2.bold())
                }
                .foregroundStyle(AppTheme.gold)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.gold.opacity(0.22), lineWidth: 1))
        .contentShape(Rectangle())
    }
}

// MARK: - Lektionen

enum PuttTraining {
    /// Alle spielbaren Lektionen der Kategorie „Putten".
    static var lessons: [TrainingLesson] {
        allLessons.filter { $0.category == .putten && $0.isAvailable }
    }
}

// MARK: - Sheet

/// Liste der Putt-Audios mit Abspielsteuerung. Nutzt denselben Player wie der
/// Training-Tab, damit Wiedergabe, Sperrbildschirm und Tempo identisch sind.
struct PuttTrainingSheet: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var player = TrainingPlayerModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showFullPlayer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Auf der Minigolfanlage entscheidet die Distanzkontrolle fast alles – genau wie auf dem Grün.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(PuttTraining.lessons) { lesson in
                        lessonRow(lesson)
                    }

                    if player.currentLesson != nil {
                        Button {
                            Haptics.tap()
                            showFullPlayer = true
                        } label: {
                            Label("Großer Player", systemImage: "chevron.up")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(AppTheme.gold)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Putt-Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        Haptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.gold)
                }
            }
            .sheet(isPresented: $showFullPlayer) {
                TrainingPlayerSheet(model: player)
                    .preferredColorScheme(.dark)
            }
            .onAppear {
                player.onAppear()
                player.isSubscribed = subscriptionManager.isSubscribed
            }
            .onDisappear { player.stop() }
        }
    }

    private func lessonRow(_ lesson: TrainingLesson) -> some View {
        let isCurrent = player.currentLesson?.id == lesson.id
        return Button {
            Haptics.tap()
            if isCurrent {
                player.toggle()
            } else {
                player.load(lesson)
                player.play()
            }
        } label: {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isCurrent ? AppTheme.gold : lesson.category.color.opacity(0.18))
                        Image(systemName: isCurrent && player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(isCurrent ? Color(red: 0.06, green: 0.14, blue: 0.08)
                                                       : lesson.category.color)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(lesson.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.text)
                            .lineLimit(1)
                        Text(lesson.subtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Text(lesson.durationLabel)
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.textSec)
                }

                if isCurrent {
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(AppTheme.textTer.opacity(0.4))
                                Capsule()
                                    .fill(AppTheme.gold)
                                    .frame(width: geo.size.width * player.progress)
                            }
                        }
                        .frame(height: 4)

                        HStack {
                            Text(timeString(player.currentTime))
                            Spacer()
                            Text(timeString(player.duration))
                        }
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(AppTheme.textSec)
                    }

                    HStack(spacing: 18) {
                        Button {
                            Haptics.tap()
                            player.skip(seconds: -15)
                        } label: {
                            Image(systemName: "gobackward.15")
                        }
                        .buttonStyle(.plain)
                        Button {
                            Haptics.tap()
                            player.skip(seconds: 15)
                        } label: {
                            Image(systemName: "goforward.15")
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.title3)
                    .foregroundStyle(AppTheme.textSec)
                }

                if !lesson.practiceTask.isEmpty && isCurrent {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundStyle(AppTheme.gold)
                        Text(lesson.practiceTask)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(AppTheme.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(14)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.gold.opacity(0.35), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isCurrent)
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
