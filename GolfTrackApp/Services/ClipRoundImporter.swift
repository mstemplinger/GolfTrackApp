import Foundation
import SwiftData

/// Übernimmt Runden, die im App Clip gezählt wurden, in die richtige App.
///
/// Der Clip schreibt in die gemeinsame App-Gruppe (`GolfLiteStore`), weil ihm
/// SwiftData fehlt – das Rundenmodell mitzunehmen hätte ihn gesprengt. Wer
/// nach der Runde installiert, soll sie trotzdem wiederfinden: Beim Start
/// holt die App sie hier ab und macht echte `Round`-Einträge daraus.
///
/// Läuft genau einmal je Runde: Was übernommen ist, wird aus der Gruppe
/// gelöscht.
@MainActor
enum ClipRoundImporter {

    /// Abgeschlossene und angefangene Clip-Runden übernehmen.
    /// - Returns: wie viele Runden angelegt wurden.
    @discardableResult
    static func importPendingRounds(into context: ModelContext) -> Int {
        var imported = 0

        for saved in GolfLiteStore.loadHistory() {
            if makeRound(from: saved, complete: true, in: context) { imported += 1 }
        }
        // Eine angefangene Runde kommt als unvollständige Runde herein – die
        // App zeigt sie unter den offenen Runden, und es lässt sich
        // weiterspielen, statt dass neun Löcher verloren gehen.
        if let open = GolfLiteStore.load(),
           makeRound(from: open, complete: false, in: context) {
            imported += 1
        }

        guard imported > 0 else { return 0 }

        // Erst sichern, dann löschen – und **nur** wenn das Sichern geklappt
        // hat. Andersherum wäre die Runde weg, sobald SwiftData muckt.
        do {
            try context.save()
        } catch {
            print("[ClipRoundImporter] Sichern fehlgeschlagen, Gruppe bleibt unangetastet: \(error)")
            context.rollback()
            return 0
        }

        GolfLiteStore.clearHistory()
        GolfLiteStore.clear()
        print("[ClipRoundImporter] \(imported) Runde(n) übernommen")
        return imported
    }

    // MARK: – Eine Runde

    private static func makeRound(from saved: SavedGolfLiteRound,
                                  complete: Bool,
                                  in context: ModelContext) -> Bool {
        // Ohne einen einzigen Schlag gibt es nichts zu übernehmen.
        guard saved.strokes.contains(where: { $0 > 0 }) else { return false }

        let round = Round(date: saved.savedAt ?? .now,
                          course: course(for: saved, in: context),
                          notes: "Im App Clip gezählt")
        round.isComplete = complete
        context.insert(round)

        for (index, strokes) in saved.strokes.enumerated() where strokes > 0 {
            let score = HoleScore(holeNumber: index + 1, strokes: strokes)
            score.round = round
            context.insert(score)
        }
        return true
    }

    // MARK: – Passenden Platz finden

    /// Erst unter den gespeicherten Plätzen suchen, dann im Katalog, sonst neu
    /// anlegen. Verglichen wird über den Namen – der Clip kennt die Kennung der
    /// Website, das `Course`-Modell der App hat keine.
    private static func course(for saved: SavedGolfLiteRound,
                               in context: ModelContext) -> Course {
        let wanted = saved.courseName.lowercased()

        if let existing = try? context.fetch(FetchDescriptor<Course>()),
           let match = existing.first(where: { $0.name.lowercased() == wanted }) {
            return match
        }

        // Im Katalog steht der Platz vollständig – mit HCP, Längen und
        // Koordinaten. Deutlich besser als das, was der Clip mitbringt.
        if let entry = CourseCatalogService.shared.allGolfCourses
            .first(where: { $0.name.lowercased() == wanted }) {
            let course = Course(
                name: entry.name,
                location: entry.location,
                numberOfHoles: entry.holes,
                parValues: entry.parValues.isEmpty ? nil : entry.parValues,
                courseRating: entry.courseRating,
                slopeRating: entry.slopeRating,
                hcpValues: entry.hcpValues,
                holeLengths: entry.holeLengths,
                facilityNotes: entry.facilityNotes,
                latitude: entry.lat,
                longitude: entry.lon,
                teeLatitudes: entry.teeLatitudes,
                teeLongitudes: entry.teeLongitudes,
                flagLatitudes: entry.flagLatitudes,
                flagLongitudes: entry.flagLongitudes
            )
            context.insert(course)
            return course
        }

        // Notnagel: nur das, was in der Runde selbst steckt. Kommt vor, wenn
        // der Platz zwischenzeitlich aus dem Verzeichnis verschwunden ist.
        let course = Course(
            name: saved.courseName,
            numberOfHoles: saved.strokes.count,
            parValues: saved.parValues.count == saved.strokes.count ? saved.parValues : nil
        )
        context.insert(course)
        return course
    }
}
