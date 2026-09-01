import Foundation

/// Welche Art Platz hinter einem Link steckt.
enum CourseLinkKind: String, Codable, Sendable {
    case golf
    case minigolf

    /// Der Pfadbestandteil in `https://golftrack.app/<pfad>/<kennung>`.
    var path: String { rawValue }
}

/// Ein eingehender Link auf einen bestimmten Platz.
struct CourseLink: Equatable, Sendable {
    let kind: CourseLinkKind
    let slug: String
}

/// Links, die direkt an einem bestimmten Platz eine Runde starten – aus dem
/// QR-Code am Kassenhäuschen oder vom Aushang am ersten Abschlag.
///
/// Zwei Formen, beide landen im selben Ablauf:
///
/// - `golftrack://golf?platz=bayerwald` bzw. `golftrack://minigolf?platz=…`
///   Funktioniert, sobald GolfTrack installiert ist. Ohne App passiert nichts.
/// - `https://golftrack.app/golf/bayerwald` bzw. `…/minigolf/…`
///   Universal Link und zugleich die Adresse für den App Clip. Dafür müssen
///   beide Pfade in der `apple-app-site-association` stehen.
///
/// `MinigolfDeepLink` bleibt daneben bestehen; es ist die ältere, engere
/// Fassung und wird von den Stellen benutzt, die es ohnehin nur mit Minigolf
/// zu tun haben.
enum CourseDeepLink {

    static let scheme = "golftrack"
    static let courseQueryItem = "platz"
    static let webBaseURL = URL(string: "https://golftrack.app")!

    static func webURL(kind: CourseLinkKind, slug: String) -> URL {
        webBaseURL.appendingPathComponent(kind.path).appendingPathComponent(slug)
    }

    static func appURL(kind: CourseLinkKind, slug: String) -> URL {
        let encoded = slug.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? slug
        return URL(string: "\(scheme)://\(kind.path)?\(courseQueryItem)=\(encoded)")
            ?? webURL(kind: kind, slug: slug)
    }

    /// Platzart und Kennung aus einem eingehenden Link – `nil`, wenn der Link
    /// zu keinem Platz gehört.
    static func link(from url: URL) -> CourseLink? {
        if url.scheme == scheme {
            guard let host = url.host, let kind = CourseLinkKind(rawValue: host) else { return nil }
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let value = components?.queryItems?.first(where: { $0.name == courseQueryItem })?.value,
               !value.isEmpty {
                return CourseLink(kind: kind, slug: value)
            }
            // Auch golftrack://golf/bayerwald akzeptieren
            if let first = url.path.split(separator: "/").map(String.init).first {
                return CourseLink(kind: kind, slug: first)
            }
            return nil
        }

        guard url.scheme == "https" else { return nil }
        let parts = url.path.split(separator: "/").map(String.init)
        // …/<art>/<kennung>
        for (index, part) in parts.enumerated() {
            guard let kind = CourseLinkKind(rawValue: part), index + 1 < parts.count else { continue }
            return CourseLink(kind: kind, slug: parts[index + 1])
        }
        return nil
    }
}
