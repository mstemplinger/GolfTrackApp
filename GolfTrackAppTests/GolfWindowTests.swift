import Foundation
import Testing
@testable import GolfTrackApp

struct GolfWindowTests {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func hour(_ offset: Int, rain: Double = 0, wind: Double = 10,
                      code: Int = 1, day: Bool = true) -> HourlyForecast {
        HourlyForecast(date: base.addingTimeInterval(Double(offset) * 3600),
                       weatherCode: code, temperature: 15, precipitationMm: rain,
                       precipitationProbability: 0, windKmh: wind, isDaylight: day)
    }

    @Test func lightDrizzleInTheMorningDoesNotSpoilTheDay() {
        let hours = [hour(0, rain: 0.1, code: 51), hour(1, rain: 0.8, code: 61)]
            + (2...7).map { hour($0) }
        // 0,1 mm um Stunde 0 ist spielbar, aber allein zu kurz; danach Regen, dann frei.
        let windows = GolfWindowFinder.windows(in: hours, rules: .default)
        #expect(windows == [GolfWindow(start: hour(2).date, end: hour(8).date)])
    }

    @Test func rainSplitsWindowsAndShortGapsAreDropped() {
        let hours = [hour(0), hour(1), hour(2, rain: 2, code: 63), hour(3), hour(4, wind: 45), hour(5), hour(6)]
        let windows = GolfWindowFinder.windows(in: hours, rules: .default)
        #expect(windows.count == 2)
        #expect(windows[0].start == hour(0).date && windows[0].end == hour(2).date)
        #expect(windows[1].start == hour(5).date && windows[1].end == hour(7).date)
    }

    @Test func nightAndThunderAreNeverPlayable() {
        #expect(!hour(0, day: false).isPlayable(with: .default))
        #expect(!hour(0, code: 95).isPlayable(with: .default))
        #expect(!hour(0, code: 45).isPlayable(with: .default))
        #expect(hour(0, rain: 0.2, code: 51).isPlayable(with: .default))
    }

    @Test func pastHoursAreIgnoredAndWindowStartsNow() {
        let hours = (0...5).map { hour($0) }
        let now = hour(2).date.addingTimeInterval(1800)
        let windows = GolfWindowFinder.windows(in: hours, now: now, rules: .default)
        #expect(windows.count == 1)
        #expect(windows[0].start == now)
        #expect(windows[0].end == hour(6).date)
    }

    @Test func lessThanTwoHoursLeftIsNoWindow() {
        let hours = (0...3).map { hour($0) }
        let now = hour(3).date.addingTimeInterval(600)
        #expect(GolfWindowFinder.windows(in: hours, now: now, rules: .default).isEmpty)
    }

    @Test func customRulesChangeTheVerdict() {
        var strict = GolfWeatherRules.default
        strict.maxRainMm = 0
        strict.maxWindKmh = 15
        #expect(!hour(0, rain: 0.1, code: 51).isPlayable(with: strict))
        #expect(!hour(0, wind: 20).isPlayable(with: strict))
        #expect(hour(0).isPlayable(with: strict))

        var long = GolfWeatherRules.default
        long.minWindowHours = 4
        let hours = (0...2).map { hour($0) }
        #expect(GolfWindowFinder.windows(in: hours, rules: .default).count == 1)
        #expect(GolfWindowFinder.windows(in: hours, rules: long).isEmpty)
    }
}
