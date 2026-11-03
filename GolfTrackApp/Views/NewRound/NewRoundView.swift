import SwiftUI
import SwiftData

struct NewRoundView: View {
    @Query(sort: \Course.name) private var courses: [Course]
    @Query(sort: \GolfBag.createdAt) private var bags: [GolfBag]
    @Query(filter: #Predicate<Round> { $0.isComplete }, sort: \Round.date, order: .reverse)
    private var completedRounds: [Round]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("playerName") private var playerName = "Golfer"
    /// Zuletzt gespielte Abschlagfarbe – Vorauswahl für die nächste Runde.
    @AppStorage("lastTeeColor") private var lastTeeColorRaw = TeeColor.yellow.rawValue
    /// Wie oft hier schon eine Runde gestartet wurde – steuert, ob vorher die
    /// Ladeseite mit dem Eintrage-Hinweis kommt (siehe `RoundLoadingView.shouldShow`).
    @AppStorage("roundStartCount") private var roundStartCount = 0

    @State private var selectedCourse: Course?
    @State private var selectedBag: GolfBag?
    @State private var selectedTee: TeeColor?
    @State private var roundDate = Date.now
    @State private var selectedMode: GameMode
    @State private var category: GameModeCategory
    @State private var activeRound: Round?
    @State private var showCourseManager = false
    @State private var showCourseSelector = false
    @State private var otherPlayers: [String]
    @State private var warnMissingNames = false
    @State private var showLoading = false

    private let availableModes = GameMode.allCases.filter(\.isAvailable)
    private let darkText = Color(red: 0.06, green: 0.14, blue: 0.08)

    /// `preselectedCourse` kommt vom QR-Code am Abschlag: Platz steht fest,
    /// alles andere – Bag, Spielform, Mitspieler – wählt der Spieler hier wie
    /// sonst auch.
    init(preselectedMode: GameMode = .strokePlay, preselectedCourse: Course? = nil) {
        _selectedMode = State(initialValue: preselectedMode)
        _category = State(initialValue: preselectedMode.category)
        _selectedCourse = State(initialValue: preselectedCourse)
        let needed = max(1, preselectedMode.minOtherPlayers)
        _otherPlayers = State(initialValue: Array(repeating: "", count: needed))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    courseSection
                    modeSection
                    if !bags.isEmpty { bagSection }
                    if selectedCourse != nil { teeSection }
                    dateSection
                    playerSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.bg.ignoresSafeArea())
            .navigationTitle("Neue Runde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { startButton }
            .onChange(of: selectedMode) { _, mode in
                adjustPlayerCount(for: mode)
                // Auswahl über „Alle erklärt“ kann die Kategorie wechseln.
                if category != mode.category { category = mode.category }
            }
            .onChange(of: selectedCourse) { _, course in
                adoptCatalogTees(for: course)
                pickDefaultTee(for: course)
            }
            .onAppear {
                if selectedCourse == nil, courses.count == 1 {
                    selectedCourse = courses.first
                }
                #if DEBUG
                if selectedCourse == nil, ProcessInfo.processInfo.environment["GOLFTRACK_OPEN"] == "newRound" {
                    selectedCourse = courses.first
                }
                #endif
                if selectedBag == nil {
                    selectedBag = bags.first
                }
                adoptCatalogTees(for: selectedCourse)
                pickDefaultTee(for: selectedCourse)
            }
            .sheet(isPresented: $showCourseManager) { CourseListView(selection: $selectedCourse) }
            .sheet(isPresented: $showCourseSelector) {
                CourseSelectorView(selectedCourse: $selectedCourse)
            }
            .navigationDestination(item: $activeRound) { round in
                ScorecardView(round: round, onRoundFinished: { dismiss() })
            }
        }
        .overlay {
            if showLoading {
                RoundLoadingView(courseName: selectedCourse?.name ?? "") {
                    startRound()
                    withAnimation(.easeOut(duration: 0.35)) { showLoading = false }
                }
                .transition(.opacity)
            }
        }
    }

    // MARK: - Abschnitte

    private func section<Content: View, Accessory: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(AppTheme.textTer)
                Spacer()
                accessory()
            }
            .padding(.horizontal, 4)
            content()
        }
    }

    private func card<Content: View>(padding: CGFloat = 12, @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Platz

    private var courseSection: some View {
        section("Platz") {
            Button {
                Haptics.tap()
                showCourseManager = true
            } label: {
                Label("Platz hinzufügen", systemImage: "plus")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.gold)
            }
        } content: {
            Button {
                Haptics.tap()
                if courses.isEmpty { showCourseManager = true } else { showCourseSelector = true }
            } label: {
                card {
                    HStack(spacing: 12) {
                        Image(systemName: courses.isEmpty ? "plus" : "flag.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(selectedCourse != nil ? darkText : AppTheme.gold)
                            .frame(width: 40, height: 40)
                            .background(selectedCourse != nil ? AppTheme.gold : AppTheme.gold.opacity(0.15),
                                        in: RoundedRectangle(cornerRadius: 11))
                        VStack(alignment: .leading, spacing: 2) {
                            if let course = selectedCourse {
                                Text(course.name)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.text)
                                    .lineLimit(1)
                                Text("\(course.numberOfHoles) Löcher · Par \(course.totalPar)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSec)
                            } else if courses.isEmpty {
                                Text("Ersten Platz hinzufügen")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.gold)
                            } else {
                                Text("Platz wählen …")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textSec)
                            }
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textTer)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Spielform

    private var modesInCategory: [GameMode] {
        availableModes.filter { $0.category == category }
    }

    private var modeSection: some View {
        section("Spielform") {
            NavigationLink {
                GameModePickerView(selectedMode: $selectedMode)
            } label: {
                Text("Alle erklärt")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.gold)
            }
        } content: {
            card {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 0) {
                        categorySegment(.individual, title: "Einzel")
                        categorySegment(.partner, title: "Partner")
                        categorySegment(.team, title: "Team")
                    }
                    .padding(3)
                    .background(AppTheme.cardDark, in: Capsule())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(modesInCategory, id: \.self) { mode in
                                modeChip(mode)
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: selectedMode.sfSymbol)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.gold)
                            .frame(width: 20)
                        Text(modeShortDesc(selectedMode))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func categorySegment(_ value: GameModeCategory, title: LocalizedStringKey) -> some View {
        let selected = category == value
        return Button {
            guard !selected else { return }
            Haptics.selection()
            withAnimation(.snappy) {
                category = value
                if selectedMode.category != value,
                   let first = availableModes.first(where: { $0.category == value }) {
                    selectedMode = first
                }
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? darkText : AppTheme.textSec)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(selected ? AppTheme.gold : .clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Mehrere Formen heißen gleich („Better Ball“) – dann hilft der Untertitel.
    private func chipTitle(_ mode: GameMode) -> String {
        let twins = modesInCategory.filter { $0.displayName == mode.displayName }
        guard twins.count > 1, !mode.subtitle.isEmpty else { return mode.displayName }
        return "\(mode.displayName) · \(mode.subtitle)"
    }

    private func modeChip(_ mode: GameMode) -> some View {
        let selected = selectedMode == mode
        return Button {
            Haptics.selection()
            withAnimation(.snappy) { selectedMode = mode }
        } label: {
            Text(chipTitle(mode))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? AppTheme.gold : AppTheme.text.opacity(0.85))
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(selected ? AppTheme.gold.opacity(0.16) : AppTheme.cardAlt, in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? AppTheme.gold.opacity(0.6) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Bag

    private var bagSection: some View {
        section("Bag") {
            card {
                Menu {
                    ForEach(bags) { bag in
                        Button {
                            Haptics.selection()
                            selectedBag = bag
                        } label: {
                            if selectedBag?.persistentModelID == bag.persistentModelID {
                                Label(bag.name, systemImage: "checkmark")
                            } else {
                                Text(bag.name)
                            }
                        }
                    }
                    Divider()
                    Button {
                        Haptics.selection()
                        selectedBag = nil
                    } label: {
                        Label("Ohne Bag", systemImage: "xmark")
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bag.fill")
                            .font(.title3)
                            .foregroundStyle(selectedBag != nil ? AppTheme.gold : AppTheme.textSec)
                            .frame(width: 28)
                        Text(selectedBag?.name ?? String(localized: "Ohne Bag"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                        Spacer(minLength: 0)
                        if let bag = selectedBag {
                            Text("\(bag.clubs.count) Schläger")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                        }
                        if bags.count > 1 || selectedBag == nil {
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.textTer)
                        }
                    }
                }
            }
        }
    }

    // MARK: Abschlag

    private var teeColors: [TeeColor] { selectedCourse?.availableTeeColors ?? TeeColor.commonSet }

    private var teeSection: some View {
        section("Abschlag") {
            card(padding: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(teeColors) { tee in
                                teeChip(tee)
                            }
                        }
                    }
                    if let info = teeInfo {
                        Text(info)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                            .padding(.horizontal, 6)
                            .padding(.bottom, 2)
                            .contentTransition(.opacity)
                    }
                }
            }
        }
    }

    private func teeChip(_ tee: TeeColor) -> some View {
        let selected = selectedTee == tee
        return Button {
            Haptics.selection()
            withAnimation(.snappy) { selectedTee = tee }
        } label: {
            HStack(spacing: 7) {
                TeeDot(tee: tee, size: 12)
                Text(tee.displayName)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(selected ? AppTheme.gold : AppTheme.text.opacity(0.85))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(selected ? AppTheme.gold.opacity(0.16) : .clear, in: Capsule())
            .overlay(Capsule().strokeBorder(selected ? AppTheme.gold.opacity(0.6) : .clear, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// „CR 71,2 · Slope 130 · 5.533 m“ – nur was für den Abschlag bekannt ist.
    private var teeInfo: String? {
        guard let course = selectedCourse, let tee = course.tee(selectedTee) else { return nil }
        var parts: [String] = []
        if let cr = tee.courseRating { parts.append("CR \(cr.formatted(.number.precision(.fractionLength(1))))") }
        if let slope = tee.slopeRating { parts.append("Slope \(slope)") }
        let total = tee.holeLengths.reduce(0) { $0 + max(0, $1) }
        if total > 0 { parts.append("\(total.formatted()) m") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: Datum

    private var dateSection: some View {
        section("Datum") {
            card(padding: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundStyle(AppTheme.gold)
                        .frame(width: 28)
                    DatePicker("Datum", selection: $roundDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(AppTheme.gold)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: Spieler

    private var handicapText: String {
        HandicapCalculator.displayString(from: completedRounds)
    }

    private var playerSection: some View {
        section("Spieler") {
            card {
                VStack(spacing: 10) {
                    playerRow(initial: String(playerName.prefix(1)).uppercased()) {
                        Text(playerName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.text)
                    } trailing: {
                        Text("HCP \(handicapText)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSec)
                    }

                    if selectedMode.isMultiplayer {
                        ForEach(0..<otherPlayers.count, id: \.self) { i in
                            otherPlayerRow(i)
                        }
                        if otherPlayers.count < selectedMode.maxOtherPlayers {
                            Button {
                                Haptics.tap()
                                withAnimation(.snappy) { otherPlayers.append("") }
                            } label: {
                                Label("Spieler hinzufügen", systemImage: "plus.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.gold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Group {
                if warnMissingNames {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Namen eingeben oder erneut drücken, um ohne Namen zu starten.")
                    }
                } else if selectedMode.isMultiplayer, !playerFooter.isEmpty {
                    Text(playerFooter)
                } else if !selectedMode.isMultiplayer {
                    Text("Mitspieler trägst du bei Partner- und Team-Spielformen ein.")
                }
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSec)
            .padding(.horizontal, 4)
        }
    }

    private func playerRow<Name: View, Trailing: View>(
        initial: String,
        highlight: Bool = false,
        @ViewBuilder name: () -> Name,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Text(initial.isEmpty ? "?" : initial)
                .font(.subheadline.bold())
                .foregroundStyle(darkText)
                .frame(width: 32, height: 32)
                .background((highlight ? Color.orange : AppTheme.gold).opacity(0.85), in: Circle())
            name()
            Spacer(minLength: 0)
            trailing()
        }
    }

    private func otherPlayerRow(_ i: Int) -> some View {
        let isEmpty = otherPlayers[i].trimmingCharacters(in: .whitespaces).isEmpty
        let canRemove = otherPlayers.count > selectedMode.minOtherPlayers
        return playerRow(initial: isEmpty ? "\(i + 2)" : String(otherPlayers[i].prefix(1)).uppercased(),
                         highlight: warnMissingNames && isEmpty) {
            TextField(playerPlaceholder(index: i + 2), text: $otherPlayers[i])
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.text)
                .textInputAutocapitalization(.words)
                .onChange(of: otherPlayers[i]) { _, _ in
                    if warnMissingNames { warnMissingNames = false }
                }
        } trailing: {
            if canRemove {
                Button {
                    Haptics.decrement()
                    withAnimation(.snappy) { _ = otherPlayers.remove(at: i) }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.textTer)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Spieler entfernen")
            }
        }
    }

    // MARK: Start

    private var startButton: some View {
        Button {
            handleStartButton()
        } label: {
            Text(warnMissingNames ? "Ohne Namen starten – erneut drücken" : "Runde starten")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    selectedCourse == nil ? Color.secondary.opacity(0.3)
                        : warnMissingNames ? Color.orange
                        : AppTheme.gold,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .foregroundStyle(selectedCourse == nil ? AppTheme.textSec : darkText)
                .animation(.easeInOut(duration: 0.2), value: warnMissingNames)
        }
        .buttonStyle(.plain)
        .disabled(selectedCourse == nil)
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(AppTheme.bg.opacity(0.96))
    }

    // MARK: - Abschlag-Logik

    /// Gespeicherte Plätze kennen die Farben des Verzeichnisses erst, wenn sie
    /// dort nachgetragen wurden – beim Rundenstart einmal nachziehen.
    private func adoptCatalogTees(for course: Course?) {
        guard let course, course.tees.isEmpty else { return }
        let name = course.name.lowercased()
        guard let entry = CourseCatalogService.shared.allGolfCourses
                .first(where: { $0.name.lowercased() == name }),
              !entry.tees.isEmpty else { return }
        course.tees = entry.tees
    }

    private func pickDefaultTee(for course: Course?) {
        let colors = course?.availableTeeColors ?? TeeColor.commonSet
        if let current = selectedTee, colors.contains(current) { return }
        if let last = TeeColor(rawValue: lastTeeColorRaw), colors.contains(last) {
            selectedTee = last
        } else {
            selectedTee = colors.contains(.yellow) ? .yellow : colors.first
        }
    }

    private func playerPlaceholder(index: Int) -> String {
        switch selectedMode {
        case .matchplay: return "Gegner Name"
        case .betterBallStroke, .betterBallStableford, .scramble2Mann,
             .vierer, .greensome: return "Partner Name"
        case .betterBallMatchplay:
            switch index {
            case 2: return "Partner Name"
            case 3: return "Gegner 1"
            default: return "Gegner 2"
            }
        case .bestBallStroke, .bestBallStableford, .scrambleTeam:
            return "Mitspieler \(index - 1) Name"
        case .skins: return "Spieler \(index) Name"
        default: return "Spieler \(index) Name"
        }
    }

    private var playerFooter: String {
        switch selectedMode {
        case .matchplay: return "Dein Gegner für das Matchplay."
        case .betterBallStroke, .betterBallStableford: return "Dein Partner – der bessere Score pro Loch zählt für das Team."
        case .scramble2Mann: return "Dein Partner – beide schlagen ab, der beste wird gewählt."
        case .vierer: return "Dein Partner – ihr spielt abwechselnd mit einem Ball (Wechselschlag)."
        case .greensome: return "Dein Partner – beide schlagen ab, bester Abschlag gewählt, dann Wechselschlag."
        case .betterBallMatchplay: return "Zuerst dein Partner, dann deine Gegner eintragen. Pro Team zählt der bessere Score."
        case .bestBallStroke, .bestBallStableford: return "Alle Mitspieler eintragen – der beste Score pro Loch zählt fürs Team."
        case .scrambleTeam: return "Alle Mitspieler – alle schlagen ab, bester Abschlag wird gespielt."
        case .skins: return "Spieler, die gegeneinander um Skins spielen."
        default: return ""
        }
    }

    private func adjustPlayerCount(for mode: GameMode) {
        let needed = mode.minOtherPlayers
        if needed == 0 {
            otherPlayers = [""]
            return
        }
        while otherPlayers.count < needed { otherPlayers.append("") }
        while otherPlayers.count > mode.maxOtherPlayers { otherPlayers.removeLast() }
    }

    private func modeShortDesc(_ mode: GameMode) -> String {
        switch mode {
        case .strokePlay: return String(localized: "Klassisches Zählspiel – jeder Schlag zählt")
        case .stableford: return String(localized: "Punkte statt Schläge – Birdie=3, Par=2, Bogey=1")
        case .matchplay: return String(localized: "Loch für Loch gegen einen Gegner")
        case .skins: return String(localized: "Niedrigster Score gewinnt den Skin – Unentschieden trägt über")
        case .erado: return String(localized: "Zählspiel – die schlechtesten Löcher werden gestrichen")
        case .betterBallStroke: return String(localized: "Bester Score pro Loch zählt für das 2er-Team")
        case .betterBallStableford: return String(localized: "Beste Stableford-Punkte pro Loch für das Team")
        case .scramble2Mann: return String(localized: "Beide schlagen ab – bester Abschlag wird gespielt")
        case .vierer: return String(localized: "Ein Ball, zwei Spieler – abwechselnd schlagen (Wechselschlag)")
        case .greensome: return String(localized: "Beide schlagen ab, bester Teeshot – dann Wechselschlag")
        case .betterBallMatchplay: return String(localized: "2 gegen 2 – bester Ball pro Team, Matchplay-Wertung")
        case .bestBallStroke: return String(localized: "3–4 Spieler – bester Score pro Loch zählt für das Team")
        case .bestBallStableford: return String(localized: "3–4 Spieler – beste Stableford-Punkte pro Loch zählen")
        case .scrambleTeam: return String(localized: "3–4 Spieler – alle schlagen ab, bester Abschlag gespielt")
        default: return String(mode.description.prefix(60)) + "…"
        }
    }

    private func handleStartButton() {
        let hasEmptyNames = selectedMode.isMultiplayer &&
            otherPlayers.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }

        if hasEmptyNames && !warnMissingNames {
            Haptics.warning()
            withAnimation(.easeInOut(duration: 0.2)) { warnMissingNames = true }
            return
        }
        warnMissingNames = false
        Haptics.medium()
        let showHint = RoundLoadingView.shouldShow(startCount: roundStartCount)
        roundStartCount += 1
        if showHint {
            withAnimation(.easeIn(duration: 0.25)) { showLoading = true }
        } else {
            startRound()
        }
    }

    private func startRound() {
        guard let course = selectedCourse else { return }
        let round = Round(date: roundDate, course: course, gameMode: selectedMode)
        round.bag = selectedBag
        round.teeColor = selectedTee
        if let tee = selectedTee { lastTeeColorRaw = tee.rawValue }
        let validNames = selectedMode.isMultiplayer ? otherPlayers.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } : []
        round.otherPlayerNames = validNames
        context.insert(round)

        for i in 1...course.numberOfHoles {
            let hole = HoleScore(holeNumber: i, strokes: 0, putts: 0)
            context.insert(hole)
            round.holeScores.append(hole)

            for (idx, name) in validNames.enumerated() {
                let phs = PlayerHoleScore(
                    playerIndex: idx + 1,
                    playerName: name,
                    holeNumber: i,
                    strokes: 0
                )
                context.insert(phs)
                round.playerHoleScores.append(phs)
            }
        }

        activeRound = round
        // Offene-Runde-Erinnerung: falls die Runde morgen früh noch nicht abgeschlossen ist
        Task { await NotificationManager.shared.scheduleOpenRoundReminder(courseName: course.name) }
    }
}
