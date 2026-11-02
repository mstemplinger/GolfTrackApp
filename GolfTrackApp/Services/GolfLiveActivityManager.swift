import ActivityKit
import Foundation
import SwiftData

extension Notification.Name {
    /// Die Live Activity hat das Loch gewechselt; `object` ist die neue Lochnummer.
    static let liveActivityHoleChanged = Notification.Name("liveActivityHoleChanged")
}

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

    /// Hängt den Plus-Knopf der Live Activity an die Datenbank. Läuft im
    /// App-Start, damit der Knopf auch wirkt, wenn iOS die App nur dafür
    /// im Hintergrund weckt.
    static func registerStrokeHandler(container: ModelContainer) {
        AddStrokeIntent.handler = {
            addStroke(in: container.mainContext)
        }
        NextHoleIntent.handler = {
            nextHole(in: container.mainContext)
        }
    }

    /// Loch, auf dem eine wieder geöffnete Runde weitergeht: das der Live
    /// Activity, falls sie zu dieser Runde gehört – sonst das erste. Ohne das
    /// stünde man nach „Nächstes Loch“ im Sperrbildschirm und einem
    /// App-Neustart wieder auf Loch 1, und die Lochansicht schriebe das
    /// zurück in die Live Activity.
    static func resumeIndex(for round: Round) -> Int {
        guard !round.isComplete,
              let activity = current ?? Activity<GolfRoundAttributes>.activities.first,
              activity.attributes.courseName == (round.course?.name ?? "GolfTrack")
        else { return 0 }
        let sorted = round.holeScores.sorted { $0.holeNumber < $1.holeNumber }
        return sorted.firstIndex { $0.holeNumber == activity.content.state.holeNumber } ?? 0
    }

    // MARK: - Private

    /// Jüngste offene Runde – die, zu der die Live Activity gehört.
    private static func openRound(in context: ModelContext) -> Round? {
        var descriptor = FetchDescriptor<Round>(
            predicate: #Predicate { !$0.isComplete },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Schaltet die Live Activity aufs nächste Loch und sagt der offenen
    /// Scorekarte Bescheid. Die Live Activity wird direkt aktualisiert, damit
    /// es auch klappt, wenn iOS die App nur im Hintergrund geweckt hat.
    private static func nextHole(in context: ModelContext) {
        if current == nil {
            current = Activity<GolfRoundAttributes>.activities.first
        }
        guard let activity = current else { return }
        let state = activity.content.state
        guard state.holeNumber < state.totalHoles,
              let round = openRound(in: context) else { return }

        let next = state.holeNumber + 1
        let score = round.holeScores.first { $0.holeNumber == next }
        let parValues = round.course?.parValues ?? []
        var newState = state
        newState.holeNumber = next
        newState.strokes = score?.strokes ?? 0
        newState.par = next - 1 < parValues.count ? parValues[next - 1] : 4
        Task { await activity.update(.init(state: newState, staleDate: nil)) }

        NotificationCenter.default.post(name: .liveActivityHoleChanged, object: next)
    }

    /// Zählt auf dem Loch, das die Live Activity gerade zeigt, einen Schlag
    /// dazu – in der jüngsten offenen Runde. Ohne GPS-Punkt: im Sperrbildschirm
    /// gibt es keine Schlägerwahl und keinen Standort aus der Lochansicht.
    private static func addStroke(in context: ModelContext) {
        if current == nil {
            current = Activity<GolfRoundAttributes>.activities.first
        }
        guard let activity = current else { return }
        let state = activity.content.state

        guard let round = openRound(in: context),
              let score = round.holeScores.first(where: { $0.holeNumber == state.holeNumber })
        else { return }

        score.strokes += 1
        try? context.save()

        var newState = state
        newState.strokes = score.strokes
        Task { await activity.update(.init(state: newState, staleDate: nil)) }
    }

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
