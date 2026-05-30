import Foundation
import WatchConnectivity
import Combine

// MARK: - Nachrichten-Keys

enum WCMessageKey {
    static let action          = "action"
    static let holes           = "holes"
    static let strokes         = "strokes"
    static let currentHole     = "currentHole"
    static let isFinished      = "isFinished"
    static let courses         = "courses"      // iPhone → Watch: Platzliste
    static let courseName      = "courseName"   // Watch → iPhone: gewählter Platz
}

enum WCAction {
    static let startRound       = "startRound"
    static let updateStrokes    = "updateStrokes"
    static let finishRound      = "finishRound"
    static let watchUpdate      = "watchUpdate"      // Watch → iPhone: Schläge
    static let courseList       = "courseList"        // iPhone → Watch: Plätze senden
    static let requestCourseList = "requestCourseList" // Watch → iPhone: Plätze anfordern
    static let watchStartRound  = "watchStartRound"  // Watch → iPhone: Runde starten
    static let watchShot        = "watchShot"         // Watch → iPhone: Schlag aufzeichnen
}

// MARK: - Manager (iPhone-Seite)

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isWatchReachable = false

    // Callbacks
    var onWatchStrokesUpdate: ((_ strokes: [Int], _ currentHole: Int) -> Void)?
    var onWatchStartRoundRequest: ((_ courseName: String, _ holes: Int) -> Void)?
    var onRequestCourseList: (() -> Void)?
    /// holeIndex (0-based), fromLat, fromLon, toLat, toLon, distanceMeters
    var onWatchShotReceived: ((_ holeIndex: Int, _ fromLat: Double, _ fromLon: Double,
                               _ toLat: Double, _ toLon: Double, _ distance: Double) -> Void)?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Runde starten (iPhone → Watch)

    func startRound(holes: Int, strokes: [Int], currentHoleIndex: Int) {
        let payload: [String: Any] = [
            WCMessageKey.action:       WCAction.startRound,
            WCMessageKey.holes:        holes,
            WCMessageKey.strokes:      strokes,
            WCMessageKey.currentHole:  currentHoleIndex
        ]
        sendToWatch(payload)
    }

    // MARK: - Schläge aktualisieren (iPhone → Watch)

    func updateStrokes(strokes: [Int], currentHoleIndex: Int) {
        let payload: [String: Any] = [
            WCMessageKey.action:      WCAction.updateStrokes,
            WCMessageKey.strokes:     strokes,
            WCMessageKey.currentHole: currentHoleIndex
        ]
        sendToWatch(payload)
    }

    // MARK: - Runde beenden (iPhone → Watch)

    func finishRound() {
        let payload: [String: Any] = [
            WCMessageKey.action:      WCAction.finishRound,
            WCMessageKey.isFinished:  true
        ]
        sendToWatch(payload)
    }

    // MARK: - Plätze an Watch senden (iPhone → Watch)

    func sendCoursesToWatch(_ courses: [Course]) {
        let courseData: [[String: Any]] = courses.map { course in
            [
                "name":       course.name,
                "holes":      course.numberOfHoles,
                "totalPar":   course.totalPar
            ]
        }
        let payload: [String: Any] = [
            WCMessageKey.action:  WCAction.courseList,
            WCMessageKey.courses: courseData
        ]
        sendToWatch(payload)
    }

    // MARK: - Senden (Message wenn erreichbar, sonst ApplicationContext)

    private func sendToWatch(_ payload: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(payload)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    // Nachrichten von der Watch empfangen
    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any]) {
        guard let action = message[WCMessageKey.action] as? String else { return }

        switch action {
        case WCAction.watchUpdate:
            guard let strokes = message[WCMessageKey.strokes] as? [Int],
                  let currentHole = message[WCMessageKey.currentHole] as? Int
            else { return }
            Task { @MainActor in
                self.onWatchStrokesUpdate?(strokes, currentHole)
            }

        case WCAction.requestCourseList:
            Task { @MainActor in
                self.onRequestCourseList?()
            }

        case WCAction.watchStartRound:
            guard let courseName = message[WCMessageKey.courseName] as? String,
                  let holes = message[WCMessageKey.holes] as? Int
            else { return }
            Task { @MainActor in
                self.onWatchStartRoundRequest?(courseName, holes)
            }

        case WCAction.watchShot:
            guard let holeIndex = message["holeIndex"]  as? Int,
                  let fromLat   = message["fromLat"]    as? Double,
                  let fromLon   = message["fromLon"]    as? Double,
                  let toLat     = message["toLat"]      as? Double,
                  let toLon     = message["toLon"]      as? Double,
                  let distance  = message["distance"]   as? Double
            else { return }
            Task { @MainActor in
                self.onWatchShotReceived?(holeIndex, fromLat, fromLon, toLat, toLon, distance)
            }

        default:
            break
        }
    }
}
