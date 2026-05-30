import Foundation
import WatchConnectivity
import Combine

// MARK: - Platz-Datenstruktur (Watch-seitig, kein SwiftData)

struct WatchCourse: Identifiable, Equatable {
    let name: String
    let holes: Int
    let totalPar: Int
    var id: String { name }
}

// MARK: - Manager (Watch-Seite)

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // Callbacks → SetupView / WatchRoundModel reagieren darauf
    var onStartRound: ((_ holes: Int, _ strokes: [Int], _ currentHole: Int) -> Void)?
    var onUpdateStrokes: ((_ strokes: [Int], _ currentHole: Int) -> Void)?
    var onFinishRound: (() -> Void)?
    var onCoursesReceived: ((_ courses: [WatchCourse]) -> Void)?

    private override init() {
        super.init()
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Schläge von Watch → iPhone senden

    func sendStrokesToPhone(strokes: [Int], currentHoleIndex: Int) {
        guard WCSession.default.activationState == .activated else { return }
        let payload: [String: Any] = [
            "action":      "watchUpdate",
            "strokes":     strokes,
            "currentHole": currentHoleIndex
        ]
        sendToPhone(payload)
    }

    // MARK: - Platzliste von iPhone anfordern

    func requestCourseList() {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            // Phone nicht erreichbar → sofort leere Liste melden
            onCoursesReceived?([])
            return
        }
        WCSession.default.sendMessage(["action": "requestCourseList"],
                                      replyHandler: nil, errorHandler: nil)
    }

    // MARK: - Runde auf iPhone starten (Watch → iPhone)

    func sendStartRoundRequest(courseName: String, holes: Int) {
        guard WCSession.default.activationState == .activated else { return }
        let payload: [String: Any] = [
            "action":     "watchStartRound",
            "courseName": courseName,
            "holes":      holes
        ]
        sendToPhone(payload)
    }

    // MARK: - Schlag von Watch → iPhone senden

    func sendShotToPhone(holeIndex: Int,
                         fromLat: Double, fromLon: Double,
                         toLat: Double, toLon: Double,
                         distance: Double) {
        guard WCSession.default.activationState == .activated else { return }
        let payload: [String: Any] = [
            "action":    "watchShot",
            "holeIndex": holeIndex,
            "fromLat":   fromLat,
            "fromLon":   fromLon,
            "toLat":     toLat,
            "toLon":     toLon,
            "distance":  distance
        ]
        sendToPhone(payload)
    }

    // MARK: - Letzten gespeicherten Context laden (falls App kalt gestartet)

    func loadPendingContext() {
        let ctx = WCSession.default.receivedApplicationContext
        handlePayload(ctx)
    }

    // MARK: - Intern: Nachricht senden

    private func sendToPhone(_ payload: [String: Any]) {
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
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in
            self.loadPendingContext()
        }
    }

    // Echtzeit-Nachrichten
    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handlePayload(message)
        }
    }

    // ApplicationContext (Watch-App war nicht aktiv)
    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in
            self.handlePayload(context)
        }
    }

    // MARK: - Payload verarbeiten

    @MainActor
    private func handlePayload(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else { return }

        switch action {
        case "startRound":
            guard let holes   = payload["holes"]        as? Int,
                  let strokes = payload["strokes"]       as? [Int],
                  let hole    = payload["currentHole"]   as? Int
            else { return }
            onStartRound?(holes, strokes, hole)

        case "updateStrokes":
            guard let strokes = payload["strokes"]       as? [Int],
                  let hole    = payload["currentHole"]   as? Int
            else { return }
            onUpdateStrokes?(strokes, hole)

        case "finishRound":
            onFinishRound?()

        case "courseList":
            guard let coursesData = payload["courses"] as? [[String: Any]] else { return }
            let courses: [WatchCourse] = coursesData.compactMap { dict in
                guard let name  = dict["name"]     as? String,
                      let holes = dict["holes"]    as? Int,
                      let par   = dict["totalPar"] as? Int
                else { return nil }
                return WatchCourse(name: name, holes: holes, totalPar: par)
            }
            onCoursesReceived?(courses)

        default:
            break
        }
    }
}
