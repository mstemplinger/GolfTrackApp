package app.golftrack.feature.guide

import androidx.compose.ui.graphics.Color
import app.golftrack.data.Course
import app.golftrack.data.Round
import app.golftrack.ui.theme.AppTheme
import java.util.Calendar
import java.util.Locale
import kotlin.math.roundToInt

// Entspricht GolfTrackApp/Views/Tips/TrainingRecommendation.swift. Die Lektionen selbst
// (Audiobooks) kommen erst später auf Android – Empfehlungen verweisen auf „Später“.

/** Kategorie einer Trainingslektion (TrainingCategory auf iOS). */
enum class TrainingCategory(val rawValue: String, val icon: String, val color: Color) {
    GRUNDLAGEN("Grundlagen", "star.fill", rgb(0.3f, 0.85f, 0.5f)),
    DRIVE("Drive", "figure.golf", AppTheme.gold),
    TECHNIK("Technik", "gearshape.fill", rgb(0.4f, 0.7f, 1.0f)),
    ANSPIEL("Anspiel", "target", rgb(1.0f, 0.6f, 0.3f)),
    KURZSPIEL("Kurzspiel", "figure.golf.circle.fill", rgb(1.0f, 0.5f, 0.3f)),
    PUTTEN("Putten", "circle.fill", rgb(0.6f, 0.5f, 1.0f)),
    MENTAL("Mental", "brain.head.profile", rgb(0.9f, 0.4f, 0.7f)),
    STRATEGIE("Strategie", "map.fill", rgb(0.4f, 0.8f, 0.6f)),
}

/** Nur die Metadaten der Lektionen, auf die Empfehlungen verweisen können. */
data class TrainingLesson(val id: String, val title: String, val subtitle: String, val category: TrainingCategory)

val allTrainingLessons = listOf(
    TrainingLesson("01", "Der richtige Griff", "Fundament jedes Schlags", TrainingCategory.GRUNDLAGEN),
    TrainingLesson("02", "Stand und Balance", "Stabilität für mehr Konsistenz", TrainingCategory.GRUNDLAGEN),
    TrainingLesson("03", "Driver-Strategie", "Warum fast immer der Driver besser ist", TrainingCategory.DRIVE),
    TrainingLesson("04", "Gewichtsverlagerung", "Hüftrotation und Schwungkraft", TrainingCategory.TECHNIK),
    TrainingLesson("05", "Weniger Lob-Wedge", "Die häufigste Kurzspiel-Falle", TrainingCategory.KURZSPIEL),
    TrainingLesson("06", "Drei-Putts vermeiden", "Distanzkontrolle auf dem Grün", TrainingCategory.PUTTEN),
    TrainingLesson("07", "Pre-Shot Routine", "Dein Anker auf dem Platz", TrainingCategory.MENTAL),
    TrainingLesson("08", "Fehler loslassen", "Ein Schlag nach dem anderen", TrainingCategory.MENTAL),
    TrainingLesson("09", "Course Management", "Smarter spielen, weniger Fehler", TrainingCategory.STRATEGIE),
    TrainingLesson("10", "Schlägerwahl beim Anspiel", "Immer einen Schläger mehr nehmen", TrainingCategory.ANSPIEL),
    TrainingLesson("11", "Bunker-Spiel", "Raus, und zwar sicher", TrainingCategory.KURZSPIEL),
    TrainingLesson("12", "Den Ball sauber treffen", "Trefferfläche und Sweet Spot", TrainingCategory.TECHNIK),
    TrainingLesson("13", "Fade und Draw spielen", "Schlagformen gezielt einsetzen", TrainingCategory.TECHNIK),
    TrainingLesson("14", "Spiel aus dem Rough", "Wenn der Plan nicht aufgeht", TrainingCategory.STRATEGIE),
    TrainingLesson("15", "Aufwärm-Routine", "Die ersten 10 Minuten entscheiden", TrainingCategory.GRUNDLAGEN),
    TrainingLesson("16", "Tempo und Rhythmus", "Der unsichtbare Schlüssel zum Swing", TrainingCategory.TECHNIK),
    TrainingLesson("17", "Das Grün lesen", "Gefälle und Grain richtig einschätzen", TrainingCategory.PUTTEN),
)

data class TrainingRecommendation(
    val lesson: TrainingLesson,
    /** Kurzer, statistikbasierter Grund für die Empfehlung */
    val reason: String,
    /** Knappe Kennzahl, z. B. "Ø 2,1 Putts/Loch" – null, wenn es keine auffällige Zahl gibt */
    val statLabel: String?,
    /** Höher = dringlicher; steuert die Reihenfolge */
    val severity: Double,
) {
    val id: String get() = lesson.id
}

object TrainingRecommender {

    /**
     * Leitet aus den letzten abgeschlossenen Runden passende Audio-Lektionen ab.
     * Gibt eine leere Liste zurück, wenn noch zu wenige Daten vorliegen.
     */
    fun recommendations(rounds: List<Round>, courseOf: (Round) -> Course?, limit: Int = 3): List<TrainingRecommendation> {
        val recent = rounds.filter { it.isComplete }.sortedByDescending { it.date }.take(8)
        val m = metrics(recent, courseOf)
        if (m.playedHoles < 5) return emptyList()
        return rules(m).sortedByDescending { it.severity }.take(limit)
    }

    /**
     * Empfehlungen aus genau einer – typischerweise gerade beendeten – Runde. Findet sich
     * keine Schwäche, kommt eine Lektion zum Dranbleiben zurück.
     */
    fun recommendations(round: Round, course: Course?, limit: Int = 2): List<TrainingRecommendation> {
        val m = metrics(listOf(round)) { course }
        if (m.playedHoles < 5) return emptyList()
        val matches = rules(m).sortedByDescending { it.severity }
        if (matches.isNotEmpty()) return matches.take(limit)
        return encouragement(round, limit)
    }

    // MARK: Kennzahlen

    private class Metrics {
        var playedHoles = 0
        var puttSum = 0
        var fairwayHit = 0
        var fairwayOpp = 0
        var girHit = 0
        var girOpp = 0
        var blowUps = 0
        var scoredHoles = 0
    }

    private fun metrics(rounds: List<Round>, courseOf: (Round) -> Course?): Metrics {
        val m = Metrics()
        for (round in rounds) {
            val course = courseOf(round)
            m.playedHoles += round.playedScores.size
            m.puttSum += round.totalPutts
            m.fairwayHit += round.fairwaysHit
            m.fairwayOpp += round.fairwayOpportunities(course)
            m.girHit += round.greensInRegulation
            m.girOpp += round.girOpportunities
            if (course != null) {
                val pars = course.parValues
                for (s in round.playedScores) {
                    if (s.strokes <= 0) continue
                    m.scoredHoles += 1
                    val par = pars.getOrNull(s.holeNumber - 1) ?: continue
                    if (s.strokes >= par + 3) m.blowUps += 1
                }
            }
        }
        return m
    }

    // MARK: Regeln

    private fun rules(m: Metrics): List<TrainingRecommendation> {
        val recs = mutableListOf<TrainingRecommendation>()

        // Putten
        val avgPutts = m.puttSum.toDouble() / m.playedHoles
        if (avgPutts >= 1.9) lesson("06")?.let {
            recs += TrainingRecommendation(
                it, "Du brauchst noch viele Putts. Diese Lektion trainiert deine Distanzkontrolle auf dem Grün.",
                puttsLabel(avgPutts), (avgPutts - 1.9) + 0.30,
            )
        }

        // Fairways / Abschlag
        if (m.fairwayOpp >= 5) {
            val pct = m.fairwayHit.toDouble() / m.fairwayOpp
            if (pct < 0.45) lesson("02")?.let {
                recs += TrainingRecommendation(
                    it, "Wenige Fairways getroffen. Mehr Stabilität im Stand sorgt für geradere Abschläge.",
                    fairwayLabel(pct), (0.45 - pct) + 0.30,
                )
            }
        }

        // Grüns in Regulation / Anspiel
        if (m.girOpp >= 5) {
            val pct = m.girHit.toDouble() / m.girOpp
            if (pct < 0.30) lesson("10")?.let {
                recs += TrainingRecommendation(
                    it, "Selten das Grün in Regulation getroffen. Die richtige Schlägerwahl beim Anspiel hilft.",
                    girLabel(pct), (0.30 - pct) + 0.20,
                )
            }
        }

        // Hohe Löcher / Course Management
        if (m.scoredHoles >= 9) {
            val rate = m.blowUps.toDouble() / m.scoredHoles
            if (rate >= 0.15) lesson("09")?.let {
                recs += TrainingRecommendation(
                    it, "Immer wieder hohe Löcher (3+ über Par). Cleveres Course Management senkt deinen Score.",
                    blowUpLabel(rate), rate + 0.10,
                )
            }
        }

        // Grünlesen (17) – wenn Putts leicht erhöht (unterhalb des Lesson-06-Schwellwerts)
        if (avgPutts >= 1.75 && avgPutts < 1.9) lesson("17")?.let {
            recs += TrainingRecommendation(
                it, "Etwas zu viele Putts. Besseres Grünlesen kann direkt Schläge sparen.",
                puttsLabel(avgPutts), (avgPutts - 1.75) * 0.8,
            )
        }

        // Rough-Spiel (14) – wenn wenig Fairways getroffen
        if (m.fairwayOpp >= 5) {
            val pct = m.fairwayHit.toDouble() / m.fairwayOpp
            if (pct < 0.40) lesson("14")?.let {
                recs += TrainingRecommendation(
                    it, "Du landest oft im Rough. Diese Lektion zeigt, wie du trotzdem gute Schläge spielst.",
                    fairwayLabel(pct), (0.40 - pct) * 0.6,
                )
            }
        }

        // Fade & Draw (13) – wenn GIR im mittleren Bereich
        if (m.girOpp >= 5) {
            val pct = m.girHit.toDouble() / m.girOpp
            if (pct >= 0.15 && pct < 0.45) lesson("13")?.let {
                recs += TrainingRecommendation(
                    it, "Dein Anspiel hat Potenzial. Gezielte Schlagformen bringen dich näher an die Fahne.",
                    girLabel(pct), 0.12,
                )
            }
        }

        // Tempo & Rhythmus (16) – bei mittlerer Blow-up-Rate
        if (m.scoredHoles >= 9) {
            val rate = m.blowUps.toDouble() / m.scoredHoles
            if (rate >= 0.10 && rate < 0.15) lesson("16")?.let {
                recs += TrainingRecommendation(
                    it, "Einzelne Löcher kosten dir zu viele Schläge. Gleichmäßiges Tempo hilft bei Drucksituationen.",
                    blowUpLabel(rate), rate * 0.5,
                )
            }
        }

        return recs
    }

    // MARK: Ohne Schwäche

    private val encouragementLessonIDs = listOf("07", "15", "16", "09")

    private fun encouragement(round: Round, limit: Int): List<TrainingRecommendation> {
        val pool = encouragementLessonIDs.mapNotNull { lesson(it) }
        if (pool.isEmpty()) return emptyList()
        val day = Calendar.getInstance().apply { timeInMillis = round.date }.get(Calendar.DAY_OF_YEAR)
        val start = (day - 1) % pool.size
        val rotated = pool.indices.map { pool[(start + it) % pool.size] }
        return rotated.take(limit).mapIndexed { offset, lesson ->
            TrainingRecommendation(
                lesson, "Runde ohne auffällige Schwäche. Diese Lektion hilft dir, das Niveau zu halten.",
                null, 0.01 - offset * 0.001,
            )
        }
    }

    // MARK: Kennzahl-Labels

    private fun puttsLabel(avgPutts: Double) = "Ø ${String.format(Locale.GERMAN, "%.1f", avgPutts)} Putts/Loch"
    private fun fairwayLabel(pct: Double) = "${percent(pct)} Fairways"
    private fun girLabel(pct: Double) = "${percent(pct)} GIR"
    private fun blowUpLabel(rate: Double) = "${percent(rate)} Löcher 3+ über Par"
    private fun percent(value: Double) = "${(value * 100).roundToInt()} %"

    private fun lesson(id: String): TrainingLesson? = allTrainingLessons.firstOrNull { it.id == id }
}
