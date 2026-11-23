import SwiftUI

/// Stundenverlauf als Balken: ein Balken je Hellstunde, Höhe = Temperatur,
/// Gold = spielbar. Über jedem Balken die Temperatur, darunter die Uhrzeit.
/// Vergangene Stunden verblassen, die aktuelle ist umrandet.
///
/// Gemeinsam genutzt von der Wetterkarte der Startseite und der
/// Wettervorhersage, damit beide gleich aussehen.
struct GolfHourBars: View {
    let hours: [HourlyForecast]
    var accessibilityText: String = ""
    var showsLegend = true

    private static let barMaxHeight: CGFloat = 38

    var body: some View {
        let temps = hours.map(\.temperature)
        let low = (temps.min() ?? 0) - 2
        let span = max(1, (temps.max() ?? 1) - low)
        let now = Date()
        let rules = GolfWeatherRules.current
        let labelStep = hours.count > 12 ? 3 : 2

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                    let past = hour.date.addingTimeInterval(3600) <= now
                    let current = hour.date <= now && !past
                    let playable = hour.isPlayable(with: rules)
                    VStack(spacing: 3) {
                        Text(String(format: "%.0f°", hour.temperature))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(current ? AppTheme.text : AppTheme.textSec)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .opacity(past ? 0.4 : 1)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(playable ? AppTheme.gold : AppTheme.cardAlt)
                            .frame(height: max(6, Self.barMaxHeight * (hour.temperature - low) / span))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(.white.opacity(current ? 0.9 : 0), lineWidth: 1.5)
                            )
                            .opacity(past ? 0.3 : 1)
                        Text(index % labelStep == 0 ? hour.date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted))) : " ")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(current ? AppTheme.text : AppTheme.textTer)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 68, alignment: .bottom)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityText))

            if showsLegend {
                HStack(spacing: 12) {
                    legendDot(AppTheme.gold, "Golf-Wetter")
                    legendDot(AppTheme.cardAlt, "Regen, Wind oder kalt")
                }
            }
        }
    }

    private func legendDot(_ color: Color, _ label: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
            Text(label)
        }
        .font(.caption2)
        .foregroundStyle(AppTheme.textSec)
    }
}
