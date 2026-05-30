import CoreLocation

struct BundledCourseEntry: Identifiable {
    let name: String
    let location: String
    let holes: Int
    let lat: Double
    let lon: Double
    /// Par-Werte pro Loch (Reihenfolge 1–18)
    let parValues: [Int]
    /// HCP-Reihenfolge (Stroke Index) pro Loch
    let hcpValues: [Int]
    /// Lochlängen in Metern (Standard-Abschlag / Gelb)
    let holeLengths: [Int]
    /// Course Rating
    let courseRating: Double
    /// Slope Rating
    let slopeRating: Int
    /// Zusätzliche Platzinfos (Toiletten, Defibrillator, Wasserstellen usw.)
    let facilityNotes: String
    /// Abschlag-Koordinaten, 1 Eintrag pro Loch (gleiche Reihenfolge)
    let teeLatitudes:  [Double]
    let teeLongitudes: [Double]
    /// Fahnen-Koordinaten, 1 Eintrag pro Loch (gleiche Reihenfolge)
    let flagLatitudes:  [Double]
    let flagLongitudes: [Double]

    var id: String { name }

    init(name: String, location: String, holes: Int, lat: Double, lon: Double,
         parValues: [Int] = [], hcpValues: [Int] = [], holeLengths: [Int] = [],
         courseRating: Double = 72.0, slopeRating: Int = 113, facilityNotes: String = "",
         teeLatitudes:  [Double] = [], teeLongitudes: [Double] = [],
         flagLatitudes:  [Double] = [], flagLongitudes: [Double] = []) {
        self.name = name
        self.location = location
        self.holes = holes
        self.lat = lat
        self.lon = lon
        self.parValues = parValues
        self.hcpValues = hcpValues
        self.holeLengths = holeLengths
        self.courseRating = courseRating
        self.slopeRating = slopeRating
        self.facilityNotes = facilityNotes
        self.teeLatitudes  = teeLatitudes
        self.teeLongitudes = teeLongitudes
        self.flagLatitudes  = flagLatitudes
        self.flagLongitudes = flagLongitudes
    }

    var clLocation: CLLocation { CLLocation(latitude: lat, longitude: lon) }

    func distance(from userLocation: CLLocation) -> CLLocationDistance {
        clLocation.distance(from: userLocation)
    }

    func formattedDistance(from userLocation: CLLocation) -> String {
        let km = distance(from: userLocation) / 1000
        if km < 1 { return "< 1 km" }
        if km < 10 { return String(format: "%.1f km", km) }
        return String(format: "%.0f km", km)
    }
}

enum BundledCourses {

    static let all: [BundledCourseEntry] = [

        // ── Passau & unmittelbare Umgebung (< 35 km) ──────────────────
        .init(name: "Donau-Golf-Club Passau-Raßbach e.V.", location: "Thyrnau (Raßbach), Bayern",
              holes: 18, lat: 48.608, lon: 13.552,
              parValues: [4, 3, 5, 3, 5, 4, 3, 4, 4,   // OUT 35
                          4, 3, 5, 3, 4, 4, 4, 5, 5],   // IN 37  → Par 72
              hcpValues: [9, 13, 5, 15, 1, 3, 17, 11, 7,
                          16, 12, 6, 14, 4, 18, 2, 10, 8],
              holeLengths: [350, 185, 474, 141, 475, 372, 139, 318, 354,   // OUT 2808
                            244, 142, 431, 130, 304, 318, 308, 450, 433],  // IN 2760 → 5568 m
              courseRating: 70.4, slopeRating: 135,
              facilityNotes: """
              Platzregeln DGV – Aushang am Sekretariat
              Hunde erlaubt (an der Leine)
              Restaurant "Leo's" im Hotel Anetseder am Clubhaus
              Kontakt: www.golf-passau.de
              """,
              // ⚠️ Lochpositionen: Näherungswerte – mit echten GPS-Messungen vor Ort ersetzen
              teeLatitudes:  [48.6148, 48.6115, 48.6082, 48.6068, 48.6040, 48.5995, 48.5993, 48.6012, 48.6042,
                               48.6094, 48.6114, 48.6140, 48.6154, 48.6153, 48.6146, 48.6138, 48.6120, 48.6126],
              teeLongitudes: [13.5455, 13.5488, 13.5506, 13.5531, 13.5551, 13.5561, 13.5512, 13.5495, 13.5470,
                               13.5449, 13.5409, 13.5382, 13.5405, 13.5461, 13.5525, 13.5581, 13.5598, 13.5542],
              flagLatitudes:  [48.6118, 48.6085, 48.6070, 48.6042, 48.5998, 48.5995, 48.6010, 48.6040, 48.6092,
                                48.6112, 48.6138, 48.6152, 48.6155, 48.6148, 48.6140, 48.6122, 48.6128, 48.6122],
              flagLongitudes: [13.5485, 13.5503, 13.5528, 13.5548, 13.5558, 13.5515, 13.5498, 13.5472, 13.5452,
                                13.5412, 13.5385, 13.5402, 13.5458, 13.5522, 13.5578, 13.5595, 13.5545, 13.5480]),
        // ⚠️ Lochpositionen: Näherungswerte – mit echten GPS-Messungen vor Ort ersetzen
        .init(name: "Golfclub Tittling", location: "Tittling, Bayern",
              holes: 9, lat: 48.704, lon: 13.388,
              teeLatitudes:  [48.7068, 48.7040, 48.7013, 48.7020, 48.7047, 48.7085, 48.7090, 48.7070, 48.7056],
              teeLongitudes: [13.3852, 13.3881, 13.3898, 13.3923, 13.3941, 13.3922, 13.3869, 13.3852, 13.3805],
              flagLatitudes:  [48.7042, 48.7015, 48.7018, 48.7045, 48.7082, 48.7092, 48.7072, 48.7058, 48.7068],
              flagLongitudes: [13.3878, 13.3895, 13.3920, 13.3938, 13.3925, 13.3872, 13.3855, 13.3808, 13.3855]),
        .init(name: "Panorama Golf Passau", location: "Fürstenzell, Bayern",
              holes: 18, lat: 48.516, lon: 13.323,
              parValues: [5, 4, 3, 4, 5, 4, 4, 4, 4,   // OUT 37
                          3, 5, 5, 4, 4, 3, 4, 4, 4],   // IN 36  → Par 73
              hcpValues: [3, 5, 13, 11, 7, 9, 1, 15, 17,
                          16, 6, 8, 12, 14, 18, 10, 4, 2],
              holeLengths: [476, 360, 173, 347, 456, 342, 367, 323, 268,   // OUT 3112
                            170, 486, 501, 352, 319, 148, 357, 367, 364],  // IN 3064 → 6176 m
              courseRating: 72.6, slopeRating: 137,
              facilityNotes: """
              Feng-Shui-Golfplatz (einziger in Deutschland)
              Driving Range · 6-Loch-Kurzplatz
              Sekretariat: tägl. 10–16 Uhr · Tel. +49 8502 917160
              """),
        .init(name: "Golf- und Landclub Bayerwald e.V.",
              location: "Jandelsbrunn, Bayern",
              holes: 18,
              lat: 48.6555, lon: 13.5890,
              // Par pro Loch (Löcher 1–18)
              parValues: [4, 4, 3, 4, 4, 5, 5, 3, 4,   // OUT
                          4, 3, 5, 3, 5, 4, 4, 4, 4],   // IN
              // HCP-Reihenfolge (Stroke Index) pro Loch
              hcpValues: [10, 14, 17, 12, 7, 4, 8, 16, 3,   // OUT
                          11, 18,  2, 13, 1, 9, 6, 15, 5],  // IN
              // Lochlängen in Metern (Gelb-Abschlag, 5533 m gesamt)
              holeLengths: [340, 232, 135, 338, 315, 441, 443, 162, 359,   // OUT 2765
                            327, 137, 448, 174, 440, 303, 334, 263, 342],  // IN 2768
              courseRating: 70.4, slopeRating: 125,
              facilityNotes: """
              Toiletten: Tee 7 · Tee 10 · Grün 14
              Trinkwasser: zwischen Grün 7/Abschlag 8 und Grün 14/Abschlag 15
              Herzdefibrillator: Sekretariat (Tel. 08581/1040)
              Entfernungsmarkierungen: 2 weiße Ringe = 150 m bis Grünbeginn · 1 weißer Ring = 100 m bis Grünbeginn
              Biotope dürfen nicht betreten werden! (Platzverweis/Turniersperre)
              Platzregeln: Lochspiel – Lochverlust · Zählspiel – 2 Strafschläge (Aushang am Sekretariat)
              Kontakt: info@gc-bayerwald.de · www.gc-bayerwald.de · Tel. +49 8581 1040
              """),
        .init(name: "Golfclub Vilshofen",                        location: "Vilshofen an der Donau, Bayern",        holes:  9, lat: 48.628, lon: 13.187),
        .init(name: "Celtic Golf Course Schärding", location: "Taufkirchen an der Pram, Oberösterreich",
              holes: 18, lat: 48.374, lon: 13.518,
              parValues: [5, 5, 4, 4, 4, 3, 4, 4, 3,   // OUT 36
                          4, 4, 4, 4, 4, 4, 4, 5, 3],   // IN 36  → Par 72
              hcpValues: [9, 11, 13, 15, 3, 5, 7, 1, 17,
                          14, 4, 2, 16, 10, 8, 12, 6, 18],
              holeLengths: [518, 499, 378, 367, 394, 172, 369, 389, 153,   // OUT 3239
                            362, 440, 413, 350, 351, 413, 344, 540, 145],  // IN 3358 → 6597 m
              courseRating: 70.4, slopeRating: 120,
              facilityNotes: """
              7 Fairways umgeben einen Teichkomplex
              6-Loch-Akademie-Kurzplatz (Josko Golf) vorhanden
              Handicap-Nachweis erforderlich
              Kontakt: sekretariat@golfclub-schaerding.at · Tel. 07719-8110
              """),
        .init(name: "Golfclub Pfarrkirchen im Mühlkreis", location: "Pfarrkirchen im Mühlkreis, OÖ",
              holes: 9, lat: 48.478, lon: 14.030,
              parValues: [3, 4, 4, 3, 4, 4, 5, 4, 3],  // Par 34 (9 Loch)
              hcpValues: [3, 17, 9, 15, 5, 7, 11, 1, 13],
              holeLengths: [142, 272, 369, 161, 315, 363, 471, 294, 144],  // 2531 m
              courseRating: 66.3, slopeRating: 128,
              facilityNotes: """
              9-Loch-Platz auf 800 m Höhe im Mühlviertel
              Zusätzlich 4-Loch-Par-3-Übungsanlage
              Kontakt: office@gcpfarrkirchen.at · Tel. +43 7285 6420
              """),

        // ── Bad Griesbach Resort (24–30 km) ───────────────────────────
        .init(name: "Golfclub Sagmühle e.V.", location: "Bad Griesbach im Rottal, Bayern",
              holes: 18, lat: 48.432, lon: 13.189,
              parValues: [4, 4, 5, 3, 4, 5, 4, 4, 3,   // OUT 36
                          4, 3, 5, 4, 4, 3, 5, 4, 4],   // IN 36  → Par 72
              hcpValues: [5, 7, 9, 15, 13, 11, 1, 3, 17,
                          18, 16, 12, 2, 4, 14, 8, 10, 6],
              holeLengths: [349, 355, 463, 155, 320, 436, 345, 338, 125,   // OUT 2886
                            295, 165, 470, 364, 397, 178, 523, 322, 355],  // IN 3069 → 5955 m
              courseRating: 72.6, slopeRating: 128,
              facilityNotes: """
              Flacher Platz, kurze Wege zwischen Abschlägen
              Zahlreiche Wasserhindernisse und alte Bäume
              Architekt: Kurt Rossknecht (1987)
              Kontakt: www.sagmuehle.de
              """),
        .init(name: "Quellness Golf — Lederbach", location: "Bad Griesbach im Rottal, Bayern",
              holes: 18, lat: 48.444, lon: 13.196,
              parValues: [4, 3, 5, 4, 4, 3, 5, 4, 4,   // OUT 36
                          4, 3, 5, 4, 3, 4, 3, 5, 4],   // IN 35  → Par 71
              hcpValues: [5, 15, 7, 13, 3, 9, 17, 11, 1,
                          4, 18, 6, 12, 14, 10, 16, 8, 2],
              holeLengths: [369, 139, 515, 271, 333, 158, 467, 315, 377,   // OUT 2944
                            345, 139, 485, 260, 179, 370, 132, 472, 373],  // IN 2755 → 5699 m
              courseRating: 70.8, slopeRating: 133,
              facilityNotes: """
              Platzregeln DGV – Hunde an der Leine erlaubt
              Wetterschutzhütten vorhanden
              Kontakt: Tel. 08532/3135 · www.quellness-golf.com
              """),
        .init(name: "Quellness Golf — Brunnwies", location: "Haarbach, Bayern",
              holes: 18, lat: 48.474, lon: 13.218,
              parValues: [4, 4, 3, 4, 4, 3, 5, 3, 4,   // OUT 34
                          5, 4, 4, 5, 3, 5, 4, 3, 4],   // IN 37  → Par 71
              hcpValues: [11, 5, 15, 7, 1, 17, 9, 13, 3,
                          12, 10, 8, 2, 18, 6, 14, 16, 4],
              holeLengths: [304, 383, 180, 315, 359, 130, 490, 167, 347,   // OUT 2675
                            494, 336, 349, 372, 155, 439, 314, 180, 389],  // IN 3028 → 5703 m
              courseRating: 70.9, slopeRating: 132,
              facilityNotes: """
              Wetterschutzhütten vorhanden
              Architekt: Rico Gullmeister
              Kontakt: Tel. 08535/96010 · www.quellness-golf.com
              """),
        .init(name: "Quellness Golf — Uttlau", location: "Haarbach, Bayern",
              holes: 18, lat: 48.460, lon: 13.207,
              parValues: [4, 5, 4, 3, 4, 4, 4, 5, 3,   // OUT 36
                          4, 3, 5, 4, 3, 4, 5, 3, 5],   // IN 36  → Par 72
              hcpValues: [7, 11, 1, 13, 15, 3, 9, 5, 17,
                          6, 16, 8, 10, 18, 2, 12, 14, 4],
              holeLengths: [284, 519, 370, 190, 324, 327, 371, 468, 117,   // OUT 2970
                            375, 145, 440, 273, 119, 376, 454, 191, 475],  // IN 2848 → 5818 m
              courseRating: 71.9, slopeRating: 136,
              facilityNotes: """
              Wetterschutzhütten vorhanden
              Gutshof Uttlau: Tel. 08535/1890
              Kontakt: Tel. 08535/18949 · www.quellness-golf.com
              """),
        .init(name: "Quellness Golf — Beckenbauer Course", location: "Rotthalmünster, Bayern",
              holes: 18, lat: 48.357, lon: 13.203,
              parValues: [4, 4, 5, 3, 4, 4, 3, 5, 4,   // OUT 36
                          5, 4, 5, 4, 3, 4, 4, 3, 4],   // IN 36  → Par 72
              hcpValues: [5, 3, 15, 17, 1, 9, 11, 13, 7,
                          10, 8, 4, 12, 18, 6, 16, 14, 2],
              holeLengths: [362, 320, 481, 182, 407, 345, 192, 494, 328,   // OUT 3111
                            448, 328, 479, 331, 148, 382, 301, 150, 400],  // IN 2967 → 6078 m
              courseRating: 73.1, slopeRating: 127,
              facilityNotes: """
              Design: Bernhard Langer
              Wetterschutzhütten vorhanden
              Gutshof Penning: Tel. 08532/92660
              Kontakt: Tel. 08532/92440 · www.quellness-golf.com
              """),
        .init(name: "Quellness Golf — Porsche Course", location: "Rotthalmünster, Bayern",
              holes: 18, lat: 48.360, lon: 13.210,
              parValues: [4, 5, 4, 4, 3, 4, 3, 5, 3,   // OUT 35
                          4, 5, 4, 3, 4, 5, 4, 3, 4],   // IN 36  → Par 71
              hcpValues: [7, 9, 5, 3, 11, 1, 15, 13, 17,
                          14, 8, 18, 12, 6, 10, 4, 16, 2],
              holeLengths: [385, 461, 336, 423, 199, 399, 156, 464, 152,   // OUT 2975
                            348, 459, 315, 158, 373, 497, 355, 171, 429],  // IN 3105 → 6080 m
              courseRating: 71.1, slopeRating: 129,
              facilityNotes: """
              Design: Bernhard Langer (2003)
              Breitere Fairways mit Wasser- und Bunkerhindernissen
              Kontakt: Tel. 08532/7900 · www.quellness-golf.com
              """),
        .init(name: "Golfodrom Bad Griesbach — Jagl", location: "Bad Griesbach im Rottal, Bayern",
              holes: 9, lat: 48.452, lon: 13.183,
              parValues: [3, 3, 3, 3, 3, 3, 3, 3, 3],  // Par 27
              hcpValues: [17, 15, 9, 11, 1, 3, 5, 7, 13],
              holeLengths: [80, 91, 156, 133, 153, 240, 139, 127, 104],   // 1223 m
              courseRating: 58.8, slopeRating: 105,
              facilityNotes: """
              9-Loch-Par-3-Kurzplatz · öffentlich zugänglich
              Architekt: Kurt Rossknecht (1989)
              Kontakt: Tel. 08532/7900 · www.quellness-golf.com
              """),
        .init(name: "Golfodrom Bad Griesbach — Engled", location: "Bad Griesbach im Rottal, Bayern",
              holes: 9, lat: 48.453, lon: 13.185,
              parValues: [3, 3, 3, 4, 3, 3, 4, 3, 4],  // Par 30
              hcpValues: [9, 11, 15, 1, 17, 13, 5, 7, 3],
              holeLengths: [156, 166, 120, 295, 115, 136, 284, 143, 272],  // 1687 m
              facilityNotes: """
              9-Loch-Kurzplatz (Par 3 + Par 4) · öffentlich zugänglich
              Kontakt: Tel. 08532/7900 · www.quellness-golf.com
              """),
        .init(name: "Golfodrom Bad Griesbach — Pfeiffer", location: "Bad Griesbach im Rottal, Bayern",
              holes: 9, lat: 48.454, lon: 13.182,
              parValues: [3, 3, 3, 3, 3, 3, 3, 3, 3],  // Par 27
              hcpValues: [1, 9, 5, 15, 13, 7, 3, 11, 17],
              holeLengths: [152, 116, 127, 96, 109, 120, 127, 113, 94],   // 1054 m
              facilityNotes: """
              9-Loch-Par-3-Kurzplatz (kürzester Golfodrom-Platz) · öffentlich zugänglich
              Kontakt: Tel. 08532/7900 · www.quellness-golf.com
              """),

        // ── Niederbayern — Rottal / Inn / Vilstal ─────────────────────
        .init(name: "ThermenGolfClub Bad Füssing-Kirchham", location: "Bad Füssing, Bayern",
              holes: 18, lat: 48.350, lon: 13.311,
              parValues: [4, 4, 5, 4, 4, 3, 5, 3, 4,   // OUT 36
                          5, 3, 4, 4, 4, 3, 4, 5, 4],   // IN 36  → Par 72
              hcpValues: [7, 3, 9, 15, 13, 11, 5, 17, 1,
                          12, 18, 6, 2, 4, 14, 10, 8, 16],
              holeLengths: [361, 396, 507, 375, 348, 164, 581, 184, 453,   // OUT 3369
                            540, 130, 411, 358, 383, 151, 417, 526, 339],  // IN 3255 → 6624 m
              courseRating: 71.3, slopeRating: 124,
              facilityNotes: """
              Parklandplatz · Architekt: Peter Harradine (2001)
              Erlbach als Wasserhindernis
              Kontakt: www.thermengolf.de
              """),
        .init(name: "Bella Vista Golfpark Bad Birnbach", location: "Bad Birnbach, Bayern",
              holes: 18, lat: 48.407, lon: 13.082,
              parValues: [4, 5, 4, 3, 4, 5, 4, 3, 4,   // OUT 36
                          4, 3, 4, 4, 3, 5, 4, 5, 4],   // IN 36  → Par 72
              hcpValues: [5, 11, 17, 15, 7, 9, 3, 13, 1,
                          14, 10, 16, 6, 18, 8, 12, 4, 2],
              holeLengths: [332, 453, 307, 185, 340, 483, 328, 163, 359,   // OUT 2950
                            310, 199, 317, 363, 148, 477, 350, 495, 399],  // IN 3058 → 6008 m
              courseRating: 70.8, slopeRating: 139,
              facilityNotes: """
              18-Loch-Meisterschaftsanlage · teils hügeliges Gelände
              Kontakt: www.badbirnbach.de/bella-vista-golfpark
              """),
        .init(name: "Rottaler Golf- & Country Club", location: "Hebertsfelden, Bayern",
              holes: 18, lat: 48.404, lon: 12.769,
              parValues: [4, 3, 4, 4, 3, 5, 4, 5, 4,   // OUT 36
                          5, 3, 4, 4, 5, 4, 4, 3, 4],   // IN 36  → Par 72
              hcpValues: [17, 9, 1, 13, 15, 5, 11, 3, 7,
                          6, 14, 16, 18, 2, 10, 8, 12, 4],
              holeLengths: [341, 207, 392, 316, 187, 466, 351, 556, 375,   // OUT 3191
                            499, 166, 373, 313, 457, 471, 348, 188, 421],  // IN 3236 → 6427 m
              courseRating: 71.7, slopeRating: 125,
              facilityNotes: """
              Parklandplatz am Rottauensee · Rott-Fluss als Hindernis
              Driving Range · Putting Green · 6-Loch-Übungsplatz
              Kontakt: www.rottaler-golfclub.de
              """),
        .init(name: "Golfclub Pfarrkirchen e.V.",               location: "Pfarrkirchen, Bayern",  holes: 18, lat: 48.428, lon: 12.937),
        .init(name: "Golfclub Vilsbiburg e.V.", location: "Vilsbiburg, Bayern",
              holes: 9, lat: 48.448, lon: 12.361,
              parValues: [4, 3, 5, 4, 5, 3, 4, 3, 4],  // Par 35 (9 Loch, 2× für 18-Loch-Wertung)
              hcpValues: [7, 17, 5, 3, 1, 13, 11, 15, 9],
              holeLengths: [410, 148, 526, 400, 571, 187, 366, 161, 400],  // 3169 m (9 Loch)
              courseRating: 70.9, slopeRating: 124,
              facilityNotes: """
              9-Loch-Anlage · Runde zweimal gespielt für 18-Loch-Wertung
              Architekt: Peter Harradine (1998)
              Driving Range · Clubhaus · Restaurant
              """),
        .init(name: "Golfclub Landau/Isar e.V.", location: "Landau an der Isar, Bayern",
              holes: 9, lat: 48.665, lon: 12.699,
              parValues: [4, 3, 4, 4, 3, 5, 4, 5, 3],  // Par 35 (9 Loch)
              hcpValues: [3, 5, 8, 7, 4, 9, 1, 6, 2],
              holeLengths: [293, 129, 340, 328, 191, 465, 281, 551, 132],  // 2710 m (9 Loch)
              courseRating: 35.4, slopeRating: 123,
              facilityNotes: """
              9-Loch-Golfpark · hügeliges, naturnahes Gelände
              Rappach 2, 94405 Landau/Isar
              Kontakt: www.golfpark-landau.de
              """),
        .init(name: "Golfclub Schloßberg e.V.", location: "Reisbach, Bayern",
              holes: 18, lat: 48.573, lon: 12.627,
              parValues: [3, 4, 3, 5, 4, 5, 4, 4, 4,   // OUT 36
                          3, 5, 4, 4, 5, 3, 4, 4, 4],   // IN 36  → Par 72
              hcpValues: [15, 17, 7, 5, 11, 1, 9, 3, 13,
                          18, 10, 6, 16, 4, 14, 12, 2, 8],
              holeLengths: [197, 383, 186, 493, 417, 536, 404, 385, 318,   // OUT 3319
                            165, 489, 352, 352, 547, 170, 388, 468, 353],  // IN 3284 → 6603 m
              courseRating: 71.6, slopeRating: 126,
              facilityNotes: """
              Ältester 18-Loch-Platz Ostbayerns (1984/85)
              Idyllische Waldlöcher · Restaurant
              Grünbach 8, 94419 Reisbach
              Kontakt: www.golfclub-schlossberg.de
              """),
        .init(name: "Golfclub Gäuboden e.V.", location: "Aiterhofen (Straubing), Bayern",
              holes: 18, lat: 48.828, lon: 12.559,
              parValues: [5, 4, 4, 5, 3, 4, 4, 5, 4,   // OUT 38
                          4, 3, 4, 5, 4, 3, 4, 4, 3],   // IN 34  → Par 72
              hcpValues: [3, 15, 11, 9, 17, 13, 1, 7, 5,
                          14, 16, 6, 12, 2, 18, 10, 4, 8],
              holeLengths: [440, 290, 328, 452, 121, 334, 348, 461, 348,   // OUT 3122
                            319, 157, 306, 426, 370, 161, 315, 318, 150],  // IN 2522 → 5644 m
              courseRating: 72.3, slopeRating: 128,
              facilityNotes: """
              Parklandplatz (1992/2006) · Bayerischer-Wald-Vorland
              Blick auf den Bogenberg · Driving Range
              Fruhstorf 6, 94330 Aiterhofen
              Kontakt: www.gc-gaeuboden.de
              """),
        .init(name: "Golfclub Straubing Stadt und Land e.V.", location: "Straubing, Bayern",
              holes: 9, lat: 48.897, lon: 12.576,
              parValues: [4, 3, 5, 4, 4, 5, 4, 4, 3],  // Par 36 (9 Loch)
              hcpValues: [3, 7, 13, 9, 11, 1, 15, 5, 17],
              holeLengths: [344, 191, 443, 302, 271, 438, 216, 268, 158],  // 2631 m (9 Loch)
              courseRating: 68.4, slopeRating: 123,
              facilityNotes: """
              9-Loch-Platz · ehemaliger Kiesabbau mit Wasserhindernissen
              Bachhof 9, 94356 Kirchroth
              Kontakt: www.golfclub-straubing.de
              """),
        .init(name: "Golfclub Altötting-Burghausen (Piesing)", location: "Haiming, Bayern",
              holes: 18, lat: 48.067, lon: 12.880,
              parValues: [5, 3, 4, 3, 5, 4, 3, 4, 5,   // OUT 36
                          5, 4, 3, 4, 4, 5, 4, 3, 4],   // IN 36  → Par 72
              hcpValues: [5, 15, 1, 11, 7, 9, 17, 13, 3,
                          4, 14, 18, 10, 8, 2, 6, 16, 12],
              holeLengths: [554, 164, 393, 203, 539, 366, 141, 337, 556,   // OUT 3253
                            548, 370, 166, 341, 386, 498, 420, 197, 360],  // IN 3286 → 6539 m
              courseRating: 71.3, slopeRating: 127,
              facilityNotes: """
              Architekt: Kurt Rossknecht (1986) · barockes Schloss Piesing
              Piesing 4, 84533 Haiming
              Kontakt: www.gc-altoetting-burghausen.de
              """),
        .init(name: "Golfclub Altötting-Burghausen (Falkenhof)", location: "Marktl am Inn, Bayern",
              holes: 9, lat: 48.254, lon: 12.844,
              facilityNotes: """
              9-Loch-Platz am Zusammenfluss von Inn und Alz · flaches Gelände
              Gesamtlänge Herren: ca. 2.927 m · Par 35
              Achtung: keine Kartenzahlung möglich
              Kontakt: www.gc-altoetting-burghausen.de
              """),
        .init(name: "Golfclub Pleiskirchen e.V.", location: "Pleiskirchen, Bayern",
              holes: 18, lat: 48.220, lon: 12.626,
              parValues: [5, 4, 4, 4, 3, 5, 4, 5, 3,   // OUT 37
                          5, 3, 4, 3, 5, 4, 4, 4, 3],   // IN 35  → Par 72
              hcpValues: [9, 5, 11, 3, 15, 17, 1, 7, 13,
                          10, 18, 4, 14, 8, 2, 16, 6, 12],
              holeLengths: [499, 409, 323, 424, 172, 479, 430, 513, 220,   // OUT 3469
                            486, 133, 445, 178, 544, 435, 330, 381, 190],  // IN 3122 → 6591 m
              courseRating: 71.8, slopeRating: 129,
              facilityNotes: """
              Parklandplatz (1996)
              Am Golfplatz 2, Pleiskirchen
              Kontakt: www.gc-pleiskirchen.de
              """),
        .init(name: "Golfclub Mühldorf",  location: "Mühldorf am Inn, Bayern", holes: 9, lat: 48.250, lon: 12.517),
        .init(name: "Golfclub Dingolfing", location: "Dingolfing, Bayern",      holes: 9, lat: 48.633, lon: 12.500),
        .init(name: "Golfclub Dorfen",     location: "Dorfen, Bayern",           holes: 18, lat: 48.267, lon: 12.167),
        .init(name: "Golfclub Schloss Guttenburg / Inntal", location: "Ampfing, Bayern",
              holes: 18, lat: 48.222, lon: 12.429,
              parValues: [4, 3, 4, 5, 4, 5, 3, 4, 4,   // OUT 36
                          4, 4, 5, 3, 5, 4, 4, 3, 4],   // IN 36  → Par 72
              hcpValues: [5, 13, 11, 9, 3, 1, 17, 15, 7,
                          6, 8, 14, 18, 10, 2, 4, 12, 16],
              holeLengths: [331, 203, 345, 490, 394, 582, 150, 289, 311,   // OUT 3095
                            303, 352, 443, 127, 485, 360, 395, 160, 314],  // IN 2939 → 6034 m
              courseRating: 72.0, slopeRating: 128,
              facilityNotes: """
              Architekt: Peter Harradine (1995) · Historisches Schloss Guttenburg
              6-Loch-Kurzplatz vorhanden
              Guttenburg 3, 84559 Kraiburg am Inn
              Kontakt: www.golfclub-guttenburg.de
              """),
        .init(name: "Golfclub Leonhardshaun", location: "Ergoldsbach, Bayern",
              holes: 9, lat: 48.688, lon: 12.172,
              parValues: [3, 4, 3, 4, 3, 4, 3, 4, 4],  // Par 32 (9 Loch)
              hcpValues: [17, 5, 11, 15, 13, 3, 9, 7, 1],
              holeLengths: [125, 330, 189, 308, 141, 299, 180, 306, 393],  // 2271 m (9 Loch)
              courseRating: 32.1, slopeRating: 115,
              facilityNotes: "Sanft hügelig · 9-Loch-Anlage · Kontakt: www.golfplatz-leonhardshaun.de"),

        // ── Bayerischer Wald ──────────────────────────────────────────
        .init(name: "Golfclub am Nationalpark Bayerischer Wald", location: "St. Oswald / Grafenau, Bayern",
              holes: 18, lat: 48.782, lon: 13.406,
              parValues: [5, 4, 4, 3, 4, 4, 4, 4, 4,   // OUT 36
                          4, 4, 4, 5, 3, 4, 3, 4, 4],   // IN 35  → Par 71
              hcpValues: [3, 7, 13, 17, 15, 11, 5, 1, 9,
                          6, 4, 8, 14, 12, 10, 18, 2, 16],
              holeLengths: [512, 327, 338, 139, 334, 308, 349, 399, 317,   // OUT 3023
                            314, 419, 390, 462, 161, 330, 149, 377, 317],  // IN 2919 → 5942 m
              courseRating: 68.7, slopeRating: 125,
              facilityNotes: """
              18-Loch-Platz auf 90 ha im Nationalpark Bayerischer Wald
              Architekt: Peter Harradine (2005)
              Driving Range · Putting- und Chipping-Green
              E-Carts erlaubt · Saison April–November
              Kontakt: www.gcanp.de
              """),
        .init(name: "Deggendorfer Golfclub (Rusel)", location: "Schaufling, Bayern",
              holes: 18, lat: 48.834, lon: 13.099,
              parValues: [4, 4, 4, 3, 5, 5, 4, 4, 4,   // OUT 37
                          4, 3, 4, 4, 3, 5, 4, 3, 5],   // IN 35  → Par 72
              hcpValues: [15, 13, 7, 17, 5, 1, 11, 9, 3,
                          6, 18, 8, 12, 14, 2, 4, 16, 10],
              holeLengths: [324, 297, 401, 150, 510, 595, 262, 304, 329,   // OUT 3172
                            343, 154, 325, 331, 178, 513, 335, 174, 478],  // IN 2831 → 6003 m
              courseRating: 68.8, slopeRating: 126,
              facilityNotes: """
              Architekten: Donald Harradine (1981) & Peter Harradine (2003)
              Driving Range · RUSEL-ARENA (Indoor-Simulator) · Golfschule
              Hunde für Mitglieder Mo–Fr ab 14 Uhr erlaubt
              Kontakt: www.deggendorfer-golfclub.de
              """),
        .init(name: "Golfclub Regen",     location: "Regen, Bayern",     holes: 9, lat: 48.967, lon: 13.117),
        .init(name: "Golfclub Viechtach", location: "Viechtach, Bayern", holes: 9, lat: 49.083, lon: 12.883),
        .init(name: "Golfclub Furth im Wald e.V.", location: "Furth im Wald, Bayern",
              holes: 18, lat: 49.307, lon: 12.849,
              parValues: [5, 3, 4, 3, 4, 4, 4, 4, 5,   // OUT 36
                          5, 4, 4, 4, 3, 3, 5, 4, 4],   // IN 36  → Par 72
              hcpValues: [17, 9, 1, 13, 5, 3, 15, 11, 7,
                          8, 4, 2, 18, 14, 16, 12, 10, 6],
              holeLengths: [517, 190, 431, 192, 400, 388, 348, 383, 509,   // OUT 3358
                            592, 430, 297, 302, 184, 162, 479, 375, 369],  // IN 3190 → 6548 m
              courseRating: 72.1, slopeRating: 136,
              facilityNotes: """
              Architekt: Kurt Rossknecht (1983/1986)
              Hügeliger Platz mit Wasserhindernissen · 70 ha Anlage
              Driving Range · Pitching- und Putting-Green
              Sekretariat Mo–So 9–16 Uhr
              Kontakt: www.gc-furth.de
              """),

        // ── Oberpfalz / Regensburg ────────────────────────────────────
        .init(name: "Golf- und Landclub Regensburg e.V.", location: "Sinzing (Regensburg), Bayern",
              holes: 18, lat: 49.019, lon: 12.003,
              parValues: [4, 4, 3, 4, 5, 3, 5, 4, 5,   // OUT 37
                          4, 5, 4, 3, 4, 4, 3, 5, 3],   // IN 35  → Par 72
              hcpValues: [17, 3, 7, 5, 9, 15, 13, 11, 1,
                          16, 6, 12, 14, 2, 8, 10, 4, 18],
              holeLengths: [249, 334, 137, 335, 448, 146, 419, 307, 448,   // OUT 2823
                            265, 481, 268, 134, 417, 365, 131, 458, 113],  // IN 2632 → 5455 m
              courseRating: 70.0, slopeRating: 133,
              facilityNotes: """
              Parklandplatz im ehem. Jagdgrund des Hauses Thurn & Taxis
              Bäume bis 300 Jahre alt · Clubhaus im Jagdschloss von 1885
              Gründungsmitglied Leading Golf Clubs of Germany
              Handicap-Ausweis & Buchung erforderlich · Green Fee 85–95 €
              Kontakt: www.golfclub-regensburg.de
              """),
        .init(name: "Golf- und Countryclub Sinzing Minoritenhof", location: "Sinzing, Bayern",
              holes: 18, lat: 48.990, lon: 12.056,
              parValues: [4, 3, 4, 4, 5, 4, 3, 4, 5,   // OUT 36
                          3, 4, 5, 4, 3, 4, 4, 5, 4],   // IN 36  → Par 72
              hcpValues: [3, 15, 7, 9, 17, 5, 11, 1, 8,
                          10, 14, 6, 18, 4, 12, 2, 16, 13],
              holeLengths: [338, 138, 355, 290, 501, 327, 170, 341, 568,   // OUT 3028
                            179, 396, 536, 341, 197, 404, 305, 521, 369],  // IN 3248 → 6276 m
              courseRating: 70.2, slopeRating: 130,
              facilityNotes: """
              27-Loch-Anlage (18 + 9 Loch) am Minoritenhof · Donau-nahe Lage
              Scorecard-PDF auf golfsinzing.de downloadbar
              Kontakt: welcome@golfsinzing.de · Tel. +49 941 37 86 100
              """),
        .init(name: "Golfclub Bad Abbach-Deutenhof e.V.", location: "Bad Abbach, Bayern",
              holes: 18, lat: 48.930, lon: 12.044,
              parValues: [4, 4, 3, 4, 3, 5, 4, 4, 5,   // OUT 36
                          4, 3, 4, 5, 4, 4, 3, 5, 4],   // IN 36  → Par 72
              hcpValues: [7, 9, 15, 5, 17, 1, 3, 13, 11,
                          2, 16, 6, 4, 10, 14, 18, 12, 8],
              holeLengths: [387, 354, 147, 384, 174, 591, 397, 374, 471,   // OUT 3279
                            434, 148, 326, 523, 387, 311, 138, 482, 335],  // IN 3084 → 6363 m
              courseRating: 70.5, slopeRating: 128,
              facilityNotes: """
              18-Loch-Championship + 9-Loch-Kurzplatz (Par 28) + Driving Range
              Ganzjährig begehbarer Kurzplatz · E-Carts verfügbar
              Kontakt: www.golf-badabbach.de
              """),
        .init(name: "MARC AUREL Spa & Golf Resort", location: "Bad Gögging, Bayern",
              holes: 9, lat: 48.861, lon: 11.972,
              parValues: [3, 3, 3, 3, 3, 3, 3, 3, 3],  // Par 27
              hcpValues: [5, 4, 1, 8, 7, 6, 3, 9, 2],
              holeLengths: [96, 100, 142, 84, 94, 103, 121, 67, 97],  // 904 m
              courseRating: 29.4, slopeRating: 104,
              facilityNotes: """
              9-Loch-Par-3-Platz direkt am Wellnesshotel · komplett flach
              Driving Range · Clubverleih · Unterricht
              Ideal für Anfänger und Kurzurlauber
              Kontakt: www.marcaurel.de
              """),
        .init(name: "Golfclub Beratzhausen",             location: "Beratzhausen, Bayern",  holes: 18, lat: 49.083, lon: 11.817),
        .init(name: "Golfclub Cham",                     location: "Cham, Bayern",           holes: 18, lat: 49.217, lon: 12.667),
        .init(name: "Golf- und Landclub Oberpfälzer Wald e.V.", location: "Neunburg vorm Wald, Bayern",
              holes: 18, lat: 49.314, lon: 12.338,
              parValues: [5, 4, 4, 3, 4, 5, 4, 3, 4,   // OUT 36
                          5, 3, 4, 4, 3, 4, 5, 3, 5],   // IN 36  → Par 72
              hcpValues: [7, 1, 3, 17, 11, 5, 9, 13, 15,
                          2, 18, 8, 4, 12, 14, 10, 16, 6],
              holeLengths: [471, 421, 344, 161, 306, 544, 365, 165, 296,   // OUT 3073
                            504, 142, 350, 395, 205, 351, 562, 180, 556],  // IN 3245 → 6318 m
              courseRating: 70.7, slopeRating: 135,
              facilityNotes: """
              18-Loch in Naturschutzgebiet · hügeliges Gelände (165 Fuß Höhenunterschied)
              Signaturloch 9: 50 m Abstieg mit Dogleg
              Driving Range (12 überdachte Abschläge) · Restaurant "Birner's Kulinarik"
              Kontakt: www.golf-oberpfalz.de
              """),
        .init(name: "Golfclub Schwanhof e.V.", location: "Luhe-Wildenau, Bayern",
              holes: 18, lat: 49.585, lon: 12.173,
              parValues: [4, 4, 3, 5, 4, 4, 5, 3, 4,   // OUT 36
                          4, 4, 3, 5, 4, 4, 3, 5, 4],   // IN 36  → Par 72
              hcpValues: [15, 3, 13, 9, 1, 11, 7, 17, 5,
                          4, 12, 14, 16, 8, 6, 18, 10, 2],
              holeLengths: [428, 381, 181, 545, 488, 393, 576, 161, 466,   // OUT 3619
                            461, 386, 173, 528, 405, 433, 124, 523, 475],  // IN 3508 → 7127 m (Weiß-Abschlag)
              courseRating: 71.3, slopeRating: 134,
              facilityNotes: """
              Architekt: Jerry Pate & Reinhold Weishaupt (1993)
              Lage im Naturpark Oberpfälzer Wald
              Driving Range · Pro-Shop · Restaurant
              Hinweis: Lochlängen beziehen sich auf den Weiß-Abschlag
              Kontakt: www.golfclub-schwanhof.de
              """),

        // ── Landshut / Ingolstadt ─────────────────────────────────────
        .init(name: "Golfclub Landshut",                        location: "Furth bei Landshut, Bayern",
              holes: 18, lat: 48.521, lon: 12.148,
              parValues: [4, 4, 5, 5, 4, 3, 5, 3, 4,   // OUT 37
                          4, 4, 5, 4, 3, 5, 3, 4, 4],   // IN 36  → Par 73
              hcpValues: [13,  1,  7,  3, 15, 11,  9,  5, 17,
                           4, 10, 12,  8, 18, 14, 16,  6,  2],
              holeLengths: [252, 371, 451, 500, 270, 168, 435, 189, 305,   // OUT 2941
                            359, 338, 431, 365, 125, 457, 154, 373, 337],  // IN 2939 → 5880 m
              courseRating: 71.1, slopeRating: 130,
              facilityNotes: """
              Digital-Birdiebook verfügbar · 3-Loch-Kurzplatz vorhanden
              Kontakt: www.golf-landshut.de
              """),
        .init(name: "Golfclub Ingolstadt",                      location: "Ingolstadt, Bayern",
              holes: 18, lat: 48.767, lon: 11.417,
              parValues: [4, 4, 5, 3, 4, 3, 5, 3, 4,   // OUT 35
                          4, 3, 5, 4, 4, 3, 5, 4, 5],   // IN 37  → Par 72
              hcpValues: [ 3,  7,  1, 11,  5, 15,  9, 13, 17,
                          10, 14,  2, 12, 16, 18,  6,  8,  4],
              holeLengths: [346, 353, 519, 140, 386, 151, 450, 172, 260,   // OUT 2777
                            330, 157, 446, 349, 340, 172, 532, 356, 452],  // IN 3134 → 5911 m
              courseRating: 71.2, slopeRating: 128,
              facilityNotes: """
              Gegründet 1977 · Parklandplatz
              Kontakt: www.golf-ingolstadt.de
              """),

        // ── München & Umgebung ────────────────────────────────────────
        .init(name: "Golfclub Eichenried",                      location: "Eichenried, Bayern",
              holes: 18, lat: 48.217, lon: 11.817,
              parValues: [4, 3, 4, 4, 4, 5, 4, 3, 5,   // OUT (A) 36
                          5, 3, 4, 4, 3, 4, 4, 5, 4],   // IN (B) 36  → Par 72
              holeLengths: [423, 166, 410, 332, 313, 468, 436, 195, 531,   // OUT (A) 3274
                            454, 482, 152, 382, 384, 210, 484, 396, 504],  // IN (B) 3448 → 6722 m
              courseRating: 73.3, slopeRating: 131,
              facilityNotes: """
              27-Loch-Anlage (A, B, C jeweils 9 Loch) · Design Kurt Rossknecht (1989)
              Turnierplatz (BMW Open) · Golfakademie · Simulator
              Daten: A-Kurs (OUT) + B-Kurs (IN)
              Kontakt: www.gc-eichenried.de
              """),
        .init(name: "Golfclub München Riedhof e.V.",            location: "Egling (Bad Tölz-Wolfratshausen), Bayern",
              holes: 18, lat: 48.083, lon: 11.283,
              parValues: [4, 3, 4, 5, 3, 4, 3, 4, 4,   // OUT 34
                          4, 3, 5, 4, 5, 4, 5, 4, 4],   // IN 38  → Par 72
              hcpValues: [ 9, 17, 13,  1, 15,  5, 11,  3,  7,
                          14, 18,  2,  8,  6, 16, 10,  4, 12],
              courseRating: 71.5, slopeRating: 132,
              facilityNotes: """
              Gegründet 1991 · Driving Range · Golfschule
              Kontakt: www.golfclub-riedhof.de
              """),
        .init(name: "Golfclub München-Strasslach e.V.",         location: "Strasslach-Dingharting, Bayern",
              holes: 18, lat: 47.967, lon: 11.517,
              parValues: [5, 4, 3, 4, 5, 4, 3, 4, 4,   // OUT (A) 36
                          5, 3, 4, 4, 3, 4, 4, 5, 4],   // IN (B) 36  → Par 72
              holeLengths: [484, 328, 136, 358, 432, 314, 132, 381, 319,   // OUT (A) 2884
                            432, 188, 366, 320, 180, 398, 378, 461, 318],  // IN (B) 3041 → 5925 m
              facilityNotes: """
              27-Loch (A, B, C) · Gegründet 1910 (ältester Golfclub Bayerns)
              Daten: A-Kurs (OUT) + B-Kurs (IN)
              Kontakt: www.mgc-golf.de
              """),
        .init(name: "Golfclub Feldafing e.V.",                  location: "Feldafing, Bayern",
              holes: 18, lat: 47.950, lon: 11.283,
              parValues: [4, 3, 5, 4, 4, 5, 4, 3, 5,   // OUT 37
                          4, 3, 4, 4, 3, 4, 3, 4, 5],   // IN 34  → Par 71
              hcpValues: [ 9, 13, 11,  1,  3,  7, 17, 15,  5,
                          16, 18,  6,  2, 10,  8, 14,  4, 12],
              holeLengths: [366, 205, 476, 396, 387, 528, 322, 170, 489,   // OUT 3339
                            305, 113, 414, 439, 190, 422, 165, 397, 479],  // IN 2924 → 6263 m
              courseRating: 71.6, slopeRating: 142,
              facilityNotes: """
              Exklusiver Clubplatz am Starnberger See · Slope 142 (sehr anspruchsvoll)
              Entfernungsmarkierungen: Weiß=100m · Rot=150m · Gelb=200m
              Kontakt: www.golfclub-feldafing.de
              """),
        .init(name: "Golfclub Tutzing e.V.",                    location: "Tutzing, Bayern",
              holes: 18, lat: 47.900, lon: 11.283,
              parValues: [4, 5, 4, 4, 5, 3, 5, 4, 3,   // OUT 37
                          5, 3, 4, 4, 3, 4, 4, 3, 5],   // IN 35  → Par 72
              hcpValues: [ 1, 11,  9,  7, 13, 17,  3,  5, 15,
                          18, 14, 10,  2, 16,  8,  6, 12,  4],
              holeLengths: [435, 505, 417, 395, 493, 124, 551, 390, 152,   // OUT 3462
                            481, 166, 367, 422, 174, 394, 385, 145, 609],  // IN 3143 → 6605 m
              courseRating: 71.7, slopeRating: 123,
              facilityNotes: """
              Gut Deixlfurt · Sekretariat tägl. 9–17 Uhr · Tel. 08158-3600
              Kontakt: www.golfclub-tutzing.de
              """),
        .init(name: "Golfclub Erding-Grünbach",                 location: "Bockhorn bei Erding, Bayern",
              holes: 18, lat: 48.283, lon: 11.917,
              parValues: [4, 4, 3, 5, 3, 4, 5, 4, 3,   // OUT 35
                          4, 3, 4, 4, 4, 5, 5, 3, 4],   // IN 36  → Par 71
              hcpValues: [ 3,  9, 11,  1,  7, 15, 13,  5, 17,
                          10, 18,  8,  2, 14,  4,  6, 12, 16],
              courseRating: 70.8, slopeRating: 127,
              facilityNotes: """
              Birdiebook mit Lochdaten am Clubhaus erhältlich
              Tel. +49 8122 49650 · Kontakt: www.golf-erding.de
              """),
        .init(name: "Golfclub Dachau-Inhauser Moos",            location: "Dachau, Bayern",
              holes:  9, lat: 48.233, lon: 11.433,
              parValues: [4, 4, 4, 4, 5, 3, 5, 4, 3],  // Par 36 (9 Loch, 18-Loch-Wertung: Par 72)
              hcpValues: [15, 5, 7, 17, 1, 13, 3, 9, 11],
              courseRating: 70.7, slopeRating: 131,
              facilityNotes: """
              9-Loch-Platz (18-Loch durch doppelten Umlauf) · An der Amper
              Saisonbetrieb April–Oktober
              Kontakt: www.gcdachau.de
              """),
        .init(name: "Golfclub Hebertshausen",                   location: "Hebertshausen, Bayern",                 holes: 18, lat: 48.283, lon: 11.383),
        .init(name: "Golfclub Mangfalltal",                     location: "Feldkirchen-Westerham, Bayern",
              holes: 18, lat: 47.867, lon: 11.917,
              parValues: [5, 3, 4, 4, 4, 3, 5, 4, 5,   // OUT 37
                          3, 5, 5, 4, 4, 4, 3, 4, 3],   // IN 35  → Par 72
              hcpValues: [ 5, 13,  1,  9, 15, 17, 11,  7,  3,
                          18,  6,  2, 14,  4,  8, 16, 10, 12],
              holeLengths: [515, 183, 446, 346, 336, 194, 499, 363, 550,   // OUT 3432
                            170, 492, 518, 253, 358, 386, 140, 372, 188],  // IN 2877 → 6309 m
              courseRating: 71.7, slopeRating: 140,
              facilityNotes: """
              Seit 1987 · 70 ha · Alpenpanorama · Slope 140 (sehr anspruchsvoll)
              Tom Duncan Performance Center · Simulatoren
              Kontakt: www.gc-mangfalltal.de
              """),

        // ── Rosenheim / Chiemgau / Berchtesgaden ─────────────────────
        .init(name: "Golfclub Rosenheim",                       location: "Stephanskirchen, Bayern",               holes: 18, lat: 47.867, lon: 12.167),
        .init(name: "Chiemsee Golf-Club Prien e.V.",            location: "Prien am Chiemsee, Bayern",
              holes: 18, lat: 47.844, lon: 12.343,
              parValues: [4, 3, 5, 3, 4, 4, 5, 4, 4,   // OUT 36
                          3, 4, 4, 4, 5, 4, 4, 5, 3],   // IN 36  → Par 72
              hcpValues: [ 3, 11,  1, 15,  9,  5, 13,  7, 17,
                          16, 14, 18,  4, 12,  6,  2, 10,  8],
              courseRating: 72.0, slopeRating: 133,
              facilityNotes: """
              Seit 1961 · Bauernberg 5, 83209 Prien am Chiemsee
              Gäste willkommen (Voranmeldung erbeten)
              Tel. 08051-62215 · cgc-prien@t-online.de
              """),
        .init(name: "Golfclub Berchtesgadener Land",            location: "Ainring (Weng), Bayern",
              holes: 18, lat: 47.733, lon: 12.867,
              parValues: [5, 4, 5, 3, 4, 4, 3, 4, 4,   // OUT 36
                          4, 3, 5, 4, 4, 4, 4, 3, 5],   // IN 36  → Par 72
              hcpValues: [ 5, 11,  9, 13,  1, 17, 15,  3,  7,
                          14, 12,  8,  6,  4, 10,  2, 18, 16],
              courseRating: 71.4, slopeRating: 130,
              facilityNotes: """
              Seit 1994 · ca. 40 Bunker · Inselgrün Loch 11 · Bergpanorama
              Weng 12, 83404 Ainring (bei Bad Reichenhall)
              Kontakt: www.gcbgl.de
              """),
        .init(name: "Golfclub Traunstein",                      location: "Traunstein, Bayern",                    holes: 18, lat: 47.867, lon: 12.650),
        .init(name: "Golfclub Waging am See",                   location: "Waging am See, Bayern",                 holes: 18, lat: 47.933, lon: 12.733),

        // ── Oberösterreich — Innviertel ───────────────────────────────
        .init(name: "Golfclub Braunau-Ranshofen",               location: "Ranshofen, Oberösterreich",             holes: 18, lat: 48.233, lon: 13.050),
        .init(name: "Golfclub Pischelsdorf (Gut Kaltenhausen)",  location: "Pischelsdorf am Engelbach, OÖ",
              holes: 18, lat: 48.073, lon: 13.250,
              parValues: [4, 4, 4, 4, 5, 4, 3, 5, 3,   // OUT 36
                          4, 3, 5, 4, 4, 4, 5, 3, 4],   // IN 36  → Par 72
              hcpValues: [11,  3,  9,  5,  7, 15, 13,  1, 17,
                           4, 14, 12, 16, 18, 10,  2,  8,  6],
              holeLengths: [292, 374, 317, 330, 470, 306, 178, 513, 149,   // OUT 2929
                            363, 185, 453, 305, 280, 339, 517, 152, 362],  // IN 2956 → 5885 m
              courseRating: 70.8, slopeRating: 123,
              facilityNotes: """
              18-Loch-Meisterschaftsplatz auf über 50 ha
              Clubhaus in umgebautem Bauernhof
              Kontakt: www.gc-kaltenhausen.at
              """),
        .init(name: "Golfclub Maria Theresia",                  location: "Haag am Hausruck, Oberösterreich",
              holes: 18, lat: 48.178, lon: 13.636,
              courseRating: 71.8, slopeRating: 124,
              facilityNotes: """
              18-Loch · Par 72 · ca. 5952 m (Gelb)
              Kontakt: www.gcmariatheresia.at
              """),
        .init(name: "Golfclub Wels",                            location: "Thalheim bei Wels, Oberösterreich",
              holes: 18, lat: 48.150, lon: 14.017,
              parValues: [4, 4, 4, 5, 3, 5, 3, 4, 3,   // OUT 35
                          4, 4, 4, 4, 5, 5, 3, 4, 4],   // IN 37  → Par 72
              hcpValues: [ 1, 11,  3,  7, 15,  9, 17,  5, 13,
                          14, 10,  6,  8, 12, 16, 18,  2,  4],
              holeLengths: [359, 396, 364, 537, 211, 494, 187, 425, 180,   // OUT 3153
                            393, 347, 394, 352, 492, 490, 143, 433, 394],  // IN 3438 → 6591 m
              courseRating: 72.9, slopeRating: 131,
              facilityNotes: """
              Gegründet 1981 · Parklandplatz
              Kontakt: www.gc-wels.at
              """),
        .init(name: "Golfclub Attnang-Puchheim",                location: "Attnang-Puchheim, Oberösterreich",      holes:  9, lat: 47.967, lon: 13.717),
        .init(name: "Golfclub Ampflwang",                       location: "Ampflwang, Oberösterreich",
              holes:  9, lat: 48.101, lon: 13.565,
              courseRating: 62.8, slopeRating: 125,
              facilityNotes: """
              ROBINSON Club-Resort · 9-Loch · Par 37 (18-Loch-Wertung: Par 74)
              Driving Range · Restaurant · Erbaut 1995
              """),

        // ── Oberösterreich — Mühlviertel ──────────────────────────────
        .init(name: "Golfpark Böhmerwald",                      location: "Ulrichsberg, Oberösterreich",
              holes: 18, lat: 48.647, lon: 13.902,
              parValues: [4, 4, 3, 4, 5, 4, 5, 3, 4,   // OUT 36
                          4, 5, 4, 4, 3, 4, 3, 5, 4],   // IN 36  → Par 72
              hcpValues: [ 3,  9, 13,  7, 11, 15,  1, 17,  5,
                           2, 16, 14,  4, 18, 12, 10,  6,  8],
              holeLengths: [344, 349, 174, 358, 444, 323, 457, 152, 327,   // OUT 2928
                            387, 471, 267, 341, 160, 367, 159, 423, 331],  // IN 2906 → 5834 m
              courseRating: 70.9, slopeRating: 129,
              facilityNotes: """
              Hochwald-Kurs (18 Loch) + Panorama-Kurs (9 Loch) im Dreiländereck OÖ/Bayern/Tschechien
              Kontakt: www.boehmerwaldgolf.at
              """),
        .init(name: "Golfclub SternGartl",                      location: "Oberneukirchen, Oberösterreich",
              holes: 18, lat: 48.477, lon: 14.233,
              parValues: [4, 3, 4, 3, 5, 4, 4, 3, 4,   // OUT 34
                          5, 4, 5, 3, 4, 5, 3, 4, 3],   // IN 36  → Par 70
              hcpValues: [ 5, 17,  7, 11,  1,  9,  3, 15, 13,
                           8,  6,  4, 12,  2, 10, 14, 16, 18],
              holeLengths: [363, 139, 313, 182, 573, 376, 408, 155, 324,   // OUT 2833
                            509, 352, 482, 156, 404, 466, 189, 366, 154],  // IN 3078 → 5911 m
              courseRating: 70.3, slopeRating: 128,
              facilityNotes: """
              18-Loch · Par 70 · Hügeliges Granit-Gelände mit Bach
              Schauerschlag 4, 4181 Oberneukirchen
              Kontakt: www.sterngartl.at
              """),
        .init(name: "Golf & Country Club Schloss Schönau",      location: "Schönau im Mühlkreis, OÖ",              holes: 18, lat: 48.483, lon: 14.150),
        .init(name: "Golfclub Bad Leonfelden",                  location: "Bad Leonfelden, Oberösterreich",        holes:  9, lat: 48.517, lon: 14.283),
        .init(name: "Golfclub St. Oswald-Freistadt",            location: "St. Oswald bei Freistadt, OÖ",
              holes: 18, lat: 48.505, lon: 14.596,
              courseRating: 70.6, slopeRating: 133,
              facilityNotes: """
              18-Loch · Par 72 · 5741 m (Gelb)
              Kontakt: www.golfclub-stoswald.at
              """),
        .init(name: "Golfclub Perg-Karlingberg",                location: "Perg, Oberösterreich",
              holes:  9, lat: 48.248, lon: 14.641,
              parValues: [3, 3, 3, 3, 3, 3, 3, 3, 3],  // Par 27 (9-Loch-Par-3-Kurzplatz)
              hcpValues: [7, 13, 3, 11, 17, 1, 9, 15, 5],
              holeLengths: [112, 108, 128, 120, 122, 148, 112, 108, 128],  // 1086 m
              slopeRating: 82,
              facilityNotes: """
              9-Loch-Par-3-Kurzanlage · erbaut 2018
              Karlingberg 3, 4320 Perg
              """),

        // ── Oberösterreich — Linz ─────────────────────────────────────
        .init(name: "Linzer Golf-Club Luftenberg",              location: "Luftenberg an der Donau, OÖ",
              holes: 18, lat: 48.328, lon: 14.394,
              courseRating: 70.3, slopeRating: 122,
              facilityNotes: """
              18-Loch · Par 71 · ca. 5867 m (Gelb)
              Clubhaus im historischen Renaissance-Meierhof
              Kontakt: www.gclinz-luftenberg.at
              """),
        .init(name: "Golfclub Stärk Linz-Ansfelden",           location: "Ansfelden, Oberösterreich",             holes: 18, lat: 48.192, lon: 14.283),
        .init(name: "Golf Club Linz-St. Florian",               location: "St. Florian (Tillysburg), OÖ",
              holes: 18, lat: 48.183, lon: 14.388,
              parValues: [5, 5, 3, 5, 4, 4, 3, 5, 4,   // OUT 38
                          4, 3, 5, 4, 3, 4, 3, 4, 4],   // IN 34  → Par 72
              hcpValues: [14, 18,  8, 10, 16,  2, 12,  6,  4,
                           3, 13, 17,  7,  1, 11,  9,  5, 15],
              holeLengths: [537, 476, 172, 548, 407, 339, 164, 547, 290,   // OUT 3480
                            322, 150, 498, 375, 140, 401, 172, 424, 453],  // IN 2935 → 6415 m
              courseRating: 72.1, slopeRating: 137,
              facilityNotes: """
              Design Donald Harradine & Hans-Georg Erhardt (1974)
              Tillysburg 28, 4490 St. Florian
              Kontakt: www.golfclub-stflorian.at
              """),
        .init(name: "Golfclub Donau Freizeitland",              location: "Feldkirchen an der Donau, OÖ",
              holes: 18, lat: 48.330, lon: 14.100,
              parValues: [4, 3, 4, 4, 4, 4, 5, 5, 3,   // OUT 36
                          4, 3, 5, 3, 4, 5, 4, 5, 3],   // IN 36  → Par 72
              hcpValues: [11,  9,  1,  3, 15,  5,  7, 13, 17,
                           6, 16,  4, 18, 12, 10, 14,  2,  8],
              holeLengths: [328, 208, 355, 398, 373, 419, 527, 495, 143,   // OUT 3246
                            377, 188, 507, 136, 354, 468, 365, 592, 178],  // IN 3165 → 6411 m
              courseRating: 71.4, slopeRating: 128,
              facilityNotes: """
              Erbaut 1991 · Auch 9-Loch-Kurzplatz (Par 30) vorhanden
              Golfplatzstraße 12, A-4101 Feldkirchen/Donau
              Kontakt: www.gc-donaufreizeitland.at
              """),
        .init(name: "Golfpark Metzenhof",                       location: "Kronstorf, Oberösterreich",
              holes: 18, lat: 48.124, lon: 14.477,
              parValues: [5, 4, 3, 5, 3, 4, 3, 4, 4,   // OUT 35
                          4, 4, 5, 3, 4, 3, 4, 4, 5],   // IN 36  → Par 71
              hcpValues: [ 2,  4, 10, 14, 16,  6, 12,  8, 18,
                          13,  7,  9, 17,  3, 11, 15,  1,  5],
              holeLengths: [541, 364, 156, 492, 155, 365, 167, 319, 331,   // OUT 2890
                            323, 369, 503, 183, 423, 143, 299, 418, 479],  // IN 3140 → 6030 m
              courseRating: 70.3, slopeRating: 131,
              facilityNotes: """
              Design Hans-Georg Erhardt (2003)
              Dörfling 2, A-4484 Kronstorf
              Kontakt: www.golfpark-metzenhof.at
              """),
        .init(name: "Golf Resort Kremstal",                     location: "Kematen an der Krems, OÖ",
              holes: 18, lat: 48.082, lon: 14.124,
              facilityNotes: """
              27-Loch-Anlage (3 × 9 Loch): Bergergut · Scherndlgut · Panorama
              Erbaut 1991–1996 · Design Peter Mayrhofer
              Am Golfplatz 1, 4531 Kematen an der Krems
              Kontakt: www.golfresort-kremstal.at
              """),
        .init(name: "Golfclub Herzog Tassilo",                  location: "Bad Hall, Oberösterreich",
              holes: 18, lat: 48.037, lon: 14.196,
              parValues: [4, 4, 3, 5, 5, 4, 4, 3, 4,   // OUT 36
                          4, 5, 3, 5, 4, 3, 4, 4, 3],   // IN 35  → Par 71
              hcpValues: [ 9, 11, 15,  3,  5, 13, 17,  1,  7,
                           8,  2, 14,  6, 18, 16, 12, 10,  4],
              holeLengths: [340, 315, 179, 462, 458, 332, 329, 130, 398,   // OUT 2943
                            398, 455, 189, 440, 314, 145, 283, 321, 212],  // IN 2757 → 5700 m
              courseRating: 70.1, slopeRating: 129,
              facilityNotes: """
              Erbaut 1989 · Design Peter Mayrhofer
              Löcher 1–11 hügelig · Löcher 12–18 flach
              Blankenberger Str. 30, 4540 Bad Hall
              Kontakt: www.gc-herzogtassilo.at
              """),

        // ── Salzkammergut / Traunsee ──────────────────────────────────
        .init(name: "Golf REGAU Attersee-Traunsee",             location: "Regau, Oberösterreich",
              holes: 18, lat: 47.950, lon: 13.680,
              parValues: [4, 4, 3, 4, 4, 3, 5, 5, 4,   // OUT 36
                          5, 4, 3, 4, 5, 4, 4, 5, 3],   // IN 37  → Par 73
              hcpValues: [15,  9,  3,  1, 17, 11,  7, 13,  5,
                           2,  4,  6, 16, 10, 18,  8, 12, 14],
              holeLengths: [320, 362, 151, 359, 262, 158, 473, 464, 332,   // OUT 2881
                            440, 281, 148, 283, 461, 298, 285, 406, 140],  // IN 2742 → 5623 m
              courseRating: 72.9, slopeRating: 129,
              facilityNotes: """
              Erbaut 2005 · Design Barbara Eisserer & Diethard Fahrenleitner
              Par 73 · Gesamtlänge ca. 6150 m (Gelb)
              Kontakt: www.golf-regau.at
              """),
        .init(name: "Golfclub Traunsee Almtal",                 location: "Kirchham, Oberösterreich",
              holes: 18, lat: 47.904, lon: 13.890,
              parValues: [4, 5, 3, 4, 3, 4, 4, 4, 3,   // OUT 34
                          4, 4, 4, 5, 5, 4, 3, 4, 4],   // IN 37  → Par 71
              hcpValues: [ 4,  6, 14, 18, 12, 16,  2,  8, 10,
                          17,  7,  5,  9,  3,  1, 13, 11, 15],
              holeLengths: [339, 478, 191, 309, 141, 292, 373, 303, 159,   // OUT 2585
                            312, 313, 382, 503, 491, 433, 199, 340, 268],  // IN 3241 → 5826 m
              courseRating: 68.9, slopeRating: 129,
              facilityNotes: """
              Erbaut 1989 · Hügeliges Gelände über 500 m Seehöhe
              Kontakt: www.golfclubtraunsee.at
              """),
        .init(name: "Golfclub Am Mondsee",                      location: "St. Lorenz am Mondsee, OÖ",
              holes: 18, lat: 47.843, lon: 13.380,
              parValues: [4, 4, 3, 4, 4, 4, 5, 3, 5,   // OUT 36
                          4, 5, 4, 4, 4, 3, 4, 3, 5],   // IN 36  → Par 72
              hcpValues: [11, 13, 15,  7,  1,  5,  9, 17,  3,
                          18,  8, 12, 16,  4,  2, 10, 14,  6],
              holeLengths: [357, 345, 171, 412, 442, 370, 481, 175, 524,   // OUT 3277
                            323, 573, 411, 398, 361, 164, 320, 170, 514],  // IN 3234 → 6511 m
              courseRating: 72.0, slopeRating: 131,
              facilityNotes: """
              Überwiegend flach · 4 Abschlagvarianten
              Kontakt: www.gc-mondsee.at
              """),
        .init(name: "Golfclub Salzkammergut",                   location: "St. Wolfgang im Salzkammergut, OÖ",
              holes: 18, lat: 47.741, lon: 13.451,
              parValues: [5, 4, 4, 3, 4, 5, 4, 3, 4,   // OUT 36
                          5, 3, 4, 4, 5, 3, 4, 3, 4],   // IN 35  → Par 71
              hcpValues: [ 6, 16,  2, 12, 10, 18,  8,  4, 14,
                           7,  3,  1, 15, 13, 11,  9, 17,  5],
              holeLengths: [460, 383, 360, 168, 246, 497, 375, 141, 419,   // OUT 3049
                            468, 174, 358, 388, 483, 149, 317, 164, 362],  // IN 2863 → 5912 m
              courseRating: 71.0, slopeRating: 132,
              facilityNotes: """
              Gegründet 1933 · ältester aktiver Golfclub Österreichs
              Wirling 36, 5351 Aigen-Voglhub / Bad Ischl
              Kontakt: www.gcsalzkammergut.at
              """),
        .init(name: "Golfclub Weyregg",                         location: "Weyregg am Attersee, OÖ",
              holes:  9, lat: 47.898, lon: 13.550,
              parValues: [5, 3, 3, 5, 3, 4, 3, 4, 4],  // Par 34 (9 Loch, 18-Loch-Wertung: Par 68)
              hcpValues: [15, 17, 13, 11, 5, 3, 7, 1, 9],
              holeLengths: [478, 138, 119, 430, 169, 288, 156, 350, 266],  // 2394 m (9 Loch)
              courseRating: 66.4, slopeRating: 123,
              facilityNotes: """
              9-Loch · 18-Loch-Layout mit 4 Abschlagvarianten
              Kontakt: www.gc-weyregg.at
              """),

        // ── Salzburg ──────────────────────────────────────────────────
        .init(name: "Golf & Country Club Salzburg-Klessheim",   location: "Wals-Siezenheim, Salzburg",
              holes: 18, lat: 47.822, lon: 13.004,
              courseRating: 70.9, slopeRating: 126,
              facilityNotes: """
              Design Robert Trent Jones Jr. (renoviert 2000)
              Gegründet 1955 · Schlosspark-Charakter
              Kontakt: www.golfclub-klessheim.com
              """),
        .init(name: "Golfclub Salzburg-Eugendorf",              location: "Eugendorf, Salzburg",
              holes: 18, lat: 47.878, lon: 13.119,
              parValues: [4, 4, 5, 4, 3, 4, 4, 5, 3,   // OUT 36
                          5, 4, 4, 4, 4, 3, 5, 3, 4],   // IN 36  → Par 72
              hcpValues: [12,  2,  6,  4, 18, 14, 10,  8, 16,
                           1,  9, 11, 13, 15, 17,  3,  5,  7],
              holeLengths: [342, 366, 484, 338, 141, 369, 303, 534, 159,   // OUT 3036
                            552, 432, 422, 354, 374, 164, 492, 178, 418],  // IN 3386 → 6422 m
              courseRating: 70.8, slopeRating: 134,
              facilityNotes: """
              Erbaut 1999
              Golfplatz 1, A-5301 Eugendorf
              Kontakt: www.golfclub-eugendorf.at
              """),
        .init(name: "Golfclub Römergolf Eugendorf",             location: "Eugendorf, Salzburg",
              holes: 18, lat: 47.876, lon: 13.126,
              parValues: [3, 4, 3, 4, 4, 5, 4, 4, 3,   // OUT 34
                          4, 4, 4, 4, 4, 3, 4, 4, 4],   // IN 35  → Par 69
              hcpValues: [17,  9,  7,  1, 11,  3,  5, 13, 15,
                           8,  4,  2, 10, 14, 12, 18,  6, 16],
              holeLengths: [154, 319, 112, 362, 279, 490, 357, 309, 110,   // OUT 2492
                            359, 357, 328, 276, 334, 131, 274, 339, 322],  // IN 2720 → 5212 m
              courseRating: 66.3, slopeRating: 124,
              facilityNotes: """
              Panorama-Course · Par 69 · Zusätzlich 9-Loch Kornbichl-Kurs (Par 60)
              Kraimoosweg 5a, 5301 Eugendorf
              Kontakt: www.roemergolf.at
              """),
        .init(name: "Golfclub Gut Altentann",                   location: "Henndorf am Wallersee, Salzburg",
              holes: 18, lat: 47.915, lon: 13.186,
              parValues: [4, 4, 3, 4, 4, 5, 3, 4, 5,   // OUT 36
                          3, 4, 5, 4, 3, 4, 4, 4, 5],   // IN 36  → Par 72
              hcpValues: [ 9, 11, 15, 17,  7, 13,  3,  5,  1,
                          12, 14, 18,  2,  8, 10,  4,  6, 16],
              holeLengths: [335, 348, 150, 353, 344, 479, 152, 360, 471,   // OUT 2992
                            140, 360, 462, 427, 179, 341, 393, 390, 475],  // IN 3167 → 6159 m
              courseRating: 70.5, slopeRating: 130,
              facilityNotes: """
              Design Jack Nicklaus & Rick Jacobson (1989)
              Hof 54, A-5302 Henndorf am Wallersee
              Kontakt: www.altentann.at
              """),
        .init(name: "Golf Club Zell am See-Kaprun",             location: "Zell am See, Salzburg",
              holes: 18, lat: 47.317, lon: 12.783,
              parValues: [5, 3, 4, 4, 4, 5, 4, 3, 5,   // OUT 37
                          4, 4, 4, 3, 4, 3, 4, 4, 5],   // IN 35  → Par 72
              hcpValues: [ 7,  5, 17,  1,  9, 11, 13, 15,  3,
                           4, 14, 10, 16, 18, 12,  8,  2,  6],
              holeLengths: [546, 232, 327, 360, 399, 494, 392, 183, 523,   // OUT 3456
                            396, 320, 370, 165, 318, 179, 382, 388, 566],  // IN 3084 → 6540 m
              courseRating: 72.5, slopeRating: 126,
              facilityNotes: """
              Schmittenhöhe-Course · Design Donald Harradine (1983)
              Zweiter Kurs: Kitzsteinhorn (Par 73)
              Golfstraße 25, Zell am See
              Kontakt: www.golfinzellamsee.at
              """),
        .init(name: "Golfclub Uttendorf",                       location: "Uttendorf, Salzburg",                   holes:  9, lat: 47.283, lon: 12.567),

        // ── Tschechien / Südböhmen ────────────────────────────────────
        .init(name: "Golfpark Böhmerwald Špičák",               location: "Železná Ruda, Tschechien",              holes:  9, lat: 49.183, lon: 13.183),
        .init(name: "Golf Rezort Lipno",                        location: "Lipno nad Vltavou, Tschechien",
              holes: 18, lat: 48.633, lon: 14.183,
              facilityNotes: "Golfplatz geschlossen · Anlage nicht mehr in Betrieb"),
        .init(name: "Golf Club Český Krumlov",                  location: "Velešín (Č. Krumlov), Tschechien",
              holes: 18, lat: 48.747, lon: 14.332,
              parValues: [4, 3, 4, 5, 4, 3, 3, 4, 5,   // OUT 35
                          4, 5, 4, 3, 4, 4, 5, 4, 3],   // IN 36  → Par 71
              hcpValues: [13, 15, 11,  3,  5, 17,  7,  1,  9,
                          10,  8, 18,  6,  2, 14,  4, 16, 12],
              holeLengths: [332, 108, 261, 442, 340, 139, 145, 352, 488,   // OUT 2607
                            344, 511, 261, 179, 412, 355, 469, 231, 120],  // IN 2882 → 5489 m
              courseRating: 68.0, slopeRating: 119,
              facilityNotes: """
              Erbaut 2006 · Privatclub
              Svachova Lhotka 1, 382 32 Velešín
              Kontakt: www.gccesky-krumlov.cz
              """),
        .init(name: "Golf Club Hluboká nad Vltavou",            location: "Hluboká nad Vltavou, Tschechien",
              holes: 18, lat: 49.051, lon: 14.434,
              parValues: [4, 4, 5, 3, 4, 4, 4, 3, 5,   // OUT 36
                          4, 4, 3, 4, 4, 3, 5, 4, 5],   // IN 36  → Par 72
              holeLengths: [348, 308, 568, 170, 376, 366, 359, 153, 527,   // OUT 3175
                            358, 301, 138, 385, 383, 195, 551, 337, 506],  // IN 3154 → 6329 m
              courseRating: 70.7, slopeRating: 121,
              facilityNotes: """
              Master Course · 68 ha unter Schloss Hluboká
              Zusätzlich 9-Loch-Öffentlichkeitskurs (Par 30)
              Kontakt: www.golfhluboka.cz
              """),
        .init(name: "Golf Resort Monachus",                     location: "Nová Bystřice, Tschechien",
              holes: 18, lat: 49.012, lon: 15.091,
              parValues: [4, 5, 3, 5, 4, 4, 4, 3, 4,   // OUT 36
                          3, 4, 5, 5, 4, 4, 3, 4, 5],   // IN 37  → Par 73
              hcpValues: [10,  6, 16, 14,  2, 18,  8,  4, 12,
                           9,  5, 17,  1,  7, 15, 13,  3, 11],
              holeLengths: [337, 472, 182, 484, 374, 314, 371, 208, 413,   // OUT 3155
                            170, 341, 469, 492, 417, 374, 161, 429, 505],  // IN 3358 → 6513 m
              courseRating: 72.8, slopeRating: 123,
              facilityNotes: """
              Mnich Course · Design Gerold & Gunther Hauser (2004)
              Zusätzlich 9-Loch Academy Course (Par 31)
              Nová Bystřice, Südböhmen
              Kontakt: www.monachus.cz
              """),
    ]
}
