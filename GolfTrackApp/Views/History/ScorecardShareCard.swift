import SwiftUI
import UIKit

// MARK: - Plain data snapshot (no SwiftData dependency for ImageRenderer)

struct ScorecardShareData {
    struct HoleEntry {
        let number: Int
        let strokes: Int
        let par: Int
    }

    let courseName: String
    let date: Date
    let gameModeIcon: String
    let gameModeName: String
    let holes: [HoleEntry]
    let totalPar: Int

    var totalStrokes: Int { holes.reduce(0) { $0 + $1.strokes } }
    var scoreToPar: Int   { totalStrokes - totalPar }

    // Build from a live Round (must be called on main thread)
    init(round: Round) {
        courseName   = round.course?.name ?? "Unbekannter Platz"
        date         = round.date
        gameModeIcon = round.gameMode.sfSymbol
        gameModeName = round.gameMode.displayName
        totalPar     = round.course?.totalPar ?? 0

        let sorted = round.holeScores.sorted { $0.holeNumber < $1.holeNumber }
        let pars   = round.course?.parValues ?? Array(repeating: 4, count: sorted.count)
        holes = sorted.enumerated().map { i, hs in
            HoleEntry(
                number:  hs.holeNumber,
                strokes: hs.strokes,
                par:     i < pars.count ? pars[i] : 4
            )
        }
    }
}

// MARK: - Rendering helper (call on @MainActor)

@MainActor
func renderScorecardImage(for round: Round) -> UIImage? {
    let data = ScorecardShareData(round: round)

    // Determine the card height by running a layout pass first
    let cardWidth: CGFloat = 390
    let scale: CGFloat = 3.0   // crisp on all devices, avoids deprecated UIScreen.main

    let card = ScorecardShareCard(data: data)

    let renderer = ImageRenderer(content: card)
    renderer.scale = scale
    renderer.proposedSize = ProposedViewSize(width: cardWidth, height: nil)

    // On iOS 26+ uiImage can be nil when height is unresolved – fall back to cgImage
    if let uiImg = renderer.uiImage { return uiImg }
    if let cg = renderer.cgImage {
        return UIImage(cgImage: cg, scale: scale, orientation: .up)
    }
    return nil
}

// MARK: - Share Card View

struct ScorecardShareCard: View {
    let data: ScorecardShareData

    private var frontHoles: [ScorecardShareData.HoleEntry] { Array(data.holes.prefix(9)) }
    private var backHoles:  [ScorecardShareData.HoleEntry] { Array(data.holes.dropFirst(9)) }
    private var is18: Bool  { data.holes.count > 9 }
    private var cellW: CGFloat { is18 ? 28 : 34 }

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            gridSection
            footerRow
        }
        .background(Color(r: 0x0E, g: 0x27, b: 0x18))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Header

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.courseName)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                Text(data.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                HStack(spacing: 5) {
                    Image(systemName: data.gameModeIcon)
                    Text(data.gameModeName)
                }
                .font(.caption.bold())
                .foregroundStyle(Color(r: 0xC9, g: 0xA0, b: 0x35))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(scoreToParLabel)
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(scoreColor)
                Text("\(data.totalStrokes) Schläge")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color(r: 0x16, g: 0x34, b: 0x21))
    }

    private var scoreToParLabel: String {
        let d = data.scoreToPar
        if d == 0 { return "E" }
        return d > 0 ? "+\(d)" : "\(d)"
    }

    private var scoreColor: Color {
        let d = data.scoreToPar
        if d < 0  { return Color(r: 0x66, g: 0xD9, b: 0x7F) }
        if d == 0 { return .white }
        if d <= 5 { return Color(r: 0xC9, g: 0xA0, b: 0x35) }
        return Color(r: 0xFF, g: 0x66, b: 0x66)
    }

    // MARK: Grid

    private var gridSection: some View {
        VStack(spacing: 0) {
            columnHeaders(holes: frontHoles)
            nineRow(label: "OUT", holes: frontHoles)

            if is18 {
                columnHeaders(holes: backHoles)
                    .padding(.top, 4)
                nineRow(label: "IN", holes: backHoles)
            }

            totalRow
        }
        .padding(.vertical, 6)
    }

    private func columnHeaders(holes: [ScorecardShareData.HoleEntry]) -> some View {
        HStack(spacing: 0) {
            headerCell("", width: 32)
            headerCell("Par", width: 32)
            ForEach(holes, id: \.number) { h in
                headerCell("\(h.number)", width: cellW)
            }
        }
    }

    private func nineRow(label: String, holes: [ScorecardShareData.HoleEntry]) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(r: 0xC9, g: 0xA0, b: 0x35))
                .frame(width: 32)
                .padding(.vertical, 6)

            Text("\(holes.map(\.par).reduce(0, +))")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 32)
                .padding(.vertical, 6)

            ForEach(holes, id: \.number) { h in
                scoreCell(strokes: h.strokes, par: h.par)
            }
        }
        .background(Color(r: 0x1C, g: 0x41, b: 0x29).opacity(0.5))
    }

    private var totalRow: some View {
        HStack(spacing: 0) {
            Text("TOT")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color(r: 0xC9, g: 0xA0, b: 0x35))
                .frame(width: 32)
                .padding(.vertical, 8)
            Text("\(data.totalPar)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 32)
                .padding(.vertical, 8)
            Spacer()
            Text("\(data.totalStrokes)")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(scoreColor)
                .padding(.trailing, 14)
        }
        .background(Color(r: 0x16, g: 0x34, b: 0x21))
        .padding(.top, 2)
    }

    // MARK: Cells

    private func headerCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(.white.opacity(0.35))
            .frame(width: width)
            .padding(.vertical, 4)
    }

    private func scoreCell(strokes: Int, par: Int) -> some View {
        let d = strokes - par
        let (bg, fg): (Color, Color) = {
            if strokes == 0    { return (.clear, .white.opacity(0.25)) }
            if d <= -2         { return (Color(r: 0x66, g: 0xD9, b: 0x7F).opacity(0.25), Color(r: 0x66, g: 0xD9, b: 0x7F)) }
            if d == -1         { return (Color(r: 0x66, g: 0xD9, b: 0x7F).opacity(0.12), Color(r: 0x66, g: 0xD9, b: 0x7F)) }
            if d == 0          { return (.clear, .white) }
            if d == 1          { return (Color(r: 0xC9, g: 0xA0, b: 0x35).opacity(0.18), Color(r: 0xC9, g: 0xA0, b: 0x35)) }
            return (Color(r: 0xFF, g: 0x66, b: 0x66).opacity(0.18), Color(r: 0xFF, g: 0x66, b: 0x66))
        }()
        return Text(strokes == 0 ? "–" : "\(strokes)")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(fg)
            .frame(width: cellW)
            .padding(.vertical, 6)
            .background(bg)
    }

    // MARK: Footer

    private var footerRow: some View {
        HStack {
            Image(systemName: "figure.golf")
                .foregroundStyle(Color(r: 0xC9, g: 0xA0, b: 0x35))
                .font(.caption)
            Text("GolfTrack")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.45))
            Spacer()
            Text("Erstellt mit GolfTrack")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color(r: 0x11, g: 0x2D, b: 0x1C))
    }
}

// MARK: - UIActivityViewController wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Color helper (RGB 0–255)

private extension Color {
    init(r: UInt8, g: UInt8, b: UInt8) {
        self.init(
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255
        )
    }
}
