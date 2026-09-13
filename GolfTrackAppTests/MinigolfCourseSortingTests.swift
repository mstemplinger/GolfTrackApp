import CoreLocation
import Testing
@testable import GolfTrackApp

/// Reihenfolge und Entfernungstext der Anlagenliste im Minigolf-Bereich.
struct MinigolfCourseSortingTests {

    private func course(_ id: String, name: String, lat: Double, lon: Double) -> MinigolfCourseEntry {
        MinigolfCourseEntry(id: id, name: name, location: "Test", holes: 18,
                            lat: lat, lon: lon, welcome: "")
    }

    /// Passau, Sankt Englmar (≈ 65 km nordwestlich) und Wien (≈ 300 km).
    private var beispiele: [MinigolfCourseEntry] {
        [
            course("wien",     name: "Wien",           lat: 48.2082, lon: 16.3738),
            course("englmar",  name: "Sankt Englmar",  lat: 48.9906, lon: 12.8114),
            course("passau",   name: "Passau",         lat: 48.5665, lon: 13.4312)
        ]
    }

    private let inPassau = CLLocation(latitude: 48.5665, longitude: 13.4312)

    @Test func sortiertMitStandortNachEntfernung() {
        let sortiert = MinigolfCourses.sorted(beispiele, near: inPassau)
        #expect(sortiert.map(\.id) == ["passau", "englmar", "wien"])
    }

    @Test func sortiertOhneStandortAlphabetisch() {
        let sortiert = MinigolfCourses.sorted(beispiele, near: nil)
        #expect(sortiert.map(\.name) == ["Passau", "Sankt Englmar", "Wien"])
    }

    /// Weit weg heißt nicht „weg": Auch ohne Anlage in der Nähe bleibt die
    /// Liste vollständig – es wird nur sortiert, nie gefiltert.
    @Test func filtertNichtsWeg() {
        let imAtlantik = CLLocation(latitude: 30, longitude: -40)
        #expect(MinigolfCourses.sorted(beispiele, near: imAtlantik).count == beispiele.count)
        #expect(MinigolfCourses.sorted(beispiele, near: nil).count == beispiele.count)
    }

    /// Gleiche Entfernung darf nicht bei jedem Neuzeichnen die Reihenfolge
    /// würfeln – dann entscheidet der Name.
    @Test func gleicheEntfernungBleibtStabil() {
        let a = course("a", name: "Bravo",  lat: 48.5665, lon: 13.4312)
        let b = course("b", name: "Alpha",  lat: 48.5665, lon: 13.4312)
        #expect(MinigolfCourses.sorted([a, b], near: inPassau).map(\.name) == ["Alpha", "Bravo"])
    }

    @Test func entfernungstextStaffelt() {
        let nah = course("nah", name: "Nah", lat: 48.5670, lon: 13.4312)      // ~55 m
        #expect(nah.formattedDistance(from: inPassau) == "< 1 km")

        let englmar = course("englmar", name: "Sankt Englmar", lat: 48.9906, lon: 12.8114)
        let text = englmar.formattedDistance(from: inPassau)
        #expect(text.hasSuffix(" km"))
        // Zweistellig und ohne Nachkommastelle – 65 km, nicht 65,3 km.
        #expect(text == "\(Int((englmar.distance(from: inPassau) / 1000).rounded())) km")
    }
}
