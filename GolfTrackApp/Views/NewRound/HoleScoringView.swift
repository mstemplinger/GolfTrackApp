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
    @State private var showClubPicker = false
    @State private var pendingGPSLocation: CLLocation?
    @State private var pendingShotNumber: Int = 0

    private var diff: Int { score.strokes - par }

    private var scoreToParColor: Color {
        guard let s = round.scoreToPar else { return AppTheme.text }
        if s < 0 { return AppTheme.gold }
        if s == 0 { return AppTheme.text }
        return s <= 2 ? .orange : .red
    }

    private var opponentScores: [PlayerHoleScore] {
        round.playerHoleScores
            .filter { $0.holeNumber == score.holeNumber }
            .sorted { $0.playerIndex < $1.playerIndex }
    }

    var body: some View {
        VStack(spacing: 14) {
            courseHeader
            holeCard
            pinDistanceCard
            strokeCounterCard
            secondaryStatsCard

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

            scoreGesamtBar
            shotTrackerButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .sheet(isPresented: $showShotTracker) {
            ShotTrackerView(holeScore: score)
        }
        .sheet(isPresented: $showPinSetter) {
            PinSetterView(pinLatitude: $score.pinLatitude, pinLongitude: $score.pinLongitude)
        }
        .sheet(isPresented: $showClubPicker) {
            ClubPickerSheet(
                clubs: clubs,
                strokeNumber: pendingShotNumber,
                gpsLocation: pendingGPSLocation,
                holeScore: score,
                onPutterSelected: { score.putts += 1 }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if clubs.isEmpty { seedDefaultClubs() }
            updateWidget()
        }
        .onChange(of: score.strokes) { _, _ in updateWidget() }
        .onChange(of: score.holeNumber) { _, _ in updateWidget() }
        .onReceive(NotificationCenter.default.publisher(for: .openShotTracker)) { _ in
            showShotTracker = true
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

    // MARK: - Pin Distance Helpers

    private var distanceToPin: Double? {
        guard let lat = score.pinLatitude, let lon = score.pinLongitude,
              let loc = userLocation else { return nil }
        return CLLocation(latitude: lat, longitude: lon).distance(from: loc)
    }

    private func recommendedClub(for distanceMeters: Double) -> GolfClub? {
        guard !clubs.isEmpty else { return nil }
        return clubs.min(by: {
            abs($0.averageDistance - Int(distanceMeters)) < abs($1.averageDistance - Int(distanceMeters))
        })
    }

    // MARK: - Pin Distance Card

    @ViewBuilder
    private var pinDistanceCard: some View {
        if score.hasPinLocation {
            // Pin is set — show distance + club recommendation
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    // Flag icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.gold.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: "flag.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppTheme.gold)
                    }

                    // Distance + club recommendation stacked
                    VStack(alignment: .leading, spacing: 5) {
                        if let dist = distanceToPin {
                            Text(distanceUnit.format(dist))
                                .font(.title3.bold())
                                .foregroundStyle(AppTheme.text)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: distanceUnit.value(dist))

                            if let club = recommendedClub(for: dist) {
                                HStack(spacing: 5) {
                                    Image(systemName: "figure.golf")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(AppTheme.gold)
                                    Text("Empfehlung:")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSec)
                                    Text(club.name)
                                        .font(.caption.bold())
                                        .foregroundStyle(AppTheme.gold)
                                    Text("(Ø \(distanceUnit.format(Double(club.averageDistance))))")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textTer)
                                }
                            } else {
                                Text("Noch \(Int(dist)) m zum Loch")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSec)
                            }
                        } else {
                            Text("Pin gesetzt")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.text)
                            Text("Standort wird ermittelt …")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                        }
                    }
                }

                // Subtle "update pin" text button at bottom
                Button {
                    showPinSetter = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 10))
                        Text("Pin aktualisieren")
                            .font(.caption)
                    }
                    .foregroundStyle(AppTheme.textTer)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        } else {
            // Pin not set — compact tappable row
            Button {
                showPinSetter = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textSec)
                    Text("Lochposition festlegen")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTer)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Course Header

    private var courseHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(round.course?.name ?? "Runde")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.text)
                if let course = round.course {
                    Text("\(course.numberOfHoles) Löcher · Par \(course.totalPar)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                }
            }
            Spacer()
            HStack(spacing: 5) {
                Circle()
                    .fill(Color(red: 0.2, green: 0.85, blue: 0.4))
                    .frame(width: 7, height: 7)
                Text("LIVE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color(red: 0.2, green: 0.85, blue: 0.4))
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    // MARK: - Hole Card

    private var holeCard: some View {
        HStack(alignment: .center, spacing: 0) {
            // Prev button
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(score.holeNumber > 1 ? AppTheme.gold : AppTheme.textTer)
                    .frame(width: 36, height: 56)
            }
            .disabled(score.holeNumber <= 1)

            // Left: hole label + big italic number + HCP/distance badges
            VStack(alignment: .leading, spacing: 0) {
                Text("AKTUELLES LOCH")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2.0)
                    .foregroundStyle(AppTheme.textTer)
                    .padding(.bottom, 2)
                Text(String(format: "%02d", score.holeNumber))
                    .font(.system(size: 64, weight: .heavy))
                    .italic()
                    .foregroundStyle(AppTheme.gold)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: score.holeNumber)
                // HCP & distance row
                HStack(spacing: 8) {
                    if let hcp = holeHCP {
                        Label("HCP \(hcp)", systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.textSec)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(AppTheme.cardAlt, in: Capsule())
                    }
                    if let len = holeLength {
                        Label("\(len) m", systemImage: "ruler")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.textSec)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(AppTheme.cardAlt, in: Capsule())
                    }
                }
                .padding(.top, 4)
            }
            .padding(.leading, 2)

            Spacer()

            // Right: par + score badge
            VStack(alignment: .trailing, spacing: 10) {
                Text("PAR \(par)")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(AppTheme.textSec)

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
            .padding(.trailing, 2)

            // Next button
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(score.holeNumber < holeCount ? AppTheme.gold : AppTheme.textTer)
                    .frame(width: 36, height: 56)
            }
            .disabled(score.holeNumber >= holeCount)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var holeHCP: Int? {
        let i = score.holeNumber - 1
        guard let vals = round.course?.hcpValues, i < vals.count else { return nil }
        return vals[i]
    }

    private var holeLength: Int? {
        let i = score.holeNumber - 1
        guard let vals = round.course?.holeLengths, i < vals.count else { return nil }
        return vals[i]
    }

    // MARK: - Stroke Counter Card

    private var strokeCounterCard: some View {
        VStack(spacing: 6) {
            Text("SCHLÄGE")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(AppTheme.textTer)

            HStack(spacing: 28) {
                Button {
                    guard score.strokes > 1 else { return }
                    let removingNum = score.strokes
                    score.strokes -= 1
                    if let shot = score.shots.first(where: { $0.shotNumber == removingNum }) {
                        if let club = clubs.first(where: { $0.name == shot.club }), club.isPutter, score.putts > 0 {
                            score.putts -= 1
                        }
                        context.delete(shot)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(score.strokes > 1 ? AppTheme.gold : AppTheme.textTer)
                }
                .disabled(score.strokes <= 1)

                Text("\(score.strokes)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .frame(minWidth: 80, alignment: .center)
                    .foregroundStyle(AppTheme.text)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: score.strokes)

                Button {
                    let shotNum = score.strokes + 1
                    score.strokes += 1
                    // Update previous shot's destination with current position
                    if let loc = userLocation,
                       let prev = score.sortedShots.last {
                        let c = loc.coordinate
                        prev.toLatitude = c.latitude
                        prev.toLongitude = c.longitude
                        prev.distanceMeters = Shot.haversineDistance(from: prev.fromCoordinate, to: c)
                    }
                    pendingGPSLocation = userLocation
                    pendingShotNumber = shotNum
                    if !clubs.isEmpty { showClubPicker = true }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Secondary Stats Card

    private var secondaryStatsCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                puttCounter
                Divider().frame(height: 50).padding(.horizontal, 8)
                if par > 3 {
                    fairwayToggle
                    Divider().frame(height: 50).padding(.horizontal, 8)
                }
                girToggle
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var puttCounter: some View {
        VStack(spacing: 8) {
            Text("Putts").font(.caption).foregroundStyle(AppTheme.textSec)
            HStack(spacing: 10) {
                Button { if score.putts > 0 { score.putts -= 1 } } label: {
                    Image(systemName: "minus.circle").font(.title2)
                        .foregroundStyle(score.putts > 0 ? AppTheme.gold : .secondary)
                }
                .disabled(score.putts <= 0)
                Text("\(score.putts)").font(.title.bold()).frame(minWidth: 28)
                    .contentTransition(.numericText()).animation(.snappy, value: score.putts)
                Button { score.putts += 1 } label: {
                    Image(systemName: "plus.circle").font(.title2).foregroundStyle(AppTheme.gold)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var fairwayToggle: some View {
        VStack(spacing: 8) {
            Text("Fairway").font(.caption).foregroundStyle(AppTheme.textSec)
            Toggle("", isOn: $score.fairwayHit).labelsHidden().tint(AppTheme.gold)
        }
        .frame(maxWidth: .infinity)
    }

    private var girToggle: some View {
        VStack(spacing: 8) {
            Text("GIR").font(.caption).foregroundStyle(AppTheme.textSec)
            Toggle("", isOn: $score.greenInRegulation).labelsHidden().tint(AppTheme.gold)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Score Gesamt Bar

    private var scoreGesamtBar: some View {
        HStack {
            Text("SCORE GESAMT")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.textTer)

            Spacer()

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(round.scoreLabel)
                    .font(.title2.bold())
                    .foregroundStyle(scoreToParColor)
                    .animation(.easeInOut(duration: 0.2), value: round.scoreLabel)
                Text("/ Loch \(score.holeNumber)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSec)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Shot Tracker Button

    private var shotTrackerButton: some View {
        Button {
            showShotTracker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                Text(score.shots.isEmpty
                     ? "Schlag aufzeichnen"
                     : "\(score.shots.count) Schlag\(score.shots.count == 1 ? "" : "schläge") erfasst")
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
            Text(sectionLabel)
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
                .padding(.horizontal)

            ForEach(opponentScores, id: \.playerIndex) { opp in
                opponentStepperRow(opp: opp, roleLabel: roleLabel(for: opp))
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
                    if opp.strokes > 1 { opp.strokes -= 1 }
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
    let strokeNumber: Int
    let gpsLocation: CLLocation?
    @Bindable var holeScore: HoleScore
    let onPutterSelected: () -> Void

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
                        ForEach(clubs) { club in
                            Button {
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
                            }
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
                    Button("Überspringen") { dismiss() }
                        .foregroundStyle(AppTheme.textSec)
                }
            }
        }
    }

    private func recordShot(club: String) {
        let coord = gpsLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let shot = Shot(shotNumber: strokeNumber, from: coord, to: coord, club: club)
        shot.holeScore = holeScore
        holeScore.shots.append(shot)
        context.insert(shot)
    }
}
