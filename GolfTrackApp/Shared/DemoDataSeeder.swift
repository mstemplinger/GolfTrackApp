//
//  DemoDataSeeder.swift
//  GolfTrackApp
//
//  NUR FÜR DEBUG-BUILDS. Befüllt die App mit einem realistischen Spielerprofil
//  (Plätze, Runden, Schläger-Messungen), damit Screenshots für Marketing und
//  Website nicht auf leere Zustände zeigen.
//
//  Auslösen:
//      xcrun simctl launch <udid> <bundle-id> -seedDemoData YES
//
//  Der Seeder löscht vorher alle Plätze, Runden und Bags — er ist bewusst
//  destruktiv und gehört deshalb niemals in einen Release-Build.
//

#if DEBUG

import SwiftUI
import SwiftData
import CoreLocation

// MARK: - Deterministischer Zufall

/// Kleiner LCG, damit jeder Seed-Lauf exakt dieselben Daten erzeugt.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next(_ upperBound: Int) -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int((state >> 33) % UInt64(max(1, upperBound)))
    }

    /// Ganzzahl in `range`, beide Grenzen inklusive.
    mutating func int(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + next(range.count)
    }

    /// True mit der Wahrscheinlichkeit `percent`.
    mutating func chance(_ percent: Int) -> Bool {
        next(100) < percent
    }

    mutating func double(in range: ClosedRange<Double>) -> Double {
        let t = Double(next(10_000)) / 10_000.0
        return range.lowerBound + t * (range.upperBound - range.lowerBound)
    }
}

// MARK: - Seeder

enum DemoDataSeeder {

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-seedDemoData")
            || UserDefaults.standard.bool(forKey: "seedDemoData")
    }

    // MARK: Platz-Vorlagen

    private struct CourseTemplate {
        let name: String
        let location: String
        let courseRating: Double
        let slopeRating: Int
        let latitude: Double
        let longitude: Double
        let pars: [Int]
    }

    private static let templates: [CourseTemplate] = [
        CourseTemplate(
            name: "GC Passau-Rassbach",
            location: "Bayern",
            courseRating: 71.2,
            slopeRating: 130,
            latitude: 48.6212,
            longitude: 13.4028,
            pars: [4, 5, 3, 4, 4, 3, 5, 4, 4,  4, 3, 5, 4, 4, 3, 4, 5, 4]
        ),
        CourseTemplate(
            name: "GC München Eichenried",
            location: "Bayern",
            courseRating: 73.5,
            slopeRating: 136,
            latitude: 48.2842,
            longitude: 11.8060,
            pars: [4, 4, 5, 3, 4, 4, 3, 5, 4,  4, 4, 3, 5, 4, 4, 3, 4, 5]
        ),
        CourseTemplate(
            name: "GC Schloss Egmating",
            location: "Bayern",
            courseRating: 70.8,
            slopeRating: 126,
            latitude: 48.0128,
            longitude: 11.7736,
            pars: [4, 3, 5, 4, 4, 4, 3, 4, 5,  4, 4, 3, 4, 5, 4, 3, 4, 4]
        )
    ]

    /// Brutto-Scores der letzten Runden, neueste zuerst.
    /// Ergibt mit den CR/Slope-Werten oben einen Index um 12.
    private static let grossScores: [Int] = [84, 88, 82, 91, 86, 89, 85, 93, 87, 90, 86, 92]

    // MARK: Hauptfunktion

    @MainActor
    static func seed(into context: ModelContext) {
        wipe(context)

        var rng = SeededRandom(seed: 20_260_808)

        // 1) Plätze
        let courses = templates.map { template -> Course in
            let holes = template.pars.count
            let course = Course(
                name: template.name,
                location: template.location,
                numberOfHoles: holes,
                parValues: template.pars,
                courseRating: template.courseRating,
                slopeRating: template.slopeRating,
                hcpValues: strokeIndexes(count: holes),
                holeLengths: template.pars.map { holeLength(par: $0, rng: &rng) },
                latitude: template.latitude,
                longitude: template.longitude
            )
            applyHoleCoordinates(to: course, base: template, rng: &rng)
            context.insert(course)
            return course
        }

        // 2) Schlägertasche mit echten Messwerten
        let bag = makeBag(context: context, rng: &rng)

        // 3) Runden – neueste zuerst, ca. alle 9–16 Tage eine
        var date = Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now

        for (index, gross) in grossScores.enumerated() {
            let course = courses[index % courses.count]
            let round = Round(date: date, course: course, gameMode: .strokePlay)
            round.isComplete = true
            round.bag = bag
            context.insert(round)

            let scores = makeHoleScores(course: course, gross: gross, rng: &rng)
            for score in scores {
                score.round = round
                context.insert(score)
                round.holeScores.append(score)
            }

            // Nur die jüngste Runde bekommt GPS-Schläge – das reicht für die
            // Schlagkarte und hält die Datenbank klein.
            if index == 0 {
                addShots(to: scores, course: course, rng: &rng)
                for score in scores {
                    for shot in score.shots { context.insert(shot) }
                }
            }

            date = Calendar.current.date(byAdding: .day, value: -rng.int(in: 9...16), to: date) ?? date
        }

        try? context.save()

        // 4) Profil-Einstellungen
        let defaults = UserDefaults.standard
        defaults.set("Alex", forKey: "playerName")
        defaults.set(true, forKey: "hasSeenOnboarding")
    }

    // MARK: Aufräumen

    @MainActor
    private static func wipe(_ context: ModelContext) {
        // Bewusst kein `delete(model:)`: der Batch-Delete lässt Runden zurück,
        // deren Platz per `.nullify` entkoppelt wurde — sie tauchen danach als
        // "Unbekannter Platz" im Verlauf auf. Einzeln löschen, Runden zuerst,
        // damit die Cascade-Regeln Löcher, Schläge und Laufspuren mitnehmen.
        deleteAll(Round.self, in: context)
        deleteAll(Course.self, in: context)
        deleteAll(HoleScore.self, in: context)
        deleteAll(Shot.self, in: context)
        deleteAll(PlayerHoleScore.self, in: context)
        deleteAll(RoundTrack.self, in: context)
        deleteAll(GolfBag.self, in: context)
        deleteAll(GolfClub.self, in: context)
        try? context.save()
    }

    @MainActor
    private static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) {
        guard let objects = try? context.fetch(FetchDescriptor<T>()) else { return }
        for object in objects { context.delete(object) }
    }

    // MARK: Löcher

    /// Stroke Index 1…n, gleichmäßig über die beiden Neuner verteilt.
    private static func strokeIndexes(count: Int) -> [Int] {
        var indexes = Array(1...count)
        // Ungerade Indizes auf die erste Hälfte, gerade auf die zweite —
        // so wie es auf echten Scorekarten üblich ist.
        let odd = indexes.filter { $0 % 2 == 1 }
        let even = indexes.filter { $0 % 2 == 0 }
        indexes = odd + even
        return indexes
    }

    private static func holeLength(par: Int, rng: inout SeededRandom) -> Int {
        switch par {
        case 3:  return rng.int(in: 125...185)
        case 5:  return rng.int(in: 445...510)
        default: return rng.int(in: 295...395)
        }
    }

    /// Verteilt `gross` auf die Löcher: erst alle auf Par, dann die
    /// Überschläge streuen — maximal +3 pro Loch, damit es echt wirkt.
    private static func makeHoleScores(course: Course,
                                       gross: Int,
                                       rng: inout SeededRandom) -> [HoleScore] {
        let pars = course.parValues
        var strokes = pars
        var remaining = gross - course.totalPar

        // Ein bis zwei Birdies pro Runde – sonst sieht der Verlauf leblos aus.
        let birdieCount = rng.int(in: 1...2)
        var birdieHoles = Set<Int>()
        while birdieHoles.count < birdieCount {
            let hole = rng.next(pars.count)
            if pars[hole] >= 4 { birdieHoles.insert(hole) }
        }
        for hole in birdieHoles {
            strokes[hole] -= 1
            remaining += 1
        }

        var guard_ = 0
        while remaining > 0 && guard_ < 500 {
            guard_ += 1
            let hole = rng.next(pars.count)
            if birdieHoles.contains(hole) { continue }
            if strokes[hole] - pars[hole] >= 3 { continue }
            strokes[hole] += 1
            remaining -= 1
        }

        return pars.indices.map { i in
            let par = pars[i]
            let shots = strokes[i]
            let overPar = shots - par

            // Grün in Regulation: par − 2 Schläge aufs Grün, danach ≤ 2 Putts.
            let gir = overPar <= 0 || (overPar == 1 && rng.chance(35))
            let putts: Int
            if gir {
                putts = rng.chance(22) ? 1 : 2
            } else {
                putts = overPar >= 2 && rng.chance(30) ? 3 : 2
            }

            let score = HoleScore(
                holeNumber: i + 1,
                strokes: shots,
                putts: putts,
                fairwayHit: par > 3 && rng.chance(56),
                greenInRegulation: gir
            )
            return score
        }
    }

    // MARK: GPS

    /// Legt Abschlag und Fahne pro Loch an. Die Löcher folgen einem Routing:
    /// Loch 1 startet am Clubhaus, jedes weitere Loch schließt in der Nähe des
    /// vorigen Grüns an, mit wechselnden Richtungen. Ein exakter Kreis würde
    /// auf der Schlagkarte sofort künstlich aussehen.
    private static func applyHoleCoordinates(to course: Course,
                                             base: CourseTemplate,
                                             rng: inout SeededRandom) {
        let latPerMeter = 1.0 / 111_320.0
        let lonPerMeter = 1.0 / (111_320.0 * cos(base.latitude * .pi / 180))

        var current = CLLocationCoordinate2D(latitude: base.latitude, longitude: base.longitude)
        // Startrichtung, danach dreht das Routing sich langsam einmal herum.
        var heading = rng.double(in: 0...(2 * .pi))

        for hole in 1...course.numberOfHoles {
            let lengthMeters = Double(course.holeLengths[hole - 1])

            // Dogleg: das Grün liegt nicht exakt in Abschlagrichtung.
            let dogleg = rng.double(in: -0.42...0.42)
            let flagHeading = heading + dogleg

            let flag = CLLocationCoordinate2D(
                latitude: current.latitude + cos(flagHeading) * lengthMeters * latPerMeter,
                longitude: current.longitude + sin(flagHeading) * lengthMeters * lonPerMeter
            )

            course.setTeeCoordinate(current, forHole: hole)
            course.setFlagCoordinate(flag, forHole: hole)

            // Nächster Abschlag: kurzer Weg vom Grün, Richtung dreht weiter.
            heading = flagHeading + rng.double(in: 0.35...1.25)
            let walk = rng.double(in: 40...110)
            current = CLLocationCoordinate2D(
                latitude: flag.latitude + cos(heading) * walk * latPerMeter,
                longitude: flag.longitude + sin(heading) * walk * lonPerMeter
            )
        }
    }

    /// Baut je Loch eine Schlagkette vom Abschlag Richtung Fahne.
    private static func addShots(to scores: [HoleScore],
                                 course: Course,
                                 rng: inout SeededRandom) {
        for score in scores {
            guard let tee = course.teeCoordinate(forHole: score.holeNumber),
                  let flag = course.flagCoordinate(forHole: score.holeNumber) else { continue }

            let approachShots = max(1, score.strokes - score.putts)
            var current = tee

            // Der erste Schlag deckt den Großteil der Bahn ab, danach wird es
            // kürzer — gleich lange Segmente sähen auf der Karte falsch aus.
            var weights: [Double] = []
            var weight = 1.0
            for _ in 0..<approachShots {
                weights.append(weight)
                weight *= 0.45
            }
            let weightSum = weights.reduce(0, +)

            var covered = 0.0
            for shotNumber in 1...approachShots {
                covered += weights[shotNumber - 1] / weightSum
                let progress = min(1.0, covered)
                // Streuung quer zur Spielrichtung, damit die Karte nicht wie
                // eine gezogene Linie aussieht.
                let drift = rng.double(in: -0.00025...0.00025)
                let target = CLLocationCoordinate2D(
                    latitude: tee.latitude + (flag.latitude - tee.latitude) * progress + drift,
                    longitude: tee.longitude + (flag.longitude - tee.longitude) * progress + drift
                )
                let shot = Shot(shotNumber: shotNumber, from: current, to: target)
                shot.club = clubName(forDistance: shot.distanceMeters, isTeeShot: shotNumber == 1)
                shot.holeScore = score
                score.shots.append(shot)
                current = target
            }
        }
    }

    /// Ordnet einem gemessenen Schlag den plausibelsten Schläger zu, damit die
    /// Distanz-Statistik pro Schläger stimmig bleibt.
    private static func clubName(forDistance meters: Double, isTeeShot: Bool) -> String {
        switch meters {
        case 200...:   return isTeeShot ? "Driver" : "3 Wood"
        case 178..<200: return "3 Eisen"
        case 160..<178: return "5 Eisen"
        case 148..<160: return "6 Eisen"
        case 136..<148: return "7 Eisen"
        case 124..<136: return "8 Eisen"
        case 112..<124: return "9 Eisen"
        case 100..<112: return "PW"
        case 70..<100:  return "GW"
        default:        return "SW"
        }
    }

    // MARK: Schlägertasche

    private static func makeBag(context: ModelContext, rng: inout SeededRandom) -> GolfBag {
        let bag = GolfBag(name: "Standard")
        context.insert(bag)

        let defaults: [(String, Int, Bool)] = [
            ("Driver", 220, false), ("3 Wood", 195, false), ("5 Wood", 180, false),
            ("3 Eisen", 185, false), ("4 Eisen", 175, false), ("5 Eisen", 165, false),
            ("6 Eisen", 155, false), ("7 Eisen", 145, false), ("8 Eisen", 130, false),
            ("9 Eisen", 120, false), ("PW", 110, false), ("GW", 95, false),
            ("SW", 80, false), ("LW", 60, false), ("Putter", 10, true)
        ]

        for (i, (name, dist, isPutter)) in defaults.enumerated() {
            let club = GolfClub(name: name, averageDistance: dist, order: i, isPutter: isPutter)
            if !isPutter {
                // Zwischen 6 und 18 Messungen pro Schläger, leicht unter der
                // Katalog-Weite — so schlägt ein realer Spieler.
                let measurements = rng.int(in: 6...18)
                let center = Double(dist) * rng.double(in: 0.93...0.99)
                for _ in 0..<measurements {
                    club.addMeasurement(center + rng.double(in: -9...9))
                }
            }
            club.bag = bag
            context.insert(club)
            bag.clubs.append(club)
        }
        return bag
    }
}

// MARK: - View-Hook

private struct DemoDataSeedModifier: ViewModifier {
    @Environment(\.modelContext) private var context
    @State private var didRun = false

    func body(content: Content) -> some View {
        content.task {
            guard !didRun, DemoDataSeeder.isRequested else { return }
            didRun = true
            DemoDataSeeder.seed(into: context)
        }
    }
}

extension View {
    /// Befüllt die App mit Demodaten, wenn sie mit `-seedDemoData` startet.
    /// In Release-Builds existiert diese Methode als No-op.
    func seedDemoDataIfRequested() -> some View {
        modifier(DemoDataSeedModifier())
    }
}

#else

import SwiftUI

extension View {
    func seedDemoDataIfRequested() -> some View { self }
}

#endif
