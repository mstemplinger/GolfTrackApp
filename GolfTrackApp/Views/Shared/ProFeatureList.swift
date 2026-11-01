import SwiftUI

/// Eine Zeile in der Leistungsliste einer Paywall.
typealias PaywallFeature = (icon: String, color: Color, text: LocalizedStringKey)

/// Leistungen des Pro-Abos – gemeinsam für Training- und Caddy-Paywall, damit
/// beide dieselbe Liste zeigen. Jede Zeile steht für etwas, das die App wirklich
/// kann: Pro schaltet das Training (Audios, Empfehlungen, Putt-Lektionen) und den
/// Caddy (Sprachassistent mit Regeln, WHS, Strategie) frei, dazu keine Werbung.
enum ProFeatureList {

    /// - Parameter caddyFirst: In der Caddy-Paywall stehen die Caddy-Leistungen oben.
    static func features(caddyFirst: Bool = false) -> [PaywallFeature] {
        let count = allLessons.filter(\.isAvailable).count

        let training: [PaywallFeature] = [
            ("headphones",                AppTheme.gold,                              "Alle \(count) Audio-Trainingseinheiten"),
            ("figure.golf",               Color(red: 0.3, green: 0.85, blue: 0.5),   "Drive, Technik, Mental & mehr"),
            ("sparkles",                  Color(red: 0.4, green: 0.7,  blue: 1.0),   "Passende Lektionen nach jeder Runde"),
            ("flag.fill",                 Color(red: 1.0, green: 0.6,  blue: 0.3),   "Putt-Lektionen direkt beim Minigolf"),
            ("play.circle.fill",          Color(red: 0.6, green: 0.5,  blue: 1.0),   "Offline anhören, jederzeit"),
            ("speedometer",               Color(red: 0.3, green: 0.85, blue: 0.5),   "Wiedergabegeschwindigkeit"),
        ]

        let caddy: [PaywallFeature] = [
            ("waveform.circle.fill",      Color(red: 0.4, green: 0.7,  blue: 1.0),   "KI-Assistent Caddy"),
            ("infinity",                  Color(red: 0.6, green: 0.5,  blue: 1.0),   "Unbegrenzte Caddy-Gespräche"),
            ("book.fill",                 Color(red: 0.3, green: 0.85, blue: 0.5),   "Golfregeln per Sprache klären – mit Regelnummer"),
            ("map.fill",                  Color(red: 1.0, green: 0.6,  blue: 0.3),   "Platzstrategie & Schlägerwahl vom Caddy"),
            ("chart.line.uptrend.xyaxis", AppTheme.gold,                              "Handicap, Stableford & WHS erklärt"),
        ]

        let general: [PaywallFeature] = [
            ("arrow.clockwise",           Color(red: 1.0, green: 0.6,  blue: 0.3),   "Neue Inhalte regelmäßig"),
            ("nosign",                    Color(red: 1.0, green: 0.4,  blue: 0.5),   "Keine Werbung in der App"),
        ]

        return (caddyFirst ? caddy + training : training + caddy) + general
    }
}
