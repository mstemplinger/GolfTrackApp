import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// Übersicht über die ganze Runde: Karte mit allen bekannten Fairways, dazu
/// Par, HCP, Länge und Score je Loch.
///
/// Erreichbar durch Tippen auf die Gesamtscore-Leiste in `HoleScoringView`.
struct RoundTrackingOverviewSheet: View {
    let round: Round
    /// Loch, das beim Öffnen hervorgehoben wird.
    let currentHole: Int

    @Environment(\.dismiss) private var dismiss
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    @State private var corridors: [HoleCorridor] = []
    @State private var isLoading = true

    private var course: Course? { round.course }
    private var scores: [HoleScore] { round.sortedScores }

    private var playedHoles: Int { round.playedScores.count }

    /// Ganze Laufspur der Runde, nach Loch gruppiert (für farbige Abschnitte).
    private var walkSegments: [(hole: Int, coordinates: [CLLocationCoordinate2D])] {
        guard let track = round.track else { return [] }
        let grouped = Dictionary(grouping: track.points.filter(\.isValid), by: \.holeNumber)
        return grouped
            .sorted { $0.key < $1.key }
            .compactMap { hole, points in
                let coords = points.sorted { $0.timeOffset < $1.timeOffset }.map(\.coordinate)
                return coords.count > 1 ? (hole, coords) : nil
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                if isLoading {
                    ProgressView("Platz wird ausgewertet …")
                        .tint(AppTheme.gold)
                        .foregroundStyle(AppTheme.textSec)
                } else {
                    VStack(spacing: 0) {
                        map
                            .frame(height: 340)
                        summaryBar
                        holeTable
                    }
                }
            }
            .navigationTitle("Runde im Überblick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await Task.yield()
            if let course { corridors = FairwayCorridorInference.currentCorridors(for: course) }
            isLoading = false
        }
    }

    // MARK: - Karte

    private var map: some View {
        Map(initialPosition: .automatic) {
            UserAnnotation()

            // Alle bekannten Fairways
            ForEach(corridors) { corridor in
                if corridor.corridorPolygon.count >= 4 {
                    MapPolygon(coordinates: corridor.corridorPolygon)
                        .foregroundStyle(AppTheme.gold.opacity(corridor.holeNumber == currentHole ? 0.30 : 0.16))
                        .stroke(AppTheme.gold.opacity(corridor.holeNumber == currentHole ? 0.85 : 0.45),
                                lineWidth: corridor.holeNumber == currentHole ? 2.5 : 1.5)
                }
                if corridor.centerline.count >= 2 {
                    MapPolyline(coordinates: corridor.centerline)
                        .stroke(AppTheme.gold.opacity(corridor.holeNumber == currentHole ? 1 : 0.55),
                                lineWidth: corridor.holeNumber == currentHole ? 3 : 2)
                }
            }

            // Gelaufene Spur der Runde
            ForEach(walkSegments, id: \.hole) { segment in
                MapPolyline(coordinates: segment.coordinates)
                    .stroke(.cyan.opacity(0.75), lineWidth: 2.5)
            }

            // Loch-Nummern an den Abschlägen
            if let course {
                ForEach(1...max(1, course.numberOfHoles), id: \.self) { hole in
                    if let tee = course.teeCoordinate(forHole: hole) {
                        Annotation("", coordinate: tee) {
                            let isCurrent = hole == currentHole
                            ZStack {
                                Circle()
                                    .fill(isCurrent ? AppTheme.gold : AppTheme.cardDark)
                                    .frame(width: isCurrent ? 28 : 22, height: isCurrent ? 28 : 22)
                                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                                Text("\(hole)")
                                    .font(.system(size: isCurrent ? 13 : 11, weight: .bold))
                                    .foregroundStyle(isCurrent ? Color(red: 0.10, green: 0.22, blue: 0.13) : .white)
                            }
                            .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                        }
                    }
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .mapControls { MapUserLocationButton() }
    }

    // MARK: - Kennzahlen

    private var summaryBar: some View {
        HStack(spacing: 0) {
            summaryItem(value: round.scoreLabel, label: "Score",
                        color: AppTheme.scoreColor(round.scoreToPar))
            divider
            summaryItem(value: "\(round.totalStrokes)", label: "Schläge")
            divider
            summaryItem(value: "\(course?.totalPar ?? 0)", label: "Par gesamt")
            divider
            summaryItem(value: "\(playedHoles)/\(scores.count)", label: "gespielt")
            if let track = round.track, track.pointCount > 1 {
                divider
                summaryItem(value: distanceUnit.format(track.totalDistanceMeters), label: "gelaufen")
            }
        }
        .padding(.vertical, 12)
        .background(AppTheme.cardDark)
    }

    private var divider: some View {
        Rectangle().fill(AppTheme.cardAlt).frame(width: 1, height: 26)
    }

    private func summaryItem(value: String, label: LocalizedStringKey,
                             color: Color = AppTheme.text) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTer)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Lochtabelle

    private var holeTable: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                ForEach(scores, id: \.holeNumber) { score in
                    row(for: score)
                    if score.holeNumber != scores.last?.holeNumber {
                        Divider().background(AppTheme.cardAlt).padding(.leading, 16)
                    }
                }
            }
            .background(AppTheme.card)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text("Loch").frame(width: 52, alignment: .leading)
            Text("Par").frame(width: 44, alignment: .trailing)
            Text("HCP").frame(width: 48, alignment: .trailing)
            Text("Länge").frame(maxWidth: .infinity, alignment: .trailing)
            Text("Score").frame(width: 62, alignment: .trailing)
            Text("Fairway").frame(width: 62, alignment: .trailing)
        }
        .font(.caption2.bold())
        .foregroundStyle(AppTheme.textTer)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func row(for score: HoleScore) -> some View {
        let hole = score.holeNumber
        let par = course.flatMap { hole - 1 < $0.parValues.count ? $0.parValues[hole - 1] : nil } ?? 4
        let hcp = course.flatMap { hole - 1 < $0.hcpValues.count ? $0.hcpValues[hole - 1] : nil }
        let length = course.flatMap { hole - 1 < $0.holeLengths.count ? $0.holeLengths[hole - 1] : nil }
        let corridor = corridors.first { $0.holeNumber == hole }
        let isCurrent = hole == currentHole

        return HStack(spacing: 0) {
            HStack(spacing: 5) {
                Text("\(hole)")
                    .font(.subheadline.bold())
                    .foregroundStyle(isCurrent ? AppTheme.gold : AppTheme.text)
                if isCurrent {
                    Circle().fill(AppTheme.gold).frame(width: 5, height: 5)
                }
            }
            .frame(width: 52, alignment: .leading)

            Text("\(par)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .frame(width: 44, alignment: .trailing)

            Text(hcp.map(String.init) ?? "–")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textTer)
                .frame(width: 48, alignment: .trailing)

            Text((length ?? 0) > 0 ? distanceUnit.format(Double(length!)) : "–")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(score.strokes > 0 ? "\(score.strokes)" : "–")
                .font(.subheadline.bold())
                .foregroundStyle(score.strokes > 0
                                 ? AppTheme.scoreColor(score.strokes - par)
                                 : AppTheme.textTer)
                .frame(width: 62, alignment: .trailing)

            // Zeigt, ob für dieses Loch ein Fairway-Verlauf vorliegt
            Group {
                if let corridor {
                    Image(systemName: corridor.reliability == .good
                          ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(corridor.reliability == .good ? AppTheme.green : AppTheme.gold)
                } else {
                    Image(systemName: "minus")
                        .foregroundStyle(AppTheme.textTer)
                }
            }
            .font(.caption)
            .frame(width: 62, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(isCurrent ? AppTheme.gold.opacity(0.07) : .clear)
    }
}
