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

    static let productID = "Trainingsvideos_abo"

    @Published var isSubscribed  = false
    @Published var product: Product?
    @Published var isPurchasing  = false
    @Published var isRestoring   = false
    @Published var errorMessage: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProduct()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Introductory Offer

    var freeTrialLabel: String? {
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

    var hasFreeTrial: Bool { freeTrialLabel != nil }

    // MARK: - Load

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            errorMessage = "Abonnement konnte nicht geladen werden."
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
            case .pending:
                break
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Kauf fehlgeschlagen. Bitte versuche es erneut."
        }
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
        var found = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.productID && tx.revocationDate == nil {
                found = true
                break
            }
        }
        isSubscribed = found
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
