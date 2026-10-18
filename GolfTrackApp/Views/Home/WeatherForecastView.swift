import SwiftUI

struct WeatherForecastView: View {
    @ObservedObject var weather: GolfWeatherService
    @Environment(\.dismiss) private var dismiss
    @State private var expandedDay: UUID?

    private let gold = AppTheme.gold

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // ── Aktuell ─────────────────────────────────
                        currentSummary

                        // ── Nächste Stunden ─────────────────────────
                        if !upcomingHours.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Nächste Stunden")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.textSec)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 12)

                                hourStrip(upcomingHours)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                            }
                        }

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
                    Button("Fertig") {
                        Haptics.tap()
                        dismiss()
                    }
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

    // MARK: - Upcoming hours

    /// Die nächsten 24 Stunden ab der laufenden Stunde, über Tagesgrenzen hinweg.
    private var upcomingHours: [HourlyForecast] {
        let now = Date()
        return weather.dailyForecast
            .flatMap(\.hours)
            .filter { $0.date.addingTimeInterval(3600) > now }
            .prefix(24)
            .map { $0 }
    }

    private func hourStrip(_ hours: [HourlyForecast]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(hours) { hour in
                    hourCell(hour)
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func hourCell(_ hour: HourlyForecast) -> some View {
        VStack(spacing: 6) {
            Text(hour.date.formatted(.dateTime.hour()))
                .font(.caption2)
                .foregroundStyle(AppTheme.textSec)
            Image(systemName: hour.symbolName)
                .font(.body)
                .symbolRenderingMode(.multicolor)
                .frame(height: 22)
            Text(String(format: "%.0f°", hour.temperature))
                .font(.caption.bold())
                .foregroundStyle(AppTheme.text)
            Text(hour.precipitationMm >= 0.1 ? String(format: "%.1f", hour.precipitationMm) : " ")
                .font(.caption2)
                .foregroundStyle(.blue.opacity(0.8))
            Capsule()
                .fill(hourColor(hour))
                .frame(height: 4)
        }
        .frame(width: 44)
    }

    /// Grün = spielbar, Orange = Regen/Wind/Kälte, Grau = dunkel.
    private func hourColor(_ hour: HourlyForecast) -> Color {
        guard hour.isDaylight else { return AppTheme.textTer.opacity(0.3) }
        return hour.isPlayable ? .green : .orange
    }

    // MARK: - Day row

    private func dayRow(day: DailyForecast, isLast: Bool) -> some View {
        let windows = day.golfWindows
        let isExpanded = expandedDay == day.id
        return VStack(spacing: 0) {
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

                if !day.hours.isEmpty {
                    Image(systemName: "chevron.down")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.textTer)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                } else {
                    Image(systemName: day.isGoodGolfWeather ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(day.isGoodGolfWeather ? Color.green : Color.orange)
                        .font(.body)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, day.hours.isEmpty ? 14 : 8)

            // Golf-Fenster statt eines Urteils über den ganzen Tag
            if !day.hours.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    daylightBar(day)
                    HStack(spacing: 6) {
                        Image(systemName: windows.isEmpty ? "xmark.circle.fill" : "figure.golf")
                            .font(.caption)
                        Text(windowText(windows, isToday: day.isToday))
                            .font(.caption.bold())
                            .lineLimit(2)
                        Spacer()
                    }
                    .foregroundStyle(windows.isEmpty ? Color.orange : Color.green)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }

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

            if isExpanded {
                hourStrip(day.daylightHours)
                    .padding(.bottom, 12)
            }

            if !isLast {
                Divider()
                    .padding(.leading, 16)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !day.hours.isEmpty else { return }
            Haptics.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedDay = isExpanded ? nil : day.id
            }
        }
    }

    /// Ein Segment je Hellstunde; vergangene Stunden von heute abgeblendet.
    private func daylightBar(_ day: DailyForecast) -> some View {
        let now = Date()
        return HStack(spacing: 2) {
            ForEach(day.daylightHours) { hour in
                RoundedRectangle(cornerRadius: 2)
                    .fill(hourColor(hour))
                    .opacity(hour.date.addingTimeInterval(3600) <= now ? 0.25 : 1)
                    .frame(height: 6)
            }
        }
    }

    private func windowText(_ windows: [GolfWindow], isToday: Bool) -> String {
        guard !windows.isEmpty else {
            return isToday
                ? String(localized: "Heute kein Golf-Fenster mehr")
                : String(localized: "Kein Golf-Fenster")
        }
        let list = windows.map(\.label).formatted(.list(type: .and))
        return String(localized: "Golf-Wetter: \(list)")
    }

    // MARK: - Helper

    // Siehe HomeView.weatherDetail: als String bliebe die Beschriftung deutsch.
    private func detailRow(icon: String, label: LocalizedStringKey, value: String) -> some View {
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
