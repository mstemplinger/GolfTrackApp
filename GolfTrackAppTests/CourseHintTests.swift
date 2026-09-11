import Foundation
import Testing
@testable import GolfTrackApp

/// Die Hinweise der Anlage – im App Clip stehen sie dort, wo die volle App
/// Werbung zeigt.
struct CourseHintTests {

    private let hints: [CourseHint] = [
        .init(kind: .toilet, text: "Toiletten beim Clubhaus"),
        .init(kind: .shelter, text: "Unterstellhaus an Bahn 5"),
        .init(kind: .drinks, text: "Getränke beim Start")
    ]

    @Test("Jede Bahn zeigt den nächsten Hinweis")
    func rotatesPerHole() {
        #expect(hints.hint(forRotation: 0)?.kind == .toilet)
        #expect(hints.hint(forRotation: 1)?.kind == .shelter)
        #expect(hints.hint(forRotation: 2)?.kind == .drinks)
        // Nach dem letzten geht es von vorne los – sonst sähe niemand die
        // hinteren Hinweise auf einer 18-Bahnen-Runde.
        #expect(hints.hint(forRotation: 3)?.kind == .toilet)
        #expect(hints.hint(forRotation: 17)?.kind == .drinks)
    }

    @Test("Ohne Hinweise gibt es nichts zu zeigen")
    func emptyStaysEmpty() {
        #expect([CourseHint]().hint(forRotation: 4) == nil)
    }

    @Test("Ein negativer Zähler stürzt nicht ab")
    func negativeRotation() {
        #expect(hints.hint(forRotation: -1)?.kind == .drinks)
    }

    @Test("Eine unbekannte Art fällt auf „Sonstiges“ zurück")
    func unknownKindDecodes() throws {
        // Die Website kann jederzeit eine neue Art bekommen, während im App
        // Store noch die alte Fassung liegt.
        let json = #"[{"kind":"sauna","text":"Sauna am Parkplatz"}]"#
        let decoded = try JSONDecoder().decode([CourseHint].self, from: Data(json.utf8))
        #expect(decoded.first?.kind == .info)
        #expect(decoded.first?.text == "Sauna am Parkplatz")
    }
}
