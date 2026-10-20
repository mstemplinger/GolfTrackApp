package app.golftrack.feature.records

import app.golftrack.data.Course
import app.golftrack.data.LatLon
import app.golftrack.data.Round
import app.golftrack.data.TrackPoint
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

/** Abgeleiteter Vorschlag für Abschlag- und Grünposition eines Lochs. */
internal data class HoleGeometrySuggestion(
    val holeNumber: Int,
    val tee: LatLon? = null,
    val green: LatLon? = null,
    /** 0…1 – wie belastbar der Vorschlag ist (Anzahl Quellen × Streuung × Plausibilität). */
    val teeConfidence: Double = 0.0,
    val greenConfidence: Double = 0.0,
    /** Streuung der Einzelschätzungen um den Mittelwert, in Metern. */
    val teeSpreadMeters: Double = 0.0,
    val greenSpreadMeters: Double = 0.0,
    /** Anzahl Runden, die zu diesem Loch etwas beigetragen haben. */
    val roundCount: Int = 0,
    /** Luftlinie Abschlag → Grün aus den abgeleiteten Positionen. */
    val measuredLengthMeters: Double? = null,
    /** Hinterlegte Lochlänge aus der Scorecard (falls vorhanden). */
    val expectedLengthMeters: Int? = null,
) {
    /** Relative Abweichung der gemessenen von der hinterlegten Länge (0,15 = 15 %). */
    val lengthDeviation: Double?
        get() {
            val m = measuredLengthMeters ?: return null
            val e = expectedLengthMeters?.takeIf { it > 0 } ?: return null
            return abs(m - e) / e
        }

    /** Falsch, wenn die abgeleitete Länge deutlich von der Scorecard abweicht. */
    val isPlausible: Boolean get() = lengthDeviation?.let { it <= CourseGeometryInference.MAX_LENGTH_DEVIATION } ?: true

    val hasUsableSuggestion: Boolean get() = tee != null || green != null

    enum class ConfidenceLevel { HIGH, MEDIUM, LOW }

    val confidenceLevel: ConfidenceLevel
        get() {
            val v = min(teeConfidence, greenConfidence)
            return when {
                v >= 0.7 -> ConfidenceLevel.HIGH
                v >= 0.4 -> ConfidenceLevel.MEDIUM
                else -> ConfidenceLevel.LOW
            }
        }
}

/**
 * Leitet aus aufgezeichneten Laufspuren und getrackten Schlägen die
 * Abschlag- und Grünpositionen der Löcher eines Platzes ab – wie
 * CourseGeometryInference.swift.
 *
 * Grundidee: Ein Spieler steht am Abschlag still (Warten, Abschlagen) und am
 * Grün ebenfalls (Putten). Zwischen beidem bewegt er sich. Also ist der
 * **erste** längere Stillstand eines Loch-Segments der Abschlag und der
 * **letzte** das Grün. Getrackte Schläge und manuell gesetzte Pins sind
 * stärkere Signale und werden höher gewichtet.
 */
internal object CourseGeometryInference {
    /** Ab dieser relativen Abweichung von der Scorecard-Länge gilt ein Vorschlag als unplausibel. */
    const val MAX_LENGTH_DEVIATION = 0.30

    /** Radius, innerhalb dessen Punkte als "am selben Ort" gelten. */
    private const val CLUSTER_RADIUS = 12.0
    /** So lange muss der Spieler stehen, damit es als Stillstand zählt (Sekunden). */
    private const val TEE_STAND = 30.0
    private const val GREEN_STAND = 25.0
    /** Einzelschätzungen, die weiter als das vom Median entfernt sind, fliegen raus. */
    private const val OUTLIER_DISTANCE = 60.0

    // Gewichte der Quellen
    private const val W_MANUAL_PIN = 3.0
    private const val W_SHOT = 2.0
    private const val W_STATIONARY = 1.0
    private const val W_SEGMENT_EDGE = 0.4

    private data class Candidate(val c: LatLon, val weight: Double)

    /** Runden eines Platzes (Ersatz für die SwiftData-Beziehung `course.rounds`). */
    fun roundsFor(course: Course, rounds: List<Round>): List<Round> = rounds.filter { it.courseId == course.id }

    /** Vorschläge für alle Löcher aus den Runden mit Laufspur oder Schlägen. */
    fun suggestions(course: Course, allRounds: List<Round>): List<HoleGeometrySuggestion> {
        val rounds = roundsFor(course, allRounds).filter { it.track != null || it.holeScores.any { h -> h.shots.isNotEmpty() } }
        if (rounds.isEmpty()) return emptyList()
        val prepared = rounds.map { PreparedRound(it) }
        return (1..max(1, course.numberOfHoles)).map { suggestion(it, prepared, course) }
    }

    /**
     * Schreibt alle Vorschläge mit ausreichender Konfidenz in den Platz.
     * Liefert den geänderten Platz und die Zahl aktualisierter Löcher.
     */
    fun apply(
        suggestions: List<HoleGeometrySuggestion>,
        course: Course,
        minConfidence: Double = 0.4,
        requirePlausible: Boolean = true,
    ): Pair<Course, Int> {
        var c = course
        var applied = 0
        for (s in suggestions) {
            if (requirePlausible && !s.isPlausible) continue
            var changed = false
            if (s.tee != null && s.teeConfidence >= minConfidence) { c = c.withTee(s.holeNumber, s.tee); changed = true }
            if (s.green != null && s.greenConfidence >= minConfidence) { c = c.withFlag(s.holeNumber, s.green); changed = true }
            if (changed) applied++
        }
        return c to applied
    }

    private fun suggestion(hole: Int, rounds: List<PreparedRound>, course: Course): HoleGeometrySuggestion {
        val expected = course.holeLengths.getOrNull(hole - 1)?.takeIf { it > 0 }
        val teeCandidates = mutableListOf<Candidate>()
        val greenCandidates = mutableListOf<Candidate>()
        var contributing = 0

        for (p in rounds) {
            var contributed = false
            val hs = p.round.holeScores.firstOrNull { it.holeNumber == hole }

            // 1) Manuell gesetzter Pin – stärkstes Signal für das Grün. Automatisch
            //    vorbefüllte Pins werden ignoriert, sonst würde die Ableitung ihr
            //    eigenes Ergebnis als Beweis verwenden.
            if (hs != null && !hs.pinIsAutomatic) {
                val lat = hs.pinLatitude
                val lon = hs.pinLongitude
                if (lat != null && lon != null) valid(lat, lon)?.let {
                    greenCandidates += Candidate(it, W_MANUAL_PIN); contributed = true
                }
            }

            // 2) Getrackte Schläge.
            val shots = hs?.sortedShots ?: emptyList()
            if (shots.isNotEmpty()) {
                valid(shots[0].fromLatitude, shots[0].fromLongitude)?.let { teeCandidates += Candidate(it, W_SHOT); contributed = true }
                val last = shots.last()
                valid(last.toLatitude, last.toLongitude)?.let { greenCandidates += Candidate(it, W_SHOT); contributed = true }
            }

            // 3) Laufspur.
            val segment = p.points(hole).filter { it.isValid }
            if (segment.size >= 2) {
                contributed = true
                val tee = firstStationaryCluster(segment, TEE_STAND)
                teeCandidates += if (tee != null) Candidate(tee, W_STATIONARY) else Candidate(segment.first().coordinate, W_SEGMENT_EDGE)
                val green = lastStationaryCluster(segment, GREEN_STAND)
                greenCandidates += if (green != null) Candidate(green, W_STATIONARY) else Candidate(segment.last().coordinate, W_SEGMENT_EDGE)
            }

            if (contributed) contributing++
        }

        var result = HoleGeometrySuggestion(holeNumber = hole, expectedLengthMeters = expected, roundCount = contributing)
        combine(teeCandidates)?.let { (c, w, s) ->
            result = result.copy(tee = c, teeSpreadMeters = s, teeConfidence = confidence(w, s))
        }
        combine(greenCandidates)?.let { (c, w, s) ->
            result = result.copy(green = c, greenSpreadMeters = s, greenConfidence = confidence(w, s))
        }
        if (result.tee != null && result.green != null) {
            result = result.copy(measuredLengthMeters = result.tee!!.distanceTo(result.green!!))
        }
        // Unplausible Längen halbieren die Konfidenz – der Vorschlag bleibt
        // sichtbar, wird aber nicht automatisch übernommen.
        if (!result.isPlausible) {
            result = result.copy(teeConfidence = result.teeConfidence * 0.5, greenConfidence = result.greenConfidence * 0.5)
        }
        return result
    }

    private fun combine(candidates: List<Candidate>): Triple<LatLon, Double, Double>? {
        if (candidates.isEmpty()) return null
        // Ausreißer gegen den Median verwerfen (ein verirrter GPS-Fix im Wald
        // darf den Mittelwert nicht verschieben).
        val median = LatLon(median(candidates.map { it.c.lat }), median(candidates.map { it.c.lon }))
        val kept = candidates.filter { it.c.distanceTo(median) <= OUTLIER_DISTANCE }
        val usable = kept.ifEmpty { candidates }
        val total = usable.sumOf { it.weight }
        if (total <= 0) return null
        val center = LatLon(usable.sumOf { it.c.lat * it.weight } / total, usable.sumOf { it.c.lon * it.weight } / total)
        val spread = if (usable.size > 1) usable.sumOf { it.c.distanceTo(center) } / usable.size else 0.0
        return Triple(center, total, spread)
    }

    /**
     * Konfidenz aus Quellengewicht und Streuung. Volle Punktzahl braucht
     * Gewicht ≥ 3 (z. B. drei Laufspuren oder Schlag + Spur) und eine Streuung unter ~5 m.
     */
    private fun confidence(weight: Double, spread: Double): Double =
        min(1.0, min(1.0, weight / 3) * max(0.0, 1 - spread / 40))

    /** Erster Abschnitt, in dem der Spieler `minDuration` lang im Radius geblieben ist. */
    private fun firstStationaryCluster(points: List<TrackPoint>, minDuration: Double): LatLon? {
        if (points.size < 2) return null
        for (start in points.indices) {
            val anchor = points[start].coordinate
            var end = start
            while (end + 1 < points.size && points[end + 1].coordinate.distanceTo(anchor) <= CLUSTER_RADIUS) end++
            if (points[end].timeOffset - points[start].timeOffset >= minDuration) return centroid(points.subList(start, end + 1))
        }
        return null
    }

    /** Analog vom Ende her – der letzte längere Stillstand (Putten am Grün). */
    private fun lastStationaryCluster(points: List<TrackPoint>, minDuration: Double): LatLon? {
        if (points.size < 2) return null
        for (end in points.indices.reversed()) {
            val anchor = points[end].coordinate
            var start = end
            while (start - 1 >= 0 && points[start - 1].coordinate.distanceTo(anchor) <= CLUSTER_RADIUS) start--
            if (points[end].timeOffset - points[start].timeOffset >= minDuration) return centroid(points.subList(start, end + 1))
        }
        return null
    }

    private fun centroid(points: List<TrackPoint>): LatLon? {
        if (points.isEmpty()) return null
        return LatLon(points.sumOf { it.latitude } / points.size, points.sumOf { it.longitude } / points.size)
    }

    private fun median(values: List<Double>): Double {
        if (values.isEmpty()) return 0.0
        val s = values.sorted()
        val mid = s.size / 2
        return if (s.size % 2 == 0) (s[mid - 1] + s[mid]) / 2 else s[mid]
    }

    private fun valid(lat: Double, lon: Double): LatLon? = LatLon(lat, lon).takeIf { it.isValid }
}
