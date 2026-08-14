import Foundation
import CoreLocation

// MARK: - Upload-fähiges Ergebnisformat

/// Ein Abschnitt entlang der Achse Abschlag→Grün mit den Querabweichungen,
/// die dort gemessen wurden.
///
/// Enthält bewusst **keine Zeit, keine Kennung und keine Einzelpunkte** –
/// nur Kennzahlen über mehrere Quellen. Damit ist die Struktur gleichzeitig
/// das Format, das später an einen Server gehen könnte.
struct FairwayBin: Codable, Hashable {
    /// Abschnitt entlang der Achse, 0 = am Abschlag.
    var index: Int
    /// Median der Querabweichung in Metern (+ = rechts der Achse).
    var centerOffset: Double
    /// 10. Perzentil der Querabweichung – linker Korridorrand.
    var leftOffset: Double
    /// 90. Perzentil – rechter Korridorrand.
    var rightOffset: Double
    /// Anzahl eingeflossener Messwerte.
    var sampleCount: Int

    var widthMeters: Double { rightOffset - leftOffset }
}

/// Der abgeleitete Fairway-Verlauf eines Lochs.
struct HoleCorridor: Codable, Identifiable, Hashable {
    var holeNumber: Int
    var teeLatitude: Double
    var teeLongitude: Double
    var greenLatitude: Double
    var greenLongitude: Double
    var binLengthMeters: Double
    var axisLengthMeters: Double
    var bins: [FairwayBin]
    /// Anzahl Runden, aus denen der Verlauf gerechnet wurde.
    var roundCount: Int

    var id: Int { holeNumber }

    // MARK: Geometrie (nicht Teil des Codable-Payloads)

    var tee: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: teeLatitude, longitude: teeLongitude)
    }
    var green: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: greenLatitude, longitude: greenLongitude)
    }

    /// Mittellinie des Fairways als Koordinatenkette.
    var centerline: [CLLocationCoordinate2D] {
        let frame = AxisFrame(tee: tee, green: green)
        return bins.map {
            frame.coordinate(axial: axialCenter(of: $0), lateral: $0.centerOffset)
        }
    }

    /// Korridor als geschlossenes Polygon (linke Kante hin, rechte Kante zurück).
    var corridorPolygon: [CLLocationCoordinate2D] {
        guard bins.count >= 2 else { return [] }
        let frame = AxisFrame(tee: tee, green: green)
        let left = bins.map { frame.coordinate(axial: axialCenter(of: $0), lateral: $0.leftOffset) }
        let right = bins.reversed().map { frame.coordinate(axial: axialCenter(of: $0), lateral: $0.rightOffset) }
        return left + right
    }

    private func axialCenter(of bin: FairwayBin) -> Double {
        (Double(bin.index) + 0.5) * binLengthMeters
    }

    // MARK: Kennzahlen

    var averageWidthMeters: Double {
        guard !bins.isEmpty else { return 0 }
        return bins.reduce(0) { $0 + $1.widthMeters } / Double(bins.count)
    }

    var totalSampleCount: Int { bins.reduce(0) { $0 + $1.sampleCount } }

    /// Anteil der Achse, für den überhaupt Messwerte vorliegen.
    var coverage: Double {
        guard axisLengthMeters > 0, binLengthMeters > 0 else { return 0 }
        let possible = max(1.0, (axisLengthMeters / binLengthMeters).rounded(.up))
        return min(1, Double(bins.count) / possible)
    }

    enum Reliability { case good, thin, veryThin }

    /// Grobe Belastbarkeit: eine einzelne Runde ist immer „sehr dünn" –
    /// eine Gehspur ist nicht das Fairway.
    var reliability: Reliability {
        if roundCount >= 5 && coverage >= 0.6 { return .good }
        if roundCount >= 3 && coverage >= 0.4 { return .thin }
        return .veryThin
    }
}

// MARK: - Lokales Meter-Koordinatensystem

/// Rechtwinkliges Hilfssystem entlang der Achse Abschlag→Grün.
/// `axial` = Meter Richtung Grün, `lateral` = Meter rechts der Achse.
struct AxisFrame {
    let originLat: Double
    let originLon: Double
    private let metersPerLat: Double
    private let metersPerLon: Double
    /// Einheitsvektor der Achse in Metern.
    private let ax: Double
    private let ay: Double
    let length: Double

    init(tee: CLLocationCoordinate2D, green: CLLocationCoordinate2D) {
        originLat = tee.latitude
        originLon = tee.longitude
        metersPerLat = 111_320.0
        metersPerLon = 111_320.0 * cos(tee.latitude * .pi / 180)

        let dx = (green.longitude - tee.longitude) * metersPerLon   // Ost
        let dy = (green.latitude  - tee.latitude)  * metersPerLat   // Nord
        let len = (dx * dx + dy * dy).squareRoot()
        length = len
        if len > 0 {
            ax = dx / len
            ay = dy / len
        } else {
            ax = 0
            ay = 1
        }
    }

    /// Projiziert eine Koordinate auf (axial, lateral).
    func project(_ coord: CLLocationCoordinate2D) -> (axial: Double, lateral: Double) {
        let dx = (coord.longitude - originLon) * metersPerLon
        let dy = (coord.latitude  - originLat) * metersPerLat
        let axial = dx * ax + dy * ay
        // Kreuzprodukt in 2D: positiv = rechts der Achse (in Blickrichtung Grün)
        let lateral = dx * ay - dy * ax
        return (axial, lateral)
    }

    /// Umkehrung – aus (axial, lateral) wieder eine Koordinate.
    func coordinate(axial: Double, lateral: Double) -> CLLocationCoordinate2D {
        let dx = ax * axial + ay * lateral
        let dy = ay * axial - ax * lateral
        return CLLocationCoordinate2D(latitude: originLat + dy / metersPerLat,
                                      longitude: originLon + dx / metersPerLon)
    }
}

// MARK: - Ableitung

/// Leitet aus Laufspuren und getrackten Schlägen den ungefähren Fairway-Verlauf
/// eines Lochs ab: Mittellinie plus Korridorbreite.
///
/// Verfahren: alle Messpunkte auf die Achse Abschlag→Grün projizieren, entlang
/// der Achse in Abschnitte einteilen und pro Abschnitt den Median der
/// Querabweichung (Mittellinie) sowie das 10./90. Perzentil (Korridorrand)
/// bilden. Doglegs ergeben sich dadurch von selbst.
///
/// **Grenzen des Verfahrens:** eine Gehspur ist nicht das Fairway – Spieler
/// laufen zu ihrem Ball, über Wege und ins Rough. Getrackte Ballpositionen sind
/// das deutlich bessere Signal und werden dreifach gewichtet. Aus einer einzigen
/// Runde entsteht deshalb bewusst nur ein Ergebnis mit Kennzeichnung
/// `reliability == .veryThin`.
enum FairwayCorridorInference {

    /// Länge eines Achsenabschnitts.
    static let binLength: Double = 10
    /// Abschnitte mit weniger Messwerten werden verworfen.
    static let minSamplesPerBin = 2
    /// Weniger Abschnitte → kein verwertbarer Verlauf.
    static let minBins = 3
    /// Querabweichungen darüber gehören zu einem anderen Loch, nicht ins Fairway.
    static let maxLateralMeters: Double = 60
    /// Für den Korridor strenger als beim Aufzeichnen.
    static let maxAccuracyMeters: Double = 15

    private enum Weight {
        /// Getrackte Ballposition – tatsächlich gespielter Punkt.
        static let ball: Double = 3
        /// Laufspur-Punkt.
        static let walk: Double = 1
    }

    // MARK: Öffentliche API

    /// Berechnet die Fairway-Verläufe aller Löcher eines Platzes, für die
    /// Abschlag- und Grünposition bekannt sind.
    ///
    /// Par-3-Löcher werden übersprungen – dort gibt es kein Fairway zu schätzen.
    static func corridors(for course: Course) -> [HoleCorridor] {
        // Laufspuren einmal dekodieren, nicht pro Loch erneut.
        let prepared = course.rounds.map(PreparedRound.init)
        return (1...max(1, course.numberOfHoles))
            .compactMap { corridor(forHole: $0, course: course, rounds: prepared) }
    }

    /// Gespeicherte Korridore, wenn sie zum aktuellen Datenstand passen – sonst
    /// frisch gerechnet. Schreibt nichts, ist also für Ansichten gedacht, die
    /// nur lesen wollen.
    static func currentCorridors(for course: Course) -> [HoleCorridor] {
        let tracked = course.rounds.filter { $0.track != nil }.count
        let stored = course.fairwayCorridors
        if !stored.isEmpty, stored.map(\.roundCount).max() == tracked { return stored }
        return corridors(for: course)
    }

    static func corridor(forHole hole: Int, course: Course) -> HoleCorridor? {
        corridor(forHole: hole, course: course, rounds: course.rounds.map(PreparedRound.init))
    }

    static func corridor(forHole hole: Int,
                         course: Course,
                         rounds: [PreparedRound]) -> HoleCorridor? {
        guard isFairwayHole(hole, course: course),
              let tee = course.teeCoordinate(forHole: hole),
              let green = course.flagCoordinate(forHole: hole) else { return nil }

        let frame = AxisFrame(tee: tee, green: green)
        guard frame.length >= 40 else { return nil }

        // Messwerte je Abschnitt sammeln: (Querabweichung, Gewicht)
        var buckets: [Int: [(value: Double, weight: Double)]] = [:]
        var contributingRounds = 0

        for prepared in rounds {
            var contributed = false

            // 1) Getrackte Ballpositionen – Abschlagpunkt und Auftreffpunkt jedes Schlags.
            for holeScore in prepared.round.holeScores where holeScore.holeNumber == hole {
                for shot in holeScore.sortedShots {
                    for coord in [shot.fromCoordinate, shot.toCoordinate] {
                        if add(coord, weight: Weight.ball, frame: frame, to: &buckets) {
                            contributed = true
                        }
                    }
                }
            }

            // 2) Laufspur.
            for point in prepared.points(forHole: hole)
            where point.isValid && point.accuracy <= maxAccuracyMeters {
                if add(point.coordinate, weight: Weight.walk, frame: frame, to: &buckets) {
                    contributed = true
                }
            }

            if contributed { contributingRounds += 1 }
        }

        // Abschnitte auswerten
        var bins: [FairwayBin] = buckets
            .filter { $0.value.count >= minSamplesPerBin }
            .map { index, samples in
                FairwayBin(index: index,
                           centerOffset: weightedPercentile(samples, 0.5),
                           leftOffset:   weightedPercentile(samples, 0.10),
                           rightOffset:  weightedPercentile(samples, 0.90),
                           sampleCount:  samples.count)
            }
            .sorted { $0.index < $1.index }

        guard bins.count >= minBins else { return nil }
        bins = smoothed(bins)
        bins = quantized(bins)

        return HoleCorridor(holeNumber: hole,
                            teeLatitude: tee.latitude,
                            teeLongitude: tee.longitude,
                            greenLatitude: green.latitude,
                            greenLongitude: green.longitude,
                            binLengthMeters: binLength,
                            axisLengthMeters: (frame.length * 10).rounded() / 10,
                            bins: bins,
                            roundCount: contributingRounds)
    }

    /// Par 3 hat kein Fairway – dort ist eine Korridorschätzung sinnlos.
    static func isFairwayHole(_ hole: Int, course: Course) -> Bool {
        let index = hole - 1
        guard index >= 0, index < course.parValues.count else { return false }
        return course.parValues[index] > 3
    }

    // MARK: Intern

    /// Projiziert und einsortiert. Gibt zurück, ob der Punkt verwertbar war.
    private static func add(_ coord: CLLocationCoordinate2D,
                            weight: Double,
                            frame: AxisFrame,
                            to buckets: inout [Int: [(value: Double, weight: Double)]]) -> Bool {
        guard CLLocationCoordinate2DIsValid(coord),
              coord.latitude.isFinite, coord.longitude.isFinite,
              !(coord.latitude == 0 && coord.longitude == 0) else { return false }

        let (axial, lateral) = frame.project(coord)
        // Nur zwischen Abschlag und Grün, seitlich begrenzt.
        guard axial >= 0, axial <= frame.length, abs(lateral) <= maxLateralMeters else { return false }

        let index = Int(axial / binLength)
        buckets[index, default: []].append((lateral, weight))
        return true
    }

    /// Gewichtetes Perzentil (0…1).
    static func weightedPercentile(_ samples: [(value: Double, weight: Double)], _ p: Double) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sorted = samples.sorted { $0.value < $1.value }
        let total = sorted.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return sorted[sorted.count / 2].value }
        let target = p * total
        var cumulative: Double = 0
        for sample in sorted {
            cumulative += sample.weight
            if cumulative >= target { return sample.value }
        }
        return sorted.last!.value
    }

    /// Gleitender Mittelwert über drei Abschnitte – sonst zappelt die Mittellinie.
    /// Nur benachbarte Abschnitte werden einbezogen, Lücken unterbrechen die Glättung.
    private static func smoothed(_ bins: [FairwayBin]) -> [FairwayBin] {
        guard bins.count >= 3 else { return bins }
        return bins.enumerated().map { position, bin in
            var neighbours = [bin]
            if position > 0, bins[position - 1].index == bin.index - 1 {
                neighbours.append(bins[position - 1])
            }
            if position < bins.count - 1, bins[position + 1].index == bin.index + 1 {
                neighbours.append(bins[position + 1])
            }
            let count = Double(neighbours.count)
            var result = bin
            result.centerOffset = neighbours.reduce(0) { $0 + $1.centerOffset } / count
            result.leftOffset   = neighbours.reduce(0) { $0 + $1.leftOffset } / count
            result.rightOffset  = neighbours.reduce(0) { $0 + $1.rightOffset } / count
            return result
        }
    }

    /// Auf Dezimeter runden. Feiner ist bei GPS-Genauigkeit ohnehin Scheingenauigkeit
    /// und würde einen späteren Upload unnötig unterscheidbar machen.
    private static func quantized(_ bins: [FairwayBin]) -> [FairwayBin] {
        bins.map { bin in
            var result = bin
            result.centerOffset = (bin.centerOffset * 10).rounded() / 10
            result.leftOffset   = (bin.leftOffset   * 10).rounded() / 10
            result.rightOffset  = (bin.rightOffset  * 10).rounded() / 10
            return result
        }
    }
}
