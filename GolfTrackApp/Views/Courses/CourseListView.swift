import SwiftUI
import SwiftData

struct CourseListView: View {
    @Query(sort: \Course.name) private var courses: [Course]
    @Environment(\.modelContext) private var context
    private var api: GolfCourseAPIService = .shared

    @State private var showAddSheet = false
    @State private var showAPISettings = false

    var body: some View {
        NavigationStack {
            Group {
                if courses.isEmpty {
                    emptyState
                } else {
                    ZStack {
                        AppTheme.bg.ignoresSafeArea()
                        List {
                            ForEach(courses) { course in
                                courseRow(course)
                                    .listRowBackground(AppTheme.card)
                            }
                            .onDelete(perform: delete)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Golfplätze")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Einstellungen", systemImage: "gear") {
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
                        showAddSheet = true
                    }
                    .tint(AppTheme.gold)
                }
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
        for i in offsets { context.delete(courses[i]) }
    }
}
