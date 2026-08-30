import Foundation

/// Links, die direkt eine Minigolfrunde an einer bestimmten Anlage starten –
/// aus dem QR-Code am Kassenhäuschen, von einem NFC-Tag oder später aus dem
/// App Clip.
///
/// Es gibt zwei Formen, beide landen im selben Startbildschirm:
///
/// - `golftrack://minigolf?platz=sankt-englmar`
///   Funktioniert sofort – die Kamera-App bietet den Link an, sobald GolfTrack
///   installiert ist. Ohne installierte App passiert nichts.
/// - `https://golftrack.app/minigolf/sankt-englmar`
///   Universal Link und zugleich die Adresse für den App Clip, der ohne
///   vollständigen Download startet. Dafür sind zusätzlich nötig:
///   `com.apple.developer.associated-domains` mit `applinks:` **und**
///   `appclips:`, eine `apple-app-site-association` unter
///   `/.well-known/` auf der Domain sowie die App-Clip-Experience in
///   App Store Connect.
///
/// Die QR-Codes zum Aushängen gibt es auf golftrack.app in der Platzliste –
/// nicht in der App.
enum MinigolfDeepLink {

    static let scheme = "golftrack"
    static let host = "minigolf"
    static let courseQueryItem = "platz"
    /// Basis der Universal Links. Zeigt auf die Domain, die auch die
    /// `apple-app-site-association` ausliefert.
    static let webBaseURL = URL(string: "https://golftrack.app")!

    static func url(for courseID: String) -> URL {
        let slug = courseID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? courseID
        return URL(string: "\(scheme)://\(host)?\(courseQueryItem)=\(slug)") ?? webURL(for: courseID)
    }

    static func webURL(for courseID: String) -> URL {
        webBaseURL.appendingPathComponent(host).appendingPathComponent(courseID)
    }

    /// Kennung der Anlage aus einem eingehenden Link – egal in welcher Form.
    static func courseID(from url: URL) -> String? {
        if url.scheme == scheme {
            guard url.host == host else { return nil }
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let value = components?.queryItems?.first(where: { $0.name == courseQueryItem })?.value,
               !value.isEmpty {
                return value
            }
            // Auch golftrack://minigolf/sankt-englmar akzeptieren
            return url.path.split(separator: "/").map(String.init).first
        }

        // Universal Link: …/minigolf/<id>
        guard url.scheme == "https" else { return nil }
        let parts = url.path.split(separator: "/").map(String.init)
        guard let index = parts.firstIndex(of: host), index + 1 < parts.count else { return nil }
        return parts[index + 1]
    }

    /// Bekannte Anlage hinter einem Link – `nil`, wenn der Link nichts mit
    /// Minigolf zu tun hat oder die Kennung unbekannt ist.
    static func course(from url: URL) -> MinigolfCourseEntry? {
        guard let id = courseID(from: url) else { return nil }
        return MinigolfCourses.course(id: id)
    }
}
