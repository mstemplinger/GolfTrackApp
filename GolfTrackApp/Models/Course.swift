import SwiftData
import Foundation
import CoreLocation

@Model
final class Course {
    var name: String
    var location: String
    var numberOfHoles: Int
    var parValues: [Int]
    /// Course Rating (CR) – Wert des Platzes für den Scratch-Spieler, z.B. 72.4
    var courseRating: Double = 72.0
    /// Slope Rating – Schwierigkeitsgrad für Bogey-Spieler, Standard = 113
    var slopeRating: Int = 113
    /// HCP-Reihenfolge (Stroke Index) pro Loch – 1-basiert, Länge = numberOfHoles
    var hcpValues: [Int] = []
    /// Lochlängen in Metern (Standard-Abschlag) – Länge = numberOfHoles
    var holeLengths: [Int] = []
    /// Zusätzliche Platzinformationen (Toiletten, Defibrillator, Wasserstellen usw.)
    var facilityNotes: String = ""
    /// GPS-Koordinaten des Platzmittelpunkts (für Distanzanzeige in der Liste)
    var latitude: Double?
    var longitude: Double?

    // MARK: – Loch-genaue GPS-Positionen
    /// Abschlag-Koordinaten: flat array [lat1, lon1, lat2, lon2, …] – Länge = numberOfHoles * 2
    var teeLatitudes:  [Double] = []
    var teeLongitudes: [Double] = []
    /// Fahnen-Koordinaten: flat array [lat1, lon1, lat2, lon2, …] – Länge = numberOfHoles * 2
    var flagLatitudes:  [Double] = []
    var flagLongitudes: [Double] = []

    @Relationship(deleteRule: .nullify, inverse: \Round.course)
    var rounds: [Round] = []

    init(name: String, location: String = "", numberOfHoles: Int = 18,
         parValues: [Int]? = nil, courseRating: Double = 72.0, slopeRating: Int = 113,
         hcpValues: [Int] = [], holeLengths: [Int] = [], facilityNotes: String = "",
         latitude: Double? = nil, longitude: Double? = nil,
         teeLatitudes: [Double] = [], teeLongitudes: [Double] = [],
         flagLatitudes: [Double] = [], flagLongitudes: [Double] = []) {
        self.name = name
        self.location = location
        self.numberOfHoles = numberOfHoles
        self.parValues = parValues ?? Course.defaultPars(for: numberOfHoles)
        self.courseRating = courseRating
        self.slopeRating = slopeRating
        self.hcpValues = hcpValues
        self.holeLengths = holeLengths
        self.facilityNotes = facilityNotes
        self.latitude = latitude
        self.longitude = longitude
        self.teeLatitudes  = teeLatitudes
        self.teeLongitudes = teeLongitudes
        self.flagLatitudes  = flagLatitudes
        self.flagLongitudes = flagLongitudes
    }

    // MARK: – Hilfsmethoden Lochpositionen

    /// True wenn für alle Löcher Abschlag- und Fahnen-GPS gespeichert sind.
    var hasHolePositions: Bool {
        teeLatitudes.count  == numberOfHoles &&
        teeLongitudes.count == numberOfHoles &&
        flagLatitudes.count  == numberOfHoles &&
        flagLongitudes.count == numberOfHoles
    }

    /// Abschlag-Koordinate für Loch `hole` (1-basiert), oder nil wenn nicht vorhanden.
    func teeCoordinate(forHole hole: Int) -> CLLocationCoordinate2D? {
        let i = hole - 1
        guard i >= 0, i < teeLatitudes.count, i < teeLongitudes.count else { return nil }
        return CLLocationCoordinate2D(latitude: teeLatitudes[i], longitude: teeLongitudes[i])
    }

    /// Fahnen-Koordinate für Loch `hole` (1-basiert), oder nil wenn nicht vorhanden.
    func flagCoordinate(forHole hole: Int) -> CLLocationCoordinate2D? {
        let i = hole - 1
        guard i >= 0, i < flagLatitudes.count, i < flagLongitudes.count else { return nil }
        return CLLocationCoordinate2D(latitude: flagLatitudes[i], longitude: flagLongitudes[i])
    }

    /// Distanz von `location` zur Fahne von Loch `hole` in Metern, oder nil.
    func distanceToFlag(hole: Int, from location: CLLocation) -> CLLocationDistance? {
        guard let coord = flagCoordinate(forHole: hole) else { return nil }
        return CLLocation(latitude: coord.latitude, longitude: coord.longitude).distance(from: location)
    }

    /// Distanz von `location` zum Abschlag von Loch `hole` in Metern, oder nil.
    func distanceToTee(hole: Int, from location: CLLocation) -> CLLocationDistance? {
        guard let coord = teeCoordinate(forHole: hole) else { return nil }
        return CLLocation(latitude: coord.latitude, longitude: coord.longitude).distance(from: location)
    }

    // MARK: – Platzmittelpunkt

    /// Distance from user location in meters, or nil if coordinates are missing.
    func distance(from userLocation: CLLocation) -> CLLocationDistance? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocation(latitude: lat, longitude: lon).distance(from: userLocation)
    }

    var totalPar: Int { parValues.reduce(0, +) }

    static func defaultPars(for holes: Int) -> [Int] {
        let pattern: [Int] = [4, 4, 3, 4, 5, 4, 3, 4, 5]
        return (0..<holes).map { pattern[$0 % 9] }
    }
}
