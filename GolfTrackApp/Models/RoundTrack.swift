import SwiftData
import Foundation
import CoreLocation

// MARK: - Einzelner Trackpunkt

/// Ein GPS-Punkt der Laufspur einer Runde.
///
/// Wird nicht als eigenes `@Model` gespeichert – bei einer 18-Loch-Runde fallen
/// je nach Gehstrecke 2.000–3.000 Punkte an. Stattdessen liegen alle Punkte
/// einer Runde gepackt in `RoundTrack.pointData` (28 Byte pro Punkt).
struct TrackPoint: Hashable {
    var latitude: Double
    var longitude: Double
    /// Sekunden seit `RoundTrack.startedAt`
    var timeOffset: Double
    /// Horizontale Genauigkeit in Metern (`CLLocation.horizontalAccuracy`)
    var accuracy: Double
    /// Loch (1-basiert), zu dem der Punkt gehört. 0 = unbekannt.
    var holeNumber: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }

    var isValid: Bool {
        latitude.isFinite && longitude.isFinite &&
        CLLocationCoordinate2DIsValid(coordinate) &&
        !(latitude == 0 && longitude == 0)
    }
}

// MARK: - Binär-Codec

/// Packt `TrackPoint`s in ein kompaktes `Data`-Blob.
///
/// Layout pro Punkt (28 Byte, Little Endian der Host-Architektur):
/// `lat: Double (8) | lon: Double (8) | timeOffset: Float32 (4) | accuracy: Float32 (4) | hole: Int16 (2) | reserved: Int16 (2)`
///
/// Zeit und Genauigkeit als `Float32` sind völlig ausreichend (Auflösung < 1 s
/// bzw. < 1 m im relevanten Bereich), Koordinaten brauchen zwingend `Double`.
enum TrackPointCodec {

    static let recordSize = 28

    static func encode(_ points: [TrackPoint]) -> Data {
        var data = Data(capacity: points.count * recordSize)
        for point in points { append(point, to: &data) }
        return data
    }

    static func append(_ point: TrackPoint, to data: inout Data) {
        withUnsafeBytes(of: point.latitude)            { data.append(contentsOf: $0) }
        withUnsafeBytes(of: point.longitude)           { data.append(contentsOf: $0) }
        withUnsafeBytes(of: Float32(point.timeOffset)) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: Float32(point.accuracy))   { data.append(contentsOf: $0) }
        withUnsafeBytes(of: Int16(clamping: point.holeNumber)) { data.append(contentsOf: $0) }
        withUnsafeBytes(of: Int16(0))                  { data.append(contentsOf: $0) }
    }

    static func decode(_ data: Data) -> [TrackPoint] {
        let count = data.count / recordSize
        guard count > 0 else { return [] }
        return data.withUnsafeBytes { raw -> [TrackPoint] in
            (0..<count).map { i in
                let o = i * recordSize
                return TrackPoint(
                    latitude:   raw.loadUnaligned(fromByteOffset: o,      as: Double.self),
                    longitude:  raw.loadUnaligned(fromByteOffset: o + 8,  as: Double.self),
                    timeOffset: Double(raw.loadUnaligned(fromByteOffset: o + 16, as: Float32.self)),
                    accuracy:   Double(raw.loadUnaligned(fromByteOffset: o + 20, as: Float32.self)),
                    holeNumber: Int(raw.loadUnaligned(fromByteOffset: o + 24, as: Int16.self))
                )
            }
        }
    }
}

// MARK: - RoundTrack

/// Die aufgezeichnete Laufspur einer Runde. Wird nur angelegt, wenn der Nutzer
/// das Positions-Tracking in den Einstellungen aktiviert hat.
@Model
final class RoundTrack {
    var startedAt: Date = Date.now
    var endedAt: Date?
    /// Gepackte Trackpunkte – siehe `TrackPointCodec`.
    var pointData: Data = Data()
    /// Redundant zu `pointData.count / 28`, damit Listen ohne Dekodieren zählen können.
    var pointCount: Int = 0

    var round: Round?

    init(startedAt: Date = .now) {
        self.startedAt = startedAt
    }

    // MARK: Punkte

    var points: [TrackPoint] { TrackPointCodec.decode(pointData) }

    /// Hängt Punkte an das Blob an (billiger als das ganze Array neu zu kodieren).
    func append(_ newPoints: [TrackPoint]) {
        guard !newPoints.isEmpty else { return }
        var data = pointData
        for point in newPoints { TrackPointCodec.append(point, to: &data) }
        pointData = data
        pointCount = data.count / TrackPointCodec.recordSize
    }

    func points(forHole hole: Int) -> [TrackPoint] {
        points.filter { $0.holeNumber == hole }
    }

    /// Alle Punkte nach Loch gruppiert. Dekodiert das Blob **einmal** – wichtig
    /// für Auswertungen über alle Löcher, sonst wird pro Loch neu dekodiert.
    func pointsByHole() -> [Int: [TrackPoint]] {
        Dictionary(grouping: points, by: \.holeNumber)
    }

    /// Löcher, für die überhaupt Punkte vorliegen – aufsteigend.
    var recordedHoles: [Int] {
        Array(Set(points.map(\.holeNumber)).subtracting([0])).sorted()
    }

    // MARK: Kennzahlen

    var duration: TimeInterval {
        guard let endedAt else { return Date.now.timeIntervalSince(startedAt) }
        return endedAt.timeIntervalSince(startedAt)
    }

    /// Gelaufene Strecke in Metern (Summe der Punkt-zu-Punkt-Distanzen).
    var totalDistanceMeters: Double {
        let pts = points.filter(\.isValid)
        guard pts.count > 1 else { return 0 }
        var sum: Double = 0
        for i in 1..<pts.count {
            sum += pts[i].location.distance(from: pts[i - 1].location)
        }
        return sum
    }

    /// Grobe Speichergröße in KB – für die Anzeige in den Einstellungen.
    var storageKilobytes: Double { Double(pointData.count) / 1024.0 }
}

// MARK: - Vorbereitete Runde für Auswertungen

/// Runde samt einmal dekodierter, nach Loch gruppierter Laufspur.
///
/// Ohne diesen Zwischenschritt dekodiert jede Loch-Auswertung das komplette
/// Punkte-Blob erneut – bei 18 Löchern × 20 Runden merkbar auf dem Main Thread.
struct PreparedRound {
    let round: Round
    let pointsByHole: [Int: [TrackPoint]]

    init(_ round: Round) {
        self.round = round
        self.pointsByHole = round.track?.pointsByHole() ?? [:]
    }

    /// Zeitlich sortierte Punkte eines Lochs.
    func points(forHole hole: Int) -> [TrackPoint] {
        (pointsByHole[hole] ?? []).sorted { $0.timeOffset < $1.timeOffset }
    }
}
