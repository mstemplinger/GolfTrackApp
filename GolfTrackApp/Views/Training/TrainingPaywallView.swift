import SwiftUI
import StoreKit

struct TrainingPaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan = .training

    enum Plan { case training, pro }

    private var trainingFeatures: [(icon: String, color: Color, text: String)] {
        let count = allLessons.filter(\.isAvailable).count
        return [
        ("headphones",           AppTheme.gold,                              "\(count) Audio-Trainingseinheiten"),
        ("figure.golf",          Color(red: 0.3, green: 0.85, blue: 0.5),   "Drive, Technik, Mental & mehr"),
        ("arrow.clockwise",      Color(red: 0.4, green: 0.7,  blue: 1.0),   "Neue Lektionen regelmäßig"),
        ("play.circle.fill",     Color(red: 1.0, green: 0.6,  blue: 0.3),   "Offline anhören, jederzeit"),
        ("speedometer",          Color(red: 0.6, green: 0.5,  blue: 1.0),   "Wiedergabegeschwindigkeit"),
        ]
    }

    private let proFeatures: [(icon: String, color: Color, text: String)] = [
        ("headphones",           AppTheme.gold,                              "Alle Audio-Trainings"),
        ("waveform.circle.fill", Color(red: 0.4, green: 0.7,  blue: 1.0),   "KI-Assistent Caddy"),
        ("figure.golf",          Color(red: 0.3, green: 0.85, blue: 0.5),   "Drive, Technik, Mental & mehr"),
        ("arrow.clockwise",      Color(red: 1.0, green: 0.6,  blue: 0.3),   "Neue Inhalte regelmäßig"),
        ("infinity",             Color(red: 0.6, green: 0.5,  blue: 1.0),   "Unbegrenzte Caddy-Gespräche"),
    ]

    private var activeProduct: Product? {
        selectedPlan == .training ? subscriptionManager.trainingProduct : subscriptionManager.proProduct
    }

    private var trialLabel: String? {
        subscriptionManager.freeTrialLabel(for: activeProduct)
    }

    private var periodLabel: String {
        subscriptionManager.subscriptionPeriodLabel(for: activeProduct)
    }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.textTer)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroSection
                        planPicker
                        if subscriptionManager.isCaddySubscribed && selectedPlan == .training {
                            caddyWarningBanner
                        }
                        if trialLabel != nil { trialBanner }
                        featuresSection
                        priceSection
                        actionSection
                        footerLinks
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onChange(of: subscriptionManager.isTrainingSubscribed) { _, subscribed in
            if subscribed { dismiss() }
        }
        .onChange(of: subscriptionManager.isPurchasing) { _, purchasing in
            if !purchasing && subscriptionManager.isTrainingSubscribed { dismiss() }
        }
        .alert("Fehler", isPresented: Binding(
            get: { subscriptionManager.errorMessage != nil },
            set: { if !$0 { subscriptionManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { subscriptionManager.errorMessage = nil }
        } message: {
            Text(subscriptionManager.errorMessage ?? "")
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.gold.opacity(0.12))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(AppTheme.gold.opacity(0.18))
                    .frame(width: 70, height: 70)
                Image(systemName: selectedPlan == .pro ? "crown.fill" : "headphones")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(AppTheme.gold)
                    .contentTransition(.symbolEffect(.replace))
            }

            Text(selectedPlan == .pro ? "GolfTrack Pro" : "Training")
                .font(.title.bold())
                .foregroundStyle(AppTheme.text)
                .contentTransition(.numericText())

            Text(selectedPlan == .pro
                 ? "Alle Trainings und der KI-Caddy –\nalles in einem Abo."
                 : "Werde zum besseren Golfspieler –\nmit geführten Audio-Trainings.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedPlan)
    }

    // MARK: - Plan Picker

    private var planPicker: some View {
        HStack(spacing: 0) {
            planTab(label: "Training", plan: .training)
            planTab(label: "Pro (Alles)", plan: .pro)
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 4)
    }

    private func planTab(label: String, plan: Plan) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = plan }
        } label: {
            Text(label)
                .font(.subheadline.weight(selectedPlan == plan ? .semibold : .regular))
                .foregroundStyle(selectedPlan == plan ? Color(red: 0.08, green: 0.18, blue: 0.11) : AppTheme.textSec)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    Group {
                        if selectedPlan == plan {
                            RoundedRectangle(cornerRadius: 10).fill(AppTheme.gold)
                        }
                    }
                )
                .padding(4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trial Banner

    private var trialBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "gift.fill")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
            Text("\(trialLabel ?? "1 Woche") kostenlos testen – danach jederzeit kündbar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Caddy-Konflikt-Hinweis

    private var caddyWarningBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.gold)
                Text("Du hast bereits Caddy")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
            }
            Text("Du hast aktuell Caddy aktiv. Wenn du das Training-Abo kaufst, verlierst du deinen Caddy-Zugang. Mit Pro bekommst du beides – Training und Caddy – in einem Abo.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = .pro }
            } label: {
                Label("Zu Pro wechseln – alles in einem", systemImage: "crown.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.gold.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.gold.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Features

    private var featuresSection: some View {
        let features = selectedPlan == .training ? trainingFeatures : proFeatures
        return VStack(spacing: 0) {
            ForEach(features.indices, id: \.self) { i in
                let f = features[i]
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(f.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: f.icon)
                            .font(.system(size: 17))
                            .foregroundStyle(f.color)
                    }
                    Text(f.text)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.gold)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                if i < features.count - 1 {
                    Divider()
                        .background(AppTheme.cardAlt)
                        .padding(.leading, 70)
                }
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.2), value: selectedPlan)
    }

    // MARK: - Price

    private var priceSection: some View {
        VStack(spacing: 6) {
            if let name = activeProduct?.displayName {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textSec)
            }
            if let label = trialLabel {
                Text("\(label) kostenlos")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.gold)
                Text("danach \(activeProduct?.displayPrice ?? "–") / \(periodLabel)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSec)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(activeProduct?.displayPrice ?? "–")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(activeProduct == nil ? AppTheme.textTer : AppTheme.text)
                    Text("/ \(periodLabel)")
                        .font(.title3)
                        .foregroundStyle(AppTheme.textSec)
                }
            }
            Text("Jederzeit kündbar · Keine Bindung")
                .font(.caption)
                .foregroundStyle(AppTheme.textTer)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.2), value: selectedPlan)
    }

    // MARK: - Action

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    if let p = activeProduct {
                        await subscriptionManager.purchase(p)
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(activeProduct == nil ? AppTheme.gold.opacity(0.4) : AppTheme.gold)
                        .frame(height: 54)

                    if subscriptionManager.isPurchasing {
                        ProgressView()
                            .tint(Color(red: 0.08, green: 0.18, blue: 0.11))
                    } else if activeProduct == nil {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(Color(red: 0.08, green: 0.18, blue: 0.11))
                                .scaleEffect(0.8)
                            Text("Abonnement wird geladen…")
                                .font(.headline)
                                .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                        }
                    } else if let label = trialLabel {
                        Label("\(label) gratis testen", systemImage: "gift.fill")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                    } else {
                        Label("Jetzt abonnieren", systemImage: selectedPlan == .pro ? "crown.fill" : "headphones")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(activeProduct == nil || subscriptionManager.isPurchasing || subscriptionManager.isRestoring)

            Button {
                Task { await subscriptionManager.restore() }
            } label: {
                if subscriptionManager.isRestoring {
                    ProgressView()
                        .tint(AppTheme.textSec)
                        .frame(height: 40)
                } else {
                    Text("Kauf wiederherstellen")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                        .frame(height: 40)
                }
            }
            .buttonStyle(.plain)
            .disabled(subscriptionManager.isPurchasing || subscriptionManager.isRestoring)
        }
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Link("Datenschutz", destination: URL(string: "https://mstemplinger.github.io/GolfTrackApp/")!)
            Text("·")
            Link("Nutzungsbedingungen", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        }
        .font(.caption2)
        .foregroundStyle(AppTheme.textTer)
        .multilineTextAlignment(.center)
    }
}
