package app.golftrack.data.catalog

import app.golftrack.data.Course
import app.golftrack.data.LatLon
import kotlinx.serialization.Serializable

/** Wie `CourseHintKind` in GolfTrackShared/CourseHints.swift. */
@Serializable
enum class CourseHintKind { toilet, shelter, drinks, food, rental, parking, water, firstAid, info }

@Serializable
data class CourseHint(val kind: CourseHintKind = CourseHintKind.info, val text: String)

/** Golfplatz aus dem Verzeichnis (eingebaut oder von golftrack.app) – wie `BundledCourseEntry`. */
data class GolfCourseEntry(
    val name: String,
    val slug: String = "",
    val location: String,
    val holes: Int,
    val lat: Double,
    val lon: Double,
    val parValues: List<Int> = emptyList(),
    val hcpValues: List<Int> = emptyList(),
    val holeLengths: List<Int> = emptyList(),
    val courseRating: Double = 72.0,
    val slopeRating: Int = 113,
    val facilityNotes: String = "",
    val hints: List<CourseHint> = emptyList(),
    val teeLatitudes: List<Double> = emptyList(),
    val teeLongitudes: List<Double> = emptyList(),
    val flagLatitudes: List<Double> = emptyList(),
    val flagLongitudes: List<Double> = emptyList(),
    val firstTeeLat: Double? = null,
    val firstTeeLon: Double? = null,
) {
    val id: String get() = name

    val startCoordinate: LatLon?
        get() = if (firstTeeLat != null && firstTeeLon != null) LatLon(firstTeeLat, firstTeeLon)
        else if (lat != 0.0 || lon != 0.0) LatLon(lat, lon) else null

    fun distance(from: LatLon): Double = LatLon(lat, lon).distanceTo(from)

    /** Als eigener `Course`-Eintrag für die Datenbank (noch nicht gespeichert). */
    fun toCourse(): Course = Course(
        name = name, location = location, numberOfHoles = holes,
        parValues = parValues.ifEmpty { Course.defaultPars(holes) },
        courseRating = courseRating, slopeRating = slopeRating,
        hcpValues = hcpValues, holeLengths = holeLengths, facilityNotes = facilityNotes,
        latitude = lat, longitude = lon,
        teeLatitudes = teeLatitudes, teeLongitudes = teeLongitudes,
        flagLatitudes = flagLatitudes, flagLongitudes = flagLongitudes,
        slug = slug,
    )
}

/** Minigolfanlage – wie `MinigolfCourseEntry` in GolfTrackShared/MinigolfCourses.swift. */
data class MinigolfCourseEntry(
    /** Stabile Kennung aus dem QR-Code. */
    val id: String,
    val name: String,
    val location: String,
    val holes: Int,
    val lat: Double,
    val lon: Double,
    val welcome: String,
    val notes: String = "",
    val hints: List<CourseHint> = emptyList(),
    val firstTeeLat: Double? = null,
    val firstTeeLon: Double? = null,
) {
    val startCoordinate: LatLon?
        get() = if (firstTeeLat != null && firstTeeLon != null) LatLon(firstTeeLat, firstTeeLon)
        else if (lat != 0.0 || lon != 0.0) LatLon(lat, lon) else null

    fun distance(from: LatLon): Double = LatLon(lat, lon).distanceTo(from)
}

/** Entfernung als Text wie `formattedDistance` auf iOS. */
fun formatKm(meters: Double): String {
    val km = meters / 1000
    return when {
        km < 1 -> "< 1 km"
        km < 10 -> String.format(java.util.Locale.GERMANY, "%.1f km", km)
        else -> String.format(java.util.Locale.GERMANY, "%.0f km", km)
    }
}
