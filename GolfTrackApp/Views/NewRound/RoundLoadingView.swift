import SwiftUI

/// Kurze Ladeseite vor jeder Runde. Lädt nichts – sie gibt dem Spieler den
/// einen Hinweis mit, auf den die Positionsdaten angewiesen sind: Schlag
/// sofort nach dem Schlagen eintragen. Nur dann passt die gespeicherte
/// Position zum Ort des Schlags, und daraus leiten wir später Abschlag und
/// Loch für alle Spieler ab.
struct RoundLoadingView: View {
    let courseName: String
    let onFinished: () -> Void

    private static let duration: Double = 4
    /// Die ersten Runden immer, danach jede siebte – oft genug, dass der
    /// Hinweis hängen bleibt, selten genug, dass er nicht nervt.
    private static let alwaysFirst = 8
    private static let interval = 7

    /// `startCount` = Zahl der bisherigen Rundenstarts (vor diesem).
    static func shouldShow(startCount: Int) -> Bool {
        startCount < alwaysFirst || (startCount - alwaysFirst + 1) % interval == 0
    }

    @State private var progress: Double = 0
    @State private var pulse = false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                ZStack {
                    Circle()
                        .fill(AppTheme.gold.opacity(0.14))
                        .frame(width: 132, height: 132)
                        .scaleEffect(pulse ? 1.08 : 0.94)
                    Image(systemName: "figure.golf")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(AppTheme.gold)
                }
                .accessibilityHidden(true)

                Text("So funktioniert’s")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(AppTheme.gold)
                    .padding(.top, 28)

                Text("Schlag sofort eintragen, direkt nachdem du geschlagen hast.")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 10)

                Text("Nur so stimmt die Position jedes Schlags auf dem Platz.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSec)
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)

                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    ProgressView(value: progress)
                        .tint(AppTheme.gold)
                    Text("Platzdaten werden geladen …")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSec)
                    Text(courseName)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.textTer)
                        .lineLimit(1)
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)
        }
        .task {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.linear(duration: Self.duration)) { progress = 1 }
            try? await Task.sleep(for: .seconds(Self.duration))
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}

#Preview {
    RoundLoadingView(courseName: "Golf- und Landclub Bayerwald") {}
}
