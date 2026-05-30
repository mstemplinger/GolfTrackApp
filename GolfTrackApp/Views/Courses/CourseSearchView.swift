import SwiftUI
import SwiftData

struct CourseSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private var api: GolfCourseAPIService = .shared

    @State private var query = ""
    @State private var results: [APICourse] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selectedCourse: APICourse?
    @State private var isFetchingDetail = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !api.hasAPIKey {
                    missingKeyBanner
                }

                List {
                    if results.isEmpty && !isSearching && !query.isEmpty {
                        ContentUnavailableView.search(text: query)
                    } else {
                        ForEach(results) { course in
                            Button { selectCourse(course) } label: {
                                courseRow(course)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if isSearching {
                        ProgressView("Suche läuft …").frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.background.opacity(0.8))
                    }
                }
            }
            .navigationTitle("Platz suchen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Platzname oder Club")
            .onSubmit(of: .search) { Task { await search() } }
            .onChange(of: query) { _, new in
                if new.isEmpty { results = [] }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .alert("Fehler", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(item: $selectedCourse) { course in
                TeeBoxPickerView(course: course) { savedCourse in
                    context.insert(savedCourse)
                    dismiss()
                }
            }
            .overlay {
                if isFetchingDetail {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Platzdaten laden …")
                            .padding(24)
                            .background(.background, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: - Row

    private func courseRow(_ course: APICourse) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(course.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
            if !course.locationString.isEmpty {
                Label(course.locationString, systemImage: "location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let tees = course.tees {
                let count = (tees.male?.count ?? 0) + (tees.female?.count ?? 0)
                if count > 0 {
                    Label("\(count) Abschlag\(count == 1 ? "" : "-Optionen")", systemImage: "flag")
                        .font(.caption)
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Missing key banner

    private var missingKeyBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "key.slash").foregroundStyle(.orange)
            Text("Kein API-Key – bitte in den Einstellungen eintragen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1))
    }

    // MARK: - Actions

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

    private func selectCourse(_ course: APICourse) {
        // If the search result already has hole data, use it directly.
        if course.preferredTeeBox()?.holes?.isEmpty == false {
            selectedCourse = course
            return
        }
        // Otherwise fetch the full record to get per-hole par values.
        Task {
            isFetchingDetail = true
            defer { isFetchingDetail = false }
            do {
                let full = try await api.getCourse(id: course.id)
                selectedCourse = full
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - TeeBoxPickerView

struct TeeBoxPickerView: View {
    let course: APICourse
    let onSave: (Course) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTeeBox: APITeeBox?

    private var teeBoxes: [APITeeBox] {
        course.allTeeBoxes.filter { $0.holes?.isEmpty == false }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(course.displayName).font(.title3.bold())
                        if !course.locationString.isEmpty {
                            Label(course.locationString, systemImage: "location")
                                .font(.subheadline).foregroundStyle(AppTheme.textSec)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(AppTheme.card)
                }

                Section("Abschlag wählen") {
                    if teeBoxes.isEmpty {
                        Text("Keine Lochwerte verfügbar")
                            .foregroundStyle(AppTheme.textSec)
                            .listRowBackground(AppTheme.card)
                    } else {
                        ForEach(teeBoxes) { tee in
                            Button { selectedTeeBox = tee } label: {
                                teeRow(tee)
                            }
                            .foregroundStyle(AppTheme.text)
                            .listRowBackground(selectedTeeBox?.id == tee.id
                                ? AppTheme.gold.opacity(0.12) : AppTheme.card)
                        }
                    }
                }

                if let tee = selectedTeeBox, let pars = course.parValues(for: tee) {
                    Section("Par pro Loch (\(pars.count) Löcher)") {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 9),
                            spacing: 6
                        ) {
                            ForEach(Array(pars.enumerated()), id: \.offset) { i, par in
                                VStack(spacing: 2) {
                                    Text("\(i + 1)")
                                        .font(.system(size: 9))
                                        .foregroundStyle(AppTheme.textSec)
                                    Text("\(par)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(parColor(par))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(AppTheme.card)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Abschlag wählen")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { selectedTeeBox = teeBoxes.first }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zurück") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Importieren") { importCourse() }
                        .bold()
                        .disabled(selectedTeeBox == nil || course.parValues(for: selectedTeeBox) == nil)
                }
            }
            } // ZStack
        }
    }

    private func teeRow(_ tee: APITeeBox) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(teeColor(tee.teeName))
                        .frame(width: 12, height: 12)
                    Text(tee.teeName ?? "Unbekannt").font(.headline)
                }
                HStack(spacing: 12) {
                    if let holes = tee.numberOfHoles {
                        Text("\(holes) Löcher").font(.caption).foregroundStyle(AppTheme.textSec)
                    }
                    if let par = tee.parTotal {
                        Text("Par \(par)").font(.caption).foregroundStyle(AppTheme.gold)
                    }
                    if let cr = tee.courseRating {
                        Text("CR \(String(format: "%.1f", cr))").font(.caption).foregroundStyle(AppTheme.textSec)
                    }
                    if let sr = tee.slopeRating {
                        Text("Slope \(sr)").font(.caption).foregroundStyle(AppTheme.textSec)
                    }
                }
            }
            Spacer()
            if selectedTeeBox?.id == tee.id {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.gold)
            }
        }
        .padding(.vertical, 4)
    }

    private func importCourse() {
        guard let tee = selectedTeeBox,
              let pars = course.parValues(for: tee) else { return }
        let saved = Course(
            name: course.displayName,
            location: course.locationString,
            numberOfHoles: pars.count,
            parValues: pars,
            courseRating: tee.courseRating ?? 72.0,
            slopeRating: tee.slopeRating ?? 113,
            latitude: course.location?.latitude,
            longitude: course.location?.longitude
        )
        onSave(saved)
        dismiss()
    }

    private func teeColor(_ name: String?) -> Color {
        switch name?.lowercased() {
        case "black": return .black
        case "blue": return .blue
        case "white": return .white.opacity(0.8)
        case "red": return .red
        case "gold", "yellow": return .yellow
        case "green": return AppTheme.gold
        case "silver": return .gray
        default: return .gray.opacity(0.5)
        }
    }

    private func parColor(_ par: Int) -> Color {
        switch par {
        case 3: return .blue
        case 5: return .orange
        default: return .primary
        }
    }
}
