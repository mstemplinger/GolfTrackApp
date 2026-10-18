import Foundation
import Testing
@testable import GolfTrackApp

struct NewCourseDetectionTests {

    private let jetzt = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func neuerPlatzWirdErkannt() {
        let ergebnis = CourseCatalogService.mergeNewCourses(
            [:], known: ["a", "b"], current: ["a", "b", "c"], now: jetzt)
        #expect(ergebnis == ["c": jetzt])
    }

    @Test func offeneHinweiseBleibenStehen() {
        let gestern = jetzt.addingTimeInterval(-86_400)
        let ergebnis = CourseCatalogService.mergeNewCourses(
            ["c": gestern], known: ["a", "c"], current: ["a", "c"], now: jetzt)
        #expect(ergebnis == ["c": gestern])
    }

    @Test func zurueckgezogenerPlatzFliegtRaus() {
        let ergebnis = CourseCatalogService.mergeNewCourses(
            ["c": jetzt], known: ["a", "c"], current: ["a"], now: jetzt)
        #expect(ergebnis.isEmpty)
    }

    @Test func alterHinweisLaeuftAb() {
        let alt = jetzt.addingTimeInterval(-CourseCatalogService.newCourseLifetime - 1)
        let ergebnis = CourseCatalogService.mergeNewCourses(
            ["c": alt], known: ["c"], current: ["c"], now: jetzt)
        #expect(ergebnis.isEmpty)
    }
}
