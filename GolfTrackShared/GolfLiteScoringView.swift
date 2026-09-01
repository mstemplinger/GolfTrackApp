import SwiftUI

/// Die schlanke Golf-Zählkarte: Schläge je Loch, Stand gegen Par, sonst nichts.
///
/// Was hier bewusst fehlt – Schlagerfassung, Karte, Positions-Tracking,
/// Statistik, Handicap – bewirbt `FullAppFeaturesCard` unter der Karte. Der
/// Gast soll wissen, was er verpasst, ohne dass ihm die Zählkarte zugebaut
/// wird.
struct GolfLiteScoringView: View {

    let course: GolfLiteCourse

    @State private var strokes: [Int]
    @State private var currentHole: Int
    @State private var showResult = false
    @Environment(\.dismiss) private var dismiss

    init(course: GolfLiteCourse, resuming saved: SavedGolfLiteRound? = nil) {
        self.course = course
        _strokes = State(initialValue: saved?.strokes.count == course.holes
                         ? saved!.strokes
                         : Array(repeating: 0, count: course.holes))
        _currentHole = State(initialValue: saved?.currentHole ?? 0)
    }

    private var par: Int? { course.par(at: currentHole) }
    private var total: Int { strokes.reduce(0, +) }

    /// Stand gegen Par über die gespielten Löcher.
    private var toPar: Int? {
        guard course.hasPar else { return nil }
        var diff = 0
        for (index, value) in strokes.enumerated() where value > 0 {
            diff += value - course.parValues[index]
        }
        return diff
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            ScrollView {
                VStack(spacing: 14) {
                    holeCard
                    totalsCard
                    FullAppFeaturesCard()
                }
                .padding()
            }
            bottomNav
        }
        .appBackground()
        .navigationTitle("Loch \(currentHole + 1) / \(course.holes)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ergebnis") { showResult = true }
                    .foregroundStyle(AppTheme.gold)
            }
        }
        .sheet(isPresented: $showResult) {
            GolfLiteResultView(course: course, strokes: strokes, onFinish: finish)
        }
        .onAppear(perform: persist)
        .onChange(of: strokes) { persist() }
        .onChange(of: currentHole) { persist() }
    }

    // MARK: – Bausteine

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(.secondary.opacity(0.15))
                Rectangle()
                    .fill(AppTheme.gold)
                    .frame(width: geo.size.width * CGFloat(currentHole + 1) / CGFloat(course.holes))
                    .animation(.easeInOut(duration: 0.25), value: currentHole)
            }
        }
        .frame(height: 3)
    }

    private var holeCard: some View {
        VStack(spacing: 16) {
            if let par {
                Text("Par \(par)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
            }

            Text("\(strokes[currentHole])")
                .font(.system(size: 88, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.scoreColor(scoreToPar))
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.2), value: strokes[currentHole])

            if let label = scoreLabel {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.scoreColor(scoreToPar))
            }

            HStack(spacing: 14) {
                stepButton(symbol: "minus", enabled: strokes[currentHole] > 0) {
                    if strokes[currentHole] > 0 { strokes[currentHole] -= 1 }
                }
                stepButton(symbol: "plus", enabled: strokes[currentHole] < 20) {
                    if strokes[currentHole] < 20 { strokes[currentHole] += 1 }
                }
            }
        }
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))
    }

    /// Nur wenn das Loch gespielt ist – „Par" bei null Schlägen wäre gelogen.
    private var scoreToPar: Int? {
        guard let par, strokes[currentHole] > 0 else { return nil }
        return strokes[currentHole] - par
    }

    private var scoreLabel: LocalizedStringKey? {
        guard let diff = scoreToPar else { return nil }
        switch diff {
        case ..<(-2): return "Albatros"
        case -2:      return "Eagle"
        case -1:      return "Birdie"
        case 0:       return "Par"
        case 1:       return "Bogey"
        case 2:       return "Doppelbogey"
        default:      return "Über Par"
        }
    }

    private func stepButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title2.bold())
                .foregroundStyle(enabled ? .white : .white.opacity(0.25))
                .frame(width: 88, height: 56)
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var totalsCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Gesamt").font(.caption).foregroundStyle(.secondary)
                Text("\(total)").font(.title3.bold())
            }
            Spacer()
            if let toPar {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Gegen Par").font(.caption).foregroundStyle(.secondary)
                    Text(toPar == 0 ? "Par" : (toPar > 0 ? "+\(toPar)" : "\(toPar)"))
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.scoreColor(toPar))
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var bottomNav: some View {
        HStack(spacing: 10) {
            Button {
                if currentHole > 0 { currentHole -= 1 }
            } label: {
                Label("Zurück", systemImage: "chevron.left")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(currentHole > 0 ? .white : .white.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(currentHole == 0)

            Button {
                if currentHole < course.holes - 1 { currentHole += 1 } else { showResult = true }
            } label: {
                Label(currentHole < course.holes - 1 ? "Weiter" : "Ergebnis",
                      systemImage: currentHole < course.holes - 1 ? "chevron.right" : "flag.checkered")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: – Ablage

    private func persist() {
        GolfLiteStore.save(SavedGolfLiteRound(
            courseID: course.id,
            courseName: course.name,
            parValues: course.parValues,
            strokes: strokes,
            currentHole: currentHole,
            savedAt: Date()
        ))
    }

    private func finish() {
        GolfLiteStore.appendToHistory(SavedGolfLiteRound(
            courseID: course.id,
            courseName: course.name,
            parValues: course.parValues,
            strokes: strokes,
            currentHole: currentHole,
            savedAt: Date()
        ))
        GolfLiteStore.clear()
        NotificationCenter.default.post(name: .minigolfRoundFinished, object: nil)
        showResult = false
        dismiss()
    }
}

// MARK: - Ergebnis

struct GolfLiteResultView: View {

    let course: GolfLiteCourse
    let strokes: [Int]
    let onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var total: Int { strokes.reduce(0, +) }
    private var played: Int { strokes.filter { $0 > 0 }.count }
    private var toPar: Int? {
        guard course.hasPar else { return nil }
        var diff = 0
        for (index, value) in strokes.enumerated() where value > 0 {
            diff += value - course.parValues[index]
        }
        return diff
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text("\(total)")
                            .font(.system(size: 76, weight: .bold, design: .rounded))
                        if let toPar {
                            Text(toPar == 0 ? "Par" : (toPar > 0 ? "+\(toPar)" : "\(toPar)"))
                                .font(.title3.bold())
                                .foregroundStyle(AppTheme.scoreColor(toPar))
                        }
                        Text("Löcher gespielt: \(played) von \(course.holes)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18))

                    holeGrid
                    FullAppFeaturesCard()

                    Button(action: onFinish) {
                        Text("Runde beenden").goldButton()
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(course.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Weiterspielen") { dismiss() }
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
    }

    private var holeGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 9)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Löcher").font(.headline)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<course.holes, id: \.self) { hole in
                    VStack(spacing: 2) {
                        Text("\(hole + 1)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text(strokes[hole] > 0 ? "\(strokes[hole])" : "–")
                            .font(.footnote.bold())
                            .foregroundStyle(AppTheme.scoreColor(
                                strokes[hole] > 0 ? course.par(at: hole).map { strokes[hole] - $0 } : nil))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 7))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Hinweis auf die volle App

/// Was die schlanke Zählkarte nicht kann. Steht unter der Karte, nicht davor –
/// erst zählen lassen, dann werben.
struct FullAppFeaturesCard: View {

    private let features: [(String, LocalizedStringKey)] = [
        ("location.fill",        "Laufspur und Schlagweiten"),
        ("map.fill",             "Abschlag, Grün und Fairway"),
        ("chart.line.uptrend.xyaxis", "Statistik über alle Runden"),
        ("applewatch",           "Zählen an der Uhr"),
        ("person.2.fill",        "Mehrere Spieler und Spielformen")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Mit der ganzen App", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(AppTheme.gold)

            Text("Diese Zählkarte ist die Kurzfassung. Die App kann deutlich mehr:")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.0) { icon, text in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.gold)
                            .frame(width: 20)
                        Text(text)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                        Spacer(minLength: 0)
                    }
                }
            }

            Text("Deine Runde von hier findest du nach dem Installieren wieder.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}
