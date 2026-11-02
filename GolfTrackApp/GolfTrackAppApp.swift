//
//  GolfTrackAppApp.swift
//  GolfTrackApp
//
//  Created by Tobias Aufschläger on 30.04.26.
//

import SwiftUI
import SwiftData
import GameKit

@main
struct GolfTrackAppApp: App {

    @StateObject private var subscriptionManager = SubscriptionManager()

    /// Ein Container für Oberfläche und Live-Activity-Knopf: Der Schlag, den
    /// `AddStrokeIntent` im Hintergrund zählt, landet im selben Kontext, den
    /// die offene Lochansicht beobachtet, und erscheint dort sofort.
    static let sharedContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Course.self, Round.self, HoleScore.self, Shot.self, PlayerHoleScore.self, QuizResult.self, GolfClub.self, GolfBag.self, RoundTrack.self)
        } catch {
            fatalError("ModelContainer konnte nicht angelegt werden: \(error)")
        }
    }()

    init() {
        configureNavigationBarAppearance()
        GolfLiveActivityManager.registerStrokeHandler(container: Self.sharedContainer)
        // Ab iOS 26 rendert die schwebende Liquid-Glass-Tab-Bar mit einer
        // opaken UITabBarAppearance beim Kaltstart fehlerhaft (riesige,
        // abgeschnittene Labels) — dort die System-Tab-Bar verwenden.
        if #unavailable(iOS 26.0) {
            configureTabBarAppearance()
        }
        // Game Center Authentifizierung beim Start
        Task { @MainActor in
            // Haptik-Generatoren vorwärmen, damit der erste Impuls sitzt.
            Haptics.warmUp()
            GameCenterManager.shared.authenticate()
            NotificationManager.shared.becomeDelegate()
            await NotificationManager.shared.requestAuthorization()
            // Zonen wieder aufnehmen, falls der Nutzer die Mitteilung bei
            // Annäherung eingeschaltet hat.
            NearbyCourseService.shared.resumeMonitoringIfEnabled()
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashContainerView()
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.dark)
                .seedDemoDataIfRequested()
                .simulateTrackedRoundIfRequested()
        }
        .modelContainer(Self.sharedContainer)
    }
}
