package app.golftrack.feature.guide

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.systemBars
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavBackStackEntry
import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavType
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import app.golftrack.data.GameMode
import app.golftrack.ui.common.Routes

/** Interne Unterseiten des Wissensbereichs (Regeln, Ratgeber, Platzreife, Spielmodi, Tipps). */
object GuideNav {
    const val RULES_CATEGORY = "guide/rules/cat/{c}"
    fun rulesCategory(c: Int) = "guide/rules/cat/$c"
    const val RULE = "guide/rules/rule/{c}/{r}"
    fun rule(c: Int, r: Int) = "guide/rules/rule/$c/$r"

    const val CHAPTER = "guide/guide/chapter/{c}"
    fun chapter(c: Int) = "guide/guide/chapter/$c"
    const val LESSON = "guide/guide/lesson/{c}/{l}"
    fun lesson(c: Int, l: Int) = "guide/guide/lesson/$c/$l"

    const val SESSION = "guide/platzreife/session?cat={cat}&mistakes={mistakes}"
    fun session(category: QuizCategory?, mistakesOnly: Boolean) =
        "guide/platzreife/session?cat=${category?.name ?: ""}&mistakes=$mistakesOnly"
    const val EXAM = "guide/platzreife/exam"

    const val GAME_MODE = "guide/gamemodes/{mode}"
    fun gameMode(mode: GameMode) = "guide/gamemodes/${mode.raw}"

    const val TIPS_CATEGORY = "guide/tips/cat/{c}"
    fun tipsCategory(c: Int) = "guide/tips/cat/$c"
    const val TIP = "guide/tips/tip/{c}/{t}"
    fun tip(c: Int, t: Int) = "guide/tips/tip/$c/$t"
}

/** Tab „Regeln“ – Golfregeln 2023 ohne Zurück-Pfeil. */
@Composable
fun RulesTab(nav: NavController) {
    // Die Tableiste hat Statusleiste/Navigationsleiste schon berücksichtigt.
    Box(Modifier.consumeWindowInsets(WindowInsets.systemBars)) { GolfRulesScreen(nav, onBack = null) }
}

/** Tab „Tipps“ – Tipps & Coaching. */
@Composable
fun TipsTab(nav: NavController) = TipsScreen(nav)

private fun NavBackStackEntry.int(name: String) = arguments?.getString(name)?.toIntOrNull() ?: 0

fun NavGraphBuilder.guideRoutes(nav: NavController) {
    // Golfregeln
    composable(Routes.RULES) { GolfRulesScreen(nav, onBack = { nav.popBackStack() }) }
    composable(GuideNav.RULES_CATEGORY) { RulesCategoryScreen(nav, it.int("c")) }
    composable(GuideNav.RULE) { RuleDetailScreen(nav, it.int("c"), it.int("r")) }

    // Golf-Ratgeber
    composable(Routes.GUIDE) { GolfGuideScreen(nav) }
    composable(GuideNav.CHAPTER) { ChapterDetailScreen(nav, it.int("c")) }
    composable(GuideNav.LESSON) { LessonDetailScreen(nav, it.int("c"), it.int("l")) }

    // Platzreife
    composable(Routes.PLATZREIFE) { PlatzreifeQuizScreen(nav) }
    composable(
        GuideNav.SESSION,
        arguments = listOf(
            navArgument("cat") { type = NavType.StringType; defaultValue = "" },
            navArgument("mistakes") { type = NavType.BoolType; defaultValue = false },
        ),
    ) { e ->
        val cat = e.arguments?.getString("cat")?.let { name -> QuizCategory.entries.firstOrNull { it.name == name } }
        PlatzreifeSessionScreen(nav, cat, e.arguments?.getBoolean("mistakes") ?: false)
    }
    composable(GuideNav.EXAM) { PlatzreifeExamScreen(nav) }

    // Spielmodi
    composable(Routes.GAME_MODES) { GameModesScreen(nav) }
    composable(GuideNav.GAME_MODE) { e -> GameModeDetailScreen(nav, GameMode.fromRaw(e.arguments?.getString("mode"))) }

    // Tipps
    composable(GuideNav.TIPS_CATEGORY) { TipsCategoryScreen(nav, it.int("c")) }
    composable(GuideNav.TIP) { TipDetailScreen(nav, it.int("c"), it.int("t")) }

    // Tutorial
    composable(Routes.TUTORIAL) { TutorialScreen(nav) }
}
