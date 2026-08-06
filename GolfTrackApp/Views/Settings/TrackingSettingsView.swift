import SwiftUI
import SwiftData
import CoreLocation

/// Einstellungen für die Positionsaufzeichnung – Opt-in, Status, Datenverwaltung.
struct TrackingSettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var tracks: [RoundTrack]
    @Query(sort: \Course.name) private var courses: [Course]
    @ObservedObject private var tracking = RoundTrackingService.shared

    @AppStorage(RoundTrackingService.enabledKey) private var isEnabled = false
    @State private var showDeleteAllAlert = false

    private var totalPoints: Int { tracks.reduce(0) { $0 + $1.pointCount } }
    private var totalKilobytes: Double { tracks.reduce(0) { $0 + $1.storageKilobytes } }

    private var coursesWithData: [Course] {
        courses.filter { course in
            course.rounds.contains { $0.track != nil }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            List {
                // MARK: Schalter
                Section {
                    Toggle(isOn: $isEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Laufspur aufzeichnen")
                                .foregroundStyle(AppTheme.text)
                            Text("Nur während einer laufenden Runde")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                        }
                    }
                    .tint(AppTheme.gold)
                    .listRowBackground(AppTheme.card)
                } header: {
                    Text("Positions-Tracking")
                } footer: {
                    Text("Während einer Runde wird alle paar Meter deine Position gespeichert. Daraus leitet die App Abschlag- und Grünpositionen der Löcher ab – so bekommst du die Entfernung zur Fahne ohne den Pin selbst zu setzen.\n\nDie Daten bleiben auf deinem iPhone und werden nicht übertragen. Du kannst sie jederzeit hier löschen.")
                        .font(.caption)
                }

                // MARK: Status
                if isEnabled {
                    Section {
                        statusRow
                        if tracking.isTracking {
                            HStack {
                                Label("Aufzeichnung aktiv", systemImage: "record.circle")
                                    .foregroundStyle(AppTheme.gold)
                                Spacer()
                                Text("\(tracking.pointCount) Punkte")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSec)
                            }
                            .listRowBackground(AppTheme.card)
                        }
                    } header: {
                        Text("Status")
                    } footer: {
                        Text("iOS zeichnet auch bei gesperrtem Display weiter auf und zeigt dabei eine blaue Anzeige in der Statusleiste. Rechne mit etwas mehr Akkuverbrauch als ohne Tracking.")
                            .font(.caption)
                    }
                }

                // MARK: Abgeleitete Positionen
                if !coursesWithData.isEmpty {
                    Section {
                        ForEach(coursesWithData) { course in
                            NavigationLink {
                                CourseGeometryReviewView(course: course)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(course.name)
                                        .foregroundStyle(AppTheme.text)
                                    Text("\(course.holePositionCount)/\(course.numberOfHoles) Löcher mit Position · Aufzeichnungen: \(trackCount(for: course))")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSec)
                                }
                            }
                            .listRowBackground(AppTheme.card)
                        }
                    } header: {
                        Text("Loch-Positionen ableiten")
                    } footer: {
                        Text("Ab etwa drei aufgezeichneten Runden pro Platz werden die Schätzungen deutlich stabiler.")
                            .font(.caption)
                    }
                }

                // MARK: Daten
                Section {
                    HStack {
                        Text("Aufzeichnungen")
                            .foregroundStyle(AppTheme.textSec)
                        Spacer()
                        Text("\(tracks.count)")
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .listRowBackground(AppTheme.card)
                    HStack {
                        Text("GPS-Punkte")
                            .foregroundStyle(AppTheme.textSec)
                        Spacer()
                        Text("\(totalPoints)")
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .listRowBackground(AppTheme.card)
                    HStack {
                        Text("Speicherbedarf")
                            .foregroundStyle(AppTheme.textSec)
                        Spacer()
                        Text(String(format: "%.1f KB", totalKilobytes))
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .listRowBackground(AppTheme.card)

                    if !tracks.isEmpty {
                        Button(role: .destructive) {
                            showDeleteAllAlert = true
                        } label: {
                            Label("Alle Laufspuren löschen", systemImage: "trash")
                        }
                        .listRowBackground(AppTheme.card)
                    }
                } header: {
                    Text("Gespeicherte Daten")
                } footer: {
                    Text("Das Löschen entfernt nur die Laufspuren. Runden, Scores und bereits übernommene Loch-Positionen bleiben erhalten.")
                        .font(.caption)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Positions-Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Alle Laufspuren löschen?", isPresented: $showDeleteAllAlert) {
            Button("Löschen", role: .destructive) { deleteAllTracks() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Alle gespeicherten Laufspuren werden endgültig entfernt (\(totalPoints) GPS-Punkte).")
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusRow: some View {
        switch tracking.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            Label("Standortzugriff erlaubt", systemImage: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.green)
                .listRowBackground(AppTheme.card)
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 8) {
                Label("Standortzugriff nicht erlaubt", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Ohne Standortzugriff kann keine Laufspur aufgezeichnet werden.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                Button("In den iOS-Einstellungen öffnen") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(AppTheme.gold)
            }
            .listRowBackground(AppTheme.card)
        default:
            Label("Wird beim Start der nächsten Runde abgefragt", systemImage: "location.circle")
                .foregroundStyle(AppTheme.textSec)
                .listRowBackground(AppTheme.card)
        }
    }

    // MARK: - Aktionen

    private func trackCount(for course: Course) -> Int {
        course.rounds.filter { $0.track != nil }.count
    }

    private func deleteAllTracks() {
        for track in tracks {
            track.round?.track = nil
            context.delete(track)
        }
        try? context.save()
    }
}
