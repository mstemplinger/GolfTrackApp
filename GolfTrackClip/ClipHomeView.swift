import SwiftUI
import CoreLocation

/// Startseite des Clips, wenn er ohne Link läuft.
///
/// iOS startet den Clip nicht nur über den QR-Code: auch aus der
/// App-Mediathek, aus „Zuletzt verwendet“ oder neu nach einem Absturz – dann
/// ohne Adresse. Statt einer Sackgasse gibt es hier drei Wege weiter:
/// die letzte Runde fortsetzen, selbst scannen, oder einen Platz in der
/// Nähe wählen.
struct ClipHomeView: View {

    /// Meldung, falls ein Link nicht aufging; sonst `nil`.
    let failure: LocalizedStringResource?
    /// Ein gescannter Code – geht durch dieselbe Auswertung wie der Start-Link.
    let onScan: (URL) -> Void
    /// Ein Platz aus der Umgebung oder die fortzusetzende Golfrunde.
    let onPick: (ClipCourse) -> Void

    @State private var savedMinigolf: SavedMinigolfGame?
    @State private var savedGolf: SavedGolfLiteRound?
    @State private var resumeConfig: MinigolfConfig?
    @State private var showScanner = false
    @State private var nearby: Nearby = .idle
    @State private var locator = ClipLocator()

    enum Nearby {
        case idle, searching, denied, found([ClipNearbyCourse])
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if let savedMinigolf { minigolfResumeCard(savedMinigolf) }
                if let savedGolf { golfResumeCard(savedGolf) }

                Button {
                    Haptics.medium()
                    showScanner = true
                } label: {
                    Label("QR-Code scannen", systemImage: "qrcode.viewfinder")
                        .goldButton()
                }
                .buttonStyle(.plain)

                nearbySection
            }
            .padding()
        }
        .appBackground()
        .onAppear(perform: reloadSaved)
        .task { await searchNearby() }
        .sheet(isPresented: $showScanner) {
            QRScannerSheet(onFound: onScan)
                .preferredColorScheme(.dark)
        }
        .fullScreenCover(item: $resumeConfig, onDismiss: reloadSaved) { config in
            NavigationStack {
                MinigolfScoringView(config: config)
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: – Kopf

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.gold)
                .padding(.top, 8)
            Text("Runde starten mit GolfTrack")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            if let failure {
                Text(failure)
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            } else {
                Text("Scanne den QR-Code am Platz oder wähle eine Anlage in deiner Nähe.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 6)
    }

    // MARK: – Letzte Runde

    private func minigolfResumeCard(_ game: SavedMinigolfGame) -> some View {
        resumeCard(
            title: game.courseName ?? String(localized: "Minigolf"),
            detail: "Bahn \(min(game.currentHole + 1, game.numberOfHoles)) von \(game.numberOfHoles) · \(game.playerNames.joined(separator: ", "))"
        ) {
            resumeConfig = MinigolfConfig(
                playerNames: game.playerNames,
                numberOfHoles: game.numberOfHoles,
                initialScores: game.scores,
                initialHole: game.currentHole,
                courseName: game.courseName,
                courseID: game.courseID,
                challenges: game.challenges ?? [],
                hints: game.courseID.flatMap(MinigolfCourses.course(id:))?.hints ?? []
            )
        }
    }

    private func golfResumeCard(_ round: SavedGolfLiteRound) -> some View {
        // „%lld Schläge" steht als eigener Schlüssel schon im Katalog, mit den
        // Pluralformen für Polnisch und Tschechisch. Deshalb hier eingesetzt
        // und nicht noch einmal ausgeschrieben.
        let schlaege = String(localized: "\(round.totalStrokes) Schläge")
        return resumeCard(
            title: round.courseName,
            detail: "Loch \(min(round.currentHole + 1, round.strokes.count)) von \(round.strokes.count) · \(schlaege)"
        ) {
            // Die Golf-Startseite bietet das Fortsetzen selbst an.
            onPick(.golf(GolfLiteCourse(
                id: round.courseID,
                name: round.courseName,
                location: "",
                holes: round.strokes.count,
                parValues: round.parValues
            )))
        }
    }

    private func resumeCard(title: String,
                            detail: LocalizedStringResource,
                            action: @escaping () -> Void) -> some View {
        Button {
            Haptics.medium()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.gold)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Letzte Runde fortsetzen")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.gold.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func reloadSaved() {
        savedMinigolf = MinigolfGameStore.load()
        savedGolf = GolfLiteStore.load()
    }

    // MARK: – In der Nähe

    @ViewBuilder
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("In deiner Nähe")
                .font(.headline)
                .padding(.top, 10)

            switch nearby {
            case .idle, .searching:
                HStack(spacing: 10) {
                    ProgressView().tint(AppTheme.gold)
                    Text("Plätze werden gesucht …")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))

            case .denied:
                Text("Ohne Standort können wir keine Plätze in der Nähe zeigen. Scanne einfach den QR-Code am Platz.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))

            case .found(let courses) where courses.isEmpty:
                Text("Im Umkreis von 50 km kennen wir noch keinen Platz.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))

            case .found(let courses):
                VStack(spacing: 0) {
                    ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                        nearbyRow(course)
                        if index < courses.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func nearbyRow(_ course: ClipNearbyCourse) -> some View {
        Button {
            Haptics.tap()
            onPick(course.course)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: course.isGolf ? "figure.golf" : "flag.fill")
                    .font(.body)
                    .foregroundStyle(AppTheme.gold)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if !course.location.isEmpty {
                        Text(course.location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Text(Self.distanceText(course.distance))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func searchNearby() async {
        guard case .idle = nearby else { return }
        nearby = .searching
        guard let location = await locator.currentLocation() else {
            nearby = .denied
            return
        }
        nearby = .found(await ClipCourseDirectory.nearby(to: location))
    }

    private static func distanceText(_ meters: CLLocationDistance) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        // Nur zwischen 1 und 10 km eine Nachkommastelle: „62 m", „3,4 km", „27 km".
        formatter.numberFormatter.maximumFractionDigits = (1_000..<10_000).contains(meters) ? 1 : 0
        return formatter.string(from: measurement)
    }
}

/// Holt einmal den Standort – mehr braucht die Startseite nicht.
///
/// Im Clip gilt die Freigabe nur bis zum nächsten Morgen; danach fragt iOS
/// von selbst noch einmal.
final class ClipLocator: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    func currentLocation() async -> CLLocation? {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            default:
                finish(nil)
            }
        }
    }

    private func finish(_ location: CLLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            guard continuation != nil else { return }
            switch manager.authorizationStatus {
            case .notDetermined: break
            case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
            default: finish(nil)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated { finish(locations.last) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated { finish(nil) }
    }
}
