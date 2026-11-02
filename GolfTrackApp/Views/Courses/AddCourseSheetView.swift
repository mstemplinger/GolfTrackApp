import SwiftUI
import SwiftData
import CoreLocation

struct AddCourseSheetView: View {
    /// Called by the parent to perform the actual SwiftData insert in the parent's context
    var onAddBundledCourse: (BundledCourseEntry) -> Void

    init(onAddBundledCourse: @escaping (BundledCourseEntry) -> Void = { _ in }) {
        self.onAddBundledCourse = onAddBundledCourse
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name) private var savedCourses: [Course]

    // Search
    @State private var query = ""

    // Manual creation
    @State private var showManualForm = false
    @State private var showScorecardScanner = false

    // Location for distance sorting
    @State private var locationManager = CLLocationManager()
    @State private var userLocation: CLLocation?
    @State private var locationDetermined = false  // true once the location lookup has finished

    private var savedNames: Set<String> {
        Set(savedCourses.map { $0.name })
    }

    private let nearbyRadius: CLLocationDistance = 30_000 // 30 km

    /// Plätze von golftrack.app zusätzlich zu den eingebauten
    private let catalog = CourseCatalogService.shared

    // All bundled courses sorted by distance (used as base for filtering)
    private var sortedBundledCourses: [BundledCourseEntry] {
        let all = catalog.allGolfCourses
        guard let loc = userLocation else { return all }
        return all.sorted { $0.distance(from: loc) < $1.distance(from: loc) }
    }

    // Only courses within 30 km – shown in the default "Nearby" section.
    // Falls back to the full sorted list when location is unavailable.
    private var nearbyBundledCourses: [BundledCourseEntry] {
        guard locationDetermined else { return [] }          // still loading → nothing yet
        guard let loc = userLocation else { return sortedBundledCourses } // no GPS → show all
        return sortedBundledCourses.filter { $0.distance(from: loc) <= nearbyRadius }
    }

    // Full bundled list filtered by search text – shown when the user is typing
    private var bundledSearchResults: [BundledCourseEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return catalog.allGolfCourses.filter {
            $0.name.lowercased().contains(q) || $0.location.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
            List {
                if query.isEmpty {
                    nearbySection
                } else if bundledSearchResults.isEmpty {
                    Section {
                        ContentUnavailableView.search(text: query)
                    }
                } else {
                    // Bundled courses matching search text (full list, no radius limit)
                    Section("Plätze aus der Datenbank") {
                        ForEach(bundledSearchResults) { entry in
                            bundledCourseRow(entry)
                        }
                    }
                }

                manualSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Platz hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Platzname oder Club suchen"
            )
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        Haptics.tap()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showManualForm) {
                AddCourseView()
            }
            .sheet(isPresented: $showScorecardScanner) {
                ScorecardScannerView { course in
                    context.insert(course)
                    dismiss()
                }
            }
            .task {
                locationManager.requestWhenInUseAuthorization()
                try? await Task.sleep(nanoseconds: 800_000_000)
                userLocation = locationManager.location
                locationDetermined = true
            }
            .task {
                // Neue Plätze von golftrack.app nachladen – schlägt der Abruf
                // fehl, bleibt die eingebaute Liste unverändert stehen.
                await catalog.refreshIfNeeded()
            }
            } // ZStack
        }
    }

    // MARK: - Sections

    private var nearbySection: some View {
        Section {
            if !locationDetermined {
                // Still waiting for GPS
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Standort wird ermittelt …")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(AppTheme.card)
            } else {
                ForEach(nearbyBundledCourses) { entry in
                    bundledCourseRow(entry)
                }
            }
        } header: {
            HStack {
                if !locationDetermined {
                    Label("Golfplätze in der Nähe", systemImage: "location")
                        .foregroundStyle(AppTheme.gold)
                    Spacer()
                    ProgressView().scaleEffect(0.7)
                } else if userLocation != nil {
                    Label("Golfplätze in der Nähe (30 km)", systemImage: "location.fill")
                        .foregroundStyle(AppTheme.gold)
                } else {
                    Label("Alle Golfplätze", systemImage: "map")
                        .foregroundStyle(AppTheme.gold)
                }
            }
        } footer: {
            if locationDetermined {
                if userLocation != nil {
                    Text("Plätze im 30-km-Umkreis. Weiter entfernte Plätze sind per Suche erreichbar.")
                        .font(.caption)
                } else {
                    Text("Standort nicht verfügbar – alle Plätze werden angezeigt.")
                        .font(.caption)
                }
            }
        }
    }

    private var manualSection: some View {
        Section {
            Button {
                Haptics.tap()
                showScorecardScanner = true
            } label: {
                Label("Scorecard scannen", systemImage: "camera.viewfinder")
                    .foregroundStyle(AppTheme.gold)
            }
            .listRowBackground(AppTheme.card)

            Button {
                Haptics.tap()
                showManualForm = true
            } label: {
                Label("Eigenen Platz manuell erstellen", systemImage: "plus.circle.fill")
                    .foregroundStyle(AppTheme.textSec)
            }
            .listRowBackground(AppTheme.card)
        } header: {
            Text("Platz nicht dabei?").foregroundStyle(AppTheme.textSec)
        } footer: {
            Text("Halte die gedruckte Scorecard vor die Kamera – GolfTrack liest Par, HCP und Distanzen automatisch aus.")
                .font(.caption)
        }
    }

    // MARK: - Bundled course row

    private func bundledCourseRow(_ entry: BundledCourseEntry) -> some View {
        let alreadySaved = savedNames.contains(entry.name)

        return Button {
            guard !alreadySaved else { return }
            Haptics.success()
            importBundledCourse(entry)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.name)
                        .font(.headline)
                        .foregroundStyle(alreadySaved ? .secondary : .primary)
                    HStack(spacing: 10) {
                        Label(entry.location, systemImage: "location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(entry.holes) Loch")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if alreadySaved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.gold)
                        .font(.title3)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        if let loc = userLocation {
                            Text(entry.formattedDistance(from: loc))
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.gold)
                        }
                        Image(systemName: "plus.circle")
                            .foregroundStyle(AppTheme.gold)
                            .font(.title3)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(alreadySaved ? AppTheme.gold.opacity(0.05) : nil)
    }

    // MARK: - Actions

    private func importBundledCourse(_ entry: BundledCourseEntry) {
        onAddBundledCourse(entry)   // parent's context does the insert
        dismiss()
    }
}
