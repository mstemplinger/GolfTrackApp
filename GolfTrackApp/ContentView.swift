import SwiftUI
import SwiftData

extension Notification.Name {
    static let openShotTracker = Notification.Name("openShotTracker")
}

struct ContentView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage(AppFocus.chosenKey)  private var hasChosenAppFocus = false
    @AppStorage(AppFocus.storageKey) private var appFocus: AppFocus = .golf
    @State private var selectedTab = 0
    @State private var tutorialFrames: [String: CGRect] = [:]
    /// Über QR-Code / Universal Link gestartete Anlage – zeigt sofort den
    /// Begrüßungs- und Startbildschirm der Minigolfrunde.
    @State private var scannedMinigolfCourse: MinigolfCourseEntry?

    private var isMinigolfFocus: Bool { appFocus == .minigolf }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)
                TrainingView()
                    .tabItem { Label("Training", systemImage: "figure.golf") }
                    .tag(1)
                // Bei Minigolf-Schwerpunkt belegt Minigolf diesen Tab. Die
                // Golfregeln bleiben über die Scorekarte einer laufenden Runde
                // erreichbar; das Training bleibt auf Tab 1 (Tipps verlinken
                // dorthin).
                thirdTab
                    .tabItem {
                        isMinigolfFocus
                            ? Label("Minigolf", systemImage: "flag.2.crossed.fill")
                            : Label("Regeln", systemImage: "book.fill")
                    }
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

            // Tutorial erst nach getroffener Schwerpunkt-Auswahl
            if hasChosenAppFocus && !hasSeenOnboarding {
                OnboardingOverlayView(selectedTab: $selectedTab, frames: tutorialFrames)
                    .transition(.opacity)
            }

            // Allererster Start: Golf oder Minigolf?
            if !hasChosenAppFocus {
                AppFocusSelectionView()
                    .transition(.opacity)
            }
        }
        // ZStack bekommt den coordinateSpace – gleich für Overlay und Tab-Inhalte
        .coordinateSpace(name: "screen")
        .onAppear(perform: migrateExistingInstall)
        .onOpenURL { url in
            // golftrack://minigolf?platz=… → QR-Code an einer Anlage
            if let course = CourseCatalogService.shared.course(fromDeepLink: url) {
                openScanned(course)
                return
            }
            // golftrack://home  → Home-Tab öffnen
            // golftrack://shottracker → Home-Tab + Runde fortsetzen (via NotificationCenter)
            if url.scheme == "golftrack" {
                selectedTab = 0
                if url.host == "shottracker" {
                    NotificationCenter.default.post(name: .openShotTracker, object: nil)
                }
            }
        }
        // Universal Link bzw. App-Clip-Aufruf (…/minigolf/<anlage>)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL,
                  let course = CourseCatalogService.shared.course(fromDeepLink: url) else { return }
            openScanned(course)
        }
        .fullScreenCover(item: $scannedMinigolfCourse) { course in
            MinigolfCourseStartView(course: course)
                .preferredColorScheme(.dark)
        }
        // Empfehlung aus den Tipps → zum Training-Tab wechseln
        .onReceive(NotificationCenter.default.publisher(for: .openTraining)) { _ in
            selectedTab = 1
        }
    }

    @ViewBuilder
    private var thirdTab: some View {
        if isMinigolfFocus {
            MinigolfView()
        } else {
            NavigationStack { GolfRulesView() }
        }
    }

    /// QR-Code an der Anlage gescannt: direkt in die Begrüßung. Wer die App
    /// dafür frisch installiert hat, hat den Schwerpunkt noch nicht gewählt –
    /// dann ist Minigolf die passende Antwort und das Golf-Tutorial entfällt.
    private func openScanned(_ course: MinigolfCourseEntry) {
        if !hasChosenAppFocus {
            appFocus = .minigolf
            hasChosenAppFocus = true
            hasSeenOnboarding = true
        }
        scannedMinigolfCourse = course
    }

    /// Bestandsinstallationen haben das Tutorial bereits gesehen – die
    /// Schwerpunkt-Auswahl darf ihnen nicht nachträglich vorgesetzt werden.
    private func migrateExistingInstall() {
        if hasSeenOnboarding && !hasChosenAppFocus {
            hasChosenAppFocus = true
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Course.self, Round.self, HoleScore.self, Shot.self, PlayerHoleScore.self, QuizResult.self, RoundTrack.self], inMemory: true)
}
