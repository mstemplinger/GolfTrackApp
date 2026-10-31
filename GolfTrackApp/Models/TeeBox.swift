import SwiftUI
import CoreLocation

/// Abschlagfarbe. Die Rohwerte stehen genauso in der Website
/// (`web/src/lib/schema.ts`) – wer hier etwas ergänzt, muss es dort ebenfalls tun.
enum TeeColor: String, Codable, CaseIterable, Identifiable, Hashable {
    case black, white, gold, blue, yellow, red, orange, green

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .black:  return String(localized: "Schwarz")
        case .white:  return String(localized: "Weiß")
        case .gold:   return String(localized: "Gold")
        case .blue:   return String(localized: "Blau")
        case .yellow: return String(localized: "Gelb")
        case .red:    return String(localized: "Rot")
        case .orange: return String(localized: "Orange")
        case .green:  return String(localized: "Grün")
        }
    }

    var color: Color {
        switch self {
        case .black:  return Color(red: 0.11, green: 0.11, blue: 0.11)
        case .white:  return Color(red: 0.96, green: 0.96, blue: 0.96)
        case .gold:   return Color(red: 0.83, green: 0.69, blue: 0.22)
        case .blue:   return Color(red: 0.18, green: 0.44, blue: 0.87)
        case .yellow: return Color(red: 0.95, green: 0.76, blue: 0.19)
        case .red:    return Color(red: 0.85, green: 0.23, blue: 0.23)
        case .orange: return Color(red: 0.94, green: 0.54, blue: 0.14)
        case .green:  return Color(red: 0.18, green: 0.62, blue: 0.31)
        }
    }

    /// Dunkle Farben brauchen auf dunklem Grund einen hellen Rand.
    var needsOutline: Bool { self == .black }

    /// Was ein Platz ohne hinterlegte Abschläge zur Auswahl anbietet –
    /// die in Deutschland übliche Grundausstattung.
    static let commonSet: [TeeColor] = [.white, .yellow, .blue, .red]
}

/// Ein Abschlag eines Platzes mit eigener Wertung, Lochlängen und Positionen.
/// Fehlende Werte: Länge 0, Koordinate `NaN` – wie bei den Standardfeldern von `Course`.
struct CourseTee: Codable, Hashable, Identifiable {
    var color: TeeColor
    var courseRating: Double?
    var slopeRating: Int?
    var holeLengths: [Int] = []
    var teeLatitudes: [Double] = []
    var teeLongitudes: [Double] = []

    var id: TeeColor { color }

    func length(forHole hole: Int) -> Int? {
        let i = hole - 1
        guard i >= 0, i < holeLengths.count, holeLengths[i] > 0 else { return nil }
        return holeLengths[i]
    }

    func coordinate(forHole hole: Int) -> CLLocationCoordinate2D? {
        let i = hole - 1
        guard i >= 0, i < teeLatitudes.count, i < teeLongitudes.count else { return nil }
        let lat = teeLatitudes[i], lon = teeLongitudes[i]
        guard lat.isFinite, lon.isFinite, !(lat == 0 && lon == 0) else { return nil }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return CLLocationCoordinate2DIsValid(coord) ? coord : nil
    }

    mutating func setCoordinate(_ coordinate: CLLocationCoordinate2D, forHole hole: Int, holeCount: Int) {
        let i = hole - 1
        guard i >= 0, i < holeCount else { return }
        while teeLatitudes.count < holeCount { teeLatitudes.append(.nan) }
        while teeLongitudes.count < holeCount { teeLongitudes.append(.nan) }
        teeLatitudes[i] = coordinate.latitude
        teeLongitudes[i] = coordinate.longitude
    }

    // NaN ist kein gültiges JSON – unbekannte Positionen werden als `null` gespeichert.
    private enum CodingKeys: String, CodingKey {
        case color, courseRating, slopeRating, holeLengths, teeLatitudes, teeLongitudes
    }

    init(color: TeeColor, courseRating: Double? = nil, slopeRating: Int? = nil,
         holeLengths: [Int] = [], teeLatitudes: [Double] = [], teeLongitudes: [Double] = []) {
        self.color = color
        self.courseRating = courseRating
        self.slopeRating = slopeRating
        self.holeLengths = holeLengths
        self.teeLatitudes = teeLatitudes
        self.teeLongitudes = teeLongitudes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        color = try c.decode(TeeColor.self, forKey: .color)
        courseRating = try c.decodeIfPresent(Double.self, forKey: .courseRating)
        slopeRating = try c.decodeIfPresent(Int.self, forKey: .slopeRating)
        holeLengths = (try c.decodeIfPresent([Int?].self, forKey: .holeLengths) ?? []).map { $0 ?? 0 }
        teeLatitudes = (try c.decodeIfPresent([Double?].self, forKey: .teeLatitudes) ?? []).map { $0 ?? .nan }
        teeLongitudes = (try c.decodeIfPresent([Double?].self, forKey: .teeLongitudes) ?? []).map { $0 ?? .nan }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(color, forKey: .color)
        try c.encodeIfPresent(courseRating, forKey: .courseRating)
        try c.encodeIfPresent(slopeRating, forKey: .slopeRating)
        try c.encode(holeLengths.map { $0 > 0 ? $0 : nil }, forKey: .holeLengths)
        try c.encode(teeLatitudes.map { $0.isFinite ? $0 : nil }, forKey: .teeLatitudes)
        try c.encode(teeLongitudes.map { $0.isFinite ? $0 : nil }, forKey: .teeLongitudes)
    }
}

/// Farbpunkt für Abschläge – überall gleich, damit Gelb überall gleich aussieht.
struct TeeDot: View {
    let tee: TeeColor
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(tee.color)
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(.white.opacity(tee.needsOutline ? 0.5 : 0.15), lineWidth: 1))
    }
}
