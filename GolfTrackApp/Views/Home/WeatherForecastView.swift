import SwiftUI

struct WeatherForecastView: View {
    @ObservedObject var weather: GolfWeatherService
    @Environment(\.dismiss) private var dismiss

    private let gold = AppTheme.gold

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // ── Aktuell ─────────────────────────────────
                        currentSummary

                        // ── 7-Tage Timeline ─────────────────────────
                        if !weather.dailyForecast.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("7-Tage-Vorhersage")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.textSec)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 12)

                                VStack(spacing: 0) {
                                    ForEach(Array(weather.dailyForecast.enumerated()), id: \.element.id) { idx, day in
                                        dayRow(day: day, isLast: idx == weather.dailyForecast.count - 1)
                                    }
                                }
                                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(weather.locationName.isEmpty ? "Wettervorhersage" : weather.locationName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(gold)
                }
            }
        }
    }

    // MARK: - Current summary card

    private var currentSummary: some View {
        HStack(spacing: 0) {
            // Icon + Temp
            VStack(spacing: 6) {
                Image(systemName: weather.symbolName)
                    .font(.system(size: 44))
                    .symbolRenderingMode(.multicolor)
                Text(weather.temperature)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text)
                Text(weather.conditionText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 80)

            // Stats
            VStack(alignment: .leading, spacing: 10) {
                detailRow(icon: "thermometer.medium", label: "Gefühlt", value: weather.feelsLike)
                detailRow(icon: "wind",               label: "Wind",    value: weather.windSpeed)
                detailRow(icon: "humidity",           label: "Feuchte", value: weather.humidity)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .overlay(alignment: .topTrailing) {
            // Golf-Wetter Badge
            HStack(spacing: 4) {
                Circle()
                    .fill(weather.isGoodGolfWeather ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                Text(weather.golfWeatherLabel)
                    .font(.caption2.bold())
                    .foregroundStyle(weather.isGoodGolfWeather ? Color.green : Color.orange)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (weather.isGoodGolfWeather ? Color.green : Color.orange).opacity(0.12),
                in: Capsule()
            )
            .padding(.top, 12)
            .padding(.trailing, 28)
        }
    }

    // MARK: - Day row

    private func dayRow(day: DailyForecast, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Day label
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.dayLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 100, alignment: .leading)
                }

                // Weather icon
                Image(systemName: day.symbolName)
                    .font(.title3)
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 28)

                // Condition
                Text(day.conditionText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Min/Max
                VStack(alignment: .trailing, spacing: 1) {
                    Text(String(format: "%.0f°", day.maxTemp))
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.text)
                    Text(String(format: "%.0f°", day.minTemp))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSec)
                }

                // Golf badge
                Image(systemName: day.isGoodGolfWeather ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(day.isGoodGolfWeather ? Color.green : Color.orange)
                    .font(.body)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Precipitation + wind detail
            if day.precipitationMm > 0 || day.maxWindKmh > 20 {
                HStack(spacing: 16) {
                    if day.precipitationMm > 0 {
                        Label(String(format: "%.1f mm", day.precipitationMm),
                              systemImage: "drop.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue.opacity(0.8))
                    }
                    if day.maxWindKmh > 0 {
                        Label(String(format: "%.0f km/h", day.maxWindKmh),
                              systemImage: "wind")
                            .font(.caption2)
                            .foregroundStyle(day.maxWindKmh > 30 ? Color.orange : AppTheme.textSec)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }

            if !isLast {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }

    // MARK: - Helper

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(gold)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSec)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.text)
        }
    }
}
