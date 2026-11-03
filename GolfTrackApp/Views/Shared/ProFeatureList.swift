import SwiftUI

/// Eine Zeile in der Leistungsliste einer Paywall.
typealias PaywallFeature = (icon: String, color: Color, text: LocalizedStringKey)

/// Leistungen von GolfTrack Pro. Jede Zeile steht für etwas, das die App
/// wirklich kann: Pro schaltet das Training frei (Audios, Empfehlungen,
/// Putt-Lektionen), dazu keine Werbung.
enum ProFeatureList {

    static func features() -> [PaywallFeature] {
        let count = allLessons.filter(\.isAvailable).count
        return [
            ("headphones",       AppTheme.gold,                              "Alle \(count) Audio-Trainingseinheiten"),
            ("figure.golf",      Color(red: 0.3, green: 0.85, blue: 0.5),   "Drive, Technik, Mental & mehr"),
            ("sparkles",         Color(red: 0.4, green: 0.7,  blue: 1.0),   "Passende Lektionen nach jeder Runde"),
            ("flag.fill",        Color(red: 1.0, green: 0.6,  blue: 0.3),   "Putt-Lektionen direkt beim Minigolf"),
            ("play.circle.fill", Color(red: 0.6, green: 0.5,  blue: 1.0),   "Offline anhören, jederzeit"),
            ("speedometer",      Color(red: 0.3, green: 0.85, blue: 0.5),   "Wiedergabegeschwindigkeit"),
            ("arrow.clockwise",  Color(red: 1.0, green: 0.6,  blue: 0.3),   "Neue Inhalte regelmäßig"),
            ("nosign",           Color(red: 1.0, green: 0.4,  blue: 0.5),   "Keine Werbung in der App"),
        ]
    }
}
