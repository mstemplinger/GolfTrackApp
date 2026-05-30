import SwiftUI

// MARK: - Data Model

struct GuideLesson: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let tip: String?
    let stats: [GuideStat]

    init(title: String, body: String, tip: String? = nil, stats: [GuideStat] = []) {
        self.title = title
        self.body = body
        self.tip = tip
        self.stats = stats
    }
}

struct GuideStat: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let color: Color
}

struct GuideChapter: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let lessons: [GuideLesson]
}

// MARK: - Content

enum GolfGuideContent {
    static let chapters: [GuideChapter] = [

        GuideChapter(
            number: 1,
            title: "Abschlag",
            subtitle: "Driver vs. 3-Holz, Genauigkeit & Strategie",
            icon: "figure.golf",
            color: AppTheme.gold,
            lessons: [
                GuideLesson(
                    title: "Driver vs. 3-Holz",
                    body: "Ein weit verbreiteter Mythos ist, dass Golfer denken, sie schlagen weiter als sie es tatsächlich tun. Spieler verwechseln oft ihren längsten Schlag mit ihrem Durchschnitt.\n\nAuffällig ist, dass ein 3-Holz quer über alle Handicaps nur 1–2 % genauer ist als ein Driver – aber fast 30 Meter kürzer. Der Verzicht auf diese Distanz lohnt sich kaum.\n\nEmpfehlung: Schlag den Driver so oft wie möglich. Der minimale Genauigkeitsvorteil des 3-Holzes rechtfertigt den Distanzverlust von fast 30 Metern nicht.",
                    tip: "Verwende den Driver so oft wie möglich. Prüfe aber deine persönlichen Unterschiede zwischen Driver und 3-Holz.",
                    stats: [
                        GuideStat(label: "Genauigkeitsvorteil 3-Holz", value: "1–2 %", color: .orange),
                        GuideStat(label: "Distanzverlust mit 3-Holz", value: "~27 m", color: .red)
                    ]
                ),
                GuideLesson(
                    title: "Was 27 Meter mehr bringen",
                    body: "Wenn ein 14er-Handicapper statt des Durchschnittsdrivers seinen besten Drive schlägt, liegt er durchschnittlich 22 Meter näher an der Fahne.\n\nDiese 22 Meter näher erhöhen die Anzahl getroffener Grüns (GIR %) deutlich und verringern die durchschnittliche Nähe zur Fahne. Eine solche Verbesserung wirkt sich massiv auf das Scoring aus.\n\nDieselbe Logik gilt auch für den Vergleich Driver vs. 3-Holz: Mit dem Driver liegst du kürzer zum Grün, was einen genaueren Approach ermöglicht.",
                    tip: "Schlag den Driver so oft wie möglich – eine kürzere zweite Bahn bedeutet fast immer eine bessere Annäherung ans Grün.",
                    stats: [
                        GuideStat(label: "Mehr Nähe durch längeren Drive", value: "22 m", color: AppTheme.gold)
                    ]
                ),
                GuideLesson(
                    title: "Die Kosten von Ungenauigkeit",
                    body: "Shot-Scope-Daten zeigen genau, wie viele Schläge es kostet, in Bäume, Rough oder Bunker zu schlagen.\n\nDer schlimmste Ort für einen Amateurschlag ist der Fairway-Bunker – er kostet im Schnitt 1,4 Schläge pro Runde. Leichtes Rough oder Semi-Rough hingegen kostet kaum mehr als ein kürzerer Schlag vom Abschlag.\n\nDas bedeutet: Wer den Driver nimmt und leicht ins Semi-Rough trifft, steht nicht schlechter als jemand, der ein 3-Holz sauber auf das Fairway trifft.",
                    stats: [
                        GuideStat(label: "Kostet Fairway-Bunker", value: "1,4 Schläge/Runde", color: .red),
                        GuideStat(label: "Kostet Semi-Rough", value: "~0 extra", color: AppTheme.gold)
                    ]
                ),
                GuideLesson(
                    title: "Links, rechts oder beidseitig?",
                    body: "Einer der wichtigsten Erkenntnisse: Golfer überschätzen den Wert des Fairways.\n\nAuf einem Loch mit Wasser oder Bunker rechts lohnt es sich, auf das leichte Rough links zu zielen – das ergibt statistisch einen niedrigeren Score als auf die Mitte zu zielen.\n\n**Rechtsmisser:** Wer 25 Meter weiter links zielt (ins spielbare Rough), reduziert verlorene Schläge von 7 auf 2 aus 10 Drives.\n\n**Linksmisser:** Ziel 15 Meter nach rechts verschieben – Schlagverlust von 3,4 auf 0,9 senken.\n\n**Beidseitiger Misser:** Zielpunkt zwischen den Hindernissen wählen – spart 1,4 Schläge.",
                    tip: "Überschätze das Fairway nicht – leichtes Rough bietet oft genauso gute Bedingungen für den nächsten Schlag.",
                    stats: [
                        GuideStat(label: "Ersparnis durch Zielpunktanpassung (Rechtsmisser)", value: "5 Schläge/10 Abschläge", color: AppTheme.gold)
                    ]
                )
            ]
        ),

        GuideChapter(
            number: 2,
            title: "Anspiel",
            subtitle: "Schlägerwahl, Genauigkeit & Distanzkontrolle",
            icon: "target",
            color: AppTheme.gold,
            lessons: [
                GuideLesson(
                    title: "135-Meter-Schlag vom Fairway",
                    body: "Viele Golfer treffen Schlägerauswahl auf Basis ihrer gefühlten Distanz – nicht ihrer echten Durchschnittsdistanz. Das führt zu systematisch zu kurzen Annäherungen.\n\nEmpfehlung: Wähle immer einen längeren Schläger als du denkst, und orientiere dich an der GPS-Distanz zur Hinterkante des Grüns statt zur Mitte.\n\nShot-Scope-Daten zeigen: 72 % der Gefahrenzone liegt vor dem Grün (Bunker, Wasser). Nur 28 % liegt hinter dem Grün. Einen Schlag zu lang zu schlagen ist also deutlich besser als zu kurz.",
                    tip: "Orientiere dich beim Schläger wählen an der Distanz zur Hinterkante des Grüns – nicht zur Mitte.",
                    stats: [
                        GuideStat(label: "Gefahr vor dem Grün", value: "72 %", color: .red),
                        GuideStat(label: "Gefahr hinter dem Grün", value: "28 %", color: .orange)
                    ]
                ),
                GuideLesson(
                    title: "Innerhalb von 90 Metern",
                    body: "Innerhalb von 90 Metern werden Scores gemacht oder vernichtet. Wer diese Schläge gut spielt, verbessert sein Handicap deutlich.\n\nEin Schlag vom Fairway gibt bis zu 25 % mehr Chance, das Grün zu treffen – verglichen mit demselben Schlag aus dem Rough oder Bunker.\n\nTypischer Fehler bei 14ern: Die meisten Schläge missen kurz-rechts. Wer seinen Zielpunkt anpasst, kann die Anzahl getroffener Grüns mehr als verdoppeln und die durchschnittliche Nähe zur Fahne um 33 % verbessern.",
                    tip: "Justiere deinen Zielpunkt bei Wedge-Schlägen – bereits eine kleine Anpassung kann die Grüntreffquote mehr als verdoppeln.",
                    stats: [
                        GuideStat(label: "Mehr Grüntreffer vom Fairway", value: "+25 %", color: AppTheme.gold),
                        GuideStat(label: "Weniger Nähe durch Zielpunktanpassung", value: "-33 %", color: AppTheme.gold)
                    ]
                ),
                GuideLesson(
                    title: "Hybrid vs. Eisen",
                    body: "Über 180 Meter ist ein Hybrid fast doppelt so effektiv wie ein langes Eisen. Zwischen 165–180 Metern ist der Hybrid immer noch überlegen, aber der Abstand verringert sich.\n\nDie meisten Amateure sollten kein Eisen tragen, mit dem sie über 165 Meter schlagen – stattdessen einen Hybrid einsetzen.\n\nWer aus dem Bereich 145–200 Meter konsistentere Treffer erzielt, kann mehr als einen Schlag pro Runde sparen.",
                    tip: "Tausche Eisen, die du über 165 Meter schlagst, gegen Hybrids – du wirst konsistenter und triffst mehr Grüns.",
                    stats: [
                        GuideStat(label: "Hybrid-Effektivität >180 m", value: "2× besser", color: AppTheme.gold),
                        GuideStat(label: "Score bei getroffem Grün", value: "2,2 Schläge bis Loch", color: AppTheme.gold),
                        GuideStat(label: "Score bei verfehlem Grün", value: "3,5 Schläge bis Loch", color: .red)
                    ]
                )
            ]
        ),

        GuideChapter(
            number: 3,
            title: "Kurzspiel",
            subtitle: "Schlägerwahl, Lob-Wedge & Bunker",
            icon: "figure.golf.circle",
            color: .orange,
            lessons: [
                GuideLesson(
                    title: "Schlägerwahl im Kurzspiel",
                    body: "Kurzspiel erfordert viel Vorstellungskraft. Nicht jeder Schlag kann mit demselben Sand-Wedge gespielt werden.\n\nPGA-Tour-Profis kommen aus der Nähe des Grüns in 90 % der Fälle auf und ein – nicht weil sie besser putten, sondern weil sie den richtigen Schläger wählen.\n\nSchlechte Kurzspieler greifen 42 % der Zeit zum Lob-Wedge. Bessere Spieler nutzen ihn nur 8 % der Zeit – stattdessen verteilen sie ihre Schläge gleichmäßig auf 8-Eisen, 9-Eisen und PW.\n\nDas Ziel: den Ball so schnell wie möglich ins Rollen bringen.",
                    tip: "Wähle den Schläger, der den Ball am schnellsten zum Rollen auf dem Grün bringt – das ist fast immer ein niedriger loftiger Schläger.",
                    stats: [
                        GuideStat(label: "Lob-Wedge-Nutzung schlechter Kurzspieler", value: "42 %", color: .red),
                        GuideStat(label: "Lob-Wedge-Nutzung guter Kurzspieler", value: "8 %", color: AppTheme.gold)
                    ]
                ),
                GuideLesson(
                    title: "Die Lob-Wedge-Sucht",
                    body: "8–20 Handicapper greifen innerhalb von 20 Metern vom Grün in 38 % der Fälle zum Lob-Wedge – obwohl dieser Schläger nur für 8 % der erfolgreichen \"Up & Downs\" verantwortlich ist.\n\nWarum? Viele Golfer sehen Tour-Profis wie Phil Mickelson spektakuläre Lob-Wedge-Schläge spielen und denken: \"Das kann ich auch!\"\n\nDie harte Realität: Der Lob-Wedge erfordert einen präzisen Treff und eine exakte Technik. Ein leichter Fehler kostet mehrere Schläge.\n\nLösung: Beim nächsten Kurzspielschlag einen Schläger weniger nehmen als geplant.",
                    tip: "Nimmst du normalerweise das Sand-Wedge? Probiere das Pitching-Wedge. Nimmst du das PW? Nimm die 9. Dein Score wird es dir danken.",
                    stats: [
                        GuideStat(label: "Lob-Wedge Up&Down Erfolg (8–20 HCP)", value: "~8 %", color: .red),
                        GuideStat(label: "Lob-Wedge-Nutzung (8–20 HCP)", value: "38 %", color: .orange)
                    ]
                ),
                GuideLesson(
                    title: "Bunker-Spiel",
                    body: "Im Schnitt hast du 1–2 Grünside-Bunker-Schläge pro Runde. Schlechte Bunker-Technik kann den Score schnell in die Höhe treiben.\n\nFür höhere Handicapper: Das Ziel sollte immer sein, den Ball einfach aus dem Bunker und auf das Grün zu bringen. Ziele auf die Mitte des Grüns – das gibt die größte Fehlertoleranz.\n\nWichtig: Setze unterschiedliche Schläger rund ums Grün ein – du spielst fast nie denselben Schlag zweimal. Bring den Ball so früh wie möglich zum Rollen.",
                    tip: "Bunker-Spiel ist ein Bereich, den Amateure kaum üben. Nutze das nächste Mal am Platz die Bunker-Übungsanlage und baue Vertrauen auf.",
                    stats: [
                        GuideStat(label: "Ø Bunker-Schläge pro Runde", value: "1–2", color: .orange)
                    ]
                )
            ]
        ),

        GuideChapter(
            number: 4,
            title: "Putten",
            subtitle: "Drei-Putt vermeiden, Distanzkontrolle & Linie",
            icon: "circle.fill",
            color: .purple,
            lessons: [
                GuideLesson(
                    title: "Drei-Putt-Wahrscheinlichkeit",
                    body: "Schnellste Möglichkeit, den Score zu senken: Drei-Putts vermeiden.\n\n20er-Handicapper dreiputtens bei 19 % aller Löcher – das ist jedes 5. Loch. Selbst 8er-Handicapper dreiputtens noch auf jedem 10. Loch.\n\nDer Hauptgrund: schlechte Distanzkontrolle auf langen Putts. Ein 20er hinterlässt beim Drei-Putt einen zweiten Putt von durchschnittlich 2,7 Metern – und Jordan Spieth macht einen 2,7-Meter-Putt nur in 24 % der Fälle.",
                    tip: "Konzentriere dich vor dem Spiel darauf, lange Putts zu üben und ein Gefühl für Distanzkontrolle zu entwickeln.",
                    stats: [
                        GuideStat(label: "Drei-Putt-Rate (20 HCP)", value: "19 %", color: .red),
                        GuideStat(label: "Drei-Putt-Rate (8 HCP)", value: "~10 %", color: .orange),
                        GuideStat(label: "Ø 2. Putt bei Drei-Putt (20 HCP)", value: "2,7 m", color: .red)
                    ]
                ),
                GuideLesson(
                    title: "Putten: Kurz oder lang vorbei?",
                    body: "84 % aller Putts außerhalb von 1,5 Metern, die verfehlt werden, bleiben kurz. Das ist eine erschreckende Statistik – und du wirst es beim nächsten Runde bemerken.\n\nEinfach darauf achten, den Ball am Loch vorbeizubringen, verbessert die Einlochquote deutlich – und du kennst die Linie für den Rückputt besser.\n\nAb 1,5 Metern und darunter dreht sich das Bild: 86 % der verfehlten kurzen Putts gehen lang vorbei. Der typische Fehler: zu stark schlagen und einen gleich langen Rückputt hinterlassen.",
                    tip: "Sei mutig beim Putten – wer den Ball am Loch vorbeischlägt, gibt ihm zumindest eine Chance einzufallen. Und du kennst die Linie für den Rückputt.",
                    stats: [
                        GuideStat(label: "Lange Putts (>1,5 m): Fehlschläge kurz", value: "84 %", color: .red),
                        GuideStat(label: "Kurze Putts (<1,5 m): Fehlschläge lang", value: "86 %", color: .orange)
                    ]
                ),
                GuideLesson(
                    title: "Lag-Putten & Strategie",
                    body: "Die durchschnittliche erste Putt-Distanz für Handicap-Golfer ist 5,6 Meter vom Loch. Diese erste Putt-Distanz entscheidet, ob du einen Tipp-In oder einen schwierigen zweiten Putt bekommst.\n\nEffektiv entstehen die meisten Drei-Putts aus über 6 Metern. Ab ca. 6 Metern sollte das Ziel sein: \"Lag\" – also den Ball so nah wie möglich ans Loch heran zu bringen, um einen möglichst kurzen zweiten Putt zu hinterlassen.\n\nLag bedeutet nicht zu kurz lassen – sondern den zweiten Putt als Tipp-In zu planen.",
                    tip: "Denke ab 6 Metern in \"Lag\"-Modus: Ziel ist ein kurzer zweiter Putt, nicht unbedingt der erste ins Loch.",
                    stats: [
                        GuideStat(label: "Ø erste Putt-Distanz (Handicap-Golfer)", value: "5,6 m", color: .purple),
                        GuideStat(label: "Meiste Drei-Putts ab", value: ">6 m", color: .red)
                    ]
                ),
                GuideLesson(
                    title: "Das richtige Putter-Modell finden",
                    body: "Golfer wählen Putter oft nach Optik – aber Leistung ist entscheidend. Was für Jordan Spieth funktioniert, muss nicht für dich funktionieren.\n\nEmpfehlung: Tracke deine Performance mit verschiedenen Puttern über mehrere Runden. Ein klares Muster wird sich zeigen, welcher Putter für dich funktioniert.\n\nVertrauen in den Putter ist der Schlüssel. Nur ein Schläger, dem du vertraust, lässt dich in entscheidenden Momenten ruhig bleiben.",
                    tip: "Tracke deine Putt-Performance mit verschiedenen Puttern und wähle den, der dir die besten Ergebnisse liefert – nicht den, den dein Lieblingsprofi nutzt.",
                    stats: []
                )
            ]
        )
    ]
}

// MARK: - Main View

struct GolfGuideView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Basierend auf Daten von über 100.000 Golfrunden analysiert Shot Scope die häufigsten Fehler von Handicap-Golfern.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSec)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(AppTheme.card)
                    }

                    Section {
                        NavigationLink {
                            PlatzreifeQuizView()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppTheme.gold.opacity(0.13))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "graduationcap.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppTheme.gold)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Platzreife Quiz")
                                        .font(.headline)
                                    Text("Smart-Modus, Probeprüfung & Ergebnisse")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSec)
                                        .lineLimit(1)
                                    Text("\(PlatzreifeQuestions.all.count) offizielle Prüfungsfragen")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.gold)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.card)
                    }

                    ForEach(GolfGuideContent.chapters) { chapter in
                        Section {
                            NavigationLink {
                                ChapterDetailView(chapter: chapter)
                            } label: {
                                ChapterRow(chapter: chapter)
                            }
                            .listRowBackground(AppTheme.card)
                        }
                    }

                    Section {
                        Text("Strategie-Insights: Shot Scope Ltd.  ·  Regeln: R&A / USGA 2023")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTer)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(AppTheme.card)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .navigationTitle("Golf-Ratgeber")
            }
        }
    }
}

// MARK: - Chapter Row

private struct ChapterRow: View {
    let chapter: GuideChapter

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(chapter.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: chapter.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(chapter.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Kapitel \(chapter.number)")
                        .font(.caption)
                        .foregroundStyle(chapter.color)
                        .fontWeight(.semibold)
                }
                Text(chapter.title)
                    .font(.headline)
                Text(chapter.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chapter Detail

struct ChapterDetailView: View {
    let chapter: GuideChapter

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            List {
                ForEach(Array(chapter.lessons.enumerated()), id: \.element.id) { index, lesson in
                    Section {
                        NavigationLink {
                            LessonDetailView(lesson: lesson, chapterColor: chapter.color)
                        } label: {
                            LessonRow(lesson: lesson, index: index + 1, color: chapter.color)
                        }
                        .listRowBackground(AppTheme.card)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle(chapter.title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Lesson Row

private struct LessonRow: View {
    let lesson: GuideLesson
    let index: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title)
                    .font(.subheadline.bold())
                if !lesson.stats.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSec)
                        Text("\(lesson.stats.count) Statistiken")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSec)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Lesson Detail

struct LessonDetailView: View {
    let lesson: GuideLesson
    let chapterColor: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Body text
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(lesson.body.components(separatedBy: "\n\n"), id: \.self) { paragraph in
                        if paragraph.hasPrefix("**") {
                            let clean = paragraph.replacingOccurrences(of: "**", with: "")
                            Text(clean)
                                .font(.subheadline.bold())
                                .padding(.bottom, 6)
                        } else {
                            Text(paragraph)
                                .font(.body)
                                .foregroundStyle(AppTheme.text)
                                .padding(.bottom, 12)
                        }
                    }
                }
                .padding()
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 14))

                // Stats
                if !lesson.stats.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Zahlen & Fakten", systemImage: "chart.bar.fill")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)

                        ForEach(lesson.stats) { stat in
                            HStack {
                                Text(stat.label)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSec)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                Text(stat.value)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(stat.color)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            if stat.id != lesson.stats.last?.id {
                                Divider().padding(.horizontal)
                            }
                        }
                        Spacer(minLength: 10)
                    }
                    .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 14))
                }

                // Top Tip
                if let tip = lesson.tip {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppTheme.gold)
                            .font(.title3)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Top-Tipp")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSec)
                            Text(tip)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.bg)
    }
}
