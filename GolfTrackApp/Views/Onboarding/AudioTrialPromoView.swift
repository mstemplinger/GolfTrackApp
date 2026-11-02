import SwiftUI
import StoreKit

// MARK: - Anzeige-Steuerung

/// Kleiner Hinweis nach dem Update: Die Audio-Lektionen lassen sich drei Tage
/// kostenlos testen. Erscheint einmal, nur für Bestandsnutzer, und nur wenn
/// StoreKit die Testphase für diesen Apple-Account tatsächlich anbietet – wer
/// sie schon hatte oder abonniert ist, bekäme sonst ein leeres Versprechen.
enum AudioTrialPromo {

    static let storageKey = "promo.audioTrial.seen"

    static var hasSeen: Bool { UserDefaults.standard.bool(forKey: storageKey) }

    static func markAsSeen() {
        UserDefaults.standard.set(true, forKey: storageKey)
    }

    @MainActor
    static func shouldShow(_ subscriptions: SubscriptionManager) async -> Bool {
        guard !hasSeen else { return false }
        // Neuinstallationen gehen durchs Onboarding – der Hinweis ist fürs Update.
        guard UserDefaults.standard.bool(forKey: "hasSeenOnboarding") else {
            markAsSeen()
            return false
        }
        if subscriptions.trainingProduct == nil { await subscriptions.loadProducts() }
        await subscriptions.updateSubscriptionStatus()
        if subscriptions.isTrainingSubscribed {
            markAsSeen()
            return false
        }
        // Ohne Produkt (offline) beim nächsten Start erneut versuchen.
        guard let subscription = subscriptions.trainingProduct?.subscription,
              subscriptions.hasFreeTrial else { return false }
        guard await subscription.isEligibleForIntroOffer else {
            markAsSeen()
            return false
        }
        return true
    }
}

// MARK: - Pop-up

struct AudioTrialPromoView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    let onTry: () -> Void
    let onDismiss: () -> Void

    private var trialLabel: String {
        subscriptionManager.freeTrialLabel ?? String(localized: "3 Tage")
    }

    private var priceLine: String? {
        guard let product = subscriptionManager.trainingProduct else { return nil }
        let period = subscriptionManager.subscriptionPeriodLabel(for: product)
        return String(localized: "Danach \(product.displayPrice) / \(period), jederzeit kündbar.")
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.gold.opacity(0.18))
                        .frame(width: 72, height: 72)
                    Image(systemName: "headphones")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                }

                VStack(spacing: 6) {
                    Text("Neu nach dem Update")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.gold)
                    Text("Audios \(trialLabel) kostenlos")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.text)
                        .multilineTextAlignment(.center)
                    Text("Hör dir alle Audio-Lektionen an – in der Testphase bezahlst du nichts.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if let priceLine {
                        Text(priceLine)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTer)
                            .multilineTextAlignment(.center)
                    }
                }

                VStack(spacing: 6) {
                    Button {
                        Haptics.tap()
                        onTry()
                    } label: {
                        Text("Jetzt kostenlos testen")
                            .goldButton()
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.tap()
                        onDismiss()
                    } label: {
                        Text("Später")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textSec)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .frame(maxWidth: 360)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.gold.opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
    }
}
