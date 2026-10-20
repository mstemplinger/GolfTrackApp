package app.golftrack.feature.home

import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import app.golftrack.feature.ads.AdDetailScreen
import app.golftrack.ui.common.Routes

/** Eigene Unterseiten der Startseite (nicht in `Routes`, nur hier verlinkt). */
object HomeExtraRoutes {
    const val WEATHER_SETTINGS = "home/weather/settings"
}

fun NavGraphBuilder.homeRoutes(nav: NavController) {
    composable(Routes.WEATHER) { WeatherForecastScreen(nav) }
    composable(HomeExtraRoutes.WEATHER_SETTINGS) { GolfWeatherSettingsScreen(nav) }
    composable(Routes.AD_DETAIL) { entry ->
        AdDetailScreen(nav, entry.arguments?.getString("adId").orEmpty())
    }
}
