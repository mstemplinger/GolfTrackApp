import SwiftData
import Foundation

@Model
final class GolfBag {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \GolfClub.bag)
    var clubs: [GolfClub] = []

    init(name: String) {
        self.name = name
        self.createdAt = .now
    }

    var sortedClubs: [GolfClub] {
        clubs.sorted { $0.order < $1.order }
    }
}
