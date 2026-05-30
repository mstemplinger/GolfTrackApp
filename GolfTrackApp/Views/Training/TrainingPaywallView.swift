import SwiftUI
import StoreKit

struct TrainingPaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, color: Color, text: String)] = [
        ("headphones",           AppTheme.gold,                         "10 Audio-Trainingseinheiten"),
        ("figure.golf",          Color(red: 0.3, green: 0.85, blue: 0.5), "Drive, Technik, Mental & mehr"),
        ("arrow.clockwise",      Color(red: 0.4, green: 0.7,  blue: 1.0), "Neue Lektionen regelmäßig"),
        ("play.circle.fill",     Color(red: 1.0, green: 0.6,  blue: 0.3), "Offline anhören, jederzeit"),
        ("speedometer",          Color(red: 0.6, green: 0.5,  blue: 1.0), "Wiedergabegeschwindigkeit"),
    ]

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Drag Handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.textTer)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        if subscriptionManager.hasFreeTrial { trialBanner }
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
        .onChange(of: subscriptionManager.isSubscribed) { _, subscribed in
            if subscribed { dismiss() }
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

    // MARK: - Trial Banner

    private var trialBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "gift.fill")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
            Text("\(subscriptionManager.freeTrialLabel ?? "1 Woche") kostenlos testen – danach jederzeit kündbar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
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
                Image(systemName: "crown.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(AppTheme.gold)
            }

            Text("GolfTrack Pro")
                .font(.title.bold())
                .foregroundStyle(AppTheme.text)

            Text("Werde zum besseren Golfspieler –\nmit geführten Audio-Trainings direkt in der App.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 0) {
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
    }

    // MARK: - Price

    private var priceSection: some View {
        VStack(spacing: 6) {
            if subscriptionManager.hasFreeTrial {
                Text("\(subscriptionManager.freeTrialLabel ?? "1 Woche") kostenlos")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.gold)
                let price = subscriptionManager.product?.displayPrice ?? "1,99 €"
                Text("danach \(price) / Monat")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSec)
            } else {
                let price = subscriptionManager.product?.displayPrice ?? "1,99 €"
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(AppTheme.text)
                    Text("/ Monat")
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
    }

    // MARK: - Action

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await subscriptionManager.purchase() }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.gold)
                        .frame(height: 54)

                    if subscriptionManager.isPurchasing {
                        ProgressView()
                            .tint(Color(red: 0.08, green: 0.18, blue: 0.11))
                    } else if subscriptionManager.hasFreeTrial {
                        Label("\(subscriptionManager.freeTrialLabel ?? "1 Woche") gratis testen", systemImage: "gift.fill")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                    } else {
                        Label("Jetzt abonnieren", systemImage: "crown.fill")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(subscriptionManager.isPurchasing || subscriptionManager.isRestoring)

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
            Link("Datenschutz", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
            Text("·")
            Link("Nutzungsbedingungen", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        }
        .font(.caption2)
        .foregroundStyle(AppTheme.textTer)
        .multilineTextAlignment(.center)
    }
}
