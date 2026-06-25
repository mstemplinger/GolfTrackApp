import SwiftUI
import SwiftData

// MARK: - Bag Manager (Übersicht aller Bags)

struct BagManagerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GolfBag.createdAt) private var bags: [GolfBag]
    @Query(sort: \GolfClub.order) private var allClubs: [GolfClub]

    @State private var showAddBag = false
    @State private var newBagName = ""
    @State private var renamingBag: GolfBag?
    @State private var renameDraft = ""

    var body: some View {
        List {
            if bags.isEmpty {
                Section {
                    emptyState
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
            } else {
                Section {
                    ForEach(bags) { bag in
                        NavigationLink(destination: ClubBagView(bag: bag)) {
                            bagRowContent(bag)
                        }
                        .listRowBackground(AppTheme.card)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                context.delete(bag)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                            Button {
                                renameDraft = bag.name
                                renamingBag = bag
                            } label: {
                                Label("Umbenennen", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
            Section {
                addBagButton
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.bg)
        .navigationTitle("Schläger-Bags")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { migrateLegacyClubs() }
        .alert("Neues Bag", isPresented: $showAddBag) {
            TextField("z. B. Turnier-Bag", text: $newBagName)
            Button("Erstellen") {
                let name = newBagName.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                context.insert(GolfBag(name: name))
                newBagName = ""
            }
            Button("Abbrechen", role: .cancel) { newBagName = "" }
        }
        .alert("Bag umbenennen", isPresented: Binding(
            get: { renamingBag != nil },
            set: { if !$0 { renamingBag = nil } }
        )) {
            TextField("Name", text: $renameDraft)
            Button("Speichern") {
                let name = renameDraft.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { renamingBag?.name = name }
                renamingBag = nil
            }
            Button("Abbrechen", role: .cancel) { renamingBag = nil }
        }
    }

    private func bagRowContent(_ bag: GolfBag) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.gold.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "bag.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.gold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(bag.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                let putterCount = bag.clubs.filter(\.isPutter).count
                let desc = "\(bag.clubs.count) Schläger" + (putterCount > 0 ? " · \(putterCount) Putter" : "")
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTer)
            Text("Noch keine Bags")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text)
            Text("Erstelle dein erstes Schläger-Bag.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
            Button {
                let bag = GolfBag(name: "Standard")
                context.insert(bag)
                seedDefaultClubs(into: bag)
            } label: {
                Label("Standard-Bag erstellen", systemImage: "arrow.down.circle.fill")
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

    private var addBagButton: some View {
        Button { showAddBag = true } label: {
            Label("Neues Bag erstellen", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func migrateLegacyClubs() {
        let orphaned = allClubs.filter { $0.bag == nil }
        guard !orphaned.isEmpty else { return }
        let bag = GolfBag(name: "Standard")
        context.insert(bag)
        for club in orphaned.sorted(by: { $0.order < $1.order }) {
            if club.name.lowercased() == "putter" { club.isPutter = true }
            club.bag = bag
            bag.clubs.append(club)
        }
    }

    private func seedDefaultClubs(into bag: GolfBag) {
        let defaults: [(String, Int, Bool)] = [
            ("Driver", 220, false), ("3 Wood", 195, false), ("5 Wood", 180, false),
            ("3 Eisen", 185, false), ("4 Eisen", 175, false), ("5 Eisen", 165, false),
            ("6 Eisen", 155, false), ("7 Eisen", 145, false), ("8 Eisen", 130, false),
            ("9 Eisen", 120, false), ("PW", 110, false), ("GW", 95, false),
            ("SW", 80, false), ("LW", 60, false), ("Putter", 10, true)
        ]
        for (i, (name, dist, isPutter)) in defaults.enumerated() {
            let club = GolfClub(name: name, averageDistance: dist, order: i, isPutter: isPutter)
            club.bag = bag
            context.insert(club)
            bag.clubs.append(club)
        }
    }
}

// MARK: - Club Bag View (ein Bag)

struct ClubBagView: View {
    @Bindable var bag: GolfBag
    @Environment(\.modelContext) private var context
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters

    @State private var showAddSheet = false
    @State private var detailClub: GolfClub?

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    let clubs = bag.sortedClubs
                    if clubs.isEmpty {
                        emptyState
                    } else {
                        let measured = clubs.filter { $0.hasUserData }
                        if !measured.isEmpty {
                            summaryCard(measuredCount: measured.count, total: clubs.count)
                        }
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
        .navigationTitle(bag.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddSheet) { addClubSheet }
        .sheet(item: $detailClub) { club in
            ClubDetailSheet(club: club, distanceUnit: distanceUnit) { detailClub = nil }
        }
    }

    private func summaryCard(measuredCount: Int, total: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(measuredCount) von \(total) Schlägern gemessen")
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

    private func clubRow(club: GolfClub) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(club.isPutter ? Color.blue.opacity(0.18) : (club.hasUserData ? AppTheme.gold.opacity(0.2) : AppTheme.cardAlt))
                    .frame(width: 36, height: 36)
                Image(systemName: club.isPutter ? "flag.fill" : "figure.golf")
                    .font(.system(size: 14))
                    .foregroundStyle(club.isPutter ? Color.blue : (club.hasUserData ? AppTheme.gold : AppTheme.textSec))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(club.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    if club.isPutter {
                        Text("PUTTER")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15), in: Capsule())
                    }
                }
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
            Button(role: .destructive) { context.delete(club) } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.golf")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTer)
            Text("Keine Schläger")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text)
            Text("Füge deine Schläger zu diesem Bag hinzu.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var addButton: some View {
        Button { showAddSheet = true } label: {
            Label("Schläger hinzufügen", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var addClubSheet: some View {
        AddClubSheet(bag: bag) { name, dist, isPutter in
            let club = GolfClub(name: name, averageDistance: dist, order: bag.clubs.count, isPutter: isPutter)
            club.bag = bag
            context.insert(club)
            bag.clubs.append(club)
        } onDone: {
            showAddSheet = false
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
                        averageCard
                        putterToggleCard
                        if !club.hasUserData { defaultDistanceCard }
                        if club.hasUserData { measurementsCard }
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
                    Button("Fertig") { onDone() }.foregroundStyle(AppTheme.gold)
                }
                if club.hasUserData {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Zurücksetzen", role: .destructive) { showResetConfirm = true }
                            .font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .confirmationDialog(
                "Alle \(club.shotCount) Messungen löschen?",
                isPresented: $showResetConfirm, titleVisibility: .visible
            ) {
                Button("Messungen löschen", role: .destructive) { club.clearMeasurements() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Der Durchschnitt wird auf die Voreinstellung (\(club.defaultDistance) m) zurückgesetzt.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var putterToggleCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "flag.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Ist ein Putter")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Text("Putts werden beim Schlag automatisch hochgezählt")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer()
            Toggle("", isOn: $club.isPutter)
                .labelsHidden()
                .tint(.blue)
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

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
                    .font(.subheadline).foregroundStyle(AppTheme.textSec)
                if club.shotCount >= 2 {
                    HStack(spacing: 20) {
                        VStack(spacing: 2) {
                            Text("Min").font(.caption).foregroundStyle(AppTheme.textTer)
                            Text(distanceUnit.format(Double(club.minDistance))).font(.caption.bold()).foregroundStyle(AppTheme.textSec)
                        }
                        Divider().frame(height: 28)
                        VStack(spacing: 2) {
                            Text("Max").font(.caption).foregroundStyle(AppTheme.textTer)
                            Text(distanceUnit.format(Double(club.maxDistance))).font(.caption.bold()).foregroundStyle(AppTheme.textSec)
                        }
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("Noch keine eigenen Messungen").font(.caption).foregroundStyle(AppTheme.textTer)
                Text("Schläge werden automatisch beim Aufzeichnen eingetragen.")
                    .font(.caption).foregroundStyle(AppTheme.textTer).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var defaultDistanceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VOREINSTELLUNG ANPASSEN")
                .font(.system(size: 10, weight: .semibold)).tracking(2).foregroundStyle(AppTheme.textTer)
            HStack(spacing: 20) {
                Button { if club.defaultDistance > 5 { club.defaultDistance -= 5 } } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 36))
                        .foregroundStyle(club.defaultDistance > 5 ? AppTheme.gold : AppTheme.textTer)
                }.disabled(club.defaultDistance <= 5)
                Text(distanceUnit.format(Double(club.defaultDistance)))
                    .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.text)
                    .frame(minWidth: 90, alignment: .center)
                    .contentTransition(.numericText()).animation(.snappy, value: club.defaultDistance)
                Button { if club.defaultDistance < 400 { club.defaultDistance += 5 } } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 36)).foregroundStyle(AppTheme.gold)
                }.disabled(club.defaultDistance >= 400)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var measurementsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ALLE MESSUNGEN")
                .font(.system(size: 10, weight: .semibold)).tracking(2).foregroundStyle(AppTheme.textTer).padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(Array(club.measuredDistances.enumerated().reversed()), id: \.offset) { i, dist in
                    HStack {
                        Text("Messung \(club.measuredDistances.count - i)").font(.subheadline).foregroundStyle(AppTheme.textSec)
                        Spacer()
                        Text(distanceUnit.format(dist)).font(.subheadline.bold()).foregroundStyle(AppTheme.gold)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 11)
                    if i > 0 { Divider().background(AppTheme.cardAlt).padding(.leading, 16) }
                }
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Add Club Sheet

struct AddClubSheet: View {
    @Bindable var bag: GolfBag
    let onAdd: (String, Int, Bool) -> Void
    let onDone: () -> Void

    private var existingNames: Set<String> { Set(bag.clubs.map(\.name)) }

    @State private var showCustomForm = false
    @State private var customName = ""
    @State private var customDist = 150
    @State private var customIsPutter = false

    // Vordefinierte Schläger nach Kategorie
    private let categories: [(String, [(String, Int, Bool)])] = [
        ("Hölzer", [
            ("Driver", 220, false), ("3 Wood", 195, false),
            ("5 Wood", 180, false), ("7 Wood", 165, false),
        ]),
        ("Hybride", [
            ("2 Hybrid", 195, false), ("3 Hybrid", 185, false),
            ("4 Hybrid", 175, false), ("5 Hybrid", 165, false),
        ]),
        ("Eisen", [
            ("2 Eisen", 200, false), ("3 Eisen", 185, false),
            ("4 Eisen", 175, false), ("5 Eisen", 165, false),
            ("6 Eisen", 155, false), ("7 Eisen", 145, false),
            ("8 Eisen", 130, false), ("9 Eisen", 120, false),
        ]),
        ("Wedges", [
            ("PW", 110, false), ("GW", 95, false),
            ("AW", 90, false), ("52°", 88, false),
            ("SW", 80, false), ("54°", 83, false),
            ("56°", 78, false), ("58°", 68, false),
            ("LW", 60, false), ("60°", 55, false),
        ]),
        ("Putter", [
            ("Putter", 10, true),
        ]),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        customSection
                        ForEach(categories, id: \.0) { category, clubs in
                            categorySection(title: category, clubs: clubs)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Schläger hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { onDone() }
                        .font(.headline)
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func categorySection(title: String, clubs: [(String, Int, Bool)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.textTer)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(clubs.enumerated()), id: \.offset) { index, club in
                    let (name, dist, isPutter) = club
                    let added = existingNames.contains(name)
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isPutter ? Color.blue.opacity(0.15) : AppTheme.gold.opacity(0.12))
                                .frame(width: 34, height: 34)
                            Image(systemName: isPutter ? "flag.fill" : "figure.golf")
                                .font(.system(size: 13))
                                .foregroundStyle(isPutter ? Color.blue : AppTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(name)
                                .font(.subheadline.bold())
                                .foregroundStyle(added ? AppTheme.textTer : AppTheme.text)
                            Text(isPutter ? "Putter · Auto-Putts" : "Ø \(dist) m")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textTer)
                        }
                        Spacer()
                        if added {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.green.opacity(0.6))
                        } else {
                            Button {
                                onAdd(name, dist, isPutter)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.gold)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .opacity(added ? 0.5 : 1)
                    if index < clubs.count - 1 {
                        Divider().background(AppTheme.cardAlt).padding(.leading, 62)
                    }
                }
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EIGENER SCHLÄGER")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(AppTheme.textTer)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showCustomForm.toggle() }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.cardAlt)
                                .frame(width: 34, height: 34)
                            Image(systemName: showCustomForm ? "minus" : "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.textSec)
                        }
                        Text("Schläger manuell eingeben")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSec)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if showCustomForm {
                    Divider().background(AppTheme.cardAlt)
                    VStack(spacing: 16) {
                        TextField("Name", text: $customName)
                            .font(.body)
                            .foregroundStyle(AppTheme.text)
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))

                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(Color.blue.opacity(0.15)).frame(width: 34, height: 34)
                                Image(systemName: "flag.fill").font(.system(size: 13)).foregroundStyle(.blue)
                            }
                            Text("Ist ein Putter").font(.subheadline).foregroundStyle(AppTheme.text)
                            Spacer()
                            Toggle("", isOn: $customIsPutter).labelsHidden().tint(.blue)
                        }

                        if !customIsPutter {
                            HStack(spacing: 16) {
                                Button { if customDist > 5 { customDist -= 5 } } label: {
                                    Image(systemName: "minus.circle.fill").font(.system(size: 32))
                                        .foregroundStyle(customDist > 5 ? AppTheme.gold : AppTheme.textTer)
                                }.disabled(customDist <= 5)
                                Text("\(customDist) m")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.gold)
                                    .frame(minWidth: 80, alignment: .center)
                                    .contentTransition(.numericText()).animation(.snappy, value: customDist)
                                Button { if customDist < 400 { customDist += 5 } } label: {
                                    Image(systemName: "plus.circle.fill").font(.system(size: 32)).foregroundStyle(AppTheme.gold)
                                }.disabled(customDist >= 400)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        Button {
                            let trimmed = customName.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            onAdd(trimmed, customIsPutter ? 10 : customDist, customIsPutter)
                            customName = ""
                            customIsPutter = false
                            customDist = 150
                            withAnimation { showCustomForm = false }
                        } label: {
                            Text("Hinzufügen")
                                .font(.headline)
                                .foregroundStyle(Color(red: 0.10, green: 0.22, blue: 0.13))
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(
                                    customName.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? AppTheme.gold.opacity(0.4) : AppTheme.gold,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                        }
                        .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                }
            }
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
