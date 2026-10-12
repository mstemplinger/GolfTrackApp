import CoreLocation
import Foundation
import Testing
@testable import GolfTrackApp

/// Welche Anzeigen für einen Platz in Frage kommen (`AdCatalogService.pool`).
@MainActor
struct AdSelectionTests {

    /// Passau als Bezugspunkt; 0,1° Breite sind gut 11 km.
    private let passau = CLLocationCoordinate2D(latitude: 48.57, longitude: 13.43)

    private func ad(_ id: String,
                    courseID: String = "",
                    lat: Double? = nil,
                    lon: Double? = nil,
                    radiusKm: Int? = nil) -> RemoteAd {
        RemoteAd(id: id, placement: "golf_scoring", courseID: courseID,
                 title: id, subtitle: "", imageURL: "", linkURL: "", advertiser: "",
                 weight: 1, startsOn: nil, endsOn: nil,
                 lat: lat, lon: lon, radiusKm: radiusKm)
    }

    @Test("Die auf den Platz gebuchte Anzeige schlägt jeden Umkreis")
    func courseWins() {
        let ads = [ad("platz", courseID: "raßbach"),
                   ad("umkreis", lat: 48.57, lon: 13.43, radiusKm: 50)]
        let pool = AdCatalogService.pool(from: ads, courseID: "raßbach", coordinate: passau)
        #expect(pool.map(\.id) == ["platz"])
    }

    @Test("Im Umkreis zählen nur die Umkreise, die den Platz treffen")
    func insideRadius() {
        let ads = [ad("nah", lat: 48.60, lon: 13.43, radiusKm: 10),
                   ad("fern", lat: 49.50, lon: 13.43, radiusKm: 10),
                   ad("überall")]
        let pool = AdCatalogService.pool(from: ads, courseID: nil, coordinate: passau)
        #expect(pool.map(\.id) == ["nah"])
    }

    @Test("Außerhalb jedes Umkreises springt der nächstgelegene ein")
    func nearestRadius() {
        // Rand von „mittel" ist ~23 km entfernt, Rand von „weit" ~80 km.
        let ads = [ad("mittel", lat: 48.90, lon: 13.43, radiusKm: 14),
                   ad("weit", lat: 49.40, lon: 13.43, radiusKm: 12),
                   ad("überall")]
        let pool = AdCatalogService.pool(from: ads, courseID: nil, coordinate: passau)
        #expect(pool.map(\.id) == ["mittel"])
    }

    @Test("Fast gleich nahe Umkreise teilen sich den Platz")
    func nearestTies() {
        // Beide Ränder gut 20 km entfernt, Unterschied unter 5 km.
        let ads = [ad("nord", lat: 48.85, lon: 13.43, radiusKm: 10),
                   ad("süd", lat: 48.29, lon: 13.43, radiusKm: 9)]
        let pool = AdCatalogService.pool(from: ads, courseID: nil, coordinate: passau)
        #expect(Set(pool.map(\.id)) == ["nord", "süd"])
    }

    @Test("Ohne Umkreisanzeigen bleiben die allgemeinen")
    func everywhereFallback() {
        let ads = [ad("überall"), ad("anderer platz", courseID: "woanders")]
        let pool = AdCatalogService.pool(from: ads, courseID: "hier", coordinate: passau)
        #expect(pool.map(\.id) == ["überall"])
    }

    @Test("Ohne Koordinate des Platzes keine Umkreiswerbung")
    func noCoordinate() {
        let ads = [ad("umkreis", lat: 48.57, lon: 13.43, radiusKm: 50), ad("überall")]
        let pool = AdCatalogService.pool(from: ads, courseID: nil, coordinate: nil)
        #expect(pool.map(\.id) == ["überall"])
    }

    @Test("Ein Tipp führt auf die Zwischenseite der Website")
    func landingURL() {
        #expect(ad("abc").landingURL.absoluteString == "https://golftrack.app/werbung/abc")
    }
}
