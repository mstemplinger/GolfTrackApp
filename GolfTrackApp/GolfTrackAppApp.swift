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
        configureTabBarAppearance()
        // Game Center Authentifizierung beim Start
        Task { @MainActor in
            GameCenterManager.shared.authenticate()
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashContainerView()
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Course.self, Round.self, HoleScore.self, Shot.self, PlayerHoleScore.self, QuizResult.self, GolfClub.self])
    }
}
