import Combine
import Foundation
import Security

/// Weiterempfehlung: Wer GolfTrack fünf Freunden empfiehlt, bekommt zwei Wochen
/// Pro geschenkt – als Apple-Angebotscode, den golftrack.app austeilt
/// (`web/src/lib/referral.ts`).
///
/// Ein Freund zählt erst, wenn seine App den Code einlöst: über den Link
/// `golftrack.app/einladen/<code>` oder von Hand im Profil. Das Gerät weist sich
/// mit einer zufälligen Kennung aus dem Schlüsselbund aus – sie übersteht eine
/// Neuinstallation, damit Löschen und Neuladen nicht erneut zählt.
@MainActor
final class ReferralService: ObservableObject {
    static let shared = ReferralService()

    static let baseURL = URL(string: "https://golftrack.app/api/v1/referral")!
    static func inviteURL(code: String) -> URL { URL(string: "https://golftrack.app/einladen/\(code)")! }

    struct Status: Codable, Equatable {
        let code: String
        let friends: Int
        let needed: Int
        let rewardCode: String?
        let rewardUrl: String?
        let rewardPending: Bool
    }

    enum ClaimResult: Equatable {
        case counted, ownCode, alreadyCounted, notFound, rateLimited, offline
    }

    @Published private(set) var status: Status?
    @Published private(set) var isLoading = false
    /// Schon einen Freundescode eingelöst – das Eingabefeld verschwindet dann.
    @Published private(set) var hasClaimed = UserDefaults.standard.bool(forKey: claimedKey)

    private static let claimedKey = "referral.hasClaimed"
    private static let statusKey = "referral.status"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.statusKey) {
            status = try? JSONDecoder().decode(Status.self, from: data)
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        guard let (data, code) = try? await post(Self.baseURL, body: ["device": Self.deviceID]),
              code == 200,
              let fresh = try? JSONDecoder().decode(Status.self, from: data) else { return }
        status = fresh
        UserDefaults.standard.set(data, forKey: Self.statusKey)
    }

    func claim(_ raw: String) async -> ClaimResult {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard Self.isValidCode(code) else { return .notFound }
        if code == status?.code { return .ownCode }
        guard let (_, status) = try? await post(
            Self.baseURL.appending(path: "\(code)/claim"), body: ["device": Self.deviceID]
        ) else { return .offline }
        let result: ClaimResult
        switch status {
        case 200..<300: result = .counted
        case 404: result = .notFound
        case 429: result = .rateLimited
        case 409: result = .alreadyCounted
        default: result = .offline
        }
        if result == .counted || result == .alreadyCounted {
            hasClaimed = true
            UserDefaults.standard.set(true, forKey: Self.claimedKey)
        }
        return result
    }

    /// Sechs Zeichen ohne verwechselbare (0/O, 1/I/L) – wie auf dem Server.
    static func isValidCode(_ code: String) -> Bool {
        let allowed = Set("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return code.count == 6 && code.allSatisfy(allowed.contains)
    }

    private func post(_ url: URL, body: [String: String]) async throws -> (Data, Int) {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    // MARK: - Gerätekennung im Schlüsselbund

    private static let keychainService = "app.golftrack.referral"
    private static let keychainAccount = "device"

    static var deviceID: String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
        ]
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
           let data = item as? Data, let id = String(data: data, encoding: .utf8) {
            return id
        }
        let id = UUID().uuidString
        let add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: Data(id.utf8),
        ]
        SecItemAdd(add as CFDictionary, nil)
        return id
    }
}

/// Einladungslink `golftrack.app/einladen/<code>` bzw. `golftrack://einladen/<code>`.
enum ReferralLink {
    static func code(from url: URL) -> String? {
        let parts = url.pathComponents.filter { $0 != "/" }
        let candidate: String?
        if url.scheme == CourseDeepLink.scheme, url.host == "einladen" {
            candidate = parts.first
        } else if parts.count == 2, parts[0] == "einladen" {
            candidate = parts[1]
        } else {
            candidate = nil
        }
        guard let code = candidate?.uppercased(), ReferralService.isValidCode(code) else { return nil }
        return code
    }
}
