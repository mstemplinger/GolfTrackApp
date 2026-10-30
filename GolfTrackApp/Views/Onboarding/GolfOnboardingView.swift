import SwiftUI

/// Einführung für Golfer – läuft direkt nach der Schwerpunkt-Auswahl „Golf“
/// und lässt sich im Profil neu starten.
///
/// Jede Seite hat denselben Aufbau: oben die Bühne mit einer nachgebauten
/// App-Ansicht, darunter Kategorie, Titel und Text in fester Höhe. Dadurch
/// bleibt das Gerät auf allen Seiten gleich groß und nichts springt beim
/// Wischen.
struct GolfOnboardingView: View {

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var current: GolfOnboardingPage.ID = GolfOnboardingPage.all[0].id
    @State private var appear = false

    private let pages = GolfOnboardingPage.all

    private var index: Int { pages.firstIndex { $0.id == current } ?? 0 }
    private var isLast: Bool { index == pages.count - 1 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.035, green: 0.100, blue: 0.062), AppTheme.bg],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 22)
                    .padding(.top, 8)

                TabView(selection: $current) {
                    ForEach(pages) { page in
                        pageView(page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomBar
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)
            }
            .readableContentWidth()
        }
        .opacity(appear ? 1 : 0)
        .onAppear {
            #if DEBUG
            // Zum Prüfen einzelner Seiten im Simulator ohne Tippen.
            if let raw = ProcessInfo.processInfo.environment["GOLFTRACK_ONBOARDING_PAGE"],
               let i = Int(raw), pages.indices.contains(i) {
                current = pages[i].id
            }
            #endif
            withAnimation(.easeOut(duration: 0.35)) { appear = true }
        }
        .onChange(of: current) { _, _ in Haptics.selection() }
    }

    // MARK: - Kopfzeile

    private var topBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 4) {
                ForEach(pages.indices, id: \.self) { i in
                    Capsule()
                        .fill(i <= index ? AppTheme.gold : Color.white.opacity(0.14))
                        .frame(height: 4)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: index)
            .accessibilityElement()
            .accessibilityLabel(Text("Seite \(index + 1) von \(pages.count)"))

            Button {
                Haptics.tap()
                finish()
            } label: {
                Text("Überspringen")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textSec)
            }
            .buttonStyle(.plain)
            .opacity(isLast ? 0 : 1)
            .disabled(isLast)
        }
        .frame(height: 32)
    }

    // MARK: - Seite

    private func pageView(_ page: GolfOnboardingPage) -> some View {
        VStack(spacing: 0) {
            OnbStage(active: current == page.id, canvas: OnbCanvas.size(for: page.id)) { visual(for: page.id) }
                .padding(.top, 10)

            textBlock(page)
                .padding(.horizontal, 26)
                .padding(.top, 18)
        }
    }

    private func textBlock(_ page: GolfOnboardingPage) -> some View {
        VStack(spacing: 10) {
            Text(page.title)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(page.text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ForEach(page.chips.indices, id: \.self) { i in
                    Label(page.chips[i].text, systemImage: page.chips[i].icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.gold.opacity(0.13), in: Capsule())
                }
            }
            .padding(.top, 4)
        }
        // Feste Höhe: das Gerät darüber bleibt auf jeder Seite gleich groß.
        .frame(maxWidth: .infinity, minHeight: 186, alignment: .top)
    }

    @ViewBuilder
    private func visual(for id: GolfOnboardingPage.ID) -> some View {
        switch id {
        case .welcome:  OnbWelcomeVisual()
        case .home:     OnbHomeMock()
        case .newRound: OnbNewRoundMock()
        case .scoring:  OnbScoringMock()
        case .map:      OnbShotMapMock()
        case .tracking: OnbTrackingMock()
        case .finish:   OnbRoundCompleteMock()
        case .learn:    OnbTrainingMock()
        case .caddy:    OnbCaddyMock()
        case .profile:  OnbProfileMock()
        case .done:     OnbTabGuideVisual()
        }
    }

    // MARK: - Fußzeile

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if index > 0 {
                Button {
                    Haptics.tap()
                    go(to: index - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 54, height: 54)
                        .background(AppTheme.card, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Zurück"))
                .transition(.scale.combined(with: .opacity))
            }

            Button {
                if isLast {
                    Haptics.success()
                    finish()
                } else {
                    go(to: index + 1)
                }
            } label: {
                HStack(spacing: 8) {
                    Text(isLast ? "Los geht's" : (index == 0 ? "Tour starten" : "Weiter"))
                    Image(systemName: isLast ? "checkmark" : "arrow.right")
                        .font(.subheadline.weight(.bold))
                }
                .goldButton()
            }
            .buttonStyle(.plain)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: index > 0)
    }

    // MARK: - Aktionen

    private func go(to i: Int) {
        guard pages.indices.contains(i) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            current = pages[i].id
        }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.3)) { hasSeenOnboarding = true }
    }
}

// MARK: - Seiten

struct GolfOnboardingPage: Identifiable {
    enum ID: Hashable {
        case welcome, home, newRound, scoring, map, tracking, finish, learn, caddy, profile, done
    }

    let id: ID
    let chips: [(icon: String, text: LocalizedStringKey)]
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    static let all: [GolfOnboardingPage] = [
        .init(id: .welcome,
              chips: [("clock.fill", "Rund 2 Minuten"), ("forward.fill", "Jederzeit überspringbar")],
              title: "Dein Golf. Alles in einer App.",
              text: "Zählen, messen, besser werden: In zwei Minuten zeigen wir dir, was GolfTrack auf und neben dem Platz für dich erledigt."),
        .init(id: .home,
              chips: [("location.fill", "Platz in der Nähe erkannt"), ("cloud.sun.fill", "Golf-Wetter stündlich")],
              title: "Alles Wichtige auf einen Blick",
              text: "Stehst du am Platz, schlägt GolfTrack ihn dir direkt vor. Dazu dein Handicap, die letzte Runde und das Golf-Wetter mit den besten Stunden zum Spielen."),
        .init(id: .newRound,
              chips: [("qrcode", "QR-Code am Platz"), ("person.3.fill", "18 Spielformen")],
              title: "In Sekunden auf der Runde",
              text: "Platz wählen oder den QR-Code am Platz scannen, eine von 18 Spielformen aussuchen, Bag und Mitspieler dazu – fertig."),
        .init(id: .scoring,
              chips: [("scope", "Entfernung zur Fahne"), ("applewatch", "Auch auf der Watch")],
              title: "Zählen mit einem Tipp",
              text: "Schläge, Putts, Fairway und Grün in Regulation pro Loch. Die Entfernung zur Fahne und der passende Schläger stehen direkt darüber."),
        .init(id: .map,
              chips: [("flag.fill", "Fahne per Tipp"), ("bag.fill", "Weiten pro Schläger")],
              title: "Jeder Schlag auf der Karte",
              text: "Fahne setzen, Schläge aufzeichnen: Jede Weite landet bei deinem Schläger. So werden die Empfehlungen mit jeder Runde genauer."),
        .init(id: .tracking,
              chips: [("mappin.and.ellipse", "Abschlag & Grün erkannt"), ("lock.fill", "Nur mit Erlaubnis")],
              title: "Die App lernt deinen Platz",
              text: "Mit deiner Erlaubnis merkt sich GolfTrack deinen Weg über den Platz und erkennt daraus Abschlag, Grün und Fairway-Verlauf jedes Lochs."),
        .init(id: .finish,
              chips: [("chart.bar.fill", "Putts, Fairway, GIR"), ("square.and.arrow.up", "Scorekarte teilen")],
              title: "Handicap sofort aktuell",
              text: "Nach der Runde steht dein WHS-Handicap fest. Dazu Statistiken, eine Scorekarte zum Teilen und Audio-Lektionen passend zu dieser Runde."),
        .init(id: .learn,
              chips: [("headphones", "Hören statt lesen"), ("checkmark.seal.fill", "Fit für die Platzreife")],
              title: "Besser werden – auch zuhause",
              text: "Audio-Trainings für Schwung, kurzes Spiel und Kopf, alle Golfregeln mit Skizzen und ein Quiz, mit dem du dich auf die Platzreife vorbereitest."),
        .init(id: .caddy,
              chips: [("mic.fill", "Einfach fragen"), ("book.fill", "Mit Regelbezug")],
              title: "Frag einfach deinen Caddy",
              text: "Regelfrage am Wasserhindernis? Taktik für ein schwieriges Loch? Der Caddy antwortet per Sprache – mitten auf der Runde."),
        .init(id: .profile,
              chips: [("chart.xyaxis.line", "Handicap-Verlauf"), ("creditcard.fill", "Mitgliedskarte dabei")],
              title: "Dein Golf-Zuhause",
              text: "Handicap-Verlauf, Bestleistungen und dein Bag mit den echten Weiten jedes Schlägers. Die Mitgliedskarte hast du ebenfalls immer dabei."),
        .init(id: .done,
              chips: [("arrow.counterclockwise", "Im Profil neu starten"), ("gearshape.fill", "Einstellungen im Profil")],
              title: "Bereit für die erste Runde",
              text: "Unten in der Leiste erreichst du alle Bereiche. Das Tutorial findest du jederzeit wieder unter Profil → Tutorial neu starten."),
    ]
}

// MARK: - Bühne

/// Gleich große Fläche für jede Visualisierung, mit leichtem Lichtkegel
/// dahinter. Die Inhalte werden für eine feste Zeichenfläche gebaut und auf
/// den verfügbaren Platz skaliert – so sehen sie auf jedem Gerät gleich aus.
private struct OnbStage<Content: View>: View {
    let active: Bool
    let canvas: CGSize
    @ViewBuilder let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / canvas.width, geo.size.height / canvas.height)

            ZStack {
                RadialGradient(
                    colors: [AppTheme.gold.opacity(0.20), AppTheme.green.opacity(0.10), .clear],
                    center: .center, startRadius: 10,
                    endRadius: max(geo.size.width, geo.size.height) * 0.55
                )

                content
                    .environment(\.onbActive, active)
                    .frame(width: canvas.width, height: canvas.height)
                    .scaleEffect(scale)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(active || reduceMotion ? 1 : 0.94)
                    .opacity(active || reduceMotion ? 1 : 0.6)
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: active)
            }
        }
    }
}

enum OnbCanvas {
    /// Zeichenfläche mit etwas Luft um das Gerät für dessen Schatten.
    static let size = CGSize(width: 310, height: 640)
    static let phone = CGSize(width: 296, height: 628)
    /// Willkommen und Abschluss zeigen kein Gerät und nutzen die Breite.
    static let wide = CGSize(width: 380, height: 600)

    static func size(for page: GolfOnboardingPage.ID) -> CGSize {
        page == .welcome || page == .done ? wide : size
    }
}

private struct OnbActiveKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Ob die Seite gerade sichtbar ist – Hinweise und Hervorhebungen
    /// erscheinen erst dann.
    var onbActive: Bool {
        get { self[OnbActiveKey.self] }
        set { self[OnbActiveKey.self] = newValue }
    }
}

#Preview {
    GolfOnboardingView()
        .preferredColorScheme(.dark)
}
