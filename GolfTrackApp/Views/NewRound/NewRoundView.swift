import SwiftUI
import SwiftData

struct NewRoundView: View {
    @Query(sort: \Course.name) private var courses: [Course]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCourse: Course?
    @State private var roundDate = Date.now
    @State private var selectedMode: GameMode
    @State private var activeRound: Round?
    @State private var showCourseManager = false
    @State private var showCourseSelector = false
    @State private var otherPlayers: [String]
    @State private var warnMissingNames = false

    private let availableModes = GameMode.allCases.filter(\.isAvailable)

    init(preselectedMode: GameMode = .strokePlay) {
        _selectedMode = State(initialValue: preselectedMode)
        let needed = max(1, preselectedMode.minOtherPlayers)
        _otherPlayers = State(initialValue: Array(repeating: "", count: needed))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Course
                Section {
                    if courses.isEmpty {
                        Button { showCourseManager = true } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AppTheme.gold)
                                Text("Ersten Platz hinzufügen")
                                    .foregroundStyle(AppTheme.gold)
                            }
                        }
                        .listRowBackground(AppTheme.card)
                    } else {
                        // Tappable row that opens the location-aware selector
                        Button { showCourseSelector = true } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(selectedCourse != nil ? AppTheme.gold : AppTheme.textSec)
                                VStack(alignment: .leading, spacing: 2) {
                                    if let course = selectedCourse {
                                        Text(course.name)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppTheme.text)
                                        Text("\(course.numberOfHoles) Löcher · Par \(course.totalPar)")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSec)
                                    } else {
                                        Text("Platz wählen …")
                                            .foregroundStyle(AppTheme.textSec)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTer)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(AppTheme.card)
                    }
                } header: {
                    HStack {
                        Text("Platz")
                        Spacer()
                        Button {
                            showCourseManager = true
                        } label: {
                            Label("Platz hinzufügen", systemImage: "plus")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.gold)
                        }
                        .textCase(nil)
                    }
                }

                // Date
                Section("Datum") {
                    DatePicker("Datum", selection: $roundDate, displayedComponents: .date)
                        .tint(AppTheme.gold)
                        .listRowBackground(AppTheme.card)
                }

                // Game mode
                Section("Spielmodus") {
                    NavigationLink {
                        GameModePickerView(selectedMode: $selectedMode)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedMode.sfSymbol)
                                .font(.title3)
                                .foregroundStyle(AppTheme.gold)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedMode.displayName).font(.headline)
                                Text(modeShortDesc(selectedMode)).font(.caption).foregroundStyle(AppTheme.textSec)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.card)
                }

                // Player names for multiplayer modes
                if selectedMode.isMultiplayer {
                    Section {
                        ForEach(0..<otherPlayers.count, id: \.self) { i in
                            let isEmpty = otherPlayers[i].trimmingCharacters(in: .whitespaces).isEmpty
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(warnMissingNames && isEmpty ? .red : AppTheme.gold)
                                    .frame(width: 24)
                                TextField(playerPlaceholder(index: i + 2), text: $otherPlayers[i])
                                    .onChange(of: otherPlayers[i]) { _, _ in
                                        if warnMissingNames { warnMissingNames = false }
                                    }
                            }
                            .listRowBackground(
                                warnMissingNames && isEmpty
                                    ? Color.red.opacity(0.12)
                                    : AppTheme.card
                            )
                        }
                        if otherPlayers.count < selectedMode.maxOtherPlayers {
                            Button {
                                otherPlayers.append("")
                            } label: {
                                Label("Spieler hinzufügen", systemImage: "plus")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.gold)
                            }
                            .listRowBackground(AppTheme.card)
                        }
                        if otherPlayers.count > selectedMode.minOtherPlayers {
                            Button(role: .destructive) {
                                otherPlayers.removeLast()
                            } label: {
                                Label("Spieler entfernen", systemImage: "minus")
                                    .font(.subheadline)
                            }
                            .listRowBackground(AppTheme.card)
                        }
                    } header: {
                        Text("Spieler")
                    } footer: {
                        if warnMissingNames {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Namen eingeben oder erneut drücken, um ohne Namen zu starten.")
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                        } else {
                            Text(playerFooter)
                                .font(.caption)
                        }
                    }
                }

            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.bg)
            .navigationTitle("Neue Runde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
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
                        .foregroundStyle(.white)
                        .animation(.easeInOut(duration: 0.2), value: warnMissingNames)
                }
                .buttonStyle(.plain)
                .disabled(selectedCourse == nil)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(AppTheme.card)
            }
            .onChange(of: selectedMode) { _, mode in
                adjustPlayerCount(for: mode)
            }
            .onAppear {
                if selectedCourse == nil, courses.count == 1 {
                    selectedCourse = courses.first
                }
            }
            .sheet(isPresented: $showCourseManager) { CourseListView() }
            .sheet(isPresented: $showCourseSelector) {
                CourseSelectorView(selectedCourse: $selectedCourse)
            }
            .navigationDestination(item: $activeRound) { round in
                ScorecardView(round: round, onRoundFinished: { dismiss() })
            }
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
        case .strokePlay: return "Klassisches Zählspiel – jeder Schlag zählt"
        case .stableford: return "Punkte statt Schläge – Birdie=3, Par=2, Bogey=1"
        case .matchplay: return "Loch für Loch gegen einen Gegner"
        case .skins: return "Niedrigster Score gewinnt den Skin – Unentschieden trägt über"
        case .erado: return "Zählspiel – die schlechtesten Löcher werden gestrichen"
        case .betterBallStroke: return "Bester Score pro Loch zählt für das 2er-Team"
        case .betterBallStableford: return "Beste Stableford-Punkte pro Loch für das Team"
        case .scramble2Mann: return "Beide schlagen ab – bester Abschlag wird gespielt"
        case .vierer: return "Ein Ball, zwei Spieler – abwechselnd schlagen (Wechselschlag)"
        case .greensome: return "Beide schlagen ab, bester Teeshot – dann Wechselschlag"
        case .betterBallMatchplay: return "2 gegen 2 – bester Ball pro Team, Matchplay-Wertung"
        case .bestBallStroke: return "3–4 Spieler – bester Score pro Loch zählt für das Team"
        case .bestBallStableford: return "3–4 Spieler – beste Stableford-Punkte pro Loch zählen"
        case .scrambleTeam: return "3–4 Spieler – alle schlagen ab, bester Abschlag gespielt"
        default: return String(mode.description.prefix(60)) + "…"
        }
    }

    private func handleStartButton() {
        let hasEmptyNames = selectedMode.isMultiplayer &&
            otherPlayers.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }

        if hasEmptyNames && !warnMissingNames {
            withAnimation(.easeInOut(duration: 0.2)) { warnMissingNames = true }
            return
        }
        warnMissingNames = false
        startRound()
    }

    private func startRound() {
        guard let course = selectedCourse else { return }
        let round = Round(date: roundDate, course: course, gameMode: selectedMode)
        let validNames = selectedMode.isMultiplayer ? otherPlayers.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty } : []
        round.otherPlayerNames = validNames
        context.insert(round)

        for i in 1...course.numberOfHoles {
            let par = course.parValues[i - 1]
            let hole = HoleScore(holeNumber: i, strokes: 0, putts: 0)
            context.insert(hole)
            round.holeScores.append(hole)

            for (idx, name) in validNames.enumerated() {
                let phs = PlayerHoleScore(
                    playerIndex: idx + 1,
                    playerName: name,
                    holeNumber: i,
                    strokes: par
                )
                context.insert(phs)
                round.playerHoleScores.append(phs)
            }
        }

        activeRound = round
    }
}
