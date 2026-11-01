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
    /// Jahresabo für die Training-Audios. Liegt in App Store Connect in
    /// derselben Abo-Gruppe wie `trainingProductID`, damit Apple Wechsel
    /// zwischen Monat und Jahr als Up-/Downgrade behandelt. Schaltet genau
    /// dasselbe frei wie das Monatsabo.
    static let trainingYearlyProductID = "Trainingsvideos_abo_jahr"
    static let caddyProductID    = "Caddy_abo"
    static let proProductID      = "GolfTrackPro_abo"
    /// Einmalkauf, der die Werbung abschaltet. Muss in App Store Connect als
    /// nicht verbrauchbarer Artikel unter dieser Kennung angelegt sein –
    /// solange er fehlt, bleibt `adFreeProduct` einfach leer.
    static let adFreeProductID   = "GolfTrack_werbefrei"
    /// Einmalkauf (nicht verbrauchbar), der alle Audiobooks dauerhaft
    /// freischaltet – auch die, die mit späteren Updates dazukommen. Wirkt
    /// wie ein Training-Abo, läuft aber nie ab.
    static let audiobooksLifetimeProductID = "Audiobooks_lifetime"

    @Published var isTrainingSubscribed = false
    @Published var isCaddySubscribed    = false
    @Published var isAdFree             = false
    /// Audiobooks per Einmalkauf freigeschaltet. Setzt `isTrainingSubscribed`
    /// mit – die Views fragen weiter nur das ab.
    @Published var ownsAudiobooksLifetime = false

    @Published var trainingProduct: Product?
    @Published var trainingYearlyProduct: Product?
    @Published var caddyProduct: Product?
    @Published var proProduct: Product?
    @Published var adFreeProduct: Product?
    @Published var audiobooksLifetimeProduct: Product?

    /// Werbung sieht nur, wer nichts bezahlt hat. Ein Abo schaltet sie mit ab –
    /// wer für Inhalte zahlt, soll nicht zusätzlich beworben werden.
    var showsAds: Bool { !(isAdFree || isTrainingSubscribed || isCaddySubscribed) }

    @Published var isPurchasing  = false
    @Published var isRestoring   = false
    @Published var errorMessage: String?

    // Legacy computed for TrainingView compatibility
    var isSubscribed: Bool { isTrainingSubscribed }

    private var transactionListener: Task<Void, Never>?

    init() {
        #if DEBUG
        // Sofort setzen, nicht erst im Task: die Views lesen den Status beim
        // ersten Aufbau. Nur mit -unlockAll und nur in DEBUG-Builds.
        if ProcessInfo.processInfo.arguments.contains("-unlockAll") {
            isTrainingSubscribed = true
            isCaddySubscribed    = true
            isAdFree             = true
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
    var trainingYearlySavingsLabel: String? {
        guard let monthly = trainingProduct, let yearly = trainingYearlyProduct,
              Self.isSinglePeriod(monthly, .month), Self.isSinglePeriod(yearly, .year),
              monthly.priceFormatStyle.currencyCode == yearly.priceFormatStyle.currencyCode,
              monthly.price > 0 else { return nil }
        let fullYear = monthly.price * 12
        let saving = NSDecimalNumber(decimal: (fullYear - yearly.price) / fullYear).doubleValue
        guard saving >= 0.01 else { return nil }
        return saving.formatted(.percent.precision(.fractionLength(0)))
    }

    /// Jahrespreis auf einen Monat umgelegt, in Währung und Format des Stores.
    var trainingYearlyPricePerMonth: String? {
        guard let yearly = trainingYearlyProduct, Self.isSinglePeriod(yearly, .year) else { return nil }
        return (yearly.price / 12).formatted(yearly.priceFormatStyle)
    }

    private static func isSinglePeriod(_ product: Product, _ unit: Product.SubscriptionPeriod.Unit) -> Bool {
        guard let period = product.subscription?.subscriptionPeriod else { return false }
        return period.value == 1 && period.unit == unit
    }

    // Legacy helpers used by TrainingPaywallView
    var freeTrialLabel: String? { freeTrialLabel(for: trainingProduct) }
    var hasFreeTrial: Bool { freeTrialLabel != nil }

    // MARK: - Load

    func loadProducts() async {
        do {
            let ids: [String] = [Self.trainingProductID, Self.trainingYearlyProductID,
                                 Self.caddyProductID,
                                 Self.proProductID, Self.adFreeProductID,
                                 Self.audiobooksLifetimeProductID]
            let products = try await Product.products(for: ids)
            for p in products {
                switch p.id {
                case Self.trainingProductID: trainingProduct = p
                case Self.trainingYearlyProductID: trainingYearlyProduct = p
                case Self.caddyProductID:    caddyProduct    = p
                case Self.proProductID:      proProduct      = p
                case Self.adFreeProductID:   adFreeProduct   = p
                case Self.audiobooksLifetimeProductID: audiobooksLifetimeProduct = p
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
                case Self.trainingProductID, Self.trainingYearlyProductID:
                    isTrainingSubscribed = true
                    isCaddySubscribed    = false
                case Self.caddyProductID:
                    isCaddySubscribed    = true
                    isTrainingSubscribed = ownsAudiobooksLifetime
                case Self.proProductID:
                    isTrainingSubscribed = true
                    isCaddySubscribed    = true
                case Self.adFreeProductID:
                    isAdFree = true
                case Self.audiobooksLifetimeProductID:
                    ownsAudiobooksLifetime = true
                    isTrainingSubscribed   = true
                default:
                    break
                }
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
            isTrainingSubscribed = true
            isCaddySubscribed    = true
            isAdFree             = true
            ownsAudiobooksLifetime = true
            return
        }
        #endif

        var hasTraining = false
        var hasCaddy    = false
        var hasAdFree   = false
        var hasLifetime = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result, tx.revocationDate == nil else { continue }
            switch tx.productID {
            case Self.trainingProductID, Self.trainingYearlyProductID: hasTraining = true
            case Self.caddyProductID:    hasCaddy    = true
            case Self.proProductID:      hasTraining = true; hasCaddy = true
            case Self.adFreeProductID:   hasAdFree   = true
            case Self.audiobooksLifetimeProductID: hasLifetime = true; hasTraining = true
            default: break
            }
        }
        ownsAudiobooksLifetime = hasLifetime
        isTrainingSubscribed = hasTraining
        isCaddySubscribed    = hasCaddy
        isAdFree             = hasAdFree
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
