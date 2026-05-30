import ActivityKit
import Foundation

/// Manages the Golf round Live Activity on the lock screen / Dynamic Island.
@MainActor
final class GolfLiveActivityManager {

    private static var current: Activity<GolfRoundAttributes>?

    // MARK: - Public API

    /// Call on every hole-scoring view appear and on strokes/hole changes.
    static func update(holeNumber: Int, totalHoles: Int, strokes: Int, par: Int, courseName: String) {
        let state = GolfRoundAttributes.ContentState(
            holeNumber: holeNumber, totalHoles: totalHoles,
            strokes: strokes, par: par
        )

        // Recover persisted activity after app restart
        if current == nil {
            current = Activity<GolfRoundAttributes>.activities.first
        }

        if let activity = current {
            Task { await activity.update(.init(state: state, staleDate: nil)) }
        } else {
            start(state: state, courseName: courseName)
        }
    }

    /// Call when the round is finished.
    static func endRound() {
        Task {
            // End the in-memory reference
            if let activity = current {
                await activity.end(.init(state: activity.content.state, staleDate: nil),
                                   dismissalPolicy: .default)
            }
            // Also end any persisted activities that survived an app restart
            for activity in Activity<GolfRoundAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            current = nil
        }
    }

    // MARK: - Private

    private static func start(state: GolfRoundAttributes.ContentState, courseName: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = GolfRoundAttributes(courseName: courseName)
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            current = activity
        } catch {
            // User may have denied Live Activities — silently ignore.
            print("Live Activity start failed: \(error.localizedDescription)")
        }
    }
}
