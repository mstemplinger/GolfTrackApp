package app.golftrack.data.catalog

import app.golftrack.data.LatLon

/** Fest eingebaute Minigolfanlagen wie `MinigolfCourses` in GolfTrackShared. */
object MinigolfCourses {
    val all: List<MinigolfCourseEntry> = listOf(
        // Bahnenzahl und Koordinaten sind die Anlage im Ortskern; falls sich
        // etwas ändert, reicht eine Anpassung hier – der QR-Code bleibt gültig,
        // solange die `id` gleich bleibt.
        MinigolfCourseEntry(
            id = "sankt-englmar",
            name = "Minigolf Sankt Englmar",
            location = "Sankt Englmar, Bayerischer Wald",
            holes = 18,
            lat = 48.9906, lon = 12.8114,
            welcome = "Servus in Sankt Englmar! Ab jetzt zählen wir für dich mit – Bahn für Bahn, Schlag für Schlag.",
            notes = "Schläger und Bälle gibt es vor Ort",
        ),
    )

    fun course(id: String): MinigolfCourseEntry? = all.firstOrNull { it.id == id }

    /** Mit Standort nach Entfernung, sonst alphabetisch – es wird bewusst nichts weggefiltert. */
    fun sorted(courses: List<MinigolfCourseEntry>, near: LatLon?): List<MinigolfCourseEntry> {
        if (near == null) return courses.sortedWith(compareBy(String.CASE_INSENSITIVE_ORDER) { it.name })
        return courses.sortedWith(compareBy<MinigolfCourseEntry> { it.distance(near) }
            .thenBy(String.CASE_INSENSITIVE_ORDER) { it.name })
    }

    /** Nächstgelegene Anlage – für „Du stehst gerade hier"-Hinweise. */
    fun nearest(to: LatLon, within: Double = 2_000.0): MinigolfCourseEntry? =
        all.map { it to it.distance(to) }.filter { it.second <= within }.minByOrNull { it.second }?.first
}
