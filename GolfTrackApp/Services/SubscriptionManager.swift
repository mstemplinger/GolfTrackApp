import Combine
import StoreKit
import SwiftUI

// MARK: - Store Error

enum StoreError: LocalizedError {
    case failedVerification
    var errorDescription: String? { "Transaktion konnte nicht verifiziert werden." }
}

// MARK: - SubscriptionManager

@MainActor
final class SubscriptionManager: ObservableObject {

    // Product IDs
    static let trainingProductID = "Trainingsvideos_abo"
    static let caddyProductID    = "Caddy_abo"
    static let proProductID      = "GolfTrackPro_abo"

    @Published var isTrainingSubscribed = false
    @Published var isCaddySubscribed    = false

    @Published var trainingProduct: Product?
    @Published var caddyProduct: Product?
    @Published var proProduct: Product?

    @Published var isPurchasing  = false
    @Published var isRestoring   = false
    @Published var errorMessage: String?

    // Legacy computed for TrainingView compatibility
    var isSubscribed: Bool { isTrainingSubscribed }

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Subscription Period

    func subscriptionPeriodLabel(for product: Product?) -> String {
        guard let period = product?.subscription?.subscriptionPeriod else { return "Monat" }
        switch period.unit {
        case .day:   return period.value == 1 ? "Tag"   : "\(period.value) Tage"
        case .week:  return period.value == 1 ? "Woche" : "\(period.value) Wochen"
        case .month: return period.value == 1 ? "Monat" : "\(period.value) Monate"
        case .year:  return period.value == 1 ? "Jahr"  : "\(period.value) Jahre"
        @unknown default: return "Periode"
        }
    }

    // MARK: - Introductory Offer

    func freeTrialLabel(for product: Product?) -> String? {
        guard let offer = product?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let p = offer.period
        switch p.unit {
        case .day:   return p.value == 7 ? "7 Tage" : "\(p.value) Tag\(p.value == 1 ? "" : "e")"
        case .week:  return p.value == 1 ? "1 Woche" : "\(p.value) Wochen"
        case .month: return p.value == 1 ? "1 Monat" : "\(p.value) Monate"
        case .year:  return p.value == 1 ? "1 Jahr" : "\(p.value) Jahre"
        @unknown default: return nil
        }
    }

    // Legacy helpers used by TrainingPaywallView
    var freeTrialLabel: String? { freeTrialLabel(for: trainingProduct) }
    var hasFreeTrial: Bool { freeTrialLabel != nil }

    // MARK: - Load

    func loadProducts() async {
        do {
            let ids: [String] = [Self.trainingProductID, Self.caddyProductID, Self.proProductID]
            let products = try await Product.products(for: ids)
            for p in products {
                switch p.id {
                case Self.trainingProductID: trainingProduct = p
                case Self.caddyProductID:    caddyProduct    = p
                case Self.proProductID:      proProduct      = p
                default: break
                }
            }
        } catch {
            errorMessage = "Abonnement konnte nicht geladen werden."
        }
    }

    // Legacy used by TrainingPaywallView
    var product: Product? { trainingProduct }
    func loadProduct() async { await loadProducts() }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                // State sofort setzen — updateSubscriptionStatus wird NICHT direkt
                // aufgerufen, da StoreKit die Entitlements erst verzögert aktualisiert
                // und sonst den gerade gesetzten State wieder überschreiben würde.
                // Der Transaction-Listener übernimmt die spätere Synchronisierung.
                switch product.id {
                case Self.trainingProductID:
                    isTrainingSubscribed = true
                    isCaddySubscribed    = false
                case Self.caddyProductID:
                    isCaddySubscribed    = true
                    isTrainingSubscribed = false
                case Self.proProductID:
                    isTrainingSubscribed = true
                    isCaddySubscribed    = true
                default:
                    break
                }
                await transaction.finish()
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Kauf fehlgeschlagen. Bitte versuche es erneut."
        }
    }

    // Legacy used by TrainingPaywallView
    func purchase() async {
        guard let p = trainingProduct else { return }
        await purchase(p)
    }

    // MARK: - Restore

    func restore() async {
        isRestoring = true
        errorMessage = nil
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Wiederherstellen fehlgeschlagen."
        }
    }

    // MARK: - Status

    func updateSubscriptionStatus() async {
        var hasTraining = false
        var hasCaddy    = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result, tx.revocationDate == nil else { continue }
            switch tx.productID {
            case Self.trainingProductID: hasTraining = true
            case Self.caddyProductID:    hasCaddy    = true
            case Self.proProductID:      hasTraining = true; hasCaddy = true
            default: break
            }
        }
        isTrainingSubscribed = hasTraining
        isCaddySubscribed    = hasCaddy
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await updateSubscriptionStatus()
                    await tx.finish()
                }
            }
        }
    }
}
