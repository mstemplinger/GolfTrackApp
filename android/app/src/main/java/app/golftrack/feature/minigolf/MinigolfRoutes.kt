package app.golftrack.feature.minigolf

import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavType
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import app.golftrack.ui.common.Placeholder
import app.golftrack.ui.common.Routes

/**
 * Zusätzliche Ziele des Minigolf-Bereichs. Von außen erreichbar sind
 * `HISTORY` (Startseite: „Minigolf-Verlauf") und `TOOLS` (Profil: „Distanz & Karte").
 */
object MinigolfRoutes {
    const val PLAY = "minigolf/play"
    const val HISTORY = "minigolf/history"
    const val TOOLS = "minigolf/tools"
    const val LANE = "minigolf/lane/{n}"
    fun lane(n: Int) = "minigolf/lane/$n"
}

/** Tab-Inhalt bei Minigolf-Schwerpunkt. */
@Composable
fun MinigolfTab(nav: NavController) = MinigolfScreen(nav, onBack = null)

fun NavGraphBuilder.minigolfRoutes(nav: NavController) {
    composable(Routes.MINIGOLF) { MinigolfScreen(nav, onBack = { nav.popBackStack() }) }

    composable(Routes.MINIGOLF_COURSE, arguments = listOf(navArgument("slug") { type = NavType.StringType })) { entry ->
        val slug = Uri.decode(entry.arguments?.getString("slug").orEmpty())
        MinigolfCourseStartRoute(nav, slug)
    }

    composable(MinigolfRoutes.PLAY) {
        // Konfiguration aus der Übergabe, sonst (nach Prozessende) das gesicherte Spiel.
        val config = remember {
            MinigolfSession.pending ?: MinigolfGameStore.load()?.let { MinigolfSession.configFromSaved(it) }
        }
        if (config == null || config.playerNames.isEmpty() || config.numberOfHoles <= 0) {
            Placeholder("Kein laufendes Spiel")
        } else {
            MinigolfScoringScreen(nav, config)
        }
    }

    composable(MinigolfRoutes.HISTORY) { MinigolfHistoryScreen(nav) }
    composable(MinigolfRoutes.TOOLS) { MinigolfToolsScreen(nav) }

    composable(MinigolfRoutes.LANE, arguments = listOf(navArgument("n") { type = NavType.IntType })) { entry ->
        val lane = MinigolfStandardLanes.lane(entry.arguments?.getInt("n") ?: 0)
        if (lane != null) MinigolfLaneDetailScreen(nav, lane) else Placeholder("Bahn nicht gefunden")
    }
}
