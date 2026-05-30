import Foundation

/// App-weite Einheit für Distanzanzeigen.
/// Gespeichert via `@AppStorage("distanceUnit")`.
enum DistanceUnit: String {
    case meters = "metric"
    case yards  = "imperial"

    static let storageKey = "distanceUnit"

    var displayName: String {
        switch self {
        case .meters: return "Meter"
        case .yards:  return "Yards"
        }
    }

    var unitLabel: String { self == .meters ? "m" : "y" }

    /// Gibt einen formatierten String für eine Distanz in Metern zurück.
    func format(_ meters: Double) -> String {
        switch self {
        case .meters: return "\(Int(meters)) m"
        case .yards:  return "\(Int(meters * 1.09361)) y"
        }
    }

    /// Gibt den Rohwert (gerundet) ohne Einheitenzeichen zurück.
    func value(_ meters: Double) -> Int {
        switch self {
        case .meters: return Int(meters)
        case .yards:  return Int(meters * 1.09361)
        }
    }
}
