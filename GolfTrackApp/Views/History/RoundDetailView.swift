import SwiftUI
import MapKit

struct RoundDetailView: View {
    @Bindable var round: Round
    @State private var continuePlaying = false

    private var roundTotalDistanceM: Double {
        round.sortedScores.reduce(0) { $0 + $1.totalDistanceMeters }
    }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    statsGrid
                    scorecardSection
                    if !round.holeScores.flatMap({ $0.shots }).isEmpty {
                        RoundShotMapCard(round: round)
                    }
                    if roundTotalDistanceM > 0 { distanceSection }
                    if !round.notes.isEmpty { notesSection }
                }
                .padding()
            }
        }
        .navigationTitle(round.course?.name ?? "Runde")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    round.isComplete = false
                    continuePlaying = true
                } label: {
                    Label("Fortsetzen", systemImage: "pencil")
                }
                .foregroundStyle(AppTheme.gold)
            }
        }
        .navigationDestination(isPresented: $continuePlaying) {
            ScorecardView(round: round)
        }
    }

    private var summaryCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(round.course?.name ?? "Unbekannter Platz")
                    .font(.title3.bold())
                Text(round.date.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSec)
                if let course = round.course {
                    Text("\(course.numberOfHoles) Loch · Par \(course.totalPar)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                HStack(spacing: 4) {
                    Image(systemName: round.gameMode.sfSymbol)
                    Text(round.gameMode.displayName)
                }
                .font(.caption)
                .foregroundStyle(AppTheme.gold)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                mainScoreView
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var mainScoreView: some View {
        switch round.gameMode {
        case .matchplay:
            matchplayScoreSummary
        case .betterBallMatchplay:
            betterBallMatchplayScoreSummary
        case .stableford:
            Text("\(round.totalStablefordPoints)")
                .font(.largeTitle.bold()).foregroundStyle(AppTheme.gold)
            Text("Punkte").font(.subheadline).foregroundStyle(AppTheme.textSec)
        case .betterBallStroke:
            betterBallScoreSummary(stableford: false)
        case .betterBallStableford:
            betterBallScoreSummary(stableford: true)
        case .bestBallStroke:
            bestBallScoreSummary(stableford: false)
        case .bestBallStableford:
            bestBallScoreSummary(stableford: true)
        case .skins:
            skinsScoreSummary
        case .erado:
            eradoScoreSummary
        default:
            Text(round.scoreLabel)
                .font(.largeTitle.bold())
                .foregroundStyle(golfScoreColor(round.scoreToPar))
            Text("\(round.totalStrokes) Schläge")
                .font(.subheadline).foregroundStyle(AppTheme.textSec)
        }
    }

    private var matchplayScoreSummary: some View {
        let status = GameScoringEngine.matchplayStatus(round: round)
        let color: Color = status.playerLeads ? AppTheme.gold : status.opponentLeads ? .red : .primary
        return Text(status.statusLabel)
            .font(.headline.bold())
            .foregroundStyle(color)
            .multilineTextAlignment(.trailing)
    }

    private func betterBallScoreSummary(stableford: Bool) -> some View {
        let total = GameScoringEngine.betterBallTeamTotal(round: round, stableford: stableford)
        return VStack(alignment: .trailing, spacing: 4) {
            Text("\(total)")
                .font(.largeTitle.bold())
                .foregroundStyle(stableford ? AppTheme.gold : Color.primary)
            Text(stableford ? "Team Punkte" : "Team Schläge")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
        }
    }

    private var skinsScoreSummary: some View {
        let myTotal = GameScoringEngine.skinsResult(round: round).skinsPerPlayer[0] ?? 0
        return VStack(alignment: .trailing, spacing: 4) {
            Text("\(myTotal)")
                .font(.largeTitle.bold())
                .foregroundStyle(.orange)
            Text("Skins")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
        }
    }

    private var betterBallMatchplayScoreSummary: some View {
        let status = GameScoringEngine.betterBallMatchplayStatus(round: round)
        let color: Color = status.playerLeads ? AppTheme.gold : status.opponentLeads ? .red : .primary
        return Text(status.statusLabel)
            .font(.headline.bold())
            .foregroundStyle(color)
            .multilineTextAlignment(.trailing)
    }

    private func bestBallScoreSummary(stableford: Bool) -> some View {
        let total = GameScoringEngine.bestBallTeamTotal(round: round, stableford: stableford)
        return VStack(alignment: .trailing, spacing: 4) {
            Text("\(total)").font(.largeTitle.bold())
                .foregroundStyle(stableford ? AppTheme.gold : Color.primary)
            Text(stableford ? "Team Punkte" : "Best Ball Schläge")
                .font(.subheadline).foregroundStyle(AppTheme.textSec)
        }
    }

    private var eradoScoreSummary: some View {
        let result = GameScoringEngine.eradoResult(round: round)
        return VStack(alignment: .trailing, spacing: 4) {
            Text("\(result.total)").font(.largeTitle.bold()).foregroundStyle(.purple)
            Text("Erado Score").font(.subheadline).foregroundStyle(AppTheme.textSec)
            if !result.scratchedHoles.isEmpty {
                let holes = result.scratchedHoles.sorted().map { "L\($0)" }.joined(separator: ", ")
                Text("Streich: \(holes)").font(.caption).foregroundStyle(AppTheme.textSec)
            }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 0) {
            statCell("\(round.totalPutts)", label: "Putts")
            Divider().frame(height: 44)
            statCell(
                round.fairwayOpportunities > 0
                    ? "\(round.fairwaysHit)/\(round.fairwayOpportunities)"
                    : "-",
                label: "Fairways"
            )
            Divider().frame(height: 44)
            statCell(
                round.girOpportunities > 0
                    ? "\(round.greensInRegulation)/\(round.girOpportunities)"
                    : "-",
                label: "GIR"
            )
            Divider().frame(height: 44)
            statCell(
                round.girOpportunities > 0
                    ? String(format: "%.1f", Double(round.totalPutts) / Double(round.girOpportunities))
                    : "-",
                label: "Ø Putts"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statCell(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
    }

    private var scorecardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scorecard").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    tableRow(label: "Loch", values: round.sortedScores.map { "\($0.holeNumber)" }, total: "∑", bold: true)
                    Divider()
                    tableRow(label: "Par", values: parValues, total: "\(round.course?.totalPar ?? 0)", muted: true)
                    tableRow(label: "Score", values: [], total: "\(round.totalStrokes)", scoreRow: true)
                    modeSpecificDetailRows
                    Divider()
                    tableRow(label: "Putts", values: round.sortedScores.map { "\($0.putts)" }, total: "\(round.totalPutts)", muted: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    @ViewBuilder
    private var modeSpecificDetailRows: some View {
        switch round.gameMode {
        case .matchplay:
            let oppName = round.otherPlayerNames.first ?? "Gegner"
            tableRow(label: String(oppName.prefix(6)), values: [], total: "-", opponentRow: true, playerIndex: 1)
            tableRow(label: "Ergebnis", values: [], total: "", matchplayRow: true)
        case .stableford:
            tableRow(label: "Punkte",
                     values: round.sortedScores.map { s in
                         let idx = s.holeNumber - 1
                         guard let vals = round.course?.parValues, idx < vals.count else { return "·" }
                         return s.strokes > 0 ? "\(GameMode.stablefordPoints(strokes: s.strokes, par: vals[idx]))" : "·"
                     },
                     total: "\(round.totalStablefordPoints)")
        case .betterBallStroke, .betterBallStableford:
            let stableford = round.gameMode == .betterBallStableford
            let partnerName = round.otherPlayerNames.first ?? "Partner"
            tableRow(label: String(partnerName.prefix(6)), values: [], total: "-", opponentRow: true, playerIndex: 1)
            tableRow(label: "Team",
                     values: round.sortedScores.map { s in
                         let partner = round.opponentScore(playerIndex: 1, holeNumber: s.holeNumber)
                         let idx = s.holeNumber - 1
                         guard let vals = round.course?.parValues, idx < vals.count else { return "·" }
                         let played = s.strokes > 0 || (partner?.strokes ?? 0) > 0
                         guard played else { return "·" }
                         let val = GameScoringEngine.betterBallHoleValue(
                             holeScore: s, partnerScore: partner, par: vals[idx], stableford: stableford)
                         return "\(val)"
                     },
                     total: "\(GameScoringEngine.betterBallTeamTotal(round: round, stableford: stableford))",
                     bold: true)
        case .betterBallMatchplay:
            betterBallMatchplayDetailRows
        case .bestBallStroke, .bestBallStableford:
            let stableford = round.gameMode == .bestBallStableford
            tableRow(label: "Best",
                     values: round.sortedScores.map { s in
                         let idx = s.holeNumber - 1
                         guard let vals = round.course?.parValues, idx < vals.count else { return "·" }
                         let val = GameScoringEngine.bestBallHoleValue(
                             round: round, holeScore: s, par: vals[idx], stableford: stableford)
                         let hasAny = s.strokes > 0 || (1...3).contains {
                             (round.opponentScore(playerIndex: $0, holeNumber: s.holeNumber)?.strokes ?? 0) > 0
                         }
                         return hasAny ? "\(val)" : "·"
                     },
                     total: "\(GameScoringEngine.bestBallTeamTotal(round: round, stableford: stableford))",
                     bold: true)
        case .skins:
            let summary = GameScoringEngine.skinsResult(round: round)
            tableRow(label: "Skins",
                     values: round.sortedScores.map { s in
                         guard let idx = summary.holeWinners[s.holeNumber] else { return "·" }
                         if idx == -1 { return "=" }
                         if idx == 0 { return "Du" }
                         let name = round.otherPlayerNames[safe: idx - 1] ?? "G\(idx)"
                         return name.isEmpty ? "G\(idx)" : String(name.prefix(2))
                     },
                     total: "\(summary.skinsPerPlayer[0] ?? 0)")
        case .erado:
            let result = GameScoringEngine.eradoResult(round: round)
            tableRow(label: "Erado",
                     values: round.sortedScores.map { s in
                         result.scratchedHoles.contains(s.holeNumber) ? "(-)" : (s.strokes > 0 ? "\(s.strokes)" : "·")
                     },
                     total: "\(result.total)")
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var betterBallMatchplayDetailRows: some View {
        let names = round.otherPlayerNames
        let partnerLabel = names[safe: 0].flatMap { $0.isEmpty ? nil : String($0.prefix(6)) } ?? "Partner"
        let opp1Label = names[safe: 1].flatMap { $0.isEmpty ? nil : String($0.prefix(6)) } ?? "Gegner 1"
        tableRow(label: partnerLabel, values: [], total: "-", opponentRow: true, playerIndex: 1)
        tableRow(label: opp1Label, values: [], total: "-", opponentRow: true, playerIndex: 2)
        if names.count >= 3 {
            let opp2Label = names[safe: 2].flatMap { $0.isEmpty ? nil : String($0.prefix(6)) } ?? "Gegner 2"
            tableRow(label: opp2Label, values: [], total: "-", opponentRow: true, playerIndex: 3)
        }
        tableRow(label: "Ergebnis", values: [], total: "", matchplayRow: true, matchplayTeam: true)
    }

    private var parValues: [String] {
        guard let course = round.course else { return round.sortedScores.map { _ in "-" } }
        return round.sortedScores.map { score in
            let idx = score.holeNumber - 1
            guard idx >= 0, idx < course.parValues.count else { return "-" }
            return "\(course.parValues[idx])"
        }
    }

    private func parInt(for score: HoleScore) -> Int {
        guard let course = round.course,
              score.holeNumber - 1 < course.parValues.count else { return 4 }
        return course.parValues[score.holeNumber - 1]
    }

    private func tableRow(
        label: String,
        values: [String],
        total: String,
        bold: Bool = false,
        muted: Bool = false,
        scoreRow: Bool = false,
        opponentRow: Bool = false,
        playerIndex: Int = 1,
        stablefordRow: Bool = false,
        matchplayRow: Bool = false,
        matchplayTeam: Bool = false
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .frame(width: 52, alignment: .leading)
                .font(bold ? .caption.bold() : .caption)
                .foregroundStyle(muted ? .secondary : .primary)

            if scoreRow {
                ForEach(round.sortedScores, id: \.holeNumber) { score in
                    let d = score.strokes - parInt(for: score)
                    ZStack {
                        Circle()
                            .fill(d < 0 ? AppTheme.gold.opacity(0.25) : d > 0 ? Color.orange.opacity(0.2) : Color.clear)
                            .frame(width: 24, height: 24)
                        Text("\(score.strokes)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(d < 0 ? AppTheme.gold : d > 0 ? .orange : .primary)
                    }
                    .frame(width: 34)
                }
            } else if opponentRow {
                ForEach(round.sortedScores, id: \.holeNumber) { holeScore in
                    let opp = round.opponentScore(playerIndex: playerIndex, holeNumber: holeScore.holeNumber)
                    let s = opp?.strokes ?? 0
                    if stablefordRow {
                        let pts = s > 0 ? GameMode.stablefordPoints(strokes: s, par: parInt(for: holeScore)) : 0
                        Text(s > 0 ? "\(pts)" : "·")
                            .frame(width: 34).font(.caption)
                            .foregroundStyle(pts >= 3 ? AppTheme.gold : pts == 0 ? .secondary : .primary)
                    } else {
                        let d = s > 0 ? s - parInt(for: holeScore) : 0
                        ZStack {
                            Circle()
                                .fill(s > 0 ? (d < 0 ? AppTheme.gold.opacity(0.25) : d > 0 ? Color.orange.opacity(0.2) : Color.clear) : Color.clear)
                                .frame(width: 24, height: 24)
                            Text(s > 0 ? "\(s)" : "·")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(s > 0 ? (d < 0 ? AppTheme.gold : d > 0 ? .orange : .primary) : Color.secondary)
                        }
                        .frame(width: 34)
                    }
                }
            } else if matchplayRow && matchplayTeam {
                ForEach(round.sortedScores, id: \.holeNumber) { holeScore in
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
                    let (lbl, color): (String, Color) = switch outcome {
                    case .player:    ("W", AppTheme.gold)
                    case .opponent:  ("L", .red)
                    case .halved:    ("H", .secondary)
                    case .notPlayed: ("·", .secondary)
                    }
                    Text(lbl).frame(width: 34).font(.caption.bold()).foregroundStyle(color)
                }
            } else if matchplayRow {
                ForEach(round.sortedScores, id: \.holeNumber) { holeScore in
                    let opp = round.opponentScore(playerIndex: 1, holeNumber: holeScore.holeNumber)
                    let outcome = GameScoringEngine.matchplayHoleOutcome(
                        playerStrokes: holeScore.strokes,
                        opponentStrokes: opp?.strokes ?? 0)
                    let (lbl, color): (String, Color) = switch outcome {
                    case .player:    ("W", AppTheme.gold)
                    case .opponent:  ("L", .red)
                    case .halved:    ("H", .secondary)
                    case .notPlayed: ("·", .secondary)
                    }
                    Text(lbl)
                        .frame(width: 34)
                        .font(.caption.bold())
                        .foregroundStyle(color)
                }
            } else {
                ForEach(Array(values.enumerated()), id: \.offset) { _, val in
                    Text(val)
                        .frame(width: 34)
                        .font(bold ? .caption.bold() : .caption)
                        .foregroundStyle(muted ? .secondary : .primary)
                }
            }

            Text(total)
                .frame(width: 40, alignment: .trailing)
                .font(.caption.bold())
        }
        .frame(height: 30)
    }

    // MARK: - Distance section

    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Distanzen (GPS)", systemImage: "figure.walk")
                    .font(.headline)
                Spacer()
                Text(formatMeters(roundTotalDistanceM))
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.gold)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(round.sortedScores.filter { $0.totalDistanceMeters > 0 }, id: \.holeNumber) { score in
                        VStack(spacing: 4) {
                            Text("L\(score.holeNumber)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSec)
                            Text(formatMeters(score.totalDistanceMeters))
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.text)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(AppTheme.cardDark, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func formatMeters(_ m: Double) -> String {
        m >= 1000
            ? String(format: "%.2f km", m / 1000)
            : String(format: "%.0f m", m)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notizen").font(.headline)
            Text(round.notes)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
