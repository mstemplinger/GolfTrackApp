import SwiftUI
import SwiftData

struct ClubBagView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GolfClub.order) private var clubs: [GolfClub]
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    @State private var showAddSheet = false
    @State private var detailClub: GolfClub?

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    if clubs.isEmpty {
                        emptyState
                    } else {
                        // Stats summary
                        let measured = clubs.filter { $0.hasUserData }
                        if !measured.isEmpty {
                            summaryCard(measuredCount: measured.count)
                        }

                        // Club list
                        VStack(spacing: 0) {
                            ForEach(Array(clubs.enumerated()), id: \.element.persistentModelID) { index, club in
                                clubRow(club: club)
                                    .onTapGesture { detailClub = club }
                                if index < clubs.count - 1 {
                                    Divider()
                                        .background(AppTheme.cardAlt)
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    }

                    addButton
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Meine Schläger")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if clubs.isEmpty { seedDefaultClubs() }
        }
        .sheet(isPresented: $showAddSheet) { addClubSheet }
        .sheet(item: $detailClub) { club in
            ClubDetailSheet(club: club, distanceUnit: distanceUnit) {
                detailClub = nil
            }
        }
    }

    // MARK: - Summary Card

    private func summaryCard(measuredCount: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(measuredCount) von \(clubs.count) Schlägern gemessen")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Text("Tippe auf einen Schläger für Details & Verlauf")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Club Row

    private func clubRow(club: GolfClub) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(club.hasUserData ? AppTheme.gold.opacity(0.2) : AppTheme.cardAlt)
                    .frame(width: 36, height: 36)
                Image(systemName: "figure.golf")
                    .font(.system(size: 14))
                    .foregroundStyle(club.hasUserData ? AppTheme.gold : AppTheme.textSec)
            }

            // Name + status
            VStack(alignment: .leading, spacing: 2) {
                Text(club.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                if club.hasUserData {
                    Text("Ø aus \(club.shotCount) Messung\(club.shotCount == 1 ? "" : "en")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.gold)
                } else {
                    Text("Voreinstellung")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTer)
                }
            }

            Spacer()

            // Distance
            VStack(alignment: .trailing, spacing: 1) {
                Text(distanceUnit.format(Double(club.averageDistance)))
                    .font(.subheadline.bold())
                    .foregroundStyle(club.hasUserData ? AppTheme.gold : AppTheme.textSec)
                if club.hasUserData && club.shotCount >= 2 {
                    Text("\(distanceUnit.value(Double(club.minDistance)))–\(distanceUnit.value(Double(club.maxDistance))) \(distanceUnit.unitLabel)")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textTer)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                context.delete(club)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTer)
            Text("Keine Schläger")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text)
            Text("Füge deine Schläger hinzu oder lade die Standardausstattung.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
            Button { seedDefaultClubs() } label: {
                Label("Standardschläger laden", systemImage: "arrow.down.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            Label("Schläger hinzufügen", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Add Club Sheet

    private var addClubSheet: some View {
        AddClubSheet(existingCount: clubs.count) { name, dist in
            context.insert(GolfClub(name: name, averageDistance: dist, order: clubs.count))
            showAddSheet = false
        } onCancel: {
            showAddSheet = false
        }
    }

    // MARK: - Seed

    private func seedDefaultClubs() {
        let defaults: [(String, Int)] = [
            ("Driver", 220), ("3 Wood", 195), ("5 Wood", 180),
            ("3 Eisen", 185), ("4 Eisen", 175), ("5 Eisen", 165),
            ("6 Eisen", 155), ("7 Eisen", 145), ("8 Eisen", 130),
            ("9 Eisen", 120), ("PW", 110), ("GW", 95),
            ("SW", 80), ("LW", 60), ("Putter", 10)
        ]
        for (i, (name, dist)) in defaults.enumerated() {
            context.insert(GolfClub(name: name, averageDistance: dist, order: i))
        }
    }
}

// MARK: - Club Detail Sheet

struct ClubDetailSheet: View {
    @Bindable var club: GolfClub
    let distanceUnit: DistanceUnit
    let onDone: () -> Void

    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // Average card
                        averageCard

                        // Default distance adjustment (only when no user data)
                        if !club.hasUserData {
                            defaultDistanceCard
                        }

                        // Measurements list
                        if club.hasUserData {
                            measurementsCard
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(club.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fertig") { onDone() }
                        .foregroundStyle(AppTheme.gold)
                }
                if club.hasUserData {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Zurücksetzen", role: .destructive) {
                            showResetConfirm = true
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
            }
            .confirmationDialog(
                "Alle \(club.shotCount) Messungen löschen?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Messungen löschen", role: .destructive) {
                    club.clearMeasurements()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Der Durchschnitt wird wieder auf die Voreinstellung (\(club.defaultDistance) m) zurückgesetzt.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Average Card

    private var averageCard: some View {
        VStack(spacing: 6) {
            Text(club.hasUserData ? "DEIN DURCHSCHNITT" : "VOREINSTELLUNG")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(AppTheme.textTer)

            Text(distanceUnit.format(Double(club.averageDistance)))
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(club.hasUserData ? AppTheme.gold : AppTheme.textSec)
                .contentTransition(.numericText())

            if club.hasUserData {
                Text("aus \(club.shotCount) Messung\(club.shotCount == 1 ? "" : "en")")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSec)
                if club.shotCount >= 2 {
                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            Text("Min")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTer)
                            Text(distanceUnit.format(Double(club.minDistance)))
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSec)
                        }
                        Divider().frame(height: 28)
                        VStack(spacing: 2) {
                            Text("Max")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTer)
                            Text(distanceUnit.format(Double(club.maxDistance)))
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSec)
                        }
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("Noch keine eigenen Messungen")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTer)
                Text("Schläge werden automatisch beim Aufzeichnen eingetragen.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTer)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Default Distance Card

    private var defaultDistanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VOREINSTELLUNG ANPASSEN")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(AppTheme.textTer)

            HStack(spacing: 20) {
                Button {
                    if club.defaultDistance > 5 { club.defaultDistance -= 5 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(club.defaultDistance > 5 ? AppTheme.gold : AppTheme.textTer)
                }
                .disabled(club.defaultDistance <= 5)

                Text(distanceUnit.format(Double(club.defaultDistance)))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                    .frame(minWidth: 90, alignment: .center)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: club.defaultDistance)

                Button {
                    if club.defaultDistance < 400 { club.defaultDistance += 5 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.gold)
                }
                .disabled(club.defaultDistance >= 400)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Measurements Card

    private var measurementsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ALLE MESSUNGEN")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(AppTheme.textTer)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(club.measuredDistances.enumerated().reversed()), id: \.offset) { i, dist in
                    HStack {
                        Text("Messung \(club.measuredDistances.count - i)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSec)
                        Spacer()
                        Text(distanceUnit.format(dist))
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.gold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    if i > 0 {
                        Divider()
                            .background(AppTheme.cardAlt)
                            .padding(.leading, 16)
                    }
                }
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Add Club Sheet

struct AddClubSheet: View {
    let existingCount: Int
    let onSave: (String, Int) -> Void
    let onCancel: () -> Void

    @State private var name = ""
    @State private var distance = 150

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textSec)
                            .padding(.leading, 4)
                        TextField("z. B. 7 Eisen", text: $name)
                            .font(.body)
                            .foregroundStyle(AppTheme.text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voreingestellte Weite")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textSec)
                            .padding(.leading, 4)
                        HStack(spacing: 16) {
                            Button {
                                if distance > 5 { distance -= 5 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(distance > 5 ? AppTheme.gold : AppTheme.textTer)
                            }
                            .disabled(distance <= 5)

                            Text("\(distance) m")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.gold)
                                .frame(minWidth: 100, alignment: .center)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: distance)

                            Button {
                                if distance < 400 { distance += 5 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(AppTheme.gold)
                            }
                            .disabled(distance >= 400)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))

                        Text("Wird durch eigene Messungen automatisch ersetzt.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTer)
                            .padding(.leading, 4)
                    }

                    Spacer()

                    Button {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, distance)
                    } label: {
                        Text("Hinzufügen")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                name.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? AppTheme.gold.opacity(0.4) : AppTheme.gold,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Schläger hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { onCancel() }
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
