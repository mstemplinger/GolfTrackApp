import SwiftUI
import SwiftData

extension Notification.Name {
    static let openShotTracker = Notification.Name("openShotTracker")
}

struct ContentView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    @State private var tutorialFrames: [String: CGRect] = [:]

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)
                TrainingView()
                    .tabItem { Label("Training", systemImage: "figure.golf") }
                    .tag(1)
                NavigationStack { GolfRulesView() }
                    .tabItem { Label("Spielregeln", systemImage: "book.fill") }
                    .tag(2)
                TipsView()
                    .tabItem { Label("Tipps", systemImage: "lightbulb.fill") }
                    .tag(3)
                ProfileView()
                    .tabItem { Label("Profil", systemImage: "person.fill") }
                    .tag(4)
            }
            .tint(AppTheme.gold)
            .onPreferenceChange(TutorialFrameKey.self) { frames in
                tutorialFrames = frames
            }

            if !hasSeenOnboarding {
                OnboardingOverlayView(selectedTab: $selectedTab, frames: tutorialFrames)
                    .transition(.opacity)
            }
        }
        // ZStack bekommt den coordinateSpace – gleich für Overlay und Tab-Inhalte
        .coordinateSpace(name: "screen")
        .onOpenURL { url in
            // golftrack://home  → Home-Tab öffnen
            // golftrack://shottracker → Home-Tab + Runde fortsetzen (via NotificationCenter)
            if url.scheme == "golftrack" {
                selectedTab = 0
                if url.host == "shottracker" {
                    NotificationCenter.default.post(name: .openShotTracker, object: nil)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Course.self, Round.self, HoleScore.self, Shot.self, PlayerHoleScore.self, QuizResult.self], inMemory: true)
}
