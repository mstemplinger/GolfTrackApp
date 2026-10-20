package app.golftrack.feature.minigolf

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.data.catalog.MinigolfCourseEntry
import app.golftrack.data.catalog.formatKm
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.common.rememberLocation
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.launch

internal val namesSaver = Saver<List<String>, ArrayList<String>>(save = { ArrayList(it) }, restore = { it })
internal val challengeListSaver = Saver<List<MinigolfChallenge>, ArrayList<String>>(
    save = { l -> ArrayList(l.map { it.raw }) },
    restore = { l -> l.mapNotNull { MinigolfChallenge.fromRaw(it) } },
)

private enum class MinigolfSegment { SPIEL, BAHNEN }

/** „Minigolf & Putten" – wie `MinigolfView`. `onBack == null` als Tab-Inhalt. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun MinigolfScreen(nav: NavController, onBack: (() -> Unit)?) {
    var rawNames by rememberSaveable(stateSaver = namesSaver) { mutableStateOf(listOf("", "")) }
    var numberOfHoles by rememberSaveable { mutableStateOf(9) }
    var selectedChallenges by rememberSaveable(stateSaver = challengeListSaver) { mutableStateOf(emptyList()) }
    var activeTab by rememberSaveable { mutableStateOf(MinigolfSegment.SPIEL) }
    var savedGame by remember { mutableStateOf(MinigolfGameStore.load()) }
    var history by remember { mutableStateOf(MinigolfGameStore.loadHistory()) }
    var selectedHistory by remember { mutableStateOf<MinigolfHistoryEntry?>(null) }
    var refreshing by remember { mutableStateOf(false) }
    var loadedDefaults by rememberSaveable { mutableStateOf(false) }

    val courses by CourseCatalog.minigolfCourses.collectAsState()
    // Nur für die Entfernungen – ohne Standort steht die Liste alphabetisch da.
    val here = rememberLocation()
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        if (!loadedDefaults) {
            loadedDefaults = true
            MinigolfGameStore.loadNames()?.takeIf { it.isNotEmpty() }?.let { if (rawNames == listOf("", "")) rawNames = it }
        }
        // Wie onAppear auf iOS: bei jeder Rückkehr den letzten Stand übernehmen.
        if (selectedChallenges.isEmpty()) selectedChallenges = MinigolfGameStore.loadChallenges()
        CourseCatalog.refreshIfNeeded()
    }

    fun startGame() {
        MinigolfGameStore.saveNames(rawNames)
        MinigolfGameStore.saveChallenges(selectedChallenges)
        MinigolfGameStore.clear()
        savedGame = null
        MinigolfSession.pending = MinigolfConfig(resolvedNames(rawNames), numberOfHoles, challenges = selectedChallenges)
        nav.navigate(MinigolfRoutes.PLAY)
    }

    AppScaffold("Minigolf & Putten", onBack = onBack) { m ->
        Column(m) {
            SegmentedPicker(
                options = listOf(
                    Triple(MinigolfSegment.SPIEL, "Spiel", Icons.Filled.SportsGolf),
                    Triple(MinigolfSegment.BAHNEN, "Bahnen & Regeln", Icons.AutoMirrored.Filled.MenuBook),
                ),
                selected = activeTab,
                onSelect = { Haptics.selection(); activeTab = it },
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
            )
            HorizontalDivider(color = AppTheme.text.copy(alpha = 0.12f))

            // Nach unten ziehen holt das Verzeichnis sofort.
            PullToRefreshBox(
                isRefreshing = refreshing,
                onRefresh = {
                    scope.launch {
                        refreshing = true
                        CourseCatalog.refresh()
                        refreshing = false
                    }
                },
                modifier = Modifier.fillMaxSize(),
            ) {
                Column(
                    Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    AnimatedContent(activeTab, transitionSpec = { fadeIn() togetherWith fadeOut() }, label = "tab") { tab ->
                        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                            if (tab == MinigolfSegment.SPIEL) {
                                savedGame?.let { game ->
                                    ResumeCard(
                                        game,
                                        onResume = {
                                            Haptics.medium()
                                            MinigolfSession.pending = MinigolfSession.configFromSaved(game)
                                            nav.navigate(MinigolfRoutes.PLAY)
                                        },
                                        onDiscard = {
                                            Haptics.warning()
                                            MinigolfGameStore.clear()
                                            savedGame = null
                                        },
                                    )
                                }
                                CoursesCard(sortedMinigolfCourses(courses, here), here) { course ->
                                    Haptics.tap()
                                    nav.navigate(Routes.minigolfCourse(course.id))
                                }
                                HolesCard(numberOfHoles) { numberOfHoles = it }
                                PlayersCard(rawNames) { rawNames = it }
                                ChallengeSetupCard(selectedChallenges, { selectedChallenges = it }, initiallyExpanded = false)
                                MgPillButton(
                                    "Spiel starten", null, AppTheme.gold, Color.White,
                                    Modifier.fillMaxWidth().padding(top = 2.dp), radius = 14.dp, vertical = 16.dp,
                                    size = MgFont.headline, haptic = { Haptics.medium() }, onClick = ::startGame,
                                )
                                PuttTrainingCard(nav)
                                if (history.isNotEmpty()) {
                                    HistoryCard(
                                        history,
                                        onSelect = { Haptics.tap(); selectedHistory = it },
                                        onDelete = { e ->
                                            Haptics.warning()
                                            history = history.filter { it.id != e.id }
                                            MinigolfGameStore.saveHistory(history)
                                        },
                                        onClear = {
                                            Haptics.warning()
                                            MinigolfGameStore.saveHistory(emptyList())
                                            history = emptyList()
                                        },
                                    )
                                }
                            } else {
                                MinigolfLanesTabContent { lane -> nav.navigate(MinigolfRoutes.lane(lane.normNumber)) }
                            }
                        }
                    }
                }
            }
        }
    }

    selectedHistory?.let { e ->
        MinigolfResultsSheet(e.playerNames, e.numberOfHoles, e.scores, e.challengeList, onFinish = null) { selectedHistory = null }
    }
}

// MARK: - Segmentierte Auswahl

@Composable
private fun <T> SegmentedPicker(
    options: List<Triple<T, String, ImageVector>>,
    selected: T,
    onSelect: (T) -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier.fillMaxWidth().background(Color.White.copy(alpha = 0.10f), RoundedCornerShape(9.dp)).padding(2.dp),
    ) {
        options.forEach { (value, title, icon) ->
            val isOn = value == selected
            Row(
                Modifier.weight(1f)
                    .background(if (isOn) Color.White.copy(alpha = 0.22f) else Color.Transparent, RoundedCornerShape(7.dp))
                    .clickable { if (!isOn) onSelect(value) }
                    .padding(vertical = 6.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(icon, null, tint = AppTheme.text, modifier = Modifier.size(15.dp))
                Spacer(Modifier.width(5.dp))
                MgText(title, 14.sp,
                    weight = if (isOn) FontWeight.SemiBold else FontWeight.Medium, maxLines = 1)
            }
        }
    }
}

// MARK: - Karten

@Composable
private fun ResumeCard(game: SavedMinigolfGame, onResume: () -> Unit, onDiscard: () -> Unit) {
    Column(Modifier.mgCard(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        MgLabel("Angefangenes Spiel", Icons.Filled.History)
        MgText(
            "${game.playerNames.joinToString(", ")} · Loch ${game.currentHole + 1} von ${game.numberOfHoles}",
            MgFont.subheadline, AppTheme.textSec,
        )
        game.savedAt?.let {
            MgLabel(formatDateTime(referenceSecondsToMillis(it)), Icons.Filled.CalendarToday, MgFont.caption,
                FontWeight.Normal, iconTint = AppTheme.textSec, color = AppTheme.textSec)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            MgPillButton("Fortsetzen", Icons.Filled.PlayArrow, AppTheme.gold, Color.White, Modifier.weight(1f),
                haptic = {}, onClick = onResume)
            MgPillButton("Verwerfen", Icons.Filled.Delete, MgRed.copy(alpha = 0.1f), MgRed, Modifier.weight(1f),
                haptic = {}, onClick = onDiscard)
        }
    }
}

/** Minigolfanlagen mit QR-Code am Eingang. Der Tipp führt in denselben Ablauf wie der Scan. */
@Composable
private fun CoursesCard(courses: List<MinigolfCourseEntry>, here: app.golftrack.data.LatLon?, onSelect: (MinigolfCourseEntry) -> Unit) {
    Column(Modifier.mgCard(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        MgLabel("Minigolfplätze", Icons.Filled.Place)
        MgText("Vor Ort einfach den QR-Code scannen – Begrüßung, kurze Einführung, los.", MgFont.caption, AppTheme.textSec)
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            courses.forEach { course ->
                Row(
                    Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(10.dp))
                        .clickable { onSelect(course) }
                        .padding(horizontal = 12.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        MgText(course.name, MgFont.subheadline, weight = FontWeight.Bold)
                        MgText("${course.location} · ${course.holes} Bahnen", MgFont.caption, AppTheme.textSec, maxLines = 1)
                    }
                    if (here != null) MgText(formatKm(course.distance(here)), MgFont.caption, AppTheme.gold, FontWeight.Bold)
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textSec)
                }
            }
        }
    }
}

@Composable
private fun HolesCard(holes: Int, onChange: (Int) -> Unit) {
    Column(Modifier.mgCard(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        MgLabel("Löcher", Icons.Filled.Flag)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            listOf(6, 9, 12, 18).forEach { n ->
                val on = holes == n
                Box(
                    Modifier.weight(1f)
                        .background(if (on) AppTheme.gold else AppTheme.textSec.copy(alpha = 0.12f), RoundedCornerShape(10.dp))
                        .clickable { Haptics.selection(); onChange(n) }
                        .padding(vertical = 10.dp),
                    contentAlignment = Alignment.Center,
                ) { MgText("$n", MgFont.subheadline, if (on) Color.White else AppTheme.text, FontWeight.Bold) }
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            MgText("Benutzerdefiniert", MgFont.subheadline, AppTheme.textSec, modifier = Modifier.weight(1f))
            Row(Modifier.background(AppTheme.cardAlt, RoundedCornerShape(10.dp)), verticalAlignment = Alignment.CenterVertically) {
                StepperButton(Icons.Filled.Remove, holes > 1) { Haptics.light(); onChange(holes - 1) }
                MgText("$holes", MgFont.headline, weight = FontWeight.SemiBold,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center, modifier = Modifier.width(38.dp))
                StepperButton(Icons.Filled.Add, holes < 36) { Haptics.stroke(); onChange(holes + 1) }
            }
        }
    }
}

@Composable
private fun StepperButton(icon: ImageVector, enabled: Boolean, onClick: () -> Unit) {
    Box(Modifier.size(38.dp).clickable(enabled = enabled, onClick = onClick), contentAlignment = Alignment.Center) {
        Icon(icon, null, tint = if (enabled) AppTheme.text else AppTheme.textSec.copy(alpha = 0.4f), modifier = Modifier.size(18.dp))
    }
}

@Composable
private fun PlayersCard(names: List<String>, onNames: (List<String>) -> Unit) {
    Column(Modifier.mgCard().animateContentSize(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MgLabel("Spieler", Icons.Filled.People)
            Spacer(Modifier.weight(1f))
            CountBadge(names.size)
        }
        PlayersEditor(names, onNames)
        PlayerCountButtons(names.size, onAdd = { onNames(names + "") }, onRemove = { if (names.isNotEmpty()) onNames(names.dropLast(1)) })
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun HistoryCard(
    history: List<MinigolfHistoryEntry>,
    onSelect: (MinigolfHistoryEntry) -> Unit,
    onDelete: (MinigolfHistoryEntry) -> Unit,
    onClear: () -> Unit,
) {
    Column(Modifier.mgCard().animateContentSize(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MgLabel("Verlauf", Icons.Filled.EmojiEvents)
            Spacer(Modifier.weight(1f))
            MgText("Alle löschen", MgFont.caption, MgRed, FontWeight.Bold, Modifier.clickable(onClick = onClear).padding(4.dp))
        }
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            history.forEach { entry ->
                var menu by remember { mutableStateOf(false) }
                val totals = entry.scores.map { it.sum() }
                val winner = totals.indices.minByOrNull { totals[it] } ?: 0
                Box {
                    Row(
                        Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(10.dp))
                            .combinedClickable(onClick = { onSelect(entry) }, onLongClick = { Haptics.medium(); menu = true })
                            .padding(horizontal = 12.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            MgText("🥇 ${entry.playerNames.getOrElse(winner) { "" }} · ${totals.getOrElse(winner) { 0 }} Schläge",
                                MgFont.subheadline, weight = FontWeight.Bold)
                            MgText("${entry.playerNames.joinToString(", ")} · ${entry.numberOfHoles} Löcher",
                                MgFont.caption, AppTheme.textSec, maxLines = 1)
                            entry.courseName?.let {
                                MgLabel(it, Icons.Filled.Place, MgFont.caption2, FontWeight.Normal,
                                    iconTint = AppTheme.textSec, color = AppTheme.textSec)
                            }
                            MgText(formatDateTime(entry.dateMillis), MgFont.caption2, AppTheme.textSec)
                        }
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textSec)
                    }
                    DropdownMenu(menu, { menu = false }, containerColor = AppTheme.cardAlt) {
                        DropdownMenuItem(
                            text = { Text("Löschen", color = MgRed) },
                            leadingIcon = { Icon(Icons.Filled.Delete, null, tint = MgRed) },
                            onClick = { menu = false; onDelete(entry) },
                        )
                    }
                }
            }
        }
    }
}
