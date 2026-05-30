import SwiftUI
import SwiftData
import CoreLocation

// MARK: - CourseSelectorView

struct CourseSelectorView: View {
    @Binding var selectedCourse: Course?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Course.name) private var allCourses: [Course]

    private let api: GolfCourseAPIService = .shared
    private let nearbyRadius: CLLocationDistance = 30_000 // 30 km

    @State private var locationManager = CLLocationManager()
    @State private var userLocation: CLLocation?
    @State private var locationDetermined = false

    @State private var searchText = ""
    @State private var apiResults: [APICourse] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selectedAPICourse: APICourse?
    @State private var isFetchingDetail = false

    // Courses within 30 km (or all if no location)
    private var nearbyCourses: [Course] {
        guard let loc = userLocation else { return allCourses }
        return allCourses.filter { course in
            guard let dist = course.distance(from: loc) else { return true }
            return dist <= nearbyRadius
        }
        .sorted {
            let d0 = $0.distance(from: loc) ?? .greatestFiniteMagnitude
            let d1 = $1.distance(from: loc) ?? .greatestFiniteMagnitude
            return d0 < d1
        }
    }

    // Local courses filtered by search text (for name-matching when no API key)
    private var localSearchResults: [Course] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return allCourses.filter { $0.name.lowercased().contains(q) }
    }

    private var isSearchActive: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                List {
                    if isSearchActive {
                        searchSection
                    } else {
                        nearbySection
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Platz wählen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Platz suchen…"
            )
            .onSubmit(of: .search) {
                if api.hasAPIKey { Task { await runAPISearch() } }
            }
            .onChange(of: searchText) { _, new in
                if new.isEmpty { apiResults = [] }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .alert("Fehler", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) { Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .sheet(item: $selectedAPICourse) { course in
                TeeBoxPickerView(course: course) { saved in
                    context.insert(saved)
                    selectedCourse = saved
                    dismiss()
                }
            }
            .overlay { loadingOverlays }
            .task {
                locationManager.requestWhenInUseAuthorization()
                // give CLLocationManager a moment
                try? await Task.sleep(nanoseconds: 700_000_000)
                userLocation = locationManager.location
                locationDetermined = true
            }
        }
    }

    // MARK: - Nearby section (default)

    @ViewBuilder
    private var nearbySection: some View {
        if allCourses.isEmpty {
            Section {
                Label("Noch keine Plätze gespeichert.", systemImage: "mappin.slash")
                    .foregroundStyle(AppTheme.textSec)
                    .listRowBackground(AppTheme.card)
            }
        } else {
            Section {
                ForEach(nearbyCourses) { course in
                    courseRow(course, showDistance: userLocation != nil)
                }
            } header: {
                HStack(spacing: 6) {
                    Image(systemName: userLocation != nil ? "location.fill" : "mappin.and.ellipse")
                        .foregroundStyle(AppTheme.gold)
                    Text(nearbyHeaderTitle)
                    if !locationDetermined {
                        Spacer()
                        ProgressView().scaleEffect(0.7)
                    }
                }
            } footer: {
                if locationDetermined && userLocation != nil && nearbyCourses.count < allCourses.count {
                    Text("Weitere Plätze sind per Suche erreichbar.")
                        .font(.caption)
                }
            }
        }
    }

    private var nearbyHeaderTitle: String {
        guard locationDetermined else { return "Meine Plätze" }
        if userLocation != nil { return "In der Nähe (30 km)" }
        return "Meine Plätze"
    }

    // MARK: - Search section

    @ViewBuilder
    private var searchSection: some View {
        // Local matches (always shown)
        if !localSearchResults.isEmpty {
            Section("Gespeicherte Plätze") {
                ForEach(localSearchResults) { course in
                    courseRow(course, showDistance: userLocation != nil)
                }
            }
        }

        // API results
        if api.hasAPIKey {
            if apiResults.isEmpty && !isSearching {
                Section {
                    Button {
                        Task { await runAPISearch() }
                    } label: {
                        Label("Online suchen: \"\(searchText)\"", systemImage: "magnifyingglass")
                            .foregroundStyle(AppTheme.gold)
                    }
                    .listRowBackground(AppTheme.card)
                } footer: {
                    Text("Sucht weltweit nach Golfplätzen via API.")
                        .font(.caption)
                }
            } else if !apiResults.isEmpty {
                Section("Online-Ergebnisse") {
                    ForEach(apiResults) { course in
                        Button { selectAPICourse(course) } label: {
                            apiCourseRow(course)
                        }
                        .listRowBackground(AppTheme.card)
                    }
                }
            }
        } else if localSearchResults.isEmpty {
            Section {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    // MARK: - Row views

    private func courseRow(_ course: Course, showDistance: Bool) -> some View {
        Button {
            selectedCourse = course
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(selectedCourse?.id == course.id ? AppTheme.gold : AppTheme.textSec)

                VStack(alignment: .leading, spacing: 2) {
                    Text(course.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    HStack(spacing: 8) {
                        if !course.location.isEmpty {
                            Text(course.location)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                                .lineLimit(1)
                        }
                        Text("\(course.numberOfHoles) Loch · Par \(course.totalPar)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                    }
                }

                Spacer()

                if showDistance, let loc = userLocation, let dist = course.distance(from: loc) {
                    Text(formattedDistance(dist))
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.gold)
                }

                if selectedCourse?.id == course.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.gold)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            selectedCourse?.id == course.id
                ? AppTheme.gold.opacity(0.08)
                : AppTheme.card
        )
    }

    private func apiCourseRow(_ course: APICourse) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(course.displayName)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.text)
            if !course.locationString.isEmpty {
                Label(course.locationString, systemImage: "location")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Loading overlays

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

    // MARK: - Actions

    private func runAPISearch() async {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            apiResults = try await api.search(query: q)
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

    // MARK: - Helpers

    private func formattedDistance(_ meters: CLLocationDistance) -> String {
        let km = meters / 1000
        if km < 1 { return "< 1 km" }
        if km < 10 { return String(format: "%.1f km", km) }
        return String(format: "%.0f km", km)
    }
}
