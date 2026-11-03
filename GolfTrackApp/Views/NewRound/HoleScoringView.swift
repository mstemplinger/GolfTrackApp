import SwiftUI
import SwiftData
import CoreLocation

struct HoleScoringView: View {
    @Bindable var score: HoleScore
    @Bindable var round: Round
    let par: Int
    let holeCount: Int
    let gameMode: GameMode
    let onPrevious: () -> Void
    let onNext: () -> Void
    /// Sprung auf ein bestimmtes Loch (1-basiert) über die Lochleiste.
    var onSelectHole: (Int) -> Void = { _ in }

    @Query(sort: \GolfClub.order) private var allClubs: [GolfClub]

    private var clubs: [GolfClub] {
        if let bag = round.bag { return bag.sortedClubs }
        return allClubs
    }
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters
    @Environment(\.modelContext) private var context
    @State private var locationManager = CLLocationManager()
    @State private var userLocation: CLLocation?
    @State private var showShotTracker = false
    @State private var showPinSetter = false
    @State private var showHoleOverview = false
    @State private var showRoundOverview = false
    @State private var showClubPicker = false
    @State private var pendingGPSLocation: CLLocation?
    @State private var pendingShotNumber: Int = 0
    @State private var showTeeHint = false
    @State private var showNoGPSAlert = false
    @AppStorage("hint.teeSetter.shown") private var teeHintShown = false
    @AppStorage(RoundTrackingService.enabledKey) private var trackingEnabled = false
    /// Mitspieler, dessen Schlagkarte (Karte mit GPS-Schlägen) gerade offen ist.
    @State private var shotTrackerPlayer: PlayerHoleScore?

    // MARK: - Mitspieler

    /// Spielformen mit gemeinsamem Ball – dort gibt es nur einen Team-Score.
    private var playsOwnBall: Bool {
        switch gameMode {
        case .scramble2Mann, .scrambleTeam, .vierer, .greensome, .scrambleMatchplay: return false
        default: return true
        }
    }

    /// Jeder Mitspieler bekommt eine eigene Scorekarte, sobald er seinen eigenen Ball spielt.
    private var showsPartnerCards: Bool {
        gameMode.isMultiplayer && playsOwnBall && !opponentScores.isEmpty
    }

    private func displayName(_ opp: PlayerHoleScore) -> String {
        opp.playerName.isEmpty ? String(localized: "Spieler \(opp.playerIndex + 1)") : opp.playerName
    }

    private var diff: Int { score.strokes - par }

    /// True, sobald für dieses Loch mindestens ein Schlag eingetragen ist.
    /// Ohne diese Prüfung rechnet `diff` mit 0 Schlägen: auf einem Par 4 ergibt
    /// das −4, und das Badge zeigte „Albatross" auf einem Loch, das noch nicht
    /// gespielt ist. Dasselbe gilt für die Stableford-Punkte, die bei 0 Schlägen
    /// auf 6 kamen.
    private var hasScore: Bool { score.strokes > 0 }

    private var scoreToParColor: Color {
        guard let s = round.scoreToPar else { return AppTheme.text }
        if s < 0 { return AppTheme.gold }
        if s == 0 { return AppTheme.text }
        return s <= 2 ? .orange : .red
    }

    /// Der Platz im Verzeichnis – über den Namen gesucht, weil das
    /// `Course`-Modell keine Kennung der Website trägt.
    private var catalogEntry: BundledCourseEntry? {
        guard let name = round.course?.name.lowercased() else { return nil }
        return CourseCatalogService.shared.allGolfCourses
            .first { $0.name.lowercased() == name }
    }

    /// Leer, solange der Platz nicht im Verzeichnis steht – dann zeigt die
    /// Karte nichts an, statt eine leere Fläche zu hinterlassen.
    private var courseHints: [CourseHint] { catalogEntry?.hints ?? [] }

    /// Für Umkreis-Werbung: erst die Kennung des Verzeichnisses, sonst nichts.
    private var courseSlug: String? {
        let slug = catalogEntry?.slug ?? ""
        return slug.isEmpty ? nil : slug
    }

    private var courseCoordinate: CLLocationCoordinate2D? {
        guard let course = round.course,
              let lat = course.latitude, let lon = course.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private var opponentScores: [PlayerHoleScore] {
        round.playerHoleScores
            .filter { $0.holeNumber == score.holeNumber }
            .sorted { $0.playerIndex < $1.playerIndex }
    }

    var body: some View {
        VStack(spacing: 12) {
            holeHeader
            pinDistanceCard
            clubRecommendationCard
            if showsPartnerCards {
                playerNameLabel(String(localized: "Du"))
            }
            strokeCounterCard
            secondaryStatsCard(score)

            if showsPartnerCards {
                ForEach(opponentScores, id: \.playerIndex) { opp in
                    partnerCard(opp)
                }
            }

            if gameMode.isMultiplayer && !opponentScores.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                        .background(AppTheme.cardAlt)
                        .padding(.horizontal)
                    switch gameMode {
                    case .scramble2Mann:
                        scrambleNote.padding(.top, 12)
                    case .scrambleTeam:
                        scrambleTeamNote.padding(.top, 12)
                    case .vierer:
                        viererNote.padding(.top, 12)
                    case .greensome:
                        greensomeNote.padding(.top, 12)
                    default:
                        opponentSection.padding(.top, 12)
                    }
                }
            }

            holeStrip
            scoreGesamtBar
            shotTrackerButton

            // Hinweise der Anlage – immer, auch mit Abo. Sie sind keine
            // Werbung, sondern das, was der Betreiber seinen Gästen sagt.
            CourseHintRotatingCard(hints: courseHints, rotation: score.holeNumber)

            // Werbung dagegen entfällt mit Abo; das entscheidet AdSlotView.
            AdSlotView(placement: .golfScoring,
                       courseID: courseSlug,
                       coordinate: courseCoordinate,
                       rotation: score.holeNumber)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .sheet(isPresented: $showShotTracker) {
            ShotTrackerView(holeScore: score)
        }
        .sheet(item: $shotTrackerPlayer) { opp in
            ShotTrackerView(holeScore: opp, playerName: displayName(opp), recordsClubDistances: false)
        }
        .sheet(isPresented: $showPinSetter) {
            PinSetterView(pinLatitude: $score.pinLatitude,
                          pinLongitude: $score.pinLongitude,
                          onManualSave: { score.pinIsAutomatic = false })
        }
        .sheet(isPresented: $showHoleOverview) {
            HoleTrackingOverviewSheet(round: round, score: score, par: par)
        }
        .sheet(isPresented: $showRoundOverview) {
            RoundTrackingOverviewSheet(round: round, currentHole: score.holeNumber)
        }
        .sheet(isPresented: $showClubPicker) {
            ClubPickerSheet(
                clubs: clubs,
                recommendedClub: pendingRecommendedClub,
                strokeNumber: pendingShotNumber,
                gpsLocation: pendingGPSLocation,
                holeScore: score,
                onPutterSelected: { score.putts += 1 },
                onHideForRound: {
                    withAnimation(.snappy) { round.hidesClubPicker = true }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if clubs.isEmpty { seedDefaultClubs() }
            updateWidget()
            prefillPinFromCourse()
        }
        .onChange(of: score.strokes) { _, _ in updateWidget() }
        .onChange(of: score.holeNumber) { _, _ in
            updateWidget()
            prefillPinFromCourse()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openShotTracker)) { _ in
            showShotTracker = true
        }
        .alert("So funktioniert's", isPresented: $showTeeHint) {
            Button("Abschlag setzen") {
                teeHintShown = true
                setTee()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Stell dich auf den Abschlag und tippe auf „Abschlag setzen“. Deine Position wird als Abschlag dieses Lochs gespeichert.\n\nDanach zählst du wie gewohnt mit Plus: Jeder Tipp nimmt deinen aktuellen Standort als Lage des nächsten Schlags. Beim nächsten Mal kennt die App den Abschlag schon.")
            + Text(trackingEnabled
                   ? "\n\nDas Positions-Tracking zeichnet dazwischen weiter deine Laufspur auf."
                   : "\n\nMit eingeschaltetem Positions-Tracking lernt die App Abschläge und Grüns zusätzlich aus deiner Laufspur.")
        }
        .alert("Kein GPS-Signal", isPresented: $showNoGPSAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Warte kurz, bis dein Standort gefunden ist, und versuch es dann noch einmal.")
        }
        .task {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            while !Task.isCancelled {
                userLocation = locationManager.location
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    // MARK: - Default club seeding

    private func updateWidget() {
        GolfLiveActivityManager.update(
            holeNumber: score.holeNumber,
            totalHoles: holeCount,
            strokes: score.strokes,
            par: par,
            courseName: round.course?.name ?? "GolfTrack"
        )
    }

    private func seedDefaultClubs() {
        let defaults: [(String, Int, Int, Bool)] = [
            ("Driver", 220, 0, false),  ("3 Wood", 195, 1, false),  ("5 Wood", 180, 2, false),
            ("3 Eisen", 185, 3, false), ("4 Eisen", 175, 4, false), ("5 Eisen", 165, 5, false),
            ("6 Eisen", 155, 6, false), ("7 Eisen", 145, 7, false), ("8 Eisen", 130, 8, false),
            ("9 Eisen", 120, 9, false), ("PW", 110, 10, false),     ("GW", 95, 11, false),
            ("SW", 80, 12, false),      ("LW", 60, 13, false),      ("Putter", 10, 14, true),
        ]
        let bag = round.bag ?? {
            let b = GolfBag(name: "Standard")
            context.insert(b)
            round.bag = b
            return b
        }()
        for (name, dist, order, isPutter) in defaults {
            let club = GolfClub(name: name, averageDistance: dist, order: order, isPutter: isPutter)
            club.bag = bag
            context.insert(club)
            bag.clubs.append(club)
        }
    }

    // MARK: - Pin Prefill

    /// Übernimmt die für den Platz hinterlegte (ggf. abgeleitete) Fahnenposition,
    /// solange der Nutzer für dieses Loch keinen eigenen Pin gesetzt hat.
    private func prefillPinFromCourse() {
        guard !score.hasPinLocation || score.pinIsAutomatic,
              let coord = round.course?.flagCoordinate(forHole: score.holeNumber) else { return }
        score.pinLatitude = coord.latitude
        score.pinLongitude = coord.longitude
        score.pinIsAutomatic = true
    }

    // MARK: - Pin Distance Helpers

    private var distanceToPin: Double? {
        guard let lat = score.pinLatitude, let lon = score.pinLongitude,
              let loc = userLocation else { return nil }
        return CLLocation(latitude: lat, longitude: lon).distance(from: loc)
    }

    /// Mehr als 2 km zur Fahne: niemand steht auf diesem Loch – dann weder
    /// Distanz noch Schlägerempfehlung, sondern ein Hinweis.
    private var isAwayFromCourse: Bool { (distanceToPin ?? 0) > 2000 }

    /// Empfehlung für den Schlag, der gerade gezählt wurde – aus der Position beim Tippen.
    private var pendingRecommendedClub: GolfClub? {
        guard let lat = score.pinLatitude, let lon = score.pinLongitude,
              let loc = pendingGPSLocation else { return nil }
        return recommendedClub(for: CLLocation(latitude: lat, longitude: lon).distance(from: loc))
    }

    private func recommendedClub(for distanceMeters: Double) -> GolfClub? {
        guard !clubs.isEmpty else { return nil }
        return clubs.min(by: {
            abs($0.averageDistance - Int(distanceMeters)) < abs($1.averageDistance - Int(distanceMeters))
        })
    }

    // MARK: - Pin Distance Card

    private let darkText = Color(red: 0.06, green: 0.14, blue: 0.08)

    @ViewBuilder
    private var pinDistanceCard: some View {
        if score.hasPinLocation {
            HStack(spacing: 10) {
                // Tippen öffnet die Loch-Übersicht mit allem, was das Tracking weiß.
                Button {
                    Haptics.tap()
                    showHoleOverview = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.gold)
                        if isAwayFromCourse {
                            Text("Du bist nicht am Platz")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSec)
                        } else if let dist = distanceToPin {
                            Text("Noch \(distanceUnit.format(dist)) zum Loch")
                                .font(.headline)
                                .foregroundStyle(AppTheme.text)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: distanceUnit.value(dist))
                        } else {
                            Text("Standort wird ermittelt …")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSec)
                        }
                        Spacer(minLength: 0)
                        if distanceToPin != nil && !isAwayFromCourse {
                            Text("LIVE")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(darkText)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(AppTheme.gold, in: Capsule())
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Pin neu setzen – klein, weil er meist automatisch stimmt.
                Button {
                    Haptics.tap()
                    showPinSetter = true
                } label: {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textSec)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.cardAlt, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pin aktualisieren")
            }
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .padding(.vertical, 10)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
        } else {
            // Pin not set — compact tappable row
            Button {
                Haptics.tap()
                showPinSetter = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.gold)
                    Text("Lochposition festlegen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTer)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Schläger-Empfehlung

    /// Empfehlung plus die beiden Nachbarn in der Distanz – kürzer und länger.
    private var clubSuggestion: (club: GolfClub, neighbours: [GolfClub])? {
        guard !isAwayFromCourse, let dist = distanceToPin,
              let club = recommendedClub(for: dist) else { return nil }
        let candidates = clubs.filter { !$0.isPutter }.sorted { $0.averageDistance < $1.averageDistance }
        guard let i = candidates.firstIndex(where: { $0.persistentModelID == club.persistentModelID }) else {
            return (club, [])
        }
        let neighbours = [i - 1, i + 1].compactMap { candidates[safe: $0] }
        return (club, neighbours)
    }

    @ViewBuilder
    private var clubRecommendationCard: some View {
        if let suggestion = clubSuggestion {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("EMPFOHLEN")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(AppTheme.gold)
                    Text(suggestion.club.name)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text("Ø \(distanceUnit.format(Double(suggestion.club.averageDistance)))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                Spacer(minLength: 0)
                ForEach(suggestion.neighbours) { club in
                    Text(club.name)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.text.opacity(0.8))
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .frame(height: 30)
                        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 9))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
            .transition(.opacity)
        }
    }

    // MARK: - Hole Header

    private var holeHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text(round.course?.name ?? String(localized: "Runde"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(1)
                Text("AKTUELLES LOCH")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2.0)
                    .foregroundStyle(AppTheme.textTer)
                    .padding(.top, 6)
                Text(String(format: "%02d", score.holeNumber))
                    .font(.system(size: 72, weight: .heavy))
                    .italic()
                    .foregroundStyle(AppTheme.gold)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: score.holeNumber)
                    .padding(.top, -6)
                HStack(spacing: 6) {
                    if let hcp = holeHCP {
                        headerPill { Label("HCP \(hcp)", systemImage: "arrow.up.arrow.down") }
                    }
                    if let len = holeLength {
                        headerPill {
                            HStack(spacing: 5) {
                                if let tee = round.teeColor { TeeDot(tee: tee, size: 8) }
                                else { Image(systemName: "ruler") }
                                Text(distanceUnit.format(Double(len)))
                            }
                        }
                    } else if let tee = round.teeColor {
                        headerPill {
                            HStack(spacing: 5) {
                                TeeDot(tee: tee, size: 8)
                                Text(tee.displayName)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 10) {
                HStack(spacing: 6) {
                    navButton("chevron.left", enabled: score.holeNumber > 1, action: onPrevious)
                        .accessibilityLabel("Vorheriges Loch")
                    navButton("chevron.right", enabled: score.holeNumber < holeCount, action: onNext)
                        .accessibilityLabel("Nächstes Loch")
                }
                .padding(.top, 2)

                Text("PAR \(par)")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(AppTheme.textSec)
                    .padding(.top, 8)

                // Badge und Punkte erst, wenn ein Schlag eingetragen ist —
                // sonst stünde dort eine Bewertung für ein ungespieltes Loch.
                if hasScore {
                    Text(scoreName)
                        .font(.subheadline.bold())
                        .foregroundStyle(scoreColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(scoreColor.opacity(0.15), in: Capsule())
                        .animation(.easeInOut(duration: 0.2), value: diff)

                    if gameMode == .stableford {
                        let pts = GameMode.stablefordPoints(strokes: score.strokes, par: par)
                        Text("\(pts) Pkt")
                            .font(.caption.bold())
                            .foregroundStyle(pts >= 3 ? AppTheme.gold : pts == 0 ? AppTheme.textTer : .primary)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func headerPill<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.textSec)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.cardAlt, in: Capsule())
    }

    private func navButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(enabled ? AppTheme.gold : AppTheme.textTer)
                .frame(width: 34, height: 34)
                .background(AppTheme.card, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var holeHCP: Int? {
        let i = score.holeNumber - 1
        guard let vals = round.course?.hcpValues, i < vals.count else { return nil }
        return vals[i]
    }

    /// Länge vom gespielten Abschlag, sonst vom Standardabschlag.
    private var holeLength: Int? {
        round.course?.holeLength(forHole: score.holeNumber, tee: round.teeColor)
    }

    // MARK: - Stroke Counter Card

    private var strokeCounterCard: some View {
        VStack(spacing: 6) {
            Text("SCHLÄGE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(AppTheme.textTer)

            HStack {
                Button {
                    removeStroke(from: score)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(score.strokes > 1 ? AppTheme.text : AppTheme.textTer)
                        .frame(width: 68, height: 68)
                        .background(AppTheme.cardAlt, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(score.strokes <= 1)
                .accessibilityLabel("Schlag abziehen")

                Spacer(minLength: 0)

                Text("\(score.strokes)")
                    .font(.system(size: 96, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(hasScore ? AppTheme.text : AppTheme.textTer)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: score.strokes)

                Spacer(minLength: 0)

                Button {
                    let shotNum = addStroke(to: score)
                    pendingGPSLocation = userLocation
                    pendingShotNumber = shotNum
                    if !clubs.isEmpty && !round.hidesClubPicker { showClubPicker = true }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(darkText)
                        .frame(width: 68, height: 68)
                        .background(AppTheme.gold, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Schlag hinzufügen")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 22))
        .overlay(alignment: .topTrailing) {
            if round.hidesClubPicker && !clubs.isEmpty {
                Button {
                    Haptics.selection()
                    withAnimation(.snappy) { round.hidesClubPicker = false }
                } label: {
                    Image(systemName: "figure.golf")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.gold.opacity(0.15), in: Circle())
                }
                .padding(10)
                .accessibilityLabel("Schlägerauswahl einblenden")
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Mitspieler-Karten

    private func playerNameLabel(_ name: String, role: String? = nil) -> some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.text)
            if let role {
                Text(role)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    /// Kompakte Scorekarte eines Mitspielers: Schläge mit GPS-Kette, Putts,
    /// Fairway und GIR – wie die eigene, nur kleiner, damit alle untereinander passen.
    private func partnerCard(_ opp: PlayerHoleScore) -> some View {
        let played = opp.strokes > 0
        let d = opp.strokes - par
        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(displayName(opp))
                        .font(.headline)
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                    if let role = roleLabel(for: opp) {
                        Text(role).font(.caption2).foregroundStyle(AppTheme.textSec)
                    }
                }
                if played {
                    Text(d == 0 ? "Par" : d > 0 ? "+\(d)" : "\(d)")
                        .font(.caption.bold())
                        .foregroundStyle(d < 0 ? AppTheme.gold : d > 0 ? .orange : AppTheme.text)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(AppTheme.cardAlt, in: Capsule())
                }
                Spacer(minLength: 0)

                Button {
                    removeStroke(from: opp)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(opp.strokes > 1 ? AppTheme.text : AppTheme.textTer)
                        .frame(width: 46, height: 46)
                        .background(AppTheme.cardAlt, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(opp.strokes <= 1)
                .accessibilityLabel(Text("Schlag abziehen") + Text(verbatim: " – \(displayName(opp))"))

                Text("\(opp.strokes)")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(played ? AppTheme.text : AppTheme.textTer)
                    .frame(minWidth: 44)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: opp.strokes)

                Button {
                    addStroke(to: opp)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(darkText)
                        .frame(width: 46, height: 46)
                        .background(AppTheme.gold, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Schlag hinzufügen") + Text(verbatim: " – \(displayName(opp))"))
            }

            secondaryStatsCard(opp)

            Button {
                Haptics.tap()
                shotTrackerPlayer = opp
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(opp.shots.isEmpty
                         ? String(localized: "Schläge auf der Karte")
                         : "\(opp.shots.count) \(opp.shots.count == 1 ? String(localized: "Schlag") : String(localized: "Schläge")) erfasst · \(distanceUnit.format(opp.totalDistanceMeters))")
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.caption)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSec)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(AppTheme.cardDark.opacity(0.6), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(AppTheme.cardAlt, lineWidth: 1))
    }

    // MARK: - Secondary Stats

    private func secondaryStatsCard(_ entry: any ScoreEntry) -> some View {
        HStack(spacing: 10) {
            puttBox(entry)
            if par > 3 {
                toggleBox("Fairway", isOn: Binding(get: { entry.fairwayHit },
                                                   set: { entry.fairwayHit = $0 }))
            }
            toggleBox("GIR", isOn: Binding(get: { entry.greenInRegulation },
                                           set: { entry.greenInRegulation = $0 }))
        }
    }

    private func puttBox(_ score: any ScoreEntry) -> some View {
        VStack(spacing: 4) {
            Text("Putts").font(.caption).foregroundStyle(AppTheme.textSec)
            HStack(spacing: 4) {
                Button {
                    guard score.putts > 0 else { return }
                    Haptics.decrement()
                    score.putts -= 1
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(score.putts > 0 ? AppTheme.text : AppTheme.textTer)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.cardAlt, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(score.putts <= 0)
                .accessibilityLabel("Putt abziehen")

                Text("\(score.putts)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                    .frame(minWidth: 26)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: score.putts)

                Button {
                    Haptics.stroke()
                    score.putts += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.gold)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.gold.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Putt hinzufügen")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func toggleBox(_ title: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Button {
            let hit = !isOn.wrappedValue
            hit ? Haptics.success() : Haptics.selection()
            withAnimation(.snappy) { isOn.wrappedValue = hit }
        } label: {
            VStack(spacing: 6) {
                Text(title).font(.caption).foregroundStyle(AppTheme.textSec)
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(isOn.wrappedValue ? AppTheme.gold : AppTheme.textTer)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isOn.wrappedValue ? AppTheme.gold.opacity(0.1) : AppTheme.card,
                        in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn.wrappedValue ? Text("Ja") : Text("Nein"))
    }

    // MARK: - Lochleiste

    private var holeStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(round.sortedScores, id: \.holeNumber) { hole in
                        let current = hole.holeNumber == score.holeNumber
                        let played = hole.strokes > 0
                        Button {
                            guard !current else { return }
                            onSelectHole(hole.holeNumber)
                        } label: {
                            Text("\(hole.holeNumber)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(current ? darkText : played ? AppTheme.text : AppTheme.textTer)
                                .frame(width: 30, height: 30)
                                .background(current ? AppTheme.gold : played ? AppTheme.cardAlt : AppTheme.cardDark,
                                            in: Circle())
                        }
                        .buttonStyle(.plain)
                        .id(hole.holeNumber)
                        .accessibilityLabel("Loch \(hole.holeNumber)")
                    }
                }
                .padding(.horizontal, 2)
            }
            .onAppear { proxy.scrollTo(score.holeNumber, anchor: .center) }
            .onChange(of: score.holeNumber) { _, n in
                withAnimation(.snappy) { proxy.scrollTo(n, anchor: .center) }
            }
        }
    }

    // MARK: - Score Gesamt Bar

    private var scoreGesamtBar: some View {
        Button {
            Haptics.tap()
            showRoundOverview = true
        } label: {
            scoreGesamtBarContent
        }
        .buttonStyle(.plain)
    }

    private var scoreGesamtBarContent: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("SCORE GESAMT")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.textTer)

            Spacer()

            Text("\(round.totalStrokes)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .contentTransition(.numericText())
                .animation(.snappy, value: round.totalStrokes)
            Text(round.scoreLabel)
                .font(.subheadline.bold())
                .foregroundStyle(scoreToParColor)
                .animation(.easeInOut(duration: 0.2), value: round.scoreLabel)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Shot Tracker Button

    /// Für dieses Loch ist noch kein Abschlag bekannt – weder aus dem Verzeichnis
    /// noch aus dem Positions-Tracking – und in dieser Runde noch nichts erfasst.
    private var needsTee: Bool {
        guard let course = round.course else { return false }
        return !course.hasOwnTeeCoordinate(forHole: score.holeNumber, tee: round.teeColor)
            && score.shots.isEmpty
    }

    @ViewBuilder
    private var shotTrackerButton: some View {
        if needsTee {
            teeSetterButton
        } else {
            shotRecorderButton
        }
    }

    private var teeSetterButton: some View {
        Button {
            Haptics.tap()
            if teeHintShown {
                setTee()
            } else {
                showTeeHint = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "figure.golf")
                Text("Abschlag setzen")
            }
            .font(.headline)
            .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    /// Nimmt den aktuellen Standort als Abschlag: für den Platz (damit das Loch
    /// ihn ab jetzt kennt) und als Startpunkt von Schlag 1. Jeder weitere Tipp
    /// auf Plus hängt dann den nächsten GPS-Punkt an.
    private func setTee() {
        guard let loc = userLocation else {
            Haptics.warning()
            showNoGPSAlert = true
            return
        }
        Haptics.stroke()
        let c = loc.coordinate
        round.course?.setTeeCoordinate(c, forHole: score.holeNumber, tee: round.teeColor)
        if score.strokes == 0 { score.strokes = 1 }
        insertShot(number: 1, at: c)
        pendingGPSLocation = loc
        pendingShotNumber = 1
        if !clubs.isEmpty && !round.hidesClubPicker { showClubPicker = true }
    }

    private func insertShot(number: Int, at coordinate: CLLocationCoordinate2D,
                            into entry: (any ScoreEntry)? = nil) {
        let entry = entry ?? score
        guard !entry.shots.contains(where: { $0.shotNumber == number }) else { return }
        let shot = Shot(shotNumber: number, from: coordinate, to: coordinate)
        context.insert(shot)
        entry.shots.append(shot)
    }

    /// Zählt einen Schlag und hängt den aktuellen Standort als Lage an die
    /// GPS-Kette des Spielers: Der vorige Schlag endet hier, der neue beginnt hier.
    /// Für Mitspieler ist das der Standort des Handys beim Tippen – also dort,
    /// wo man beim Schlag des Mitspielers steht.
    @discardableResult
    private func addStroke(to entry: any ScoreEntry) -> Int {
        Haptics.stroke()
        let shotNum = entry.strokes + 1
        entry.strokes += 1
        if let loc = userLocation, let prev = entry.sortedShots.last {
            let c = loc.coordinate
            prev.toLatitude = c.latitude
            prev.toLongitude = c.longitude
            prev.distanceMeters = Shot.haversineDistance(from: prev.fromCoordinate, to: c)
        }
        // Die Lage sofort speichern – auch wenn die Schlägerwahl
        // übersprungen wird, bleibt die Kette der GPS-Punkte geschlossen.
        if let loc = userLocation {
            insertShot(number: shotNum, at: loc.coordinate, into: entry)
        }
        return shotNum
    }

    private func removeStroke(from entry: any ScoreEntry) {
        guard entry.strokes > 1 else { return }
        Haptics.decrement()
        let removingNum = entry.strokes
        entry.strokes -= 1
        if let shot = entry.shots.first(where: { $0.shotNumber == removingNum }) {
            if let club = clubs.first(where: { $0.name == shot.club }), club.isPutter, entry.putts > 0 {
                entry.putts -= 1
            }
            entry.shots.removeAll { $0.shotNumber == removingNum }
            context.delete(shot)
        }
    }

    private var shotRecorderButton: some View {
        Button {
            Haptics.tap()
            showShotTracker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                Text(score.shots.isEmpty
                     ? "Schlag aufzeichnen"
                     : "\(score.shots.count) \(score.shots.count == 1 ? String(localized: "Schlag") : String(localized: "Schläge")) erfasst")
                if !score.shots.isEmpty {
                    Text("· \(distanceUnit.format(score.totalDistanceMeters)) gesamt")
                        .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08).opacity(0.6))
                }
            }
            .font(.headline)
            .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Mode notes (shared score)

    private var scrambleNote: some View {
        sharedScoreNote(
            icon: "person.2.wave.2.fill",
            title: "2-Mann Scramble mit \(opponentScores.first.flatMap { $0.playerName.isEmpty ? nil : $0.playerName } ?? "Partner")",
            subtitle: "Tragt den gemeinsamen Team-Score oben ein."
        )
    }

    private var scrambleTeamNote: some View {
        let names = opponentScores.map { $0.playerName.isEmpty ? "Spieler \($0.playerIndex + 1)" : $0.playerName }.joined(separator: ", ")
        return sharedScoreNote(
            icon: "person.3.fill",
            title: "Team Scramble - \(names)",
            subtitle: "Alle schlagen ab. Tragt den gemeinsamen Team-Score oben ein."
        )
    }

    private var viererNote: some View {
        sharedScoreNote(
            icon: "arrow.triangle.2.circlepath.circle.fill",
            title: "Vierer mit \(opponentScores.first.flatMap { $0.playerName.isEmpty ? nil : $0.playerName } ?? "Partner")",
            subtitle: "Ihr spielt abwechselnd mit einem Ball. Tragt den gemeinsamen Score ein."
        )
    }

    private var greensomeNote: some View {
        sharedScoreNote(
            icon: "person.2.circle.fill",
            title: "Greensome mit \(opponentScores.first.flatMap { $0.playerName.isEmpty ? nil : $0.playerName } ?? "Partner")",
            subtitle: "Beide schlagen ab - bester Teeshot, dann Wechselschlag."
        )
    }

    private func sharedScoreNote(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.title3).foregroundStyle(AppTheme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(AppTheme.textSec)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Opponent / Partner scoring

    private var opponentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Mit eigenen Karten stehen die Mitspieler schon oben – hier bleibt
            // nur die Auswertung des Lochs.
            if !showsPartnerCards {
                Text(sectionLabel)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .padding(.horizontal)

                ForEach(opponentScores, id: \.playerIndex) { opp in
                    opponentStepperRow(opp: opp, roleLabel: roleLabel(for: opp))
                }
            }

            switch gameMode {
            case .matchplay:
                if let opp = opponentScores.first {
                    matchplayHoleBadge(playerStrokes: score.strokes, opponentStrokes: opp.strokes)
                }
            case .betterBallStroke, .betterBallStableford:
                if let partner = opponentScores.first {
                    betterBallSummary(partner: partner)
                }
            case .betterBallMatchplay:
                betterBallMatchplayBadge
            case .bestBallStroke, .bestBallStableford:
                bestBallBadge(stableford: gameMode == .bestBallStableford)
            default:
                EmptyView()
            }
        }
    }

    private var sectionLabel: String {
        switch gameMode {
        case .matchplay: return "Gegner"
        case .betterBallStroke, .betterBallStableford: return "Partner"
        case .betterBallMatchplay: return "Partner & Gegner"
        default: return "Mitspieler"
        }
    }

    private func roleLabel(for opp: PlayerHoleScore) -> String? {
        guard gameMode == .betterBallMatchplay else { return nil }
        return opp.playerIndex == 1 ? "Partner" : "Gegner \(opp.playerIndex - 1)"
    }

    @ViewBuilder
    private var betterBallMatchplayBadge: some View {
        let partner = opponentScores.first { $0.playerIndex == 1 }
        let opp1 = opponentScores.first { $0.playerIndex == 2 }
        let opp2 = opponentScores.first { $0.playerIndex == 3 }
        let myBest: Int = {
            if let p = partner, p.strokes > 0 { return min(score.strokes, p.strokes) }
            return score.strokes
        }()
        let oppBest: Int = {
            guard let o1 = opp1, o1.strokes > 0 else { return 0 }
            if let o2 = opp2, o2.strokes > 0 { return min(o1.strokes, o2.strokes) }
            return o1.strokes
        }()
        if oppBest > 0 {
            let outcome = GameScoringEngine.matchplayHoleOutcome(playerStrokes: myBest, opponentStrokes: oppBest)
            let (label, color): (String, Color) = switch outcome {
            case .player:    ("Team gewinnt Loch", AppTheme.gold)
            case .opponent:  ("Team verliert Loch", .red)
            case .halved:    ("Unentschieden", .secondary)
            case .notPlayed: ("Noch kein Ergebnis", .secondary)
            }
            HStack {
                Spacer()
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(color.opacity(0.12), in: Capsule())
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func bestBallBadge(stableford: Bool) -> some View {
        let val = GameScoringEngine.bestBallHoleValue(
            round: round, holeScore: score, par: par, stableford: stableford)
        let hasAny = score.strokes > 0 || opponentScores.contains { $0.strokes > 0 }
        if hasAny {
            HStack {
                Spacer()
                if stableford {
                    Text("Best Ball: \(val) Punkte")
                        .font(.caption.bold())
                        .foregroundStyle(val >= 3 ? AppTheme.gold : val == 0 ? .secondary : .primary)
                } else {
                    let d = val - par
                    let ds = d == 0 ? "Par" : d > 0 ? "+\(d)" : "\(d)"
                    Text("Best Ball: \(val) (\(ds))")
                        .font(.caption.bold())
                        .foregroundStyle(d < 0 ? AppTheme.gold : d > 0 ? .orange : .primary)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    private func opponentStepperRow(opp: PlayerHoleScore, roleLabel: String? = nil) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(opp.playerName.isEmpty ? "Spieler \(opp.playerIndex + 1)" : opp.playerName)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text)
                if let role = roleLabel {
                    Text(role).font(.caption2).foregroundStyle(AppTheme.textSec)
                }
            }
            Spacer()
            HStack(spacing: 16) {
                Button {
                    guard opp.strokes > 1 else { return }
                    Haptics.decrement()
                    opp.strokes -= 1
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(opp.strokes > 1 ? .primary : .secondary)
                }
                .disabled(opp.strokes <= 1)
                Text("\(opp.strokes)")
                    .font(.title2.bold())
                    .frame(minWidth: 28, alignment: .center)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: opp.strokes)
                Button {
                    Haptics.stroke()
                    opp.strokes += 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.text)
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func matchplayHoleBadge(playerStrokes: Int, opponentStrokes: Int) -> some View {
        let outcome = GameScoringEngine.matchplayHoleOutcome(
            playerStrokes: playerStrokes, opponentStrokes: opponentStrokes)
        let (label, color): (String, Color) = switch outcome {
        case .player:    ("Loch gewonnen", AppTheme.gold)
        case .opponent:  ("Loch verloren", .red)
        case .halved:    ("Unentschieden", .secondary)
        case .notPlayed: ("Noch kein Ergebnis", .secondary)
        }
        HStack {
            Spacer()
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(color.opacity(0.12), in: Capsule())
            Spacer()
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: outcome.shortLabel)
    }

    @ViewBuilder
    private func betterBallSummary(partner: PlayerHoleScore) -> some View {
        let stableford = gameMode == .betterBallStableford
        let teamValue = GameScoringEngine.betterBallHoleValue(
            holeScore: score, partnerScore: partner, par: par, stableford: stableford)
        // Hat noch keiner gespielt, liefert betterBallHoleValue 0 — die Zeile
        // stünde dann als „Team: 0 Schläge (−4)" in Gold auf dem Loch.
        // Gleiche Prüfung wie in der Best-Ball-Zeile weiter oben.
        if score.strokes > 0 || partner.strokes > 0 {
        HStack {
            Spacer()
            if stableford {
                Text("Team: \(teamValue) Punkte")
                    .font(.caption.bold())
                    .foregroundStyle(teamValue >= 3 ? AppTheme.gold : teamValue == 0 ? .secondary : .primary)
            } else {
                let teamDiff = teamValue - par
                let diffStr = teamDiff == 0 ? "Par" : teamDiff > 0 ? "+\(teamDiff)" : "\(teamDiff)"
                Text("Team: \(teamValue) Schläge (\(diffStr))")
                    .font(.caption.bold())
                    .foregroundStyle(teamDiff < 0 ? AppTheme.gold : teamDiff > 0 ? .orange : .primary)
            }
            Spacer()
        }
        .padding(.horizontal)
        }
    }

    // MARK: - Score helpers

    private var scoreName: String {
        if score.strokes == 1 { return "Hole in One!" }
        switch diff {
        case ..<(-2): return "Albatross"
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Double"
        case 3: return "Triple"
        default: return "+\(diff)"
        }
    }

    private var scoreColor: Color {
        if diff < 0 { return AppTheme.gold }
        if diff == 0 { return .primary }
        return diff == 1 ? .orange : .red
    }
}

// MARK: - Club Picker Sheet

private struct ClubPickerSheet: View {
    let clubs: [GolfClub]
    let recommendedClub: GolfClub?
    let strokeNumber: Int
    let gpsLocation: CLLocation?
    @Bindable var holeScore: HoleScore
    let onPutterSelected: () -> Void
    let onHideForRound: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 8) {
                        if gpsLocation == nil {
                            HStack(spacing: 8) {
                                Image(systemName: "location.slash")
                                    .foregroundStyle(AppTheme.textSec)
                                Text("Kein GPS-Signal – Position nicht gespeichert")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSec)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        if let recommended = recommendedClub {
                            clubButton(recommended, isRecommended: true)
                            if clubs.count > 1 {
                                Text("Weitere Schläger")
                                    .font(.caption.bold())
                                    .foregroundStyle(AppTheme.textSec)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 4)
                                    .padding(.top, 8)
                            }
                        }
                        ForEach(otherClubs) { club in
                            clubButton(club, isRecommended: false)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Schlag \(strokeNumber) – Schläger?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Überspringen") {
                        Haptics.tap()
                        dismiss()
                    }
                        .foregroundStyle(AppTheme.textSec)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.tap()
                        onHideForRound()
                        dismiss()
                    } label: {
                        Image(systemName: "eye.slash")
                    }
                    .foregroundStyle(AppTheme.textSec)
                    .accessibilityLabel("Schlägerauswahl für diese Runde ausblenden")
                }
            }
        }
    }

    private var otherClubs: [GolfClub] {
        guard let recommended = recommendedClub else { return clubs }
        return clubs.filter { $0.persistentModelID != recommended.persistentModelID }
    }

    private func clubButton(_ club: GolfClub, isRecommended: Bool) -> some View {
        Button {
            Haptics.tap()
            if club.isPutter { onPutterSelected() }
            recordShot(club: club.name)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(club.isPutter ? Color.blue.opacity(0.15) : AppTheme.gold.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: club.isPutter ? "flag.fill" : "figure.golf")
                        .font(.system(size: 16))
                        .foregroundStyle(club.isPutter ? Color.blue : AppTheme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(club.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.text)
                        if club.isPutter {
                            Text("PUTTER")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15), in: Capsule())
                        }
                        if isRecommended {
                            Text("EMPFOHLEN")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(AppTheme.gold)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(AppTheme.gold.opacity(0.15), in: Capsule())
                        }
                    }
                    Text(club.isPutter ? "Putts +1 automatisch" : "Ø \(distanceUnit.format(Double(club.averageDistance)))")
                        .font(.caption)
                        .foregroundStyle(club.isPutter ? Color.blue.opacity(0.7) : AppTheme.textSec)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTer)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                if isRecommended {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(AppTheme.gold.opacity(0.6), lineWidth: 1.5)
                }
            }
        }
    }

    private func recordShot(club: String) {
        // Mit GPS legt der Plus-Knopf den Schlag schon an – dann nur den Schläger nachtragen.
        if let existing = holeScore.shots.first(where: { $0.shotNumber == strokeNumber }) {
            existing.club = club
            return
        }
        let coord = gpsLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let shot = Shot(shotNumber: strokeNumber, from: coord, to: coord, club: club)
        shot.holeScore = holeScore
        holeScore.shots.append(shot)
        context.insert(shot)
    }
}
