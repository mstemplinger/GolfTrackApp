import SwiftUI
import MapKit
import CoreLocation

/// Richtet die Lochkarte so aus, dass der Spieler „das Loch hochschaut":
/// unten mittig der Ausgangspunkt (Abschlag, nach dem ersten Schlag die
/// eigene Position), oben mittig das Loch. Weitere Punkte – Fairway-Korridor,
/// Schläge, Laufspur – werden mit eingepasst, ohne die Achse zu verschieben.
enum HoleCameraFraming {

    /// Weiter als das vom Loch weg heißt: man steht nicht auf diesem Loch.
    /// Dann gilt wieder der Abschlag als unterer Punkt.
    static let maxPlayerDistance: CLLocationDistance = 1_200

    /// Verhältnis sichtbare Höhe (m) zu Kameraabstand (m) bei Neigung 0.
    /// MapKit rechnet mit rund 30° vertikalem Sichtfeld: 2 · tan(15°) ≈ 0,536.
    private static let heightPerDistance = 2 * tan(15 * Double.pi / 180)

    /// Unterer Punkt der Karte: vor dem ersten Schlag der Abschlag, danach
    /// die eigene Position – sofern man in der Nähe des Lochs steht.
    static func bottomPoint(tee: CLLocationCoordinate2D?,
                            hole: CLLocationCoordinate2D,
                            player: CLLocationCoordinate2D?,
                            hasPlayed: Bool) -> CLLocationCoordinate2D? {
        if hasPlayed, let player, distance(player, hole) <= maxPlayerDistance,
           distance(player, hole) > 15 {
            return player
        }
        return tee
    }

    /// Kamera mit Blickrichtung `bottom` → `top`. `bottom` liegt unten mittig,
    /// `top` oben mittig; `including` vergrößert nur den Ausschnitt.
    static func camera(bottom: CLLocationCoordinate2D,
                       top: CLLocationCoordinate2D,
                       including extra: [CLLocationCoordinate2D] = [],
                       viewSize: CGSize) -> MapCamera? {
        let frame = AxisFrame(tee: bottom, green: top)
        let length = frame.length
        guard length > 5, viewSize.width > 0, viewSize.height > 0 else { return nil }

        // Ausdehnung längs der Achse (symmetrisch um die Mitte, damit Abschlag
        // und Loch auf der Mittellinie bleiben) und quer dazu.
        let mid = length / 2
        var halfAxial = mid
        var halfLateral = 0.0
        for coord in extra {
            let p = frame.project(coord)
            halfAxial = max(halfAxial, abs(p.axial - mid))
            halfLateral = max(halfLateral, abs(p.lateral))
        }

        // Rand, damit Marker an den Enden nicht abgeschnitten werden.
        let neededHeight = halfAxial * 2 * 1.18 + 40
        let neededWidth = max(halfLateral * 2 * 1.15, 60)
        let aspect = viewSize.height / viewSize.width
        let visibleHeight = max(neededHeight, neededWidth * aspect)

        let center = frame.coordinate(axial: mid, lateral: 0)
        return MapCamera(centerCoordinate: center,
                         distance: visibleHeight / heightPerDistance,
                         heading: heading(from: bottom, to: top),
                         pitch: 0)
    }

    /// Kompasskurs in Grad (0 = Nord, 90 = Ost).
    static func heading(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> CLLocationDirection {
        let lat1 = a.latitude * .pi / 180, lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let deg = atan2(y, x) * 180 / .pi
        return (deg + 360).truncatingRemainder(dividingBy: 360)
    }

    static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }
}

/// Liefert die aktuelle Position fortlaufend, solange die Ansicht sichtbar ist.
/// Kleine Bewegungen (< `minimumMove`) werden verschluckt, damit die Karte
/// nicht bei jedem GPS-Zittern neu ausgerichtet wird.
struct LivePlayerLocation: ViewModifier {
    @Binding var location: CLLocationCoordinate2D?
    var minimumMove: CLLocationDistance = 8

    func body(content: Content) -> some View {
        content.task {
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    guard let loc = update.location, loc.horizontalAccuracy >= 0,
                          loc.horizontalAccuracy <= 40 else { continue }
                    let coord = loc.coordinate
                    if let old = location, HoleCameraFraming.distance(old, coord) < minimumMove { continue }
                    location = coord
                }
            } catch {
                // Kein Standort – die Karte bleibt beim Abschlag.
            }
        }
    }
}

extension View {
    func livePlayerLocation(_ location: Binding<CLLocationCoordinate2D?>) -> some View {
        modifier(LivePlayerLocation(location: location))
    }
}
