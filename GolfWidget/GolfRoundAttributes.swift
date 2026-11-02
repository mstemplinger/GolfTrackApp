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
    }
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
