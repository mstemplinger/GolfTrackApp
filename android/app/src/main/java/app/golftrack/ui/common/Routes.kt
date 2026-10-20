package app.golftrack.ui.common

import android.net.Uri

/**
 * Alle Ziele der App. Die Tabs liegen unter `MAIN`; alles andere öffnet sich
 * bildschirmfüllend darüber (ohne Tableiste). Jede Feature-Datei registriert
 * ihre Ziele in `AppNavHost` über eine `NavGraphBuilder.xyzRoutes(nav)`-Funktion.
 *
 * Querverweise zwischen Features nur über diese Konstanten/Funktionen.
 */
object Routes {
    const val MAIN = "main"

    // Golf (feature/golf)
    const val NEW_ROUND = "golf/new?courseId={courseId}&mode={mode}"
    /** `mode` = `GameMode.raw` zum Vorwählen der Spielform. */
    fun newRound(courseId: String? = null, mode: String? = null): String {
        val q = listOfNotNull(courseId?.let { "courseId=$it" }, mode?.let { "mode=$it" })
        return if (q.isEmpty()) "golf/new" else "golf/new?" + q.joinToString("&")
    }
    const val PLAY_ROUND = "golf/play/{roundId}"
    fun playRound(roundId: String) = "golf/play/$roundId"
    const val ROUND_DETAIL = "golf/round/{roundId}"
    fun roundDetail(roundId: String) = "golf/round/$roundId"
    const val HISTORY = "golf/history"
    const val STATISTICS = "golf/statistics"
    const val COURSES = "golf/courses"
    const val COURSE_EDIT = "golf/course/{courseId}"
    fun courseEdit(courseId: String) = "golf/course/$courseId"

    // Minigolf (feature/minigolf)
    const val MINIGOLF = "minigolf"
    const val MINIGOLF_COURSE = "minigolf/course/{slug}"
    fun minigolfCourse(slug: String) = "minigolf/course/${Uri.encode(slug)}"

    // Wissen (feature/guide)
    const val RULES = "guide/rules"
    const val GUIDE = "guide/guide"
    const val PLATZREIFE = "guide/platzreife"
    const val GAME_MODES = "guide/gamemodes"
    const val TUTORIAL = "guide/tutorial"

    // Profil & Co. (feature/profile, feature/home)
    const val CLUB_BAG = "profile/clubbag"
    const val SETTINGS = "profile/settings"
    const val DOCUMENTS = "profile/documents"
    const val HELP = "profile/help"
    const val WEATHER = "home/weather"
    const val AD_DETAIL = "ads/{adId}"
    fun adDetail(adId: String) = "ads/${Uri.encode(adId)}"

    // Funktionen, die erst mit einer späteren Version kommen
    const val COMING_LATER = "later/{feature}"
    fun comingLater(feature: LaterFeature) = "later/${feature.name}"
}

/** Auf iOS kostenpflichtige Bereiche – in der ersten Android-Version noch nicht enthalten. */
enum class LaterFeature(val title: String, val text: String) {
    CADDY(
        "KI-Caddy",
        "Der sprechende KI-Caddy kommt mit einer späteren Version auch auf Android.",
    ),
    AUDIOBOOKS(
        "Training & Audiobooks",
        "Die Trainingslektionen und Audiobooks kommen mit einer späteren Version auch auf Android.",
    ),
}
