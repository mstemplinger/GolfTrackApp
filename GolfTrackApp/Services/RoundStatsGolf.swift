import Foundation

/// Golfrunden der vollen App als anonyme Rundenstatistik (`RoundStatsService`).
extension RoundStatsService {

    /// Kennung im Verzeichnis – ohne sie gibt es keinen Betreiber, dem die
    /// Runde etwas nützt (selbst angelegte Plätze).
    static func catalogSlug(for round: Round) -> String? {
        guard let course = round.course else { return nil }
        return CrowdGeometryService.catalogSlug(for: course)
    }

    /// Ob diese Runde etwas beitragen kann – unabhängig von der Einwilligung.
    static func canContribute(_ round: Round) -> Bool {
        round.isComplete && catalogSlug(for: round) != nil && payload(for: round) != nil
    }

    /// Schläge und Putts je Spieler, ohne Namen. Der eigene Spieler zuerst,
    /// dann die Mitspieler in ihrer Reihenfolge.
    static func payload(for round: Round) -> Payload? {
        guard let course = round.course else { return nil }
        let holes = course.numberOfHoles
        guard holes > 0 else { return nil }

        var strokes: [[Int]] = []
        var putts: [[Int]] = []

        var ownStrokes = Array(repeating: 0, count: holes)
        var ownPutts = Array(repeating: 0, count: holes)
        for score in round.holeScores where (1...holes).contains(score.holeNumber) {
            ownStrokes[score.holeNumber - 1] = score.strokes
            ownPutts[score.holeNumber - 1] = score.putts
        }
        strokes.append(ownStrokes)
        putts.append(ownPutts)

        let others = Set(round.playerHoleScores.map(\.playerIndex)).sorted()
        for index in others.prefix(7) {
            var s = Array(repeating: 0, count: holes)
            var p = Array(repeating: 0, count: holes)
            for score in round.playerHoleScores
            where score.playerIndex == index && (1...holes).contains(score.holeNumber) {
                s[score.holeNumber - 1] = score.strokes
                p[score.holeNumber - 1] = score.putts
            }
            if s.contains(where: { $0 > 0 }) {
                strokes.append(s)
                putts.append(p)
            }
        }

        // Dauer nur aus einer echten Aufzeichnung; nachgetragene Runden haben
        // keine Laufspur mehr und bekommen deshalb keine Dauer.
        let start = round.track?.startedAt
        let end = round.track?.endedAt ?? .now
        let anyPutts = putts.contains { $0.contains { $0 > 0 } }
        return payload(kind: .golf,
                       startedAt: start,
                       endedAt: start == nil ? round.date : end,
                       strokes: strokes,
                       putts: anyPutts ? putts : nil,
                       teeColor: round.teeColor?.rawValue,
                       source: .app)
    }

    /// Nach dem Abschluss einer Golfrunde.
    func contribute(_ round: Round) {
        guard Self.hasConsent,
              let slug = Self.catalogSlug(for: round),
              let payload = Self.payload(for: round) else { return }
        contribute(slug: slug, payload: payload)
    }
}
