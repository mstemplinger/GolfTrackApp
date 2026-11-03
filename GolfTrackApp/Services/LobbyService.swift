import CoreLocation
import Foundation
import Observation
import SwiftData

// MARK: - Datenvertrag mit golftrack.app (`web/src/lib/lobby.ts`)

struct LobbyShot: Codable, Hashable {
    var n: Int
    var club: String
    var lat: Double?
    var lon: Double?
    var meters: Double?
}

struct LobbyHole: Codable, Hashable {
    var hole: Int
    var strokes: Int
    var putts: Int
    var fairway: Bool
    var gir: Bool
    var shots: [LobbyShot]
}

struct LobbyLocation: Codable, Hashable {
    var lat: Double
    var lon: Double
    var accuracy: Double
    var at: Date

    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lon) }
}

struct LobbyMember: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var isHost: Bool
    var currentHole: Int
    var scores: [LobbyHole]
    var seenAt: Date
    var location: LobbyLocation?

    func hole(_ number: Int) -> LobbyHole? { scores.first { $0.hole == number } }
    var playedHoles: [LobbyHole] { scores.filter { $0.strokes > 0 } }
    var totalStrokes: Int { playedHoles.reduce(0) { $0 + $1.strokes } }

    /// Ergebnis zum Par über die gespielten Löcher.
    func toPar(pars: [Int]) -> Int? {
        let played = playedHoles.filter { $0.hole - 1 < pars.count }
        guard !played.isEmpty else { return nil }
        return played.reduce(0) { $0 + $1.strokes - pars[$1.hole - 1] }
    }

    /// Länger als zwei Minuten nichts gehört – Funkloch oder App zu.
    var isStale: Bool { Date().timeIntervalSince(seenAt) > 120 }
}

struct LobbyState: Codable, Hashable {
    var code: String
    var courseName: String
    var courseSlug: String
    var holes: Int
    var tracking: Bool
    var me: String
    var members: [LobbyMember]

    var others: [LobbyMember] { members.filter { $0.id != me } }
    var host: LobbyMember? { members.first(where: \.isHost) }
}

/// Was in der App gespeichert bleibt, damit die Lobby einen Neustart übersteht.
private struct LobbySession: Codable {
    var code: String
    var memberId: String
    var token: String
    var isHost: Bool
}

// MARK: - Dienst

/// Lobby für gemeinsame Runden: Code anlegen oder beitreten, eigenen Stand
/// melden, den der Freunde abholen und – wenn alle einverstanden sind – sich
/// gegenseitig auf dem Platz wiederfinden.
///
/// Jeder spielt auf dem eigenen iPhone. Der Server (`golftrack.app/api/v1/lobby`)
/// hält nur den letzten Stand jedes Mitspielers und löscht die Lobby nach
/// einem Tag ohne Lebenszeichen. Abgeglichen wird per Abfrage alle paar
/// Sekunden, solange die App vorn ist; mit geteiltem Standort meldet sie ihre
/// Lage auch bei gesperrtem Display weiter.
@MainActor
@Observable
final class LobbyService: NSObject {

    static let shared = LobbyService()

    static let baseURL = URL(string: "https://golftrack.app/api/v1/lobby")!
    /// Universal Link im QR-Code – mit Kamera-App gescannt öffnet er den Beitritt.
    static func joinURL(code: String) -> URL { URL(string: "https://golftrack.app/lobby/\(code)")! }

    private static let sessionKey = "lobby.session"
    private static let shareLocationKey = "lobby.shareLocation"
    private static let pollInterval: Duration = .seconds(4)
    /// Standort höchstens so oft melden – genug, um sich auf dem Platz zu finden.
    private static let locationInterval: TimeInterval = 10

    private(set) var state: LobbyState?
    private(set) var isBusy = false
    var errorMessage: String?
    /// Die Lobby wurde vom Gastgeber beendet oder man wurde entfernt.
    var endedNotice: String?

    /// Eigener Standort an die Lobby – nur wirksam, wenn der Gastgeber das
    /// gegenseitige Orten eingeschaltet hat.
    var shareLocation: Bool {
        didSet {
            UserDefaults.standard.set(shareLocation, forKey: Self.shareLocationKey)
            updateLocationUpdates()
            Task { await push(LobbyPush(shareLocation: shareLocation, location: shareLocation ? currentLocationPayload : nil)) }
        }
    }

    private(set) var myLocation: CLLocation?

    private var session: LobbySession?
    private var pollTask: Task<Void, Never>?
    private let manager = CLLocationManager()
    private var lastLocationSent: Date?
    private var lastScoresSent: [LobbyHole]?
    private var lastHoleSent: Int?
    private var attachedRound: Round?

    var isActive: Bool { session != nil }
    var isHost: Bool { session?.isHost ?? false }
    var code: String? { session?.code }

    private override init() {
        shareLocation = UserDefaults.standard.object(forKey: Self.shareLocationKey) as? Bool ?? true
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 5
        if let data = UserDefaults.standard.data(forKey: Self.sessionKey),
           let saved = try? JSONDecoder().decode(LobbySession.self, from: data) {
            session = saved
        }
    }

    // MARK: Anlegen, Beitreten, Verlassen

    func create(name: String, courseName: String, courseSlug: String, holes: Int, tracking: Bool) async {
        await run {
            struct Body: Encodable { let name, courseName, courseSlug: String; let holes: Int; let tracking: Bool }
            struct Reply: Decodable { let code, memberId, token: String }
            let reply: Reply = try await self.request(
                Self.baseURL, method: "POST",
                body: Body(name: Self.clean(name), courseName: courseName, courseSlug: courseSlug,
                           holes: holes, tracking: tracking))
            self.begin(LobbySession(code: reply.code, memberId: reply.memberId, token: reply.token, isHost: true))
        }
    }

    func join(code: String, name: String) async {
        let code = code.filter(\.isNumber)
        guard code.count == 5 else {
            errorMessage = String(localized: "Der Lobby-Code hat fünf Ziffern.")
            return
        }
        await run {
            struct Body: Encodable { let name: String }
            struct Reply: Decodable { let code, memberId, token: String }
            let reply: Reply = try await self.request(
                Self.baseURL.appending(path: "\(code)/join"), method: "POST",
                body: Body(name: Self.clean(name)))
            self.begin(LobbySession(code: reply.code, memberId: reply.memberId, token: reply.token, isHost: false))
        }
    }

    func leave() async {
        guard let session else { return }
        var req = URLRequest(url: Self.baseURL.appending(path: session.code))
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(session.token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: req)
        end()
    }

    /// Nur der Gastgeber: gegenseitiges Orten für alle an- oder ausschalten.
    func setTracking(_ enabled: Bool) async {
        await settings(["tracking": AnyEncodable(enabled)])
    }

    /// Nur der Gastgeber: Platz der Lobby ändern – die Gäste übernehmen ihn.
    func setCourse(name: String, slug: String, holes: Int) async {
        guard isHost, let state, state.courseName != name || state.holes != holes else { return }
        struct CourseBody: Encodable { let name, slug: String; let holes: Int }
        await settings(["course": AnyEncodable(CourseBody(name: name, slug: slug, holes: holes))])
    }

    /// Nur der Gastgeber: jemanden aus der Lobby nehmen.
    func remove(_ member: LobbyMember) async {
        await settings(["kick": AnyEncodable(member.id)])
    }

    // MARK: Runde

    /// Verbindet die laufende Runde mit der Lobby: eigener Stand geht raus,
    /// der Stand der Freunde landet – bei Spielformen mit Mitspielern – in
    /// deren Scorekarte.
    func attach(round: Round) {
        guard isActive, round.lobbyCode == session?.code else { return }
        attachedRound = round
        startPolling()
        updateLocationUpdates()
    }

    func detach(round: Round) {
        guard attachedRound === round else { return }
        attachedRound = nil
    }

    /// Eigenen Stand melden, wenn er sich geändert hat.
    func publish(round: Round, currentHole: Int) {
        guard isActive, round.lobbyCode == session?.code else { return }
        let scores = Self.payload(for: round)
        var update = LobbyPush()
        if scores != lastScoresSent { update.scores = scores }
        if currentHole != lastHoleSent { update.currentHole = currentHole }
        guard update.scores != nil || update.currentHole != nil else { return }
        Task { await push(update) }
    }

    /// Runde abgeschlossen: Stand ein letztes Mal melden, Standort nicht mehr teilen.
    func roundFinished(_ round: Round) {
        guard isActive, round.lobbyCode == session?.code else { return }
        attachedRound = nil
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        Task { await push(LobbyPush(scores: Self.payload(for: round), location: .some(nil))) }
    }

    // MARK: Abgleich

    func startPolling() {
        guard isActive, pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    /// Außerhalb von Lobby-Karte und Runde nicht weiter abfragen.
    func pauseIfIdle() {
        if attachedRound == nil { stopPolling() }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh() async {
        guard let session else { return }
        do {
            let fresh: LobbyState = try await request(
                Self.baseURL.appending(path: session.code), method: "GET", body: Optional<String>.none)
            apply(fresh)
        } catch LobbyError.gone {
            endedByServer()
        } catch {
            // Funkloch: beim nächsten Durchgang wieder.
        }
    }

    private func push(_ update: LobbyPush) async {
        guard let session else { return }
        do {
            let fresh: LobbyState = try await request(
                Self.baseURL.appending(path: "\(session.code)/state"), method: "POST", body: update)
            if let scores = update.scores { lastScoresSent = scores }
            if let hole = update.currentHole { lastHoleSent = hole }
            apply(fresh)
        } catch LobbyError.gone {
            endedByServer()
        } catch {}
    }

    private func settings(_ body: [String: AnyEncodable]) async {
        guard let session, session.isHost else { return }
        await run {
            let fresh: LobbyState = try await self.request(
                Self.baseURL.appending(path: "\(session.code)/settings"), method: "POST", body: body)
            self.apply(fresh)
        }
    }

    private func apply(_ fresh: LobbyState) {
        let trackingChanged = state?.tracking != fresh.tracking
        state = fresh
        if trackingChanged { updateLocationUpdates() }
        if let round = attachedRound { Self.mirror(fresh, into: round) }
    }

    // MARK: Sitzung

    private func begin(_ new: LobbySession) {
        session = new
        lastScoresSent = nil
        lastHoleSent = nil
        if let data = try? JSONEncoder().encode(new) {
            UserDefaults.standard.set(data, forKey: Self.sessionKey)
        }
        startPolling()
    }

    private func end() {
        stopPolling()
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        session = nil
        state = nil
        attachedRound = nil
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
    }

    private func endedByServer() {
        let wasHost = isHost
        end()
        endedNotice = wasHost
            ? String(localized: "Die Lobby ist abgelaufen.")
            : String(localized: "Die Lobby wurde beendet oder du wurdest entfernt.")
    }

    // MARK: Standort

    private var wantsLocation: Bool {
        isActive && shareLocation && (state?.tracking ?? false) && attachedRound != nil
    }

    private func updateLocationUpdates() {
        guard wantsLocation else {
            manager.stopUpdatingLocation()
            manager.allowsBackgroundLocationUpdates = false
            return
        }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            // Hintergrundmodus `location` ist gesetzt (Laufspur) – damit finden
            // die anderen einen auch mit gesperrtem Display.
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    private var currentLocationPayload: LobbyPush.Location? {
        myLocation.map { .init(lat: $0.coordinate.latitude, lon: $0.coordinate.longitude,
                               accuracy: max(0, $0.horizontalAccuracy)) }
    }

    fileprivate func received(_ location: CLLocation) {
        myLocation = location
        guard wantsLocation else { return }
        if let last = lastLocationSent, Date().timeIntervalSince(last) < Self.locationInterval { return }
        lastLocationSent = .now
        Task { await push(LobbyPush(location: .some(currentLocationPayload))) }
    }

    fileprivate func authorizationChanged() { updateLocationUpdates() }

    // MARK: Abbildung Runde ↔ Lobby

    private static func payload(for round: Round) -> [LobbyHole] {
        round.sortedScores.map { score in
            LobbyHole(
                hole: score.holeNumber,
                strokes: score.strokes,
                putts: score.putts,
                fairway: score.fairwayHit,
                gir: score.greenInRegulation,
                shots: score.sortedShots.map { shot in
                    let located = shot.fromLatitude != 0 || shot.fromLongitude != 0
                    return LobbyShot(
                        n: shot.shotNumber,
                        club: String(shot.club.prefix(40)),
                        lat: located ? shot.fromLatitude : nil,
                        lon: located ? shot.fromLongitude : nil,
                        meters: located && shot.distanceMeters > 0 ? min(shot.distanceMeters, 1000) : nil)
                })
        }
    }

    /// Bei Spielformen mit Mitspielern stehen die Freunde als Mitspieler in der
    /// Runde (`Round.lobbyMemberIDs`). Ihre Schläge kommen von ihrem eigenen
    /// iPhone und werden hier eingetragen – Matchplay, Skins usw. rechnen dann
    /// wie gewohnt.
    private static func mirror(_ state: LobbyState, into round: Round) {
        let ids = round.lobbyMemberIDs
        guard !ids.isEmpty else { return }
        for (offset, id) in ids.enumerated() {
            guard let member = state.members.first(where: { $0.id == id }) else { continue }
            let playerIndex = offset + 1
            // Nur gespielte Löcher – solange der Freund nichts eingetragen hat,
            // bleibt stehen, was hier von Hand eingetragen wurde.
            for hole in member.scores where hole.strokes > 0 {
                guard let entry = round.opponentScore(playerIndex: playerIndex, holeNumber: hole.hole) else { continue }
                if entry.strokes != hole.strokes { entry.strokes = hole.strokes }
                if entry.putts != hole.putts { entry.putts = hole.putts }
                if entry.fairwayHit != hole.fairway { entry.fairwayHit = hole.fairway }
                if entry.greenInRegulation != hole.gir { entry.greenInRegulation = hole.gir }
            }
        }
    }

    // MARK: Netz

    private func run(_ work: @escaping () async throws -> Void) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await work()
        } catch let error as LobbyError {
            errorMessage = error.message
        } catch {
            errorMessage = String(localized: "Keine Verbindung zum Server. Prüf die Internetverbindung.")
        }
    }

    private func request<Body: Encodable, Reply: Decodable>(
        _ url: URL, method: String, body: Body?
    ) async throws -> Reply {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = method
        if let token = session?.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200..<300:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let raw = try decoder.singleValueContainer().decode(String.self)
                return Self.isoFractional.date(from: raw) ?? Self.iso.date(from: raw) ?? .now
            }
            return try decoder.decode(Reply.self, from: data)
        case 401:
            throw LobbyError.gone
        case 404:
            // Beim Beitreten heißt 404 „falscher Code", sonst ist die Lobby weg.
            throw url.path.hasSuffix("/join") || session == nil ? LobbyError.notFound : LobbyError.gone
        case 409: throw LobbyError.full
        case 429: throw LobbyError.rateLimited
        default: throw LobbyError.server
        }
    }

    nonisolated(unsafe) private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    nonisolated(unsafe) private static let iso = ISO8601DateFormatter()

    private static func clean(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String((trimmed.isEmpty ? "Golfer" : trimmed).prefix(30))
    }
}

extension LobbyService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last, last.horizontalAccuracy >= 0 else { return }
        Task { @MainActor in LobbyService.shared.received(last) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in LobbyService.shared.authorizationChanged() }
    }
}

// MARK: - Hilfstypen

/// Teilmeldung an `/state` – nur gesetzte Felder werden übertragen.
private struct LobbyPush: Encodable {
    struct Location: Encodable { let lat, lon, accuracy: Double }

    var currentHole: Int?
    var scores: [LobbyHole]?
    var shareLocation: Bool?
    /// `.some(nil)` löscht den Standort am Server, `nil` lässt ihn stehen.
    var location: Location??

    enum CodingKeys: String, CodingKey { case currentHole, scores, shareLocation, location }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(currentHole, forKey: .currentHole)
        try c.encodeIfPresent(scores, forKey: .scores)
        try c.encodeIfPresent(shareLocation, forKey: .shareLocation)
        if let location {
            if let location { try c.encode(location, forKey: .location) } else { try c.encodeNil(forKey: .location) }
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void
    init(_ value: some Encodable) { encodeValue = value.encode }
    func encode(to encoder: Encoder) throws { try encodeValue(encoder) }
}

private enum LobbyError: Error {
    case gone, notFound, full, rateLimited, server

    var message: String {
        switch self {
        case .gone, .notFound: String(localized: "Zu diesem Code gibt es keine Lobby. Prüf die fünf Ziffern.")
        case .full: String(localized: "Die Lobby ist voll – mehr als acht Spieler gehen nicht.")
        case .rateLimited: String(localized: "Zu viele Versuche. Warte ein paar Minuten.")
        case .server: String(localized: "Der Server hat nicht geantwortet. Versuch es gleich noch einmal.")
        }
    }
}
