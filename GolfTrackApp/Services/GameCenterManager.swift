import GameKit
import SwiftUI
import Combine

// MARK: - Leaderboard + Achievement Identifiers

enum GCLeaderboard {
    static let bestRoundScore = "com.TobiasAufschlaeger.GolfTrackappnew.bestScore"
}

// MARK: - Achievement Identifiers

enum GCAchievement: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case firstRound     = "com.TobiasAufschlaeger.GolfTrackappnew.firstRound"
    case rounds10       = "com.TobiasAufschlaeger.GolfTrackappnew.rounds10"
    case rounds50       = "com.TobiasAufschlaeger.GolfTrackappnew.rounds50"
    case firstPar       = "com.TobiasAufschlaeger.GolfTrackappnew.firstPar"
    case firstBirdie    = "com.TobiasAufschlaeger.GolfTrackappnew.firstBirdie"
    case firstEagle     = "com.TobiasAufschlaeger.GolfTrackappnew.firstEagle"
    case handicapSub18  = "com.TobiasAufschlaeger.GolfTrackappnew.handicapSub18"
    case handicapSub10  = "com.TobiasAufschlaeger.GolfTrackappnew.handicapSub10"
    case allCategories  = "com.TobiasAufschlaeger.GolfTrackappnew.allCategories"

    var displayTitle: String {
        switch self {
        case .firstRound:    return "Erste Runde"
        case .rounds10:      return "10 Runden"
        case .rounds50:      return "50 Runden"
        case .firstPar:      return "Erstes Par"
        case .firstBirdie:   return "Erstes Birdie"
        case .firstEagle:    return "Erstes Eagle"
        case .handicapSub18: return "Handicap < 18"
        case .handicapSub10: return "Handicap < 10"
        case .allCategories: return "Alleskönner"
        }
    }

    var displayDescription: String {
        switch self {
        case .firstRound:    return "Schließe deine erste Runde ab"
        case .rounds10:      return "Schließe 10 Runden ab"
        case .rounds50:      return "Schließe 50 Runden ab"
        case .firstPar:      return "Spiele dein erstes Par"
        case .firstBirdie:   return "Spiele dein erstes Birdie"
        case .firstEagle:    return "Spiele dein erstes Eagle"
        case .handicapSub18: return "Erreiche ein Handicap unter 18"
        case .handicapSub10: return "Erreiche ein Handicap unter 10"
        case .allCategories: return "Schließe Runden auf 5 verschiedenen Plätzen ab"
        }
    }

    var icon: String {
        switch self {
        case .firstRound:    return "flag.fill"
        case .rounds10:      return "10.circle.fill"
        case .rounds50:      return "50.circle.fill"
        case .firstPar:      return "equal.circle.fill"
        case .firstBirdie:   return "bird.fill"
        case .firstEagle:    return "star.fill"
        case .handicapSub18: return "18.circle.fill"
        case .handicapSub10: return "10.circle.fill"
        case .allCategories: return "map.fill"
        }
    }

    var hint: String {
        switch self {
        case .firstRound:
            return "Spiele eine vollständige Runde (alle Löcher eintragen) und schließe sie ab."
        case .rounds10:
            return "Spiele 10 Runden bis zum Ende. Jede abgeschlossene Runde zählt – egal auf welchem Platz."
        case .rounds50:
            return "Spiele 50 abgeschlossene Runden. Dein Fortschritt wird automatisch gespeichert."
        case .firstPar:
            return "Spiele auf einem Loch genau so viele Schläge wie der Par-Wert des Lochs beträgt (z. B. 4 Schläge auf Par 4)."
        case .firstBirdie:
            return "Spiele auf einem Loch einen Schlag weniger als Par (z. B. 3 Schläge auf Par 4). Ein toller Schlag!"
        case .firstEagle:
            return "Spiele auf einem Loch zwei Schläge weniger als Par (z. B. 2 Schläge auf Par 4). Sehr selten und beeindruckend!"
        case .handicapSub18:
            return "Senke dein Handicap auf unter 18. Das gelingt durch regelmäßiges Spielen und konstante Verbesserung."
        case .handicapSub10:
            return "Senke dein Handicap auf unter 10. Das erfordert viel Übung – du bist dann ein sehr erfahrener Golfer!"
        case .allCategories:
            return "Schließe Runden auf 5 verschiedenen Golfplätzen ab. Erkunde neue Plätze in deiner Region oder auf Reisen."
        }
    }
}

// MARK: - Manager

@MainActor
final class GameCenterManager: ObservableObject {

    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var localPlayer: GKLocalPlayer = .local

    // Lokaler State – unabhängig von Game Center
    @Published var unlockedAchievements: Set<String> = []
    @Published var achievementProgress: [String: Double] = [:]

    private let defaults = UserDefaults.standard
    private let unlockedKey = "gc_unlocked_achievements"
    private let progressKey = "gc_achievement_progress"

    private var authVC: UIViewController?

    private init() {
        loadLocalState()
    }

    // MARK: - Lokalen State laden / speichern

    private func loadLocalState() {
        if let saved = defaults.array(forKey: unlockedKey) as? [String] {
            unlockedAchievements = Set(saved)
        }
        if let saved = defaults.dictionary(forKey: progressKey) as? [String: Double] {
            achievementProgress = saved
        }
    }

    private func saveLocalState() {
        defaults.set(Array(unlockedAchievements), forKey: unlockedKey)
        defaults.set(achievementProgress, forKey: progressKey)
    }

    // MARK: - Authentication (optional für Game Center Sharing)

    func authenticate(presentingVC: UIViewController? = nil) {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            Task { @MainActor in
                if let vc = viewController {
                    self.authVC = vc
                    let presenter = presentingVC ?? UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows.first?.rootViewController
                    presenter?.present(vc, animated: true)
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.isAuthenticated = true
                    self.localPlayer = GKLocalPlayer.local
                    // Game Center State mit lokalem State synchronisieren
                    await self.syncWithGameCenter()
                } else {
                    self.isAuthenticated = false
                }
            }
        }
    }

    // Gleicht Game Center Fortschritt mit lokalem State ab
    private func syncWithGameCenter() async {
        guard isAuthenticated else { return }
        do {
            let gcAchievements = try await GKAchievement.loadAchievements()
            for a in gcAchievements {
                // Game Center gewinnt nur wenn weiter als lokal
                let localProg = achievementProgress[a.identifier] ?? 0
                if a.percentComplete > localProg {
                    achievementProgress[a.identifier] = a.percentComplete
                }
                if a.isCompleted {
                    unlockedAchievements.insert(a.identifier)
                }
            }
            saveLocalState()
            // Lokale Fortschritte zurück zu Game Center melden falls nötig
            await reportPendingToGameCenter()
        } catch {
            // Game Center nicht erreichbar – lokaler State bleibt gültig
        }
    }

    // Meldet lokal gespeicherte Fortschritte an Game Center nach
    private func reportPendingToGameCenter() async {
        guard isAuthenticated else { return }
        var toReport: [GKAchievement] = []
        for (id, progress) in achievementProgress {
            let gk = GKAchievement(identifier: id)
            gk.percentComplete = progress
            gk.showsCompletionBanner = progress >= 100
            toReport.append(gk)
        }
        guard !toReport.isEmpty else { return }
        try? await GKAchievement.report(toReport)
    }

    // MARK: - Lokal entsperren + optional an Game Center melden

    private func unlock(_ achievement: GCAchievement, percentComplete: Double = 100.0) {
        let id = achievement.rawValue
        let currentProgress = achievementProgress[id] ?? 0

        // Nur updaten wenn Fortschritt gestiegen
        guard percentComplete > currentProgress else { return }

        achievementProgress[id] = percentComplete
        if percentComplete >= 100 {
            unlockedAchievements.insert(id)
        }
        saveLocalState()

        // Zusätzlich an Game Center melden wenn eingeloggt
        if isAuthenticated {
            let gk = GKAchievement(identifier: id)
            gk.percentComplete = percentComplete
            gk.showsCompletionBanner = percentComplete >= 100
            Task { try? await GKAchievement.report([gk]) }
        }
    }

    // MARK: - Achievements aus Runden auswerten (funktioniert OHNE Game Center)

    func evaluateAchievements(rounds: [Round]) {
        let completed = rounds.filter(\.isComplete)

        // Erste Runde
        if !completed.isEmpty {
            unlock(.firstRound)
        }

        // 10 / 50 Runden (mit Fortschritt)
        let count = completed.count
        unlock(.rounds10, percentComplete: min(100, Double(count) / 10.0 * 100))
        unlock(.rounds50, percentComplete: min(100, Double(count) / 50.0 * 100))

        // Par / Birdie / Eagle
        var hasPar    = false
        var hasBirdie = false
        var hasEagle  = false

        for round in completed {
            guard let course = round.course else { continue }
            let parValues = course.parValues
            for (idx, hole) in round.holeScores.enumerated() {
                guard idx < parValues.count, hole.strokes > 0 else { continue }
                let par = parValues[idx]
                if hole.strokes == par     { hasPar    = true }
                if hole.strokes == par - 1 { hasBirdie = true }
                if hole.strokes <= par - 2 { hasEagle  = true }
            }
        }
        if hasPar    { unlock(.firstPar) }
        if hasBirdie { unlock(.firstBirdie) }
        if hasEagle  { unlock(.firstEagle) }

        // Verschiedene Plätze
        let courseCount = Set(completed.compactMap { $0.course?.name }).count
        unlock(.allCategories, percentComplete: min(100, Double(courseCount) / 5.0 * 100))

        // Handicap-Errungenschaften werden manuell über die Profil-Statistiken ausgewertet
        // und können über unlock(.handicapSub18) / unlock(.handicapSub10) ausgelöst werden
    }

    // MARK: - Access Point (Aktivitätsstatus während einer Runde)

    /// Access Point dauerhaft deaktiviert – Rakete wird nicht angezeigt.
    func activateAccessPoint() {
        GKAccessPoint.shared.isActive = false
    }

    func deactivateAccessPoint() {
        GKAccessPoint.shared.isActive = false
    }

    // MARK: - Leaderboard: Score einreichen

    /// Schickt den Runden-Score (Schläge) an die Bestenliste. Niedriger = besser.
    func submitRoundScore(_ totalStrokes: Int) {
        guard isAuthenticated, totalStrokes > 0 else { return }
        Task {
            try? await GKLeaderboard.submitScore(
                totalStrokes,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [GCLeaderboard.bestRoundScore]
            )
        }
    }

    // MARK: - Show Game Center UI

    func showGameCenter(from viewController: UIViewController? = nil) {
        guard isAuthenticated else { return }
        let gcVC = GKGameCenterViewController(state: .achievements)
        gcVC.gameCenterDelegate = GameCenterDelegateHandler.shared
        topMostViewController(from: viewController)?.present(gcVC, animated: true)
    }

    /// Öffnet die Freunde-Bestenliste für den besten Runden-Score
    func showLeaderboard(from viewController: UIViewController? = nil) {
        guard isAuthenticated else { return }
        let gcVC = GKGameCenterViewController(
            leaderboardID: GCLeaderboard.bestRoundScore,
            playerScope: .friendsOnly,
            timeScope: .allTime
        )
        gcVC.gameCenterDelegate = GameCenterDelegateHandler.shared
        topMostViewController(from: viewController)?.present(gcVC, animated: true)
    }

    // MARK: - Obersten präsentierten ViewController finden

    private func topMostViewController(from base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)?
            .rootViewController

        func top(_ vc: UIViewController?) -> UIViewController? {
            if let nav = vc as? UINavigationController {
                return top(nav.visibleViewController)
            }
            if let tab = vc as? UITabBarController {
                return top(tab.selectedViewController)
            }
            if let presented = vc?.presentedViewController {
                return top(presented)
            }
            return vc
        }
        return top(root)
    }

    func isUnlocked(_ achievement: GCAchievement) -> Bool {
        unlockedAchievements.contains(achievement.rawValue)
    }

    func progress(for achievement: GCAchievement) -> Double {
        achievementProgress[achievement.rawValue] ?? 0
    }
}

// MARK: - Delegate Handler

final class GameCenterDelegateHandler: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDelegateHandler()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
