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

    // Product IDs – verkauft wird nur noch GolfTrack Pro.
    /// Pro im Monatsabo (Ziel 5 €). Liegt in derselben Abo-Gruppe wie das
    /// Jahresabo, damit Apple Wechsel als Up-/Downgrade behandelt.
    static let proProductID        = "GolfTrackPro_abo"
    /// Pro im Jahresabo (Ziel 50 €).
    static let proYearlyProductID  = "GolfTrackPro_abo_jahr"
    /// Pro als Einmalkauf (nicht verbrauchbar, Ziel 80 €) – läuft nie ab.
    static let proLifetimeProductID = "GolfTrackPro_lifetime"

    /// Frühere Produkte, die nicht mehr verkauft werden. Wer eines davon noch
    /// besitzt, behält seinen Zugang: Abos und Audiobooks-Kauf zählen als Pro,
    /// der Werbefrei-Kauf schaltet weiter nur die Werbung ab.
    static let legacyProProductIDs: Set<String> = [
        "Trainingsvideos_abo", "Trainingsvideos_abo_jahr", "Caddy_abo", "Audiobooks_lifetime",
    ]
    static let legacyAdFreeProductID = "GolfTrack_werbefrei"

    /// Pro aktiv – per Abo, Einmalkauf oder einem früheren Produkt.
    @Published var isPro = false
    /// Pro per Einmalkauf, läuft also nie ab.
    @Published var ownsProLifetime = false
    /// Früherer Werbefrei-Einmalkauf.
    @Published var isAdFree = false

    @Published var proProduct: Product?
    @Published var proYearlyProduct: Product?
    @Published var proLifetimeProduct: Product?

    /// Werbung sieht nur, wer nichts bezahlt hat.
    var showsAds: Bool { !(isPro || isAdFree) }

    @Published var isPurchasing  = false
    @Published var isRestoring   = false
    @Published var errorMessage: String?

    /// Schaltet die Audio-Lektionen frei – heißt in den Training-Views so.
    var isSubscribed: Bool { isPro }

    private var transactionListener: Task<Void, Never>?

    init() {
        #if DEBUG
        // Sofort setzen, nicht erst im Task: die Views lesen den Status beim
        // ersten Aufbau. Nur mit -unlockAll und nur in DEBUG-Builds.
        if ProcessInfo.processInfo.arguments.contains("-unlockAll") {
            isPro = true
        }
        #endif

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

    /// „Monat“ bzw. „3 Monate“ – in der Sprache der App, für „/ Monat“ hinter dem Preis.
    func subscriptionPeriodLabel(for product: Product?) -> String {
        guard let period = product?.subscription?.subscriptionPeriod else { return String(localized: "Monat") }
        if period.value == 1 {
            switch period.unit {
            case .day:   return String(localized: "Tag")
            case .week:  return String(localized: "Woche")
            case .month: return String(localized: "Monat")
            case .year:  return String(localized: "Jahr")
            @unknown default: break
            }
        }
        return Self.spelledOut(period) ?? String(localized: "Monat")
    }

    // MARK: - Introductory Offer

    /// Dauer der Gratis-Testphase, z. B. „3 Tage“ / „3 days“ / „3 jours“.
    func freeTrialLabel(for product: Product?) -> String? {
        guard let offer = product?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return Self.spelledOut(offer.period)
    }

    /// Zahl + Einheit ausgeschrieben, übersetzt und mit richtiger Mehrzahl vom System.
    private static func spelledOut(_ period: Product.SubscriptionPeriod) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        var parts = DateComponents()
        switch period.unit {
        case .day:   parts.day = period.value;        formatter.allowedUnits = [.day]
        case .week:  parts.weekOfMonth = period.value; formatter.allowedUnits = [.weekOfMonth]
        case .month: parts.month = period.value;      formatter.allowedUnits = [.month]
        case .year:  parts.year = period.value;       formatter.allowedUnits = [.year]
        @unknown default: return nil
        }
        return formatter.string(from: parts)
    }

    // MARK: - Jahresabo-Ersparnis

    /// Ersparnis des Jahresabos gegenüber 12 × Monatsabo, z. B. „17 %“.
    /// Rein aus den StoreKit-Preisen gerechnet – kein Betrag ist fest verdrahtet.
    /// `nil`, wenn ein Produkt fehlt, die Währungen abweichen, die Laufzeiten
    /// nicht Monat/Jahr sind oder sich nichts spart.
    var yearlySavingsLabel: String? {
        guard let monthly = proProduct, let yearly = proYearlyProduct,
              Self.isSinglePeriod(monthly, .month), Self.isSinglePeriod(yearly, .year),
              monthly.priceFormatStyle.currencyCode == yearly.priceFormatStyle.currencyCode,
              monthly.price > 0 else { return nil }
        let fullYear = monthly.price * 12
        let saving = NSDecimalNumber(decimal: (fullYear - yearly.price) / fullYear).doubleValue
        guard saving >= 0.01 else { return nil }
        return saving.formatted(.percent.precision(.fractionLength(0)))
    }

    /// Jahrespreis auf einen Monat umgelegt, in Währung und Format des Stores.
    var yearlyPricePerMonth: String? {
        guard let yearly = proYearlyProduct, Self.isSinglePeriod(yearly, .year) else { return nil }
        return (yearly.price / 12).formatted(yearly.priceFormatStyle)
    }

    private static func isSinglePeriod(_ product: Product, _ unit: Product.SubscriptionPeriod.Unit) -> Bool {
        guard let period = product.subscription?.subscriptionPeriod else { return false }
        return period.value == 1 && period.unit == unit
    }

    /// Testphase des Monatsabos, falls in App Store Connect eine angelegt ist.
    var freeTrialLabel: String? { freeTrialLabel(for: proProduct) }
    var hasFreeTrial: Bool { freeTrialLabel != nil }

    // MARK: - Load

    func loadProducts() async {
        do {
            let ids = [Self.proProductID, Self.proYearlyProductID, Self.proLifetimeProductID]
            let products = try await Product.products(for: ids)
            for p in products {
                switch p.id {
                case Self.proProductID:         proProduct         = p
                case Self.proYearlyProductID:   proYearlyProduct   = p
                case Self.proLifetimeProductID: proLifetimeProduct = p
                default: break
                }
            }
        } catch {
            errorMessage = "Abonnement konnte nicht geladen werden."
        }
    }

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
                isPro = true
                if product.id == Self.proLifetimeProductID { ownsProLifetime = true }
                Haptics.celebrate()
                await transaction.finish()
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            Haptics.error()
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
            Haptics.success()
        } catch {
            Haptics.error()
            errorMessage = "Wiederherstellen fehlgeschlagen."
        }
    }

    // MARK: - Status

    func updateSubscriptionStatus() async {
        #if DEBUG
        // Screenshots sollen die Inhalte zeigen, nicht die Kaufseite. Nur mit
        // -unlockAll beim Start, nur in DEBUG-Builds — im Release existiert
        // dieser Zweig nicht.
        if ProcessInfo.processInfo.arguments.contains("-unlockAll") {
            isPro = true
            return
        }
        #endif

        var hasPro      = false
        var hasLifetime = false
        var hasAdFree   = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result, tx.revocationDate == nil else { continue }
            switch tx.productID {
            case Self.proProductID, Self.proYearlyProductID:
                hasPro = true
            case Self.proLifetimeProductID:
                hasPro = true; hasLifetime = true
            case Self.legacyAdFreeProductID:
                hasAdFree = true
            case let id where Self.legacyProProductIDs.contains(id):
                hasPro = true
            default: break
            }
        }
        isPro           = hasPro
        ownsProLifetime = hasLifetime
        isAdFree        = hasAdFree
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
