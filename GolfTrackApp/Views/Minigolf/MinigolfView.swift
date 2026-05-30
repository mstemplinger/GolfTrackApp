import SwiftUI
import CoreLocation
import MapKit

// MARK: - Config

struct MinigolfConfig: Identifiable, Hashable {
    let id = UUID()
    let playerNames: [String]
    let numberOfHoles: Int
}

// MARK: - Setup

enum MinigolfTab { case spiel, tools }

struct MinigolfView: View {
    @State private var rawNames: [String] = ["", ""]
    @State private var numberOfHoles: Int = 9
    @State private var activeConfig: MinigolfConfig?
    @State private var tracker = DistanceTracker()
    @State private var activeTab: MinigolfTab = .spiel

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
                            holesCard
                            playersCard

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
                        } else {
                            DistanceTrackerCard(tracker: tracker)
                            DistanceMapCard(tracker: tracker)
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.2), value: activeTab)
                }
            }
            .navigationTitle("Minigolf & Putten")
            .navigationDestination(item: $activeConfig) { config in
                MinigolfScoringView(config: config)
            }
        }
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
        activeConfig = MinigolfConfig(playerNames: names, numberOfHoles: numberOfHoles)
    }
}

// MARK: - Scoring

struct MinigolfScoringView: View {
    let config: MinigolfConfig
    @State private var scores: [[Int]]
    @State private var currentHole = 0
    @State private var showResults = false

    init(config: MinigolfConfig) {
        self.config = config
        _scores = State(initialValue:
            Array(repeating: Array(repeating: 1, count: config.numberOfHoles),
                  count: config.playerNames.count)
        )
    }

    private var playerCount: Int { config.playerNames.count }
    private var holeCount: Int { config.numberOfHoles }

    private func total(for player: Int) -> Int {
        scores[player].reduce(0, +)
    }

    private var sortedPlayerIndices: [Int] {
        (0..<playerCount).sorted { total(for: $0) < total(for: $1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(0..<playerCount, id: \.self) { i in
                        playerCard(for: i)
                    }
                }
                .padding()
            }
            bottomNav
        }
        .navigationTitle("Loch \(currentHole + 1) / \(holeCount)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ergebnis") { showResults = true }
                    .foregroundStyle(AppTheme.gold)
            }
        }
        .sheet(isPresented: $showResults) {
            MinigolfResultsView(
                playerNames: config.playerNames,
                numberOfHoles: holeCount,
                scores: scores
            )
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(.secondary.opacity(0.15))
                Rectangle()
                    .fill(AppTheme.gold)
                    .frame(width: geo.size.width * CGFloat(currentHole + 1) / CGFloat(holeCount))
                    .animation(.easeInOut(duration: 0.25), value: currentHole)
            }
        }
        .frame(height: 3)
    }

    private func playerCard(for i: Int) -> some View {
        let rank = sortedPlayerIndices.firstIndex(of: i) ?? i
        return HStack(spacing: 12) {
            Text("\(rank + 1)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(rankColor(rank), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(config.playerNames[i]).font(.headline)
                Text("Gesamt: \(total(for: i))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            HStack(spacing: 4) {
                Button {
                    if scores[i][currentHole] > 1 { scores[i][currentHole] -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(scores[i][currentHole] > 1 ? AppTheme.gold : Color.secondary.opacity(0.35))
                }
                .buttonStyle(.plain)

                Text("\(scores[i][currentHole])")
                    .font(.title.bold())
                    .monospacedDigit()
                    .frame(width: 40, alignment: .center)

                Button {
                    if scores[i][currentHole] < 20 { scores[i][currentHole] += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(AppTheme.gold)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 0: return Color(red: 0.85, green: 0.65, blue: 0.1)
        case 1: return .gray
        case 2: return Color(red: 0.72, green: 0.45, blue: 0.2)
        default: return .secondary
        }
    }

    private var bottomNav: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { currentHole -= 1 }
            } label: {
                Label("Zurück", systemImage: "chevron.left")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(currentHole == 0)
            .opacity(currentHole == 0 ? 0.3 : 1)
            .buttonStyle(.plain)

            if currentHole < holeCount - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { currentHole += 1 }
                } label: {
                    HStack(spacing: 6) {
                        Text("Weiter")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            } else {
                Button { showResults = true } label: {
                    Text("Ergebnis")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(AppTheme.bg)
    }
}

// MARK: - Results

struct MinigolfResultsView: View {
    let playerNames: [String]
    let numberOfHoles: Int
    let scores: [[Int]]
    @Environment(\.dismiss) private var dismiss

    private func total(for player: Int) -> Int {
        scores[player].reduce(0, +)
    }

    private var ranked: [(index: Int, name: String, total: Int)] {
        (0..<playerNames.count)
            .map { i in (i, playerNames[i], total(for: i)) }
            .sorted { $0.total < $1.total }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    rankingList
                    scorecardTable
                }
                .padding()
            }
            .navigationTitle("Ergebnis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private var rankingList: some View {
        VStack(spacing: 0) {
            ForEach(Array(ranked.enumerated()), id: \.offset) { place, entry in
                HStack(spacing: 12) {
                    Text(medal(for: place))
                        .font(place < 3 ? .title2 : .body)
                        .frame(width: 36)
                    Text(entry.name).font(.headline)
                    Spacer()
                    Text("\(entry.total)")
                        .font(.headline.bold())
                        .monospacedDigit()
                        .foregroundStyle(place == 0 ? Color(red: 0.85, green: 0.65, blue: 0.1) : .primary)
                    Text("Schl.").font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                if place < ranked.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func medal(for place: Int) -> String {
        switch place {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(place + 1)."
        }
    }

    private var scorecardTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scorecard").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Spieler")
                            .frame(width: 80, alignment: .leading)
                            .font(.caption.bold())
                        ForEach(0..<numberOfHoles, id: \.self) { h in
                            Text("\(h + 1)")
                                .frame(width: 28)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("∑")
                            .frame(width: 36, alignment: .trailing)
                            .font(.caption.bold())
                    }
                    .frame(height: 26)

                    Divider()

                    ForEach(Array(ranked.enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: 0) {
                            Text(entry.name)
                                .frame(width: 80, alignment: .leading)
                                .font(.caption)
                                .lineLimit(1)
                            ForEach(0..<numberOfHoles, id: \.self) { h in
                                let s = scores[entry.index][h]
                                Text("\(s)")
                                    .frame(width: 28)
                                    .font(.caption)
                                    .foregroundStyle(s == 1 ? AppTheme.gold : .primary)
                            }
                            Text("\(entry.total)")
                                .frame(width: 36, alignment: .trailing)
                                .font(.caption.bold())
                        }
                        .frame(height: 28)
                    }
                }
                .padding(12)
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
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
