import Foundation
import Testing
@testable import GolfTrackApp

@MainActor
struct RoundStatsTests {

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    @Test func slotBoundaries() {
        #expect(RoundStatsService.slot(for: date(2026, 11, 23, 10, 59), calendar: calendar) == "morning")
        #expect(RoundStatsService.slot(for: date(2026, 11, 23, 11), calendar: calendar) == "midday")
        #expect(RoundStatsService.slot(for: date(2026, 11, 23, 14), calendar: calendar) == "afternoon")
        #expect(RoundStatsService.slot(for: date(2026, 11, 23, 18), calendar: calendar) == "evening")
    }

    @Test func isoWeekdayStartsMonday() {
        // 23.11.2026 ist ein Montag, 29.11.2026 ein Sonntag.
        #expect(RoundStatsService.isoWeekday(date(2026, 11, 23, 12), calendar: calendar) == 1)
        #expect(RoundStatsService.isoWeekday(date(2026, 11, 29, 12), calendar: calendar) == 7)
    }

    @Test func durationIsRoundedAndPlausible() {
        let start = date(2026, 11, 23, 9)
        // 4 h 22 min Golf über 18 Löcher → nächste Viertelstunde: 4 h 15 min
        #expect(RoundStatsService.duration(kind: .golf, from: start, to: start.addingTimeInterval(262 * 60), holes: 18) == 255)
        // 4 h 23 min → 4 h 30 min
        #expect(RoundStatsService.duration(kind: .golf, from: start, to: start.addingTimeInterval(263 * 60), holes: 18) == 270)
        // 18 Löcher Golf in 20 Minuten: nachgetragen, keine Dauer
        #expect(RoundStatsService.duration(kind: .golf, from: start, to: start.addingTimeInterval(20 * 60), holes: 18) == nil)
        // Minigolf 18 Bahnen in 40 Minuten → 45
        #expect(RoundStatsService.duration(kind: .minigolf, from: start, to: start.addingTimeInterval(40 * 60), holes: 18) == 45)
        // Fortgesetzte Runde ohne Beginn
        #expect(RoundStatsService.duration(kind: .minigolf, from: nil, to: start, holes: 18) == nil)
    }

    @Test func payloadCountsPlayedHolesAndDropsGolfOnlyFields() {
        let start = date(2026, 11, 23, 15)
        let payload = RoundStatsService.payload(kind: .minigolf,
                                                startedAt: start,
                                                endedAt: start.addingTimeInterval(30 * 60),
                                                strokes: [[2, 3, 0, 1], [1, 0, 0, 2]],
                                                putts: [[1, 1, 0, 1], [1, 0, 0, 1]],
                                                teeColor: "yellow",
                                                source: .clip,
                                                calendar: calendar)
        #expect(payload?.holesPlayed == 3)
        #expect(payload?.day == "2026-11-23")
        #expect(payload?.slot == "afternoon")
        #expect(payload?.putts == nil)
        #expect(payload?.teeColor == nil)
    }

    @Test func payloadRejectsEmptyOrUnevenRounds() {
        let now = Date()
        #expect(RoundStatsService.payload(kind: .minigolf, startedAt: nil, endedAt: now,
                                          strokes: [[0, 0, 0]], source: .app) == nil)
        #expect(RoundStatsService.payload(kind: .minigolf, startedAt: nil, endedAt: now,
                                          strokes: [[1, 2], [1]], source: .app) == nil)
    }

    @Test func payloadEncodesServerFieldNames() throws {
        let payload = try #require(RoundStatsService.payload(kind: .golf, startedAt: nil, endedAt: Date(),
                                                             strokes: [[4, 5]], putts: [[2, 2]],
                                                             teeColor: "yellow", source: .app))
        let json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(payload)) as? [String: Any])
        for key in ["version", "kind", "day", "slot", "weekday", "holesPlayed", "strokes", "putts", "teeColor", "source"] {
            #expect(json[key] != nil, "fehlt: \(key)")
        }
        #expect(json["kind"] as? String == "golf")
        #expect(json["source"] as? String == "app")
    }
}
