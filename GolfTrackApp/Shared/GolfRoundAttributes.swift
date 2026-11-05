import ActivityKit
import AppIntents
import Foundation

/// ActivityAttributes shared between GolfTrackApp and GolfWidget.
/// This file must be added to BOTH targets.
struct GolfRoundAttributes: ActivityAttributes {

    // Static — set once when the activity starts
    var courseName: String

    // Dynamic — updated on every stroke / hole change
    struct ContentState: Codable, Hashable {
        var holeNumber: Int
        var totalHoles: Int
        var strokes: Int
        var par: Int
        /// Gesetzt, solange die Runde nur eingestellt und noch nicht gestartet
        /// ist – die Live Activity zeigt dann „Runde starten“ statt Zählknöpfen.
        /// Optional, damit bestehende Live Activities weiter dekodieren.
        var setup: RoundSetup? = nil
    }
}

/// Was in „Neue Runde“ eingestellt ist. Die Texte kommen fertig übersetzt aus
/// der App – das Widget kennt Spielformen und Abschlagfarben nicht.
struct RoundSetup: Codable, Hashable {
    var courseName: String
    /// z. B. „18 Löcher“, „Zählspiel“, „Abschlag Gelb“, „2 Mitspieler“
    var details: [String]
}

/// Großer Plus-Knopf der Live Activity. Als `LiveActivityIntent` führt iOS
/// `perform()` im Prozess der App aus – auch wenn sie nur im Hintergrund
/// geweckt wird. Das Widget kennt die Datenbank nicht; die App hängt beim
/// Start ihren Handler ein.
struct AddStrokeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Schlag hinzufügen"
    static var description = IntentDescription("Zählt auf dem aktuellen Loch einen Schlag dazu.")
    static var openAppWhenRun = false

    @MainActor static var handler: (@MainActor () async -> Void)?

    init() {}

    func perform() async throws -> some IntentResult {
        await AddStrokeIntent.handler?()
        return .result()
    }
}

/// Knopf „Runde starten“ der Live Activity, solange die Runde nur eingestellt
/// ist. Öffnet die App, damit man gleich auf der Scorekarte landet; die
/// Einstellungsseite hört auf den Handler.
struct StartRoundIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Runde starten"
    static var description = IntentDescription("Startet die eingestellte Runde.")
    static var openAppWhenRun = true

    @MainActor static var handler: (@MainActor () async -> Void)?

    init() {}

    func perform() async throws -> some IntentResult {
        await StartRoundIntent.handler?()
        return .result()
    }
}

/// Knopf „Nächstes Loch“ der Live Activity – läuft wie `AddStrokeIntent`
/// im Prozess der App, die beim Start ihren Handler einhängt.
struct NextHoleIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Nächstes Loch"
    static var description = IntentDescription("Springt in der laufenden Runde zum nächsten Loch.")
    static var openAppWhenRun = false

    @MainActor static var handler: (@MainActor () async -> Void)?

    init() {}

    func perform() async throws -> some IntentResult {
        await NextHoleIntent.handler?()
        return .result()
    }
}
