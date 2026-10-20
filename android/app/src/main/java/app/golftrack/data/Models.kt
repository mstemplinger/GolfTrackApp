package app.golftrack.data

import kotlinx.serialization.Serializable
import java.util.UUID
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/*
 * Datenmodell der Android-App. Entspricht den SwiftData-Modellen in
 * GolfTrackApp/Models/. Statt Beziehungen hängen Lochergebnisse, Schläge,
 * Mitspieler-Scores und die Laufspur direkt an der Runde; Platz und Bag werden
 * über ihre ID referenziert. Alles ist unveränderlich – geändert wird über
 * `copy` und `GolfStore.update…`.
 */

fun newId(): String = UUID.randomUUID().toString()

@Serializable
data class LatLon(val lat: Double, val lon: Double) {
    val isValid: Boolean
        get() = lat.isFinite() && lon.isFinite() && !(lat == 0.0 && lon == 0.0) &&
            lat in -90.0..90.0 && lon in -180.0..180.0

    /** Entfernung in Metern (Haversine), wie `CLLocation.distance(from:)`. */
    fun distanceTo(other: LatLon): Double {
        val r = 6_371_000.0
        val dLat = Math.toRadians(other.lat - lat)
        val dLon = Math.toRadians(other.lon - lon)
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(Math.toRadians(lat)) * cos(Math.toRadians(other.lat)) * sin(dLon / 2) * sin(dLon / 2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

@Serializable
data class Course(
    val id: String = newId(),
    val name: String,
    val location: String = "",
    val numberOfHoles: Int = 18,
    val parValues: List<Int> = defaultPars(numberOfHoles),
    val courseRating: Double = 72.0,
    val slopeRating: Int = 113,
    val hcpValues: List<Int> = emptyList(),
    val holeLengths: List<Int> = emptyList(),
    val facilityNotes: String = "",
    val latitude: Double? = null,
    val longitude: Double? = null,
    val teeLatitudes: List<Double> = emptyList(),
    val teeLongitudes: List<Double> = emptyList(),
    val flagLatitudes: List<Double> = emptyList(),
    val flagLongitudes: List<Double> = emptyList(),
    /** Kennung aus dem Platzverzeichnis (QR-Code), leer bei eigenen Plätzen. */
    val slug: String = "",
) {
    val totalPar: Int get() = parValues.sum()

    fun par(hole: Int): Int = parValues.getOrNull(hole - 1) ?: 4

    fun teeCoordinate(hole: Int): LatLon? = coord(teeLatitudes, teeLongitudes, hole)
    fun flagCoordinate(hole: Int): LatLon? = coord(flagLatitudes, flagLongitudes, hole)

    val holePositionCount: Int
        get() = (1..maxOf(1, numberOfHoles)).count { teeCoordinate(it) != null && flagCoordinate(it) != null }

    val hasHolePositions: Boolean get() = holePositionCount == maxOf(1, numberOfHoles)

    fun withTee(hole: Int, c: LatLon): Course = copy(
        teeLatitudes = set(teeLatitudes, hole, c.lat),
        teeLongitudes = set(teeLongitudes, hole, c.lon),
    )

    fun withFlag(hole: Int, c: LatLon): Course = copy(
        flagLatitudes = set(flagLatitudes, hole, c.lat),
        flagLongitudes = set(flagLongitudes, hole, c.lon),
    )

    fun distance(from: LatLon): Double? {
        val lat = latitude ?: return null
        val lon = longitude ?: return null
        return LatLon(lat, lon).distanceTo(from)
    }

    private fun set(list: List<Double>, hole: Int, v: Double): List<Double> {
        val i = hole - 1
        if (i < 0 || i >= numberOfHoles) return list
        val m = list.toMutableList()
        while (m.size < numberOfHoles) m.add(Double.NaN)
        m[i] = v
        return m
    }

    companion object {
        fun defaultPars(holes: Int): List<Int> {
            val pattern = listOf(4, 4, 3, 4, 5, 4, 3, 4, 5)
            return List(holes) { pattern[it % 9] }
        }

        private fun coord(lats: List<Double>, lons: List<Double>, hole: Int): LatLon? {
            val i = hole - 1
            if (i < 0 || i >= lats.size || i >= lons.size) return null
            return LatLon(lats[i], lons[i]).takeIf { it.isValid }
        }
    }
}

@Serializable
data class Shot(
    val shotNumber: Int,
    val fromLatitude: Double,
    val fromLongitude: Double,
    val toLatitude: Double,
    val toLongitude: Double,
    val club: String = "",
) {
    val from: LatLon get() = LatLon(fromLatitude, fromLongitude)
    val to: LatLon get() = LatLon(toLatitude, toLongitude)
    val distanceMeters: Double get() = from.distanceTo(to)
    val distanceYards: Int get() = (distanceMeters * 1.09361).toInt()
}

@Serializable
data class HoleScore(
    val holeNumber: Int,
    val strokes: Int = 0,
    val putts: Int = 0,
    val fairwayHit: Boolean = false,
    val greenInRegulation: Boolean = false,
    val pinLatitude: Double? = null,
    val pinLongitude: Double? = null,
    val pinIsAutomatic: Boolean = false,
    val clubName: String? = null,
    val shots: List<Shot> = emptyList(),
) {
    val hasPinLocation: Boolean get() = pinLatitude != null && pinLongitude != null
    val sortedShots: List<Shot> get() = shots.sortedBy { it.shotNumber }
    val totalDistanceMeters: Double get() = shots.sumOf { it.distanceMeters }
}

@Serializable
data class PlayerHoleScore(
    val playerIndex: Int,
    val playerName: String,
    val holeNumber: Int,
    val strokes: Int,
)

/** Ein Punkt der Laufspur – wie `TrackPoint` in RoundTrack.swift. */
@Serializable
data class TrackPoint(
    val latitude: Double,
    val longitude: Double,
    val timeOffset: Double,
    val accuracy: Double,
    val holeNumber: Int,
) {
    val coordinate: LatLon get() = LatLon(latitude, longitude)
}

@Serializable
data class RoundTrack(
    val startedAt: Long = System.currentTimeMillis(),
    val endedAt: Long? = null,
    val points: List<TrackPoint> = emptyList(),
) {
    fun points(hole: Int): List<TrackPoint> = points.filter { it.holeNumber == hole }
    val recordedHoles: List<Int> get() = points.map { it.holeNumber }.filter { it != 0 }.distinct().sorted()
}

@Serializable
data class Round(
    val id: String = newId(),
    /** Millisekunden seit 1970. */
    val date: Long = System.currentTimeMillis(),
    val courseId: String? = null,
    val isComplete: Boolean = false,
    val notes: String = "",
    val gameModeRaw: String = GameMode.STROKE_PLAY.raw,
    val bagId: String? = null,
    val otherPlayerNames: List<String> = emptyList(),
    val holeScores: List<HoleScore> = emptyList(),
    val playerHoleScores: List<PlayerHoleScore> = emptyList(),
    val track: RoundTrack? = null,
) {
    val gameMode: GameMode get() = GameMode.fromRaw(gameModeRaw)

    fun opponentScore(playerIndex: Int, holeNumber: Int): PlayerHoleScore? =
        playerHoleScores.firstOrNull { it.playerIndex == playerIndex && it.holeNumber == holeNumber }

    val sortedScores: List<HoleScore> get() = holeScores.sortedBy { it.holeNumber }
    val playedScores: List<HoleScore> get() = sortedScores.filter { it.strokes > 0 }
    val totalStrokes: Int get() = playedScores.sumOf { it.strokes }
    val totalPutts: Int get() = playedScores.sumOf { it.putts }

    fun scoreToPar(course: Course?): Int? {
        if (course == null || playedScores.isEmpty()) return null
        val parSum = playedScores.mapNotNull { course.parValues.getOrNull(it.holeNumber - 1) }.sum()
        return totalStrokes - parSum
    }

    fun scoreLabel(course: Course?): String {
        val d = scoreToPar(course) ?: return "-"
        return when {
            d == 0 -> "E"
            d > 0 -> "+$d"
            else -> "$d"
        }
    }

    fun totalStablefordPoints(course: Course?): Int {
        if (course == null) return 0
        return playedScores.sumOf { s ->
            course.parValues.getOrNull(s.holeNumber - 1)?.let { GameMode.stablefordPoints(s.strokes, it) } ?: 0
        }
    }

    val fairwaysHit: Int get() = holeScores.count { it.fairwayHit }
    val greensInRegulation: Int get() = holeScores.count { it.greenInRegulation }

    fun fairwayOpportunities(course: Course?): Int {
        if (course == null) return 0
        return playedScores.count { (course.parValues.getOrNull(it.holeNumber - 1) ?: 0) > 3 }
    }

    val girOpportunities: Int get() = playedScores.size

    fun score(hole: Int): HoleScore? = holeScores.firstOrNull { it.holeNumber == hole }

    fun withHoleScore(score: HoleScore): Round =
        copy(holeScores = holeScores.filter { it.holeNumber != score.holeNumber } + score)
}

@Serializable
data class GolfClub(
    val id: String = newId(),
    val name: String,
    val defaultDistance: Int,
    val measuredDistances: List<Double> = emptyList(),
    val order: Int = 0,
    val isPutter: Boolean = false,
) {
    val hasUserData: Boolean get() = measuredDistances.isNotEmpty()
    val shotCount: Int get() = measuredDistances.size
    val minDistance: Int get() = measuredDistances.minOrNull()?.let { Math.round(it).toInt() } ?: 0
    val maxDistance: Int get() = measuredDistances.maxOrNull()?.let { Math.round(it).toInt() } ?: 0
    val averageDistance: Int
        get() = if (!hasUserData) defaultDistance else Math.round(measuredDistances.average()).toInt()

    fun addMeasurement(meters: Double): GolfClub =
        if (meters < 5 || meters > 450) this else copy(measuredDistances = measuredDistances + meters)
}

@Serializable
data class GolfBag(
    val id: String = newId(),
    val name: String,
    val createdAt: Long = System.currentTimeMillis(),
    val clubs: List<GolfClub> = emptyList(),
) {
    val sortedClubs: List<GolfClub> get() = clubs.sortedBy { it.order }
}

@Serializable
data class QuizResult(
    val id: String = newId(),
    val date: Long = System.currentTimeMillis(),
    /** "smart" | "exam" */
    val mode: String,
    val score: Int,
    val total: Int,
    val durationSeconds: Int,
    val passed: Boolean = if (mode == "exam") total > 0 && score.toDouble() / total >= 0.75 else true,
) {
    val percentage: Double get() = if (total > 0) score.toDouble() / total * 100 else 0.0
    val durationFormatted: String
        get() {
            val m = durationSeconds / 60
            val s = durationSeconds % 60
            return if (m > 0) "${m}m ${s}s" else "${s}s"
        }
}

enum class DistanceUnit(val raw: String, val displayName: String, val unitLabel: String) {
    METERS("metric", "Meter", "m"),
    YARDS("imperial", "Yards", "y");

    fun value(meters: Double): Int = if (this == METERS) meters.toInt() else (meters * 1.09361).toInt()
    fun format(meters: Double): String = "${value(meters)} $unitLabel"

    companion object {
        fun fromRaw(raw: String?): DistanceUnit = entries.firstOrNull { it.raw == raw } ?: METERS
    }
}

enum class AppFocus(val raw: String) {
    GOLF("golf"), MINIGOLF("minigolf");

    companion object {
        fun fromRaw(raw: String?): AppFocus = entries.firstOrNull { it.raw == raw } ?: GOLF
    }
}
