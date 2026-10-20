package app.golftrack.ui

import android.net.Uri
import androidx.navigation.NavController
import app.golftrack.data.AppFocus
import app.golftrack.data.GolfStore
import app.golftrack.data.Prefs
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes

/**
 * Auswertung von QR-Codes und Links wie `CourseDeepLink` auf iOS:
 *  - https://golftrack.app/minigolf/<slug>, https://golftrack.app/golf/<slug>
 *  - https://play.golftrack.app/p/<kennung> (Art steht nicht im Link)
 *  - golftrack://minigolf/<slug>, golftrack://golf/<slug>
 *  - golftrack://platzreife, golftrack://home
 */
object DeepLinks {
    enum class Kind { GOLF, MINIGOLF }
    data class Link(val kind: Kind?, val slug: String)

    fun parse(uri: Uri): Link? {
        val segs = uri.pathSegments
        return when (uri.scheme) {
            "https", "http" -> when {
                segs.size >= 2 && segs[0] == "minigolf" -> Link(Kind.MINIGOLF, segs[1])
                segs.size >= 2 && segs[0] == "golf" -> Link(Kind.GOLF, segs[1])
                segs.size >= 2 && segs[0] == "p" -> Link(null, segs[1])
                else -> null
            }
            "golftrack" -> when (uri.host) {
                "minigolf" -> segs.firstOrNull()?.let { Link(Kind.MINIGOLF, it) }
                "golf" -> segs.firstOrNull()?.let { Link(Kind.GOLF, it) }
                else -> null
            }
            else -> null
        }
    }

    fun handleScheme(uri: Uri, nav: NavController) {
        if (uri.scheme != "golftrack") return
        nav.popBackStack(Routes.MAIN, inclusive = false)
        when (uri.host) {
            "platzreife" -> nav.navigate(Routes.PLATZREIFE)
            "shottracker" -> GolfStore.current.openRound?.let { nav.navigate(Routes.playRound(it.id)) }
        }
    }

    /** `false`, wenn die Anlage (noch) nicht im Katalog steht. */
    fun open(link: Link, nav: NavController): Boolean {
        val mini = if (link.kind != Kind.GOLF) CourseCatalog.minigolfCourse(link.slug) else null
        if (mini != null) {
            chooseFocusIfNeeded(AppFocus.MINIGOLF)
            Haptics.success()
            nav.navigate(Routes.minigolfCourse(mini.id))
            return true
        }
        val golf = if (link.kind != Kind.MINIGOLF) CourseCatalog.golfCourse(link.slug) else null
        if (golf != null) {
            chooseFocusIfNeeded(AppFocus.GOLF)
            Haptics.success()
            val course = GolfStore.storedCourse(golf.toCourse())
            nav.navigate(Routes.newRound(course.id))
            return true
        }
        return false
    }

    private fun chooseFocusIfNeeded(focus: AppFocus) {
        if (!Prefs.bool("hasChosenAppFocus")) {
            Prefs.appFocus = focus
            Prefs.set("hasChosenAppFocus", true)
            Prefs.set("hasSeenOnboarding", true)
        }
    }
}
