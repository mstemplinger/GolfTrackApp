import SwiftUI
import WatchKit
import WatchConnectivity

// MARK: - Farbkonstanten

private let gold   = Color(red: 0.79, green: 0.66, blue: 0.30)
private let darkBg = Color(red: 0.06, green: 0.14, blue: 0.08)
private let rowBg  = Color(red: 0.10, green: 0.20, blue: 0.12)

// MARK: - Setup View

struct SetupView: View {

    @State private var model: WatchRoundModel?

    // Platz-Auswahl
    @State private var availableCourses: [WatchCourse] = []
    @State private var selectedCourse: WatchCourse?    // nil = "Ohne Platz"
    @State private var selectedHoles: Int = 18

    // Wartemodus: iPhone erstellt gerade die Runde
    @State private var isWaitingForPhone = false
    @State private var waitingTimeoutTask: Task<Void, Never>?

    private let wc = WatchConnectivityManager.shared

    // MARK: - Body

    var body: some View {
        if let model {
            StrokeTrackerView(model: model) {
                self.model = nil
                self.selectedCourse = nil
            }
        } else if isWaitingForPhone {
            waitingView
        } else {
            setupBody
        }
    }

    // MARK: - Warte-Screen

    private var waitingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(gold)
                .scaleEffect(1.2)
            Text("iPhone startet\ndie Runde…")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(darkBg)
    }

    // MARK: - Setup-Screen

    private var setupBody: some View {
        ScrollView {
            VStack(spacing: 6) {

                // Header
                VStack(spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "figure.golf")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(gold)
                        Text("GOLFTRACK")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .kerning(0.5)
                    }
                    Text("Neue Runde")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)
                .padding(.bottom, 2)

                // ── Platz-Sektion ──────────────────────────────────
                if !availableCourses.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PLATZ")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        // Ohne Platz (Fallback)
                        courseRow(nil)

                        ForEach(availableCourses) { course in
                            courseRow(course)
                        }
                    }
                }

                // ── Löcher-Sektion (nur wenn kein Platz gewählt) ──
                if selectedCourse == nil {
                    VStack(alignment: .leading, spacing: 4) {
                        if !availableCourses.isEmpty {
                            Text("LÖCHER")
                                .font(.system(size: 9, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.top, 4)
                        }
                        holeRow(9,  label: "9 Löcher")
                        holeRow(18, label: "18 Löcher")
                    }
                }

                // ── Starten ────────────────────────────────────────
                Button { handleStart() } label: {
                    Text("Starten")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(gold)
                        .foregroundStyle(darkBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 6)
        }
        .background(darkBg)
        .onAppear {
            setupConnectivity()
            wc.loadPendingContext()
            wc.requestCourseList()
        }
    }

    // MARK: - Platz-Reihe

    @ViewBuilder
    private func courseRow(_ course: WatchCourse?) -> some View {
        let isSelected: Bool = {
            if let course { return selectedCourse?.name == course.name }
            return selectedCourse == nil
        }()

        Button {
            selectedCourse = course
            WKInterfaceDevice.current().play(.click)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(course?.name ?? "Ohne Platz")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isSelected ? gold : .white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let course {
                        Text("\(course.holes) Loch · Par \(course.totalPar)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("9 oder 18 Löcher wählen")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 4)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(gold)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? rowBg : rowBg.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? gold : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Löcher-Reihe

    private func holeRow(_ count: Int, label: String) -> some View {
        let isSelected = selectedHoles == count
        return Button {
            selectedHoles = count
            WKInterfaceDevice.current().play(.click)
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? gold : .white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(gold)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? rowBg : rowBg.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? gold : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Start-Logik

    private func handleStart() {
        WKInterfaceDevice.current().play(.click)

        if let course = selectedCourse, WCSession.default.isReachable {
            // ── Mit iPhone synchronisieren ─────────────────────────
            isWaitingForPhone = true
            wc.sendStartRoundRequest(courseName: course.name, holes: course.holes)

            // Timeout: 5 Sekunden → dann lokal starten
            waitingTimeoutTask = Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if isWaitingForPhone {
                        isWaitingForPhone = false
                        model = WatchRoundModel(holes: course.holes, courseName: course.name)
                        WKInterfaceDevice.current().play(.failure)
                    }
                }
            }
        } else {
            // ── Lokal starten (kein Platz oder iPhone nicht erreichbar) ──
            let holes = selectedCourse?.holes ?? selectedHoles
            let name  = selectedCourse?.name  ?? ""
            model = WatchRoundModel(holes: holes, courseName: name)
        }
    }

    // MARK: - WatchConnectivity-Callbacks

    private func setupConnectivity() {
        wc.onStartRound = { holes, strokes, currentHole in
            // Timeout abbrechen – iPhone hat geantwortet
            waitingTimeoutTask?.cancel()
            waitingTimeoutTask = nil
            isWaitingForPhone = false

            let newModel = WatchRoundModel(
                holes: holes,
                courseName: self.selectedCourse?.name ?? ""
            )
            newModel.applyFromPhone(holes: holes, strokes: strokes, currentHoleIndex: currentHole)
            WKInterfaceDevice.current().play(.notification)
            self.model = newModel
        }

        wc.onUpdateStrokes = { strokes, currentHole in
            model?.applyStrokesUpdate(strokes: strokes, currentHoleIndex: currentHole)
        }

        wc.onFinishRound = {
            model?.isFinished = true
        }

        wc.onCoursesReceived = { courses in
            availableCourses = courses
        }
    }
}
