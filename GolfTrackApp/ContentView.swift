import SwiftUI
import SwiftData

extension Notification.Name {
    static let openShotTracker = Notification.Name("openShotTracker")
}

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage(AppFocus.chosenKey)  private var hasChosenAppFocus = false
    @AppStorage(AppFocus.storageKey) private var appFocus: AppFocus = .golf
    @State private var selectedTab = 0
    @State private var tutorialFrames: [String: CGRect] = [:]
    /// Über QR-Code / Universal Link gestartete Anlage – zeigt sofort den
    /// Begrüßungs- und Startbildschirm der Minigolfrunde.
    @State private var scannedMinigolfCourse: MinigolfCourseEntry?
    /// Über QR-Code gestarteter Golfplatz – öffnet den gewohnten Rundenstart
    /// mit vorgewähltem Platz, damit Bag, Spielform und Mitspieler noch
    /// gewählt werden können.
    @State private var scannedGolfCourse: Course?
    /// Läuft, während der Platzkatalog wegen eines unbekannten Codes nachgeladen wird.
    @State private var deepLinkLoading = false
    /// Text der Meldung, wenn ein gescannter Code zu keiner Anlage führt.
    @State private var deepLinkFehler: String?
    /// Wie viele im App Clip gezählte Runden gerade übernommen wurden.
    @State private var importedClipRounds = 0

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
            .onChange(of: selectedTab) { _, _ in Haptics.selection() }
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
        // Runden aus dem App Clip einsammeln. Muss nach dem Start laufen, weil
        // erst dann ein Datenkontext bereitsteht; der Katalog wird abgewartet,
        // damit der Platz vollständig angelegt wird statt als Notnagel.
        .task {
            await CourseCatalogService.shared.refreshIfNeeded()
            let count = ClipRoundImporter.importPendingRounds(into: modelContext)
            if count > 0 { importedClipRounds = count }
        }
        .alert("Runde übernommen", isPresented: Binding(
            get: { importedClipRounds > 0 },
            set: { if !$0 { importedClipRounds = 0 } }
        )) {
            Button("Gut") {
                Haptics.tap()
                importedClipRounds = 0
            }
        } message: {
            Text(importedClipRounds == 1
                 ? "Deine Runde aus dem App Clip steht jetzt in der App."
                 : "\(importedClipRounds) Runden aus dem App Clip stehen jetzt in der App.")
        }
        .onOpenURL { url in
            Task { await handleDeepLink(url) }
        }
        #if DEBUG
        // Zum Durchspielen ohne echten Scan. `simctl openurl` legt vor jedem
        // eigenen Schema eine Rückfrage vor, die nur von Hand zu beantworten
        // ist – im Simulator ist der Weg damit sonst nicht prüfbar. Der Clip
        // hat aus demselben Grund `_XCAppClipURL`.
        .task {
            guard let raw = ProcessInfo.processInfo.environment["GOLFTRACK_DEEPLINK"],
                  let url = URL(string: raw) else { return }
            await handleDeepLink(url)
        }
        #endif
        // Universal Link bzw. App-Clip-Aufruf (…/minigolf/<anlage>)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL else { return }
            Task { await handleDeepLink(url) }
        }
        .fullScreenCover(item: $scannedMinigolfCourse) { course in
            MinigolfCourseStartView(course: course)
                .preferredColorScheme(.dark)
        }
        .fullScreenCover(item: $scannedGolfCourse) { course in
            NewRoundView(preselectedCourse: course)
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
            Button("OK", role: .cancel) {
                Haptics.tap()
                deepLinkFehler = nil
            }
        } message: {
            Text(deepLinkFehler ?? "")
        }
        // Mitteilung „Du stehst am Platz" angetippt
        .onReceive(NotificationCenter.default.publisher(for: .openCourseFromNotification)) { note in
            guard let url = note.object as? URL else { return }
            Task { await handleDeepLink(url) }
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
        // Golf und Minigolf über dieselbe Auswertung wie im App Clip. Vorher
        // kannte diese Stelle nur Minigolf – ein Golfplatz-Code öffnete die
        // App und tat dann nichts.
        guard let link = CourseDeepLink.link(from: url) else {
            // golftrack://home  → Home-Tab öffnen
            // golftrack://shottracker → Home-Tab + Runde fortsetzen
            if url.scheme == CourseDeepLink.scheme {
                selectedTab = 0
                if url.host == "shottracker" {
                    NotificationCenter.default.post(name: .openShotTracker, object: nil)
                }
            }
            return
        }

        if open(link) { return }

        deepLinkLoading = true
        await CourseCatalogService.shared.refresh()
        deepLinkLoading = false

        if open(link) { return }

        Haptics.error()
        deepLinkFehler = CourseCatalogService.shared.lastError != nil
            ? "Das Platzverzeichnis ließ sich nicht laden. Prüf die Internetverbindung und scanne den Code noch einmal."
            : "Diese Anlage steht noch nicht im Verzeichnis. Wurde sie gerade erst freigegeben, versuch es in ein paar Minuten noch einmal."
    }

    /// Öffnet den Platz hinter dem Link. `false`, wenn er im Katalog fehlt –
    /// dann lädt der Aufrufer einmal nach und fragt erneut.
    @MainActor
    private func open(_ link: CourseLink) -> Bool {
        switch link.kind {
        case .minigolf:
            guard let entry = CourseCatalogService.shared.minigolfCourse(id: link.slug) else { return false }
            openScanned(entry)
        case .golf:
            guard let entry = CourseCatalogService.shared.golfCourse(slug: link.slug) else { return false }
            openScanned(golf: entry)
        case nil:
            // Kurzform `play.golftrack.app/p/<kennung>` – die Art steht nicht
            // im Link. Die Kennungen sind über beide Arten hinweg eindeutig,
            // also genügt es, der Reihe nach zu suchen.
            if let entry = CourseCatalogService.shared.minigolfCourse(id: link.slug) {
                openScanned(entry)
            } else if let entry = CourseCatalogService.shared.golfCourse(slug: link.slug) {
                openScanned(golf: entry)
            } else {
                return false
            }
        }
        return true
    }

    private func openScanned(_ course: MinigolfCourseEntry) {
        Haptics.success()
        if !hasChosenAppFocus {
            appFocus = .minigolf
            hasChosenAppFocus = true
            hasSeenOnboarding = true
        }
        scannedMinigolfCourse = course
    }

    private func openScanned(golf entry: BundledCourseEntry) {
        Haptics.success()
        if !hasChosenAppFocus {
            appFocus = .golf
            hasChosenAppFocus = true
            hasSeenOnboarding = true
        }
        scannedGolfCourse = storedCourse(for: entry)
    }

    /// Der Platz aus dem Verzeichnis als Eintrag in der eigenen Datenbank.
    ///
    /// Wiedererkannt wird über den Namen – sonst entstünde bei jedem Scan ein
    /// zweiter Eintrag, und die Runden desselben Platzes lägen verstreut.
    @MainActor
    private func storedCourse(for entry: BundledCourseEntry) -> Course {
        let name = entry.name.lowercased()
        if let vorhanden = (try? modelContext.fetch(FetchDescriptor<Course>()))?
            .first(where: { $0.name.lowercased() == name }) {
            return vorhanden
        }

        let course = Course(
            name: entry.name,
            location: entry.location,
            numberOfHoles: entry.holes,
            parValues: entry.parValues.isEmpty ? nil : entry.parValues,
            courseRating: entry.courseRating,
            slopeRating: entry.slopeRating,
            hcpValues: entry.hcpValues,
            holeLengths: entry.holeLengths,
            facilityNotes: entry.facilityNotes,
            latitude: entry.lat,
            longitude: entry.lon,
            teeLatitudes: entry.teeLatitudes,
            teeLongitudes: entry.teeLongitudes,
            flagLatitudes: entry.flagLatitudes,
            flagLongitudes: entry.flagLongitudes
        )
        modelContext.insert(course)
        return course
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
