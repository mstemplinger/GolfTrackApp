package app.golftrack.feature.golf

import app.golftrack.data.Course
import app.golftrack.data.LatLon
import app.golftrack.data.Round
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.roundToLong
import kotlin.math.sqrt

/*
 * Fairway-Verlauf aus Laufspuren und getrackten Schlägen – wie
 * FairwayCorridorInference.swift. Gespeichert wird nichts; die Ansichten
 * rechnen beim Öffnen frisch.
 */

data class FairwayBin(val index: Int, val centerOffset: Double, val leftOffset: Double, val rightOffset: Double, val sampleCount: Int) {
    val widthMeters: Double get() = rightOffset - leftOffset
}

enum class Reliability { GOOD, THIN, VERY_THIN }

data class HoleCorridor(
    val holeNumber: Int,
    val tee: LatLon,
    val green: LatLon,
    val binLengthMeters: Double,
    val axisLengthMeters: Double,
    val bins: List<FairwayBin>,
    val roundCount: Int,
) {
    private fun axialCenter(b: FairwayBin) = (b.index + 0.5) * binLengthMeters

    val centerline: List<LatLon>
        get() {
            val f = AxisFrame(tee, green)
            return bins.map { f.coordinate(axialCenter(it), it.centerOffset) }
        }

    val corridorPolygon: List<LatLon>
        get() {
            if (bins.size < 2) return emptyList()
            val f = AxisFrame(tee, green)
            return bins.map { f.coordinate(axialCenter(it), it.leftOffset) } +
                bins.reversed().map { f.coordinate(axialCenter(it), it.rightOffset) }
        }

    val averageWidthMeters: Double get() = if (bins.isEmpty()) 0.0 else bins.sumOf { it.widthMeters } / bins.size

    val coverage: Double
        get() {
            if (axisLengthMeters <= 0 || binLengthMeters <= 0) return 0.0
            val possible = maxOf(1.0, ceil(axisLengthMeters / binLengthMeters))
            return minOf(1.0, bins.size / possible)
        }

    /** Eine einzelne Runde ist immer „sehr dünn" – eine Gehspur ist nicht das Fairway. */
    val reliability: Reliability
        get() = when {
            roundCount >= 5 && coverage >= 0.6 -> Reliability.GOOD
            roundCount >= 3 && coverage >= 0.4 -> Reliability.THIN
            else -> Reliability.VERY_THIN
        }
}

/** Rechtwinkliges Hilfssystem entlang Abschlag→Grün (axial, lateral in Metern). */
class AxisFrame(tee: LatLon, green: LatLon) {
    private val originLat = tee.lat
    private val originLon = tee.lon
    private val mPerLat = 111_320.0
    private val mPerLon = 111_320.0 * cos(Math.toRadians(tee.lat))
    private val ax: Double
    private val ay: Double
    val length: Double

    init {
        val dx = (green.lon - tee.lon) * mPerLon
        val dy = (green.lat - tee.lat) * mPerLat
        val len = sqrt(dx * dx + dy * dy)
        length = len
        if (len > 0) { ax = dx / len; ay = dy / len } else { ax = 0.0; ay = 1.0 }
    }

    fun project(c: LatLon): Pair<Double, Double> {
        val dx = (c.lon - originLon) * mPerLon
        val dy = (c.lat - originLat) * mPerLat
        return (dx * ax + dy * ay) to (dx * ay - dy * ax)
    }

    fun coordinate(axial: Double, lateral: Double): LatLon {
        val dx = ax * axial + ay * lateral
        val dy = ay * axial - ax * lateral
        return LatLon(originLat + dy / mPerLat, originLon + dx / mPerLon)
    }
}

object FairwayCorridorInference {
    private const val BIN_LENGTH = 10.0
    private const val MIN_SAMPLES_PER_BIN = 2
    private const val MIN_BINS = 3
    private const val MAX_LATERAL = 60.0
    private const val MAX_ACCURACY = 15.0
    private const val W_BALL = 3.0
    private const val W_WALK = 1.0

    /** Alle Löcher mit bekanntem Abschlag und Grün; Par 3 wird übersprungen. */
    fun corridors(course: Course, rounds: List<Round>): List<HoleCorridor> {
        val own = rounds.filter { it.courseId == course.id }
        return (1..maxOf(1, course.numberOfHoles)).mapNotNull { corridor(it, course, own) }
    }

    fun corridor(hole: Int, course: Course, rounds: List<Round>): HoleCorridor? {
        if ((course.parValues.getOrNull(hole - 1) ?: 0) <= 3) return null
        val tee = course.teeCoordinate(hole) ?: return null
        val green = course.flagCoordinate(hole) ?: return null
        val frame = AxisFrame(tee, green)
        if (frame.length < 40) return null

        val buckets = HashMap<Int, MutableList<Pair<Double, Double>>>()
        var contributing = 0

        fun add(c: LatLon, weight: Double): Boolean {
            if (!c.isValid) return false
            val (axial, lateral) = frame.project(c)
            if (axial < 0 || axial > frame.length || abs(lateral) > MAX_LATERAL) return false
            buckets.getOrPut((axial / BIN_LENGTH).toInt()) { mutableListOf() } += lateral to weight
            return true
        }

        for (r in rounds) {
            var contributed = false
            r.score(hole)?.sortedShots?.forEach { s ->
                if (add(s.from, W_BALL)) contributed = true
                if (add(s.to, W_BALL)) contributed = true
            }
            r.track?.points(hole)?.sortedBy { it.timeOffset }?.forEach { p ->
                if (p.isValid && p.accuracy <= MAX_ACCURACY && add(p.coordinate, W_WALK)) contributed = true
            }
            if (contributed) contributing++
        }

        var bins = buckets.filter { it.value.size >= MIN_SAMPLES_PER_BIN }.map { (i, s) ->
            FairwayBin(i, percentile(s, 0.5), percentile(s, 0.10), percentile(s, 0.90), s.size)
        }.sortedBy { it.index }
        if (bins.size < MIN_BINS) return null
        bins = smoothed(bins).map {
            it.copy(centerOffset = q(it.centerOffset), leftOffset = q(it.leftOffset), rightOffset = q(it.rightOffset))
        }
        return HoleCorridor(hole, tee, green, BIN_LENGTH, (frame.length * 10).roundToLong() / 10.0, bins, contributing)
    }

    private fun q(v: Double) = (v * 10).roundToLong() / 10.0

    private fun percentile(samples: List<Pair<Double, Double>>, p: Double): Double {
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

    private fun smoothed(bins: List<FairwayBin>): List<FairwayBin> {
        if (bins.size < 3) return bins
        return bins.mapIndexed { pos, b ->
            val n = mutableListOf(b)
            if (pos > 0 && bins[pos - 1].index == b.index - 1) n += bins[pos - 1]
            if (pos < bins.size - 1 && bins[pos + 1].index == b.index + 1) n += bins[pos + 1]
            b.copy(
                centerOffset = n.sumOf { it.centerOffset } / n.size,
                leftOffset = n.sumOf { it.leftOffset } / n.size,
                rightOffset = n.sumOf { it.rightOffset } / n.size,
            )
        }
    }
}
