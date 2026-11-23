import Foundation

/// Anonyme Rundenstatistik für Platzbetreiber.
///
/// Nach einer Runde auf einem Platz aus dem Verzeichnis schickt das Gerät –
/// nur mit Einwilligung – eine grobe Zusammenfassung an golftrack.app:
/// Spieltag, Tagesabschnitt (vormittags/mittags/nachmittags/abends), Dauer in
/// 15-Minuten-Stufen, Gruppengröße und Schläge (Golf: auch Putts) je Loch.
///
/// **Nicht** gesendet werden: Namen, Uhrzeit, Laufspur, Koordinaten, Schläger,
/// Handicap, Geräte- oder Rundenkennung. Der Server speichert auch keinen
/// Eingangszeitpunkt und keine Netzadresse (`web/src/lib/roundStats.ts`).
/// Betreiber sehen später nur Summen ab zehn Runden.
///
/// Liegt in GolfTrackShared, weil App und App Clip ihn gleichermaßen nutzen.
/// Ohne Netz bleibt der Beitrag liegen und geht beim nächsten Start raus.
@MainActor
final class RoundStatsService {

    static let shared = RoundStatsService()

    // MARK: Einwilligung

    static let consentKey = "roundStats.consent"
    static let askedKey = "roundStats.asked"

    /// Vom Spieler erlaubt – Standard: aus.
    static var hasConsent: Bool {
        get { UserDefaults.standard.bool(forKey: consentKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: consentKey)
            UserDefaults.standard.set(true, forKey: askedKey)
        }
    }

    /// Ob die Frage schon einmal gestellt wurde (egal mit welcher Antwort).
    static var wasAsked: Bool { UserDefaults.standard.bool(forKey: askedKey) }

    // MARK: Konfiguration

    static func endpoint(slug: String) -> URL {
        URL(string: "https://golftrack.app/api/v1/courses")!
            .appendingPathComponent(slug)
            .appendingPathComponent("round-stats")
    }

    /// Liegengebliebene Beiträge werden nach dieser Zeit verworfen
    /// (der Server nimmt ohnehin nichts älter als 30 Tage an).
    static let pendingLifetime: TimeInterval = 14 * 24 * 60 * 60
    private static let pendingKey = "roundStats.pending"

    private var isFlushing = false

    private init() {}

    // MARK: Nutzlast

    enum Kind: String, Codable { case golf, minigolf }
    enum Source: String, Codable { case app, clip, web }

    struct Payload: Codable, Equatable {
        var version = 1
        let kind: Kind
        let day: String
        let slot: String
        let weekday: Int
        let holesPlayed: Int
        let durationMinutes: Int?
        let teeColor: String?
        let strokes: [[Int]]
        let putts: [[Int]]?
        let source: Source
    }

    struct PendingUpload: Codable {
        let slug: String
        let payload: Payload
        let createdAt: Date
    }

    /// Baut die Zusammenfassung. `strokes`/`putts`: je Spieler ein Feld mit
    /// den Schlägen je Loch, 0 = nicht gespielt. `startedAt` nur, wenn der
    /// Beginn wirklich bekannt ist – sonst bleibt die Dauer leer.
    static func payload(kind: Kind,
                        startedAt: Date?,
                        endedAt: Date,
                        strokes: [[Int]],
                        putts: [[Int]]? = nil,
                        teeColor: String? = nil,
                        source: Source,
                        calendar: Calendar = .current) -> Payload? {
        let rows = strokes.map { $0.map { min(max($0, 0), 20) } }
        guard let first = rows.first, !first.isEmpty, rows.count <= 8,
              rows.allSatisfy({ $0.count == first.count }) else { return nil }
        let holesPlayed = (0..<first.count).filter { hole in rows.contains { $0[hole] > 0 } }.count
        guard holesPlayed > 0 else { return nil }

        let reference = startedAt ?? endedAt
        return Payload(kind: kind,
                       day: dayString(reference, calendar: calendar),
                       slot: slot(for: reference, calendar: calendar),
                       weekday: isoWeekday(reference, calendar: calendar),
                       holesPlayed: holesPlayed,
                       durationMinutes: duration(kind: kind, from: startedAt, to: endedAt, holes: holesPlayed),
                       teeColor: kind == .golf ? teeColor : nil,
                       strokes: rows,
                       putts: kind == .golf ? putts?.map { $0.map { min(max($0, 0), 20) } } : nil,
                       source: source)
    }

    static func dayString(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Vormittag < 11 Uhr, Mittag < 14, Nachmittag < 18, sonst Abend.
    static func slot(for date: Date, calendar: Calendar) -> String {
        switch calendar.component(.hour, from: date) {
        case ..<11: return "morning"
        case ..<14: return "midday"
        case ..<18: return "afternoon"
        default: return "evening"
        }
    }

    /// 1 = Montag … 7 = Sonntag (Foundation zählt ab Sonntag = 1).
    static func isoWeekday(_ date: Date, calendar: Calendar) -> Int {
        let w = calendar.component(.weekday, from: date)
        return (w + 5) % 7 + 1
    }

    /// Dauer auf 15 Minuten gerundet – nur, wenn sie zur Lochzahl passt.
    /// Golf: 3–30 min je Loch; Minigolf: 0,5–10 min je Bahn.
    static func duration(kind: Kind, from start: Date?, to end: Date, holes: Int) -> Int? {
        guard let start, holes > 0 else { return nil }
        let minutes = end.timeIntervalSince(start) / 60
        let perHole = minutes / Double(holes)
        let range: ClosedRange<Double> = kind == .golf ? 3...30 : 0.5...10
        guard range.contains(perHole) else { return nil }
        let rounded = Int((minutes / 15).rounded()) * 15
        return min(max(rounded, 15), 600)
    }

    // MARK: Senden

    /// Nach dem Abschluss einer Runde: Beitrag vormerken und senden, wenn
    /// erlaubt. Tut sonst nichts.
    func contribute(slug: String, payload: Payload) {
        guard Self.hasConsent, !slug.isEmpty else { return }
        var pending = loadPending()
        pending.append(PendingUpload(slug: slug, payload: payload, createdAt: .now))
        savePending(pending)
        Task { await flushPending() }
    }

    /// Schickt liegengebliebene Beiträge. Wird nach dem Abschluss einer Runde
    /// und beim Start aufgerufen.
    func flushPending() async {
        guard !isFlushing else { return }
        isFlushing = true
        defer { isFlushing = false }

        // Einwilligung zurückgezogen → nichts mehr senden, auch nichts Altes.
        guard Self.hasConsent else {
            savePending([])
            return
        }

        var remaining: [PendingUpload] = []
        for upload in loadPending() where upload.createdAt.timeIntervalSinceNow > -Self.pendingLifetime {
            if await !send(upload) { remaining.append(upload) }
        }
        savePending(remaining)
    }

    /// `true`, wenn der Beitrag erledigt ist – angenommen oder endgültig
    /// abgelehnt. `false` heißt: später noch einmal versuchen.
    private func send(_ upload: PendingUpload) async -> Bool {
        var request = URLRequest(url: Self.endpoint(slug: upload.slug))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        guard let body = try? JSONEncoder().encode(upload.payload) else { return true }
        request.httpBody = body
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            return !(status == 429 || status >= 500 || status == 0)
        } catch {
            return false
        }
    }

    private func loadPending() -> [PendingUpload] {
        guard let data = UserDefaults.standard.data(forKey: Self.pendingKey) else { return [] }
        return (try? JSONDecoder().decode([PendingUpload].self, from: data)) ?? []
    }

    private func savePending(_ uploads: [PendingUpload]) {
        if uploads.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.pendingKey)
        } else if let data = try? JSONEncoder().encode(Array(uploads.suffix(20))) {
            UserDefaults.standard.set(data, forKey: Self.pendingKey)
        }
    }
}
