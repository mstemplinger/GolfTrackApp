import Foundation

/// Sprache der App, unabhängig von der Systemsprache wählbar.
/// Gespeichert via `@AppStorage("appLanguage")`.
///
/// iOS liest die Sprache beim Start aus `AppleLanguages`. Ein Eintrag in den
/// Einstellungen der App überschreibt die Systemsprache nur für GolfTrack und
/// greift ab dem nächsten Start. `.system` entfernt den Eintrag wieder.
///
/// Der Sprung in die iOS-Einstellungen (`openSettingsURLString`) landete im
/// Test auf der Startseite der Einstellungen statt bei GolfTrack – deshalb die
/// eigene Auswahl.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case de, en, es, fr, it, pl, cs

    static let storageKey = "appLanguage"

    var id: String { rawValue }

    /// Name in der Sprache selbst („Polski“, „Čeština“) – bewusst unübersetzt,
    /// damit man seine Sprache auch in einer fremden Oberfläche wiederfindet.
    /// `nil` für die Systemsprache, die einen übersetzten Titel bekommt.
    var nativeName: String? {
        guard self != .system else { return nil }
        let locale = Locale(identifier: rawValue)
        return locale.localizedString(forLanguageCode: rawValue)?.capitalized(with: locale)
    }

    /// Schreibt die Wahl dorthin, wo iOS beim nächsten Start nachsieht.
    func apply(to defaults: UserDefaults = .standard) {
        if self == .system {
            defaults.removeObject(forKey: "AppleLanguages")
        } else {
            defaults.set([rawValue], forKey: "AppleLanguages")
        }
    }
}
