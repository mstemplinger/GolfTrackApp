import SwiftUI

// Nachgebaute App-Ansichten für die Golf-Einführung. Gebaut für die feste
// Zeichenfläche `OnbCanvas` und in `OnbStage` auf den Bildschirm skaliert,
// darum stehen hier echte Schriftgrößen statt Mini-Werten.

// MARK: - Gerät

/// iPhone-Rahmen mit Dynamic Island, mittig in der Zeichenfläche.
struct OnbPhone<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        let size = OnbCanvas.phone
        ZStack {
            RoundedRectangle(cornerRadius: 46, style: .continuous)
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 46, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.06)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.55), radius: 26, y: 14)

            content
                .frame(width: size.width - 16, height: size.height - 16)
                .background(AppTheme.bg)
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))

            Capsule()
                .fill(.black)
                .frame(width: 84, height: 24)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 18)
        }
        .frame(width: size.width, height: size.height)
        .frame(width: OnbCanvas.size.width, height: OnbCanvas.size.height)
    }
}

// MARK: - Bausteine

private struct OnbStatusBar: View {
    var body: some View {
        HStack {
            Text(verbatim: "9:41")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
            }
            .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 28)
        .frame(height: 50)
    }
}

/// Bildschirm mit Statusleiste und – falls gesetzt – der schwebenden Tab-Leiste.
private struct OnbScreen<Content: View>: View {
    var tab: Int? = nil
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                OnbStatusBar()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            if let tab {
                OnbTabBar(selected: tab)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
            }
        }
    }
}

private struct OnbTabBar: View {
    let selected: Int

    private let items: [(String, LocalizedStringKey)] = [
        ("house.fill", "Home"), ("figure.golf", "Training"), ("book.fill", "Regeln"),
        ("lightbulb.fill", "Tipps"), ("person.fill", "Profil"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                VStack(spacing: 2) {
                    Image(systemName: items[i].0).font(.system(size: 15))
                    Text(items[i].1).font(.system(size: 8, weight: .medium))
                }
                .foregroundStyle(i == selected ? AppTheme.gold : .white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(i == selected ? Color.white.opacity(0.10) : .clear, in: Capsule())
            }
        }
        .padding(4)
        .background(Color(red: 0.07, green: 0.19, blue: 0.12).opacity(0.96), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
    }
}

private extension View {
    func onbCard(_ radius: CGFloat = 16, padding: CGFloat = 12) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Pulsierender Goldrahmen um das Element, um das es auf der Seite geht.
private struct OnbHighlight: ViewModifier {
    var radius: CGFloat = 14
    @Environment(\.onbActive) private var active
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: radius + 4, style: .continuous)
                .strokeBorder(AppTheme.gold, lineWidth: 2.5)
                .padding(-5)
                .opacity(active ? (pulse ? 1 : 0.45) : 0)
                .shadow(color: AppTheme.gold.opacity(0.6), radius: 6)
        )
        .onAppear {
            guard !reduceMotion else { pulse = true; return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

private extension View {
    func onbHighlight(_ radius: CGFloat = 14) -> some View { modifier(OnbHighlight(radius: radius)) }
}

private let onbDarkText = Color(red: 0.06, green: 0.14, blue: 0.08)

// MARK: - Willkommen

/// Raster aller Bereiche – füllt die Bühne statt eines einzelnen Symbols.
struct OnbWelcomeVisual: View {
    @Environment(\.onbActive) private var active

    private let tiles: [(String, LocalizedStringKey)] = [
        ("list.number", "Zählkarte"), ("location.fill", "GPS-Distanzen"),
        ("bag.fill", "Schläger & Bag"), ("chart.line.uptrend.xyaxis", "WHS-Handicap"),
        ("figure.walk", "Laufspur"), ("cloud.sun.fill", "Golf-Wetter"),
        ("headphones", "Audio-Training"), ("waveform", "Caddy"),
        ("graduationcap.fill", "Platzreife"), ("applewatch", "Apple Watch"),
    ]

    var body: some View {
        VStack(spacing: 22) {
            Image("AppLogo")
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: AppTheme.gold.opacity(0.35), radius: 22)
                .shadow(color: .black.opacity(0.5), radius: 12, y: 6)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                      spacing: 12) {
                ForEach(tiles.indices, id: \.self) { i in
                    HStack(spacing: 10) {
                        Image(systemName: tiles[i].0)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppTheme.gold)
                            .frame(width: 38, height: 38)
                            .background(AppTheme.gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 11))
                        Text(tiles[i].1)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: 0)
                    }
                    .padding(9)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
                    .opacity(active ? 1 : 0)
                    .offset(y: active ? 0 : 12)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(active ? 0.05 * Double(i) : 0),
                               value: active)
                }
            }
        }
        .padding(.horizontal, 2)
        .frame(width: OnbCanvas.wide.width, height: OnbCanvas.wide.height)
    }
}

// MARK: - Startseite

struct OnbHomeMock: View {
    var body: some View {
        OnbPhone {
            OnbScreen(tab: 0) {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image("AppLogo").resizable().scaledToFill()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        Text(verbatim: "GolfTrack").font(.system(size: 19, weight: .bold))
                        Spacer()
                    }
                    .foregroundStyle(.white)

                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Willkommen zurück,").font(.system(size: 11)).foregroundStyle(AppTheme.textSec)
                            Text(verbatim: "Alex!").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill").foregroundStyle(AppTheme.gold)
                            Text(verbatim: "19°").foregroundStyle(.white)
                        }
                        .font(.system(size: 14, weight: .semibold))
                    }
                    .onbCard()

                    nearbyCard

                    HStack(spacing: 8) {
                        statBox("Handicap", value: "18.4", sub: "WHS")
                        statBox("Letzte Runde", value: "86", sub: "+14")
                    }

                    weatherCard

                    Label("Neue Runde spielen", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(onbDarkText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 13))

                    HStack(spacing: 8) {
                        greenButton("Platzreife lernen", icon: "graduationcap.fill")
                        greenButton("Verlauf", icon: "clock.fill")
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "waveform.circle.fill").font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Caddy – Golf-Assistent").font(.system(size: 12, weight: .semibold))
                            Text("Regeln, Tipps & Strategien").font(.system(size: 9)).opacity(0.7)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .semibold)).opacity(0.5)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 13)
                            .fill(LinearGradient(colors: [Color(red: 0.12, green: 0.30, blue: 0.12),
                                                          Color(red: 0.08, green: 0.20, blue: 0.08)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppTheme.gold.opacity(0.35), lineWidth: 1))
                    )
                }
                .padding(.horizontal, 14)
            }
        }
    }

    private func greenButton(_ title: LocalizedStringKey, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AppTheme.greenMid, in: RoundedRectangle(cornerRadius: 12))
    }

    private var nearbyCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "flag.fill").font(.system(size: 16)).foregroundStyle(AppTheme.gold)
            VStack(alignment: .leading, spacing: 1) {
                Text("Du bist hier").font(.system(size: 9, weight: .semibold)).foregroundStyle(AppTheme.gold)
                Text(verbatim: "Golfclub Bayerwald").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
            }
            Spacer(minLength: 0)
            Text("Starten")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(onbDarkText)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(AppTheme.gold, in: Capsule())
        }
        .onbCard(14, padding: 10)
        .onbHighlight(14)
    }

    private func statBox(_ title: LocalizedStringKey, value: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
            Text(verbatim: value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(verbatim: sub).font(.system(size: 9, weight: .semibold)).foregroundStyle(AppTheme.gold)
        }
        .onbCard(14, padding: 10)
    }

    private var weatherCard: some View {
        let levels: [CGFloat] = [0.35, 0.5, 0.8, 0.9, 1, 0.95, 0.85, 0.6, 0.4, 0.3]
        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("Golf-Wetter", systemImage: "cloud.sun.fill")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
                Spacer()
                Text(verbatim: "10–15")
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(AppTheme.gold)
            }
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(levels.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill((2...6).contains(i) ? AppTheme.gold : AppTheme.cardAlt)
                        .frame(height: 30 * levels[i])
                }
            }
            .frame(height: 30, alignment: .bottom)
        }
        .onbCard(14, padding: 10)
    }
}

// MARK: - Neue Runde

struct OnbNewRoundMock: View {
    var body: some View {
        OnbPhone {
            OnbScreen {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Abbrechen").font(.system(size: 13)).foregroundStyle(AppTheme.gold)
                        Spacer()
                        Text("Neue Runde").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        Spacer()
                        Text("Abbrechen").font(.system(size: 13)).hidden()
                    }

                    section("Platz") {
                        HStack(spacing: 10) {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(onbDarkText)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 9))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(verbatim: "Golfclub Bayerwald").font(.system(size: 13, weight: .bold))
                                Text("18 Löcher · Par 72").font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(AppTheme.textTer)
                        }
                        .foregroundStyle(.white)
                        .onbCard(13, padding: 10)
                    }

                    section("Spielform") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 0) {
                                segment("Einzel", selected: true)
                                segment("Partner", selected: false)
                                segment("Team", selected: false)
                            }
                            .padding(3)
                            .background(AppTheme.cardDark, in: Capsule())

                            HStack(spacing: 6) {
                                chip("Zählspiel", selected: true)
                                chip("Stableford", selected: false)
                                chip("Matchplay", selected: false)
                            }
                        }
                        .onbCard(13, padding: 10)
                        .onbHighlight(13)
                    }

                    section("Bag") {
                        HStack {
                            Image(systemName: "bag.fill").foregroundStyle(AppTheme.gold)
                            Text("Mein Bag").font(.system(size: 13, weight: .semibold))
                            Spacer()
                            Text("14 Schläger").font(.system(size: 11)).foregroundStyle(AppTheme.textSec)
                        }
                        .foregroundStyle(.white)
                        .onbCard(13, padding: 10)
                    }

                    section("Abschlag") {
                        HStack(spacing: 6) {
                            tee(.yellow, "Gelb", selected: true)
                            tee(.red, "Rot", selected: false)
                            tee(.white, "Weiß", selected: false)
                            tee(.blue, "Blau", selected: false)
                        }
                        .onbCard(13, padding: 8)
                    }

                    section("Spieler") {
                        VStack(spacing: 8) {
                            playerRow(initial: "A", name: "Alex", hcp: "18.4")
                            playerRow(initial: "S", name: "Sam", hcp: "24.0")
                            Label("Spieler hinzufügen", systemImage: "plus.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.gold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onbCard(13, padding: 10)
                    }

                    Spacer(minLength: 0)

                    Text("Runde starten")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(onbDarkText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.bottom, 18)
                }
                .padding(.horizontal, 14)
            }
        }
    }

    private func section<C: View>(_ title: LocalizedStringKey, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 10, weight: .semibold)).textCase(.uppercase)
                .foregroundStyle(AppTheme.textTer)
            content()
        }
    }

    private func segment(_ title: LocalizedStringKey, selected: Bool) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(selected ? onbDarkText : AppTheme.textSec)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(selected ? AppTheme.gold : .clear, in: Capsule())
    }

    private func chip(_ title: LocalizedStringKey, selected: Bool) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(selected ? AppTheme.gold : .white.opacity(0.8))
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(selected ? AppTheme.gold.opacity(0.16) : AppTheme.cardAlt, in: Capsule())
            .overlay(Capsule().strokeBorder(selected ? AppTheme.gold.opacity(0.6) : .clear, lineWidth: 1))
    }

    private func tee(_ color: Color, _ name: LocalizedStringKey, selected: Bool) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(name).font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(selected ? AppTheme.gold : .white.opacity(0.8))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(selected ? AppTheme.gold.opacity(0.16) : .clear, in: Capsule())
    }

    private func playerRow(initial: String, name: String, hcp: String) -> some View {
        HStack(spacing: 10) {
            Text(verbatim: initial)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(onbDarkText)
                .frame(width: 26, height: 26)
                .background(AppTheme.gold.opacity(0.85), in: Circle())
            Text(verbatim: name).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
            Spacer()
            Text(verbatim: "HCP \(hcp)").font(.system(size: 10, weight: .semibold)).foregroundStyle(AppTheme.textSec)
        }
    }
}

// MARK: - Zählkarte

struct OnbScoringMock: View {
    var body: some View {
        OnbPhone {
            OnbScreen {
                VStack(spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("AKTUELLES LOCH")
                                .font(.system(size: 8, weight: .semibold)).tracking(2)
                                .foregroundStyle(AppTheme.textTer)
                            Text(verbatim: "07")
                                .font(.system(size: 50, weight: .heavy)).italic()
                                .foregroundStyle(AppTheme.gold)
                            HStack(spacing: 5) {
                                pill("arrow.up.arrow.down", "HCP 5")
                                pill("ruler", "356 m")
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text(verbatim: "PAR 4").font(.system(size: 12, weight: .semibold)).tracking(1)
                                .foregroundStyle(AppTheme.textSec)
                            Text("Par")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.white.opacity(0.12), in: Capsule())
                        }
                    }
                    .padding(.top, 4)

                    HStack(spacing: 8) {
                        Image(systemName: "location.fill").foregroundStyle(AppTheme.gold)
                        Text("Noch 142 m zum Loch").font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                        Spacer()
                        Text("LIVE")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(onbDarkText)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(AppTheme.gold, in: Capsule())
                    }
                    .onbCard(13, padding: 10)
                    .onbHighlight(13)

                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("EMPFOHLEN").font(.system(size: 8, weight: .heavy)).tracking(1)
                                .foregroundStyle(AppTheme.gold)
                            Text(verbatim: "7i").font(.system(size: 17, weight: .heavy)).foregroundStyle(.white)
                        }
                        Text(verbatim: "Ø 140 m").font(.system(size: 11)).foregroundStyle(AppTheme.textSec)
                        Spacer()
                        Text(verbatim: "8i").clubChip()
                        Text(verbatim: "6i").clubChip()
                    }
                    .onbCard(13, padding: 10)

                    VStack(spacing: 4) {
                        Text("SCHLÄGE").font(.system(size: 9, weight: .semibold)).tracking(2)
                            .foregroundStyle(AppTheme.textTer)
                        HStack {
                            stepperButton("minus")
                            Spacer()
                            Text(verbatim: "4").font(.system(size: 60, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                            stepperButton("plus", gold: true)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .onbCard(16, padding: 12)

                    HStack(spacing: 8) {
                        smallBox("Putts", value: "2")
                        toggleBox("Fairway", on: true)
                        toggleBox("GIR", on: false)
                    }

                    holeStrip

                    HStack {
                        Text("SCORE GESAMT").font(.system(size: 9, weight: .semibold)).tracking(1.5)
                            .foregroundStyle(AppTheme.textTer)
                        Spacer()
                        Text(verbatim: "27").font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(verbatim: "+3").font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.3))
                    }
                    .onbCard(13, padding: 10)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }

    private func pill(_ icon: String, _ text: String) -> some View {
        Label { Text(verbatim: text) } icon: { Image(systemName: icon) }
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(AppTheme.textSec)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(AppTheme.cardAlt, in: Capsule())
    }

    private func stepperButton(_ icon: String, gold: Bool = false) -> some View {
        Image(systemName: icon)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(gold ? onbDarkText : .white)
            .frame(width: 52, height: 52)
            .background(gold ? AppTheme.gold : AppTheme.cardAlt, in: Circle())
    }

    private func smallBox(_ title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
            Text(verbatim: value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 13))
    }

    private func toggleBox(_ title: LocalizedStringKey, on: Bool) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(on ? AppTheme.gold : AppTheme.textTer)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 13))
    }

    private var holeStrip: some View {
        HStack(spacing: 5) {
            ForEach(1...9, id: \.self) { n in
                Text(verbatim: "\(n)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(n == 7 ? onbDarkText : n < 7 ? .white : AppTheme.textTer)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .background(n == 7 ? AppTheme.gold : n < 7 ? AppTheme.cardAlt : AppTheme.cardDark,
                                in: Circle())
            }
        }
    }
}

private extension Text {
    func clubChip() -> some View {
        self.font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white.opacity(0.8))
            .frame(width: 32, height: 26)
            .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Karte

/// Gezeichnetes Loch als Satellitenansicht: Rough, Fairway mit Dogleg,
/// Bunker, Wasser und Grün. Koordinaten relativ zur Fläche (0…1).
private struct OnbHoleMap: View {
    var body: some View {
        Canvas { ctx, size in
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * size.width, y: y * size.height) }

            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.11, green: 0.29, blue: 0.13),
                                                             Color(red: 0.08, green: 0.22, blue: 0.10)]),
                                           startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

            // Bäume
            for (x, y, r) in [(0.1, 0.2, 0.07), (0.85, 0.55, 0.09), (0.15, 0.62, 0.08), (0.9, 0.12, 0.06),
                              (0.08, 0.85, 0.07), (0.62, 0.92, 0.06), (0.92, 0.82, 0.07)] as [(CGFloat, CGFloat, CGFloat)] {
                let rr = r * size.width
                ctx.fill(Path(ellipseIn: CGRect(x: x * size.width - rr, y: y * size.height - rr, width: rr * 2, height: rr * 2)),
                         with: .color(Color(red: 0.05, green: 0.16, blue: 0.07)))
            }

            // Wasser
            ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.58, y: size.height * 0.36,
                                            width: size.width * 0.3, height: size.height * 0.1)),
                     with: .color(Color(red: 0.16, green: 0.36, blue: 0.52)))

            // Fairway mit Knick nach links
            var fairway = Path()
            fairway.move(to: p(0.5, 0.88))
            fairway.addCurve(to: p(0.38, 0.22), control1: p(0.55, 0.6), control2: p(0.3, 0.45))
            ctx.stroke(fairway, with: .color(Color(red: 0.26, green: 0.55, blue: 0.27)),
                       style: StrokeStyle(lineWidth: size.width * 0.2, lineCap: .round))

            // Bunker
            for (x, y, w, h) in [(0.22, 0.43, 0.1, 0.05), (0.5, 0.13, 0.09, 0.04)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
                ctx.fill(Path(ellipseIn: CGRect(x: x * size.width, y: y * size.height,
                                                width: w * size.width, height: h * size.height)),
                         with: .color(Color(red: 0.86, green: 0.78, blue: 0.56)))
            }

            // Grün
            ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.28, y: size.height * 0.15,
                                            width: size.width * 0.22, height: size.height * 0.1)),
                     with: .color(Color(red: 0.38, green: 0.72, blue: 0.36)))

            // Abschlag
            ctx.fill(Path(roundedRect: CGRect(x: size.width * 0.44, y: size.height * 0.86,
                                              width: size.width * 0.12, height: size.height * 0.04),
                          cornerRadius: 3),
                     with: .color(Color(red: 0.32, green: 0.62, blue: 0.32)))
        }
    }
}

private struct OnbPin: View {
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "flag.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.red)
                .offset(x: 6)
            Rectangle().fill(.white).frame(width: 2, height: 10)
        }
        .shadow(color: .black.opacity(0.5), radius: 3)
    }
}

private struct OnbShotLabel: View {
    let club: String
    let meters: String
    var body: some View {
        HStack(spacing: 4) {
            Text(verbatim: club).font(.system(size: 10, weight: .heavy)).foregroundStyle(onbDarkText)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(AppTheme.gold, in: Capsule())
            Text(verbatim: meters).font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 5).padding(.vertical, 3)
        .background(.black.opacity(0.55), in: Capsule())
    }
}

struct OnbShotMapMock: View {
    var body: some View {
        OnbPhone {
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack(alignment: .top) {
                    OnbHoleMap()

                    // Schlaglinien Abschlag → Landepunkt → Grün
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.5, y: h * 0.87))
                        path.addLine(to: CGPoint(x: w * 0.47, y: h * 0.52))
                        path.addLine(to: CGPoint(x: w * 0.39, y: h * 0.21))
                    }
                    .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 5]))

                    ForEach([(0.5, 0.87), (0.47, 0.52)] as [(CGFloat, CGFloat)], id: \.0) { pt in
                        Circle().fill(.white).frame(width: 12, height: 12)
                            .overlay(Circle().strokeBorder(AppTheme.gold, lineWidth: 3))
                            .position(x: w * pt.0, y: h * pt.1)
                    }

                    OnbPin().position(x: w * 0.39, y: h * 0.19)

                    OnbShotLabel(club: "Dr", meters: "212 m").position(x: w * 0.68, y: h * 0.7)
                    OnbShotLabel(club: "7i", meters: "138 m").position(x: w * 0.66, y: h * 0.33)

                    VStack(spacing: 0) {
                        OnbStatusBar()
                        HStack {
                            Label { Text("Pin gesetzt") } icon: { Image(systemName: "checkmark.circle.fill") }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AppTheme.gold)
                            Spacer()
                            Text(verbatim: "Loch 7 · Par 4").font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(.black.opacity(0.55), in: Capsule())
                        .padding(.horizontal, 12)
                    }

                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Zur Fahne").font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
                                Text(verbatim: "142 m").font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Label("Schlag", systemImage: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(onbDarkText)
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(AppTheme.gold, in: Capsule())
                        }
                        .padding(12)
                        .background(AppTheme.card.opacity(0.96), in: RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 12)
                        .padding(.bottom, 18)
                    }
                }
            }
        }
    }
}

// MARK: - Laufspur

struct OnbTrackingMock: View {
    var body: some View {
        OnbPhone {
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack(alignment: .top) {
                    OnbHoleMap()

                    // Fairway-Korridor aus mehreren Runden
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.5, y: h * 0.86))
                        path.addCurve(to: CGPoint(x: w * 0.39, y: h * 0.21),
                                      control1: CGPoint(x: w * 0.56, y: h * 0.58),
                                      control2: CGPoint(x: w * 0.3, y: h * 0.45))
                    }
                    .stroke(AppTheme.gold.opacity(0.22), style: StrokeStyle(lineWidth: w * 0.16, lineCap: .round))

                    // Laufspur
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.56, y: h * 0.95))
                        path.addCurve(to: CGPoint(x: w * 0.52, y: h * 0.86),
                                      control1: CGPoint(x: w * 0.6, y: h * 0.91), control2: CGPoint(x: w * 0.55, y: h * 0.88))
                        path.addCurve(to: CGPoint(x: w * 0.43, y: h * 0.53),
                                      control1: CGPoint(x: w * 0.6, y: h * 0.74), control2: CGPoint(x: w * 0.38, y: h * 0.62))
                        path.addCurve(to: CGPoint(x: w * 0.42, y: h * 0.22),
                                      control1: CGPoint(x: w * 0.5, y: h * 0.42), control2: CGPoint(x: w * 0.33, y: h * 0.32))
                        path.addCurve(to: CGPoint(x: w * 0.7, y: h * 0.08),
                                      control1: CGPoint(x: w * 0.5, y: h * 0.15), control2: CGPoint(x: w * 0.62, y: h * 0.12))
                    }
                    .stroke(Color(red: 0.45, green: 0.78, blue: 1.0),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 6]))

                    marker("T", color: .white).position(x: w * 0.5, y: h * 0.88)
                    OnbPin().position(x: w * 0.39, y: h * 0.19)

                    VStack(spacing: 0) {
                        OnbStatusBar()
                        HStack(spacing: 10) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(onbDarkText)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.gold, in: Circle())
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Deine Laufspur").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                                Text(verbatim: "6,4 km · 4:12 h").font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(AppTheme.card.opacity(0.95), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 12)
                    }

                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            legend(color: Color(red: 0.45, green: 0.78, blue: 1.0), text: "Laufspur")
                            legend(color: AppTheme.gold.opacity(0.6), text: "Fairway-Verlauf")
                        }
                        .padding(10)
                        .background(AppTheme.card.opacity(0.95), in: Capsule())
                        .padding(.bottom, 22)
                    }
                }
            }
        }
    }

    private func marker(_ letter: String, color: Color) -> some View {
        Text(verbatim: letter)
            .font(.system(size: 11, weight: .heavy))
            .foregroundStyle(onbDarkText)
            .frame(width: 22, height: 22)
            .background(color, in: Circle())
            .overlay(Circle().strokeBorder(AppTheme.gold, lineWidth: 2))
            .shadow(color: .black.opacity(0.5), radius: 3)
    }

    private func legend(color: Color, text: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Capsule().fill(color).frame(width: 14, height: 5)
            Text(text).font(.system(size: 10, weight: .semibold)).foregroundStyle(.white)
        }
    }
}

// MARK: - Auswertung

struct OnbRoundCompleteMock: View {
    var body: some View {
        OnbPhone {
            OnbScreen {
                VStack(spacing: 11) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(AppTheme.gold)
                        .frame(width: 60, height: 60)
                        .background(AppTheme.gold.opacity(0.15), in: Circle())
                    Text("Runde abgeschlossen!").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)

                    HStack(spacing: 8) {
                        resultBox("Score", value: "86", sub: "+14", subColor: AppTheme.textSec)
                        resultBox("Handicap", value: "17.9", sub: "▼ 0.5", subColor: Color(red: 0.4, green: 0.85, blue: 0.5))
                            .onbHighlight(13)
                    }

                    HStack(spacing: 0) {
                        miniStat("Putts", "32")
                        miniStat("Fairway", "57 %")
                        miniStat("GIR", "33 %")
                    }
                    .padding(.vertical, 9)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 13))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Passend zu dieser Runde").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                        lesson(no: "04", title: "Putten auf Distanz", reason: "32 Putts")
                        lesson(no: "11", title: "Der Weg aufs Grün", reason: "GIR 33 %")
                        lesson(no: "16", title: "Gelassen bis zum letzten Loch", reason: "Back 9 +9")
                    }
                    .onbCard(14, padding: 10)

                    HStack(spacing: 10) {
                        Image(systemName: "gamecontroller.fill").foregroundStyle(AppTheme.gold)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Bestenliste").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                            Text("Vergleiche dich mit Freunden").font(.system(size: 9)).foregroundStyle(AppTheme.textSec)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(AppTheme.textTer)
                    }
                    .onbCard(13, padding: 10)

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        Label("Teilen", systemImage: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(AppTheme.greenMid, in: RoundedRectangle(cornerRadius: 13))
                        Text("Fertig")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(onbDarkText)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 13))
                    }
                    .padding(.bottom, 18)
                }
                .padding(.horizontal, 14)
            }
        }
    }

    private func resultBox(_ title: LocalizedStringKey, value: String, sub: String, subColor: Color) -> some View {
        VStack(spacing: 1) {
            Text(title).font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
            Text(verbatim: value).font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundStyle(.white)
            Text(verbatim: sub).font(.system(size: 11, weight: .bold)).foregroundStyle(subColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 13))
    }

    private func miniStat(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(verbatim: value).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(title).font(.system(size: 9)).foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
    }

    private func lesson(no: String, title: LocalizedStringKey, reason: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: "play.fill")
                .font(.system(size: 11))
                .foregroundStyle(onbDarkText)
                .frame(width: 28, height: 28)
                .background(AppTheme.gold, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                Text(verbatim: "\(no) · \(reason)").font(.system(size: 9)).foregroundStyle(AppTheme.textSec)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Training

struct OnbTrainingMock: View {
    var body: some View {
        OnbPhone {
            OnbScreen(tab: 1) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Training").font(.system(size: 24, weight: .bold)).foregroundStyle(.white)

                    HStack(spacing: 6) {
                        category("Alle", selected: true)
                        category("Schwung", selected: false)
                        category("Putten", selected: false)
                        category("Mental", selected: false)
                    }

                    // Player
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [AppTheme.gold, AppTheme.goldDark],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                                .overlay(Image(systemName: "figure.golf").font(.system(size: 20)).foregroundStyle(onbDarkText))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(verbatim: "07").font(.system(size: 9, weight: .bold)).foregroundStyle(AppTheme.gold)
                                Text("Ruhig bleiben unter Druck").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                            }
                        }
                        Capsule().fill(AppTheme.cardAlt).frame(height: 4)
                            .overlay(alignment: .leading) { Capsule().fill(AppTheme.gold).frame(width: 110, height: 4) }
                        HStack(spacing: 26) {
                            Spacer()
                            Image(systemName: "gobackward.15")
                            Image(systemName: "pause.fill").font(.system(size: 22))
                                .foregroundStyle(onbDarkText)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.gold, in: Circle())
                            Image(systemName: "goforward.15")
                            Spacer()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    }
                    .onbCard(16, padding: 12)
                    .onbHighlight(16)

                    lessonRow("figure.golf", "Der lange Schwung", "12 min")
                    lessonRow("circle.dotted", "Putten auf Distanz", "9 min")
                    lessonRow("brain.head.profile", "Routine vor dem Schlag", "11 min")

                    HStack(spacing: 12) {
                        ZStack {
                            Circle().stroke(AppTheme.cardAlt, lineWidth: 6)
                            Circle().trim(from: 0, to: 0.68)
                                .stroke(AppTheme.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text(verbatim: "68 %").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        }
                        .frame(width: 50, height: 50)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Platzreife lernen").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                            Text("Regeln, Etikette und Quiz").font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
                        }
                        Spacer(minLength: 0)
                    }
                    .onbCard(16, padding: 10)
                }
                .padding(.horizontal, 14)
            }
        }
    }

    private func category(_ title: LocalizedStringKey, selected: Bool) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(selected ? onbDarkText : .white.opacity(0.85))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(selected ? AppTheme.gold : AppTheme.cardAlt, in: Capsule())
    }

    private func lessonRow(_ icon: String, _ title: LocalizedStringKey, _ length: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.gold)
                .frame(width: 30, height: 30)
                .background(AppTheme.gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
            Spacer()
            Text(verbatim: length).font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
        }
        .onbCard(13, padding: 8)
    }
}

// MARK: - Caddy

struct OnbCaddyMock: View {
    @Environment(\.onbActive) private var active
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var wave = false

    var body: some View {
        OnbPhone {
            OnbScreen {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(AppTheme.gold)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Caddy").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            Text("Golf-Assistent").font(.system(size: 10)).foregroundStyle(AppTheme.textSec)
                        }
                        Spacer()
                    }

                    bubble("Mein Ball liegt im Wasserhindernis. Was darf ich jetzt tun?", mine: true)
                    bubble("Du hast drei Möglichkeiten, jeweils mit einem Strafschlag: Schlag wiederholen, auf der Linie zur Fahne zurückgehen oder seitlich innerhalb von zwei Schlägerlängen droppen (Regel 17).",
                           mine: false)
                    bubble("Und welchen Schläger für 140 m?", mine: true)
                    bubble("Nimm dein 7er-Eisen – damit schlägst du laut deinem Bag im Schnitt 140 m.", mine: false)

                    Spacer(minLength: 0)

                    HStack(alignment: .center, spacing: 4) {
                        ForEach(0..<16, id: \.self) { i in
                            Capsule()
                                .fill(AppTheme.gold)
                                .frame(width: 4, height: barHeight(i))
                        }
                    }
                    .frame(height: 50)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                               value: wave)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(onbDarkText)
                        .frame(width: 68, height: 68)
                        .background(AppTheme.gold, in: Circle())
                        .shadow(color: AppTheme.gold.opacity(0.5), radius: 14)
                        .onbHighlight(34)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 14)
            }
        }
        .onAppear { wave = true }
    }

    private func barHeight(_ i: Int) -> CGFloat {
        let base: [CGFloat] = [0.3, 0.5, 0.8, 0.55, 0.9, 0.4, 0.7, 1, 0.65, 0.85, 0.45, 0.75, 0.5, 0.9, 0.35, 0.55]
        let v = wave ? base[i] : base[(i + 5) % base.count]
        return 8 + 40 * v
    }

    private func bubble(_ text: LocalizedStringKey, mine: Bool) -> some View {
        HStack {
            if mine { Spacer(minLength: 40) }
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(mine ? onbDarkText : .white)
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(mine ? AppTheme.gold : AppTheme.card,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .fixedSize(horizontal: false, vertical: true)
            if !mine { Spacer(minLength: 30) }
        }
    }
}

// MARK: - Profil

struct OnbProfileMock: View {
    var body: some View {
        OnbPhone {
            OnbScreen(tab: 4) {
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Text(verbatim: "A")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(onbDarkText)
                            .frame(width: 54, height: 54)
                            .background(AppTheme.gold, in: Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 2))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: "Alex").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                            Text("Ambitionierter Golfer").font(.system(size: 11)).foregroundStyle(AppTheme.textSec)
                        }
                        Spacer()
                    }
                    .onbCard(16, padding: 12)

                    HStack(spacing: 8) {
                        stat("12", "Runden")
                        stat("81", "Bestleistung")
                        stat("31.5", "Ø Putts")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("WHS-Handicap").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                            Spacer()
                            Text(verbatim: "17.9").font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.gold)
                        }
                        sparkline.frame(height: 46)
                    }
                    .onbCard(16, padding: 12)
                    .onbHighlight(16)

                    row("bag.fill", "Meine Schläger", detail: "14")
                    row("creditcard.fill", "Mitgliedskarte", detail: nil)
                    row("chart.bar.fill", "Statistiken", detail: nil)
                    row("gamecontroller.fill", "Game Center", detail: nil)
                }
                .padding(.horizontal, 14)
            }
        }
    }

    private var sparkline: some View {
        let values: [CGFloat] = [0.2, 0.28, 0.25, 0.4, 0.38, 0.5, 0.48, 0.62, 0.7, 0.68, 0.82, 0.9]
        return GeometryReader { geo in
            let step = geo.size.width / CGFloat(values.count - 1)
            let line = Path { p in
                for (i, v) in values.enumerated() {
                    let pt = CGPoint(x: CGFloat(i) * step, y: geo.size.height * (1 - v))
                    i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                }
            }
            ZStack {
                line.stroke(AppTheme.gold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                Path { p in
                    p.addPath(line)
                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    p.addLine(to: CGPoint(x: 0, y: geo.size.height))
                }
                .fill(LinearGradient(colors: [AppTheme.gold.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
            }
        }
    }

    private func stat(_ value: String, _ title: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(title).font(.system(size: 9)).foregroundStyle(AppTheme.textSec).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 13))
    }

    private func row(_ icon: String, _ title: LocalizedStringKey, detail: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.gold)
                .frame(width: 30, height: 30)
                .background(AppTheme.gold.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
            Text(title).font(.system(size: 13)).foregroundStyle(.white)
            Spacer()
            if let detail {
                Text(verbatim: detail).font(.system(size: 11)).foregroundStyle(AppTheme.textSec)
            }
            Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(AppTheme.textTer)
        }
        .onbCard(13, padding: 8)
    }
}

// MARK: - Abschluss: Wo finde ich was?

/// Die fünf Tabs mit je einem Satz – die Bühne zeigt den Weg durch die App.
struct OnbTabGuideVisual: View {
    @Environment(\.onbActive) private var active

    private let rows: [(String, LocalizedStringKey, LocalizedStringKey)] = [
        ("house.fill", "Home", "Runde starten, Wetter, Verlauf"),
        ("figure.golf", "Training", "Audio-Lektionen für dein Spiel"),
        ("book.fill", "Regeln", "Alle Golfregeln mit Skizzen"),
        ("lightbulb.fill", "Tipps", "Tipps passend zu deinen Runden"),
        ("person.fill", "Profil", "Handicap, Bag, Statistik, Einstellungen"),
    ]

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 34, weight: .heavy))
                .foregroundStyle(onbDarkText)
                .frame(width: 80, height: 80)
                .background(AppTheme.gold, in: Circle())
                .shadow(color: AppTheme.gold.opacity(0.5), radius: 22)
                .scaleEffect(active ? 1 : 0.6)
                .animation(.spring(response: 0.45, dampingFraction: 0.6), value: active)
                .padding(.bottom, 10)

            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 14) {
                    Image(systemName: rows[i].0)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                        .frame(width: 46, height: 46)
                        .background(AppTheme.gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rows[i].1).font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                        Text(rows[i].2).font(.system(size: 13)).foregroundStyle(AppTheme.textSec)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 0)
                }
                .padding(10)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .opacity(active ? 1 : 0)
                .offset(x: active ? 0 : 24)
                .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(active ? 0.15 + 0.07 * Double(i) : 0),
                           value: active)
            }
        }
        .padding(.horizontal, 2)
        .frame(width: OnbCanvas.wide.width, height: OnbCanvas.wide.height)
    }
}
