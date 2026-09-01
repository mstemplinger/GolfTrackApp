import Foundation
import Observation

/// Anzeigen für den freien Platz unter den Spielernamen in der Minigolfkarte.
///
/// Der Aufbau entspricht `CourseCatalogService`: einmal geladen, liegt die
/// Liste im Cache und funktioniert auch ohne Netz weiter – auf einer Anlage
/// im Wald ist das eher der Normalfall als die Ausnahme. Deshalb lädt die App
/// *alle* aktiven Anzeigen und sucht sich die passende selbst heraus.
///
/// Gezählt wird nur, wie oft eine Anzeige zu sehen war und wie oft jemand
/// darauf getippt hat. Es geht keine Gerätekennung, kein Standort und keine
/// Kennung eines Menschen an den Server – damit bleibt der Werbeplatz ohne
/// Einwilligungsdialog benutzbar.
@MainActor
@Observable
final class AdCatalogService {

    static let shared = AdCatalogService()

    static let feedURL = URL(string: "https://golftrack.app/api/v1/ads")!
    static let eventURL = URL(string: "https://golftrack.app/api/v1/ads/event")!

    /// Anzeigen wechseln häufiger als Plätze, deshalb kürzer als dort.
    private static let refreshInterval: TimeInterval = 2 * 60 * 60

    private(set) var ads: [RemoteAd] = []
    private(set) var lastUpdated: Date?
    private(set) var isLoading = false

    private var loadedFromDisk = false

    /// Verschiebt die Reihenfolge pro Start, damit nicht immer dieselbe
    /// Anzeige auf Bahn 1 landet.
    private let rotationSeed = Int.random(in: 0..<1000)

    /// Noch nicht gemeldete Zähler, nach Anzeigenkennung.
    private var pendingImpressions: [String: Int] = [:]
    private var pendingClicks: [String: Int] = [:]

    private init() {}

    // MARK: – Auswahl

    /// Die Anzeige für einen Platz in der Oberfläche.
    ///
    /// - Parameters:
    ///   - placement: Welcher Platz in der App gefüllt wird.
    ///   - courseID: Kennung der Anlage, auf der gerade gespielt wird.
    ///   - rotation: Zählwert, der die Anzeige weiterschaltet – in der
    ///     Scorecard die Bahnnummer.
    ///
    /// Eine für die Anlage gebuchte Anzeige geht immer vor: Wer den Platz vor
    /// Ort bezahlt hat, soll ihn auch bekommen. Nur wenn es keine gibt, kommen
    /// die allgemeinen Anzeigen zum Zug, gewichtet nach `weight`.
    func ad(placement: AdPlacement, courseID: String?, rotation: Int = 0) -> RemoteAd? {
        let today = Date()
        let candidates = ads.filter { $0.placement == placement.rawValue && $0.isRunning(on: today) }
        guard !candidates.isEmpty else { return nil }

        let local = courseID.map { id in candidates.filter { $0.courseID == id } } ?? []
        let pool = local.isEmpty ? candidates.filter(\.isEverywhere) : local
        guard !pool.isEmpty else { return nil }

        // Gewichtung als Wiederholung im Los: Gewicht 3 liegt dreimal drin.
        let weighted = pool.flatMap { ad in Array(repeating: ad, count: max(1, min(ad.weight, 100))) }
        let index = abs(rotation &+ rotationSeed) % weighted.count
        return weighted[index]
    }

    // MARK: – Zählen

    func countImpression(_ ad: RemoteAd) {
        pendingImpressions[ad.id, default: 0] += 1
    }

    func countClick(_ ad: RemoteAd) {
        pendingClicks[ad.id, default: 0] += 1
    }

    /// Schickt die gesammelten Zähler los. Fehler sind hier belanglos – im
    /// Zweifel geht eine Runde Reichweite verloren, nicht mehr.
    func flushCounters() async {
        let events = pendingImpressions.map { AdEvent(id: $0.key, type: "impression", count: $0.value) }
            + pendingClicks.map { AdEvent(id: $0.key, type: "click", count: $0.value) }
        guard !events.isEmpty else { return }
        pendingImpressions.removeAll()
        pendingClicks.removeAll()

        // Der Server nimmt 50 Meldungen je Anfrage; mehr entsteht hier nicht,
        // sicherheitshalber trotzdem in Häppchen.
        for chunk in stride(from: 0, to: events.count, by: 50).map({ Array(events[$0..<min($0 + 50, events.count)]) }) {
            var request = URLRequest(url: Self.eventURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 10
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(AdEventBatch(events: chunk))
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    // MARK: – Laden

    func refreshIfNeeded() async {
        if !loadedFromDisk { loadCache() }
        guard shouldRefresh else { return }
        await refresh()
    }

    private var shouldRefresh: Bool {
        guard let lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > Self.refreshInterval
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        var request = URLRequest(url: Self.feedURL)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadRevalidatingCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
            let feed = try JSONDecoder().decode(RemoteAdFeed.self, from: data)
            ads = feed.ads
            lastUpdated = Date()
            saveCache(data)
        } catch {
            // Ohne Netz bleibt der Cache stehen – das ist kein Fehlerfall.
        }
    }

    // MARK: – Cache auf der Platte

    private var cacheURL: URL? {
        guard let directory = FileManager.default.urls(for: .applicationSupportDirectory,
                                                       in: .userDomainMask).first else { return nil }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("remote-ads.json")
    }

    private func loadCache() {
        loadedFromDisk = true
        guard let cacheURL, let data = try? Data(contentsOf: cacheURL),
              let feed = try? JSONDecoder().decode(RemoteAdFeed.self, from: data) else { return }
        ads = feed.ads
        lastUpdated = (try? cacheURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }

    private func saveCache(_ data: Data) {
        guard let cacheURL else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}

// MARK: – Plätze in der Oberfläche

/// Wo eine Anzeige stehen kann. Bislang nur die Fläche unter den Namen in der
/// Minigolfkarte; weitere Plätze kommen hier dazu und müssen im Adminpanel
/// dieselbe Kennung tragen.
enum AdPlacement: String {
    case minigolfScoring = "minigolf_scoring"
}

// MARK: – Format der API

struct RemoteAdFeed: Codable {
    let version: Int
    let generatedAt: String?
    let ads: [RemoteAd]
}

struct RemoteAd: Codable, Identifiable, Hashable {
    let id: String
    let placement: String
    /// Kennung der Anlage – leer heißt „überall".
    let courseID: String
    let title: String
    let subtitle: String
    let imageURL: String
    let linkURL: String
    let advertiser: String
    let weight: Int
    /// Tagesdaten im Format `JJJJ-MM-TT`, `nil` heißt unbegrenzt.
    let startsOn: String?
    let endsOn: String?

    var isEverywhere: Bool { courseID.isEmpty }

    var link: URL? { linkURL.isEmpty ? nil : URL(string: linkURL) }
    var image: URL? { imageURL.isEmpty ? nil : URL(string: imageURL) }

    /// Der Server filtert schon nach Zeitraum. Weil der Cache Tage alt sein
    /// kann, prüft das Gerät zusätzlich selbst – sonst läuft eine abgelaufene
    /// Anzeige auf einer Anlage ohne Empfang weiter.
    func isRunning(on date: Date) -> Bool {
        let today = Self.dayFormatter.string(from: date)
        if let startsOn, today < startsOn { return false }
        if let endsOn, today > endsOn { return false }
        return true
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct AdEvent: Encodable {
    let id: String
    let type: String
    let count: Int
}

private struct AdEventBatch: Encodable {
    let events: [AdEvent]
}
