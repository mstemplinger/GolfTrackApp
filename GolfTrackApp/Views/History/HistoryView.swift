import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(
        filter: #Predicate<Round> { $0.isComplete },
        sort: \Round.date,
        order: .reverse
    ) private var rounds: [Round]
    @Environment(\.modelContext) private var context

    @State private var editMode: EditMode = .inactive
    @State private var roundToDelete: Round?
    @State private var showDeleteAllConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                Group {
                    if rounds.isEmpty {
                        ContentUnavailableView(
                            "Keine Runden",
                            systemImage: "clock",
                            description: Text("Abgeschlossene Runden erscheinen hier")
                        )
                    } else {
                        List {
                            ForEach(rounds) { round in
                                NavigationLink {
                                    RoundDetailView(round: round)
                                } label: {
                                    RoundRowView(round: round)
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        roundToDelete = round
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                            }
                            .onDelete { offsets in
                                for i in offsets { context.delete(rounds[i]) }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .environment(\.editMode, $editMode)
                    }
                }
            }
            .navigationTitle("Verlauf")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !rounds.isEmpty {
                        HStack(spacing: 16) {
                            // Alle löschen
                            if editMode == .active {
                                Button {
                                    showDeleteAllConfirmation = true
                                } label: {
                                    Text("Alle löschen")
                                        .foregroundStyle(.red)
                                        .font(.subheadline)
                                }
                            }
                            // Bearbeiten / Fertig
                            Button {
                                withAnimation {
                                    editMode = editMode == .active ? .inactive : .active
                                }
                            } label: {
                                Text(editMode == .active ? "Fertig" : "Bearbeiten")
                                    .foregroundStyle(AppTheme.gold)
                            }
                        }
                    }
                }
            }
            // Einzelne Runde löschen – Bestätigung
            .confirmationDialog(
                "Runde löschen?",
                isPresented: Binding(
                    get: { roundToDelete != nil },
                    set: { if !$0 { roundToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    if let r = roundToDelete { context.delete(r) }
                    roundToDelete = nil
                }
                Button("Abbrechen", role: .cancel) { roundToDelete = nil }
            } message: {
                if let r = roundToDelete {
                    Text("\(r.course?.name ?? "Unbekannter Platz") · \(r.date.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            // Alle löschen – Bestätigung
            .confirmationDialog(
                "Alle \(rounds.count) Runden löschen?",
                isPresented: $showDeleteAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Alle löschen", role: .destructive) {
                    for round in rounds { context.delete(round) }
                    editMode = .inactive
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }
}
