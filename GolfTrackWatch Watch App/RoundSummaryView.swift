import SwiftUI
import WatchKit

// MARK: - Farbkonstanten

private let gold   = Color(red: 0.79, green: 0.66, blue: 0.30)
private let darkBg = Color(red: 0.06, green: 0.14, blue: 0.08)
private let rowBg  = Color(red: 0.10, green: 0.20, blue: 0.12)

// MARK: - Summary after all holes

struct RoundSummaryView: View {
    let model: WatchRoundModel
    let onNewRound: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {

                // ── Header ──────────────────────────────────────────
                VStack(spacing: 3) {
                    ZStack {
                        Circle()
                            .fill(rowBg)
                            .frame(width: 36, height: 36)
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(gold)
                    }
                    Text("Runde beendet")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Ergebnis")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 6)

                // ── Gesamt-Schläge ───────────────────────────────────
                VStack(spacing: 1) {
                    Text("\(model.totalStrokes)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Schläge gesamt")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(rowBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(gold.opacity(0.4), lineWidth: 1)
                        )
                )

                // ── Loch-für-Loch ────────────────────────────────────
                VStack(spacing: 0) {
                    ForEach(0..<model.holes, id: \.self) { i in
                        HStack {
                            Text("L\(i + 1)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .leading)

                            Spacer()

                            // Score-Anzeige mit Farbe
                            let s = model.strokes[i]
                            HStack(spacing: 3) {
                                if s > 0 {
                                    strokeBadge(s)
                                } else {
                                    Text("–")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)

                        if i < model.holes - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 0.5)
                                .padding(.leading, 38)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(rowBg)
                )

                // ── Neue Runde ───────────────────────────────────────
                Button {
                    WKInterfaceDevice.current().play(.success)
                    onNewRound()
                } label: {
                    Text("Neue Runde")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(gold)
                        .foregroundStyle(Color(red: 0.06, green: 0.14, blue: 0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 6)
        }
        .background(darkBg)
    }

    // MARK: - Score-Badge

    @ViewBuilder
    private func strokeBadge(_ strokes: Int) -> some View {
        let (color, _) = strokeStyle(strokes)
        Text("\(strokes)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(color)
    }

    private func strokeStyle(_ strokes: Int) -> (Color, Bool) {
        switch strokes {
        case 0:        return (.secondary, false)
        case 1...2:    return (gold, false)
        case 3...4:    return (.white, false)
        default:       return (Color(red: 1.0, green: 0.5, blue: 0.3), false)
        }
    }
}
