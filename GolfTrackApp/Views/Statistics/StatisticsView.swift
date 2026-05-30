import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(
        filter: #Predicate<Round> { $0.isComplete },
        sort: \Round.date,
        order: .reverse
    ) private var rounds: [Round]

    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    private var last10: [Round] { Array(rounds.prefix(10).reversed()) }

    private var allShots: [Shot] {
        rounds.flatMap { $0.holeScores.flatMap { $0.shots } }
    }

    private var clubStats: [(club: String, avgMeters: Double, count: Int)] {
        let valid = allShots.filter { !$0.club.isEmpty && $0.distanceMeters > 1 }
        let grouped = Dictionary(grouping: valid) { $0.club }
        return grouped.map { club, shots in
            let avg = shots.reduce(0) { $0 + $1.distanceMeters } / Double(shots.count)
            return (club: club, avgMeters: avg, count: shots.count)
        }
        .sorted { $0.avgMeters > $1.avgMeters }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView {
                VStack(spacing: 16) {
                    if rounds.isEmpty {
                        ContentUnavailableView(
                            "Keine Statistiken",
                            systemImage: "chart.bar",
                            description: Text("Spiele Runden, um Statistiken zu sehen")
                        )
                    } else {
                        overviewGrid
                        if last10.count >= 2 { trendChart }
                        averagesCard
                        if !clubStats.isEmpty { clubDistanceCard }
                    }
                }
                .padding()
            }
            } // ZStack
            .navigationTitle("Statistiken")
        }
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Runden gespielt", value: "\(rounds.count)", icon: "flag.fill", color: AppTheme.gold)
            StatCard(title: "Handicap (WHS)", value: HandicapCalculator.displayString(from: rounds), icon: "trophy.fill", color: .yellow)
            StatCard(title: "Bestleistung", value: bestScore, icon: "star.fill", color: .orange)
            StatCard(title: "Ø Score vs. Par", value: avgScore, icon: "chart.line.uptrend.xyaxis", color: .blue)
            StatCard(title: "Ø Putts/Runde", value: avgPutts, icon: "circle.fill", color: .purple)
            StatCard(title: "GIR", value: girAvg, icon: "scope", color: AppTheme.gold)
        }
    }

    private var girAvg: String {
        let rs = rounds.filter { $0.girOpportunities > 0 }
        guard !rs.isEmpty else { return "–" }
        let pct = Double(rs.reduce(0) { $0 + $1.greensInRegulation }) /
                  Double(rs.reduce(0) { $0 + $1.girOpportunities }) * 100
        return String(format: "%.0f%%", pct)
    }

    private var bestScore: String {
        guard let best = rounds.compactMap(\.scoreToPar).min() else { return "-" }
        if best < 0 { return "\(best)" }
        if best == 0 { return "E" }
        return "+\(best)"
    }

    private var avgScore: String {
        let scores = rounds.compactMap(\.scoreToPar)
        guard !scores.isEmpty else { return "-" }
        let avg = Double(scores.reduce(0, +)) / Double(scores.count)
        return avg < 0 ? String(format: "%.1f", avg) : String(format: "+%.1f", avg)
    }

    private var avgPutts: String {
        guard !rounds.isEmpty else { return "-" }
        let total = rounds.reduce(0) { $0 + $1.totalPutts }
        return String(format: "%.1f", Double(total) / Double(rounds.count))
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Score-Verlauf (letzte \(last10.count) Runden)")
                .font(.headline)

            Chart {
                RuleMark(y: .value("Par", 0))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .lineStyle(StrokeStyle(dash: [6, 4]))

                ForEach(Array(last10.enumerated()), id: \.offset) { i, round in
                    if let score = round.scoreToPar {
                        AreaMark(
                            x: .value("Runde", i + 1),
                            yStart: .value("Par", 0),
                            yEnd: .value("Score", score)
                        )
                        .foregroundStyle(score < 0 ? AppTheme.gold.opacity(0.15) : Color.orange.opacity(0.1))

                        LineMark(
                            x: .value("Runde", i + 1),
                            y: .value("Score", score)
                        )
                        .foregroundStyle(AppTheme.gold)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Runde", i + 1),
                            y: .value("Score", score)
                        )
                        .foregroundStyle(AppTheme.gold)
                        .annotation(position: score < 0 ? .bottom : .top) {
                            Text(score < 0 ? "\(score)" : score == 0 ? "E" : "+\(score)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let i = value.as(Int.self), let round = last10[safe: i - 1] {
                            Text(round.date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private var averagesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Durchschnittswerte").font(.headline)

            let fwRounds = rounds.filter { $0.fairwayOpportunities > 0 }
            statRow(
                "Fairways getroffen",
                value: fwRounds.isEmpty ? "-" : {
                    let pct = Double(fwRounds.reduce(0) { $0 + $1.fairwaysHit }) /
                              Double(fwRounds.reduce(0) { $0 + $1.fairwayOpportunities }) * 100
                    return String(format: "%.0f%%", pct)
                }()
            )
            Divider()

            let girRounds = rounds.filter { $0.girOpportunities > 0 }
            statRow(
                "Greens in Regulation",
                value: girRounds.isEmpty ? "-" : {
                    let pct = Double(girRounds.reduce(0) { $0 + $1.greensInRegulation }) /
                              Double(girRounds.reduce(0) { $0 + $1.girOpportunities }) * 100
                    return String(format: "%.0f%%", pct)
                }()
            )
            Divider()

            let totalStrokes = rounds.reduce(0) { $0 + $1.totalStrokes }
            statRow(
                "Ø Schläge pro Runde",
                value: rounds.isEmpty ? "-" : String(format: "%.1f", Double(totalStrokes) / Double(rounds.count))
            )
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private var clubDistanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Schlägerdistanzen (Ø)", systemImage: "figure.golf")
                .font(.headline)

            ForEach(Array(clubStats.enumerated()), id: \.offset) { i, stat in
                if i > 0 { Divider() }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.club)
                            .font(.subheadline.bold())
                        Text("\(stat.count) Schlag\(stat.count == 1 ? "" : "schläge") gemessen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(distanceUnit.format(stat.avgMeters))
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
