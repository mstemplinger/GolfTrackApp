import SwiftUI

// MARK: - GolfTip Model

struct GolfTip: Identifiable {
    let id: UUID = UUID()
    let title: String
    let body: String
    let icon: String
}

// MARK: - Tip Content

enum TipsCategoryContent {
    static let anfaenger: [GolfTip] = [
        GolfTip(
            title: "Griff entspannen",
            body: "Halte den Schläger wie ein Vogel – fest genug, damit er nicht wegfliegt, aber nicht so fest, dass du ihn erdrückst. Ein zu fester Griff blockiert die Handgelenke und kostet Distanz.",
            icon: "hand.raised.fill"
        ),
        GolfTip(
            title: "Standfläche prüfen",
            body: "Schulterbreiter Stand für normale Schläge. Die Füße zeigen leicht nach außen. Bei kurzen Eisen etwas enger stehen, bei Holz und Driver etwas breiter.",
            icon: "figure.stand"
        ),
        GolfTip(
            title: "Auge auf dem Ball",
            body: "Bewege den Kopf beim Schwung nicht. Fixiere einen konkreten Punkt auf dem Ball und behalte den Blick dort, bis der Schläger den Ball getroffen hat.",
            icon: "eye.fill"
        ),
        GolfTip(
            title: "Tempo ist alles",
            body: "Ein langsamer, gleichmäßiger Rückschwung erzeugt mehr Kraft als ein schneller. Verhältnis Rückschwung zu Durchschwung: 3:1. Eil dich nie beim Abschlag.",
            icon: "speedometer"
        ),
        GolfTip(
            title: "Chip-Technik",
            body: "Beim Chippen: Gewicht auf den vorderen Fuß, Ball in der Mitte des Stands, Handgelenke fest. Denke an eine Pendelbewegung vom Schultergelenk – kein Handgelenk-Flip.",
            icon: "arrow.down.right"
        ),
    ]

    static let technik: [GolfTip] = [
        GolfTip(
            title: "Schwungachse halten",
            body: "Die Wirbelsäule ist die Achse deines Schwungs. Bleib beim Rückschwung in der Vorbeuge und vermeide seitliches Wackeln. Eine stabile Achse = konsistente Trefferfläche.",
            icon: "arrow.up.arrow.down"
        ),
        GolfTip(
            title: "Hüftrotation",
            body: "Die Hüfte führt den Durchschwung an, nicht die Arme. Beginne den Durchschwung mit dem Drehen der Hüfte zur Zielseite. Die Arme folgen automatisch.",
            icon: "rotate.right"
        ),
        GolfTip(
            title: "Gewichtsverlagerung",
            body: "Im Rückschwung: 70% Gewicht aufs hintere Bein. Im Durchschwung: vollständige Verlagerung aufs vordere Bein. Am Ende: 90% Gewicht vorne, Zehen des hinteren Fußes am Boden.",
            icon: "scalemass.fill"
        ),
        GolfTip(
            title: "Flaches Anspiel",
            body: "Der Schläger sollte von innen auf den Ball treffen (Inside-Out-Bahn). Das erzeugt Draw-Spin und mehr Distanz. Verhindere ein Over-the-Top-Anspiel durch langsamen Beginn des Durchschwungs.",
            icon: "arrow.right.to.line"
        ),
        GolfTip(
            title: "Trefferfläche kontrollieren",
            body: "Triff die Mitte der Schlägerface. Off-Center-Hits kosten 10-15% Distanz. Übe mit Klebeband auf der Face, um dein Treffermuster zu sehen.",
            icon: "target"
        ),
    ]

    static let mentalGame: [GolfTip] = [
        GolfTip(
            title: "Pre-Shot Routine",
            body: "Entwickle eine feste Routine vor jedem Schlag: Stand hinter dem Ball, Ziellinie visualisieren, zwei Probeschwünge, einsteigen, Alignment checken, schlagen. Immer gleich – das beruhigt das Nervensystem.",
            icon: "repeat"
        ),
        GolfTip(
            title: "Einen Schlag nach dem anderen",
            body: "Golf besteht aus einzelnen, unabhängigen Schlägen. Ein Fehler beeinflusst den nächsten Schlag nicht – außer du lässt es zu. Atme tief durch und fokussiere dich nur auf den nächsten Schlag.",
            icon: "1.circle.fill"
        ),
        GolfTip(
            title: "Bogey akzeptieren",
            body: "Ein Bogey ist kein Fehler. Durchschnittliche Amateurspieler spielen konstant Bogey Golf. Wer Bogeys akzeptiert und Double Bogeys vermeidet, hat eine sehr gute Runde.",
            icon: "checkmark.circle.fill"
        ),
        GolfTip(
            title: "Visualisierung",
            body: "Stelle dir den idealen Flug des Balls vor, bevor du schlägst. Sieh das Ziel, sieh die Flugbahn, sieh den Ball landen. Dein Körper schlägt, was dein Geist sieht.",
            icon: "eye.fill"
        ),
        GolfTip(
            title: "Umgang mit Druck",
            body: "Wenn du nervös wirst: verlangsamter Schwung-Gedanke, tiefer Atemzug vor dem Schlag. Nervosität bedeutet, dass du dich kümmerst – nutze diese Energie positiv.",
            icon: "heart.fill"
        ),
    ]

    static let strategie: [GolfTip] = [
        GolfTip(
            title: "Course Management",
            body: "Spiele immer auf die große Fläche, nicht auf die Fahne. Ein Bogey von der Fairwaymitte ist besser als ein Triple vom Rough. Vermeide Hindernisse durch kluge Schlägerwahl.",
            icon: "map.fill"
        ),
        GolfTip(
            title: "Handicap klug nutzen",
            body: "Kenne deine Vorgabelöcher. Nutze deine Vorgabeschläge auf den schwierigsten Löchern strategisch. Ein Net Par auf Loch 1 (SI 1) ist sehr wertvoll.",
            icon: "trophy.fill"
        ),
        GolfTip(
            title: "Wind berücksichtigen",
            body: "Gegen den Wind: einen Schläger mehr, ruhiger schwingen, Ball tiefer halten. Mit dem Wind: Flugkurve wird länger, Kurzspiel wird schneller. Seitenwind: Ball auf die Windseite der Fahne zielen.",
            icon: "wind"
        ),
        GolfTip(
            title: "Putt-Strategie",
            body: "Beim ersten Putt: Ziel ist die Zone 50cm um den Ball – kein Dreiputtter. Beim zweiten Putt unter 1.5m: festes Tempo, schaue den Einloch-Punkt an, nicht den Ball. Vertraue deiner Linie.",
            icon: "circle.fill"
        ),
        GolfTip(
            title: "Risiko vs. Belohnung",
            body: "Frage dich vor jedem riskanten Schlag: Was ist das Worst-Case-Scenario? Wenn der Fehler einen Doppelbogey kostet, ist das Risiko meist nicht wert. Spiele sicher auf Score-Karte-Ziele.",
            icon: "exclamationmark.triangle.fill"
        ),
    ]

    static func tips(for category: TipsCategory) -> [GolfTip] {
        switch category.name {
        case "Anfänger":    return anfaenger
        case "Technik":     return technik
        case "Mental Game": return mentalGame
        case "Strategie":   return strategie
        default:            return []
        }
    }
}

// MARK: - TipsCategoryDetailView

struct TipsCategoryDetailView: View {
    let category: TipsCategory

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Category header
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.18))
                                .frame(width: 52, height: 52)
                            Image(systemName: category.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(category.color)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(category.name)
                                .font(.title3.bold())
                                .foregroundStyle(AppTheme.text)
                            Text("\(TipsCategoryContent.tips(for: category).count) Tipps")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSec)
                        }
                        Spacer()
                    }
                    .padding(18)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Tips list
                    VStack(spacing: 10) {
                        ForEach(TipsCategoryContent.tips(for: category)) { tip in
                            NavigationLink {
                                TipDetailView(tip: tip, categoryColor: category.color)
                            } label: {
                                tipCard(tip)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
                .padding(.top, 4)
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tipCard(_ tip: GolfTip) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: tip.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(category.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.text)
                Text(tip.body)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - TipDetailView

struct TipDetailView: View {
    let tip: GolfTip
    let categoryColor: Color

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Icon card
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.15))
                            .frame(width: 90, height: 90)
                        Image(systemName: tip.icon)
                            .font(.system(size: 38))
                            .foregroundStyle(categoryColor)
                    }
                    .padding(.top, 24)

                    // Title
                    Text(tip.title)
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Body card
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.gold)
                            Text("Tipp")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSec)
                        }
                        .padding(.bottom, 10)

                        Text(tip.body)
                            .font(.body)
                            .foregroundStyle(AppTheme.text)
                            .lineSpacing(5)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle(tip.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
