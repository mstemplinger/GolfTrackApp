//
//  DemoRoundSimulator.swift
//  GolfTrackApp
//
//  NUR FÜR DEBUG-BUILDS. Erzeugt eine abgeschlossene Runde mit vollständiger
//  Laufspur, damit man das Positions-Tracking ohne echte Runde ansehen kann –
//  für Screenshots, Marketing und zum Prüfen der Ableitung.
//
//  Auslösen:
//      xcrun simctl launch <udid> <bundle-id> -simulateTrackedRound YES
//
//  Wichtig: Die Punkte werden über denselben Codeweg gespeichert wie im
//  Betrieb (RoundTrack.append) und die Ableitung rechnet anschließend mit den
//  echten Services. Simuliert sind nur die GPS-Positionen selbst.
//

#if DEBUG

import SwiftUI
import SwiftData
import CoreLocation

enum DemoRoundSimulator {

    /// Markierung in `Round.notes`, damit ein erneuter Lauf die alte Demo-Runde
    /// ersetzt statt sie zu vervielfachen.
    private static let marker = "[Demo-Laufspur]"

    /// Schreibt eine Diagnosezeile in die Documents – print() kommt beim
    /// Simulator-Start nicht zuverlässig an.
    static func log(_ message: String) {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        let file = dir.appendingPathComponent("demo-round-simulator.log")
        let line = message + "\n"
        if let handle = try? FileHandle(forWritingTo: file) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            try? handle.close()
        } else {
            try? line.write(to: file, atomically: true, encoding: .utf8)
        }
    }

    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-simulateTrackedRound")
    }

    /// Wie viele Löcher simuliert werden. 18 dauert im UI etwas beim Rechnen.
    private static let holeCount = 18

    // MARK: - Ablauf

    @MainActor
    static func run(context: ModelContext) {
        let course = ensureCourse(in: context)
        guard course.hasHolePositions else {
            log("abgebrochen: Platz ohne Lochpositionen")
            return
        }

        removePreviousDemoRounds(in: context)

        // Mehrere Runden: mit einer einzigen bleibt der Fairway-Korridor
        // zwangsläufig "sehr dünn", weil pro 10-m-Abschnitt kaum zwei
        // Messwerte zusammenkommen.
        for index in 0..<roundCount {
            simulateOne(course: course, index: index, context: context)
        }
        try? context.save()
        log("fertig: \(roundCount) Runden erzeugt")
    }

    /// Wie viele Runden erzeugt werden.
    private static let roundCount = 4

    @MainActor
    private static func simulateOne(course: Course, index: Int, context: ModelContext) {
        var rng = DemoRandom(seed: 20_260_814 &+ UInt64(index) &* 7919)
        // Jede Runde läuft etwas anders – sonst liegen alle Spuren übereinander.
        let bias = Double(index - 1) * 6
        let round = Round(date: Date.now.addingTimeInterval(Double(-index) * 7 * 86_400),
                          course: course, notes: marker)
        context.insert(round)
        course.rounds.append(round)

        let track = RoundTrack(startedAt: Date.now.addingTimeInterval(-4 * 3600))
        context.insert(track)
        track.round = round
        round.track = track

        var points: [TrackPoint] = []
        var time: Double = 0

        for hole in 1...min(holeCount, course.numberOfHoles) {
            guard let tee = course.teeCoordinate(forHole: hole),
                  let green = course.flagCoordinate(forHole: hole) else { continue }

            let par = course.parValues[hole - 1]
            let score = HoleScore(holeNumber: hole,
                                  strokes: par + rng.int(in: -1...2),
                                  putts: rng.int(in: 1...3),
                                  fairwayHit: par > 3 && rng.chance(60),
                                  greenInRegulation: rng.chance(45))
            context.insert(score)
            round.holeScores.append(score)

            // 1) Warten und Abschlagen: Stillstand über ~40 s
            points += stand(at: tee, from: &time, seconds: 40, spread: 3, rng: &rng, hole: hole)

            // 2) Weg zum Grün, mit seitlichem Wackeln – man läuft zu seinem Ball
            points += walk(from: tee, to: green, from: &time, hole: hole, rng: &rng, bias: bias)

            // 3) Putten: Stillstand über ~30 s
            points += stand(at: green, from: &time, seconds: 30, spread: 3, rng: &rng, hole: hole)

            // 4) Schläge: Abschlag Richtung Grün, dann aufs Grün
            addShots(to: score, tee: tee, green: green, par: par, context: context, rng: &rng)

            // 5) Übergang zum nächsten Abschlag
            if hole < min(holeCount, course.numberOfHoles),
               let nextTee = course.teeCoordinate(forHole: hole + 1) {
                points += walk(from: green, to: nextTee, from: &time,
                               hole: hole, rng: &rng, steps: 10, wobble: 4)
            }
        }

        track.append(points)
        track.endedAt = track.startedAt.addingTimeInterval(time)
        round.isComplete = true
        log("Runde \(index + 1): \(points.count) Punkte über \(Int(time / 60)) min")
    }

    // MARK: - Bausteine

    /// Punkte für einen Stillstand: kleine Streuung um dieselbe Stelle.
    private static func stand(at coord: CLLocationCoordinate2D,
                              from time: inout Double,
                              seconds: Double,
                              spread: Double,
                              rng: inout DemoRandom,
                              hole: Int) -> [TrackPoint] {
        let step = 8.0
        var result: [TrackPoint] = []
        var elapsed = 0.0
        while elapsed <= seconds {
            let jittered = offset(coord,
                                  north: rng.double(in: -spread...spread),
                                  east: rng.double(in: -spread...spread))
            result.append(TrackPoint(latitude: jittered.latitude,
                                     longitude: jittered.longitude,
                                     timeOffset: time,
                                     accuracy: rng.double(in: 4...9),
                                     holeNumber: hole))
            elapsed += step
            time += step
        }
        return result
    }

    /// Punkte für einen Gehweg zwischen zwei Koordinaten.
    private static func walk(from start: CLLocationCoordinate2D,
                             to end: CLLocationCoordinate2D,
                             from time: inout Double,
                             hole: Int,
                             rng: inout DemoRandom,
                             steps: Int = 34,
                             wobble: Double = 11,
                             bias: Double = 0) -> [TrackPoint] {
        var result: [TrackPoint] = []
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let base = CLLocationCoordinate2D(
                latitude: start.latitude + (end.latitude - start.latitude) * t,
                longitude: start.longitude + (end.longitude - start.longitude) * t)
            // Seitlicher Versatz: sanft schwingend plus Rauschen
            let lateral = sin(t * .pi * 1.7) * wobble + rng.double(in: -3...3) + bias
            let bearing = atan2(end.longitude - start.longitude,
                                end.latitude - start.latitude)
            let jittered = offset(base,
                                  north: cos(bearing + .pi / 2) * lateral,
                                  east: sin(bearing + .pi / 2) * lateral)
            result.append(TrackPoint(latitude: jittered.latitude,
                                     longitude: jittered.longitude,
                                     timeOffset: time,
                                     accuracy: rng.double(in: 4...11),
                                     holeNumber: hole))
            time += 7
        }
        return result
    }

    /// Zwei bis drei getrackte Schläge pro Loch entlang der Spielrichtung.
    private static func addShots(to score: HoleScore,
                                 tee: CLLocationCoordinate2D,
                                 green: CLLocationCoordinate2D,
                                 par: Int,
                                 context: ModelContext,
                                 rng: inout DemoRandom) {
        let fractions: [Double] = par > 4 ? [0, 0.45, 0.8] : (par == 3 ? [0] : [0, 0.62])
        for (index, from) in fractions.enumerated() {
            let to = index + 1 < fractions.count ? fractions[index + 1] : 1.0
            let a = along(tee: tee, green: green, t: from, sideways: rng.double(in: -14...14))
            let b = along(tee: tee, green: green, t: to, sideways: rng.double(in: -12...12))
            let shot = Shot(shotNumber: index + 1, from: a, to: b,
                            club: index == 0 ? "Driver" : "7 Eisen")
            context.insert(shot)
            shot.holeScore = score
        }
    }

    // MARK: - Geometrie

    private static func along(tee: CLLocationCoordinate2D,
                              green: CLLocationCoordinate2D,
                              t: Double,
                              sideways: Double) -> CLLocationCoordinate2D {
        let base = CLLocationCoordinate2D(
            latitude: tee.latitude + (green.latitude - tee.latitude) * t,
            longitude: tee.longitude + (green.longitude - tee.longitude) * t)
        let bearing = atan2(green.longitude - tee.longitude, green.latitude - tee.latitude)
        return offset(base,
                      north: cos(bearing + .pi / 2) * sideways,
                      east: sin(bearing + .pi / 2) * sideways)
    }

    private static func offset(_ base: CLLocationCoordinate2D,
                               north: Double, east: Double) -> CLLocationCoordinate2D {
        let metersPerLat = 111_320.0
        let metersPerLon = 111_320.0 * cos(base.latitude * .pi / 180)
        return CLLocationCoordinate2D(latitude: base.latitude + north / metersPerLat,
                                      longitude: base.longitude + east / metersPerLon)
    }

    // MARK: - Platz und Aufräumen

    /// Nimmt den ersten Platz mit Lochpositionen, sonst den ersten gebündelten,
    /// der welche mitbringt.
    @MainActor
    private static func ensureCourse(in context: ModelContext) -> Course {
        let existing = (try? context.fetch(FetchDescriptor<Course>())) ?? []
        if let ready = existing.first(where: \.hasHolePositions) { return ready }

        let entry = BundledCourses.all.first { !$0.teeLatitudes.isEmpty && !$0.flagLatitudes.isEmpty }
        guard let entry else { return existing.first ?? Course(name: "Demo") }

        let course = Course(
            name: entry.name, location: entry.location, numberOfHoles: entry.holes,
            parValues: entry.parValues.isEmpty ? nil : entry.parValues,
            courseRating: entry.courseRating, slopeRating: entry.slopeRating,
            hcpValues: entry.hcpValues, holeLengths: entry.holeLengths,
            facilityNotes: entry.facilityNotes, latitude: entry.lat, longitude: entry.lon,
            teeLatitudes: entry.teeLatitudes, teeLongitudes: entry.teeLongitudes,
            flagLatitudes: entry.flagLatitudes, flagLongitudes: entry.flagLongitudes)
        context.insert(course)
        return course
    }

    /// Räumt alle vorhandenen Runden weg, damit die Demo-Runde allein dasteht –
    /// sonst hängt eine halbfertige Runde als "aktiv" auf der Startseite und
    /// verdeckt beim Ansehen die Demo. Bewusst destruktiv, wie der Demo-Seeder.
    @MainActor
    private static func removePreviousDemoRounds(in context: ModelContext) {
        for round in (try? context.fetch(FetchDescriptor<Round>())) ?? [] {
            context.delete(round)
        }
    }
}

// MARK: - Deterministischer Zufall

/// Kleiner LCG, damit jeder Lauf dieselbe Runde erzeugt.
private struct DemoRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    private mutating func next(_ bound: Int) -> Int {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int((state >> 33) % UInt64(max(1, bound)))
    }

    mutating func int(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + next(range.count)
    }

    mutating func chance(_ percent: Int) -> Bool { next(100) < percent }

    mutating func double(in range: ClosedRange<Double>) -> Double {
        let t = Double(next(10_000)) / 10_000
        return range.lowerBound + t * (range.upperBound - range.lowerBound)
    }
}

// MARK: - View-Anbindung

extension View {
    @ViewBuilder
    func simulateTrackedRoundIfRequested() -> some View {
        modifier(DemoRoundSimulatorModifier())
    }
}

private struct DemoRoundSimulatorModifier: ViewModifier {
    @Environment(\.modelContext) private var context
    @State private var done = false

    func body(content: Content) -> some View {
        content.task {
            DemoRoundSimulator.log("task lief, isRequested=\(DemoRoundSimulator.isRequested), args=\(ProcessInfo.processInfo.arguments.joined(separator: " "))")
            guard DemoRoundSimulator.isRequested, !done else { return }
            done = true
            DemoRoundSimulator.run(context: context)
        }
    }
}

#else

import SwiftUI

extension View {
    func simulateTrackedRoundIfRequested() -> some View { self }
}

#endif
