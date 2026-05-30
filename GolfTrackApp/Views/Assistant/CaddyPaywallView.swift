import SwiftUI

struct CaddyPaywallView: View {
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, color: Color, text: String)] = [
        ("waveform.circle.fill",   AppTheme.gold,                           "KI-Sprachassistent Caddy"),
        ("book.fill",              Color(red: 0.3, green: 0.85, blue: 0.5), "Regeln, Tipps & Strategien auf Abruf"),
        ("mic.fill",               Color(red: 0.4, green: 0.7,  blue: 1.0), "Gesprächsbasierte Golf-Beratung"),
        ("location.fill",          Color(red: 1.0, green: 0.6,  blue: 0.3), "Auch unterwegs auf dem Platz nutzbar"),
        ("infinity",               Color(red: 0.6, green: 0.5,  blue: 1.0), "Unbegrenzte Gespräche"),
    ]

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.textTer)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        comingSoonBanner
                        featuresSection
                        closeButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.gold.opacity(0.08))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(AppTheme.gold.opacity(0.12))
                    .frame(width: 70, height: 70)
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AppTheme.gold.opacity(0.5))
            }

            Text("Caddy – Golf-Assistent")
                .font(.title.bold())
                .foregroundStyle(AppTheme.text)

            Text("Dein persönlicher KI-Caddy –\nRegeln, Tipps und Strategien per Sprache.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }

    // MARK: - Coming Soon Banner

    private var comingSoonBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.fill")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
            Text("Bald verfügbar – wir arbeiten daran!")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.08, green: 0.18, blue: 0.11))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(features.indices, id: \.self) { i in
                let f = features[i]
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(f.color.opacity(0.08))
                            .frame(width: 40, height: 40)
                        Image(systemName: f.icon)
                            .font(.system(size: 17))
                            .foregroundStyle(f.color.opacity(0.5))
                    }
                    Text(f.text)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSec)
                    Spacer()
                    Image(systemName: "clock")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textTer)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                if i < features.count - 1 {
                    Divider()
                        .background(AppTheme.cardAlt)
                        .padding(.leading, 70)
                }
            }
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Close

    private var closeButton: some View {
        Button { dismiss() } label: {
            Text("Schließen")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSec)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
