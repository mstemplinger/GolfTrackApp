import SwiftUI
import WatchKit
import CoreLocation
import Combine

// MARK: - Round Model

@MainActor
final class WatchRoundModel: ObservableObject {

    @Published var holes: Int = 18
    @Published var strokes: [Int]
    @Published var currentHoleIndex: Int = 0
    @Published var isFinished: Bool = false
    var courseName: String = ""

    // Zeigt an ob diese Runde vom iPhone gestartet wurde
    var syncedWithPhone: Bool = false

    // MARK: - Auto-Schlag-Erkennung

    let swingDetector = SwingDetector()

    /// true = automatische Erkennung aktiv
    @Published var autoDetectEnabled: Bool = true {
        didSet { autoDetectEnabled ? swingDetector.start() : swingDetector.stop() }
    }

    /// Letzter erkannter Schlag – für Undo-Banner
    @Published var lastAutoSwingDate: Date?

    /// GPS-Position des letzten Schwungs (Startpunkt des aktuellen Schlags)
    private var lastShotFromCoord: CLLocationCoordinate2D?

    init(holes: Int = 18, courseName: String = "") {
        self.holes = holes
        self.courseName = courseName
        self.strokes = Array(repeating: 0, count: holes)
        setupSwingDetector()
    }

    // MARK: - SwingDetector Setup

    private func setupSwingDetector() {
        swingDetector.onSwingDetected = { [weak self] coord in
            guard let self, self.autoDetectEnabled, !self.isFinished else { return }
            self.handleAutoSwing(at: coord)
        }
    }

    func linkLocationService(_ svc: WatchLocationService) {
        swingDetector.setLocationService(svc)
    }

    private func handleAutoSwing(at coord: CLLocationCoordinate2D?) {
        // Vorherigen Schlag abschließen: from = letztes coord, to = aktuelles coord
        if let from = lastShotFromCoord, let to = coord {
            let fromLoc = CLLocation(latitude: from.latitude, longitude: from.longitude)
            let toLoc   = CLLocation(latitude: to.latitude,   longitude: to.longitude)
            let dist    = fromLoc.distance(from: toLoc)

            // Schlag mit GPS an iPhone senden
            Task { @MainActor in
                WatchConnectivityManager.shared.sendShotToPhone(
                    holeIndex: self.currentHoleIndex,
                    fromLat: from.latitude, fromLon: from.longitude,
                    toLat: to.latitude,     toLon: to.longitude,
                    distance: dist
                )
            }
        }

        // Neuen Startpunkt setzen
        lastShotFromCoord = coord

        // Schlagzahl erhöhen
        strokes[currentHoleIndex] = min(20, strokes[currentHoleIndex] + 1)
        lastAutoSwingDate = Date()
        sendToPhone()
    }

    /// Letzten automatisch erkannten Schlag rückgängig machen
    func undoLastAutoSwing() {
        guard strokes[currentHoleIndex] > 0 else { return }
        strokes[currentHoleIndex] -= 1
        lastShotFromCoord = nil
        lastAutoSwingDate = nil
        WKInterfaceDevice.current().play(.click)
        sendToPhone()
    }

    func resetHoleTracking() {
        lastShotFromCoord = nil
    }

    // MARK: - Current hole

    var currentHole: Int { currentHoleIndex + 1 }
    var currentStrokes: Int {
        get { strokes[currentHoleIndex] }
        set { strokes[currentHoleIndex] = max(0, newValue) }
    }

    func increment() {
        strokes[currentHoleIndex] = min(20, strokes[currentHoleIndex] + 1)
        WKInterfaceDevice.current().play(.click)
        sendToPhone()
    }

    func decrement() {
        guard strokes[currentHoleIndex] > 0 else { return }
        strokes[currentHoleIndex] -= 1
        WKInterfaceDevice.current().play(.click)
        sendToPhone()
    }

    func nextHole() {
        resetHoleTracking()
        if currentHoleIndex < holes - 1 {
            currentHoleIndex += 1
            WKInterfaceDevice.current().play(.success)
        } else {
            isFinished = true
            swingDetector.stop()
            WKInterfaceDevice.current().play(.success)
        }
        sendToPhone()
    }

    func previousHole() {
        guard currentHoleIndex > 0 else { return }
        currentHoleIndex -= 1
        WKInterfaceDevice.current().play(.click)
        sendToPhone()
    }

    // MARK: - Sync von iPhone empfangen

    func applyFromPhone(holes: Int, strokes: [Int], currentHoleIndex: Int) {
        self.holes = holes
        self.strokes = strokes.count == holes ? strokes : Array(repeating: 0, count: holes)
        self.currentHoleIndex = min(currentHoleIndex, holes - 1)
        self.isFinished = false
        self.syncedWithPhone = true
    }

    func applyStrokesUpdate(strokes: [Int], currentHoleIndex: Int) {
        guard strokes.count == self.holes else { return }
        self.strokes = strokes
        self.currentHoleIndex = min(currentHoleIndex, holes - 1)
    }

    // MARK: - Schläge an iPhone senden

    private func sendToPhone() {
        guard syncedWithPhone else { return }
        Task { @MainActor in
            WatchConnectivityManager.shared.sendStrokesToPhone(
                strokes: self.strokes,
                currentHoleIndex: self.currentHoleIndex
            )
        }
    }

    // MARK: - Stats

    var totalStrokes: Int { strokes.reduce(0, +) }

    var completedHoles: Int {
        strokes.filter { $0 > 0 }.count
    }

    func reset() {
        strokes = Array(repeating: 0, count: holes)
        currentHoleIndex = 0
        isFinished = false
        syncedWithPhone = false
        lastShotFromCoord = nil
        lastAutoSwingDate = nil
        swingDetector.stop()
    }
}
