import SwiftUI
import SwiftData
import CoreLocation

struct ScorecardView: View {
    @Bindable var round: Round
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Closure called when the round is fully finished – dismisses the enclosing fullScreenCover.
    var onRoundFinished: (() -> Void)? = nil

    @State private var currentIndex: Int = 0
    @State private var showFinishAlert = false
    @State private var showCancelAlert = false
    @State private var showRoundCompleteSheet = false
    @State private var showShakeAlert = false
    @State private var showRules = false
    @State private var showCourseInfo = false

    private let wc = WatchConnectivityManager.shared
    @ObservedObject private var gc = GameCenterManager.shared

    private var sortedScores: [HoleScore] {
        round.holeScores.sorted { $0.holeNumber < $1.holeNumber }
    }

    private var currentScore: HoleScore? { sortedScores[safe: currentIndex] }

    private func par(for score: HoleScore) -> Int {
        guard let course = round.course,
              score.holeNumber - 1 < course.parValues.count else { return 4 }
        return course.parValues[score.holeNumber - 1]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Shake-Erkennung – unsichtbar, kein Einfluss auf Layout
                ShakeDetector()
                    .frame(width: 0, height: 0)

                if let score = currentScore {
                    HoleScoringView(
                        score: score,
                        round: round,
                        par: par(for: score),
                        holeCount: sortedScores.count,
                        gameMode: round.gameMode,
                        onPrevious: { if currentIndex > 0 { currentIndex -= 1 } },
                        onNext: { if currentIndex < sortedScores.count - 1 { currentIndex += 1 } }
                    )
                }

                if round.gameMode.isMultiplayer {
                    gameStatusBanner
                }

                miniScorecard
                    .padding(.bottom, 8)
            }
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Abbrechen") { showCancelAlert = true }
                    .foregroundStyle(AppTheme.textSec)
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: round.gameMode.sfSymbol)
                        .font(.caption)
                        .foregroundStyle(AppTheme.gold)
                    Text(round.gameMode.displayName)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    if let course = round.course, !course.hcpValues.isEmpty || !course.facilityNotes.isEmpty {
                        Button {
                            showCourseInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(AppTheme.textSec)
                        }
                    }
                    Button("Abschließen") { showFinishAlert = true }
                        .bold().foregroundStyle(AppTheme.gold)
                }
            }
        }
        .alert("Runde abschließen?", isPresented: $showFinishAlert) {
            Button("Abschließen") {
                round.isComplete = true
                wc.finishRound()
                // Nur zur Bestenliste zählen wenn alle Löcher mit mindestens 1 Schlag belegt sind
                let allHolesPlayed = sortedScores.allSatisfy { $0.strokes >= 1 }
                if allHolesPlayed {
                    gc.submitRoundScore(round.totalStrokes)
                }
                gc.evaluateAchievements(rounds: [round])
                GolfLiveActivityManager.endRound()
                showRoundCompleteSheet = true
            }
            Button("Weiter spielen", role: .cancel) {}
        } message: {
            Text("Die Runde wird als abgeschlossen gespeichert.")
        }
        .sheet(isPresented: $showRoundCompleteSheet) {
            RoundCompleteSheet(round: round) {
                showRoundCompleteSheet = false
                gc.deactivateAccessPoint()
                // Close the whole fullScreenCover (back to home), not just ScorecardView
                onRoundFinished?()
            }
            .presentationDetents([.large])
        }
        // ── Shake → Spielregeln ─────────────────────────────────────
        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            showShakeAlert = true
        }
        .alert("Spielregeln anzeigen?", isPresented: $showShakeAlert) {
            Button("Anzeigen") { showRules = true }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Möchtest du die wichtigsten Golfregeln nachschlagen?")
        }
        .sheet(isPresented: $showRules) {
            NavigationStack {
                GolfRulesView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Fertig") { showRules = false }
                                .foregroundStyle(AppTheme.gold)
                        }
                    }
            }
        }
        .sheet(isPresented: $showCourseInfo) {
            if let course = round.course {
                CourseInfoSheet(course: course)
            }
        }

        .alert("Runde verlassen?", isPresented: $showCancelAlert) {
            Button("Verlassen", role: .destructive) { dismiss() }
            Button("Weiter spielen", role: .cancel) {}
        } message: {
            Text("Dein Fortschritt wird gespeichert. Du kannst die Runde auf der Startseite fortsetzen oder dort löschen.")
        }
        .onAppear {
            // Game Center: Aktivitätsstatus setzen (Freunde sehen "spielt gerade")
            gc.activateAccessPoint()

            // Runde an Watch senden beim Start
            let strokes = sortedScores.map(\.strokes)
            wc.startRound(holes: sortedScores.count, strokes: strokes, currentHoleIndex: currentIndex)

            // Watch-Updates auf iPhone anwenden
            wc.onWatchStrokesUpdate = { watchStrokes, watchHole in
                guard watchStrokes.count == sortedScores.count else { return }
                for (i, score) in sortedScores.enumerated() {
                    score.strokes = watchStrokes[i]
                }
                currentIndex = watchHole
            }

            // Watch-Schläge (GPS) in SwiftData speichern
            wc.onWatchShotReceived = { holeIdx, fromLat, fromLon, toLat, toLon, distance in
                guard holeIdx < sortedScores.count else { return }
                let targetHole = sortedScores[holeIdx]
                let existingShots = targetHole.shots
                let shot = Shot(
                    shotNumber: existingShots.count + 1,
                    from: CLLocationCoordinate2D(latitude: fromLat, longitude: fromLon),
                    to:   CLLocationCoordinate2D(latitude: toLat,   longitude: toLon)
                )
                context.insert(shot)
                shot.holeScore = targetHole
            }
        }
        .onDisappear {
            // Callbacks aufräumen damit keine Zombie-Referenzen bleiben
            wc.onWatchShotReceived = nil
        }
        .onChange(of: currentIndex) { _, newIndex in
            let strokes = sortedScores.map(\.strokes)
            wc.updateStrokes(strokes: strokes, currentHoleIndex: newIndex)
        }
        .onChange(of: round.totalStrokes) { _, _ in
            let strokes = sortedScores.map(\.strokes)
            wc.updateStrokes(strokes: strokes, currentHoleIndex: currentIndex)
        }
    }

    // MARK: - Game status banner

    @ViewBuilder
    private var gameStatusBanner: some View {
        switch round.gameMode {
        case .matchplay:
            matchplayBanner
        case .betterBallMatchplay:
            betterBallMatchplayBanner
        case .skins:
            skinsBanner
        case .betterBallStroke:
            betterBallBanner(stableford: false)
        case .betterBallStableford:
            betterBallBanner(stableford: true)
        case .bestBallStroke:
            bestBallBanner(stableford: false)
        case .bestBallStableford:
            bestBallBanner(stableford: true)
        case .scramble2Mann, .scrambleTeam, .vierer, .greensome:
            sharedScoreBanner
        case .erado:
            eradoBanner
        default:
            EmptyView()
        }
    }

    private var matchplayBanner: some View {
        let status = GameScoringEngine.matchplayStatus(round: round)
        let (icon, color): (String, Color) = status.holesUp > 0
            ? ("chevron.up.circle.fill", AppTheme.gold)
            : status.holesUp < 0
                ? ("chevron.down.circle.fill", .red)
                : ("equal.circle.fill", .secondary)
        return HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(status.statusLabel)
                .font(.caption.bold())
                .foregroundStyle(color)
            if status.isFinished {
                Text("• Runde beendet").font(.caption).foregroundStyle(AppTheme.textSec)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.cardDark)
    }

    private var skinsBanner: some View {
        let summary = GameScoringEngine.skinsResult(round: round)
        let myTotal = summary.skinsPerPlayer[0] ?? 0
        let opponentNames = round.otherPlayerNames
        let opponentTotals = (1...max(1, opponentNames.count)).map { i in
            summary.skinsPerPlayer[i] ?? 0
        }
        let opponentBest = opponentTotals.max() ?? 0

        return HStack(spacing: 8) {
            Image(systemName: "seal.fill").foregroundStyle(.orange)
            Text("Skins: Du \(myTotal)")
                .font(.caption.bold())
                .foregroundStyle(myTotal >= opponentBest ? AppTheme.gold : .primary)
            if !opponentNames.isEmpty {
                Text("–")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                ForEach(Array(opponentNames.enumerated()), id: \.offset) { i, name in
                    Text("\(name.isEmpty ? "Sp.\(i+2)" : name) \(opponentTotals[i])")
                        .font(.caption.bold())
                }
            }
            if summary.openSkins > 0 {
                Text("(\(summary.openSkins) offen)").font(.caption).foregroundStyle(AppTheme.textSec)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.cardDark)
    }

    private func betterBallBanner(stableford: Bool) -> some View {
        let total = GameScoringEngine.betterBallTeamTotal(round: round, stableford: stableford)
        let partnerName = round.otherPlayerNames.first ?? "Partner"
        return HStack(spacing: 6) {
            Image(systemName: "flame.fill").foregroundStyle(.orange)
            Text("Team \(partnerName)")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
            if stableford {
                Text("\(total) Punkte")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.gold)
            } else {
                let playedPar = round.sortedScores
                    .filter { $0.strokes > 0 }
                    .compactMap { s -> Int? in
                        let idx = s.holeNumber - 1
                        guard let vals = round.course?.parValues, idx < vals.count else { return nil }
                        return vals[idx]
                    }.reduce(0, +)
                let diff = total - playedPar
                let label = diff == 0 ? "E" : diff > 0 ? "+\(diff)" : "\(diff)"
                Text("\(label)")
                    .font(.caption.bold())
                    .foregroundStyle(diff < 0 ? AppTheme.gold : diff > 0 ? .orange : .primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.cardDark)
    }

    private var scrambleBanner: some View {
        let partnerName = round.otherPlayerNames.first ?? "Partner"
        let playedPar = round.sortedScores
            .filter { $0.strokes > 0 }
            .compactMap { s -> Int? in
                let idx = s.holeNumber - 1
                guard let vals = round.course?.parValues, idx < vals.count else { return nil }
                return vals[idx]
            }.reduce(0, +)
        let diff = round.totalStrokes - playedPar
        let diffLabel = diff == 0 ? "E" : diff > 0 ? "+\(diff)" : "\(diff)"
        return HStack(spacing: 6) {
            Image(systemName: "person.2.wave.2.fill").foregroundStyle(AppTheme.gold)
            Text("Team \(partnerName.isEmpty ? "Scramble" : partnerName)")
                .font(.caption).foregroundStyle(AppTheme.textSec)
            if round.totalStrokes > 0 {
                Text(diffLabel)
                    .font(.caption.bold())
                    .foregroundStyle(diff < 0 ? AppTheme.gold : diff > 0 ? .orange : .primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.cardDark)
    }

    private var betterBallMatchplayBanner: some View {
        let status = GameScoringEngine.betterBallMatchplayStatus(round: round)
        let (icon, color): (String, Color) = status.holesUp > 0
            ? ("chevron.up.circle.fill", AppTheme.gold)
            : status.holesUp < 0
                ? ("chevron.down.circle.fill", .red)
                : ("equal.circle.fill", .secondary)
        return HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(status.statusLabel).font(.caption.bold()).foregroundStyle(color)
            if status.isFinished {
                Text("• Runde beendet").font(.caption).foregroundStyle(AppTheme.textSec)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.cardDark)
    }

    private func bestBallBanner(stableford: Bool) -> some View {
        let total = GameScoringEngine.bestBallTeamTotal(round: round, stableford: stableford)
        let playerCount = 1 + round.otherPlayerNames.count
        return HStack(spacing: 6) {
            Image(systemName: "flame.circle.fill").foregroundStyle(.orange)
            Text("Best Ball – \(playerCount) Spieler")
                .font(.caption).foregroundStyle(AppTheme.textSec)
            if stableford {
                Text("\(total) Punkte").font(.caption.bold()).foregroundStyle(AppTheme.gold)
            } else {
                let playedPar = round.sortedScores.filter { $0.strokes > 0 }
                    .compactMap { s -> Int? in
                        let idx = s.holeNumber - 1
                        guard let vals = round.course?.parValues, idx < vals.count else { return nil }
                        return vals[idx]
                    }.reduce(0, +)
                let diff = total - playedPar
                let label = diff == 0 ? "E" : diff > 0 ? "+\(diff)" : "\(diff)"
                Text(label).font(.caption.bold())
                    .foregroundStyle(diff < 0 ? AppTheme.gold : diff > 0 ? .orange : .primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.cardDark)
    }

    private var sharedScoreBanner: some View {
        let (icon, label): (String, String) = switch round.gameMode {
        case .scrambleTeam: ("person.3.fill", "Team Scramble")
        case .vierer:       ("arrow.triangle.2.circlepath.circle.fill", "Vierer")
        case .greensome:    ("person.2.circle.fill", "Greensome")
        default:            ("person.2.wave.2.fill", "2-Mann Scramble")
        }
        let partnerNames = round.otherPlayerNames.filter { !$0.isEmpty }.joined(separator: ", ")
        let playedPar = round.sortedScores.filter { $0.strokes > 0 }
            .compactMap { s -> Int? in
                let idx = s.holeNumber - 1
                guard let vals = round.course?.parValues, idx < vals.count else { return nil }
                return vals[idx]
            }.reduce(0, +)
        let diff = round.totalStrokes - playedPar
        let diffLabel = diff == 0 ? "E" : diff > 0 ? "+\(diff)" : "\(diff)"
        return HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(AppTheme.gold)
            Text("\(label)\(partnerNames.isEmpty ? "" : " – \(partnerNames)")")
                .font(.caption).foregroundStyle(AppTheme.textSec)
            if round.totalStrokes > 0 {
                Text(diffLabel).font(.caption.bold())
                    .foregroundStyle(diff < 0 ? AppTheme.gold : diff > 0 ? .orange : .primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.cardDark)
    }

    private var eradoBanner: some View {
        let result = GameScoringEngine.eradoResult(round: round)
        let playedPar = round.sortedScores
            .filter { $0.strokes > 0 && !result.scratchedHoles.contains($0.holeNumber) }
            .compactMap { s -> Int? in
                let idx = s.holeNumber - 1
                guard let vals = round.course?.parValues, idx < vals.count else { return nil }
                return vals[idx]
            }.reduce(0, +)
        let diff = result.total - playedPar
        let diffLabel = diff == 0 ? "E" : diff > 0 ? "+\(diff)" : "\(diff)"
        return HStack(spacing: 6) {
            Image(systemName: "ticket.fill").foregroundStyle(.purple)
            Text("Erado").font(.caption).foregroundStyle(AppTheme.textSec)
            if result.total > 0 {
                Text("\(result.total) (\(diffLabel))")
                    .font(.caption.bold())
                    .foregroundStyle(diff < 0 ? AppTheme.gold : diff > 0 ? .orange : .primary)
            }
            if !result.scratchedHoles.isEmpty {
                let holes = result.scratchedHoles.sorted().map { "L\($0)" }.joined(separator: ", ")
                Text("Streich: \(holes)").font(.caption2).foregroundStyle(AppTheme.textSec)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.cardDark)
    }

    // MARK: - Mini scorecard

    @ViewBuilder
    private var modeSpecificRows: some View {
        switch round.gameMode {
        case .matchplay:
            scoreRow
            matchplayOpponentRow
            matchplayResultRow
        case .stableford:
            stablefordRow
        case .betterBallStroke:
            scoreRow
            betterBallPartnerRow(stableford: false)
            betterBallTeamRow(stableford: false)
        case .betterBallStableford:
            stablefordRow
            betterBallPartnerRow(stableford: true)
            betterBallTeamRow(stableford: true)
        case .betterBallMatchplay:
            scoreRow
            betterBallMatchplayAllRows
        case .skins:
            scoreRow
            skinsRow
        case .bestBallStroke:
            scoreRow
            bestBallAllPartnerRows(stableford: false)
            bestBallTeamRow(stableford: false)
        case .bestBallStableford:
            stablefordRow
            bestBallAllPartnerRows(stableford: true)
            bestBallTeamRow(stableford: true)
        case .erado:
            eradoScoreRow
        case .scramble2Mann, .scrambleTeam, .vierer, .greensome:
            scoreRow
        default:
            scoreRow
        }
    }

    private var miniScorecard: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    scorecardRow(label: "Loch", values: sortedScores.map { "\($0.holeNumber)" },
                                 total: "∑", style: .header)
                    scorecardRow(label: "Par", values: sortedScores.map { "\(par(for: $0))" },
                                 total: "\(round.course?.totalPar ?? 0)", style: .muted)

                    modeSpecificRows
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(AppTheme.cardDark)
            .onChange(of: currentIndex) { _, idx in
                withAnimation { proxy.scrollTo("hole-\(idx)", anchor: .center) }
            }
        }
    }

    private enum RowStyle { case header, muted }

    private func scorecardRow(label: String, values: [String], total: String, style: RowStyle) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .frame(width: 50, alignment: .leading)
                .font(style == .header ? .caption.bold() : .caption)
                .foregroundStyle(style == .muted ? .secondary : .primary)
            ForEach(Array(values.enumerated()), id: \.offset) { idx, val in
                Text(val)
                    .frame(width: 34)
                    .font(style == .header ? .caption.bold() : .caption)
                    .foregroundStyle(idx == currentIndex ? AppTheme.gold : style == .muted ? .secondary : .primary)
                    .background(idx == currentIndex && style == .header ? AppTheme.gold.opacity(0.12) : .clear,
                                in: RoundedRectangle(cornerRadius: 4))
                    .id("hole-\(idx)")
            }
            Text(total).frame(width: 40, alignment: .trailing).font(.caption.bold())
        }
        .frame(height: 26)
    }

    // MARK: - Score rows

    private var scoreRow: some View {
        HStack(spacing: 0) {
            Text("Score")
                .frame(width: 50, alignment: .leading)
                .font(.caption).foregroundStyle(AppTheme.textSec)
            ForEach(Array(sortedScores.enumerated()), id: \.offset) { _, score in
                let d = score.strokes - par(for: score)
                ZStack {
                    Circle().fill(scoreBg(diff: d, hasScore: score.strokes > 0)).frame(width: 22, height: 22)
                    Text(score.strokes > 0 ? "\(score.strokes)" : "·")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(score.strokes > 0 ? scoreFg(diff: d) : .secondary)
                }
                .frame(width: 34)
            }
            Text(round.totalStrokes > 0 ? "\(round.totalStrokes)" : "-")
                .frame(width: 40, alignment: .trailing).font(.caption.bold())
        }
        .frame(height: 26)
    }

    private var stablefordRow: some View {
        HStack(spacing: 0) {
            Text("Punkte")
                .frame(width: 50, alignment: .leading)
                .font(.caption).foregroundStyle(AppTheme.textSec)
            ForEach(sortedScores, id: \.holeNumber) { score in
                let pts = GameMode.stablefordPoints(strokes: score.strokes, par: par(for: score))
                Text(score.strokes > 0 ? "\(pts)" : "·")
                    .frame(width: 34)
                    .font(.caption.bold())
                    .foregroundStyle(pts >= 3 ? AppTheme.gold : pts == 0 ? .secondary : .primary)
            }
            Text("\(round.totalStablefordPoints)")
                .frame(width: 40, alignment: .trailing).font(.caption.bold()).foregroundStyle(AppTheme.gold)
        }
        .frame(height: 26)
    }

    // MARK: - Matchplay rows

    private var matchplayOpponentRow: some View {
        let oppName = round.otherPlayerNames.first ?? "Gegner"
        return HStack(spacing: 0) {
            Text(oppName.isEmpty ? "Gegner" : String(oppName.prefix(6)))
                .frame(width: 50, alignment: .leading)
                .font(.caption).foregroundStyle(AppTheme.textSec)
            ForEach(sortedScores, id: \.holeNumber) { holeScore in
                let opp = round.opponentScore(playerIndex: 1, holeNumber: holeScore.holeNumber)
                let strokes = opp?.strokes ?? 0
                let d = strokes > 0 ? strokes - par(for: holeScore) : 0
                ZStack {
                    Circle().fill(scoreBg(diff: d, hasScore: strokes > 0)).frame(width: 22, height: 22)
                    Text(strokes > 0 ? "\(strokes)" : "·")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(strokes > 0 ? scoreFg(diff: d) : Color.secondary)
                }
                .frame(width: 34)
            }
            Text("-").frame(width: 40, alignment: .trailing).font(.caption.bold())
        }
        .frame(height: 26)
    }

    private var matchplayResultRow: some View {
        HStack(spacing: 0) {
            Text("Ergebnis")
                .frame(width: 50, alignment: .leading)
                .font(.caption).foregroundStyle(AppTheme.textSec)
            ForEach(sortedScores, id: \.holeNumber) { holeScore in
                let opp = round.opponentScore(playerIndex: 1, holeNumber: holeScore.holeNumber)
                let outcome = GameScoringEngine.matchplayHoleOutcome(
                    playerStrokes: holeScore.strokes,
                    opponentStrokes: opp?.strokes ?? 0
                )
                let (label, color): (String, Color) = switch outcome {
                case .player:    ("W", AppTheme.gold)
                case .opponent:  ("L", .red)
                case .halved:    ("H", .secondary)
                case .notPlayed: ("·", .secondary)
                }
                Text(label)
                    .frame(width: 34)
                    .font(.caption.bold())
                    .foregroundStyle(color)
            }
            Text("").frame(width: 40, alignment: .trailing)
        }
        .frame(height: 26)
    }

    // MARK: - Better Ball rows

    private func betterBallPartnerRow(stableford: Bool) -> some View {
        let partnerName = round.otherPlayerNames.first ?? "Partner"
        return HStack(spacing: 0) {
            Text(partnerName.isEmpty ? "Partner" : String(partnerName.prefix(6)))
                .frame(width: 50, alignment: .leading)
                .font(.caption).foregroundStyle(AppTheme.textSec)
            ForEach(sortedScores, id: \.holeNumber) { holeScore in
                let partner = round.opponentScore(playerIndex: 1, holeNumber: holeScore.holeNumber)
                let strokes = partner?.strokes ?? 0
                if stableford {
                    let pts = strokes > 0 ? GameMode.stablefordPoints(strokes: strokes, par: par(for: holeScore)) : 0
                    Text(strokes > 0 ? "\(pts)" : "·")
                        .frame(width: 34)
                        .font(.caption)
                        .foregroundStyle(pts >= 3 ? AppTheme.gold : pts == 0 ? .secondary : .primary)
                } else {
                    let d = strokes > 0 ? strokes - par(for: holeScore) : 0
                    ZStack {
                        Circle().fill(scoreBg(diff: d, hasScore: strokes > 0)).frame(width: 22, height: 22)
                        Text(strokes > 0 ? "\(strokes)" : "·")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(strokes > 0 ? scoreFg(diff: d) : Color.secondary)
                    }
                    .frame(width: 34)
                }
            }
            Text("-").frame(width: 40, alignment: .trailing).font(.caption.bold())
        }
        .frame(height: 26)
    }

    private func betterBallTeamRow(stableford: Bool) -> some View {
        HStack(spacing: 0) {
            Text("Team")
                .frame(width: 50, alignment: .leading)
                .font(.caption.bold()).foregroundStyle(AppTheme.text)
            ForEach(sortedScores, id: \.holeNumber) { holeScore in
                let partner = round.opponentScore(playerIndex: 1, holeNumber: holeScore.holeNumber)
                let val = GameScoringEngine.betterBallHoleValue(
                    holeScore: holeScore,
                    partnerScore: partner,
                    par: par(for: holeScore),
                    stableford: stableford
                )
                let played = holeScore.strokes > 0 || (partner?.strokes ?? 0) > 0
                if stableford {
                    Text(played ? "\(val)" : "·")
                        .frame(width: 34)
                        .font(.caption.bold())
                        .foregroundStyle(val >= 3 ? AppTheme.gold : val == 0 ? .secondary : .primary)
                } else {
                    let d = played ? val - par(for: holeScore) : 0
                    Text(played ? "\(val)" : "·")
                        .frame(width: 34)
                        .font(.caption.bold())
                        .foregroundStyle(played ? scoreFg(diff: d) : Color.secondary)
                }
            }
            let total = GameScoringEngine.betterBallTeamTotal(round: round, stableford: stableford)
            Text("\(total)")
                .frame(width: 40, alignment: .trailing)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.gold)
        }
        .frame(height: 26)
    }

    // MARK: - Skins row

    private var skinsRow: some View {
        let summary = GameScoringEngine.skinsResult(round: round)
        return HStack(spacing: 0) {
            Text("Skins")
                .frame(width: 50, alignment: .leading)
                .font(.caption).foregroundStyle(AppTheme.textSec)
            ForEach(sortedScores, id: \.holeNumber) { holeScore in
                let winnerOpt = summary.holeWinners[holeScore.holeNumber]
                let (label, color): (String, Color) = {
                    guard let idx = winnerOpt else { return ("·", .secondary) }
                    if idx == -1 { return ("=", .secondary) }
                    if idx == 0 { return ("Du", AppTheme.gold) }
                    let name = round.otherPlayerNames[safe: idx - 1] ?? "G\(idx)"
                    return (name.isEmpty ? "G\(idx)" : String(name.prefix(2)), .orange)
                }()
                Text(label)
                    .frame(width: 34)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
            }
            let myTotal = summary.skinsPerPlayer[0] ?? 0
            Text("\(myTotal)")
                .frame(width: 40, alignment: .trailing)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.gold)
        }
        .frame(height: 26)
    }

    // MARK: - Better Ball Matchplay rows

    @ViewBuilder
    private var betterBallMatchplayAllRows: some View {
        // Partner row
        opponentScoreRow(playerIndex: 1,
                         label: round.otherPlayerNames[safe: 0].flatMap { $0.isEmpty ? nil : String($0.prefix(6)) } ?? "Partner")
        // Opponent rows
        if round.otherPlayerNames.count >= 2 {
            opponentScoreRow(playerIndex: 2,
                             label: round.otherPlayerNames[safe: 1].flatMap { $0.isEmpty ? nil : String($0.prefix(6)) } ?? "Gegner 1")
        }
        if round.otherPlayerNames.count >= 3 {
            opponentScoreRow(playerIndex: 3,
                             label: round.otherPlayerNames[safe: 2].flatMap { $0.isEmpty ? nil : String($0.prefix(6)) } ?? "Gegner 2")
        }
        // Result row
        betterBallMatchplayResultRow
    }

    private var betterBallMatchplayResultRow: some View {
        HStack(spacing: 0) {
            Text("Ergebnis")
                .frame(width: 50, alignment: .leading)
                .font(.caption).foregroundStyle(AppTheme.textSec)
            ForEach(sortedScores, id: \.holeNumber) { holeScore in
                let h = holeScore.holeNumber
                let partner = round.opponentScore(playerIndex: 1, holeNumber: h)
                let opp1 = round.opponentScore(playerIndex: 2, holeNumber: h)
                let opp2 = round.opponentScore(playerIndex: 3, holeNumber: h)
                let myBest: Int = {
                    if let p = partner, p.strokes > 0 { return min(holeScore.strokes, p.strokes) }
                    return holeScore.strokes
                }()
                let oppBest: Int = {
                    guard let o1 = opp1, o1.strokes > 0 else { return 0 }
                    if let o2 = opp2, o2.strokes > 0 { return min(o1.strokes, o2.strokes) }
                    return o1.strokes
                }()
                let outcome: HoleOutcome = oppBest > 0 && myBest > 0
                    ? GameScoringEngine.matchplayHoleOutcome(playerStrokes: myBest, opponentStrokes: oppBest)
                    : .notPlayed
                let (label, color): (String, Color) = switch outcome {
                case .player:    ("W", AppTheme.gold)
                case .opponent:  ("L", .red)
                case .halved:    ("H", .secondary)
                case .notPlayed: ("·", .secondary)
                }
                Text(label).frame(width: 34).font(.caption.bold()).foregroundStyle(color)
            }
            Text("").frame(width: 40, alignment: .trailing)
        }
        .frame(height: 26)
    }

    // MARK: - Best Ball rows

    @ViewBuilder
    private func bestBallAllPartnerRows(stableford: Bool) -> some View {
        ForEach(0..<round.otherPlayerNames.count, id: \.self) { i in
            let name = round.otherPlayerNames[i]
            opponentScoreRow(playerIndex: i + 1,
                             label: name.isEmpty ? "Sp.\(i+2)" : String(name.prefix(6)),
                             stableford: stableford)
        }
    }

    private func bestBallTeamRow(stableford: Bool) -> some View {
        HStack(spacing: 0) {
            Text("Best")
                .frame(width: 50, alignment: .leading)
                .font(.caption.bold()).foregroundStyle(AppTheme.text)
            ForEach(sortedScores, id: \.holeNumber) { holeScore in
                let idx = holeScore.holeNumber - 1
                guard let vals = round.course?.parValues, idx < vals.count else {
                    return AnyView(Text("·").frame(width: 34).font(.caption))
                }
                let val = GameScoringEngine.bestBallHoleValue(
                    round: round, holeScore: holeScore, par: vals[idx], stableford: stableford)
                let hasAny = holeScore.strokes > 0 ||
                    (1...3).contains { round.opponentScore(playerIndex: $0, holeNumber: holeScore.holeNumber)?.strokes ?? 0 > 0 }
                return AnyView(
                    Group {
                        if stableford {
                            Text(hasAny ? "\(val)" : "·")
                                .frame(width: 34)
                                .font(.caption.bold())
                                .foregroundStyle(val >= 3 ? AppTheme.gold : val == 0 ? .secondary : .primary)
                        } else {
                            let d = hasAny ? val - vals[idx] : 0
                            Text(hasAny ? "\(val)" : "·")
                                .frame(width: 34)
                                .font(.caption.bold())
                                .foregroundStyle(hasAny ? scoreFg(diff: d) : Color.secondary)
                        }
                    }
                )
            }
            let total = GameScoringEngine.bestBallTeamTotal(round: round, stableford: stableford)
            Text("\(total)").frame(width: 40, alignment: .trailing).font(.caption.bold()).foregroundStyle(AppTheme.gold)
        }
        .frame(height: 26)
    }

    // MARK: - Shared opponent score row

    private func opponentScoreRow(playerIndex: Int, label: String, stableford: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .frame(width: 50, alignment: .leading)
                .font(.caption).foregroundStyle(AppTheme.textSec)
            ForEach(sortedScores, id: \.holeNumber) { holeScore in
                let opp = round.opponentScore(playerIndex: playerIndex, holeNumber: holeScore.holeNumber)
                let strokes = opp?.strokes ?? 0
                if stableford {
                    let pts = strokes > 0 ? GameMode.stablefordPoints(strokes: strokes, par: par(for: holeScore)) : 0
                    Text(strokes > 0 ? "\(pts)" : "·")
                        .frame(width: 34).font(.caption)
                        .foregroundStyle(pts >= 3 ? AppTheme.gold : pts == 0 ? .secondary : .primary)
                } else {
                    let d = strokes > 0 ? strokes - par(for: holeScore) : 0
                    ZStack {
                        Circle().fill(scoreBg(diff: d, hasScore: strokes > 0)).frame(width: 22, height: 22)
                        Text(strokes > 0 ? "\(strokes)" : "·")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(strokes > 0 ? scoreFg(diff: d) : Color.secondary)
                    }
                    .frame(width: 34)
                }
            }
            Text("-").frame(width: 40, alignment: .trailing).font(.caption.bold())
        }
        .frame(height: 26)
    }

    // MARK: - Erado score row

    private var eradoScoreRow: some View {
        let result = GameScoringEngine.eradoResult(round: round)
        return HStack(spacing: 0) {
            Text("Erado")
                .frame(width: 50, alignment: .leading)
                .font(.caption.bold()).foregroundStyle(.purple)
            ForEach(Array(sortedScores.enumerated()), id: \.offset) { _, score in
                let scratched = result.scratchedHoles.contains(score.holeNumber)
                let d = score.strokes - par(for: score)
                ZStack {
                    if scratched {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 28, height: 20)
                    } else {
                        Circle().fill(scoreBg(diff: d, hasScore: score.strokes > 0)).frame(width: 22, height: 22)
                    }
                    Text(score.strokes > 0 ? "\(score.strokes)" : "·")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(scratched ? Color.purple : score.strokes > 0 ? scoreFg(diff: d) : Color.secondary)
                        .strikethrough(scratched)
                }
                .frame(width: 34)
            }
            Text(result.total > 0 ? "\(result.total)" : "-")
                .frame(width: 40, alignment: .trailing).font(.caption.bold()).foregroundStyle(.purple)
        }
        .frame(height: 26)
    }

    // MARK: - Color helpers

    private func scoreBg(diff: Int, hasScore: Bool) -> Color {
        guard hasScore else { return .clear }
        return diff < 0 ? AppTheme.gold.opacity(0.3) : diff > 0 ? .orange.opacity(0.25) : .clear
    }

    private func scoreFg(diff: Int) -> Color {
        diff < 0 ? AppTheme.gold : diff > 0 ? .orange : .primary
    }
}
