import SwiftUI
import WatchKit

private let gold = Color(red: 0.79, green: 0.66, blue: 0.30)

// MARK: - Summary after all holes

struct RoundSummaryView: View {
    let model: WatchRoundModel
    let onNewRound: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {

                // Header
                VStack(spacing: 2) {
                    Image(systemName: "flag.checkered")
                        .font(.title2)
                        .foregroundStyle(gold)
                    Text("Runde beendet")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                // Total
                VStack(spacing: 0) {
                    Text("\(model.totalStrokes)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Schläge gesamt")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                // Per-hole list
                VStack(spacing: 0) {
                    ForEach(0..<model.holes, id: \.self) { i in
                        HStack {
                            Text("L\(i + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 26, alignment: .leading)
                            Spacer()
                            Text("\(model.strokes[i])")
                                .font(.caption.bold())
                                .foregroundStyle(strokeColor(model.strokes[i]))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)

                        if i < model.holes - 1 {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))

                // New round button
                Button {
                    onNewRound()
                } label: {
                    Text("Neue Runde")
                        .font(.caption.bold())
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
    }

    private func strokeColor(_ strokes: Int) -> Color {
        if strokes == 0 { return .secondary }
        if strokes <= 3 { return gold }
        if strokes <= 5 { return .white }
        return Color.orange
    }
}
