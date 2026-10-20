package app.golftrack.feature.home

import app.golftrack.data.LatLon
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.ui.DeepLinks
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Erkennt, dass jemand an einem Platz aus dem Verzeichnis steht – wie
 * `NearbyCourseService` auf iOS, aber nur die erste Stufe (Vorschlag in der
 * App). Eine Mitteilung bei geschlossener App bräuchte Hintergrund-Standort
 * und Geofencing; das gibt es in der Android-Fassung nicht.
 *
 * Gemeldet wird der **erste Abschlag**, nicht die Adresse der Anlage.
 */
object NearbyCourses {
    data class NearbyCourse(
        val kind: DeepLinks.Kind,
        val slug: String,
        val name: String,
        val location: String,
        val distance: Double,
    ) {
        val id: String get() = "${kind.name}/$slug"
    }

    /** Für den Vorschlag darf es etwas großzügiger sein – wer die App am Parkplatz öffnet, meint denselben Platz. */
    private const val SUGGESTION_RADIUS = 500.0
    /** Neue Plätze werden gemeldet, wenn sie höchstens so weit weg liegen. */
    private const val NEW_COURSE_RADIUS = 30_000.0

    private val _suggestion = MutableStateFlow<NearbyCourse?>(null)
    val suggestion: StateFlow<NearbyCourse?> = _suggestion.asStateFlow()
    private val _newNearby = MutableStateFlow<List<NearbyCourse>>(emptyList())
    val newNearby: StateFlow<List<NearbyCourse>> = _newNearby.asStateFlow()

    /** Für diesen Besuch weggeklickt – kommt beim nächsten App-Start wieder. */
    private val dismissed = mutableSetOf<String>()

    private data class Candidate(val kind: DeepLinks.Kind, val slug: String, val name: String, val location: String, val point: LatLon)

    /** Bewusst nur das Verzeichnis: ohne Kennung gibt es keinen Link. */
    private fun candidates(): List<Candidate> {
        val golf = CourseCatalog.remoteGolfCourses.value.mapNotNull { e ->
            val p = e.startCoordinate ?: return@mapNotNull null
            if (e.slug.isEmpty()) null else Candidate(DeepLinks.Kind.GOLF, e.slug, e.name, e.location, p)
        }
        val mini = CourseCatalog.minigolfCourses.value.mapNotNull { e ->
            val p = e.startCoordinate ?: return@mapNotNull null
            Candidate(DeepLinks.Kind.MINIGOLF, e.id, e.name, e.location, p)
        }
        return golf + mini
    }

    fun update(here: LatLon) {
        val all = candidates()
        val naechster = all.map { it to it.point.distanceTo(here) }
            .filter { it.second <= SUGGESTION_RADIUS }
            .minByOrNull { it.second }
        _suggestion.value = naechster
            ?.let { (c, d) -> NearbyCourse(c.kind, c.slug, c.name, c.location, d) }
            ?.takeIf { it.id !in dismissed }

        val neu = CourseCatalog.newCourseIDs
        _newNearby.value = if (neu.isEmpty()) emptyList() else all
            .filter { it.slug in neu }
            .map { it to it.point.distanceTo(here) }
            .filter { it.second <= NEW_COURSE_RADIUS }
            .sortedBy { it.second }
            .map { (c, d) -> NearbyCourse(c.kind, c.slug, c.name, c.location, d) }
    }

    fun dismissSuggestion() {
        _suggestion.value?.let { dismissed.add(it.id) }
        _suggestion.value = null
    }

    /** Die neuen Plätze sind gesehen – sie melden sich nicht wieder. */
    fun dismissNewNearby() {
        CourseCatalog.markNewCoursesSeen(_newNearby.value.map { it.slug })
        _newNearby.value = emptyList()
    }
}
