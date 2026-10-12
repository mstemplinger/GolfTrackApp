import SwiftUI
import SwiftData

struct CourseListView: View {
    @Query(sort: \Course.name) private var courses: [Course]
    @Environment(\.modelContext) private var context
    private var api: GolfCourseAPIService = .shared

    @Environment(\.dismiss) private var dismiss

    @State private var showAddSheet = false
    @State private var showAPISettings = false

    /// Aus dem Rundenstart geöffnet: Ein Tipp auf einen Platz wählt ihn für
    /// die Runde und schließt die Liste. Ein neu hinzugefügter Platz wird
    /// gleich vorgewählt. In Einstellungen/Profil bleibt das `nil`.
    private var selection: Binding<Course?>?

    init(selection: Binding<Course?>? = nil) {
        self.selection = selection
    }

    var body: some View {
        NavigationStack {
            Group {
                if courses.isEmpty {
                    emptyState
                } else {
                    ZStack {
                        AppTheme.bg.ignoresSafeArea()
                        List {
                            Section {
                                ForEach(courses) { course in
                                    selectableRow(course)
                                }
                                .onDelete(perform: delete)
                            } footer: {
                                if selection != nil {
                                    Text("Tippe auf einen Platz, um ihn für die Runde zu wählen.")
                                        .font(.caption)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Golfplätze")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Einstellungen", systemImage: "gear") {
                        Haptics.tap()
                        showAPISettings = true
                    }
                    .foregroundStyle(api.hasAPIKey ? Color.secondary : Color.orange)
                    .overlay(alignment: .topTrailing) {
                        if !api.hasAPIKey {
                            Circle().fill(.orange).frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hinzufügen", systemImage: "plus") {
                        Haptics.tap()
                        showAddSheet = true
                    }
                    .tint(AppTheme.gold)
                }
                if selection != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fertig") {
                            Haptics.tap()
                            dismiss()
                        }
                    }
                }
            }
            .onChange(of: courses.map(\.persistentModelID)) { old, new in
                // Neu hinzugefügten Platz gleich für die Runde vorwählen –
                // egal ob aus der Liste, der Online-Suche, dem Scan oder manuell.
                guard let selection, let added = new.first(where: { !old.contains($0) }) else { return }
                selection.wrappedValue = courses.first { $0.persistentModelID == added }
            }
            .sheet(isPresented: $showAddSheet) {
                AddCourseSheetView { entry in
                    let course = Course(
                        name: entry.name,
                        location: entry.location,
                        numberOfHoles: entry.holes,
                        parValues: entry.parValues.isEmpty ? nil : entry.parValues,
                        courseRating: entry.courseRating,
                        slopeRating: entry.slopeRating,
                        hcpValues: entry.hcpValues,
                        holeLengths: entry.holeLengths,
                        facilityNotes: entry.facilityNotes,
                        latitude: entry.lat,
                        longitude: entry.lon,
                        teeLatitudes:  entry.teeLatitudes,
                        teeLongitudes: entry.teeLongitudes,
                        flagLatitudes:  entry.flagLatitudes,
                        flagLongitudes: entry.flagLongitudes
                    )
                    context.insert(course)
                }
            }
            .sheet(isPresented: $showAPISettings) { APIKeySettingsView() }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "flag.slash")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Noch keine Golfplätze")
                .font(.title3.bold())
            Text("Suche weltweit nach Plätzen oder lege einen manuell an.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Button {
                Haptics.tap()
                showAddSheet = true
            } label: {
                Label("Golfplatz hinzufügen", systemImage: "plus")
                    .frame(maxWidth: 240)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.gold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Row

    @ViewBuilder
    private func selectableRow(_ course: Course) -> some View {
        if let selection {
            let isSelected = selection.wrappedValue?.persistentModelID == course.persistentModelID
            Button {
                Haptics.selection()
                selection.wrappedValue = course
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    courseRow(course)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? AppTheme.gold : AppTheme.textTer)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(isSelected ? AppTheme.gold.opacity(0.08) : AppTheme.card)
        } else {
            courseRow(course)
                .listRowBackground(AppTheme.card)
        }
    }

    private func courseRow(_ course: Course) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name).font(.headline)
                HStack(spacing: 12) {
                    if !course.location.isEmpty {
                        Label(course.location, systemImage: "location")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Label("\(course.numberOfHoles) Loch", systemImage: "flag")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Par \(course.totalPar)")
                        .font(.caption.bold()).foregroundStyle(AppTheme.gold)
                }
            }
            Spacer()
            if course.hasHolePositions {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(AppTheme.gold)
                    .font(.system(size: 18))
                    .help("Loch- & Abschlagpositionen gespeichert")
            }
        }
        .padding(.vertical, 4)
    }

    private func delete(at offsets: IndexSet) {
        Haptics.warning()
        for i in offsets { context.delete(courses[i]) }
    }
}
