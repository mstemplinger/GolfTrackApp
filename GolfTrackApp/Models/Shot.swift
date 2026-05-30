import SwiftData
import Foundation
import CoreLocation

@Model
final class Shot {
    var shotNumber: Int
    var fromLatitude: Double
    var fromLongitude: Double
    var toLatitude: Double
    var toLongitude: Double
    var distanceMeters: Double
    var club: String
    var holeScore: HoleScore?

    init(shotNumber: Int,
         from: CLLocationCoordinate2D,
         to: CLLocationCoordinate2D,
         club: String = "") {
        self.shotNumber = shotNumber
        self.fromLatitude = from.latitude
        self.fromLongitude = from.longitude
        self.toLatitude = to.latitude
        self.toLongitude = to.longitude
        self.club = club
        self.distanceMeters = Shot.haversineDistance(from: from, to: to)
    }

    var fromCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: fromLatitude, longitude: fromLongitude)
    }

    var toCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: toLatitude, longitude: toLongitude)
    }

    var distanceYards: Int { Int(distanceMeters * 1.09361) }
    var distanceMetersInt: Int { Int(distanceMeters) }

    static func haversineDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let loc2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return loc1.distance(from: loc2)
    }
}
