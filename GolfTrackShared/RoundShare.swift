import SwiftUI
import UIKit

/// Runde teilen: Text, Ergebniskarte und Knopf – für Golf und Minigolf, in der
/// App wie im Clip.
///
/// Geteilt wird ein freundlicher Text mit den wichtigsten Zahlen, ein Link zum
/// Laden der App und ein Bild der Runde. Das Bild lässt sich über das
/// Share-Sheet auch in Fotos sichern. Der Link führt auf `golftrack.app/laden`,
/// die Weiche zwischen App Store und Android-APK – Freunde sitzen nicht alle
/// am iPhone.

// MARK: - Inhalt

/// Eine Runde, so wie sie geteilt wird – reine Werte, ohne SwiftData, damit
/// App und Clip denselben Text und dieselbe Karte erzeugen.
struct RoundShareSummary {

    enum Kind { case golf, minigolf }

    struct Player {
        let name: String
        let total: Int
        /// 0 = vorn. Gleich viele Schläge teilen sich den Platz.
        let place: Int
    }

    var kind: Kind
    var courseName: String?
    /// `nil`, wenn das Datum nicht bekannt ist – dann fehlt es im Text.
    var date: Date?
    var holesPlayed: Int
    var holesTotal: Int
    var totalStrokes: Int
    var scoreToPar: Int?
    /// Schläge je Loch bzw. Bahn bei einer Einzelrunde, 0 = nicht gespielt.
    var holeStrokes: [Int] = []
    /// Rangliste, nur bei Minigolf mit mehreren Spielern.
    var ranking: [Player] = []

    var isGroup: Bool { ranking.count > 1 }
}

extension RoundShareSummary {

    /// Golf aus der schlanken Zählkarte. `pars` leer, wenn der Platz keine
    /// Par-Werte hat – dann bleibt der Stand gegen Par weg.
    static func golf(courseName: String?, date: Date?, strokes: [Int], pars: [Int]) -> RoundShareSummary {
        let hasPar = pars.count == strokes.count
        var toPar: Int?
        if hasPar {
            toPar = zip(strokes, pars).filter { $0.0 > 0 }.reduce(0) { $0 + $1.0 - $1.1 }
        }
        return RoundShareSummary(
            kind: .golf,
            courseName: courseName,
            date: date,
            holesPlayed: strokes.filter { $0 > 0 }.count,
            holesTotal: strokes.count,
            totalStrokes: strokes.reduce(0, +),
            scoreToPar: strokes.contains { $0 > 0 } ? toPar : nil,
            holeStrokes: strokes
        )
    }

    /// Minigolf, eine Zeile in `scores` je Spieler. Bei einem Spieler zählt
    /// dessen Runde, bei mehreren die Rangliste.
    static func minigolf(playerNames: [String], scores: [[Int]], numberOfHoles: Int,
                         courseName: String?, date: Date?) -> RoundShareSummary {
        let totals = scores.map { $0.reduce(0, +) }
        let ranking = playerNames.indices
            .map { i in
                Player(name: playerNames[i],
                       total: totals.indices.contains(i) ? totals[i] : 0,
                       place: totals.filter { $0 < (totals.indices.contains(i) ? totals[i] : 0) }.count)
            }
            .sorted { $0.total < $1.total }
        let played = scores.map { $0.filter { $0 > 0 }.count }.max() ?? 0
        return RoundShareSummary(
            kind: .minigolf,
            courseName: courseName,
            date: date,
            holesPlayed: played,
            holesTotal: numberOfHoles,
            totalStrokes: totals.first ?? 0,
            scoreToPar: nil,
            holeStrokes: playerNames.count == 1 ? (scores.first ?? []) : [],
            ranking: playerNames.count > 1 ? ranking : []
        )
    }
}

// MARK: - Text

enum RoundShareText {

    /// Weiche zwischen App Store und Android-APK auf der eigenen Seite.
    static let downloadURL = URL(string: "https://golftrack.app/laden")!

    static func message(for summary: RoundShareSummary) -> String {
        var lines = [intro(for: summary)]

        let details = detailParts(for: summary)
        if !details.isEmpty {
            lines.append(details.joined(separator: " · "))
        }

        if summary.isGroup {
            lines.append("")
            lines += summary.ranking.map { player in
                "\(medal(for: player.place)) \(player.name) – \(String(localized: "\(player.total) Schläge"))"
            }
        }

        lines.append("")
        lines.append(String(localized: "Gezählt mit GolfTrack. Hol dir die App auch: \(downloadURL.absoluteString)"))
        return lines.joined(separator: "\n")
    }

    private static func intro(for summary: RoundShareSummary) -> String {
        if summary.isGroup {
            if let course = summary.courseName {
                return String(localized: "Schau mal, wie unsere Minigolf-Runde auf \(course) gelaufen ist:")
            }
            return String(localized: "Schau mal, wie unsere Minigolf-Runde gelaufen ist:")
        }
        let strokes = String(localized: "\(summary.totalStrokes) Schläge")
        if let course = summary.courseName {
            return String(localized: "Schau mal, ich habe gerade auf \(course) \(strokes) gebraucht!")
        }
        return String(localized: "Schau mal, ich habe gerade \(strokes) gebraucht!")
    }

    static func detailParts(for summary: RoundShareSummary) -> [String] {
        var parts: [String] = []
        if let date = summary.date {
            parts.append(date.formatted(date: .long, time: .omitted))
        }
        parts.append(holesText(for: summary))
        if let toPar = summary.scoreToPar {
            parts.append(toPar == 0
                ? String(localized: "Par gespielt")
                : String(localized: "\(signed(toPar)) zu Par"))
        }
        return parts
    }

    static func holesText(for summary: RoundShareSummary) -> String {
        let played = summary.holesPlayed, total = summary.holesTotal
        switch (summary.kind, played >= total) {
        case (.golf, true):      return String(localized: "\(total) Löcher")
        case (.golf, false):     return String(localized: "\(played) von \(total) Löchern")
        case (.minigolf, true):  return String(localized: "\(total) Bahnen")
        case (.minigolf, false): return String(localized: "\(played) von \(total) Bahnen")
        }
    }

    static func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    static func medal(for place: Int) -> String {
        switch place {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(place + 1)."
        }
    }
}

// MARK: - Ergebniskarte

/// Das Bild zum Teilen. Feste Breite, damit `ImageRenderer` eine eindeutige
/// Größe bekommt; Farben aus `AppTheme`, damit es nach der App aussieht.
struct RoundShareCard: View {

    let summary: RoundShareSummary

    static let width: CGFloat = 390

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Group {
                if summary.isGroup {
                    rankingList
                } else {
                    scoreBlock
                }
            }
            .padding(18)

            if !summary.isGroup, !summary.holeStrokes.isEmpty {
                holeGrid
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
            }

            footer
        }
        .frame(width: Self.width)
        .background(AppTheme.bg)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: summary.kind == .golf ? "figure.golf" : "flag.checkered")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.gold)
                .frame(width: 40, height: 40)
                .background(AppTheme.gold.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.courseName ?? String(localized: summary.kind == .golf ? "Golf" : "Minigolf"))
                    .font(.headline.bold())
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppTheme.card)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let date = summary.date {
            parts.append(date.formatted(date: .abbreviated, time: .omitted))
        }
        parts.append(RoundShareText.holesText(for: summary))
        return parts.joined(separator: " · ")
    }

    private var scoreBlock: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(summary.totalStrokes)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.gold)
            Text("Schläge")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textSec)
            Spacer(minLength: 0)
            if let toPar = summary.scoreToPar {
                Text(toPar == 0 ? String(localized: "Par") : RoundShareText.signed(toPar))
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.scoreColor(toPar))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.card, in: Capsule())
            }
        }
    }

    private var rankingList: some View {
        VStack(spacing: 0) {
            ForEach(Array(summary.ranking.prefix(6).enumerated()), id: \.offset) { row, player in
                HStack(spacing: 12) {
                    Text(RoundShareText.medal(for: player.place))
                        .font(player.place < 3 ? .title2 : .headline)
                        .foregroundStyle(AppTheme.textSec)
                        .frame(width: 36)
                    Text(player.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text("\(player.total)")
                        .font(.title3.bold())
                        .monospacedDigit()
                        .foregroundStyle(player.place == 0 ? AppTheme.gold : AppTheme.text)
                    Text("Schl.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }
                .padding(.vertical, 9)
                .padding(.horizontal, 12)
                if row < min(summary.ranking.count, 6) - 1 {
                    Divider().overlay(AppTheme.cardAlt).padding(.leading, 60)
                }
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private var holeGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 9)
        return LazyVGrid(columns: columns, spacing: 5) {
            ForEach(Array(summary.holeStrokes.enumerated()), id: \.offset) { index, strokes in
                VStack(spacing: 1) {
                    Text("\(index + 1)")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(AppTheme.textTer)
                    Text(strokes > 0 ? "\(strokes)" : "–")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(strokes == 1 ? AppTheme.gold : AppTheme.text)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 7))
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "figure.golf")
                .font(.caption)
                .foregroundStyle(AppTheme.gold)
            Text("GolfTrack")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textSec)
            Spacer()
            Text(verbatim: "golftrack.app")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTer)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(AppTheme.cardDark)
    }
}

extension RoundShareCard {

    /// Rendert die Karte als Bild. Läuft auf dem Main Actor wie jede SwiftUI-Ansicht.
    @MainActor
    static func image(for summary: RoundShareSummary) -> UIImage? {
        let renderer = ImageRenderer(content: RoundShareCard(summary: summary)
            .environment(\.colorScheme, .dark))
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        if let image = renderer.uiImage { return image }
        // Unter iOS 26 kommt uiImage manchmal leer zurück – cgImage hilft.
        return renderer.cgImage.map { UIImage(cgImage: $0, scale: 3, orientation: .up) }
    }
}

// MARK: - Knopf

/// Gut sichtbarer Knopf am Ende der Runde. Öffnet das Share-Sheet mit Text,
/// Link und Ergebniskarte; dort steht auch „Bild sichern“ für Fotos.
struct RoundShareButton: View {

    let summary: RoundShareSummary
    /// Eigenes Bild statt der gemeinsamen Karte – die volle App nimmt für Golf
    /// ihre ausführliche Scorecard.
    var image: (@MainActor () -> UIImage?)? = nil

    @State private var payload: SharePayload?

    var body: some View {
        Button {
            Haptics.tap()
            share()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Runde teilen")
                        .font(.headline)
                    Text("Ergebnis und Link für Freunde – oder als Bild in Fotos sichern")
                        .font(.caption)
                        .opacity(0.75)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .opacity(0.6)
            }
            .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("roundShareButton")
        .sheet(item: $payload) { payload in
            ShareSheet(items: payload.items)
                .presentationDetents([.medium, .large])
                .ignoresSafeArea()
        }
    }

    @MainActor
    private func share() {
        var items: [Any] = [RoundShareText.message(for: summary)]
        if let picture = image?() ?? RoundShareCard.image(for: summary) {
            items.append(picture)
        }
        payload = SharePayload(items: items)
    }

    private struct SharePayload: Identifiable {
        let id = UUID()
        let items: [Any]
    }
}

// MARK: - UIActivityViewController

/// Das System-Share-Sheet. `ShareLink` kann Text und Bild nicht zusammen
/// übergeben – Nachrichten, WhatsApp & Co. sollen aber beides bekommen.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
