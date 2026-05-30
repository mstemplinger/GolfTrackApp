import SwiftUI
import CoreLocation
import WatchKit
import Combine

// MARK: - Farbkonstanten (lokale Kopie)

private let gold   = Color(red: 0.79, green: 0.66, blue: 0.30)
private let darkBg = Color(red: 0.06, green: 0.14, blue: 0.08)
private let rowBg  = Color(red: 0.10, green: 0.20, blue: 0.12)

// MARK: - Shot-Schritt

private enum ShotStep {
    case waitingForTee          // Schritt 1: Abschlagpunkt erfassen
    case waitingForLanding      // Schritt 2: Auftreffpunkt erfassen
    case result(distance: Double) // Schritt 3: Ergebnis anzeigen
}

// MARK: - View

struct WatchShotView: View {

    let holeIndex: Int          // 0-basiert
    let onDismiss: () -> Void

    @StateObject private var locationService = WatchLocationService()
    @State private var step: ShotStep = .waitingForTee
    @State private var teeCoord: CLLocationCoordinate2D?

    private let wc = WatchConnectivityManager.shared

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()
            content
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .waitingForTee:
            captureStepView(
                icon: "location.fill",
                label: "ABSCHLAG",
                subtitle: "Stehe am Abschlag\nund tippe",
                buttonLabel: "Abschlag setzen",
                buttonAction: captureTee
            )

        case .waitingForLanding:
            captureStepView(
                icon: "mappin.and.ellipse",
                label: "AUFTREFFPUNKT",
                subtitle: "Gehe zur Kugel\nund tippe",
                buttonLabel: "Auftreffpunkt setzen",
                buttonAction: captureLanding
            )

        case .result(let distance):
            resultView(distance: distance)
        }
    }

    // MARK: - Erfassungs-Screen

    private func captureStepView(icon: String,
                                 label: String,
                                 subtitle: String,
                                 buttonLabel: String,
                                 buttonAction: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            // Header
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(gold)
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(gold)
                    .kerning(0.8)
            }
            .padding(.top, 4)

            Spacer()

            // GPS-Status
            gpsStatusView

            Spacer()

            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Erfassen-Button
            Button(action: buttonAction) {
                Text(buttonLabel)
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(locationService.hasLocation ? gold : Color.white.opacity(0.15))
                    .foregroundStyle(locationService.hasLocation ? darkBg : Color.white.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(!locationService.hasLocation)
            .padding(.bottom, 2)

            // Abbrechen
            Button("Abbrechen") { onDismiss() }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
                .padding(.bottom, 4)
        }
        .padding(.horizontal, 8)
        .onAppear { locationService.start() }
    }

    // MARK: - GPS-Status-Indikator

    private var gpsStatusView: some View {
        VStack(spacing: 4) {
            if locationService.hasLocation {
                VStack(spacing: 2) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(gold)
                    Text("GPS bereit")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(gold)
                    if let acc = locationService.accuracy {
                        Text("±\(Int(acc)) m")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(spacing: 2) {
                    ProgressView()
                        .tint(gold)
                        .scaleEffect(0.9)
                    Text("GPS wird geladen…")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 48)
    }

    // MARK: - Ergebnis-Screen

    private func resultView(distance: Double) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(gold)
                Text("SCHLAG")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(gold)
                    .kerning(0.8)
            }
            .padding(.top, 4)

            Spacer()

            // Distanz groß
            VStack(spacing: 2) {
                Text("\(Int(distance))")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Meter")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("≈ \(Int(distance * 1.09361)) Yards")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Weiter-Button
            Button("Fertig") {
                WKInterfaceDevice.current().play(.success)
                onDismiss()
            }
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(gold)
            .foregroundStyle(darkBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Aktionen

    private func captureTee() {
        guard let coord = locationService.currentCoordinate else { return }
        teeCoord = coord
        step = .waitingForLanding
        WKInterfaceDevice.current().play(.click)
    }

    private func captureLanding() {
        guard let tee = teeCoord,
              let landing = locationService.currentCoordinate else { return }

        let loc1 = CLLocation(latitude: tee.latitude, longitude: tee.longitude)
        let loc2 = CLLocation(latitude: landing.latitude, longitude: landing.longitude)
        let distance = loc1.distance(from: loc2)

        // An iPhone senden
        wc.sendShotToPhone(
            holeIndex: holeIndex,
            fromLat: tee.latitude,
            fromLon: tee.longitude,
            toLat: landing.latitude,
            toLon: landing.longitude,
            distance: distance
        )

        WKInterfaceDevice.current().play(.success)
        step = .result(distance: distance)
    }
}

// MARK: - CoreLocation-Helfer (Watch)

@MainActor
final class WatchLocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var hasLocation = false
    @Published var accuracy: Double?
    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last,
              loc.horizontalAccuracy >= 0 else { return }
        Task { @MainActor in
            self.currentCoordinate = loc.coordinate
            self.accuracy = loc.horizontalAccuracy
            self.hasLocation = true
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {}
}
