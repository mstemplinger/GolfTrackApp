import SwiftUI
import MapKit

/// Zeigt die aufgezeichnete Laufspur einer Runde auf der Karte – inkl. Einstieg
/// in die Ableitung der Loch-Positionen für den Platz.
struct RoundTrackMapCard: View {
    let round: Round

    @State private var segments: [TrackSegment] = []
    @State private var stats: TrackStats?
    @State private var isExpanded = false
    @State private var isSatellite = true
    @State private var showGeometryReview = false
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    struct TrackSegment: Identifiable {
        let id: Int          // Lochnummer, 0 = ohne Lochzuordnung
        let coordinates: [CLLocationCoordinate2D]
        let color: Color
    }

    struct TrackStats {
        let distanceMeters: Double
        let duration: TimeInterval
        let pointCount: Int
        let holeCount: Int
    }

    // Gleiche Farbfolge wie in RoundShotMapCard, damit Schlag- und Laufkarte zusammenpassen.
    private static let palette: [Color] = [
        Color(red: 0.20, green: 0.52, blue: 0.96),
        Color(red: 0.96, green: 0.52, blue: 0.20),
        Color(red: 0.22, green: 0.78, blue: 0.38),
        Color(red: 0.78, green: 0.30, blue: 0.96),
        Color(red: 0.96, green: 0.28, blue: 0.28),
        Color(red: 0.10, green: 0.80, blue: 0.78),
        Color(red: 0.85, green: 0.70, blue: 0.20),
        Color(red: 0.40, green: 0.80, blue: 0.40),
        Color(red: 0.90, green: 0.40, blue: 0.60),
        Color(red: 0.40, green: 0.40, blue: 0.90),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Laufspur", systemImage: "figure.walk")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Spacer()
                if !segments.isEmpty {
                    Button { isExpanded = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                            Text("Vollbild")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.gold)
                    }
                }
            }

            if segments.isEmpty {
                Text("Für diese Runde liegen noch keine verwertbaren GPS-Punkte vor.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            } else {
                mapContent(interactive: false)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)

                if let stats {
                    HStack(spacing: 14) {
                        statItem(icon: "figure.walk", value: distanceUnit.format(stats.distanceMeters))
                        statItem(icon: "clock", value: durationText(stats.duration))
                        statItem(icon: "flag", value: "\(stats.holeCount) Löcher")
                        statItem(icon: "dot.radiowaves.up.forward", value: "\(stats.pointCount) Punkte")
                    }
                }

                if round.course != nil {
                    Button { showGeometryReview = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "wand.and.stars")
                            Text("Loch-Positionen ableiten")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .task { load() }
        .fullScreenCover(isPresented: $isExpanded) { expandedView }
        .sheet(isPresented: $showGeometryReview) {
            if let course = round.course {
                CourseGeometryReviewView(course: course)
            }
        }
    }

    // MARK: - Aufbereitung

    private func load() {
        guard let track = round.track else { return }
        let points = track.points.filter(\.isValid).sorted { $0.timeOffset < $1.timeOffset }
        guard points.count > 1 else { return }

        // Nach Loch gruppieren, Reihenfolge der Löcher wie gespielt.
        var order: [Int] = []
        var grouped: [Int: [CLLocationCoordinate2D]] = [:]
        for point in points {
            if grouped[point.holeNumber] == nil {
                grouped[point.holeNumber] = []
                order.append(point.holeNumber)
            }
            grouped[point.holeNumber]?.append(point.coordinate)
        }

        segments = order.enumerated().compactMap { index, hole in
            guard let coords = grouped[hole], coords.count > 1 else { return nil }
            return TrackSegment(id: hole,
                                coordinates: coords,
                                color: hole == 0 ? AppTheme.textTer : Self.palette[index % Self.palette.count])
        }

        stats = TrackStats(distanceMeters: track.totalDistanceMeters,
                           duration: track.duration,
                           pointCount: points.count,
                           holeCount: order.filter { $0 > 0 }.count)
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? "\(hours) h \(minutes) min" : "\(minutes) min"
    }

    // MARK: - Bausteine

    private func statItem(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppTheme.gold)
            Text(value)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSec)
        }
    }

    @ViewBuilder
    private func mapContent(interactive: Bool) -> some View {
        Map(initialPosition: .automatic) {
            ForEach(segments) { segment in
                MapPolyline(coordinates: segment.coordinates)
                    .stroke(segment.color.opacity(0.85), lineWidth: 3)
            }
            if let start = segments.first?.coordinates.first {
                Annotation(String(localized: "Start"), coordinate: start) {
                    Circle()
                        .fill(.green)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
            if let end = segments.last?.coordinates.last {
                Annotation(String(localized: "Ende"), coordinate: end) {
                    Circle()
                        .fill(.red)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
        }
        .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard)
        .mapControls {
            if interactive {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
        }
    }

    private var expandedView: some View {
        NavigationStack {
            mapContent(interactive: true)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Laufspur")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Schließen") { isExpanded = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isSatellite.toggle()
                        } label: {
                            Image(systemName: isSatellite ? "map" : "globe.europe.africa")
                        }
                    }
                }
        }
    }
}
