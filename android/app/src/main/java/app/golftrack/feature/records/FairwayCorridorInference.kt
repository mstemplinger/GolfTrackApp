package app.golftrack.feature.records

import app.golftrack.data.Course
import app.golftrack.data.LatLon
import app.golftrack.data.Round
import kotlinx.serialization.Serializable
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToLong
import kotlin.math.sqrt

/**
 * Ein Abschnitt entlang der Achse Abschlag→Grün mit den dort gemessenen
 * Querabweichungen. Enthält bewusst keine Zeit, keine Kennung und keine
 * Einzelpunkte – nur Kennzahlen über mehrere Quellen.
 */
@Serializable
internal data class FairwayBin(
    /** Abschnitt entlang der Achse, 0 = am Abschlag. */
    val index: Int,
    /** Median der Querabweichung in Metern (+ = rechts der Achse). */
    val centerOffset: Double,
    /** 10. Perzentil – linker Korridorrand. */
    val leftOffset: Double,
    /** 90. Perzentil – rechter Korridorrand. */
    val rightOffset: Double,
    val sampleCount: Int,
) {
    val widthMeters: Double get() = rightOffset - leftOffset
}

/** Der abgeleitete Fairway-Verlauf eines Lochs. */
@Serializable
internal data class HoleCorridor(
    val holeNumber: Int,
    val teeLatitude: Double,
    val teeLongitude: Double,
    val greenLatitude: Double,
    val greenLongitude: Double,
    val binLengthMeters: Double,
    val axisLengthMeters: Double,
    val bins: List<FairwayBin>,
    /** Anzahl Runden, aus denen der Verlauf gerechnet wurde. */
    val roundCount: Int,
) {
    val tee: LatLon get() = LatLon(teeLatitude, teeLongitude)
    val green: LatLon get() = LatLon(greenLatitude, greenLongitude)

    private fun axialCenter(bin: FairwayBin) = (bin.index + 0.5) * binLengthMeters

    /** Mittellinie des Fairways als Koordinatenkette. */
    val centerline: List<LatLon>
        get() {
            val f = AxisFrame(tee, green)
            return bins.map { f.coordinate(axialCenter(it), it.centerOffset) }
        }

    /** Korridor als geschlossenes Polygon (linke Kante hin, rechte Kante zurück). */
    val corridorPolygon: List<LatLon>
        get() {
            if (bins.size < 2) return emptyList()
            val f = AxisFrame(tee, green)
            return bins.map { f.coordinate(axialCenter(it), it.leftOffset) } +
                bins.reversed().map { f.coordinate(axialCenter(it), it.rightOffset) }
        }

    val averageWidthMeters: Double get() = if (bins.isEmpty()) 0.0 else bins.sumOf { it.widthMeters } / bins.size

    /** Anteil der Achse, für den überhaupt Messwerte vorliegen. */
    val coverage: Double
        get() {
            if (axisLengthMeters <= 0 || binLengthMeters <= 0) return 0.0
            val possible = max(1.0, ceil(axisLengthMeters / binLengthMeters))
            return min(1.0, bins.size / possible)
        }

    enum class Reliability { GOOD, THIN, VERY_THIN }

    /** Eine einzelne Runde ist immer „sehr dünn" – eine Gehspur ist nicht das Fairway. */
    val reliability: Reliability
        get() = when {
            roundCount >= 5 && coverage >= 0.6 -> Reliability.GOOD
            roundCount >= 3 && coverage >= 0.4 -> Reliability.THIN
            else -> Reliability.VERY_THIN
        }
}

/** Rechtwinkliges Hilfssystem entlang der Achse Abschlag→Grün (axial = Richtung Grün, lateral = rechts). */
internal class AxisFrame(tee: LatLon, green: LatLon) {
    private val originLat = tee.lat
    private val originLon = tee.lon
    private val mLat = 111_320.0
    private val mLon = 111_320.0 * cos(Math.toRadians(tee.lat))
    private val ax: Double
    private val ay: Double
    val length: Double

    init {
        val dx = (green.lon - tee.lon) * mLon
        val dy = (green.lat - tee.lat) * mLat
        val len = sqrt(dx * dx + dy * dy)
        length = len
        if (len > 0) { ax = dx / len; ay = dy / len } else { ax = 0.0; ay = 1.0 }
    }

    fun project(c: LatLon): Pair<Double, Double> {
        val dx = (c.lon - originLon) * mLon
        val dy = (c.lat - originLat) * mLat
        // Kreuzprodukt in 2D: positiv = rechts der Achse (in Blickrichtung Grün)
        return (dx * ax + dy * ay) to (dx * ay - dy * ax)
    }

    fun coordinate(axial: Double, lateral: Double): LatLon {
        val dx = ax * axial + ay * lateral
        val dy = ay * axial - ax * lateral
        return LatLon(originLat + dy / mLat, originLon + dx / mLon)
    }
}

/**
 * Leitet aus Laufspuren und getrackten Schlägen den ungefähren Fairway-Verlauf
 * eines Lochs ab (wie FairwayCorridorInference.swift): alle Messpunkte auf die
 * Achse projizieren, in Abschnitte einteilen, pro Abschnitt Median und
 * 10./90. Perzentil der Querabweichung. Ballpositionen zählen dreifach.
 */
internal object FairwayCorridorInference {
    const val BIN_LENGTH = 10.0
    const val MIN_SAMPLES_PER_BIN = 2
    const val MIN_BINS = 3
    const val MAX_LATERAL = 60.0
    const val MAX_ACCURACY = 15.0
    private const val W_BALL = 3.0
    private const val W_WALK = 1.0

    /** Verläufe aller Löcher mit bekannter Abschlag-/Grünposition (Par 3 übersprungen). */
    fun corridors(course: Course, allRounds: List<Round>): List<HoleCorridor> {
        val prepared = allRounds.filter { it.courseId == course.id }.map { PreparedRound(it) }
        return (1..max(1, course.numberOfHoles)).mapNotNull { corridor(it, course, prepared) }
    }

    fun isFairwayHole(hole: Int, course: Course): Boolean = (course.parValues.getOrNull(hole - 1) ?: 0) > 3

    private fun corridor(hole: Int, course: Course, rounds: List<PreparedRound>): HoleCorridor? {
        if (!isFairwayHole(hole, course)) return null
        val tee = course.teeCoordinate(hole) ?: return null
        val green = course.flagCoordinate(hole) ?: return null
        val frame = AxisFrame(tee, green)
        if (frame.length < 40) return null

        val buckets = mutableMapOf<Int, MutableList<Pair<Double, Double>>>()
        var contributing = 0

        fun add(c: LatLon, w: Double): Boolean {
            if (!c.isValid) return false
            val (axial, lateral) = frame.project(c)
            if (axial < 0 || axial > frame.length || abs(lateral) > MAX_LATERAL) return false
            buckets.getOrPut((axial / BIN_LENGTH).toInt()) { mutableListOf() }.add(lateral to w)
            return true
        }

        for (p in rounds) {
            var contributed = false
            // 1) Getrackte Ballpositionen – Abschlag- und Auftreffpunkt jedes Schlags.
            for (hs in p.round.holeScores) {
                if (hs.holeNumber != hole) continue
                for (shot in hs.sortedShots) {
                    if (add(shot.from, W_BALL)) contributed = true
                    if (add(shot.to, W_BALL)) contributed = true
                }
            }
            // 2) Laufspur.
            for (pt in p.points(hole)) {
                if (pt.isValid && pt.accuracy <= MAX_ACCURACY && add(pt.coordinate, W_WALK)) contributed = true
            }
            if (contributed) contributing++
        }

        var bins = buckets.filter { it.value.size >= MIN_SAMPLES_PER_BIN }.map { (i, s) ->
            FairwayBin(i, weightedPercentile(s, 0.5), weightedPercentile(s, 0.10), weightedPercentile(s, 0.90), s.size)
        }.sortedBy { it.index }
        if (bins.size < MIN_BINS) return null
        bins = quantized(smoothed(bins))

        return HoleCorridor(
            holeNumber = hole,
            teeLatitude = tee.lat, teeLongitude = tee.lon,
            greenLatitude = green.lat, greenLongitude = green.lon,
            binLengthMeters = BIN_LENGTH,
            axisLengthMeters = (frame.length * 10).roundToLong() / 10.0,
            bins = bins,
            roundCount = contributing,
        )
    }

    /** Gewichtetes Perzentil (0…1). */
    fun weightedPercentile(samples: List<Pair<Double, Double>>, p: Double): Double {
        if (samples.isEmpty()) return 0.0
        val sorted = samples.sortedBy { it.first }
        val total = sorted.sumOf { it.second }
        if (total <= 0) return sorted[sorted.size / 2].first
        val target = p * total
        var cum = 0.0
        for (s in sorted) {
            cum += s.second
            if (cum >= target) return s.first
        }
        return sorted.last().first
    }

    /** Gleitender Mittelwert über drei benachbarte Abschnitte – Lücken unterbrechen die Glättung. */
    private fun smoothed(bins: List<FairwayBin>): List<FairwayBin> {
        if (bins.size < 3) return bins
        return bins.mapIndexed { pos, bin ->
            val n = mutableListOf(bin)
            if (pos > 0 && bins[pos - 1].index == bin.index - 1) n += bins[pos - 1]
            if (pos < bins.size - 1 && bins[pos + 1].index == bin.index + 1) n += bins[pos + 1]
            bin.copy(
                centerOffset = n.sumOf { it.centerOffset } / n.size,
                leftOffset = n.sumOf { it.leftOffset } / n.size,
                rightOffset = n.sumOf { it.rightOffset } / n.size,
            )
        }
    }

    /** Auf Dezimeter runden – feiner wäre bei GPS-Genauigkeit Scheingenauigkeit. */
    private fun quantized(bins: List<FairwayBin>): List<FairwayBin> = bins.map {
        it.copy(
            centerOffset = (it.centerOffset * 10).roundToLong() / 10.0,
            leftOffset = (it.leftOffset * 10).roundToLong() / 10.0,
            rightOffset = (it.rightOffset * 10).roundToLong() / 10.0,
        )
    }
}
