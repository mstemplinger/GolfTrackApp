import Foundation

/// Die Rechtstexte stehen auf golftrack.app. Früher zeigten die Paywalls auf
/// die alte GitHub-Pages-Seite; die kannte weder Abos noch die heutigen Texte.
enum LegalLinks {
    /// Deutsch liegt ohne Präfix, alles andere bekommt die englische Fassung –
    /// Französisch, Italienisch und Spanisch gibt es auf der Website nicht.
    static var privacy: URL {
        let german = Locale.current.language.languageCode?.identifier == "de"
        return URL(string: german
            ? "https://golftrack.app/datenschutz"
            : "https://golftrack.app/en/privacy")!
    }

    /// Apples Standard-EULA, wie in App Store Connect hinterlegt.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
