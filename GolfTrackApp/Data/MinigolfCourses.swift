import CoreLocation
import Foundation

/// Eine Minigolfanlage, die per QR-Code direkt eine Runde starten kann.
///
/// Die Einträge sind fest eingebaut (wie `BundledCourses`), damit der Start
/// nach dem Scannen ohne Netzwerk funktioniert – auch im App Clip.
struct MinigolfCourseEntry: Identifiable, Hashable {
    /// Stabile Kennung – steckt im QR-Code bzw. App-Clip-Link.
    /// Einmal gedruckt, darf sie sich nie mehr ändern.
    let id: String
    let name: String
    /// Ort für die Zeile unter dem Namen, z. B. „Sankt Englmar, Bayerischer Wald".
    let location: String
    /// Anzahl der Bahnen – wird beim Start direkt übernommen.
    let holes: Int
    let lat: Double
    let lon: Double
    /// Begrüßung auf dem Willkommensbildschirm nach dem Scan.
    let welcome: String
    /// Zusatzinfos (Ausleihe, Öffnungszeiten …). Leer = wird ausgeblendet.
    let notes: String

    init(id: String, name: String, location: String, holes: Int,
         lat: Double, lon: Double, welcome: String, notes: String = "") {
        self.id = id
        self.name = name
        self.location = location
        self.holes = holes
        self.lat = lat
        self.lon = lon
        self.welcome = welcome
        self.notes = notes
    }

    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lon) }
    var clLocation: CLLocation { CLLocation(latitude: lat, longitude: lon) }

    /// Link für den QR-Code an der Anlage (öffnet die installierte App).
    var startURL: URL { MinigolfDeepLink.url(for: id) }
    /// Universal Link – Ziel für den späteren App Clip.
    var webURL: URL { MinigolfDeepLink.webURL(for: id) }

    func distance(from userLocation: CLLocation) -> CLLocationDistance {
        clLocation.distance(from: userLocation)
    }
}

enum MinigolfCourses {

    static let all: [MinigolfCourseEntry] = [
        // Bahnenzahl und Koordinaten sind die Anlage im Ortskern; falls sich
        // etwas ändert, reicht eine Anpassung hier – der QR-Code bleibt gültig,
        // solange die `id` gleich bleibt.
        .init(id: "sankt-englmar",
              name: "Minigolf Sankt Englmar",
              location: "Sankt Englmar, Bayerischer Wald",
              holes: 18,
              lat: 48.9906, lon: 12.8114,
              welcome: "Servus in Sankt Englmar! Ab jetzt zählen wir für dich mit – Bahn für Bahn, Schlag für Schlag.",
              notes: "Schläger und Bälle gibt es vor Ort")
    ]

    static func course(id: String) -> MinigolfCourseEntry? {
        all.first { $0.id == id }
    }

    /// Nächstgelegene Anlage – für „Du stehst gerade hier"-Hinweise.
    static func nearest(to location: CLLocation, within meters: CLLocationDistance = 2_000) -> MinigolfCourseEntry? {
        all
            .map { ($0, $0.distance(from: location)) }
            .filter { $0.1 <= meters }
            .min { $0.1 < $1.1 }?
            .0
    }
}
