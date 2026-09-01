import Foundation

/// Läuft dieser Prozess als App Clip oder als vollständige App?
///
/// Nötig, weil Apple Werbung im App Clip untersagt – Richtlinie 2.5.16(a)
/// („App Clips cannot contain advertising") und 2.5.18, wonach Anzeigen ins
/// Hauptprogramm gehören und nicht in Erweiterungen, App Clips, Widgets,
/// Mitteilungen oder watchOS-Apps. Eine Einreichung mit Werbung im Clip wird
/// abgelehnt.
///
/// Der Werbeslot ist deshalb ohnehin nicht Teil des Clip-Ziels. Diese Prüfung
/// ist die zweite Sicherung für den Fall, dass jemand die Datei später doch
/// dazunimmt: dann erscheint schlicht nichts, statt dass es erst bei der
/// Einreichung auffällt.
///
/// Erkannt wird es am `NSAppClip`-Eintrag in der Info.plist, den jedes
/// App-Clip-Ziel zwingend mitbringt. Das kommt ohne eigenes Build-Flag aus –
/// eines, das jemand beim Anlegen eines Ziels vergisst zu setzen, würde die
/// Sicherung stillschweigend aushebeln.
enum AppClipEnvironment {

    static let isRunningAsAppClip: Bool = Bundle.main.infoDictionary?["NSAppClip"] != nil
}
