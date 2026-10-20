import Foundation
import Combine
import CoreLocation
import SwiftUI

// MARK: - Hourly forecast model

struct HourlyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let weatherCode: Int
    let temperature: Double
    let precipitationMm: Double
    let precipitationProbability: Int
    let windKmh: Double
    let isDaylight: Bool

    var symbolName: String { GolfWeatherService.weatherInfo(wmoCode: weatherCode, isDay: isDaylight).1 }

    /// Bewertung je Stunde statt je Tag: 0,1 mm Niesel um 6 Uhr morgens
    /// sollen nicht den ganzen Tag als „schlechtes Wetter“ markieren.
    var isPlayable: Bool { isPlayable(with: .current) }

    func isPlayable(with rules: GolfWeatherRules) -> Bool {
        isDaylight
            && precipitationMm <= rules.maxRainMm + 0.001
            && windKmh <= rules.maxWindKmh
            && temperature >= rules.minTemperature
            && !Self.unplayableCodes.contains(weatherCode)
    }

    /// Nebel, Eis, Schnee und Gewitter sind unabhängig von der Regenmenge kein Golfwetter.
    private static let unplayableCodes: Set<Int> = [45, 48, 56, 57, 66, 67, 71, 73, 75, 77, 85, 86, 95, 96, 99]
}

/// Vom Nutzer einstellbare Grenzen für „Golf-Wetter“ (Einstellungen → Golf-Wetter).
struct GolfWeatherRules: Equatable {
    var maxRainMm: Double
    var maxWindKmh: Double
    var minTemperature: Double
    var minWindowHours: Int

    static let `default` = GolfWeatherRules(maxRainMm: 0.2, maxWindKmh: 30,
                                            minTemperature: 3, minWindowHours: 2)

    static let maxRainKey        = "golfWeather.maxRainMm"
    static let maxWindKey        = "golfWeather.maxWindKmh"
    static let minTemperatureKey = "golfWeather.minTemperature"
    static let minWindowKey      = "golfWeather.minWindowHours"

    /// Liest die gespeicherten Werte; fehlende Schlüssel fallen auf `default` zurück.
    static var current: GolfWeatherRules {
        let d = UserDefaults.standard
        func double(_ key: String, _ fallback: Double) -> Double {
            d.object(forKey: key) == nil ? fallback : d.double(forKey: key)
        }
        return GolfWeatherRules(
            maxRainMm: double(maxRainKey, `default`.maxRainMm),
            maxWindKmh: double(maxWindKey, `default`.maxWindKmh),
            minTemperature: double(minTemperatureKey, `default`.minTemperature),
            minWindowHours: d.object(forKey: minWindowKey) == nil
                ? `default`.minWindowHours : d.integer(forKey: minWindowKey)
        )
    }

    static func reset() {
        for key in [maxRainKey, maxWindKey, minTemperatureKey, minWindowKey] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

/// Zusammenhängende Spielzeit an einem Tag, `end` ist exklusiv (Ende der letzten guten Stunde).
struct GolfWindow: Equatable {
    let start: Date
    let end: Date

    var duration: TimeInterval { end.timeIntervalSince(start) }
    /// „10–15 Uhr“ bzw. „10 AM – 3 PM“, je nach Sprache.
    var label: String { (start..<end).formatted(.interval.hour()) }
}

enum GolfWindowFinder {
    /// Fasst aufeinanderfolgende spielbare Stunden zu Fenstern zusammen.
    /// Stunden, die vor `now` enden, werden ignoriert; Fenster kürzer als
    /// `rules.minWindowHours` (Standard 2 h ≈ neun Loch) zählen nicht.
    static func windows(in hours: [HourlyForecast], now: Date? = nil,
                        rules: GolfWeatherRules = .current) -> [GolfWindow] {
        let minimumDuration = TimeInterval(rules.minWindowHours) * 3600
        var result: [GolfWindow] = []
        var start: Date?
        var end: Date?
        func close() {
            if let s = start, let e = end, e.timeIntervalSince(s) >= minimumDuration {
                result.append(GolfWindow(start: s, end: e))
            }
            start = nil; end = nil
        }
        for hour in hours.sorted(by: { $0.date < $1.date }) {
            let hourEnd = hour.date.addingTimeInterval(3600)
            if let now, hourEnd <= now { continue }
            if hour.isPlayable(with: rules) {
                // Lücken in den Daten beenden ein Fenster ebenfalls.
                if let e = end, e != hour.date { close() }
                if start == nil { start = max(hour.date, now ?? hour.date) }
                end = hourEnd
            } else {
                close()
            }
        }
        close()
        return result
    }
}

// MARK: - Daily forecast model (public – used by WeatherForecastView)

struct DailyForecast: Identifiable {
    let id = UUID()
    let date: Date
    let weatherCode: Int
    let maxTemp: Double
    let minTemp: Double
    let precipitationMm: Double
    let maxWindKmh: Double
    let conditionText: String
    let symbolName: String
    var hours: [HourlyForecast] = []

    var isToday: Bool { Calendar.current.isDateInToday(date) }

    /// Für heute nur die noch kommenden Stunden.
    var golfWindows: [GolfWindow] {
        GolfWindowFinder.windows(in: hours, now: isToday ? Date() : nil)
    }

    var isGoodGolfWeather: Bool {
        guard !hours.isEmpty else { return weatherCode < 45 && maxWindKmh <= 30 }
        return !golfWindows.isEmpty
    }

    /// Hellstunden des Tages für die Stundenleiste.
    var daylightHours: [HourlyForecast] { hours.filter(\.isDaylight) }

    var dayLabel: String {
        if Calendar.current.isDateInToday(date)    { return String(localized: "Heute") }
        if Calendar.current.isDateInTomorrow(date) { return String(localized: "Morgen") }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }
}

// MARK: - Open-Meteo response models

private struct OpenMeteoResponse: Decodable {
    let current: CurrentWeather
    let daily: DailyWeather
    let hourly: HourlyWeather?
    let utcOffsetSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case current, daily, hourly
        case utcOffsetSeconds = "utc_offset_seconds"
    }

    struct HourlyWeather: Decodable {
        let time: [String]
        let weatherCode: [Int?]
        let temperature2m: [Double?]
        let precipitation: [Double?]
        let precipitationProbability: [Int?]?
        let windSpeed10m: [Double?]
        let isDay: [Int?]
        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode              = "weather_code"
            case temperature2m            = "temperature_2m"
            case precipitation
            case precipitationProbability = "precipitation_probability"
            case windSpeed10m             = "wind_speed_10m"
            case isDay                    = "is_day"
        }
    }

    struct CurrentWeather: Decodable {
        let temperature2m: Double
        let apparentTemperature: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let relativeHumidity2m: Int
        let isDay: Int?
        enum CodingKeys: String, CodingKey {
            case temperature2m         = "temperature_2m"
            case apparentTemperature   = "apparent_temperature"
            case weatherCode           = "weather_code"
            case windSpeed10m          = "wind_speed_10m"
            case relativeHumidity2m    = "relative_humidity_2m"
            case isDay                 = "is_day"
        }
    }

    struct DailyWeather: Decodable {
        let time: [String]
        let weatherCode: [Int]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let precipitationSum: [Double]
        let windSpeed10mMax: [Double]
        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode       = "weather_code"
            case temperature2mMax  = "temperature_2m_max"
            case temperature2mMin  = "temperature_2m_min"
            case precipitationSum  = "precipitation_sum"
            case windSpeed10mMax   = "wind_speed_10m_max"
        }
    }
}

// MARK: - Service

@MainActor
final class GolfWeatherService: NSObject, ObservableObject {

    // MARK: Published state

    @Published var temperature: String = "--"
    @Published var feelsLike: String = "--"
    @Published var conditionText: String = "Golf-Wetter"
    @Published var symbolName: String = "sun.max.fill"
    @Published var windSpeed: String = ""
    @Published var humidity: String = ""
    @Published var uvIndex: String = ""
    @Published var locationName: String = ""
    @Published var isLoading = false
    @Published var hasData = false
    @Published var authDenied = false
    @Published var errorMessage: String?

    @Published var dailyForecast: [DailyForecast] = []

    // Raw values for golf-suitability check
    private(set) var rawWeatherCode: Int = -1
    private(set) var rawWindSpeed: Double = 0

    /// Heute (ab jetzt) spielbare Zeitfenster – Grundlage für das Badge auf der Startseite.
    var todayWindows: [GolfWindow] {
        dailyForecast.first(where: \.isToday)?.golfWindows ?? []
    }

    private var hasHourlyData: Bool {
        dailyForecast.contains { $0.isToday && !$0.hours.isEmpty }
    }

    /// true → heute gibt es noch ein Golf-Fenster.
    var isGoodGolfWeather: Bool {
        guard hasData else { return true }
        guard hasHourlyData else { return rawWeatherCode < 45 && rawWindSpeed <= 30 }
        return !todayWindows.isEmpty
    }

    // String(localized:) statt eines nackten Literals: der Wert landet über
    // Text(String) im UI und würde sonst in jeder Sprache deutsch bleiben.
    var golfWeatherLabel: String {
        guard hasData, hasHourlyData else {
            return isGoodGolfWeather
                ? String(localized: "Golf-Wetter")
                : String(localized: "schlechtes Wetter")
        }
        guard let next = todayWindows.first else {
            return String(localized: "Heute kein Golf-Wetter")
        }
        let time = next.end.formatted(.dateTime.hour())
        if next.start <= Date() {
            return String(localized: "Golf-Wetter bis \(time)")
        }
        return String(localized: "Golf-Wetter ab \(next.start.formatted(.dateTime.hour()))")
    }

    // MARK: Private

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // MARK: Init

    private var defaultsObserver: AnyCancellable?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        // Geänderte Golf-Wetter-Grenzen sofort auf Startseite und Vorhersage anwenden.
        defaultsObserver = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in GolfWeatherRules.current }
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    // MARK: Public API

    func fetch() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        authDenied = false
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            isLoading = false
            authDenied = true
        }
    }

    /// Fetch weather for a specific course coordinate (bypasses GPS).
    func fetchForCoordinate(lat: Double, lon: Double, name: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        authDenied = false
        locationName = name
        Task {
            await fetchWeather(for: CLLocation(latitude: lat, longitude: lon))
        }
    }

    // MARK: Fetch from Open-Meteo

    private func fetchWeather(for location: CLLocation) async {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(lat)&longitude=\(lon)"
            + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max"
            + "&hourly=weather_code,temperature_2m,precipitation,precipitation_probability,wind_speed_10m,is_day"
            + "&forecast_days=7&wind_speed_unit=kmh&timezone=auto"

        guard let url = URL(string: urlString) else {
            isLoading = false
            errorMessage = "Ungültige URL"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let cur = decoded.current

            temperature    = String(format: "%.0f°C", cur.temperature2m)
            feelsLike      = String(format: "%.0f°C", cur.apparentTemperature)
            windSpeed      = String(format: "%.0f km/h", cur.windSpeed10m)
            humidity       = "\(cur.relativeHumidity2m)%"
            uvIndex        = "–"
            rawWeatherCode = cur.weatherCode
            rawWindSpeed   = cur.windSpeed10m
            let (text, symbol) = Self.weatherInfo(wmoCode: cur.weatherCode, isDay: (cur.isDay ?? 1) == 1)
            conditionText  = text
            symbolName     = symbol

            let hoursByDay = Self.parseHourly(decoded.hourly,
                                              utcOffset: decoded.utcOffsetSeconds ?? 0)

            // Parse daily forecast
            let iso = ISO8601DateFormatter(); iso.formatOptions = [.withFullDate]
            iso.timeZone = TimeZone(secondsFromGMT: decoded.utcOffsetSeconds ?? 0)
            let d = decoded.daily
            dailyForecast = zip(d.time.indices, d.time).compactMap { i, timeStr -> DailyForecast? in
                guard let date = iso.date(from: timeStr) else { return nil }
                let code = d.weatherCode[safe: i] ?? 0
                let (ct, sym) = Self.weatherInfo(wmoCode: code)
                return DailyForecast(
                    date: date,
                    weatherCode: code,
                    maxTemp: d.temperature2mMax[safe: i] ?? 0,
                    minTemp: d.temperature2mMin[safe: i] ?? 0,
                    precipitationMm: d.precipitationSum[safe: i] ?? 0,
                    maxWindKmh: d.windSpeed10mMax[safe: i] ?? 0,
                    conditionText: ct,
                    symbolName: sym,
                    hours: hoursByDay[timeStr] ?? []
                )
            }

            hasData        = true
        } catch {
            errorMessage = "Wetter nicht verfügbar"
        }
        isLoading = false
    }

    /// Open-Meteo liefert Ortszeit ohne Zone („2026-10-18T14:00“); gruppiert wird
    /// nach dem Datumsteil, damit die Stunden zum gleichnamigen Tag passen.
    private static func parseHourly(_ h: OpenMeteoResponse.HourlyWeather?,
                                    utcOffset: Int) -> [String: [HourlyForecast]] {
        guard let h else { return [:] }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: utcOffset)
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"
        var result: [String: [HourlyForecast]] = [:]
        for (i, timeStr) in h.time.enumerated() {
            guard let date = fmt.date(from: timeStr),
                  let code = h.weatherCode[safe: i] ?? nil,
                  let temp = h.temperature2m[safe: i] ?? nil,
                  let wind = h.windSpeed10m[safe: i] ?? nil else { continue }
            let hour = HourlyForecast(
                date: date,
                weatherCode: code,
                temperature: temp,
                precipitationMm: (h.precipitation[safe: i] ?? nil) ?? 0,
                precipitationProbability: (h.precipitationProbability?[safe: i] ?? nil) ?? 0,
                windKmh: wind,
                isDaylight: ((h.isDay[safe: i] ?? nil) ?? 1) == 1
            )
            result[String(timeStr.prefix(10)), default: []].append(hour)
        }
        return result
    }

    // MARK: WMO-Wettercode → lokalisierter Text + SF Symbol
    // Die Texte liegen als deutsche Schlüssel im String-Katalog; ohne
    // String(localized:) blieben sie in jeder Sprache deutsch.

    static func weatherInfo(wmoCode code: Int, isDay: Bool = true) -> (String, String) {
        // Nachts Mond statt Sonne – nur bei Codes, deren Symbol eine Sonne zeigt.
        if !isDay {
            switch code {
            case 0:      return (String(localized: "Klar"),          "moon.stars.fill")
            case 1:      return (String(localized: "Meist klar"),    "moon.stars.fill")
            case 2:      return (String(localized: "Teils bewölkt"), "cloud.moon.fill")
            case 80, 81: return (String(localized: "Regenschauer"),  "cloud.moon.rain.fill")
            default:     break
            }
        }
        switch code {
        case 0:           return (String(localized: "Sonnig"),             "sun.max.fill")
        case 1:           return (String(localized: "Meist sonnig"),       "sun.max.fill")
        case 2:           return (String(localized: "Teils bewölkt"),      "cloud.sun.fill")
        case 3:           return (String(localized: "Bedeckt"),            "cloud.fill")
        case 45, 48:      return (String(localized: "Neblig"),             "cloud.fog.fill")
        case 51, 53, 55:  return (String(localized: "Nieselregen"),        "cloud.drizzle.fill")
        case 56, 57:      return (String(localized: "Eisregen"),           "cloud.sleet.fill")
        case 61, 63:      return (String(localized: "Regen"),              "cloud.rain.fill")
        case 65:          return (String(localized: "Starkregen"),         "cloud.heavyrain.fill")
        case 66, 67:      return (String(localized: "Gefrierender Regen"), "cloud.sleet.fill")
        case 71, 73:      return (String(localized: "Schnee"),             "cloud.snow.fill")
        case 75:          return (String(localized: "Starker Schnee"),     "cloud.snow.fill")
        case 77:          return (String(localized: "Schneegriesel"),      "cloud.snow.fill")
        case 80, 81:      return (String(localized: "Regenschauer"),       "cloud.sun.rain.fill")
        case 82:          return (String(localized: "Starke Schauer"),     "cloud.heavyrain.fill")
        case 85, 86:      return (String(localized: "Schneeschauer"),      "cloud.snow.fill")
        case 95:          return (String(localized: "Gewitter"),           "cloud.bolt.fill")
        case 96, 99:      return (String(localized: "Starke Gewitter"),   "cloud.bolt.rain.fill")
        default:          return (String(localized: "Wechselhaft"),        "cloud.sun.fill")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension GolfWeatherService: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                self.isLoading = false
                self.authDenied = true
            default:
                self.isLoading = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        Task { @MainActor in
            await self.fetchWeather(for: loc)
        }
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, _ in
            DispatchQueue.main.async {
                self.locationName = placemarks?.first?.locality ?? ""
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            self.isLoading = false
            self.errorMessage = "Standort nicht verfügbar"
        }
    }
}
