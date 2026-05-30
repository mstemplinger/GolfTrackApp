import SwiftUI

struct RoundRowView: View {
    let round: Round

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(round.course?.name ?? "Unbekannter Platz")
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(round.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !round.isComplete {
                        Text("Aktiv")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(round.scoreLabel)
                    .font(.title3.bold())
                    .foregroundStyle(golfScoreColor(round.scoreToPar))
                if round.totalStrokes > 0 {
                    Text("\(round.totalStrokes) Schläge")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}
