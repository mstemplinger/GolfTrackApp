import SwiftUI
import SwiftData
import Charts

// MARK: - Zusammenfassung nach einer Einheit

/// Erscheint nach „Einheit beenden“: je Schläger Ø und Bestweite von heute,
/// verglichen mit allen Einheiten davor.
struct RangeSessionSummaryView: View {
    let session: RangeSession
    let earlierShots: [RangeShot]

    @Environment(\.dismiss) private var dismiss
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    var body: some View {
        let today = RangeClubStats.byClub(session.shots)
        let earlier = RangeClubStats.byClub(earlierShots)
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Image(systemName: "figure.golf")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.gold)
                        Text("Einheit gespeichert")
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.text)
                        Text("Bälle: \(session.shots.count) · Schläger: \(today.count)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .padding(.vertical, 8)

                    VStack(spacing: 0) {
                        ForEach(session.clubNames, id: \.self) { club in
                            if let stats = today[club] {
                                RangeClubCompareRow(stats: stats, earlier: earlier[club], unit: distanceUnit)
                                if club != session.clubNames.last {
                                    Divider().background(AppTheme.cardAlt)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .cardStyle()
                }
                .padding()
                .readableContentWidth()
            }
            .background(AppTheme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        Haptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.gold)
                }
            }
        }
    }
}

/// Eine Zeile „Schläger – Ø heute – Unterschied zu früher – Bestweite“.
struct RangeClubCompareRow: View {
    let stats: RangeClubStats
    let earlier: RangeClubStats?
    let unit: DistanceUnit

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stats.clubName)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Text("Bälle: \(stats.count) · Bestweite \(unit.format(stats.best))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer()
            if let earlier, stats.best > earlier.best {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.gold)
                    .accessibilityLabel("Neue Bestweite")
            }
            VStack(alignment: .trailing, spacing: 2) {
                Text("Ø \(unit.format(stats.average))")
                    .font(.subheadline.bold())
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.text)
                if let earlier {
                    let diff = unit.value(stats.average) - unit.value(earlier.average)
                    Text(verbatim: diff >= 0 ? "+\(diff) \(unit.unitLabel)" : "\(diff) \(unit.unitLabel)")
                        .font(.caption.bold())
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.scoreColor(diff >= 0 ? -1 : 1))
                } else {
                    Text("Neu")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Verlauf

/// Entwicklung je Schläger über alle Einheiten plus Liste der Einheiten.
struct RangeHistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RangeSession.date) private var sessions: [RangeSession]
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters
    @State private var chartClub = ""
    @State private var sessionToDelete: RangeSession?

    private var finished: [RangeSession] { sessions.filter { !$0.shots.isEmpty } }

    /// Schläger nach Häufigkeit – der meistgeschlagene steht vorn.
    private var clubs: [RangeClubStats] {
        RangeClubStats.byClub(finished.flatMap(\.shots)).values
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.clubName < $1.clubName }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if finished.isEmpty {
                    emptyState
                } else {
                    trendCard
                    clubsCard
                    sessionsCard
                }
            }
            .padding()
            .readableContentWidth()
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle("Range-Verlauf")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if chartClub.isEmpty { chartClub = clubs.first?.clubName ?? "" }
        }
        .alert("Einheit löschen?", isPresented: Binding(
            get: { sessionToDelete != nil },
            set: { if !$0 { sessionToDelete = nil } }
        )) {
            Button("Löschen", role: .destructive) {
                Haptics.warning()
                if let s = sessionToDelete { context.delete(s) }
                sessionToDelete = nil
            }
            Button("Abbrechen", role: .cancel) {
                Haptics.tap()
                sessionToDelete = nil
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.golf")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.gold)
            Text("Noch keine Range-Einheit")
                .font(.headline)
                .foregroundStyle(AppTheme.text)
            Text("Trage auf der Driving Range Schläger und Weite ein – hier siehst du dann, wie du dich entwickelst.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: Diagramm

    private struct TrendPoint: Identifiable {
        let date: Date
        let average: Double
        let best: Double
        var id: Date { date }
    }

    private var trend: [TrendPoint] {
        finished.compactMap { s in
            let d = s.shots.filter { $0.clubName == chartClub }.map(\.distanceMeters)
            guard let stats = RangeClubStats(clubName: chartClub, distances: d) else { return nil }
            return TrendPoint(date: s.date, average: Double(distanceUnit.value(stats.average)),
                              best: Double(distanceUnit.value(stats.best)))
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Entwicklung")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Menu {
                    ForEach(clubs) { club in
                        Button(club.clubName) {
                            Haptics.selection()
                            chartClub = club.clubName
                        }
                    }
                } label: {
                    Label(chartClub, systemImage: "chevron.up.chevron.down")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.gold)
                }
            }

            if trend.count >= 2 {
                Chart(trend) { p in
                    LineMark(x: .value("Datum", p.date), y: .value("Ø", p.average))
                        .foregroundStyle(by: .value("Wert", String(localized: "Durchschnitt")))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Datum", p.date), y: .value("Ø", p.average))
                        .foregroundStyle(by: .value("Wert", String(localized: "Durchschnitt")))
                    LineMark(x: .value("Datum", p.date), y: .value("Bestweite", p.best))
                        .foregroundStyle(by: .value("Wert", String(localized: "Bestweite")))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
                .chartForegroundStyleScale([
                    String(localized: "Durchschnitt"): AppTheme.gold,
                    String(localized: "Bestweite"): AppTheme.green
                ])
                .chartYAxisLabel(distanceUnit.unitLabel)
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 200)
            } else {
                Text("Ab zwei Einheiten mit diesem Schläger siehst du hier deine Entwicklung.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: Schläger

    private var clubsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Deine Weiten")
                .font(.headline)
                .foregroundStyle(AppTheme.text)
                .padding(.bottom, 6)
            ForEach(clubs) { club in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(club.clubName)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.text)
                        Text("Bälle: \(club.count)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Ø \(distanceUnit.format(club.average))")
                            .font(.subheadline.bold())
                            .monospacedDigit()
                            .foregroundStyle(AppTheme.text)
                        Text("Bestweite \(distanceUnit.format(club.best))")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: Einheiten

    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Einheiten")
                .font(.headline)
                .foregroundStyle(AppTheme.text)
                .padding(.bottom, 6)
            ForEach(finished.reversed()) { s in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.text)
                        Text("Bälle: \(s.shots.count) · \(s.clubNames.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button {
                        Haptics.tap()
                        sessionToDelete = s
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(AppTheme.textTer)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Einheit löschen")
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .cardStyle()
    }
}
