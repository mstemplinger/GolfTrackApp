import Combine
import CoreLocation
import Foundation
import UserNotifications

/// Erkennt, dass jemand an einem Platz aus dem Verzeichnis steht.
///
/// Zwei getrennte Stufen, weil sie unterschiedlich viel kosten:
///
/// 1. **Vorschlag in der App** – braucht nur die Berechtigung, die GolfTrack
///    ohnehin hat („Beim Verwenden"). Beim Öffnen der Startseite wird einmal
///    der Standort geholt und der nächstgelegene Platz gesucht.
/// 2. **Mitteilung, während die App zu ist** – dafür führt kein Weg an
///    Geofences und damit an „Immer" vorbei. Das ist ausdrücklich ein Opt-in:
///    standardmäßig aus, die Berechtigung wird erst beim Einschalten erfragt.
///
/// Gemeldet wird der **erste Abschlag**, nicht die Adresse der Anlage – sonst
/// schlägt die App die Runde schon am Parkplatz der Nachbarstraße vor.
@MainActor
final class NearbyCourseService: NSObject, ObservableObject {

    static let shared = NearbyCourseService()

    /// Mitteilung bei Annäherung – vom Nutzer in den Einstellungen gesetzt.
    static let enabledKey = "nearby.notifications.enabled"

    static var isEnabledByUser: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    // MARK: - Ein Platz in Reichweite

    struct NearbyCourse: Identifiable, Equatable {
        let kind: CourseLinkKind
        let slug: String
        let name: String
        let location: String
        let distance: CLLocationDistance

        var id: String { "\(kind.rawValue)/\(slug)" }
        var startURL: URL { CourseDeepLink.appURL(kind: kind, slug: slug) }
    }

    @Published private(set) var suggestion: NearbyCourse?
    @Published private(set) var authorizationDenied = false

    // MARK: - Maße

    /// Radius der überwachten Zone um den ersten Abschlag. Enger wäre bei der
    /// Ortungsgenauigkeit eines iPhones unzuverlässig, weiter träfe schon die
    /// Durchgangsstraße.
    private let regionRadius: CLLocationDistance = 250
    /// Für den Vorschlag in der App darf es etwas großzügiger sein – wer die
    /// App am Parkplatz öffnet, meint denselben Platz.
    private let suggestionRadius: CLLocationDistance = 500
    /// iOS überwacht höchstens 20 Zonen je App. Bei knapp hundert Plätzen wird
    /// deshalb immer nur die nächste Umgebung überwacht und beim Ortswechsel
    /// neu bestimmt.
    private let maxRegions = 20
    /// Derselbe Platz meldet sich frühestens nach dieser Zeit erneut.
    private let notifyCooldown: TimeInterval = 6 * 3600

    // MARK: - Intern

    private let manager = CLLocationManager()
    /// Läuft gerade eine einzelne Standortabfrage für den Vorschlag?
    private var awaitingSuggestionFix = false

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Vorschlag in der App

    /// Sucht einmalig den Platz, an dem der Nutzer gerade steht.
    ///
    /// Ohne Berechtigung passiert nichts – die Startseite zeigt dann einfach
    /// keine Karte. Es wird bewusst **nicht** von sich aus nach der
    /// Berechtigung gefragt; das tut die App an den Stellen, wo der Nutzer sie
    /// erwartet.
    func refreshSuggestion() async {
        guard CLLocationManager.locationServicesEnabled() else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // Ohne geladenes Verzeichnis gäbe es nichts zu vergleichen – beim
            // ersten Start der App ist es noch leer.
            await CourseCatalogService.shared.refreshIfNeeded()
            awaitingSuggestionFix = true
            manager.requestLocation()
        default:
            suggestion = nil
        }
    }

    func dismissSuggestion() {
        suggestion = nil
    }

    // MARK: - Mitteilung bei Annäherung

    /// Schaltet die Mitteilung ein oder aus. Beim Einschalten wird „Immer"
    /// erfragt; lehnt der Nutzer ab, bleibt der Schalter zwar an, aber es
    /// werden keine Zonen überwacht – `authorizationDenied` sagt das der
    /// Oberfläche.
    func setNotificationsEnabled(_ enabled: Bool) {
        Self.isEnabledByUser = enabled
        guard enabled else {
            stopMonitoring()
            return
        }
        manager.requestAlwaysAuthorization()
        startMonitoringIfPossible()
    }

    /// Beim Start der App: Überwachung wieder aufnehmen, falls eingeschaltet.
    func resumeMonitoringIfEnabled() {
        guard Self.isEnabledByUser else { return }
        startMonitoringIfPossible()
    }

    private func startMonitoringIfPossible() {
        guard Self.isEnabledByUser,
              manager.authorizationStatus == .authorizedAlways,
              CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        authorizationDenied = manager.authorizationStatus == .denied
        // Grobe Ortswechsel wecken die App, damit die überwachten Zonen zur
        // Umgebung passen – sonst nützen 20 Zonen bei hundert Plätzen nichts.
        manager.startMonitoringSignificantLocationChanges()
        manager.requestLocation()
    }

    private func stopMonitoring() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        manager.stopMonitoringSignificantLocationChanges()
    }

    /// Überwacht die dem Standort nächsten Plätze – höchstens `maxRegions`.
    private func updateRegions(around location: CLLocation) {
        let plaetze = candidates()
            .sorted { $0.coordinate.distance(to: location) < $1.coordinate.distance(to: location) }
            .prefix(maxRegions)

        let gewuenscht = Set(plaetze.map(\.regionID))
        for region in manager.monitoredRegions where !gewuenscht.contains(region.identifier) {
            manager.stopMonitoring(for: region)
        }

        let bereits = Set(manager.monitoredRegions.map(\.identifier))
        for platz in plaetze where !bereits.contains(platz.regionID) {
            let region = CLCircularRegion(center: platz.coordinate,
                                          radius: regionRadius,
                                          identifier: platz.regionID)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
            // Wer beim Einschalten schon auf dem Platz steht, betritt die Zone
            // nie – deshalb einmal aktiv nachfragen.
            manager.requestState(for: region)
        }
    }

    // MARK: - Plätze aus dem Verzeichnis

    /// Ein Platz, wie ihn dieser Dienst braucht: Kennung, Name, ein Punkt.
    private struct Candidate {
        let kind: CourseLinkKind
        let slug: String
        let name: String
        let location: String
        let coordinate: CLLocationCoordinate2D

        var regionID: String { "nearby|\(kind.rawValue)|\(slug)" }
        var startURLString: String { CourseDeepLink.appURL(kind: kind, slug: slug).absoluteString }
    }

    private func candidates() -> [Candidate] {
        let katalog = CourseCatalogService.shared
        // **Nicht** `allGolfCourses`: dort gewinnen bei Namensgleichheit die
        // eingebauten Plätze, und die tragen keine Kennung – ohne Kennung gibt
        // es weder Zone noch Link. Das Verzeichnis enthält ohnehin alle.
        let golf = katalog.remoteGolfCourses.compactMap { entry -> Candidate? in
            guard !entry.slug.isEmpty, let punkt = entry.startCoordinate else { return nil }
            return Candidate(kind: .golf, slug: entry.slug, name: entry.name,
                             location: entry.location, coordinate: punkt)
        }
        let minigolf = katalog.allMinigolfCourses.compactMap { entry -> Candidate? in
            guard let punkt = entry.startCoordinate else { return nil }
            return Candidate(kind: .minigolf, slug: entry.id, name: entry.name,
                             location: entry.location, coordinate: punkt)
        }
        return golf + minigolf
    }

    private func candidate(forRegion identifier: String) -> Candidate? {
        candidates().first { $0.regionID == identifier }
    }

    // MARK: - Mitteilung

    private func notify(about candidate: Candidate) {
        let merker = "nearby.lastNotified.\(candidate.regionID)"
        let zuletzt = UserDefaults.standard.double(forKey: merker)
        let jetzt = Date().timeIntervalSince1970
        guard jetzt - zuletzt > notifyCooldown else { return }
        UserDefaults.standard.set(jetzt, forKey: merker)

        let inhalt = UNMutableNotificationContent()
        inhalt.title = candidate.name
        // `String(localized:)`, weil eine Mitteilung kein SwiftUI-`Text` ist –
        // hier übersetzt nichts von allein.
        inhalt.body = candidate.kind == .golf
            ? String(localized: "Du stehst am Platz. Runde starten und mitzählen?")
            : String(localized: "Du stehst an der Anlage. Runde starten und mitzählen?")
        inhalt.sound = UNNotificationSound(named: UNNotificationSoundName("notification.caf"))
        inhalt.userInfo = [NotificationPayload.deepLinkKey: candidate.startURLString]

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: candidate.regionID, content: inhalt, trigger: nil)
        )
    }
}

// MARK: - CLLocationManagerDelegate

extension NearbyCourseService: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            if awaitingSuggestionFix {
                awaitingSuggestionFix = false
                updateSuggestion(from: location)
            }
            if Self.isEnabledByUser, manager.authorizationStatus == .authorizedAlways {
                updateRegions(around: location)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in awaitingSuggestionFix = false }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            guard let treffer = candidate(forRegion: region.identifier) else { return }
            notify(about: treffer)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didDetermineState state: CLRegionState,
                                     for region: CLRegion) {
        guard state == .inside else { return }
        Task { @MainActor in
            guard let treffer = candidate(forRegion: region.identifier) else { return }
            notify(about: treffer)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationDenied = manager.authorizationStatus == .denied
            if Self.isEnabledByUser { startMonitoringIfPossible() }
        }
    }

    @MainActor
    private func updateSuggestion(from location: CLLocation) {
        let naechster = candidates()
            .map { ($0, $0.coordinate.distance(to: location)) }
            .filter { $0.1 <= suggestionRadius }
            .min { $0.1 < $1.1 }

        suggestion = naechster.map {
            NearbyCourse(kind: $0.0.kind, slug: $0.0.slug, name: $0.0.name,
                         location: $0.0.location, distance: $0.1)
        }
    }
}

// MARK: - Kleinkram

extension CLLocationCoordinate2D {
    func distance(to location: CLLocation) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude).distance(from: location)
    }
}

enum NotificationPayload {
    /// Unter diesem Schlüssel steckt der Link in einer Mitteilung.
    static let deepLinkKey = "golftrack.deepLink"
}
