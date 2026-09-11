import SwiftUI

/// Hinweise, die der Betreiber zu seiner Anlage hinterlegt hat – Toiletten,
/// Unterstellhaus bei Gewitter, Ausleihe.
///
/// Sie kommen aus dem Platzverzeichnis (`facilityHints` im Feed) und stehen im
/// App Clip an genau der Stelle, an der die volle App Werbung zeigt: Werbung
/// ist im Clip untersagt (Richtlinie 2.5.16(a)), eine Information zur Anlage
/// ist es nicht. Für den Gast ist sie außerdem nützlicher.

// MARK: - Modell

/// Art des Hinweises. Die Bezeichner stehen genauso in `hintKind` (zod) auf der
/// Website – wer hier etwas ergänzt, muss es dort ebenfalls tun.
enum CourseHintKind: String, Codable, CaseIterable, Hashable {
    case toilet
    case shelter
    case drinks
    case food
    case rental
    case parking
    case water
    case firstAid
    case info

    var symbol: String {
        switch self {
        case .toilet:   "toilet.fill"
        case .shelter:  "umbrella.fill"
        case .drinks:   "takeoutbag.and.cup.and.straw.fill"
        case .food:     "fork.knife"
        case .rental:   "figure.golf"
        case .parking:  "parkingsign"
        case .water:    "drop.fill"
        case .firstAid: "cross.case.fill"
        case .info:     "info.circle.fill"
        }
    }
}

struct CourseHint: Identifiable, Hashable, Codable {
    let kind: CourseHintKind
    let text: String

    var id: String { "\(kind.rawValue)|\(text)" }

    init(kind: CourseHintKind, text: String) {
        self.kind = kind
        self.text = text
    }

    /// Eine unbekannte Art fällt auf `info` zurück, statt den ganzen Platz
    /// scheitern zu lassen: die Website kann jederzeit eine neue Art bekommen,
    /// während im App Store noch die alte Fassung liegt.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode(String.self, forKey: .kind)
        kind = CourseHintKind(rawValue: raw) ?? .info
        text = try container.decode(String.self, forKey: .text)
    }
}

extension Array where Element == CourseHint {
    /// Der Hinweis, der bei Loch `rotation` an der Reihe ist.
    ///
    /// Rechnet negative Werte mit, damit ein unerwarteter Zähler nicht
    /// abstürzt – bei einer Zählkarte ist eine falsche Zeile hinnehmbar, ein
    /// Absturz mitten in der Runde nicht.
    func hint(forRotation rotation: Int) -> CourseHint? {
        guard !isEmpty else { return nil }
        return self[((rotation % count) + count) % count]
    }
}

// MARK: - Alle Hinweise am Stück (Startbildschirm)

/// Karte mit allen Hinweisen – auf dem Willkommensbildschirm, wo Zeit ist,
/// alles zu lesen.
struct CourseHintsCard: View {
    let hints: [CourseHint]

    var body: some View {
        if !hints.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Gut zu wissen")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.gold)

                ForEach(hints) { hint in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: hint.kind.symbol)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.gold)
                            .frame(width: 22)
                        Text(hint.text)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Ein Hinweis je Loch (während der Runde)

/// Ein einzelner Hinweis, der mit dem Loch wechselt.
///
/// Bewusst dieselbe Umlauflogik wie bei der Werbung in der vollen App: sonst
/// steht auf Bahn 1 immer derselbe Hinweis und die übrigen sieht nie jemand.
struct CourseHintRotatingCard: View {
    let hints: [CourseHint]
    /// Laufende Nummer des Lochs – der Hinweis wechselt mit ihr.
    let rotation: Int

    private var hint: CourseHint? { hints.hint(forRotation: rotation) }

    var body: some View {
        if let hint {
            HStack(spacing: 12) {
                Image(systemName: hint.kind.symbol)
                    .font(.title3)
                    .foregroundStyle(AppTheme.gold)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Gut zu wissen")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.gold.opacity(0.8))
                    Text(hint.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .animation(.easeInOut(duration: 0.2), value: hint)
        }
    }
}
