package app.golftrack.feature.minigolf

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Help
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.ArrowCircleRight
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.GolfCourse
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.data.catalog.MinigolfCourseEntry
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.launch

private enum class StartStep { WELCOME, TUTORIAL_QUESTION, TUTORIAL, PLAYERS }

private data class TutorialSlide(val icon: ImageVector, val title: String, val text: String)

private val tutorialSlides = listOf(
    TutorialSlide(Icons.Filled.AddCircle, "Schläge zählen",
        "Jeder Spieler hat eine eigene Zeile. Nach jedem Schlag auf + tippen – verzählt? Das Minus korrigiert."),
    TutorialSlide(Icons.Filled.ArrowCircleRight, "Bahn für Bahn",
        "Unten auf „Weiter“ geht es zur nächsten Bahn. Der Stand wird automatisch gesichert, auch wenn du das Handy weglegst."),
    TutorialSlide(Icons.Filled.EmojiEvents, "Ergebnis",
        "Oben rechts siehst du jederzeit die Tabelle. Nach der letzten Bahn steht der Sieger fest."),
)

/**
 * Einstieg nach dem Scannen des QR-Codes: Begrüßung → Frage nach dem Tutorial
 * → Spieler → Runde läuft. Wie `MinigolfCourseStartView`.
 */
@Composable
internal fun MinigolfCourseStartRoute(nav: NavController, slug: String) {
    val courses by CourseCatalog.minigolfCourses.collectAsState()
    val course = courses.firstOrNull { it.id == slug }
    var loading by remember { mutableStateOf(course == null) }
    LaunchedEffect(slug) {
        if (CourseCatalog.minigolfCourse(slug) == null) {
            loading = true
            CourseCatalog.refreshIfNeeded()
            loading = false
        }
    }
    if (course != null) {
        MinigolfCourseStartScreen(nav, course)
    } else {
        AppScaffold("Minigolf", onBack = { nav.popBackStack() }) { m ->
            Box(m.padding(24.dp), contentAlignment = Alignment.Center) {
                if (loading) CircularProgressIndicator(color = AppTheme.gold)
                else MgText("Diese Anlage steht noch nicht im Verzeichnis.", MgFont.subheadline, AppTheme.textSec, textAlign = TextAlign.Center)
            }
        }
    }
}

@Composable
private fun MinigolfCourseStartScreen(nav: NavController, course: MinigolfCourseEntry) {
    var step by rememberSaveable { mutableStateOf(StartStep.WELCOME) }
    var rawNames by rememberSaveable(stateSaver = namesSaver) { mutableStateOf(listOf("", "")) }
    var challenges by rememberSaveable(stateSaver = challengeListSaver) { mutableStateOf(emptyList()) }
    var loadedDefaults by rememberSaveable { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        if (!loadedDefaults) {
            loadedDefaults = true
            MinigolfGameStore.loadNames()?.takeIf { it.isNotEmpty() }?.let { rawNames = it }
            if (challenges.isEmpty()) challenges = MinigolfGameStore.loadChallenges()
        }
    }

    fun startRound() {
        MinigolfGameStore.saveNames(rawNames)
        MinigolfGameStore.saveChallenges(challenges)
        MinigolfGameStore.clear()
        MinigolfSession.pending = MinigolfConfig(
            playerNames = resolvedNames(rawNames), numberOfHoles = course.holes,
            courseName = course.name, courseID = course.id, challenges = challenges, hints = course.hints,
        )
        // Runde beendet oder verlassen → gesamter Ablauf ist weg.
        nav.navigate(MinigolfRoutes.PLAY) { popUpTo(Routes.MINIGOLF_COURSE) { inclusive = true } }
    }

    AppScaffold(course.name, onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp)) {
            AnimatedContent(step, transitionSpec = { fadeIn() togetherWith fadeOut() }, label = "step") { s ->
                Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp)) {
                    when (s) {
                        StartStep.WELCOME -> WelcomeStep(course) { step = StartStep.TUTORIAL_QUESTION }
                        StartStep.TUTORIAL_QUESTION -> TutorialQuestionStep(
                            onYes = { step = StartStep.TUTORIAL },
                            onNo = { step = StartStep.PLAYERS },
                        )
                        StartStep.TUTORIAL -> TutorialStep { step = StartStep.PLAYERS }
                        StartStep.PLAYERS -> {
                            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
                                modifier = Modifier.padding(top = 8.dp)) {
                                MgText("Wer spielt mit?", MgFont.title2, weight = FontWeight.Bold)
                                MgText("Namen sind optional – leer lassen geht auch.", MgFont.subheadline, AppTheme.textSec)
                            }
                            Column(Modifier.mgCard().animateContentSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                PlayersEditor(rawNames) { rawNames = it }
                                PlayerCountButtons(rawNames.size, onAdd = { rawNames = rawNames + "" },
                                    onRemove = { if (rawNames.isNotEmpty()) rawNames = rawNames.dropLast(1) })
                            }
                            ChallengeSetupCard(challenges, { challenges = it }, initiallyExpanded = false)
                            MgPillButton("Runde starten · ${course.holes} Bahnen", null, AppTheme.gold, AppTheme.onGold, Modifier.fillMaxWidth(),
                                radius = 14.dp, vertical = 16.dp, size = MgFont.headline, haptic = { Haptics.medium() }, onClick = ::startRound)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun BigIcon(icon: ImageVector) =
    Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.padding(top = 12.dp).size(52.dp))

@Composable
private fun WelcomeStep(course: MinigolfCourseEntry, onGo: () -> Unit) {
    BigIcon(Icons.Filled.GolfCourse)
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        MgText("Willkommen!", MgFont.title, weight = FontWeight.Bold)
        MgText(course.welcome, MgFont.subheadline, AppTheme.textSec, textAlign = TextAlign.Center)
    }
    Column(Modifier.mgCard(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        InfoRow(Icons.Filled.Place, course.location)
        InfoRow(Icons.Filled.Flag, "${course.holes} Bahnen")
        if (course.notes.isNotEmpty()) InfoRow(Icons.Outlined.Info, course.notes)
    }
    CourseHintsCard(course.hints)
    MgPillButton("Los geht's", null, AppTheme.gold, AppTheme.onGold, Modifier.fillMaxWidth(),
        radius = 14.dp, vertical = 16.dp, size = MgFont.headline, haptic = { Haptics.medium() }, onClick = onGo)
}

@Composable
private fun InfoRow(icon: ImageVector, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.width(22.dp).size(18.dp))
        MgText(text, MgFont.subheadline, AppTheme.textSec, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun TutorialQuestionStep(onYes: () -> Unit, onNo: () -> Unit) {
    BigIcon(Icons.AutoMirrored.Filled.Help)
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        MgText("Kurz erklärt?", MgFont.title2, weight = FontWeight.Bold)
        MgText("Drei Sätze, wie das Zählen in der App funktioniert – oder direkt loslegen.",
            MgFont.subheadline, AppTheme.textSec, textAlign = TextAlign.Center)
    }
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        MgPillButton("Ja, kurz zeigen", Icons.Filled.AutoAwesome, AppTheme.gold, AppTheme.onGold, Modifier.fillMaxWidth(),
            radius = 14.dp, vertical = 16.dp, size = MgFont.headline, onClick = onYes)
        MgPillButton("Nein, direkt starten", Icons.Filled.SportsGolf, AppTheme.card, Color.White, Modifier.fillMaxWidth(),
            radius = 14.dp, vertical = 16.dp, size = MgFont.headline, onClick = onNo)
    }
}

@Composable
private fun TutorialStep(onDone: () -> Unit) {
    val pager = rememberPagerState { tutorialSlides.size }
    val scope = rememberCoroutineScope()
    HorizontalPager(pager, Modifier.fillMaxWidth().height(250.dp)) { i ->
        val slide = tutorialSlides[i]
        Column(
            Modifier.fillMaxSize().padding(top = 20.dp, start = 16.dp, end = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Icon(slide.icon, null, tint = AppTheme.gold, modifier = Modifier.size(52.dp))
            MgText(slide.title, MgFont.title3, weight = FontWeight.Bold)
            MgText(slide.text, MgFont.subheadline, AppTheme.textSec, textAlign = TextAlign.Center)
        }
    }
    // Seitenpunkte wie `.page(indexDisplayMode: .always)`
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        repeat(tutorialSlides.size) { i ->
            Box(Modifier.size(7.dp).background(if (i == pager.currentPage) AppTheme.text else AppTheme.textTer, CircleShape))
        }
    }
    val last = pager.currentPage >= tutorialSlides.size - 1
    MgPillButton(if (last) "Verstanden" else "Weiter", null, AppTheme.gold, AppTheme.onGold, Modifier.fillMaxWidth(),
        radius = 14.dp, vertical = 16.dp, size = MgFont.headline, haptic = { Haptics.selection() }) {
        if (!last) scope.launch { pager.animateScrollToPage(pager.currentPage + 1) } else onDone()
    }
    MgText("Überspringen", MgFont.subheadline, AppTheme.textSec,
        modifier = Modifier.clickable { Haptics.tap(); onDone() }.padding(6.dp))
    Spacer(Modifier.height(4.dp))
}
