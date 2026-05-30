import SwiftUI

// MARK: - TutorialView

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var pulse = false

    private let totalSteps = 10

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.10).ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Close button ─────────────────────────────────────
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // ── Phone mockup + content ────────────────────────────
                TabView(selection: $currentStep) {
                    ForEach(0..<totalSteps, id: \.self) { i in
                        stepContent(i)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                // ── Navigation bar ───────────────────────────────────
                navBar
                    .padding(.bottom, 28)
            }
        }
        .onAppear { startPulse() }
        .onChange(of: currentStep) { _, _ in
            pulse = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { startPulse() }
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }

    // MARK: - Step dispatcher

    @ViewBuilder
    private func stepContent(_ i: Int) -> some View {
        VStack(spacing: 20) {
            // Phone frame with mockup
            PhoneFrame {
                switch i {
                case 0: HomeScreenMockup(pulse: pulse)
                case 1: CoursePickerMockup(pulse: pulse)
                case 2: ModePickerMockup(pulse: pulse)
                case 3: StrokesCounterMockup(pulse: pulse)
                case 4: DetailsMockup(pulse: pulse)
                case 5: PinSetterMockup(pulse: pulse)
                case 6: ClubRecommendationMockup(pulse: pulse)
                case 7: ShotTrackerMockup(pulse: pulse)
                case 8: FinishButtonMockup(pulse: pulse)
                default: StatsChartMockup(pulse: pulse)
                }
            }
            .frame(width: 210, height: 420)

            // Text block
            VStack(spacing: 8) {
                Text("Schritt \(i + 1) von \(totalSteps)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(AppTheme.gold.opacity(0.12), in: Capsule())

                Text(stepTitle(i))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(stepDescription(i))
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .padding(.top, 12)
    }

    // MARK: - Nav bar

    private var navBar: some View {
        VStack(spacing: 14) {
            // Step dots
            HStack(spacing: 5) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i == currentStep ? AppTheme.gold : Color.white.opacity(0.18))
                        .frame(width: i == currentStep ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.3), value: currentStep)
                }
            }

            HStack {
                // Back
                if currentStep > 0 {
                    Button {
                        currentStep -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.07), in: Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 42, height: 42)
                }

                Spacer()

                // Forward / Finish
                Button {
                    if currentStep < totalSteps - 1 {
                        currentStep += 1
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(currentStep < totalSteps - 1 ? "Weiter" : "Los geht's!")
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: currentStep < totalSteps - 1 ? "arrow.right" : "checkmark")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 22)
                    .frame(height: 42)
                    .background(AppTheme.gold, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
        }
        .padding(.top, 8)
    }

    // MARK: - Step copy

    private func stepTitle(_ i: Int) -> String {
        switch i {
        case 0: return "Neue Runde starten"
        case 1: return "Golfplatz auswählen"
        case 2: return "Spielmodus wählen"
        case 3: return "Schläge eintragen"
        case 4: return "Putts & Details"
        case 5: return "Lochposition setzen"
        case 6: return "Schlägerverwaltung"
        case 7: return "Schläge tracken"
        case 8: return "Runde abschließen"
        default: return "Statistiken auswerten"
        }
    }

    private func stepDescription(_ i: Int) -> String {
        switch i {
        case 0: return "Tippe auf der Startseite auf den goldenen Button, um eine neue Runde zu beginnen."
        case 1: return "Wähle deinen Platz aus. Neue Plätze legst du unter Einstellungen → Golfplätze an."
        case 2: return "Wähle zwischen 14 Modi – vom Zählspiel bis Stableford. Das ⓘ erklärt jeden Modus."
        case 3: return "Tippe + oder − um Schläge pro Loch einzutragen. Die Zahl aktualisiert sich sofort."
        case 4: return "Trage Putts, Fairway-Treffer und GIR ein – die Basis für deine Statistiken."
        case 5: return "Tippe auf \"Lochposition festlegen\" und setze den Pin auf der Satellitenkarte. Die App zeigt dir ab sofort die genaue Distanz zum Loch an."
        case 6: return "Basierend auf deinen gespeicherten Schlägerdistanzen empfiehlt die App automatisch den besten Schläger für die aktuelle Distanz. Unter Profil → Meine Schläger siehst du alle Messungen."
        case 7: return "Tippe auf \"Schläge aufzeichnen\", um jeden Schlag auf der Karte zu markieren. Setze Abschlag und Landepunkt – die Distanz wird automatisch berechnet und dem Schläger gutgeschrieben."
        case 8: return "Nach dem letzten Loch tippe auf \"Runde abschließen\". Dein WHS-Handicap wird berechnet."
        default: return "Im Statistik-Tab siehst du Fairway-Quote, GIR, Putts, Handicap-Verlauf und mehr."
        }
    }
}

// MARK: - Phone Frame

struct PhoneFrame<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            // Outer shell
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.6), radius: 20, y: 10)

            // Screen background
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(red: 0.07, green: 0.07, blue: 0.09))
                .padding(6)

            // Content clipped to screen
            content
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .padding(6)

            // Dynamic island
            Capsule()
                .fill(Color(white: 0.12))
                .frame(width: 62, height: 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 12)
        }
    }
}

// MARK: - Highlight Ring

struct Spotlight: View {
    let pulse: Bool
    var radius: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .strokeBorder(AppTheme.gold, lineWidth: pulse ? 2 : 1.2)
            .shadow(color: AppTheme.gold.opacity(pulse ? 0.85 : 0.3), radius: pulse ? 7 : 3)
    }
}

// MARK: - Shared status bar

struct MockStatusBar: View {
    var body: some View {
        HStack {
            Text("9:41")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "wifi").font(.system(size: 8))
                Image(systemName: "battery.100").font(.system(size: 8))
            }
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

// MARK: - Mockup: Home → "Neue Runde" Button highlighted

private struct HomeScreenMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            // Top bar
            HStack {
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.gold)
                        .frame(width: 18, height: 18)
                    Text("GolfTrack")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // Greeting card
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Willkommen zurück,")
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                    Text("Golfer!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(10)
            .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 10)

            // Stats row
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Handicap").font(.system(size: 6)).foregroundStyle(.secondary)
                    Text("24.0").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Letzte Runde").font(.system(size: 6)).foregroundStyle(.secondary)
                    Text("92").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 9))
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)

            Spacer()

            // ── HIGHLIGHTED: Neue Runde Button ───────────────────────
            ZStack {
                HStack(spacing: 5) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Neue Runde spielen")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 11))

                Spotlight(pulse: pulse, radius: 11)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 16)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
}

// MARK: - Mockup: New Round → Course Picker highlighted

private struct CoursePickerMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            // Nav
            HStack {
                Text("Neue Runde")
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                Spacer()
                Image(systemName: "xmark").font(.system(size: 9)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            Divider().background(Color.white.opacity(0.07))

            VStack(spacing: 10) {
                // ── HIGHLIGHTED: Course picker ───────────────────────
                VStack(alignment: .leading, spacing: 5) {
                    Text("GOLFPLATZ")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ZStack {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 10)).foregroundStyle(AppTheme.gold)
                            Text("Platz auswählen…")
                                .font(.system(size: 10)).foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9)).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 9)
                        .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 10))

                        Spotlight(pulse: pulse, radius: 10)
                    }
                }
                .padding(.horizontal, 12)

                // Date row (dimmed, not highlighted)
                VStack(alignment: .leading, spacing: 5) {
                    Text("DATUM")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(.secondary)
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                        Text("Heute")
                            .font(.system(size: 10)).foregroundStyle(Color.white.opacity(0.4))
                        Spacer()
                    }
                    .padding(.horizontal, 10).padding(.vertical, 9)
                    .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 12)
                .opacity(0.5)
            }
            .padding(.top, 10)

            Spacer()
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
}

// MARK: - Mockup: New Round → Mode Picker highlighted

private struct ModePickerMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            HStack {
                Text("Neue Runde")
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            Divider().background(Color.white.opacity(0.07))

            VStack(spacing: 10) {
                // Course row (dimmed)
                HStack {
                    Image(systemName: "mappin.circle.fill").font(.system(size: 9)).foregroundStyle(AppTheme.gold)
                    Text("Golfclub Beispiel").font(.system(size: 9)).foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 12)
                .opacity(0.45)

                // ── HIGHLIGHTED: Mode picker ─────────────────────────
                VStack(alignment: .leading, spacing: 5) {
                    Text("SPIELMODUS")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ZStack {
                        VStack(spacing: 3) {
                            modeRow("Zählspiel", selected: true)
                            modeRow("Stableford", selected: false)
                            modeRow("Matchplay", selected: false)
                        }
                        .padding(6)
                        .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 11))

                        Spotlight(pulse: pulse, radius: 11)
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.top, 10)

            Spacer()
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }

    private func modeRow(_ name: String, selected: Bool) -> some View {
        HStack {
            Circle()
                .fill(selected ? AppTheme.gold : Color(white: 0.25))
                .frame(width: 7, height: 7)
            Text(name)
                .font(.system(size: 9, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? AppTheme.gold : .white)
            Spacer()
            Image(systemName: "info.circle")
                .font(.system(size: 8)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(Color(white: selected ? 0.17 : 0.09), in: RoundedRectangle(cornerRadius: 7))
    }
}

// MARK: - Mockup: Scorecard → Stroke counter highlighted

private struct StrokesCounterMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            HStack {
                Image(systemName: "chevron.left").font(.system(size: 9)).foregroundStyle(AppTheme.gold)
                Spacer()
                Text("LOCH 1 · 18").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                Spacer()
                Text("● LIVE").font(.system(size: 7, weight: .bold)).foregroundStyle(.green)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            // Hole header
            VStack(spacing: 2) {
                Text("AKTUELLES LOCH").font(.system(size: 7, weight: .semibold)).foregroundStyle(.secondary)
                Text("01").font(.system(size: 26, weight: .black, design: .rounded).italic()).foregroundStyle(AppTheme.gold)
                Text("PAR 4").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 10)
            .padding(.top, 4)

            Spacer()

            // ── HIGHLIGHTED: Stroke counter ──────────────────────────
            ZStack {
                VStack(spacing: 6) {
                    Text("SCHLÄGE")
                        .font(.system(size: 7, weight: .semibold)).foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        Image(systemName: "minus")
                            .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.18), in: RoundedRectangle(cornerRadius: 9))
                        Text("4")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold)).foregroundStyle(.black)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 9))
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
                .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 10)

                Spotlight(pulse: pulse, radius: 12)
                    .padding(.horizontal, 10)
            }

            Spacer()
            // Dimmed bottom buttons
            HStack(spacing: 6) {
                Text("WEITER →")
                    .font(.system(size: 9, weight: .bold)).foregroundStyle(Color.black.opacity(0.6))
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(AppTheme.gold.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 10).padding(.bottom, 16)
            .opacity(0.5)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
}

// MARK: - Mockup: Scorecard → Putts/Fairway/GIR highlighted

private struct DetailsMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            HStack {
                Image(systemName: "chevron.left").font(.system(size: 9)).foregroundStyle(AppTheme.gold)
                Spacer()
                Text("LOCH 1 · 18").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                Spacer()
                Text("● LIVE").font(.system(size: 7, weight: .bold)).foregroundStyle(.green)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            // Stroke counter (dimmed)
            VStack(spacing: 4) {
                Text("SCHLÄGE").font(.system(size: 7)).foregroundStyle(.secondary)
                Text("4").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(Color.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 10)
            .opacity(0.45)

            Spacer()

            // ── HIGHLIGHTED: Putts / Fairway / GIR ──────────────────
            ZStack {
                HStack(spacing: 6) {
                    detailCell(icon: "arrow.triangle.2.circlepath", label: "Putts", value: "2")
                    detailCell(icon: "arrow.up.right", label: "Fairway", value: "✓", active: true)
                    detailCell(icon: "flag.fill", label: "GIR", value: "✓", active: true)
                }
                .padding(.horizontal, 10)

                Spotlight(pulse: pulse, radius: 10)
                    .padding(.horizontal, 10)
            }

            Spacer()

            // Next button dimmed
            Text("WEITER →")
                .font(.system(size: 9, weight: .bold)).foregroundStyle(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 9)
                .background(AppTheme.gold.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 10).padding(.bottom, 16)
                .opacity(0.5)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }

    private func detailCell(icon: String, label: String, value: String, active: Bool = false) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 10)).foregroundStyle(active ? AppTheme.gold : .secondary)
            Text(label).font(.system(size: 6)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 10, weight: .bold)).foregroundStyle(active ? AppTheme.gold : .white)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 9)
        .background(Color(white: active ? 0.16 : 0.12), in: RoundedRectangle(cornerRadius: 9))
    }
}

// MARK: - Mockup: Scorecard → Finish button highlighted

private struct FinishButtonMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            HStack {
                Image(systemName: "chevron.left").font(.system(size: 9)).foregroundStyle(AppTheme.gold)
                Spacer()
                Text("LOCH 18 · 18").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                Spacer()
                Text("● LIVE").font(.system(size: 7, weight: .bold)).foregroundStyle(.green)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            // Score summary (dimmed)
            VStack(spacing: 2) {
                Text("GESAMT").font(.system(size: 7)).foregroundStyle(.secondary)
                Text("92").font(.system(size: 26, weight: .black, design: .rounded)).foregroundStyle(Color.white.opacity(0.5))
                Text("+20").font(.system(size: 9, weight: .bold)).foregroundStyle(Color.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 10)
            .opacity(0.5)

            // Mini scorecard rows (dimmed)
            VStack(spacing: 3) {
                ForEach(16...18, id: \.self) { hole in
                    HStack {
                        Text("Loch \(hole)").font(.system(size: 8)).foregroundStyle(.secondary)
                        Spacer()
                        Text(hole == 18 ? "5" : "4")
                            .font(.system(size: 8, weight: .semibold)).foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 10).padding(.top, 8)
            .opacity(0.4)

            Spacer()

            // ── HIGHLIGHTED: Finish button ───────────────────────────
            ZStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11)).foregroundStyle(.black)
                    Text("Runde abschließen")
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 11)
                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 11))
                .padding(.horizontal, 10)

                Spotlight(pulse: pulse, radius: 11)
                    .padding(.horizontal, 10)
            }
            .padding(.bottom, 16)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
}

// MARK: - Mockup: Pin Setter on Map

struct PinSetterMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            // Nav bar
            HStack {
                Image(systemName: "chevron.left").font(.system(size: 9)).foregroundStyle(AppTheme.gold)
                Spacer()
                Text("Loch 1 – Position").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                Spacer()
                Text("Fertig").font(.system(size: 9, weight: .semibold)).foregroundStyle(AppTheme.gold)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            // Instruction banner
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill").font(.system(size: 10)).foregroundStyle(.red)
                Text("Tippe auf die Karte, um den Pin zu setzen")
                    .font(.system(size: 7, weight: .medium)).foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.red.opacity(0.15))

            // ── HIGHLIGHTED: Map with pin ────────────────────────────
            ZStack {
                // Fake satellite map
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(red: 0.18, green: 0.24, blue: 0.16))
                    .overlay(
                        // Fake fairway
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.24, green: 0.38, blue: 0.20).opacity(0.8))
                            .frame(width: 28, height: 90)
                            .rotationEffect(.degrees(-15))
                            .offset(x: 10, y: 10)
                    )
                    .overlay(
                        // Fake green
                        Ellipse()
                            .fill(Color(red: 0.28, green: 0.50, blue: 0.22).opacity(0.9))
                            .frame(width: 28, height: 22)
                            .offset(x: 14, y: -42)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Pulsing pin marker
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(pulse ? 0.25 : 0.1))
                        .frame(width: pulse ? 28 : 20, height: pulse ? 28 : 20)
                        .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: pulse)
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.red)
                }
                .offset(x: 14, y: -38)

                // Distance badge
                Text("354 m zum Loch")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.black.opacity(0.7), in: Capsule())
                    .offset(x: 14, y: -20)

                Spotlight(pulse: pulse, radius: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(Rectangle())
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
}

// MARK: - Mockup: Club Recommendation Card

struct ClubRecommendationMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            HStack {
                Image(systemName: "chevron.left").font(.system(size: 9)).foregroundStyle(AppTheme.gold)
                Spacer()
                Text("LOCH 4 · 18").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                Spacer()
                Text("● LIVE").font(.system(size: 7, weight: .bold)).foregroundStyle(.green)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            // Hole card (dimmed)
            VStack(spacing: 2) {
                Text("PAR 4").font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary)
                Text("04").font(.system(size: 22, weight: .black, design: .rounded).italic()).foregroundStyle(Color.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 10)
            .opacity(0.45)

            Spacer()

            // ── HIGHLIGHTED: Pin distance + club recommendation ──────
            ZStack {
                VStack(spacing: 0) {
                    // Distance row
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.red.opacity(0.15)).frame(width: 26, height: 26)
                            Image(systemName: "mappin.circle.fill").font(.system(size: 13)).foregroundStyle(.red)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("186 m zum Loch")
                                .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                            Text("Pin gesetzt · Loch 4")
                                .font(.system(size: 6)).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10).padding(.vertical, 8)

                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 10)

                    // Club recommendation row
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(AppTheme.gold.opacity(0.15)).frame(width: 26, height: 26)
                            Image(systemName: "figure.golf").font(.system(size: 11)).foregroundStyle(AppTheme.gold)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Empfehlung: 5 Wood")
                                .font(.system(size: 10, weight: .bold)).foregroundStyle(AppTheme.gold)
                            Text("Ø 180 m · aus 12 Messungen")
                                .font(.system(size: 6)).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 10).padding(.vertical, 8)
                }
                .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 10)

                Spotlight(pulse: pulse, radius: 12)
                    .padding(.horizontal, 10)
            }

            Spacer()

            // Stroke counter (dimmed)
            HStack(spacing: 16) {
                Text("−").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 32, height: 32).background(Color(white: 0.18), in: RoundedRectangle(cornerRadius: 8))
                Text("3").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(Color.white.opacity(0.4))
                Text("+").font(.system(size: 14, weight: .bold)).foregroundStyle(.black)
                    .frame(width: 32, height: 32).background(AppTheme.gold.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .opacity(0.45)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
}

// MARK: - Mockup: Shot Tracker Map

struct ShotTrackerMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            // Instruction banner
            HStack(spacing: 6) {
                Image(systemName: "figure.golf").font(.system(size: 9)).foregroundStyle(.blue)
                Text("Abschlag setzen").font(.system(size: 7, weight: .semibold)).foregroundStyle(.blue)
                Spacer()
                Text("Standort").font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.blue.opacity(0.7), in: Capsule())
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))

            // ── HIGHLIGHTED: Map with shots ──────────────────────────
            ZStack {
                // Satellite-style background
                Rectangle()
                    .fill(Color(red: 0.18, green: 0.24, blue: 0.16))
                    .overlay(
                        // Fairway strip
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.24, green: 0.38, blue: 0.20).opacity(0.75))
                            .frame(width: 32, height: 110)
                            .rotationEffect(.degrees(8))
                            .offset(x: -5, y: 5)
                    )

                // Shot line 1 → 2
                Path { p in
                    p.move(to: CGPoint(x: 50, y: 130))
                    p.addLine(to: CGPoint(x: 85, y: 75))
                }
                .stroke(AppTheme.gold.opacity(0.7), lineWidth: 1.5)

                // Shot line 2 → 3 (current, brighter)
                Path { p in
                    p.move(to: CGPoint(x: 85, y: 75))
                    p.addLine(to: CGPoint(x: 105, y: 38))
                }
                .stroke(AppTheme.gold, lineWidth: 2)

                // Shot marker 1
                ZStack {
                    Circle().fill(Color.blue).frame(width: 18, height: 18)
                    Text("1").font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
                }
                .position(x: 50, y: 130)

                // Shot marker 2
                ZStack {
                    Circle().fill(Color.blue).frame(width: 18, height: 18)
                    Text("2").font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
                }
                .position(x: 85, y: 75)

                // Landing marker (orange target)
                ZStack {
                    Circle().fill(.white).frame(width: 16, height: 16)
                    Image(systemName: "target").font(.system(size: 12)).foregroundStyle(.orange)
                }
                .position(x: 105, y: 38)

                // Pulsing shot-3 start marker
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(pulse ? 0.3 : 0.1))
                        .frame(width: pulse ? 24 : 16, height: pulse ? 24 : 16)
                        .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: pulse)
                    Circle().fill(Color.blue).frame(width: 18, height: 18)
                    Text("3").font(.system(size: 7, weight: .bold)).foregroundStyle(.white)
                }
                .position(x: 85, y: 75)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(Rectangle())

            // Bottom panel
            VStack(spacing: 6) {
                // Distance row (highlighted)
                ZStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("128 m").font(.system(size: 12, weight: .bold)).foregroundStyle(AppTheme.gold)
                            Text("Meter").font(.system(size: 6)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Speichern")
                            .font(.system(size: 8, weight: .bold)).foregroundStyle(.black)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(AppTheme.gold, in: Capsule())
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 10)

                    Spotlight(pulse: pulse, radius: 10)
                        .padding(.horizontal, 10)
                }

                // Club chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(["Driver", "3 Wood", "5 Wood", "7 Eisen"], id: \.self) { club in
                            Text(club)
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundStyle(club == "5 Wood" ? Color.black : Color.white)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(club == "5 Wood" ? AppTheme.gold : Color(white: 0.20), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 10)
                }

                // Shot log
                HStack {
                    Label("Schlag 1 · Driver", systemImage: "figure.golf")
                        .font(.system(size: 7)).foregroundStyle(.secondary)
                    Spacer()
                    Text("195 m").font(.system(size: 7, weight: .bold)).foregroundStyle(AppTheme.gold)
                }
                .padding(.horizontal, 12)
            }
            .padding(.vertical, 6)
            .background(Color(white: 0.10))
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
}

// MARK: - Mockup: Stats → Chart highlighted

private struct StatsChartMockup: View {
    let pulse: Bool
    var body: some View {
        VStack(spacing: 0) {
            MockStatusBar()
            HStack {
                Text("Statistiken")
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)

            VStack(spacing: 8) {
                // Handicap card (dimmed)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WHS Handicap").font(.system(size: 7)).foregroundStyle(.secondary)
                        Text("24.0")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.gold)
                    }
                    Spacer()
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 16)).foregroundStyle(AppTheme.gold.opacity(0.3))
                }
                .padding(10)
                .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 10)
                .opacity(0.45)

                // ── HIGHLIGHTED: Score chart ─────────────────────────
                ZStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SCORE-VERLAUF")
                            .font(.system(size: 7, weight: .semibold)).foregroundStyle(.secondary)
                        HStack(alignment: .bottom, spacing: 5) {
                            ForEach([0.50, 0.65, 0.55, 0.75, 0.60, 0.80, 0.70], id: \.self) { h in
                                Capsule()
                                    .fill(AppTheme.gold.opacity(0.75))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: CGFloat(44) * h)
                            }
                        }
                        .frame(height: 44)
                    }
                    .padding(10)
                    .background(Color(white: 0.14), in: RoundedRectangle(cornerRadius: 11))
                    .padding(.horizontal, 10)

                    Spotlight(pulse: pulse, radius: 11)
                        .padding(.horizontal, 10)
                }

                // Stat pills (dimmed)
                HStack(spacing: 5) {
                    ForEach([("61%", "Fairway"), ("38%", "GIR"), ("1.9", "Putts")], id: \.0) { val, lbl in
                        VStack(spacing: 2) {
                            Text(val).font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                            Text(lbl).font(.system(size: 6)).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 10)
                .opacity(0.45)
            }
            .padding(.top, 4)

            Spacer()
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
}
