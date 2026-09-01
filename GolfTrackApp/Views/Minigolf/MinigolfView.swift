import SwiftUI
import CoreLocation
import MapKit

// MARK: - Setup

enum MinigolfTab { case spiel, tools }

struct MinigolfView: View {
    /// Wird die View modal präsentiert (z.B. von der Startseite), braucht sie
    /// einen eigenen Schließen-Button – beim Push in einen NavigationStack nicht.
    var showsCloseButton: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var rawNames: [String] = ["", ""]
    @State private var numberOfHoles: Int = 9
    @State private var selectedChallenges: [MinigolfChallenge] = []
    @State private var activeConfig: MinigolfConfig?
    @State private var tracker = DistanceTracker()
    @State private var activeTab: MinigolfTab = .spiel
    @State private var savedGame: SavedMinigolfGame?
    @State private var history: [MinigolfHistoryEntry] = []
    @State private var selectedHistoryEntry: MinigolfHistoryEntry?
    /// Anlage, deren Start-Flow gerade gezeigt wird (Liste oder QR-Scan)
    @State private var startingCourse: MinigolfCourseEntry?
    @ObservedObject private var wc = WatchConnectivityManager.shared
    /// Anlagen von golftrack.app zusätzlich zu den eingebauten
    private let catalog = CourseCatalogService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("", selection: $activeTab.animation(.easeInOut(duration: 0.2))) {
                    Label("Spiel", systemImage: "figure.golf").tag(MinigolfTab.spiel)
                    Label("Distanz & Karte", systemImage: "location.viewfinder").tag(MinigolfTab.tools)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(AppTheme.bg)

                Divider()

                ScrollView {
                    VStack(spacing: 14) {
                        if activeTab == .spiel {
                            if savedGame != nil {
                                resumeCard
                            }
                            coursesCard
                            holesCard
                            playersCard
                            MinigolfChallengeSetupCard(selection: $selectedChallenges,
                                                       initiallyExpanded: false)

                            Button { startGame() } label: {
                                Text("Spiel starten")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)

                            if !history.isEmpty {
                                historyCard
                            }
                        } else {
                            DistanceTrackerCard(tracker: tracker)
                            DistanceMapCard(tracker: tracker)
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.2), value: activeTab)
                }
            }
            .appBackground()
            .navigationTitle("Minigolf & Putten")
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Fertig") { dismiss() }
                            .foregroundStyle(AppTheme.gold)
                    }
                }
            }
            .navigationDestination(item: $activeConfig) { config in
                MinigolfScoringView(config: config)
            }
            .onAppear {
                if let names = MinigolfGameStore.loadNames(), !names.isEmpty, rawNames == ["", ""] {
                    rawNames = names
                }
                savedGame = MinigolfGameStore.load()
                history = MinigolfGameStore.loadHistory()
                if selectedChallenges.isEmpty {
                    selectedChallenges = MinigolfGameStore.loadChallenges()
                }
            }
            .task {
                await catalog.refreshIfNeeded()
                // Anzeigen schon hier holen, nicht erst in der Zählkarte: auf
                // der Anlage selbst ist oft kein Netz mehr.
                await AdCatalogService.shared.refreshIfNeeded()
            }
            .onChange(of: activeConfig) { _, newValue in
                // Returning from a running game — pick up the persisted state
                if newValue == nil {
                    savedGame = MinigolfGameStore.load()
                    history = MinigolfGameStore.loadHistory()
                }
            }
            // Watch hat ein Minigolf-Spiel gestartet → auf dem iPhone öffnen
            .onChange(of: wc.minigolfState) { _, newValue in
                guard activeConfig == nil,
                      let s = newValue, s.active,
                      !s.players.isEmpty else { return }
                activeConfig = MinigolfConfig(
                    playerNames: s.players,
                    numberOfHoles: s.holes,
                    initialScores: s.scores,
                    initialHole: s.currentHole,
                    challenges: selectedChallenges
                )
            }
            .fullScreenCover(item: $startingCourse, onDismiss: reloadStoredGames) { course in
                MinigolfCourseStartView(course: course)
                    .preferredColorScheme(.dark)
            }
            .sheet(item: $selectedHistoryEntry) { entry in
                MinigolfResultsView(
                    playerNames: entry.playerNames,
                    numberOfHoles: entry.numberOfHoles,
                    scores: entry.scores,
                    challenges: entry.challenges ?? []
                )
            }
        }
    }

    // MARK: Anlagen (QR-Code-Start)

    /// Minigolfanlagen, für die es einen QR-Code am Eingang gibt. Der Tipp auf
    /// die Zeile führt in denselben Ablauf wie der Scan. Die Codes zum
    /// Aushängen gibt es auf golftrack.app, nicht in der App.
    private var coursesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Minigolfplätze", systemImage: "mappin.and.ellipse")
                .font(.headline)

            Text("Vor Ort einfach den QR-Code scannen – Begrüßung, kurze Einführung, los.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(catalog.allMinigolfCourses) { course in
                    Button { startingCourse = course } label: {
                        courseRow(course)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func courseRow(_ course: MinigolfCourseEntry) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(course.name)
                    .font(.subheadline.bold())
                Text("\(course.location) · \(course.holes) Bahnen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
    }

    /// Nach einem Start über die Anlagen-Liste den gespeicherten Stand neu laden.
    private func reloadStoredGames() {
        savedGame = MinigolfGameStore.load()
        history = MinigolfGameStore.loadHistory()
    }

    // MARK: History card

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Verlauf", systemImage: "trophy.fill")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        MinigolfGameStore.saveHistory([])
                        history = []
                    }
                } label: {
                    Text("Alle löschen")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 8) {
                ForEach(history) { entry in
                    Button { selectedHistoryEntry = entry } label: {
                        historyRow(entry)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.3)) {
                                history.removeAll { $0.id == entry.id }
                                MinigolfGameStore.saveHistory(history)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func historyRow(_ entry: MinigolfHistoryEntry) -> some View {
        let totals = entry.scores.map { $0.reduce(0, +) }
        let winnerIndex = totals.indices.min(by: { totals[$0] < totals[$1] }) ?? 0
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("🥇 \(entry.playerNames[winnerIndex]) · \(totals[winnerIndex]) Schläge")
                    .font(.subheadline.bold())
                Text("\(entry.playerNames.joined(separator: ", ")) · \(entry.numberOfHoles) Löcher")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let courseName = entry.courseName {
                    Label(courseName, systemImage: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(entry.date.formatted(date: .abbreviated, time: .shortened) + " Uhr")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Resume card

    private var resumeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Angefangenes Spiel", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            if let game = savedGame {
                Text("\(game.playerNames.joined(separator: ", ")) · Loch \(game.currentHole + 1) von \(game.numberOfHoles)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let savedAt = game.savedAt {
                    Label(savedAt.formatted(date: .abbreviated, time: .shortened) + " Uhr", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    Button {
                        activeConfig = MinigolfConfig(
                            playerNames: game.playerNames,
                            numberOfHoles: game.numberOfHoles,
                            initialScores: game.scores,
                            initialHole: game.currentHole,
                            courseName: game.courseName,
                            courseID: game.courseID,
                            challenges: game.challenges ?? []
                        )
                    } label: {
                        Label("Fortsetzen", systemImage: "play.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Button {
                        MinigolfGameStore.clear()
                        withAnimation(.spring(response: 0.3)) { savedGame = nil }
                    } label: {
                        Label("Verwerfen", systemImage: "trash")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Holes card

    private var holesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Löcher", systemImage: "flag.fill")
                .font(.headline)

            // Quick-pick row
            HStack(spacing: 8) {
                ForEach([6, 9, 12, 18], id: \.self) { n in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            numberOfHoles = n
                        }
                    } label: {
                        Text("\(n)")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                numberOfHoles == n ? AppTheme.gold : Color.secondary.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .foregroundStyle(numberOfHoles == n ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom stepper
            HStack {
                Text("Benutzerdefiniert")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 0) {
                    Button {
                        if numberOfHoles > 1 {
                            withAnimation(.spring(response: 0.25)) { numberOfHoles -= 1 }
                        }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 38, height: 38)
                            .foregroundStyle(numberOfHoles > 1 ? .primary : Color.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)

                    Text("\(numberOfHoles)")
                        .font(.headline.monospacedDigit())
                        .frame(width: 38, alignment: .center)

                    Button {
                        if numberOfHoles < 36 {
                            withAnimation(.spring(response: 0.25)) { numberOfHoles += 1 }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 38, height: 38)
                            .foregroundStyle(numberOfHoles < 36 ? .primary : Color.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Players card

    private var playersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Spieler", systemImage: "person.2.fill")
                    .font(.headline)
                Spacer()
                Text("\(rawNames.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(AppTheme.gold, in: Circle())
            }

            VStack(spacing: 8) {
                ForEach(Array(rawNames.indices), id: \.self) { i in
                    HStack(spacing: 10) {
                        Text("\(i + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(AppTheme.gold.opacity(0.75), in: Circle())
                        TextField("Spieler \(i + 1)", text: $rawNames[i])
                            .font(.body)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
                }
            }

            HStack(spacing: 10) {
                if rawNames.count < 8 {
                    Button {
                        withAnimation(.spring(response: 0.3)) { rawNames.append("") }
                    } label: {
                        Label("Hinzufügen", systemImage: "plus")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(AppTheme.gold)
                    }
                    .buttonStyle(.plain)
                }
                if rawNames.count > 1 {
                    Button {
                        withAnimation(.spring(response: 0.3)) { if !rawNames.isEmpty { rawNames.removeLast() } }
                    } label: {
                        Label("Entfernen", systemImage: "minus")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.subheadline.bold()).foregroundStyle(AppTheme.gold)
            Text(title).font(.subheadline.bold()).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private func startGame() {
        let names = rawNames.enumerated().map { i, n in
            n.trimmingCharacters(in: .whitespaces).isEmpty ? "Spieler \(i + 1)" : n
        }
        MinigolfGameStore.saveNames(rawNames)
        MinigolfGameStore.saveChallenges(selectedChallenges)
        MinigolfGameStore.clear()
        savedGame = nil
        activeConfig = MinigolfConfig(playerNames: names,
                                      numberOfHoles: numberOfHoles,
                                      challenges: selectedChallenges)
    }
}


// MARK: - Shared tracker model

@Observable
final class DistanceTracker: NSObject, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()
    var startLocation: CLLocation?
    var currentLocation: CLLocation?
    var currentDistance: Double?
    var isTracking = false
    var currentHeading: CLLocationDirection?
    var lockedHeading: CLLocationDirection?
    var savedDistances: [SavedShotDistance] = []
    private var updateTimer: Timer?

    struct SavedShotDistance: Identifiable {
        let id = UUID()
        let distance: Double
        let date = Date()
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 2
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        currentHeading = h
    }

    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        let initial = locationManager.location
        startLocation = initial
        currentLocation = initial
        currentDistance = initial != nil ? 0 : nil
        isTracking = true

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let loc = self.locationManager.location
            if self.startLocation == nil { self.startLocation = loc }
            self.currentLocation = loc
            if let start = self.startLocation, let cur = loc {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.currentDistance = cur.distance(from: start)
                }
            }
        }
    }

    func setNewStart() {
        startLocation = locationManager.location
        currentDistance = 0
        lockedHeading = nil
    }

    func stop() {
        updateTimer?.invalidate()
        updateTimer = nil
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isTracking = false
        startLocation = nil
        currentLocation = nil
        currentDistance = nil
        currentHeading = nil
        lockedHeading = nil
    }

    func lockHeading() { lockedHeading = currentHeading }
    func clearLockedHeading() { lockedHeading = nil }

    func saveDistance() {
        guard let d = currentDistance, d > 0.5 else { return }
        savedDistances.append(SavedShotDistance(distance: d))
    }

    func removeSavedDistance(at offsets: IndexSet) {
        savedDistances.remove(atOffsets: offsets)
    }

    static func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 { return String(format: "%.2f km", meters / 1000) }
        if meters >= 100  { return String(format: "%.0f m", meters) }
        return String(format: "%.1f m", meters)
    }

    // Point at `distanceMeters` from `coord` in `bearing` degrees
    static func destination(from coord: CLLocationCoordinate2D,
                            bearing: CLLocationDirection,
                            distanceMeters: Double) -> CLLocationCoordinate2D {
        let R = 6371000.0
        let δ = distanceMeters / R
        let θ = bearing * .pi / 180
        let φ1 = coord.latitude  * .pi / 180
        let λ1 = coord.longitude * .pi / 180
        let φ2 = asin(sin(φ1)*cos(δ) + cos(φ1)*sin(δ)*cos(θ))
        let λ2 = λ1 + atan2(sin(θ)*sin(δ)*cos(φ1), cos(δ) - sin(φ1)*sin(φ2))
        return CLLocationCoordinate2D(latitude: φ2 * 180 / .pi, longitude: λ2 * 180 / .pi)
    }

    static func compassPoint(_ deg: CLLocationDirection) -> String {
        let d = ((deg.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        switch d {
        case 0..<22.5, 337.5...360: return "N"
        case 22.5..<67.5:   return "NO"
        case 67.5..<112.5:  return "O"
        case 112.5..<157.5: return "SO"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SW"
        case 247.5..<292.5: return "W"
        default:            return "NW"
        }
    }
}

// MARK: - Distance Tracker Card

struct DistanceTrackerCard: View {
    let tracker: DistanceTracker

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "location.viewfinder")
                    .font(.title3)
                    .foregroundStyle(.blue)
                Text("Distanz messen").font(.headline)
                Spacer()
                if tracker.isTracking {
                    HStack(spacing: 4) {
                        Circle().fill(AppTheme.gold).frame(width: 7, height: 7)
                        Text("Live").font(.caption2.bold()).foregroundStyle(AppTheme.gold)
                    }
                }
            }

            Group {
                if let d = tracker.currentDistance {
                    Text(DistanceTracker.formatDistance(d))
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: tracker.currentDistance)
                } else if tracker.isTracking {
                    Text("Warte auf GPS…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("— m")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 10) {
                if tracker.isTracking {
                    Button { tracker.setNewStart() } label: {
                        Label("Neu setzen", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)

                    Button { tracker.stop() } label: {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button { tracker.start() } label: {
                        Label("Startpunkt setzen", systemImage: "location.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.blue, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Save button — visible only when tracking and distance > 0.5 m
            if tracker.isTracking && (tracker.currentDistance ?? 0) > 0.5 {
                Button { tracker.saveDistance() } label: {
                    Label("Distanz speichern", systemImage: "bookmark.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.gold.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(AppTheme.gold)
                }
                .buttonStyle(.plain)
            }

            // Saved distances list
            if !tracker.savedDistances.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Gespeicherte Distanzen")
                            .font(.subheadline.bold())
                        Text("\(tracker.savedDistances.count)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(AppTheme.gold, in: Circle())
                        Spacer()
                        Button {
                            withAnimation { tracker.savedDistances.removeAll() }
                        } label: {
                            Text("Alle löschen")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(Array(tracker.savedDistances.enumerated()), id: \.element.id) { index, shot in
                        HStack {
                            Text("Schlag \(index + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(DistanceTracker.formatDistance(shot.distance))
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.gold)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let idx = tracker.savedDistances.firstIndex(where: { $0.id == shot.id }) {
                                    tracker.removeSavedDistance(at: IndexSet(integer: idx))
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Distance Map Card

struct DistanceMapCard: View {
    let tracker: DistanceTracker
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isSatellite = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.gold)
                Text("Karte").font(.headline)
                Spacer()
                if tracker.isTracking, let d = tracker.currentDistance {
                    Text(DistanceTracker.formatDistance(d))
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .monospacedDigit()
                }
            }

            // Compass banner — shown when tracking
            if tracker.isTracking {
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Text("🧭")
                            .font(.body)
                        if let heading = tracker.currentHeading {
                            Text(String(format: "%.0f°", heading) + " " + DistanceTracker.compassPoint(heading))
                                .font(.subheadline.bold())
                                .monospacedDigit()
                                .foregroundStyle(tracker.lockedHeading != nil ? .orange : .blue)
                        } else {
                            Text("—")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if tracker.lockedHeading == nil {
                        Button { tracker.lockHeading() } label: {
                            Label("Richtungslinie setzen", systemImage: "arrow.up.forward")
                                .font(.caption.bold())
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.orange, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 6) {
                            if let locked = tracker.lockedHeading {
                                Text(String(format: "%.0f°", locked) + " " + DistanceTracker.compassPoint(locked))
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)
                                    .monospacedDigit()
                            }
                            Button { tracker.clearLockedHeading() } label: {
                                Label("Linie entfernen", systemImage: "xmark")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(Color.secondary.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    tracker.lockedHeading != nil
                        ? Color.orange.opacity(0.08)
                        : Color.blue.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            }

            Map(position: $position) {
                UserAnnotation()

                if let start = tracker.startLocation {
                    Annotation("Start", coordinate: start.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.blue.opacity(0.25))
                                .frame(width: 28, height: 28)
                            Circle()
                                .fill(.blue)
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }
                    .annotationTitles(.hidden)
                }

                if let start = tracker.startLocation,
                   let current = tracker.currentLocation,
                   tracker.isTracking {
                    MapPolyline(coordinates: [start.coordinate, current.coordinate])
                        .stroke(.blue.opacity(0.7), style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
                }

                // Direction line when heading is locked
                if let start = tracker.startLocation,
                   let heading = tracker.lockedHeading,
                   tracker.isTracking {
                    let endCoord = DistanceTracker.destination(from: start.coordinate, bearing: heading, distanceMeters: 250)
                    MapPolyline(coordinates: [start.coordinate, endCoord])
                        .stroke(.orange, style: StrokeStyle(lineWidth: 3, dash: [8, 5]))
                    Annotation("", coordinate: endCoord) {
                        Image(systemName: "chevron.forward.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .background(Circle().fill(.white).frame(width: 22, height: 22))
                    }
                }
            }
            .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard)
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topLeading) {
                Button {
                    withAnimation { isSatellite.toggle() }
                } label: {
                    Image(systemName: isSatellite ? "map" : "globe.europe.africa.fill")
                        .font(.callout.bold())
                        .padding(8)
                        .background(.regularMaterial, in: Capsule())
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .padding(10)
            }
            .overlay(alignment: .bottomTrailing) {
                if !tracker.isTracking {
                    Button { tracker.start() } label: {
                        Label("Start", systemImage: "location.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.blue, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

