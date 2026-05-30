import Foundation
import Observation

enum APIError: LocalizedError {
    case missingAPIKey
    case unauthorized
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Kein API-Key hinterlegt. Bitte in den Einstellungen eintragen."
        case .unauthorized:
            return "API-Key ungültig. Bitte in den Einstellungen prüfen."
        case .httpError(let code):
            return "API-Fehler (HTTP \(code))"
        case .networkError(let e):
            return "Netzwerkfehler: \(e.localizedDescription)"
        case .decodingError:
            return "Unbekanntes Antwortformat der API."
        }
    }
}

@Observable
final class GolfCourseAPIService {
    static let shared = GolfCourseAPIService()

    private let baseURL = "https://api.golfcourseapi.com"
    static let apiKeyDefaultsKey = "golfcourse_api_key"

    var apiKey: String = UserDefaults.standard.string(forKey: apiKeyDefaultsKey) ?? "" {
        didSet { UserDefaults.standard.set(apiKey, forKey: Self.apiKeyDefaultsKey) }
    }

    var hasAPIKey: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Search

    func search(query: String) async throws -> [APICourse] {
        guard hasAPIKey else { throw APIError.missingAPIKey }
        var comps = URLComponents(string: "\(baseURL)/v1/search")!
        comps.queryItems = [URLQueryItem(name: "search_query", value: query)]
        guard let url = comps.url else { throw APIError.httpError(0) }
        let data = try await fetch(makeRequest(url))
        return try decode(APISearchResponse.self, from: data).courses
    }

    // MARK: - Get by ID (full data with holes)

    func getCourse(id: Int) async throws -> APICourse {
        guard hasAPIKey else { throw APIError.missingAPIKey }
        let url = URL(string: "\(baseURL)/v1/courses/\(id)")!
        let data = try await fetch(makeRequest(url))
        return try decode(APICourse.self, from: data)
    }

    // MARK: - Private helpers

    private func makeRequest(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue("Key \(apiKey.trimmingCharacters(in: .whitespaces))",
                     forHTTPHeaderField: "Authorization")
        return req
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 { throw APIError.unauthorized }
                if http.statusCode != 200 { throw APIError.httpError(http.statusCode) }
            }
            return data
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
