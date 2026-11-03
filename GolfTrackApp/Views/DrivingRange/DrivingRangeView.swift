import SwiftUI
import SwiftData

/// Driving Range: Schläger wählen, geschlagene Weite eintragen, mit früheren
/// Einheiten vergleichen. Eine nicht beendete Einheit wird beim nächsten
/// Öffnen fortgesetzt.
struct DrivingRangeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \GolfBag.createdAt) private var bags: [GolfBag]
    @Query(sort: \RangeSession.date, order: .reverse) private var sessions: [RangeSession]
    @AppStorage(DistanceUnit.storageKey) private var distanceUnit: DistanceUnit = .meters
    @AppStorage("rangeBagName") private var rangeBagName = ""
    @AppStorage("rangeLastClub") private var lastClub = ""

    @State private var session: RangeSession?
    @State private var selectedClub = ""
    /// Weite in der Anzeige-Einheit (m oder y)
    @State private var distance = 150
    @State private var finishedSession: RangeSession?
    @State private var showHistory = false
    @FocusState private var distanceFocused: Bool

    private let gc = GameCenterManager.shared

    // MARK: Schläger

    private var activeBag: GolfBag? {
        bags.first { $0.name == rangeBagName } ?? bags.first
    }

    private var clubNames: [String] {
        let fromBag = activeBag?.sortedClubs.filter { !$0.isPutter }.map(\.name) ?? []
        return fromBag.isEmpty ? RangeClubDefaults.names : fromBag
    }

    // MARK: Vergleichswerte

    /// Alle Schläge vor der laufenden Einheit – die Messlatte zum Vergleich.
    private var earlierShots: [RangeShot] {
        sessions.filter { $0.persistentModelID != session?.persistentModelID }.flatMap(\.shots)
    }

    private var earlierStats: [String: RangeClubStats] { RangeClubStats.byClub(earlierShots) }
    private var sessionStats: [String: RangeClubStats] { RangeClubStats.byClub(session?.shots ?? []) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    sessionHeader
                    clubPicker
                    entryCard
                    if let session, !session.shots.isEmpty {
                        shotList(session)
                    }
                }
                .padding()
                .readableContentWidth()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle("Driving Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") {
                        Haptics.tap()
                        close()
                    }
                    .foregroundStyle(AppTheme.gold)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showHistory = true
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                    .foregroundStyle(AppTheme.gold)
                    .accessibilityLabel("Range-Verlauf")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") { distanceFocused = false }
                }
            }
            .navigationDestination(isPresented: $showHistory) {
                RangeHistoryView()
            }
            .sheet(item: $finishedSession, onDismiss: { dismiss() }) { finished in
                RangeSessionSummaryView(session: finished, earlierShots: earlierShots(before: finished))
                    .preferredColorScheme(.dark)
            }
            .onAppear(perform: setUp)
        }
    }

    // MARK: - Kopf

    private var sessionHeader: some View {
        let shots = session?.shots ?? []
        return HStack(spacing: 0) {
            headerStat("\(shots.count)", "Bälle")
            Divider().frame(height: 34).background(AppTheme.cardAlt)
            headerStat("\(Set(shots.map(\.clubName)).count)", "Schläger")
            Divider().frame(height: 34).background(AppTheme.cardAlt)
            headerStat(longestText(shots), "Weitester")
        }
        .padding(.vertical, 14)
        .cardStyle()
    }

    private func headerStat(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.text)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
    }

    private func longestText(_ shots: [RangeShot]) -> String {
        guard let best = shots.map(\.distanceMeters).max() else { return "–" }
        return distanceUnit.format(best)
    }

    // MARK: - Schlägerwahl

    private var clubPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Schläger wählen")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                if bags.count > 1 {
                    Menu {
                        ForEach(bags) { bag in
                            Button {
                                Haptics.selection()
                                rangeBagName = bag.name
                            } label: {
                                if bag.persistentModelID == activeBag?.persistentModelID {
                                    Label(bag.name, systemImage: "checkmark")
                                } else {
                                    Text(bag.name)
                                }
                            }
                        }
                    } label: {
                        Label(activeBag?.name ?? "", systemImage: "bag.fill")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.gold)
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                ForEach(clubNames, id: \.self) { name in
                    clubChip(name)
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func clubChip(_ name: String) -> some View {
        let selected = name == selectedClub
        let count = sessionStats[name]?.count ?? 0
        return Button {
            Haptics.selection()
            select(name)
        } label: {
            VStack(spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(verbatim: count > 0 ? "\(count)×" : " ")
                    .font(.caption2)
                    .opacity(0.8)
            }
            .foregroundStyle(selected ? Color(red: 0.10, green: 0.22, blue: 0.13) : AppTheme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? AppTheme.gold : AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Eingabe

    private var entryCard: some View {
        VStack(spacing: 14) {
            Text("Wie weit hast du geschlagen?")
                .font(.headline)
                .foregroundStyle(AppTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                stepButton(-5)
                stepButton(-1)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("0", value: $distance, format: .number)
                        .keyboardType(.numberPad)
                        .focused($distanceFocused)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.text)
                        .frame(minWidth: 90)
                    Text(distanceUnit.unitLabel)
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.textSec)
                }
                .frame(maxWidth: .infinity)
                stepButton(1)
                stepButton(5)
            }

            comparisonRow

            Button {
                Haptics.stroke()
                saveShot()
            } label: {
                Label("Schlag speichern", systemImage: "plus.circle.fill")
                    .goldButton()
            }
            .disabled(selectedClub.isEmpty || distance <= 0)
            .opacity(selectedClub.isEmpty || distance <= 0 ? 0.5 : 1)
        }
        .padding(16)
        .cardStyle()
    }

    private func stepButton(_ step: Int) -> some View {
        Button {
            Haptics.selection()
            distance = max(0, distance + step)
        } label: {
            Text(verbatim: step > 0 ? "+\(step)" : "\(step)")
                .font(.subheadline.bold())
                .monospacedDigit()
                .foregroundStyle(AppTheme.text)
                .frame(width: 40, height: 40)
                .background(AppTheme.cardAlt, in: Circle())
        }
        .buttonStyle(.plain)
    }

    /// Ø und Bestweite dieses Schlägers aus früheren Einheiten und von heute.
    @ViewBuilder
    private var comparisonRow: some View {
        let earlier = earlierStats[selectedClub]
        let today = sessionStats[selectedClub]
        if earlier != nil || today != nil {
            HStack(spacing: 10) {
                compareStat("Ø bisher", earlier.map { distanceUnit.format($0.average) } ?? "–")
                compareStat("Bestweite", earlier.map { distanceUnit.format($0.best) } ?? "–")
                compareStat("Ø heute", today.map { distanceUnit.format($0.average) } ?? "–",
                            highlight: delta(today, earlier))
            }
        } else {
            Text("Erster Schlag mit diesem Schläger – ab jetzt kannst du dich vergleichen.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func delta(_ today: RangeClubStats?, _ earlier: RangeClubStats?) -> Color? {
        guard let today, let earlier else { return nil }
        return today.average >= earlier.average ? AppTheme.scoreColor(-1) : AppTheme.scoreColor(1)
    }

    private func compareStat(_ label: LocalizedStringKey, _ value: String, highlight: Color? = nil) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.bold())
                .monospacedDigit()
                .foregroundStyle(highlight ?? AppTheme.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.cardDark, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Schläge dieser Einheit

    private func shotList(_ session: RangeSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Diese Einheit")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Button {
                    Haptics.decrement()
                    undoLastShot()
                } label: {
                    Label("Letzten löschen", systemImage: "arrow.uturn.backward")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.gold)
                }
            }

            ForEach(Array(session.sortedShots.reversed().prefix(12))) { shot in
                HStack {
                    Text(shot.clubName)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    if isRecord(shot) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.gold)
                            .accessibilityLabel("Neue Bestweite")
                    }
                    Text(distanceUnit.format(shot.distanceMeters))
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundStyle(AppTheme.text)
                }
                .padding(.vertical, 4)
            }

            Button {
                Haptics.celebrate()
                finish()
            } label: {
                Label("Einheit beenden", systemImage: "checkmark.circle.fill")
                    .greenButton()
            }
            .padding(.top, 6)
        }
        .padding(16)
        .cardStyle()
    }

    /// Weiter als alles, was dieser Schläger früher geschafft hat.
    private func isRecord(_ shot: RangeShot) -> Bool {
        guard let earlier = earlierStats[shot.clubName] else { return false }
        return shot.distanceMeters > earlier.best
    }

    // MARK: - Aktionen

    private func setUp() {
        if session == nil, let open = sessions.first(where: { $0.endedAt == nil }) {
            session = open
        }
        let start = clubNames.contains(lastClub) ? lastClub : (clubNames.first ?? "")
        select(start)
    }

    private func select(_ name: String) {
        selectedClub = name
        lastClub = name
        // Vorschlag: der letzte Schlag mit diesem Schläger, sonst sein Durchschnitt.
        let last = session?.sortedShots.last { $0.clubName == name }?.distanceMeters
        let guess = last ?? earlierStats[name]?.average
            ?? activeBag?.clubs.first { $0.name == name }.map { Double($0.averageDistance) }
        if let guess { distance = distanceUnit.value(guess) }
    }

    private func saveShot() {
        guard !selectedClub.isEmpty, distance > 0 else { return }
        let meters = distanceUnit == .meters ? Double(distance) : Double(distance) / 1.09361
        let current: RangeSession
        if let session {
            current = session
        } else {
            current = RangeSession()
            context.insert(current)
            session = current
        }
        let shot = RangeShot(clubName: selectedClub, distanceMeters: meters)
        context.insert(shot)
        current.shots.append(shot)
        distanceFocused = false
    }

    private func undoLastShot() {
        guard let session, let last = session.sortedShots.last else { return }
        session.shots.removeAll { $0.persistentModelID == last.persistentModelID }
        context.delete(last)
    }

    private func finish() {
        guard let session else { return }
        session.endedAt = .now
        try? context.save()
        gc.evaluateRangeAchievements(sessions: sessions)
        finishedSession = session
    }

    /// Leere Einheiten nicht aufheben; angefangene bleiben offen und werden fortgesetzt.
    private func close() {
        if let session, session.shots.isEmpty {
            context.delete(session)
        } else {
            gc.evaluateRangeAchievements(sessions: sessions)
        }
        dismiss()
    }

    private func earlierShots(before session: RangeSession) -> [RangeShot] {
        sessions.filter { $0.date < session.date }.flatMap(\.shots)
    }
}
