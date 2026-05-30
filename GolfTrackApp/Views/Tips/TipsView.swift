import SwiftUI

struct TipsView: View {
    private let categories: [TipsCategory] = [
        TipsCategory(name: "Anfänger",    icon: "star",                color: Color(red: 0.3, green: 0.85, blue: 0.5)),
        TipsCategory(name: "Technik",     icon: "figure.golf",         color: AppTheme.gold),
        TipsCategory(name: "Mental Game", icon: "brain.head.profile",  color: Color(red: 0.6, green: 0.5, blue: 1.0)),
        TipsCategory(name: "Strategie",   icon: "map",                 color: Color(red: 1.0, green: 0.6, blue: 0.3)),
    ]

    @State private var showDailyTipDetail = false

    private var dailyTip: DailyTip {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % DailyTip.all.count
        return DailyTip.all[index]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("Tipps & Coaching")
                                .font(.title2.bold())
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // Daily tip
                        Button { showDailyTipDetail = true } label: { dailyTipCard }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showDailyTipDetail) {
                                DailyTipDetailView(tip: dailyTip)
                            }

                        // Ratgeber Link
                        NavigationLink {
                            GolfGuideView()
                        } label: {
                            tipLinkRow(
                                icon: "graduationcap.fill",
                                title: "Golf-Ratgeber",
                                subtitle: "Platzreife Quiz & Shot-Scope-Strategie"
                            )
                        }
                        .padding(.horizontal)

                        // Statistiken Link
                        NavigationLink {
                            StatisticsView()
                        } label: {
                            tipLinkRow(
                                icon: "chart.bar.fill",
                                title: "Meine Statistiken",
                                subtitle: "Fairways, Greens, Putts & Score-Verlauf"
                            )
                        }
                        .padding(.horizontal)

                        // Kategorie header
                        HStack {
                            Text("Kategorien")
                                .font(.headline)
                                .foregroundStyle(AppTheme.text)
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Categories grid
                        VStack(spacing: 0) {
                            ForEach(Array(categories.enumerated()), id: \.element.name) { i, cat in
                                NavigationLink {
                                    TipsCategoryDetailView(category: cat)
                                } label: {
                                    categoryRow(cat)
                                }
                                .buttonStyle(.plain)
                                if i < categories.count - 1 {
                                    Divider()
                                        .background(AppTheme.cardAlt)
                                        .padding(.leading, 66)
                                }
                            }
                        }
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 4)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var dailyTipCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardAlt)
                    .frame(width: 52, height: 52)
                Image(systemName: dailyTip.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.gold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Pro Tipp des Tages")
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                Text("\(dailyTip.title) – \(dailyTip.body)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func tipLinkRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardAlt)
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.gold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(18)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private func categoryRow(_ cat: TipsCategory) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(cat.color.opacity(0.18)).frame(width: 40, height: 40)
                Image(systemName: cat.icon)
                    .font(.system(size: 17))
                    .foregroundStyle(cat.color)
            }
            Text(cat.name)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.text)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

struct TipsCategory {
    let name: String
    let icon: String
    let color: Color
}

struct DailyTip {
    let title: String
    let body: String
    let icon: String

    static let all: [DailyTip] = [
        DailyTip(title: "Ruhiger Griff", body: "Ein entspannter Griff sorgt für mehr Kontrolle und Konstanz.", icon: "hands.clap.fill"),
        DailyTip(title: "Vorschwung", body: "Nimm dir Zeit für den Vorschung – ein ruhiger Start verhindert Fehler im Abschwung.", icon: "arrow.up.circle.fill"),
        DailyTip(title: "Auge auf den Ball", body: "Halte den Kopf ruhig und den Blick auf den Ball bis nach dem Kontakt.", icon: "eye.fill"),
        DailyTip(title: "Standfestigkeit", body: "Schulterbreiter Stand gibt dir die beste Balance für kraftvolle Schläge.", icon: "figure.stand"),
        DailyTip(title: "Putting-Linie lesen", body: "Lies das Grün immer von hinter dem Ball und zusätzlich von der Seite.", icon: "scope"),
        DailyTip(title: "Windeinfluss", body: "Bei Gegenwind: weniger Schwung, mehr Schläger. Nicht gegen den Wind kämpfen.", icon: "wind"),
        DailyTip(title: "Kurzes Spiel", body: "70 % aller Schläge fallen innerhalb von 100 Metern. Übe Chip und Pitch täglich.", icon: "figure.golf"),
        DailyTip(title: "Platz-Management", body: "Spiele auf die sichere Seite, nicht auf die Fahne. Bogey ist besser als Doppelbogey.", icon: "map.fill"),
        DailyTip(title: "Pre-Shot-Routine", body: "Eine feste Routine vor jedem Schlag beruhigt die Nerven und verbessert die Konsistenz.", icon: "repeat.circle.fill"),
        DailyTip(title: "Mentale Stärke", body: "Vergiss den letzten schlechten Schlag sofort. Jeder Schlag ist ein Neuanfang.", icon: "brain.head.profile"),
        DailyTip(title: "Tempo beim Putten", body: "Das richtige Tempo ist wichtiger als die perfekte Linie. Übe Längenputts.", icon: "flag.fill"),
        DailyTip(title: "Abschwung", body: "Starte den Abschwung mit den Hüften, nicht mit den Armen – das gibt mehr Power.", icon: "arrow.down.circle.fill"),
        DailyTip(title: "Bunker-Strategie", body: "Im Bunker: offenes Clubface, offene Standfläche, schlage hinter den Ball – nicht auf ihn.", icon: "circle.dotted"),
        DailyTip(title: "Chip vs. Pitch", body: "Chip wenn möglich, pitch wenn nötig. Der Chip ist einfacher zu kontrollieren.", icon: "arrow.up.right.circle.fill"),
        DailyTip(title: "Körperdrehung", body: "Eine volle Schulter-Drehung im Rückschwung ist wichtiger als Armgeschwindigkeit.", icon: "arrow.clockwise.circle.fill"),
        DailyTip(title: "Spielplanung", body: "Plane jeden Loch rückwärts – von der Fahne zum Abschlag. Wo willst du einlochen?", icon: "map"),
        DailyTip(title: "Kurzspiel-Griff", body: "Halte den Putter und das Wedge fester als den Driver – mehr Kontrolle, weniger Fehlschläge.", icon: "hand.raised.fill"),
        DailyTip(title: "Augen über dem Ball", body: "Beim Putten sollten deine Augen direkt über dem Ball sein für die beste Linie.", icon: "eye.circle.fill"),
        DailyTip(title: "Atemtechnik", body: "Atme vor dem Schlag tief aus. Das entspannt die Muskeln und stabilisiert den Schwung.", icon: "lungs.fill"),
        DailyTip(title: "Downhill-Putts", body: "Bei Abwärtsputts: ziele einen Meter kürzer und schlage sanfter – das Grün macht den Rest.", icon: "arrow.down.right.circle.fill"),
        DailyTip(title: "Schläger-Auswahl", body: "Wähle immer einen Schläger mehr als du denkst. Die meisten Amateure spielen zu kurz.", icon: "slider.horizontal.3"),
        DailyTip(title: "Fairway-Bunker", body: "Im Fairway-Bunker: steile, saubere Bewegung. Treffe den Ball sauber, nicht den Sand zuerst.", icon: "arrow.up.and.down.circle.fill"),
        DailyTip(title: "Wasserhindernisse", body: "Zögere nicht zu lang bei Wasserhindernissen – spiele auf die sichere Seite.", icon: "drop.fill"),
        DailyTip(title: "Aufwärmen", body: "Beginne das Warm-up mit kurzen Schlägern und arbeite dich zum Driver vor.", icon: "flame.fill"),
        DailyTip(title: "Schlagfolge", body: "Übe die Reihenfolge: kurze Eisen → mittlere Eisen → Holz → Driver.", icon: "list.number"),
        DailyTip(title: "Regen & Nässe", body: "Bei Regen: trockene Handschuhe bereitstellen, langsamer schwingen, Ball tiefer tee-en.", icon: "cloud.rain.fill"),
        DailyTip(title: "Temposteuerung", body: "Ein gleichmäßiges Tempo – nicht Kraft – macht den guten Golfer aus.", icon: "speedometer"),
        DailyTip(title: "Rücken gerade", body: "Behalte die Wirbelsäulenneigung konstant durch den gesamten Schwung.", icon: "figure.walk"),
        DailyTip(title: "Spieltempo", body: "Spiele zügig. Schnelles Spiel entspannt und verbessert oft den Score.", icon: "timer"),
        DailyTip(title: "Driving Range", body: "Übe auf der Range mit Ziel, nicht nur zum Schlagen. Stelle dir immer ein Ziel vor.", icon: "target"),
        DailyTip(title: "3-Putt vermeiden", body: "Lage dich bei langen Putts auf 1 Meter ans Loch – vermisse nie die zweite Putt-Chance.", icon: "minus.circle.fill"),
        DailyTip(title: "Griff-Stärke", body: "Halte den Schläger wie ein rohes Ei – weder zu fest noch zu locker.", icon: "hand.thumbsup.fill"),
        DailyTip(title: "Ball-Position", body: "Driver: Ball an der linken Ferse. Kurze Eisen: Ballmitte des Stands.", icon: "arrow.left.and.right.circle.fill"),
        DailyTip(title: "Punch Shot", body: "Bei starkem Wind: kürzerer Rückschwung, Hands-ahead, weniger Loft.", icon: "bolt.circle.fill"),
        DailyTip(title: "Handicap verbessern", body: "Spiele öfter auf schwierigen Plätzen – das entwickelt dein Spiel schneller.", icon: "chart.line.uptrend.xyaxis"),
        DailyTip(title: "Mentale Vorbereitung", body: "Stelle dir jeden Schlag zuerst positiv vor, bevor du ihn ausführst.", icon: "lightbulb.fill"),
        DailyTip(title: "Tee-Höhe", body: "Driver: Ball sollte halb über der Clubkrone stehen. Eisen: nur leicht über dem Boden.", icon: "arrow.up.and.line.horizontal.and.arrow.down"),
        DailyTip(title: "Follow-Through", body: "Ein vollständiger Follow-Through zeigt, dass du korrekt durch den Ball gespielt hast.", icon: "checkmark.circle.fill"),
        DailyTip(title: "Platzregelkenntnisse", body: "Kenne die Grundregeln: kostenlose Erleichterung, Spielreihenfolge, markieren.", icon: "book.fill"),
        DailyTip(title: "Grünlesen", body: "Achte auf das Mährichtungsmuster des Grüns – es beeinflusst die Rollrichtung.", icon: "arrow.left.and.right"),
        DailyTip(title: "Schläger reinigen", body: "Saubere Schläger-Grooves geben mehr Spin und Kontrolle – besonders im Kurzspiel.", icon: "sparkles"),
        DailyTip(title: "Druck annehmen", body: "Übe unter Druck: Setze dir beim Üben kleine Wetten oder Regeln.", icon: "trophy.fill"),
        DailyTip(title: "Körpergewicht", body: "Im Rückschwung: Gewicht auf rechtes Bein. Im Durchschwung: Gewicht auf linkes Bein.", icon: "scalemass.fill"),
        DailyTip(title: "Distanzkontrolle", body: "Miss deine Schlagweiten mit GPS und passe sie ans Wetter und die Höhe an.", icon: "ruler.fill"),
        DailyTip(title: "Fehler analysieren", body: "Slice? Prüfe den offenen Clubface. Hook? Prüfe den zu starken Griff.", icon: "magnifyingglass.circle.fill"),
        DailyTip(title: "Chip-Technik", body: "Beim Chip: Hände führen den Schläger, kein Handgelenk-Break, Gewicht vorne.", icon: "arrow.right.circle.fill"),
        DailyTip(title: "Lob-Wedge", body: "Benutze das Lob-Wedge nur wenn nötig – es ist der schwierigste Schläger im Bag.", icon: "exclamationmark.triangle.fill"),
        DailyTip(title: "Gelassenheit", body: "Golf ist ein Marathon, kein Sprint. Ein schlechtes Loch ruiniert nicht die ganze Runde.", icon: "tortoise.fill"),
        DailyTip(title: "Griff-Typ", body: "Probiere Overlap- und Interlock-Griff aus – finde den, der sich natürlicher anfühlt.", icon: "hand.raised.fingers.spread.fill"),
        DailyTip(title: "Ziel-Ausrichten", body: "Richte Clubface zuerst auf das Ziel aus, dann stelle deinen Körper parallel dazu.", icon: "scope"),
    ]
}

// MARK: - Detail-Sheet für den Tipp des Tages

struct DailyTipDetailView: View {
    let tip: DailyTip
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag-Indicator-Bereich + Schließen-Button
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(AppTheme.textTer)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {

                        // Icon
                        ZStack {
                            Circle()
                                .fill(AppTheme.gold.opacity(0.15))
                                .frame(width: 88, height: 88)
                            Image(systemName: tip.icon)
                                .font(.system(size: 38))
                                .foregroundStyle(AppTheme.gold)
                        }
                        .padding(.top, 12)

                        // Badge
                        Text("PRO TIPP DES TAGES")
                            .font(.caption.bold())
                            .kerning(1.2)
                            .foregroundStyle(AppTheme.gold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(AppTheme.gold.opacity(0.12), in: Capsule())

                        // Titel
                        Text(tip.title)
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.text)
                            .multilineTextAlignment(.center)

                        // Volltext
                        Text(tip.body)
                            .font(.body)
                            .foregroundStyle(AppTheme.textSec)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .padding(.horizontal, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}
