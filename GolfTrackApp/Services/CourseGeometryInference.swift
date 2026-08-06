import Foundation
import CoreLocation

// MARK: - Ergebnis pro Loch

/// Abgeleiteter Vorschlag für Abschlag- und Grünposition eines Lochs.
struct HoleGeometrySuggestion: Identifiable {
    var id: Int { holeNumber }
    let holeNumber: Int

    var tee: CLLocationCoordinate2D?
    var green: CLLocationCoordinate2D?

    /// 0…1 – wie belastbar der Vorschlag ist (Anzahl Quellen × Streuung × Plausibilität).
    var teeConfidence: Double = 0
    var greenConfidence: Double = 0

    /// Streuung der Einzelschätzungen um den Mittelwert, in Metern.
    var teeSpreadMeters: Double = 0
    var greenSpreadMeters: Double = 0

    /// Anzahl Runden, die zu diesem Loch etwas beigetragen haben.
    var roundCount: Int = 0

    /// Luftlinie Abschlag → Grün aus den abgeleiteten Positionen.
    var measuredLengthMeters: Double?
    /// Hinterlegte Lochlänge aus der Scorecard (falls vorhanden).
    var expectedLengthMeters: Int?

    /// Relative Abweichung der gemessenen von der hinterlegten Länge (0,15 = 15 %).
    var lengthDeviation: Double? {
        guard let measured = measuredLengthMeters,
              let expected = expectedLengthMeters, expected > 0 else { return nil }
        return abs(measured - Double(expected)) / Double(expected)
    }

    /// Falsch, wenn die abgeleitete Länge deutlich von der Scorecard abweicht.
    var isPlausible: Bool {
        guard let deviation = lengthDeviation else { return true }
        return deviation <= CourseGeometryInference.maxLengthDeviation
    }

    var hasUsableSuggestion: Bool { tee != nil || green != nil }

    enum ConfidenceLevel { case high, medium, low }

    /// Stufe statt fertigem Text – die Beschriftung gehört in die View,
    /// damit sie lokalisiert werden kann.
    var confidenceLevel: ConfidenceLevel {
        let value = min(teeConfidence, greenConfidence)
        if value >= 0.7 { return .high }
        if value >= 0.4 { return .medium }
        return .low
    }
}

// MARK: - Ableitung

/// Leitet aus aufgezeichneten Laufspuren und getrackten Schlägen die
/// Abschlag- und Grünpositionen der Löcher eines Platzes ab.
///
/// Grundidee: Ein Spieler steht am Abschlag still (Warten, Abschlagen) und am
/// Grün ebenfalls (Putten). Zwischen beidem bewegt er sich. Also ist der
/// **erste** längere Stillstand eines Loch-Segments der Abschlag und der
/// **letzte** das Grün. Getrackte Schläge und manuell gesetzte Pins sind
/// stärkere Signale und werden höher gewichtet.
enum CourseGeometryInference {

    /// Ab dieser relativen Abweichung von der Scorecard-Länge gilt ein Vorschlag als unplausibel.
    static let maxLengthDeviation: Double = 0.30

    /// Radius, innerhalb dessen Punkte als "am selben Ort" gelten.
    private static let clusterRadius: Double = 12
    /// So lange muss der Spieler stehen, damit es als Stillstand zählt.
    private static let teeStandDuration: TimeInterval = 30
    private static let greenStandDuration: TimeInterval = 25
    /// Einzelschätzungen, die weiter als das vom Median entfernt sind, fliegen raus.
    private static let outlierDistance: Double = 60

    // MARK: Gewichte der Quellen

    private enum Source {
        /// Manuell gesetzter Pin – der Nutzer hat ihn bewusst platziert.
        static let manualPin: Double = 3
        /// Getrackter Schlag (Abschlagpunkt / letzter Auftreffpunkt).
        static let shot: Double = 2
        /// Stillstands-Cluster aus der Laufspur.
        static let stationary: Double = 1
        /// Notfall: erster bzw. letzter Punkt des Segments.
        static let segmentEdge: Double = 0.4
    }

    private struct Candidate {
        let coordinate: CLLocationCoordinate2D
        let weight: Double
    }

    // MARK: - Öffentliche API

    /// Berechnet Vorschläge für alle Löcher eines Platzes aus den Runden, die
    /// eine Laufspur besitzen.
    static func suggestions(for course: Course) -> [HoleGeometrySuggestion] {
        let rounds = course.rounds.filter { $0.track != nil || !$0.holeScores.flatMap(\.shots).isEmpty }
        guard !rounds.isEmpty else { return [] }

        // Laufspuren einmal dekodieren, nicht pro Loch erneut.
        let prepared = rounds.map(PreparedRound.init)
        return (1...max(1, course.numberOfHoles)).map { hole in
            suggestion(forHole: hole, rounds: prepared, course: course)
        }
    }

    /// Schreibt alle Vorschläge mit ausreichender Konfidenz in den Platz.
    /// Gibt zurück, wie viele Löcher aktualisiert wurden.
    @discardableResult
    static func apply(_ suggestions: [HoleGeometrySuggestion],
                      to course: Course,
                      minConfidence: Double = 0.4,
                      requirePlausible: Bool = true) -> Int {
        var applied = 0
        for suggestion in suggestions {
            guard !requirePlausible || suggestion.isPlausible else { continue }
            var changed = false
            if let tee = suggestion.tee, suggestion.teeConfidence >= minConfidence {
                course.setTeeCoordinate(tee, forHole: suggestion.holeNumber)
                changed = true
            }
            if let green = suggestion.green, suggestion.greenConfidence >= minConfidence {
                course.setFlagCoordinate(green, forHole: suggestion.holeNumber)
                changed = true
            }
            if changed { applied += 1 }
        }
        return applied
    }

    // MARK: - Ein Loch

    private static func suggestion(forHole hole: Int,
                                   rounds: [PreparedRound],
                                   course: Course) -> HoleGeometrySuggestion {
        var result = HoleGeometrySuggestion(holeNumber: hole)
        let index = hole - 1
        if index >= 0, index < course.holeLengths.count, course.holeLengths[index] > 0 {
            result.expectedLengthMeters = course.holeLengths[index]
        }

        var teeCandidates: [Candidate] = []
        var greenCandidates: [Candidate] = []
        var contributingRounds = 0

        for prepared in rounds {
            var contributed = false
            let holeScore = prepared.round.holeScores.first { $0.holeNumber == hole }

            // 1) Manuell gesetzter Pin – stärkstes Signal für das Grün.
            //    Automatisch vorbefüllte Pins werden ignoriert, sonst würde die
            //    Ableitung ihr eigenes Ergebnis als Beweis verwenden.
            if holeScore?.pinIsAutomatic == false,
               let lat = holeScore?.pinLatitude, let lon = holeScore?.pinLongitude,
               let coord = validCoordinate(lat, lon) {
                greenCandidates.append(Candidate(coordinate: coord, weight: Source.manualPin))
                contributed = true
            }

            // 2) Getrackte Schläge.
            if let shots = holeScore?.sortedShots, !shots.isEmpty {
                if let coord = validCoordinate(shots[0].fromLatitude, shots[0].fromLongitude) {
                    teeCandidates.append(Candidate(coordinate: coord, weight: Source.shot))
                    contributed = true
                }
                if let last = shots.last,
                   let coord = validCoordinate(last.toLatitude, last.toLongitude) {
                    greenCandidates.append(Candidate(coordinate: coord, weight: Source.shot))
                    contributed = true
                }
            }

            // 3) Laufspur.
            do {
                let segment = prepared.points(forHole: hole).filter(\.isValid)

                if segment.count >= 2 {
                    contributed = true
                    if let tee = firstStationaryCluster(segment, minDuration: teeStandDuration) {
                        teeCandidates.append(Candidate(coordinate: tee, weight: Source.stationary))
                    } else if let first = segment.first {
                        teeCandidates.append(Candidate(coordinate: first.coordinate, weight: Source.segmentEdge))
                    }

                    if let green = lastStationaryCluster(segment, minDuration: greenStandDuration) {
                        greenCandidates.append(Candidate(coordinate: green, weight: Source.stationary))
                    } else if let last = segment.last {
                        greenCandidates.append(Candidate(coordinate: last.coordinate, weight: Source.segmentEdge))
                    }
                }
            }

            if contributed { contributingRounds += 1 }
        }

        result.roundCount = contributingRounds

        if let tee = combine(teeCandidates) {
            result.tee = tee.coordinate
            result.teeSpreadMeters = tee.spread
            result.teeConfidence = confidence(weight: tee.weight, spread: tee.spread)
        }
        if let green = combine(greenCandidates) {
            result.green = green.coordinate
            result.greenSpreadMeters = green.spread
            result.greenConfidence = confidence(weight: green.weight, spread: green.spread)
        }

        if let tee = result.tee, let green = result.green {
            result.measuredLengthMeters = CLLocation(latitude: tee.latitude, longitude: tee.longitude)
                .distance(from: CLLocation(latitude: green.latitude, longitude: green.longitude))
        }

        // Unplausible Längen halbieren die Konfidenz – der Vorschlag bleibt
        // sichtbar, wird aber nicht automatisch übernommen.
        if !result.isPlausible {
            result.teeConfidence *= 0.5
            result.greenConfidence *= 0.5
        }

        return result
    }

    // MARK: - Kandidaten zusammenfassen

    private static func combine(_ candidates: [Candidate])
        -> (coordinate: CLLocationCoordinate2D, weight: Double, spread: Double)? {
        guard !candidates.isEmpty else { return nil }

        // Ausreißer gegen den Median verwerfen (ein verirrter GPS-Fix im Wald
        // darf den Mittelwert nicht verschieben).
        let medianLat = median(candidates.map(\.coordinate.latitude))
        let medianLon = median(candidates.map(\.coordinate.longitude))
        let medianLocation = CLLocation(latitude: medianLat, longitude: medianLon)
        let kept = candidates.filter {
            CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
                .distance(from: medianLocation) <= outlierDistance
        }
        let usable = kept.isEmpty ? candidates : kept

        let totalWeight = usable.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return nil }
        let lat = usable.reduce(0) { $0 + $1.coordinate.latitude * $1.weight } / totalWeight
        let lon = usable.reduce(0) { $0 + $1.coordinate.longitude * $1.weight } / totalWeight
        let center = CLLocation(latitude: lat, longitude: lon)

        let spread: Double
        if usable.count > 1 {
            spread = usable.reduce(0) {
                $0 + CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
                    .distance(from: center)
            } / Double(usable.count)
        } else {
            spread = 0
        }

        return (CLLocationCoordinate2D(latitude: lat, longitude: lon), totalWeight, spread)
    }

    /// Konfidenz aus Quellengewicht und Streuung.
    /// Volle Punktzahl braucht Gewicht ≥ 3 (z. B. drei Laufspuren oder Schlag + Spur)
    /// und eine Streuung unter ~5 m.
    private static func confidence(weight: Double, spread: Double) -> Double {
        let weightFactor = min(1, weight / 3)
        let spreadFactor = max(0, 1 - spread / 40)
        return min(1, weightFactor * spreadFactor)
    }

    // MARK: - Stillstands-Cluster

    /// Erster Abschnitt, in dem der Spieler `minDuration` lang innerhalb von
    /// `clusterRadius` geblieben ist → Schwerpunkt dieses Abschnitts.
    private static func firstStationaryCluster(_ points: [TrackPoint],
                                               minDuration: TimeInterval) -> CLLocationCoordinate2D? {
        guard points.count >= 2 else { return nil }
        var start = 0
        while start < points.count {
            let anchor = points[start].location
            var end = start
            while end + 1 < points.count,
                  points[end + 1].location.distance(from: anchor) <= clusterRadius {
                end += 1
            }
            if points[end].timeOffset - points[start].timeOffset >= minDuration {
                return centroid(points[start...end])
            }
            start += 1
        }
        return nil
    }

    /// Analog vom Ende her – der letzte längere Stillstand (Putten am Grün).
    private static func lastStationaryCluster(_ points: [TrackPoint],
                                              minDuration: TimeInterval) -> CLLocationCoordinate2D? {
        guard points.count >= 2 else { return nil }
        var end = points.count - 1
        while end >= 0 {
            let anchor = points[end].location
            var start = end
            while start - 1 >= 0,
                  points[start - 1].location.distance(from: anchor) <= clusterRadius {
                start -= 1
            }
            if points[end].timeOffset - points[start].timeOffset >= minDuration {
                return centroid(points[start...end])
            }
            end -= 1
        }
        return nil
    }

    // MARK: - Kleinkram

    private static func centroid(_ points: ArraySlice<TrackPoint>) -> CLLocationCoordinate2D? {
        guard !points.isEmpty else { return nil }
        let count = Double(points.count)
        return CLLocationCoordinate2D(
            latitude: points.reduce(0) { $0 + $1.latitude } / count,
            longitude: points.reduce(0) { $0 + $1.longitude } / count
        )
    }

    private static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? (sorted[mid - 1] + sorted[mid]) / 2
            : sorted[mid]
    }

    private static func validCoordinate(_ lat: Double, _ lon: Double) -> CLLocationCoordinate2D? {
        guard lat.isFinite, lon.isFinite, !(lat == 0 && lon == 0) else { return nil }
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return CLLocationCoordinate2DIsValid(coord) ? coord : nil
    }
}
