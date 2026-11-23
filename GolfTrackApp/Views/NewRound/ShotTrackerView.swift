import SwiftUI
import MapKit
import SwiftData
import CoreLocation

struct ShotTrackerView<Entry: ScoreEntry>: View {
    @Bindable var holeScore: Entry
    /// Name des Mitspielers im Titel; nil für die eigene Karte.
    var playerName: String? = nil
    /// Nur eigene Schläge fließen in die Distanzen der eigenen Schläger.
    var recordsClubDistances = true
    /// Abschlag und Loch dieses Lochs – damit richtet sich die Karte aus.
    var tee: CLLocationCoordinate2D? = nil
    var hole: CLLocationCoordinate2D? = nil
    /// Fairway-Verlauf aus früheren Runden; wird komplett eingepasst.
    var corridor: HoleCorridor? = nil
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
    @State private var playerCoord: CLLocationCoordinate2D?
    @State private var mapSize: CGSize = .zero

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

                        if let tee {
                            Annotation("", coordinate: tee) {
                                Image(systemName: "figure.golf")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(.blue.opacity(0.85)))
                                    .accessibilityLabel(Text("Abschlag"))
                            }
                        }
                        if let hole {
                            Annotation(String(localized: "Loch"), coordinate: hole) {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(.red))
                                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                            }
                        }

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
                        HStack(spacing: 8) {
                            satelliteToggleButton
                            if canAlignToHole { alignButton }
                        }
                        .padding(.top, 12)
                        .padding(.leading, 12)
                    }
                    .background {
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { updateMapSize(geo.size) }
                                .onChange(of: geo.size) { _, size in updateMapSize(size) }
                        }
                    }
                    .onTapGesture { screenPoint in
                        guard let coord = proxy.convert(screenPoint, from: .local) else { return }
                        handleTap(coord)
                    }
                }

                bottomPanel
            }
            .navigationTitle((playerName.map { "\($0) · " } ?? "")
                             + String(localized: "Loch \(holeScore.holeNumber) – Schläge"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") {
                        Haptics.tap()
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if canUndo {
                        Button {
                            Haptics.decrement()
                            undoLastAction()
                        } label: {
                            Image(systemName: "arrow.uturn.backward")
                        }
                    }
                    if !holeScore.sortedShots.isEmpty || fromCoord != nil {
                        Button("Alle löschen", role: .destructive) {
                            Haptics.warning()
                            clearAll()
                        }
                            .font(.caption)
                    }
                }
            }
            .alert("Standort nicht verfügbar", isPresented: $locationUnavailableAlert) {
                Button("OK", role: .cancel) { Haptics.tap() }
            } message: {
                Text("Stelle sicher, dass der Standortzugriff erlaubt ist.")
            }
            .onAppear {
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
                playerCoord = locationManager.location?.coordinate
                if canAlignToHole {
                    alignToHole(animated: false)
                } else {
                    cameraPosition = .userLocation(fallback: .automatic)
                }
            }
            .livePlayerLocation($playerCoord)
            .onChange(of: playerCoord?.latitude) { _, _ in autoAlign() }
            .onChange(of: holeScore.strokes) { _, _ in autoAlign() }
            .onChange(of: holeScore.shots.count) { _, _ in autoAlign() }
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
                Haptics.tap()
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

    private var alignButton: some View {
        Button {
            Haptics.selection()
            alignToHole(animated: true)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Loch")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.5), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        .accessibilityLabel(Text("Karte zum Loch ausrichten"))
    }

    private var landingMarker: some View {
        Image(systemName: "target")
            .font(.title2)
            .foregroundStyle(.orange)
            .background(Circle().fill(.white).frame(width: 28, height: 28))
    }

    private var satelliteToggleButton: some View {
        Button {
            Haptics.selection()
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
                            Button(club) {
                                Haptics.selection()
                                selectedClub = club
                            }
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

    // MARK: - Ausrichtung

    private var hasPlayed: Bool { holeScore.strokes > 0 || !holeScore.shots.isEmpty }

    private var canAlignToHole: Bool {
        guard let hole else { return false }
        return HoleCameraFraming.bottomPoint(tee: tee, hole: hole, player: playerCoord,
                                             hasPlayed: hasPlayed) != nil
    }

    /// Unten mittig Abschlag bzw. die eigene Position, oben mittig das Loch;
    /// Fairway und Schläge werden mit eingepasst.
    private func alignToHole(animated: Bool) {
        guard let hole,
              let bottom = HoleCameraFraming.bottomPoint(tee: tee, hole: hole, player: playerCoord,
                                                         hasPlayed: hasPlayed) else { return }
        var extra: [CLLocationCoordinate2D] = []
        // Das ganze Fairway nur, solange man noch am Abschlag steht – danach
        // zählt der Weg von der eigenen Position zum Loch.
        if bottom.latitude == tee?.latitude, bottom.longitude == tee?.longitude,
           let corridor {
            extra += corridor.corridorPolygon
        }
        if let from = fromCoord { extra.append(from) }
        if let to = toCoord { extra.append(to) }
        let size = mapSize == .zero ? CGSize(width: 390, height: 500) : mapSize
        guard let camera = HoleCameraFraming.camera(bottom: bottom, top: hole,
                                                    including: extra, viewSize: size) else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.6)) { cameraPosition = .camera(camera) }
        } else {
            cameraPosition = .camera(camera)
        }
    }

    /// Automatisch nachführen – aber nicht, wenn der Spieler die Karte selbst
    /// verschoben hat. Der Knopf „Loch" holt die Ausrichtung zurück.
    private func autoAlign() {
        guard canAlignToHole, !cameraPosition.positionedByUser else { return }
        alignToHole(animated: true)
    }

    private func updateMapSize(_ size: CGSize) {
        let changed = abs(size.width - mapSize.width) > 1 || abs(size.height - mapSize.height) > 1
        mapSize = size
        if changed { autoAlign() }
    }

    // MARK: - Actions

    private func handleTap(_ coord: CLLocationCoordinate2D) {
        Haptics.rigid()
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
            Haptics.error()
            locationUnavailableAlert = true
            return
        }
        handleTap(coord)
        playerCoord = coord
        if canAlignToHole {
            alignToHole(animated: true)
            return
        }
        // Ohne Lochdaten: auf den Standort zentrieren
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
        Haptics.success()
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
        if recordsClubDistances, !selectedClub.isEmpty,
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
