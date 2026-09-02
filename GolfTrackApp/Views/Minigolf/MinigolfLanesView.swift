import SwiftUI

// MARK: - Regeln

/// Eine Regelgruppe für die Übersicht im Minigolf-Tab.
struct MinigolfRule: Identifiable, Hashable {
    let title: String
    let icon: String
    let points: [String]
    var id: String { title }
}

enum MinigolfRules {
    /// Zusammenfassung der offiziellen Bahnengolf-Regeln (DMV/WMF) in der Form,
    /// in der sie auf der Anlage wirklich gebraucht wird. Kein Regelwerk-Ersatz.
    static let all: [MinigolfRule] = [
        .init(title: "Ziel und Zählweise",
              icon: "flag.checkered",
              points: [
                "Der Ball wird vom Abschlag mit möglichst wenigen Schlägen ins Ziel gespielt.",
                "Pro Bahn hat man höchstens 6 Schläge. Liegt der Ball danach nicht im Ziel, wird 7 notiert.",
                "Auch für eine nicht gespielte Bahn werden 7 Schläge notiert.",
                "Gewonnen hat, wer über alle Bahnen zusammen die wenigsten Schläge braucht."
              ]),
        .init(title: "Ball verlässt die Bahn",
              icon: "arrow.uturn.left",
              points: [
                "Springt der Ball heraus, bevor er das Hindernis bzw. die Grenzlinie korrekt überwunden hat, wird der nächste Schlag wieder vom Abschlag gespielt – ohne Strafschlag.",
                "Ist die Grenzlinie schon überwunden, wird der Ball dort eingelegt, wo er die Bahn verlassen hat, und von da weitergespielt."
              ]),
        .init(title: "Ablegen",
              icon: "arrow.left.and.right",
              points: [
                "Liegt der Ball an der Bande oder an einem Hindernis, darf er bis zur Ablegemarkierung abgelegt werden – üblich sind 20 cm von der Bande.",
                "Einzelne Bahnen haben eigene Ablegeregeln, etwa Pyramiden, Stäbe oder Mittelhügel.",
                "Abgelegt wird ohne Strafschlag."
              ]),
        .init(title: "Vorgesehener Weg",
              icon: "arrow.triangle.turn.up.right.diamond",
              points: [
                "Manche Bahnen schreiben den Weg vor: Rohr, Fensterbahnen, Salto, liegende Schleife, Labyrinth, Rampe und Sprungschanze.",
                "Bei den übrigen Bahnen ist der Weg frei – links oder rechts am Hindernis vorbei ist beides erlaubt.",
                "Springt der Ball über ein Hindernis, das er durchlaufen müsste, gilt der Weg als verlassen."
              ]),
        .init(title: "Ball und Ausrüstung",
              icon: "circle.circle",
              points: [
                "Während einer Bahn darf der Ball nicht gewechselt werden.",
                "Gespielt wird mit dem Putter; der Ball wird geschlagen, nicht geschoben."
              ]),
        .init(title: "Auf der Anlage",
              icon: "figure.stand",
              points: [
                "Bahnen und Hindernisse dürfen nicht betreten werden. Auf die Banden darf man für einen Schlag treten.",
                "Bei Netz, Schüssel, Vulkan und Plateau darf man die Bahn betreten, um den Ball aus dem Ziel zu nehmen.",
                "Etwa zwei Meter Abstand zum Spieler halten, der gerade schlägt."
              ]),
        .init(title: "Die Anlage selbst",
              icon: "ruler",
              points: [
                "Eine genormte Miniaturgolfbahn ist \(MinigolfStandardLanes.laneLength) lang und \(MinigolfStandardLanes.laneWidth) breit, der Zielkreis hat \(MinigolfStandardLanes.targetCircleDiameter) Durchmesser.",
                "Eine zugelassene Anlage besteht aus 18 der 28 genormten Bahnen, in beliebiger Reihenfolge.",
                "Deshalb ist Bahn 7 vor Ort nicht dieselbe wie Bahn 7 in dieser Liste."
              ])
    ]
}

// MARK: - Tab-Inhalt

/// „Bahnen & Regeln" im Minigolf-Bereich: die 28 genormten Bahnen mit Skizze
/// und darüber die Regeln, die man auf der Anlage wirklich braucht.
struct MinigolfLanesTabContent: View {
    @State private var expandedRule: String?
    @State private var query = ""

    private var lanes: [MinigolfStandardLane] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return MinigolfStandardLanes.all }
        return MinigolfStandardLanes.all.filter {
            $0.name.lowercased().contains(q)
                || $0.hindernis.lowercased().contains(q)
                || String($0.normNumber) == q
        }
    }

    var body: some View {
        rulesCard
        lanesCard
    }

    // MARK: Regeln

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Regeln", systemImage: "book.fill")
                .font(.headline)

            Text("Die offiziellen Bahnengolf-Regeln, kurz gefasst.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(MinigolfRules.all) { rule in
                    ruleRow(rule)
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func ruleRow(_ rule: MinigolfRule) -> some View {
        let isOpen = expandedRule == rule.title
        return VStack(alignment: .leading, spacing: 8) {
            Button {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedRule = isOpen ? nil : rule.title
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: rule.icon)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.gold)
                        .frame(width: 20)
                    Text(rule.title)
                        .font(.subheadline.bold())
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isOpen ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(rule.points, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(AppTheme.gold.opacity(0.6))
                                .frame(width: 4, height: 4)
                                .padding(.top, 6)
                            Text(point)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.leading, 30)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Bahnen

    private var lanesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Die 28 genormten Bahnen", systemImage: "square.grid.2x2.fill")
                .font(.headline)

            Text("Jede zugelassene Miniaturgolfanlage besteht aus 18 davon. Tippe eine Bahn an für Weg, Maße und Tipp.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Bahn suchen", text: $query)
                    .font(.subheadline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button {
                        Haptics.tap()
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))

            if lanes.isEmpty {
                Text("Keine Bahn gefunden.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(lanes) { lane in
                        NavigationLink {
                            MinigolfLaneDetailView(lane: lane)
                        } label: {
                            laneRow(lane)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func laneRow(_ lane: MinigolfStandardLane) -> some View {
        HStack(spacing: 12) {
            MinigolfLaneSketch(shape: lane.shape, glyph: lane.glyph, lineWidth: 1.3)
                .frame(width: 100, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(lane.normNumber). \(lane.name)")
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(lane.hindernis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
    }
}

// MARK: - Detail einer Bahn

struct MinigolfLaneDetailView: View {
    let lane: MinigolfStandardLane

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Text("\(lane.normNumber)")
                            .font(.headline.bold())
                            .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                            .frame(width: 32, height: 32)
                            .background(AppTheme.gold, in: Circle())
                        Text(lane.name)
                            .font(.title3.bold())
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    MinigolfLaneSketch(shape: lane.shape, glyph: lane.glyph, lineWidth: 2)
                        .frame(height: 110)
                        .padding(.vertical, 6)

                    HStack(spacing: 14) {
                        legend(color: .white.opacity(0.8), text: "Abschlag")
                        legend(color: AppTheme.gold, text: "Hindernis")
                        // Bei der Sprungschanze ist das Netz selbst das Ziel und
                        // deshalb wie ein Hindernis gezeichnet – kein grüner Kreis.
                        if lane.shape != .jump {
                            legend(color: Color(red: 0.35, green: 0.80, blue: 0.50), text: "Ziel")
                        } else {
                            legend(color: AppTheme.gold, text: "Netz")
                        }
                    }
                }
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))

                section(icon: "cube", title: "Hindernis", text: lane.hindernis)
                section(icon: "arrow.triangle.turn.up.right.diamond",
                        title: "Vorgesehener Weg", text: lane.weg)
                section(icon: "ruler", title: "Maße & Besonderheiten", text: lane.mass)
                section(icon: "lightbulb.fill", title: "Tipp", text: lane.tipp, accent: true)

                Text("Nummer der Normbahn nach den Normungsbestimmungen für Miniaturgolf (DMV/WMF). Auf der Anlage kann sie an jeder Position stehen. Verbindlich sind die Zeichnungen des Weltverbands – die Skizze hier ist schematisch.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Bahn \(lane.normNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func legend(color: Color, text: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func section(icon: String, title: LocalizedStringKey, text: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(accent ? AppTheme.gold : AppTheme.text)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(accent ? AppTheme.gold.opacity(0.10) : AppTheme.card,
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            if accent {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.gold.opacity(0.3), lineWidth: 1)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 14) {
                MinigolfLanesTabContent()
            }
            .padding()
        }
        .appBackground()
    }
    .preferredColorScheme(.dark)
}
