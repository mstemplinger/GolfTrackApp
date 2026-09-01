import Foundation
import SwiftUI

// MARK: - Notification zum Öffnen des Training-Tabs

extension Notification.Name {
    /// Wechselt zum Training-Tab. userInfo["category"] = TrainingCategory.rawValue (optional)
    static let openTraining = Notification.Name("openTraining")
}

// MARK: - Empfehlung

struct TrainingRecommendation: Identifiable {
    var id: String { lesson.id }
    let lesson: TrainingLesson
    /// Kurzer, statistikbasierter Grund für die Empfehlung
    let reason: LocalizedStringResource
    /// Knappe Kennzahl, z. B. "Ø 2,1 Putts/Loch" – nil, wenn es keine auffällige Zahl gibt
    let statLabel: String?
    /// Höher = dringlicher; steuert die Reihenfolge
    let severity: Double
}

// MARK: - Empfehlungs-Engine

enum TrainingRecommender {

    /// Leitet aus den letzten abgeschlossenen Runden passende Audio-Lektionen ab.
    /// Gibt eine leere Liste zurück, wenn noch zu wenige Daten vorliegen.
    static func recommendations(from rounds: [Round], limit: Int = 3) -> [TrainingRecommendation] {
        let recent = rounds
            .filter { $0.isComplete }
            .sorted { $0.date > $1.date }
            .prefix(8)

        let metrics = metrics(for: Array(recent))
        guard metrics.playedHoles >= 5 else { return [] }

        return Array(rules(for: metrics).sorted { $0.severity > $1.severity }.prefix(limit))
    }

    /// Leitet Empfehlungen aus genau einer – typischerweise gerade beendeten – Runde ab.
    ///
    /// Anders als `recommendations(from:)` ist das Ergebnis nie leer, sobald die Runde
    /// genug gespielte Löcher hat: Findet sich keine Schwäche, kommt eine Lektion zum
    /// Dranbleiben zurück. Damit hat der Rundenabschluss immer etwas zum Anhören.
    static func recommendations(forRound round: Round, limit: Int = 2) -> [TrainingRecommendation] {
        let metrics = metrics(for: [round])
        guard metrics.playedHoles >= 5 else { return [] }

        let matches = rules(for: metrics).sorted { $0.severity > $1.severity }
        guard matches.isEmpty else { return Array(matches.prefix(limit)) }

        return encouragement(for: round, limit: limit)
    }

    // MARK: Kennzahlen

    /// Zusammengefasste Rundenkennzahlen, aus denen die Regeln ihre Empfehlung ziehen.
    private struct Metrics {
        var playedHoles = 0
        var puttSum     = 0
        var fairwayHit  = 0
        var fairwayOpp  = 0
        var girHit      = 0
        var girOpp      = 0
        var blowUps     = 0
        var scoredHoles = 0
    }

    private static func metrics(for rounds: [Round]) -> Metrics {
        var m = Metrics()

        for round in rounds {
            m.playedHoles += round.playedScores.count
            m.puttSum     += round.totalPutts
            m.fairwayHit  += round.fairwaysHit
            m.fairwayOpp  += round.fairwayOpportunities
            m.girHit      += round.greensInRegulation
            m.girOpp      += round.girOpportunities

            if let course = round.course {
                let pars = course.parValues
                for s in round.playedScores where s.strokes > 0 {
                    m.scoredHoles += 1
                    let idx = s.holeNumber - 1
                    if idx >= 0, idx < pars.count, s.strokes >= pars[idx] + 3 {
                        m.blowUps += 1
                    }
                }
            }
        }

        return m
    }

    // MARK: Regeln

    private static func rules(for m: Metrics) -> [TrainingRecommendation] {
        var recs: [TrainingRecommendation] = []

        // Putten
        let avgPutts = Double(m.puttSum) / Double(m.playedHoles)
        if avgPutts >= 1.9, let l = lesson("06") {
            recs.append(TrainingRecommendation(
                lesson: l,
                reason: "Du brauchst noch viele Putts. Diese Lektion trainiert deine Distanzkontrolle auf dem Grün.",
                statLabel: puttsLabel(avgPutts),
                severity: (avgPutts - 1.9) + 0.30
            ))
        }

        // Fairways / Abschlag
        if m.fairwayOpp >= 5 {
            let pct = Double(m.fairwayHit) / Double(m.fairwayOpp)
            if pct < 0.45, let l = lesson("02") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Wenige Fairways getroffen. Mehr Stabilität im Stand sorgt für geradere Abschläge.",
                    statLabel: fairwayLabel(pct),
                    severity: (0.45 - pct) + 0.30
                ))
            }
        }

        // Grüns in Regulation / Anspiel
        if m.girOpp >= 5 {
            let pct = Double(m.girHit) / Double(m.girOpp)
            if pct < 0.30, let l = lesson("10") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Selten das Grün in Regulation getroffen. Die richtige Schlägerwahl beim Anspiel hilft.",
                    statLabel: girLabel(pct),
                    severity: (0.30 - pct) + 0.20
                ))
            }
        }

        // Hohe Löcher / Course Management
        if m.scoredHoles >= 9 {
            let rate = Double(m.blowUps) / Double(m.scoredHoles)
            if rate >= 0.15, let l = lesson("09") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Immer wieder hohe Löcher (3+ über Par). Cleveres Course Management senkt deinen Score.",
                    statLabel: blowUpLabel(rate),
                    severity: rate + 0.10
                ))
            }
        }

        // Grünlesen (17) – wenn Putts leicht erhöht (unterhalb des Lesson-06-Schwellwerts)
        if avgPutts >= 1.75, avgPutts < 1.9, let l = lesson("17") {
            recs.append(TrainingRecommendation(
                lesson: l,
                reason: "Etwas zu viele Putts. Besseres Grünlesen kann direkt Schläge sparen.",
                statLabel: puttsLabel(avgPutts),
                severity: (avgPutts - 1.75) * 0.8
            ))
        }

        // Rough-Spiel (14) – wenn wenig Fairways getroffen
        if m.fairwayOpp >= 5 {
            let pct = Double(m.fairwayHit) / Double(m.fairwayOpp)
            if pct < 0.40, let l = lesson("14") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Du landest oft im Rough. Diese Lektion zeigt, wie du trotzdem gute Schläge spielst.",
                    statLabel: fairwayLabel(pct),
                    severity: (0.40 - pct) * 0.6
                ))
            }
        }

        // Fade & Draw (13) – wenn GIR im mittleren Bereich (gezieltes Schlagformen hilft)
        if m.girOpp >= 5 {
            let pct = Double(m.girHit) / Double(m.girOpp)
            if pct >= 0.15, pct < 0.45, let l = lesson("13") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Dein Anspiel hat Potenzial. Gezielte Schlagformen bringen dich näher an die Fahne.",
                    statLabel: girLabel(pct),
                    severity: 0.12
                ))
            }
        }

        // Tempo & Rhythmus (16) – bei mittlerer Blow-up-Rate (unter dem Lesson-09-Schwellwert)
        if m.scoredHoles >= 9 {
            let rate = Double(m.blowUps) / Double(m.scoredHoles)
            if rate >= 0.10, rate < 0.15, let l = lesson("16") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Einzelne Löcher kosten dir zu viele Schläge. Gleichmäßiges Tempo hilft bei Drucksituationen.",
                    statLabel: blowUpLabel(rate),
                    severity: rate * 0.5
                ))
            }
        }

        return recs
    }

    // MARK: Fallback ohne Schwäche

    /// Lektionen, die nach einer runden Sache zum Dranbleiben passen. Die Auswahl
    /// rotiert über das Rundendatum, damit nicht nach jeder guten Runde dasselbe steht.
    private static let encouragementLessonIDs = ["07", "15", "16", "09"]

    private static func encouragement(for round: Round, limit: Int) -> [TrainingRecommendation] {
        let pool = encouragementLessonIDs.compactMap { lesson($0) }
        guard !pool.isEmpty else { return [] }

        let day = Calendar.current.ordinality(of: .day, in: .year, for: round.date) ?? 1
        let start = (day - 1) % pool.count
        let rotated = (0 ..< pool.count).map { pool[(start + $0) % pool.count] }

        return rotated.prefix(limit).enumerated().map { offset, lesson in
            TrainingRecommendation(
                lesson: lesson,
                reason: "Runde ohne auffällige Schwäche. Diese Lektion hilft dir, das Niveau zu halten.",
                statLabel: nil,
                severity: 0.01 - Double(offset) * 0.001
            )
        }
    }

    // MARK: Kennzahl-Labels

    private static func puttsLabel(_ avgPutts: Double) -> String {
        let value = avgPutts.formatted(.number.precision(.fractionLength(1)))
        return String(format: String(localized: "Ø %@ Putts/Loch"), value)
    }

    private static func fairwayLabel(_ pct: Double) -> String {
        String(format: String(localized: "%@ Fairways"), percent(pct))
    }

    private static func girLabel(_ pct: Double) -> String {
        String(format: String(localized: "%@ GIR"), percent(pct))
    }

    private static func blowUpLabel(_ rate: Double) -> String {
        String(format: String(localized: "%@ Löcher 3+ über Par"), percent(rate))
    }

    private static func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    private static func lesson(_ id: String) -> TrainingLesson? {
        allLessons.first { $0.id == id && $0.isAvailable }
    }
}
