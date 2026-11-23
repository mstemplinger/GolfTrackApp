import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// Übersicht zu einem einzelnen Loch während der Runde: was das Tracking über
/// dieses Loch weiß und wo man aktuell steht.
///
/// Erreichbar durch Tippen auf die Entfernungskarte in `HoleScoringView`.
struct HoleTrackingOverviewSheet: View {
    let round: Round
    @Bindable var score: HoleScore
    let par: Int

    @Environment(\.dismiss) private var dismiss
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    @State private var corridor: HoleCorridor?
    @State private var isLoading = true
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var playerCoord: CLLocationCoordinate2D? = CLLocationManager().location?.coordinate
    @State private var mapSize: CGSize = .zero

    private var course: Course? { round.course }
    private var hole: Int { score.holeNumber }

    private var tee: CLLocationCoordinate2D? { course?.teeCoordinate(forHole: hole, tee: round.teeColor) }
    private var green: CLLocationCoordinate2D? { course?.flagCoordinate(forHole: hole) }

    private var pin: CLLocationCoordinate2D? {
        guard let lat = score.pinLatitude, let lon = score.pinLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Laufspur dieses Lochs aus der aktuellen Runde. Während des Spiels puffert
    /// der Tracking-Service ein paar Punkte, die letzten Meter fehlen also ggf.
    private var walk: [CLLocationCoordinate2D] {
        guard let track = round.track else { return [] }
        return track.points(forHole: hole)
            .filter(\.isValid)
            .sorted { $0.timeOffset < $1.timeOffset }
            .map(\.coordinate)
    }

    private var scorecardLength: Int? {
        guard let course, hole - 1 < course.holeLengths.count else { return nil }
        let value = course.holeLengths[hole - 1]
        return value > 0 ? value : nil
    }

    private var hcp: Int? {
        guard let course, hole - 1 < course.hcpValues.count else { return nil }
        return course.hcpValues[hole - 1]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    if isLoading {
                        Spacer()
                        ProgressView().tint(AppTheme.gold)
                        Spacer()
                    } else {
                        map
                            .frame(maxHeight: .infinity)
                        infoPanel
                    }
                }
            }
            .navigationTitle("Loch \(hole)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") {
                        Haptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await Task.yield()
            if let course {
                corridor = FairwayCorridorInference.currentCorridors(for: course)
                    .first { $0.holeNumber == hole }
            }
            isLoading = false
            alignToHole(animated: false)
        }
        .livePlayerLocation($playerCoord)
        .onChange(of: playerCoord?.latitude) { _, _ in
            if !cameraPosition.positionedByUser { alignToHole(animated: true) }
        }
    }

    // MARK: - Ausrichtung

    /// Unten mittig Abschlag (nach dem ersten Schlag die eigene Position),
    /// oben mittig das Loch – Fairway, Spur und Schläge passen mit hinein.
    private func alignToHole(animated: Bool) {
        guard let top = pin ?? green,
              let bottom = HoleCameraFraming.bottomPoint(
                tee: tee, hole: top, player: playerCoord,
                hasPlayed: score.strokes > 0 || !score.shots.isEmpty) else { return }
        var extra: [CLLocationCoordinate2D] = []
        if bottom.latitude == tee?.latitude, bottom.longitude == tee?.longitude {
            extra += corridor?.corridorPolygon ?? []
            extra += score.sortedShots.flatMap { [$0.fromCoordinate, $0.toCoordinate] }
        }
        let size = mapSize == .zero ? CGSize(width: 390, height: 520) : mapSize
        guard let camera = HoleCameraFraming.camera(bottom: bottom, top: top,
                                                    including: extra, viewSize: size) else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.6)) { cameraPosition = .camera(camera) }
        } else {
            cameraPosition = .camera(camera)
        }
    }

    // MARK: - Karte

    private var map: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            if let corridor, corridor.corridorPolygon.count >= 4 {
                MapPolygon(coordinates: corridor.corridorPolygon)
                    .foregroundStyle(AppTheme.gold.opacity(0.20))
                    .stroke(AppTheme.gold.opacity(0.6), lineWidth: 2)
            }
            if let corridor, corridor.centerline.count >= 2 {
                MapPolyline(coordinates: corridor.centerline)
                    .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }

            // Laufspur dieser Runde
            if walk.count >= 2 {
                MapPolyline(coordinates: walk)
                    .stroke(.cyan.opacity(0.9), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }

            // Getrackte Schläge
            ForEach(score.sortedShots, id: \.shotNumber) { shot in
                MapPolyline(coordinates: [shot.fromCoordinate, shot.toCoordinate])
                    .stroke(.white.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                Annotation("", coordinate: shot.fromCoordinate) {
                    ZStack {
                        Circle().fill(.white).frame(width: 20, height: 20)
                        Text("\(shot.shotNumber)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.bg)
                    }
                }
            }

            if let tee {
                Annotation(String(localized: "Abschlag"), coordinate: tee) {
                    marker(symbol: "figure.golf", color: .blue)
                }
            }
            if let green {
                Annotation(String(localized: "Grün"), coordinate: green) {
                    marker(symbol: "flag.fill", color: .red)
                }
            }
            // Der Pin kann vom Grün-Mittelpunkt abweichen, wenn er selbst gesetzt wurde.
            if let pin, let green, pin.latitude != green.latitude || pin.longitude != green.longitude {
                Annotation(String(localized: "Pin"), coordinate: pin) {
                    marker(symbol: "mappin", color: AppTheme.gold)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .overlay(alignment: .topLeading) {
            if (pin ?? green) != nil {
                Button {
                    Haptics.selection()
                    alignToHole(animated: true)
                } label: {
                    Label("Loch", systemImage: "location.north.line.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.5), in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(12)
                .accessibilityLabel(Text("Karte zum Loch ausrichten"))
            }
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { mapSize = geo.size }
                    .onChange(of: geo.size) { _, size in
                        mapSize = size
                        if !cameraPosition.positionedByUser { alignToHole(animated: false) }
                    }
            }
        }
    }

    private func marker(symbol: String, color: Color) -> some View {
        ZStack {
            Circle().fill(color).frame(width: 26, height: 26)
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
    }

    // MARK: - Infopanel

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                badge("Par \(par)", color: AppTheme.gold)
                if let hcp { badge("HCP \(hcp)", color: AppTheme.textSec) }
                if let scorecardLength {
                    badge("\(scorecardLength) m", color: AppTheme.textSec)
                }
                Spacer()
                if score.strokes > 0 {
                    Text("\(score.strokes) Schläge")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.text)
                }
            }

            legend

            if let corridor {
                Divider().background(AppTheme.cardAlt)
                HStack(spacing: 16) {
                    stat(icon: "arrow.left.and.right",
                         value: distanceUnit.format(corridor.averageWidthMeters),
                         label: "Korridor")
                    stat(icon: "ruler",
                         value: distanceUnit.format(corridor.axisLengthMeters),
                         label: "Abschlag→Grün")
                    stat(icon: "arrow.triangle.2.circlepath",
                         value: "\(corridor.roundCount)",
                         label: "Runden")
                }
                Text(reliabilityHint(corridor.reliability))
                    .font(.caption2)
                    .foregroundStyle(corridor.reliability == .good ? AppTheme.textSec : .orange)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Divider().background(AppTheme.cardAlt)
                Text(tee == nil || green == nil
                     ? "Für dieses Loch sind noch keine Abschlag- und Grünpositionen gespeichert. Sie entstehen aus den aufgezeichneten Runden."
                     : "Noch kein Fairway-Verlauf für dieses Loch – dafür braucht es Messpunkte zwischen Abschlag und Grün. Par-3-Löcher werden übersprungen.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(AppTheme.card)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            if corridor != nil {
                legendItem(color: AppTheme.gold, text: "Fairway")
            }
            // Nur zeigen, was auf der Karte auch zu sehen ist.
            if walk.count >= 2 {
                legendItem(color: .cyan, text: "deine Spur")
            }
            if !score.sortedShots.isEmpty {
                legendItem(color: .white, text: "Schläge")
            }
        }
    }

    private func legendItem(color: Color, text: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Capsule().fill(color).frame(width: 14, height: 4)
            Text(text)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSec)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }

    private func stat(icon: String, value: String, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.gold)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTer)
        }
    }

    private func reliabilityHint(_ reliability: HoleCorridor.Reliability) -> LocalizedStringKey {
        switch reliability {
        case .good:     "Aus mehreren Runden gerechnet – trotzdem eine Schätzung."
        case .thin:     "Noch wenige Runden, der Korridor kann daneben liegen."
        case .veryThin: "Aus sehr wenigen Daten – nur ein grober Anhaltspunkt."
        }
    }
}
