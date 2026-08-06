import Foundation
import Combine
import CoreLocation
import SwiftData
import SwiftUI
import UIKit

/// Zeichnet während einer Runde die Laufspur des Spielers auf.
///
/// **Nur mit doppelter Zustimmung:** der Nutzer muss das Tracking in den
/// Einstellungen aktivieren (`isEnabledByUser`) *und* iOS die Standort-
/// Berechtigung erteilt haben. Ohne beides passiert nichts.
///
/// Läuft mit `WhenInUse`-Berechtigung plus Background-Mode `location` weiter,
/// wenn das Display gesperrt ist – iOS zeigt dabei die blaue Statusleiste an.
@MainActor
final class RoundTrackingService: NSObject, ObservableObject {

    static let shared = RoundTrackingService()

    // MARK: - Nutzer-Opt-in

    static let enabledKey = "tracking.roundPath.enabled"

    /// Vom Nutzer in den Einstellungen gesetzt – Standard: aus.
    static var isEnabledByUser: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    // MARK: - Zustand

    @Published private(set) var isTracking = false
    @Published private(set) var pointCount = 0
    @Published private(set) var currentHole = 0
    @Published private(set) var authorizationDenied = false
    @Published private(set) var lastAccuracy: Double?

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    // MARK: - Konfiguration

    /// Punkte mit schlechterer Genauigkeit werden verworfen – bei > 20 m ist die
    /// Position für Abschlag-/Grün-Erkennung wertlos.
    private let maxAcceptableAccuracy: Double = 20
    /// Mindestabstand zum letzten gespeicherten Punkt.
    private let minDistanceMeters: Double = 4
    /// … oder Mindestzeit, damit auch Stillstand (Putten!) Punkte erzeugt.
    private let minIntervalSeconds: TimeInterval = 10
    /// Nach so vielen Punkten wird in SwiftData geschrieben.
    private let flushThreshold = 20

    // MARK: - Intern

    private let manager = CLLocationManager()
    private var buffer: [TrackPoint] = []
    private var track: RoundTrack?
    private var context: ModelContext?
    private var startedAt: Date = .now
    private var lastKeptLocation: CLLocation?
    private var lastKeptTime: Date?
    private var observers: [NSObjectProtocol] = []

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = minDistanceMeters
        manager.activityType = .fitness
        // Muss aus bleiben: iOS würde sonst beim Putten/Warten pausieren und
        // genau die Stillstands-Cluster verschlucken, aus denen wir Abschlag
        // und Grün ableiten.
        manager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Steuerung

    /// Startet die Aufzeichnung für `round`. Tut nichts, wenn der Nutzer das
    /// Tracking nicht aktiviert hat oder die Runde schon einen Track besitzt.
    func start(round: Round, context: ModelContext, currentHole: Int = 0) {
        guard Self.isEnabledByUser else { return }
        guard !isTracking else { return }

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Weiter geht es in locationManagerDidChangeAuthorization.
            pendingStart = (round, context, currentHole)
            return
        case .denied, .restricted:
            authorizationDenied = true
            return
        default:
            break
        }

        self.context = context
        self.currentHole = currentHole
        authorizationDenied = false

        // Bestehenden Track fortsetzen (Runde wurde unterbrochen und wieder geöffnet).
        if let existing = round.track {
            track = existing
            startedAt = existing.startedAt
            existing.endedAt = nil
            pointCount = existing.pointCount
        } else {
            let newTrack = RoundTrack(startedAt: .now)
            context.insert(newTrack)
            newTrack.round = round
            round.track = newTrack
            track = newTrack
            startedAt = newTrack.startedAt
            pointCount = 0
        }

        buffer.removeAll()
        lastKeptLocation = nil
        lastKeptTime = nil

        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
        isTracking = true
        registerLifecycleObservers()
    }

    private var pendingStart: (round: Round, context: ModelContext, hole: Int)?

    /// Wird bei jedem Lochwechsel aufgerufen – damit sind die Punkte direkt beim
    /// Loch beschriftet und müssen später nicht rekonstruiert werden.
    func setCurrentHole(_ hole: Int) {
        guard hole != currentHole else { return }
        flush()
        currentHole = hole
    }

    /// Beendet die Aufzeichnung und schreibt den Puffer weg.
    func stop() {
        guard isTracking else { return }
        flush()
        track?.endedAt = .now
        try? context?.save()
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        isTracking = false
        track = nil
        context = nil
        pendingStart = nil
        removeLifecycleObservers()
    }

    // MARK: - Persistenz

    private func flush() {
        guard !buffer.isEmpty, let track else { return }
        track.append(buffer)
        pointCount = track.pointCount
        buffer.removeAll()
        try? context?.save()
    }

    private func registerLifecycleObservers() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        // Im Hintergrund läuft das Tracking weiter, aber der Puffer soll
        // trotzdem auf der Platte landen – sonst gehen bei einem Kill Punkte verloren.
        for name in [UIApplication.didEnterBackgroundNotification,
                     UIApplication.willTerminateNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.flush() }
            })
        }
    }

    private func removeLifecycleObservers() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
    }

    // MARK: - Filter

    /// Entscheidet, ob ein Punkt gespeichert wird.
    private func shouldKeep(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy > 0,
              location.horizontalAccuracy <= maxAcceptableAccuracy else { return false }
        // Sichtlich veraltete Fixes (z. B. der letzte Cache-Wert beim Start) ignorieren.
        guard abs(location.timestamp.timeIntervalSinceNow) < 30 else { return false }

        guard let lastLocation = lastKeptLocation, let lastTime = lastKeptTime else { return true }
        let movedFarEnough = location.distance(from: lastLocation) >= minDistanceMeters
        let waitedLongEnough = location.timestamp.timeIntervalSince(lastTime) >= minIntervalSeconds
        return movedFarEnough || waitedLongEnough
    }
}

// MARK: - CLLocationManagerDelegate

extension RoundTrackingService: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for location in locations where self.shouldKeep(location) {
                self.buffer.append(TrackPoint(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    timeOffset: location.timestamp.timeIntervalSince(self.startedAt),
                    accuracy: location.horizontalAccuracy,
                    holeNumber: self.currentHole
                ))
                self.lastKeptLocation = location
                self.lastKeptTime = location.timestamp
                self.lastAccuracy = location.horizontalAccuracy
            }
            if self.buffer.count >= self.flushThreshold { self.flush() }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.authorizationDenied = false
                if let pending = self.pendingStart {
                    self.pendingStart = nil
                    self.start(round: pending.round, context: pending.context, currentHole: pending.hole)
                }
            case .denied, .restricted:
                self.authorizationDenied = true
                self.pendingStart = nil
                if self.isTracking { self.stop() }
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        // Einzelne Fehler (kein Fix) sind auf dem Platz normal – Tracking läuft weiter.
    }
}
