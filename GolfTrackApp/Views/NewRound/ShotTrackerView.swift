import SwiftUI
import MapKit
import SwiftData
import CoreLocation

struct ShotTrackerView: View {
    @Bindable var holeScore: HoleScore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var fromCoord: CLLocationCoordinate2D?
    @State private var toCoord: CLLocationCoordinate2D?
    @State private var placingState: PlacingState = .from
    @State private var selectedClub = ""
    @Query(sort: \GolfClub.order) private var clubs: [GolfClub]
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters
    @State private var locationManager = CLLocationManager()
    @State private var locationUnavailableAlert = false
    @State private var isSatellite = false

    enum PlacingState {
        case from, to
        var label: String { self == .from ? "Abschlag" : "Treffpunkt" }
        var color: Color { self == .from ? .blue : .orange }
        var icon: String { self == .from ? "figure.golf" : "target" }
    }

    private let fallbackClubs = ["Driver", "3 Wood", "5 Wood", "4 Eisen", "5 Eisen", "6 Eisen",
                                 "7 Eisen", "8 Eisen", "9 Eisen", "PW", "GW", "SW", "LW", "Putter"]

    private var clubNames: [String] {
        clubs.isEmpty ? fallbackClubs : clubs.map { $0.name }
    }

    private var canUndo: Bool {
        fromCoord != nil || !holeScore.sortedShots.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                instructionBanner

                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        UserAnnotation()

                        ForEach(holeScore.sortedShots, id: \.shotNumber) { shot in
                            Annotation("A\(shot.shotNumber)", coordinate: shot.fromCoordinate) {
                                shotMarker(number: shot.shotNumber, color: .blue)
                            }
                            Annotation("", coordinate: shot.toCoordinate) {
                                landingMarker
                            }
                            MapPolyline(coordinates: [shot.fromCoordinate, shot.toCoordinate])
                                .stroke(AppTheme.gold.opacity(0.7), lineWidth: 2)
                        }

                        if let from = fromCoord {
                            Annotation("Abschlag", coordinate: from) {
                                shotMarker(number: holeScore.sortedShots.count + 1, color: .blue)
                            }
                        }
                        if let to = toCoord {
                            Annotation("", coordinate: to) {
                                landingMarker
                            }
                        }
                        if let from = fromCoord, let to = toCoord {
                            MapPolyline(coordinates: [from, to])
                                .stroke(AppTheme.gold, lineWidth: 2.5)
                        }
                    }
                    .mapStyle(isSatellite ? .hybrid(elevation: .realistic) : .standard)
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                        MapScaleView()
                    }
                    .overlay(alignment: .topLeading) {
                        satelliteToggleButton
                            .padding(.top, 12)
                            .padding(.leading, 12)
                    }
                    .onTapGesture { screenPoint in
                        guard let coord = proxy.convert(screenPoint, from: .local) else { return }
                        handleTap(coord)
                    }
                }

                bottomPanel
            }
            .navigationTitle("Loch \(holeScore.holeNumber) – Schläge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if canUndo {
                        Button {
                            undoLastAction()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                    }
                    if !holeScore.sortedShots.isEmpty || fromCoord != nil {
                        Button("Alle löschen", role: .destructive) { clearAll() }
                            .font(.caption)
                    }
                }
            }
            .alert("Standort nicht verfügbar", isPresented: $locationUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Stelle sicher, dass der Standortzugriff erlaubt ist.")
            }
            .onAppear {
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
                cameraPosition = .userLocation(fallback: .automatic)
            }
        }
    }

    // MARK: - Subviews

    private var instructionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: placingState.icon)
                .foregroundStyle(placingState.color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(placingState.label + " setzen")
                    .font(.subheadline.bold())
                    .foregroundStyle(placingState.color)
                Text("Tippe auf Karte oder nutze deinen Standort")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                useCurrentLocation()
            } label: {
                Label("Standort", systemImage: "location.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(placingState.color, in: Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(placingState.color.opacity(0.08))
    }

    private var landingMarker: some View {
        Image(systemName: "target")
            .font(.title2)
            .foregroundStyle(.orange)
            .background(Circle().fill(.white).frame(width: 28, height: 28))
    }

    private var satelliteToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isSatellite.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSatellite ? "map.fill" : "globe.europe.africa.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(isSatellite ? "Standard" : "Satellit")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSatellite ? .white : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSatellite
                    ? Color.black.opacity(0.65)
                    : Color.black.opacity(0.5),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSatellite ? 0.35 : 0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
    }

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            // Distance + save
            if let from = fromCoord, let to = toCoord {
                let dist = Shot.haversineDistance(from: from, to: to)
                HStack(spacing: 20) {
                    VStack {
                        Text(distanceUnit.format(dist))
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.gold)
                        Text(distanceUnit.displayName)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Speichern") { saveShot() }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.gold)
                }
                .padding(.horizontal)
                Divider()
            }

            // Club picker
            if fromCoord != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(clubNames, id: \.self) { club in
                            Button(club) { selectedClub = club }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedClub == club ? AppTheme.gold : Color.secondary.opacity(0.15),
                                            in: Capsule())
                                .foregroundStyle(selectedClub == club ? .white : .primary)
                        }
                    }
                    .padding(.horizontal)
                }
                Divider()
            }

            // Saved shots
            if !holeScore.sortedShots.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Gespeicherte Schläge")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    ForEach(holeScore.sortedShots, id: \.shotNumber) { shot in
                        HStack {
                            Label("Schlag \(shot.shotNumber)", systemImage: "figure.golf")
                                .font(.subheadline)
                            if !shot.club.isEmpty {
                                Text("· \(shot.club)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(distanceUnit.format(shot.distanceMeters))
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.gold)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .background(.background.secondary)
    }

    private func shotMarker(number: Int, color: Color) -> some View {
        ZStack {
            Circle().fill(color).frame(width: 28, height: 28)
            Text("\(number)").font(.caption.bold()).foregroundStyle(.white)
        }
    }

    // MARK: - Actions

    private func handleTap(_ coord: CLLocationCoordinate2D) {
        switch placingState {
        case .from:
            fromCoord = coord
            placingState = .to
        case .to:
            toCoord = coord
        }
    }

    private func useCurrentLocation() {
        guard let coord = locationManager.location?.coordinate else {
            locationUnavailableAlert = true
            return
        }
        handleTap(coord)
        // Center map on current location
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: coord,
                latitudinalMeters: 300,
                longitudinalMeters: 300
            ))
        }
    }

    private func saveShot() {
        guard let from = fromCoord, let to = toCoord else { return }
        let dist = Shot.haversineDistance(from: from, to: to)
        let shot = Shot(
            shotNumber: holeScore.sortedShots.count + 1,
            from: from,
            to: to,
            club: selectedClub
        )
        context.insert(shot)
        holeScore.shots.append(shot)

        // Distanz automatisch in die Schläger-Datenbank eintragen
        if !selectedClub.isEmpty,
           let club = clubs.first(where: { $0.name == selectedClub }) {
            club.addMeasurement(dist)
        }

        // Auto-chain: next shot starts where this one ended
        fromCoord = to
        toCoord = nil
        selectedClub = ""
        placingState = .to
    }

    private func undoLastAction() {
        if toCoord != nil {
            // Step 1: remove landing point, keep starting point
            toCoord = nil
        } else if fromCoord != nil {
            // Step 2: remove starting point
            fromCoord = nil
            placingState = .from
        } else if let lastShot = holeScore.sortedShots.last {
            // Step 3: delete last saved shot
            context.delete(lastShot)
            holeScore.shots.removeAll { $0.shotNumber == lastShot.shotNumber }
        }
    }

    private func clearAll() {
        for shot in holeScore.shots { context.delete(shot) }
        holeScore.shots.removeAll()
        fromCoord = nil
        toCoord = nil
        placingState = .from
        selectedClub = ""
    }
}
