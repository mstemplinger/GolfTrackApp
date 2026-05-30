import SwiftUI
import MapKit
import CoreLocation

struct PinSetterView: View {
    @Binding var pinLatitude: Double?
    @Binding var pinLongitude: Double?

    @Environment(\.dismiss) private var dismiss
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var locationManager = CLLocationManager()
    @State private var userLocation: CLLocation?
    @State private var pendingLat: Double?
    @State private var pendingLon: Double?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        UserAnnotation()

                        if let lat = pendingLat, let lon = pendingLon {
                            Annotation("Pin", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                pinMarker
                            }
                        }
                    }
                    .mapStyle(.hybrid(elevation: .realistic))
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                        MapScaleView()
                    }
                    .onTapGesture { screenPoint in
                        guard let coord = proxy.convert(screenPoint, from: .local) else { return }
                        withAnimation(.spring(response: 0.3)) {
                            pendingLat = coord.latitude
                            pendingLon = coord.longitude
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                // Top banner
                instructionBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Bottom panel
                VStack {
                    Spacer()
                    bottomPanel
                }
            }
            .navigationTitle("Pin setzen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            // Pre-fill with existing pin if available
            if let lat = pinLatitude, let lon = pinLongitude {
                pendingLat = lat
                pendingLon = lon
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    latitudinalMeters: 200,
                    longitudinalMeters: 200
                ))
            }
        }
        .task {
            while !Task.isCancelled {
                userLocation = locationManager.location
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    // MARK: - Pin Marker

    private var pinMarker: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 32, height: 32)
                Image(systemName: "flag.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

            // Pin stem
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: 10)

            // Base dot
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
        }
    }

    // MARK: - Instruction Banner

    private var instructionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.gold)
            Text("Tippe auf die Karte, um das Loch zu markieren")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.text)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            // Distance info
            if let pinLat = pendingLat, let pinLon = pendingLon,
               let userLoc = userLocation {
                let pinLocation = CLLocation(latitude: pinLat, longitude: pinLon)
                let distanceM = pinLocation.distance(from: userLoc)

                HStack {
                    Image(systemName: "arrow.left.and.right")
                        .foregroundStyle(AppTheme.gold)
                    Text("Entfernung:")
                        .foregroundStyle(AppTheme.textSec)
                    Text(distanceUnit.format(distanceM))
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.gold)
                    Spacer()
                }
                .font(.subheadline)
                .padding(.horizontal, 4)
            }

            // Use current location button
            Button {
                useCurrentLocation()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                    Text("Meinen Standort verwenden")
                }
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
            }

            // Save button
            Button {
                if let lat = pendingLat, let lon = pendingLon {
                    pinLatitude = lat
                    pinLongitude = lon
                }
                dismiss()
            } label: {
                Text(pendingLat != nil ? "Speichern" : "Ohne Pin schließen")
                    .font(.headline)
                    .foregroundStyle(
                        pendingLat != nil
                            ? Color(red: 0.10, green: 0.22, blue: 0.13)
                            : AppTheme.textSec
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        pendingLat != nil ? AppTheme.gold : AppTheme.card,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 32)
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func useCurrentLocation() {
        guard let coord = locationManager.location?.coordinate else { return }
        withAnimation(.spring(response: 0.3)) {
            pendingLat = coord.latitude
            pendingLon = coord.longitude
            cameraPosition = .region(MKCoordinateRegion(
                center: coord,
                latitudinalMeters: 150,
                longitudinalMeters: 150
            ))
        }
    }
}
