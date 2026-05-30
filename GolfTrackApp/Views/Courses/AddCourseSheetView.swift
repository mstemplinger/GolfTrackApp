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
    private var api: GolfCourseAPIService = .shared

    // Search
    @State private var query = ""
    @State private var results: [APICourse] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selectedAPICourse: APICourse?
    @State private var isFetchingDetail = false

    // Manual creation
    @State private var showManualForm = false

    // Location for distance sorting
    @State private var locationManager = CLLocationManager()
    @State private var userLocation: CLLocation?
    @State private var locationDetermined = false  // true once the location lookup has finished

    private var savedNames: Set<String> {
        Set(savedCourses.map { $0.name })
    }

    private let nearbyRadius: CLLocationDistance = 30_000 // 30 km

    // All bundled courses sorted by distance (used as base for filtering)
    private var sortedBundledCourses: [BundledCourseEntry] {
        guard let loc = userLocation else { return BundledCourses.all }
        return BundledCourses.all.sorted { $0.distance(from: loc) < $1.distance(from: loc) }
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
        return BundledCourses.all.filter {
            $0.name.lowercased().contains(q) || $0.location.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
            List {
                if !api.hasAPIKey { keyBannerSection }

                if query.isEmpty {
                    nearbySection
                } else if isSearching {
                    // spinner shown via overlay
                } else {
                    // Bundled courses matching search text (full list, no radius limit)
                    if !bundledSearchResults.isEmpty {
                        Section("Plätze aus der Datenbank") {
                            ForEach(bundledSearchResults) { entry in
                                bundledCourseRow(entry)
                            }
                        }
                    }
                    // API results
                    if results.isEmpty {
                        if bundledSearchResults.isEmpty {
                            Section {
                                ContentUnavailableView.search(text: query)
                            }
                        }
                    } else {
                        apiResultsSection
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
            .onSubmit(of: .search) { Task { await search() } }
            .onChange(of: query) { _, new in if new.isEmpty { results = [] } }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .overlay { loadingOverlays }
            .alert("Fehler", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(item: $selectedAPICourse) { course in
                TeeBoxPickerView(course: course) { saved in
                    context.insert(saved)
                    dismiss()
                }
            }
            .sheet(isPresented: $showManualForm) {
                AddCourseView()
            }
            .task {
                locationManager.requestWhenInUseAuthorization()
                try? await Task.sleep(nanoseconds: 800_000_000)
                userLocation = locationManager.location
                locationDetermined = true
            }
            } // ZStack
        }
    }

    // MARK: - Sections

    private var keyBannerSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "key.slash").foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kein API-Key eingetragen").font(.subheadline.bold())
                    Text("Für die Online-Suche wird ein API-Key benötigt.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .listRowBackground(AppTheme.card)
        }
    }

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

    private var apiResultsSection: some View {
        Section("Suchergebnisse (\(results.count))") {
            ForEach(results) { course in
                Button { selectAPICourse(course) } label: {
                    apiCourseRow(course)
                }
                .listRowBackground(Color.clear)
            }
        }
    }

    private var manualSection: some View {
        Section {
            Button { showManualForm = true } label: {
                Label("Eigenen Platz manuell erstellen", systemImage: "plus.circle.fill")
                    .foregroundStyle(AppTheme.gold)
            }
            .listRowBackground(AppTheme.card)
        } footer: {
            Text(query.isEmpty
                 ? "Platz nicht dabei? Lege ihn manuell an."
                 : "Platz nicht gefunden? Lege ihn manuell an.")
                .font(.caption)
        }
    }

    @ViewBuilder
    private var loadingOverlays: some View {
        if isSearching {
            ProgressView("Suche läuft …")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background.opacity(0.8))
        }
        if isFetchingDetail {
            ZStack {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Platzdaten laden …")
                    .padding(24)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Bundled course row

    private func bundledCourseRow(_ entry: BundledCourseEntry) -> some View {
        let alreadySaved = savedNames.contains(entry.name)

        return Button {
            guard !alreadySaved else { return }
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

    // MARK: - API course row

    private func apiCourseRow(_ course: APICourse) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(course.displayName).font(.headline).foregroundStyle(.primary)
            if !course.locationString.isEmpty {
                Label(course.locationString, systemImage: "location")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let tees = course.tees {
                let count = (tees.male?.count ?? 0) + (tees.female?.count ?? 0)
                if count > 0 {
                    Label("\(count) Abschlag\(count == 1 ? "" : "-Optionen")", systemImage: "flag")
                        .font(.caption).foregroundStyle(AppTheme.gold)
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private func importBundledCourse(_ entry: BundledCourseEntry) {
        onAddBundledCourse(entry)   // parent's context does the insert
        dismiss()
    }

    private func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            results = try await api.search(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func selectAPICourse(_ course: APICourse) {
        if course.preferredTeeBox()?.holes?.isEmpty == false {
            selectedAPICourse = course
            return
        }
        Task {
            isFetchingDetail = true
            defer { isFetchingDetail = false }
            do {
                let full = try await api.getCourse(id: course.id)
                selectedAPICourse = full
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
