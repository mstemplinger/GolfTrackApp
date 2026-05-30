import Foundation
import Combine
import CoreLocation
import SwiftUI

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

    var isGoodGolfWeather: Bool { weatherCode < 45 && maxWindKmh <= 30 }
    var golfLabel: String { isGoodGolfWeather ? "Golf-Wetter" : "schlechtes Wetter" }

    var dayLabel: String {
        if Calendar.current.isDateInToday(date)    { return "Heute" }
        if Calendar.current.isDateInTomorrow(date) { return "Morgen" }
        let fmt = DateFormatter(); fmt.locale = Locale(identifier: "de_DE")
        fmt.dateFormat = "EEE, d. MMM"
        return fmt.string(from: date)
    }
}

// MARK: - Open-Meteo response models

private struct OpenMeteoResponse: Decodable {
    let current: CurrentWeather
    let daily: DailyWeather

    struct CurrentWeather: Decodable {
        let temperature2m: Double
        let apparentTemperature: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let relativeHumidity2m: Int
        enum CodingKeys: String, CodingKey {
            case temperature2m         = "temperature_2m"
            case apparentTemperature   = "apparent_temperature"
            case weatherCode           = "weather_code"
            case windSpeed10m          = "wind_speed_10m"
            case relativeHumidity2m    = "relative_humidity_2m"
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

    /// true  → "Golf-Wetter"   false → "schlechtes Wetter"
    var isGoodGolfWeather: Bool {
        guard hasData else { return true }
        return rawWeatherCode < 45 && rawWindSpeed <= 30
    }
    var golfWeatherLabel: String { isGoodGolfWeather ? "Golf-Wetter" : "schlechtes Wetter" }

    // MARK: Private

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // MARK: Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
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
            + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max"
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
            let (text, symbol) = Self.weatherInfo(wmoCode: cur.weatherCode)
            conditionText  = text
            symbolName     = symbol

            // Parse daily forecast
            let iso = ISO8601DateFormatter(); iso.formatOptions = [.withFullDate]
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
                    symbolName: sym
                )
            }

            hasData        = true
        } catch {
            errorMessage = "Wetter nicht verfügbar"
        }
        isLoading = false
    }

    // MARK: WMO weather code → German text + SF Symbol

    static func weatherInfo(wmoCode code: Int) -> (String, String) {
        switch code {
        case 0:           return ("Sonnig",             "sun.max.fill")
        case 1:           return ("Meist sonnig",       "sun.max.fill")
        case 2:           return ("Teils bewölkt",      "cloud.sun.fill")
        case 3:           return ("Bedeckt",            "cloud.fill")
        case 45, 48:      return ("Neblig",             "cloud.fog.fill")
        case 51, 53, 55:  return ("Nieselregen",        "cloud.drizzle.fill")
        case 56, 57:      return ("Eisregen",           "cloud.sleet.fill")
        case 61, 63:      return ("Regen",              "cloud.rain.fill")
        case 65:          return ("Starkregen",         "cloud.heavyrain.fill")
        case 66, 67:      return ("Gefrierender Regen", "cloud.sleet.fill")
        case 71, 73:      return ("Schnee",             "cloud.snow.fill")
        case 75:          return ("Starker Schnee",     "cloud.snow.fill")
        case 77:          return ("Schneegriesel",      "cloud.snow.fill")
        case 80, 81:      return ("Regenschauer",       "cloud.sun.rain.fill")
        case 82:          return ("Starke Schauer",     "cloud.heavyrain.fill")
        case 85, 86:      return ("Schneeschauer",      "cloud.snow.fill")
        case 95:          return ("Gewitter",           "cloud.bolt.fill")
        case 96, 99:      return ("Starke Gewitter",   "cloud.bolt.rain.fill")
        default:          return ("Wechselhaft",        "cloud.sun.fill")
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
