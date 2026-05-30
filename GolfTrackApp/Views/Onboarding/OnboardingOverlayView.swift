import SwiftUI

// MARK: - Step Model

private struct OnboardingStep {
    enum MockupKind { case pinSetter, clubRecommendation, shotTracker }
    enum CardPosition { case top, bottom, center }

    let icon: String
    let iconColor: Color
    let title: String
    let body: String
    let tab: Int
    let anchor: TutorialAnchor?   // nil → kein Spotlight, zentrierte Karte
    let cardPosition: CardPosition
    var mockup: MockupKind? = nil  // wenn gesetzt → PhoneFrame statt Icon

    init(icon: String, iconColor: Color, title: String, body: String,
         tab: Int, anchor: TutorialAnchor?, cardPosition: CardPosition,
         mockup: MockupKind? = nil) {
        self.icon = icon; self.iconColor = iconColor
        self.title = title; self.body = body
        self.tab = tab; self.anchor = anchor
        self.cardPosition = cardPosition; self.mockup = mockup
    }
}

private let steps: [OnboardingStep] = [
    OnboardingStep(
        icon: "figure.golf", iconColor: AppTheme.gold,
        title: "Willkommen bei GolfTrack",
        body: "In wenigen Schritten zeigen wir dir alles Wichtige. Tippe auf Weiter, um zu starten.",
        tab: 0, anchor: nil, cardPosition: .center
    ),
    OnboardingStep(
        icon: "house.fill", iconColor: AppTheme.gold,
        title: "Dein Dashboard",
        body: "Hier siehst du dein Handicap, das aktuelle Wetter und deine letzte Runde auf einen Blick.",
        tab: 0, anchor: .dashboardCards, cardPosition: .bottom
    ),
    OnboardingStep(
        icon: "plus.circle.fill", iconColor: Color(red: 0.3, green: 0.85, blue: 0.5),
        title: "Neue Runde starten",
        body: "Tippe auf diesen Button, um eine Runde zu beginnen. Du wählst Platz, Modus und Löcherzahl.",
        tab: 0, anchor: .newRoundButton, cardPosition: .top
    ),
    OnboardingStep(
        icon: "mappin.circle.fill", iconColor: .red,
        title: "Lochposition setzen",
        body: "Tippe beim Scoring auf \"Lochposition festlegen\" und markiere den Pin auf der Karte. Die App zeigt dir danach die genaue Distanz zum Loch.",
        tab: 0, anchor: nil, cardPosition: .center, mockup: .pinSetter
    ),
    OnboardingStep(
        icon: "figure.golf", iconColor: AppTheme.gold,
        title: "Schlägerverwaltung",
        body: "Basierend auf deinen gespeicherten Schlägerdistanzen empfiehlt die App automatisch den besten Schläger. Deine Messungen werden mit jeder Runde genauer.",
        tab: 0, anchor: nil, cardPosition: .center, mockup: .clubRecommendation
    ),
    OnboardingStep(
        icon: "map.fill", iconColor: Color(red: 0.4, green: 0.7, blue: 1.0),
        title: "Schläge tracken",
        body: "Tippe auf \"Schläge aufzeichnen\", setze Abschlag und Landepunkt auf der Karte. Distanz wird berechnet und dem Schläger gutgeschrieben.",
        tab: 0, anchor: nil, cardPosition: .center, mockup: .shotTracker
    ),
    OnboardingStep(
        icon: "person.crop.circle.fill", iconColor: AppTheme.gold,
        title: "Dein Profil",
        body: "Ändere hier deinen Namen und dein Foto. Deine Statistiken findest du direkt darunter.",
        tab: 4, anchor: .profileHeader, cardPosition: .bottom
    ),
    OnboardingStep(
        icon: "trophy.fill", iconColor: AppTheme.gold,
        title: "Handicap & Errungenschaften",
        body: "Dein WHS-Handicap wird nach jeder Runde automatisch berechnet. Scrolle für Golfplatz-Einstellungen.",
        tab: 4, anchor: .handicapCard, cardPosition: .bottom
    ),
    OnboardingStep(
        icon: "book.fill", iconColor: Color(red: 0.55, green: 0.70, blue: 1.0),
        title: "Spielregeln & Tipps",
        body: "Alle offiziellen Golf-Regeln und Profi-Tipps sind immer griffbereit — egal ob auf dem Platz oder zuhause.",
        tab: 2, anchor: nil, cardPosition: .center
    ),
    OnboardingStep(
        icon: "checkmark.circle.fill", iconColor: Color(red: 0.3, green: 0.85, blue: 0.5),
        title: "Du bist startklar!",
        body: "Das war der Schnelleinstieg. Viel Spaß auf dem Platz!",
        tab: 0, anchor: nil, cardPosition: .center
    ),
]

// MARK: - Cutout Mask Shape (Even-Odd Rule → transparentes Loch)

private struct DimMask: Shape {
    var rect: CGRect
    var cornerRadius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>,
                                       AnimatablePair<CGFloat, CGFloat>> {
        get { .init(.init(rect.minX, rect.minY), .init(rect.width, rect.height)) }
        set { rect = CGRect(x: newValue.first.first, y: newValue.first.second,
                            width: newValue.second.first, height: newValue.second.second) }
    }

    func path(in bounds: CGRect) -> Path {
        var p = Path(bounds)
        p.addRoundedRect(in: rect.insetBy(dx: -4, dy: -4),
                         cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        return p
    }
}

// MARK: - Pulsing Spotlight Ring

private struct SpotlightRing: View {
    let rect: CGRect
    let cornerRadius: CGFloat
    @State private var glow = false

    var body: some View {
        let expanded = rect.insetBy(dx: -4, dy: -4)
        ZStack {
            // Äußerer Glow
            RoundedRectangle(cornerRadius: cornerRadius + 2)
                .strokeBorder(AppTheme.gold.opacity(glow ? 0.4 : 0.0), lineWidth: 12)
                .frame(width: expanded.width, height: expanded.height)
                .position(x: expanded.midX, y: expanded.midY)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: glow)

            // Scharfer Ring
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(AppTheme.gold, lineWidth: glow ? 2.5 : 1.8)
                .frame(width: expanded.width, height: expanded.height)
                .position(x: expanded.midX, y: expanded.midY)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: glow)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { glow = true }
        }
    }
}

// MARK: - Main Overlay

struct OnboardingOverlayView: View {
    @Binding var selectedTab: Int
    let frames: [String: CGRect]

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentStep = 0
    @State private var pulse = false

    private let tabBarH: CGFloat = 83
    private let padding: CGFloat = 14

    private var step: OnboardingStep { steps[currentStep] }
    private var isLast: Bool { currentStep == steps.count - 1 }

    // Frame des aktuell hervorgehobenen Elements (nil → zentrierte Karte)
    private func spotlightFrame(geo: GeometryProxy) -> CGRect? {
        guard let anchor = step.anchor else { return nil }
        return frames[anchor.rawValue]
    }

    var body: some View {
        GeometryReader { geo in
            let sf = spotlightFrame(geo: geo)

            ZStack {
                // ── Dim-Layer ─────────────────────────────────────────
                if let rect = sf {
                    DimMask(rect: rect, cornerRadius: cornerRadius(for: step.anchor))
                        .fill(Color.black.opacity(0.82), style: FillStyle(eoFill: true))
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.4), value: currentStep)

                    SpotlightRing(rect: rect, cornerRadius: cornerRadius(for: step.anchor))
                        .id(currentStep)
                        .ignoresSafeArea()
                } else {
                    Color.black.opacity(0.85).ignoresSafeArea()
                }

                // ── Gesten-Blocker ────────────────────────────────────
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0))
                    .ignoresSafeArea()

                // ── Karte ─────────────────────────────────────────────
                if sf == nil {
                    centeredCard
                        .id(currentStep)
                        .transition(.scale(scale: 0.93).combined(with: .opacity))
                } else {
                    positionedCard(geo: geo, spotlightRect: sf)
                        .id(currentStep)
                        .transition(.asymmetric(
                            insertion: step.cardPosition == .top
                                ? .move(edge: .top).combined(with: .opacity)
                                : .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .onAppear { startPulse() }
        .onChange(of: currentStep) { _, new in
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = steps[new].tab
            }
            pulse = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { startPulse() }
        }
    }

    // MARK: - Card positioning

    private func positionedCard(geo: GeometryProxy, spotlightRect sf: CGRect?) -> some View {
        VStack(spacing: 0) {
            if step.cardPosition == .top {
                infoCard
                    .padding(.horizontal, padding)
                    .padding(.top, geo.safeAreaInsets.top + 6)
                Spacer()
                navBar
                    .padding(.horizontal, padding)
                    .padding(.bottom, tabBarH + 6)
            } else {
                Spacer()
                VStack(spacing: 0) {
                    navBar
                        .padding(.horizontal, padding)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    infoCard
                        .padding(.horizontal, padding)
                        .padding(.bottom, tabBarH + 10)
                }
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24, bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0, topTrailingRadius: 24
                    )
                    .fill(AppTheme.card)
                    .shadow(color: .black.opacity(0.45), radius: 20, y: -4)
                )
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(step.iconColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: step.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(step.iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Text(step.body)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSec)
                    .lineSpacing(2.5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Button { dismissTutorial() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.textSec)
                    .frame(width: 26, height: 26)
                    .background(AppTheme.cardAlt, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.45), radius: 18, y: 4)
        )
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentStep ? AppTheme.gold : Color.white.opacity(0.2))
                        .frame(width: i == currentStep ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.28), value: currentStep)
                }
            }

            Spacer()

            if currentStep > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { currentStep -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.textSec)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.cardAlt, in: Circle())
                }
                .buttonStyle(.plain)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.3)) { advance() }
            } label: {
                HStack(spacing: 5) {
                    Text(isLast ? "Fertig" : "Weiter")
                        .font(.system(size: 14, weight: .bold))
                    Image(systemName: isLast ? "checkmark" : "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                .padding(.horizontal, 20)
                .padding(.vertical, 11)
                .background(AppTheme.gold, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Centered Card

    private var centeredCard: some View {
        VStack(spacing: 20) {
            // Phone mockup or icon
            if let mockupKind = step.mockup {
                PhoneFrame { mockupContent(for: mockupKind) }
                    .frame(width: 170, height: 340)
            } else {
                ZStack {
                    Circle()
                        .fill(step.iconColor.opacity(0.14))
                        .frame(width: 90, height: 90)
                    Image(systemName: step.icon)
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(step.iconColor)
                }
                .padding(.top, 8)
            }

            VStack(spacing: 8) {
                Text(step.title)
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.center)
                Text(step.body)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSec)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 5) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i == currentStep ? AppTheme.gold : Color.white.opacity(0.2))
                        .frame(width: i == currentStep ? 18 : 6, height: 6)
                        .animation(.spring(response: 0.28), value: currentStep)
                }
            }

            VStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { advance() }
                } label: {
                    Text(isLast ? "Tutorial beenden" : "Weiter")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                }
                .buttonStyle(.plain)

                if !isLast {
                    Button { dismissTutorial() } label: {
                        Text("Überspringen")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.55), radius: 32, y: 10)
        )
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Mockup dispatcher

    @ViewBuilder
    private func mockupContent(for kind: OnboardingStep.MockupKind) -> some View {
        switch kind {
        case .pinSetter:          PinSetterMockup(pulse: pulse)
        case .clubRecommendation: ClubRecommendationMockup(pulse: pulse)
        case .shotTracker:        ShotTrackerMockup(pulse: pulse)
        }
    }

    // MARK: - Helpers

    private func startPulse() {
        withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }

    private func cornerRadius(for anchor: TutorialAnchor?) -> CGFloat {
        switch anchor {
        case .newRoundButton: return 14
        default:              return 18
        }
    }

    private func advance() {
        if isLast { dismissTutorial() }
        else { currentStep += 1 }
    }

    private func dismissTutorial() {
        withAnimation(.easeOut(duration: 0.3)) { hasSeenOnboarding = true }
    }
}
