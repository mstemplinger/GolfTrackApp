import StoreKit
import SwiftUI

/// Kaufseite für „Werbefrei": ein Einmalkauf, der die Werbefläche in den
/// Zählkarten abschaltet – kein Abo, nichts läuft weiter.
///
/// Erreichbar aus der Werbefläche selbst („Werbung entfernen"), aus der
/// Eigenwerbung an derselben Stelle und aus den Einstellungen. Die Hinweise der
/// Anlage (Toiletten, Unterstand …) sind keine Werbung und bleiben stehen –
/// das steht hier ausdrücklich, damit niemand dafür bezahlt und sich wundert.
struct AdFreePaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    private var product: Product? { subscriptionManager.adFreeProduct }

    private let points: [(icon: String, text: LocalizedStringKey)] = [
        ("rectangle.slash", "Keine Anzeigen mehr in den Zählkarten"),
        ("checkmark.seal.fill", "Einmal bezahlen – kein Abo, keine Verlängerung"),
        ("iphone.and.arrow.forward", "Gilt auf allen Geräten mit derselben Apple-ID"),
        ("info.circle.fill", "Hinweise der Anlage wie Toiletten oder Unterstand bleiben sichtbar"),
    ]

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.gold.opacity(0.15))
                                .frame(width: 84, height: 84)
                            Image(systemName: "rectangle.slash")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(AppTheme.gold)
                        }
                        Text("Werbefrei")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(AppTheme.text)
                        Text("Spiel deine Runden ohne Anzeigen.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSec)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                            HStack(spacing: 14) {
                                Image(systemName: point.icon)
                                    .font(.system(size: 17))
                                    .foregroundStyle(AppTheme.gold)
                                    .frame(width: 28)
                                Text(point.text)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.text)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            if index < points.count - 1 {
                                Divider().padding(.leading, 58)
                            }
                        }
                    }
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))

                    VStack(spacing: 6) {
                        Text(product?.displayPrice ?? "–")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(product == nil ? AppTheme.textTer : AppTheme.text)
                        Text("einmalig")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))

                    actions

                    Text("Wer ein Training- oder Caddy-Abo hat, sieht ohnehin keine Werbung.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTer)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Link("Datenschutz", destination: LegalLinks.privacy)
                        Text(verbatim: "·")
                        Link("Nutzungsbedingungen", destination: LegalLinks.terms)
                    }
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTer)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.large])
        .onChange(of: subscriptionManager.isAdFree) { _, adFree in
            if adFree { dismiss() }
        }
        .alert("Fehler", isPresented: Binding(
            get: { subscriptionManager.errorMessage != nil },
            set: { if !$0 { subscriptionManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(subscriptionManager.errorMessage ?? "")
        }
        .task {
            if product == nil { await subscriptionManager.loadProducts() }
        }
    }

    private var actions: some View {
        let ink = Color(red: 0.08, green: 0.18, blue: 0.11)
        return VStack(spacing: 12) {
            Button {
                Haptics.medium()
                Task {
                    if let product { await subscriptionManager.purchase(product) }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(product == nil ? AppTheme.gold.opacity(0.4) : AppTheme.gold)
                        .frame(height: 54)
                    if subscriptionManager.isPurchasing {
                        ProgressView().tint(ink)
                    } else if product == nil {
                        Text("Wird geladen…")
                            .font(.headline)
                            .foregroundStyle(ink)
                    } else {
                        Label("Werbung entfernen", systemImage: "rectangle.slash")
                            .font(.headline)
                            .foregroundStyle(ink)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(product == nil || subscriptionManager.isPurchasing || subscriptionManager.isRestoring)

            Button {
                Haptics.tap()
                Task { await subscriptionManager.restore() }
            } label: {
                Group {
                    if subscriptionManager.isRestoring {
                        ProgressView().tint(AppTheme.textSec)
                    } else {
                        Text("Kauf wiederherstellen")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
                .frame(height: 40)
            }
            .buttonStyle(.plain)
            .disabled(subscriptionManager.isPurchasing || subscriptionManager.isRestoring)
        }
    }
}

#Preview {
    AdFreePaywallView()
        .environmentObject(SubscriptionManager())
        .preferredColorScheme(.dark)
}
