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
    /// Läuft, während der Platzkatalog wegen eines unbekannten Codes nachgeladen wird.
    @State private var deepLinkLoading = false
    /// Text der Meldung, wenn ein gescannter Code zu keiner Anlage führt.
    @State private var deepLinkFehler: String?

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
            Task { await handleDeepLink(url) }
        }
        // Universal Link bzw. App-Clip-Aufruf (…/minigolf/<anlage>)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL else { return }
            Task { await handleDeepLink(url) }
        }
        .fullScreenCover(item: $scannedMinigolfCourse) { course in
            MinigolfCourseStartView(course: course)
                .preferredColorScheme(.dark)
        }
        .overlay {
            if deepLinkLoading {
                ZStack {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    ProgressView("Anlage wird gesucht …")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .transition(.opacity)
            }
        }
        .alert(
            "Anlage nicht gefunden",
            isPresented: Binding(
                get: { deepLinkFehler != nil },
                set: { if !$0 { deepLinkFehler = nil } }
            )
        ) {
            Button("OK", role: .cancel) { deepLinkFehler = nil }
        } message: {
            Text(deepLinkFehler ?? "")
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
    /// QR-Code oder Universal Link auswerten.
    ///
    /// Der Katalog gleicht sich von allein nur alle sechs Stunden ab. Eine
    /// Anlage, die die Website vor zehn Minuten freigegeben hat, steht deshalb
    /// oft noch nicht im Zwischenspeicher. Früher endete das stumm: der
    /// Universal Link tat nichts, das eigene Schema landete wortlos auf dem
    /// Home-Tab. Jetzt wird bei einem unbekannten Code einmal erzwungen
    /// nachgeladen, und wenn die Anlage dann immer noch fehlt, sagt die App es.
    @MainActor
    private func handleDeepLink(_ url: URL) async {
        if let course = CourseCatalogService.shared.course(fromDeepLink: url) {
            openScanned(course)
            return
        }

        // Kein Anlagen-Link: die übrigen Adressen wie bisher behandeln.
        guard MinigolfDeepLink.courseID(from: url) != nil else {
            // golftrack://home  → Home-Tab öffnen
            // golftrack://shottracker → Home-Tab + Runde fortsetzen
            if url.scheme == "golftrack" {
                selectedTab = 0
                if url.host == "shottracker" {
                    NotificationCenter.default.post(name: .openShotTracker, object: nil)
                }
            }
            return
        }

        deepLinkLoading = true
        await CourseCatalogService.shared.refresh()
        deepLinkLoading = false

        if let course = CourseCatalogService.shared.course(fromDeepLink: url) {
            openScanned(course)
        } else if CourseCatalogService.shared.lastError != nil {
            deepLinkFehler = "Das Platzverzeichnis ließ sich nicht laden. Prüf die Internetverbindung und scanne den Code noch einmal."
        } else {
            deepLinkFehler = "Diese Anlage steht noch nicht im Verzeichnis. Wurde sie gerade erst freigegeben, versuch es in ein paar Minuten noch einmal."
        }
    }

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
