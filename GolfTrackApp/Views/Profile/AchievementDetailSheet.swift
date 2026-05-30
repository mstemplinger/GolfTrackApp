import SwiftUI

private let gold = Color(red: 0.79, green: 0.66, blue: 0.30)

struct AchievementDetailSheet: View {
    let achievement: GCAchievement
    let isUnlocked: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {

            // Handle
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 24)

            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? gold.opacity(0.2) : Color.white.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: achievement.icon)
                    .font(.system(size: 34))
                    .foregroundStyle(isUnlocked ? gold : Color.white.opacity(0.3))

                // Fortschrittsring wenn in Arbeit
                if !isUnlocked && progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress / 100)
                        .stroke(gold.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                }
            }
            .padding(.bottom, 16)

            // Status-Badge
            Text(isUnlocked ? "Erreicht ✓" : (progress > 0 ? "In Arbeit" : "Noch gesperrt"))
                .font(.caption.bold())
                .foregroundStyle(isUnlocked ? gold : Color.white.opacity(0.4))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    isUnlocked ? gold.opacity(0.15) : Color.white.opacity(0.07),
                    in: Capsule()
                )
                .padding(.bottom, 14)

            // Titel
            Text(achievement.displayTitle)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            // Beschreibung was zu tun ist
            Text(achievement.displayDescription)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)

            // Fortschrittsbalken wenn teilweise erreicht
            if !isUnlocked && progress > 0 {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(gold.opacity(0.7))
                                .frame(width: geo.size.width * (progress / 100))
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 32)

                    Text("\(Int(progress)) %")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .padding(.bottom, 20)
            }

            // Hinweis wie man es erreicht
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(gold)
                Text(achievement.hint)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.06, green: 0.14, blue: 0.08).ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}
