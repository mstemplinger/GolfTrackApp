import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Round.date, order: .reverse) private var allRounds: [Round]
    @Query(sort: \Course.name) private var allCourses: [Course]
    @Environment(\.modelContext) private var context
    @AppStorage("playerName") private var playerName = "Golfer"

    @State private var showNewRound      = false
    @State private var showTutorial      = false
    @State private var showAssistant     = false
    @State private var showCaddyPaywall  = false
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var weather = GolfWeatherService()
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// nil = Mein Standort, non-nil = Platz-Wetter
    @State private var selectedWeatherCourse: Course?

    /// Runde die per Bestätigungs-Alert gelöscht werden soll
    @State private var roundToDelete: Round?
    @State private var showWeatherForecast = false

    private var coursesWithGPS: [Course] {
        allCourses.filter { $0.latitude != nil && $0.longitude != nil }
    }

    /// Vom Apple Watch gestartete Runde (zeigt Banner + ermöglicht iPhone-Spiegel)
    @State private var watchRound: Round?
    /// Steuert Navigation zur gespiegelten Runde
    @State private var mirrorRound: Round?
    /// Steuert Navigation zu einer aktiven (unvollständigen) Runde
    @State private var selectedIncompleteRound: Round?

    private let wc = WatchConnectivityManager.shared

    private var completedRounds: [Round] { allRounds.filter(\.isComplete) }
    private var incompleteRounds: [Round] { allRounds.filter { !$0.isComplete } }
    private var lastRound: Round? { completedRounds.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        topBar
                        greetingCard
                            .tutorialAnchor(.dashboardCards)
                        statsRow
                        weatherCard
                            .onTapGesture {
                                if weather.hasData { showWeatherForecast = true }
                            }
                        if let wr = watchRound, !wr.isComplete { watchRoundBanner(wr) }
                        if !completedRounds.isEmpty { trainingProgressCard }
                        if !incompleteRounds.isEmpty { activeRoundsCard }

                        Button { showNewRound = true } label: {
                            Label("Neue Runde spielen", systemImage: "plus.circle.fill")
                                .goldButton()
                        }
                        .padding(.horizontal)
                        .tutorialAnchor(.newRoundButton)

                        HStack(spacing: 12) {
                            NavigationLink {
                                PlatzreifeQuizView()
                            } label: {
                                Label("Platzreife lernen", systemImage: "graduationcap.fill")
                                    .greenButton()
                            }
                            NavigationLink {
                                HistoryView()
                            } label: {
                                Label("Verlauf", systemImage: "clock.fill")
                                    .greenButton()
                            }
                        }
                        .padding(.horizontal)

                        Button {
                            if subscriptionManager.isCaddySubscribed {
                                showAssistant = true
                            } else {
                                showCaddyPaywall = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "waveform.circle.fill")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Caddy – Golf-Assistent")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Regeln, Tipps & Strategien")
                                        .font(.caption)
                                        .opacity(0.7)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .opacity(0.5)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.12, green: 0.30, blue: 0.12),
                                                Color(red: 0.08, green: 0.20, blue: 0.08)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppTheme.gold.opacity(0.35), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showAssistant) {
                            GolfAssistantView()
                                .presentationDetents([.large])
                                .presentationDragIndicator(.visible)
                        }
                        .sheet(isPresented: $showCaddyPaywall) {
                            CaddyPaywallView()
                                .environmentObject(subscriptionManager)
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            // Navigation zur gespiegelten Watch-Runde (manuell via Banner-Button)
            .navigationDestination(item: $mirrorRound) { round in
                ScorecardView(round: round)
            }
            // Navigation zu aktiven Runden (activeRoundsCard)
            .navigationDestination(item: $selectedIncompleteRound) { round in
                ScorecardView(round: round, onRoundFinished: {
                    selectedIncompleteRound = nil
                })
            }
            // iPad: vollständige Seite; iPhone: Sheet
            .fullScreenCover(isPresented: $showNewRound) { NewRoundView().preferredColorScheme(.dark) }
            .sheet(isPresented: $showTutorial) { TutorialView().preferredColorScheme(.dark) }
            .sheet(isPresented: $showWeatherForecast) {
                WeatherForecastView(weather: weather).preferredColorScheme(.dark)
            }
            .onAppear {
                weather.fetch()
                setupWatchSync()
            }
            .onChange(of: allCourses) { _, courses in
                // Wenn Plätze sich ändern, Watch sofort aktualisieren
                wc.sendCoursesToWatch(courses)
            }
        }
    }

    // MARK: - Watch-Synchronisation

    private func setupWatchSync() {
        // Plätze sofort senden
        wc.sendCoursesToWatch(allCourses)

        // Watch fordert Plätze an (z.B. nach App-Neustart)
        wc.onRequestCourseList = { [weak wc] in
            wc?.sendCoursesToWatch(allCourses)
        }

        // Watch möchte eine Runde starten
        wc.onWatchStartRoundRequest = { [weak wc] courseName, holes in
            guard watchRound == nil else { return }  // Duplikat verhindern

            // Platz suchen
            let course = allCourses.first(where: { $0.name == courseName })

            // Runde anlegen
            let round = Round(date: .now, course: course)
            round.isWatchInitiated = true
            context.insert(round)

            let holeCount = course?.numberOfHoles ?? holes
            for i in 1...holeCount {
                let par = course?.parValues[safe: i - 1] ?? 4
                let hole = HoleScore(holeNumber: i, strokes: 0, putts: 0)
                context.insert(hole)
                round.holeScores.append(hole)
            }

            // Zur Watch zurücksenden
            let strokes = (1...holeCount).map { course?.parValues[safe: $0 - 1] ?? 4 }
            wc?.startRound(holes: holeCount, strokes: strokes, currentHoleIndex: 0)

            // watchRound setzen → Banner erscheint (keine automatische Navigation)
            watchRound = round
        }
    }

    // MARK: Top Bar
    private var topBar: some View {
        HStack {
            HStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("GolfTrack")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.text)
            }
            Spacer()
            Button { showTutorial = true } label: {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.gold)
                    .padding(10)
                    .background(AppTheme.card, in: Circle())
            }
        }
        .padding(.horizontal)
    }

    // MARK: Greeting
    private var greetingCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Willkommen zurück,")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                    Text(playerName + "!")
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.text)
                }
                Spacer()
                // Wetter-Pill
                weatherPill
            }
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: Wetter-Pill (kompakt, im Greeting)
    @ViewBuilder
    private var weatherPill: some View {
        if weather.isLoading {
            ProgressView()
                .scaleEffect(0.7)
                .tint(AppTheme.gold)
                .frame(width: 44, height: 44)
        } else if weather.hasData {
            HStack(spacing: 6) {
                Image(systemName: weather.symbolName)
                    .font(.title3)
                    .foregroundStyle(AppTheme.gold)
                    .symbolRenderingMode(.multicolor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(weather.temperature)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Text(weather.conditionText)
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textSec)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.cardAlt, in: Capsule())
        } else if weather.authDenied {
            Label("Standort gesperrt", systemImage: "location.slash")
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.orange.opacity(0.12), in: Capsule())
        } else {
            Menu {
                Button {
                    selectedWeatherCourse = nil
                    weather.fetch()
                } label: {
                    Label("Mein Standort", systemImage: "location.fill")
                }
                if !coursesWithGPS.isEmpty {
                    Divider()
                    ForEach(coursesWithGPS) { course in
                        Button {
                            selectedWeatherCourse = course
                            weather.fetchForCoordinate(
                                lat: course.latitude!,
                                lon: course.longitude!,
                                name: course.name
                            )
                        } label: {
                            Label(course.name, systemImage: "flag.fill")
                        }
                    }
                }
            } label: {
                Label(weather.errorMessage != nil ? "Erneut versuchen" : "Wetter",
                      systemImage: "location.fill")
                    .font(.caption.bold())
                    .foregroundStyle(weather.errorMessage != nil ? .orange : AppTheme.gold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(AppTheme.cardAlt, in: Capsule())
            }
        }
    }

    // MARK: Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            // Handicap
            VStack(alignment: .leading, spacing: 6) {
                Text("Handicap")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                Text(handicapDisplay)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                Text("WHS")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.gold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .cardStyle()

            // Letzte Runde
            VStack(alignment: .leading, spacing: 6) {
                Text("Letzte Runde")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                if let r = lastRound {
                    Text("\(r.totalStrokes)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.text)
                    Text(r.scoreLabel)
                        .font(.caption2.bold())
                        .foregroundStyle(r.scoreToPar.map { $0 <= 0 ? AppTheme.gold : Color.white.opacity(0.6) } ?? AppTheme.textSec)
                } else {
                    Text("–")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSec)
                    Text("Noch keine Runde")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTer)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .cardStyle()
        }
        .padding(.horizontal)
    }

    // MARK: Wetter-Detailkarte
    @ViewBuilder
    private var weatherCard: some View {
        if weather.hasData {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Standort-/Platz-Picker
                    Menu {
                        Button {
                            selectedWeatherCourse = nil
                            weather.fetch()
                        } label: {
                            Label("Mein Standort", systemImage: "location.fill")
                        }
                        if !coursesWithGPS.isEmpty {
                            Divider()
                            ForEach(coursesWithGPS) { course in
                                Button {
                                    selectedWeatherCourse = course
                                    weather.fetchForCoordinate(
                                        lat: course.latitude!,
                                        lon: course.longitude!,
                                        name: course.name
                                    )
                                } label: {
                                    Label(course.name, systemImage: "flag.fill")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: selectedWeatherCourse == nil ? "location.fill" : "flag.fill")
                                .font(.caption)
                            Text(weather.locationName.isEmpty ? "Aktuelles Wetter" : weather.locationName)
                                .font(.subheadline.bold())
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(AppTheme.text)
                    }
                    Spacer()
                    // Golf-Wetter / schlechtes Wetter Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(weather.isGoodGolfWeather ? .green : .orange)
                            .frame(width: 6, height: 6)
                        Text(weather.golfWeatherLabel)
                            .font(.caption.bold())
                            .foregroundStyle(weather.isGoodGolfWeather ? .green : .orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (weather.isGoodGolfWeather ? Color.green : Color.orange).opacity(0.12),
                        in: Capsule()
                    )
                }

                HStack(spacing: 0) {
                    // Haupttemperatur
                    VStack(spacing: 4) {
                        Image(systemName: weather.symbolName)
                            .font(.system(size: 36))
                            .symbolRenderingMode(.multicolor)
                            .foregroundStyle(AppTheme.gold)
                        Text(weather.temperature)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.text)
                        Text(weather.conditionText)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 70)
                        .background(AppTheme.cardAlt)

                    // Detail-Grid
                    VStack(spacing: 8) {
                        weatherDetail(icon: "thermometer.medium", label: "Gefühlt", value: weather.feelsLike)
                        weatherDetail(icon: "wind", label: "Wind", value: weather.windSpeed)
                        weatherDetail(icon: "humidity", label: "Feuchte", value: weather.humidity)
                        weatherDetail(icon: "sun.max", label: "UV", value: weather.uvIndex)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
            .cardStyle()
            .padding(.horizontal)
        }
    }

    private func weatherDetail(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.gold)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.text)
        }
    }

    // MARK: Training Progress
    private var trainingProgressCard: some View {
        let pct = min(1.0, Double(completedRounds.count) / 20.0)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trainingsfortschritt")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text("\(Int(pct * 100)) %")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.gold)
            }
            Text("Richtung 20 Runden für vollen WHS-Index")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.cardAlt).frame(height: 8)
                    Capsule().fill(AppTheme.gold).frame(width: geo.size.width * pct, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: Active Rounds Card
    private var activeRoundsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aktive Runden")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textSec)
            ForEach(incompleteRounds) { round in
                HStack(spacing: 10) {
                    Button { selectedIncompleteRound = round } label: {
                        DarkRoundRow(round: round)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    // Runde abbrechen / löschen
                    Button {
                        roundToDelete = round
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.textTer)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal)
        .alert("Runde abbrechen?", isPresented: Binding(
            get: { roundToDelete != nil },
            set: { if !$0 { roundToDelete = nil } }
        )) {
            Button("Runde löschen", role: .destructive) {
                if let r = roundToDelete {
                    GolfLiveActivityManager.endRound()
                    context.delete(r)
                    roundToDelete = nil
                }
            }
            Button("Abbrechen", role: .cancel) { roundToDelete = nil }
        } message: {
            Text("Die Runde wird unwiderruflich gelöscht.")
        }
    }

    // MARK: Watch-Runde Banner

    private func watchRoundBanner(_ round: Round) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                // Apple Watch Puls-Indikator
                HStack(spacing: 5) {
                    Circle()
                        .fill(AppTheme.gold)
                        .frame(width: 7, height: 7)
                    Text("APPLE WATCH")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.gold)
                        .kerning(0.8)
                }
                Spacer()
                // Platz-Name
                Text(round.course?.name ?? "Runde läuft")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(1)
            }

            Text("Runde läuft auf der Watch")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.text)

            Text("Du kannst die Runde auf dem iPhone spiegeln und dort Einträge vornehmen.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                mirrorRound = round
            } label: {
                Label("Auf iPhone spiegeln", systemImage: "applewatch.and.arrow.forward")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.gold)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal)
        .overlay(alignment: .topTrailing) {
            // Schließen-Button
            Button {
                watchRound = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.textSec)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
    }

    // MARK: WHS Handicap
    private var handicapDisplay: String {
        HandicapCalculator.displayString(from: completedRounds)
    }
}

// MARK: - Dark Round Row
struct DarkRoundRow: View {
    let round: Round
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(round.course?.name ?? "Unbekannter Platz")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer()
            if round.isComplete {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(round.scoreLabel)
                        .font(.headline.bold())
                        .foregroundStyle(AppTheme.gold)
                    Text("\(round.totalStrokes)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
            } else {
                Text("Aktiv")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.gold.opacity(0.25), in: Capsule())
                    .foregroundStyle(AppTheme.gold)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(14)
        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 12))
    }
}
