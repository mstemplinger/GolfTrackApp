import CoreMotion
import CoreLocation
import WatchKit
import SwiftUI

// MARK: - Automatische Schlag-Erkennung via CoreMotion

@MainActor
final class SwingDetector {

    // MARK: - State (nur intern, UI beobachtet WatchRoundModel)

    private(set) var isActive: Bool = false

    // Callback: GPS-Koordinate beim erkannten Schwung (nil wenn kein GPS)
    var onSwingDetected: ((CLLocationCoordinate2D?) -> Void)?

    // MARK: - Private

    private let motionManager = CMMotionManager()
    private var isDebouncing  = false
    private weak var locationService: WatchLocationService?

    // Schwellenwert-Konfiguration
    // Golf-Schwung-Impact erzeugt typisch 3–6g Beschleunigung + starke Rotation
    private let accelThreshold: Double = 2.8   // g-Kräfte (userAcceleration = ohne Gravitation)
    private let rotThreshold:   Double = 4.0   // rad/s (Rotation)
    private let debounceSecs:   Double = 3.0   // Mindestzeit zwischen zwei erkannten Schwüngen

    // MARK: - Init

    init(locationService: WatchLocationService? = nil) {
        self.locationService = locationService
    }

    // MARK: - Public API

    func setLocationService(_ svc: WatchLocationService) {
        self.locationService = svc
    }

    func start() {
        guard motionManager.isDeviceMotionAvailable, !isActive else { return }
        isActive = true

        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0   // 50 Hz – präzise genug, akkuschonend
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            Task { @MainActor in self.process(motion) }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        isActive = false
        isDebouncing = false
    }

    // MARK: - Motion Processing

    private func process(_ motion: CMDeviceMotion) {
        guard !isDebouncing else { return }

        let a = motion.userAcceleration
        let r = motion.rotationRate

        let accelMag = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
        let rotMag   = (r.x * r.x + r.y * r.y + r.z * r.z).squareRoot()

        // Beide Kriterien müssen erfüllt sein → reduziert Fehlerkennungen (Gehen, Stolpern)
        guard accelMag > accelThreshold, rotMag > rotThreshold else { return }

        triggerSwing()
    }

    private func triggerSwing() {
        isDebouncing = true

        // Haptisches Feedback
        WKInterfaceDevice.current().play(.notification)

        // GPS-Position zum Zeitpunkt des Schlags
        let coord = locationService?.currentCoordinate
        onSwingDetected?(coord)

        // Debounce zurücksetzen
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(debounceSecs))
            self.isDebouncing = false
        }
    }
}
