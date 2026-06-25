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
    let reason: String
    /// Knappe Kennzahl, z. B. "Ø 2,1 Putts/Loch"
    let statLabel: String
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

        var playedHoles = 0
        var puttSum     = 0
        var fairwayHit  = 0, fairwayOpp = 0
        var girHit      = 0, girOpp     = 0
        var blowUps     = 0, scoredHoles = 0

        for round in recent {
            playedHoles += round.playedScores.count
            puttSum     += round.totalPutts
            fairwayHit  += round.fairwaysHit
            fairwayOpp  += round.fairwayOpportunities
            girHit      += round.greensInRegulation
            girOpp      += round.girOpportunities

            if let course = round.course {
                let pars = course.parValues
                for s in round.playedScores where s.strokes > 0 {
                    scoredHoles += 1
                    let idx = s.holeNumber - 1
                    if idx >= 0, idx < pars.count, s.strokes >= pars[idx] + 3 {
                        blowUps += 1
                    }
                }
            }
        }

        // Zu wenig Datenbasis → keine Empfehlung
        guard playedHoles >= 5 else { return [] }

        var recs: [TrainingRecommendation] = []

        // Putten
        let avgPutts = Double(puttSum) / Double(playedHoles)
        if avgPutts >= 1.9, let l = lesson("06") {
            recs.append(TrainingRecommendation(
                lesson: l,
                reason: "Du brauchst noch viele Putts. Diese Lektion trainiert deine Distanzkontrolle auf dem Grün.",
                statLabel: String(format: "Ø %.1f Putts/Loch", avgPutts).replacingOccurrences(of: ".", with: ","),
                severity: (avgPutts - 1.9) + 0.30
            ))
        }

        // Fairways / Abschlag
        if fairwayOpp >= 5 {
            let pct = Double(fairwayHit) / Double(fairwayOpp)
            if pct < 0.45, let l = lesson("02") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Wenige Fairways getroffen. Mehr Stabilität im Stand sorgt für geradere Abschläge.",
                    statLabel: String(format: "%.0f%% Fairways", pct * 100),
                    severity: (0.45 - pct) + 0.30
                ))
            }
        }

        // Grüns in Regulation / Anspiel
        if girOpp >= 5 {
            let pct = Double(girHit) / Double(girOpp)
            if pct < 0.30, let l = lesson("10") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Selten das Grün in Regulation getroffen. Die richtige Schlägerwahl beim Anspiel hilft.",
                    statLabel: String(format: "%.0f%% GIR", pct * 100),
                    severity: (0.30 - pct) + 0.20
                ))
            }
        }

        // Hohe Löcher / Course Management
        if scoredHoles >= 9 {
            let rate = Double(blowUps) / Double(scoredHoles)
            if rate >= 0.15, let l = lesson("09") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Immer wieder hohe Löcher (3+ über Par). Cleveres Course Management senkt deinen Score.",
                    statLabel: String(format: "%.0f%% Löcher 3+ über Par", rate * 100),
                    severity: rate + 0.10
                ))
            }
        }

        // Grünlesen (17) – wenn Putts leicht erhöht (unterhalb des Lesson-06-Schwellwerts)
        if avgPutts >= 1.75, avgPutts < 1.9, let l = lesson("17") {
            recs.append(TrainingRecommendation(
                lesson: l,
                reason: "Etwas zu viele Putts. Besseres Grünlesen kann direkt Schläge sparen.",
                statLabel: String(format: "Ø %.1f Putts/Loch", avgPutts).replacingOccurrences(of: ".", with: ","),
                severity: (avgPutts - 1.75) * 0.8
            ))
        }

        // Rough-Spiel (14) – wenn wenig Fairways getroffen
        if fairwayOpp >= 5 {
            let pct = Double(fairwayHit) / Double(fairwayOpp)
            if pct < 0.40, let l = lesson("14") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Du landest oft im Rough. Diese Lektion zeigt, wie du trotzdem gute Schläge spielst.",
                    statLabel: String(format: "%.0f%% Fairways", pct * 100),
                    severity: (0.40 - pct) * 0.6
                ))
            }
        }

        // Fade & Draw (13) – wenn GIR im mittleren Bereich (gezieltes Schlagformen hilft)
        if girOpp >= 5 {
            let pct = Double(girHit) / Double(girOpp)
            if pct >= 0.15, pct < 0.45, let l = lesson("13") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Dein Anspiel hat Potenzial. Gezielte Schlagformen bringen dich näher an die Fahne.",
                    statLabel: String(format: "%.0f%% GIR", pct * 100),
                    severity: 0.12
                ))
            }
        }

        // Tempo & Rhythmus (16) – bei mittlerer Blow-up-Rate (unter dem Lesson-09-Schwellwert)
        if scoredHoles >= 9 {
            let rate = Double(blowUps) / Double(scoredHoles)
            if rate >= 0.10, rate < 0.15, let l = lesson("16") {
                recs.append(TrainingRecommendation(
                    lesson: l,
                    reason: "Einzelne Löcher kosten dir zu viele Schläge. Gleichmäßiges Tempo hilft bei Drucksituationen.",
                    statLabel: String(format: "%.0f%% Löcher 3+ über Par", rate * 100),
                    severity: rate * 0.5
                ))
            }
        }

        return Array(recs.sorted { $0.severity > $1.severity }.prefix(limit))
    }

    private static func lesson(_ id: String) -> TrainingLesson? {
        allLessons.first { $0.id == id && $0.isAvailable }
    }
}
