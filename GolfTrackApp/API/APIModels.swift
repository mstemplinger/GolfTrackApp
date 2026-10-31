import Foundation

// MARK: - Search Response

struct APISearchResponse: Codable {
    let courses: [APICourse]
}

// MARK: - Course

struct APICourse: Codable, Identifiable {
    let id: Int
    let clubName: String
    let courseName: String?
    let location: APICourseLocation?
    let tees: APITees?

    enum CodingKeys: String, CodingKey {
        case id
        case clubName = "club_name"
        case courseName = "course_name"
        case location
        case tees
    }

    var displayName: String {
        guard let cn = courseName, !cn.isEmpty, cn != clubName else { return clubName }
        return "\(clubName) – \(cn)"
    }

    var locationString: String {
        var parts: [String] = []
        if let city = location?.city, !city.isEmpty { parts.append(city) }
        if let country = location?.country, !country.isEmpty { parts.append(country) }
        return parts.joined(separator: ", ")
    }

    // Returns hole par values from the best available tee box.
    func parValues(for teeBox: APITeeBox? = nil) -> [Int]? {
        let box = teeBox ?? preferredTeeBox()
        guard let holes = box?.holes, !holes.isEmpty else { return nil }
        let pars = holes.compactMap(\.par)
        return pars.isEmpty ? nil : pars
    }

    func preferredTeeBox() -> APITeeBox? {
        (tees?.male ?? tees?.female)?.first
    }

    var allTeeBoxes: [APITeeBox] {
        let male = tees?.male ?? []
        let female = tees?.female ?? []
        return male + female
    }

    /// Abschläge mit erkennbarer Farbe als `CourseTee` – je Farbe der erste
    /// (Herren vor Damen). Yards werden in Meter umgerechnet.
    var courseTees: [CourseTee] {
        var seen = Set<TeeColor>()
        return allTeeBoxes.compactMap { box in
            guard let color = box.teeColor, seen.insert(color).inserted else { return nil }
            let lengths = (box.holes ?? []).map { hole in
                hole.yardage.map { Int((Double($0) * 0.9144).rounded()) } ?? 0
            }
            return CourseTee(color: color, courseRating: box.courseRating,
                             slopeRating: box.slopeRating, holeLengths: lengths)
        }
    }
}

// MARK: - Location

struct APICourseLocation: Codable {
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
}

// MARK: - Tees

struct APITees: Codable {
    let female: [APITeeBox]?
    let male: [APITeeBox]?
}

// MARK: - TeeBox

struct APITeeBox: Codable, Identifiable {
    var id: String { teeName ?? "unknown" }

    /// Farbe aus dem Namen („Yellow“, „Gelb Herren“ …), nil wenn keine passt.
    var teeColor: TeeColor? {
        let name = (teeName ?? "").lowercased()
        let keywords: [(TeeColor, [String])] = [
            (.black, ["black", "schwarz"]), (.white, ["white", "weiß", "weiss"]),
            (.gold, ["gold"]), (.blue, ["blue", "blau"]), (.yellow, ["yellow", "gelb"]),
            (.red, ["red", "rot"]), (.orange, ["orange"]), (.green, ["green", "grün", "gruen"]),
        ]
        return keywords.first { _, words in words.contains { name.contains($0) } }?.0
    }
    let teeName: String?
    let numberOfHoles: Int?
    let parTotal: Int?
    let courseRating: Double?
    let slopeRating: Int?
    let holes: [APIHole]?

    enum CodingKeys: String, CodingKey {
        case teeName = "tee_name"
        case numberOfHoles = "number_of_holes"
        case parTotal = "par_total"
        case courseRating = "course_rating"
        case slopeRating = "slope_rating"
        case holes
    }
}

// MARK: - Hole

struct APIHole: Codable {
    let par: Int?
    let yardage: Int?
    let handicap: Int?
}
