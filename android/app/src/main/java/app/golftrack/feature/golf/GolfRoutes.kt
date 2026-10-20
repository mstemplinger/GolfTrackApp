package app.golftrack.feature.golf

import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavType
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import app.golftrack.data.GameMode
import app.golftrack.ui.common.Routes

/** Golfrunde starten und spielen. */
fun NavGraphBuilder.golfRoutes(nav: NavController) {
    composable(
        Routes.NEW_ROUND,
        arguments = listOf(
            navArgument("courseId") { type = NavType.StringType; nullable = true; defaultValue = null },
            navArgument("mode") { type = NavType.StringType; nullable = true; defaultValue = null },
        ),
    ) { entry ->
        NewRoundScreen(
            nav,
            preselectedCourseId = entry.arguments?.getString("courseId"),
            preselectedMode = GameMode.fromRaw(entry.arguments?.getString("mode")),
        )
    }
    composable(Routes.PLAY_ROUND) { entry ->
        ScorecardScreen(nav, roundId = entry.arguments?.getString("roundId") ?: "")
    }
}
