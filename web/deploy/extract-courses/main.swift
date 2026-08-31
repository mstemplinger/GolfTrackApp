import Foundation

// Schreibt die in der App eingebauten Plätze als JSON auf die Standardausgabe.
// Übersetzt wird gegen die echten Datendateien der App – so kann beim Abtippen
// nichts verrutschen. Aufruf über `deploy/extract-courses.sh`.
//
// Course- und Slope-Rating stehen in `BundledCourseEntry` mit den Vorgabewerten
// 72.0/113 da, wenn für den Platz keine Zahlen hinterlegt wurden. Solche
// Einträge – erkennbar daran, dass auch keine Par-Werte vorliegen – gehen ohne
// Rating in den Katalog, damit die Website keine erfundenen Zahlen zeigt.

let defaultCourseRating = 72.0
let defaultSlopeRating = 113

var out: [[String: Any]] = []

for c in BundledCourses.all {
    let ratingIsPlaceholder = c.parValues.isEmpty
        && c.courseRating == defaultCourseRating
        && c.slopeRating == defaultSlopeRating

    out.append([
        "kind": "golf",
        "name": c.name,
        "location": c.location,
        "holes": c.holes,
        "lat": c.lat,
        "lon": c.lon,
        "parValues": c.parValues,
        "hcpValues": c.hcpValues,
        "holeLengths": c.holeLengths,
        "courseRating": ratingIsPlaceholder ? NSNull() : c.courseRating,
        "slopeRating": ratingIsPlaceholder ? NSNull() : c.slopeRating,
        "facilityNotes": c.facilityNotes,
        "welcome": "",
        "teeLatitudes": c.teeLatitudes,
        "teeLongitudes": c.teeLongitudes,
        "flagLatitudes": c.flagLatitudes,
        "flagLongitudes": c.flagLongitudes,
    ])
}

for m in MinigolfCourses.all {
    // Die Kennung steckt in gedruckten QR-Codes – sie wird unverändert zum
    // Slug in der Datenbank, sonst laufen die Codes ins Leere.
    out.append([
        "kind": "minigolf",
        "slug": m.id,
        "name": m.name,
        "location": m.location,
        "holes": m.holes,
        "lat": m.lat,
        "lon": m.lon,
        "parValues": [Int](),
        "hcpValues": [Int](),
        "holeLengths": [Int](),
        "courseRating": NSNull(),
        "slopeRating": NSNull(),
        "facilityNotes": m.notes,
        "welcome": m.welcome,
        "teeLatitudes": [Double](),
        "teeLongitudes": [Double](),
        "flagLatitudes": [Double](),
        "flagLongitudes": [Double](),
    ])
}

let data = try JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted, .sortedKeys])
FileHandle.standardOutput.write(data)
FileHandle.standardOutput.write(Data("\n".utf8))
