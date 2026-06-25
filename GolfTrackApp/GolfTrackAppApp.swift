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

    init() {
        configureNavigationBarAppearance()
        // Ab iOS 26 rendert die schwebende Liquid-Glass-Tab-Bar mit einer
        // opaken UITabBarAppearance beim Kaltstart fehlerhaft (riesige,
        // abgeschnittene Labels) — dort die System-Tab-Bar verwenden.
        if #unavailable(iOS 26.0) {
            configureTabBarAppearance()
        }
        // Game Center Authentifizierung beim Start
        Task { @MainActor in
            GameCenterManager.shared.authenticate()
            await NotificationManager.shared.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashContainerView()
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Course.self, Round.self, HoleScore.self, Shot.self, PlayerHoleScore.self, QuizResult.self, GolfClub.self, GolfBag.self])
    }
}
