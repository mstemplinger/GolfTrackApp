package app.golftrack.feature.minigolf

import app.golftrack.feature.ads.AdPlacement
import app.golftrack.feature.ads.AdSlot

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.outlined.EmojiEvents
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

private val scoresSaver = Saver<List<List<Int>>, String>(
    save = { s -> s.joinToString(";") { it.joinToString(",") } },
    restore = { str -> if (str.isEmpty()) emptyList() else str.split(";").map { r -> if (r.isEmpty()) emptyList() else r.split(",").map(String::toInt) } },
)

private val challengesSaver = Saver<List<MinigolfChallenge>, String>(
    save = { l -> l.joinToString(",") { it.raw } },
    restore = { s -> s.split(",").mapNotNull { MinigolfChallenge.fromRaw(it) } },
)

/** Die Zählkarte – wie `MinigolfScoringView` (ohne Watch-Abgleich und Werbefläche). */
@Composable
internal fun MinigolfScoringScreen(nav: NavController, config: MinigolfConfig) {
    val playerCount = config.playerNames.size
    val holeCount = config.numberOfHoles

    var scores by rememberSaveable(stateSaver = scoresSaver) {
        mutableStateOf(
            config.initialScores?.takeIf { it.size == playerCount && it.all { r -> r.size == holeCount } }
                ?: List(playerCount) { List(holeCount) { 0 } },
        )
    }
    var currentHole by rememberSaveable { mutableStateOf(config.initialHole.coerceIn(0, maxOf(0, holeCount - 1))) }
    var challenges by rememberSaveable(stateSaver = challengesSaver) { mutableStateOf(config.challenges) }
    var showResults by rememberSaveable { mutableStateOf(false) }
    var showChallenges by rememberSaveable { mutableStateOf(false) }
    var finished by remember { mutableStateOf(false) }

    fun total(p: Int) = scores[p].sum()
    val sortedPlayers = (0 until playerCount).sortedBy { total(it) }

    fun setScore(p: Int, v: Int) {
        scores = scores.mapIndexed { i, row -> if (i == p) row.mapIndexed { h, s -> if (h == currentHole) v else s } else row }
    }

    // Stand bei jeder Änderung sichern – wie onChange(of:) auf iOS.
    LaunchedEffect(scores, currentHole, challenges) {
        if (finished) return@LaunchedEffect
        MinigolfGameStore.save(
            SavedMinigolfGame(
                playerNames = config.playerNames, numberOfHoles = holeCount, scores = scores,
                currentHole = currentHole, savedAt = nowReferenceSeconds(),
                courseName = config.courseName, courseID = config.courseID,
                challenges = challenges.map { it.raw },
            ),
        )
    }
    LaunchedEffect(challenges) { MinigolfGameStore.saveChallenges(challenges) }

    fun finishGame() {
        finished = true
        MinigolfGameStore.appendToHistory(
            MinigolfHistoryEntry(
                date = nowReferenceSeconds(), playerNames = config.playerNames, numberOfHoles = holeCount,
                scores = scores, courseName = config.courseName, challenges = challenges.map { it.raw },
            ),
        )
        MinigolfGameStore.clear()
        MinigolfSession.pending = null
        showResults = false
        nav.popBackStack()
    }

    AppScaffold(
        title = "Loch ${currentHole + 1} / $holeCount",
        onBack = { nav.popBackStack() },
        actions = {
            MgText("Ergebnis", MgFont.body, AppTheme.gold, FontWeight.SemiBold,
                Modifier.clickable { Haptics.tap(); showResults = true }.padding(8.dp))
            IconButton(onClick = { Haptics.tap(); showChallenges = true }) {
                Icon(if (challenges.isEmpty()) Icons.Outlined.EmojiEvents else Icons.Filled.EmojiEvents, "Wettkämpfe", tint = AppTheme.gold)
            }
        },
    ) { m ->
        Column(m) {
            val progress by animateFloatAsState((currentHole + 1f) / holeCount.coerceAtLeast(1), label = "progress")
            Box(Modifier.fillMaxWidth().height(3.dp).background(AppTheme.textSec.copy(alpha = 0.15f))) {
                Box(Modifier.fillMaxWidth(progress).fillMaxHeight().background(AppTheme.gold))
            }
            Column(
                Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                for (i in 0 until playerCount) {
                    PlayerScoreCard(
                        name = config.playerNames[i], total = total(i), rank = sortedPlayers.indexOf(i),
                        strokes = scores[i][currentHole],
                        onMinus = {
                            if (scores[i][currentHole] > 0) { Haptics.light(); setScore(i, scores[i][currentHole] - 1) }
                        },
                        onPlus = {
                            if (scores[i][currentHole] < 20) { Haptics.stroke(); setScore(i, scores[i][currentHole] + 1) }
                        },
                    )
                }
                if (challenges.isEmpty()) AddChallengesButton { showChallenges = true }
                else ChallengeLiveCard(config.playerNames, scores, challenges) { showChallenges = true }

                // Hinweise der Anlage stehen immer – sie sind keine Werbung.
                CourseHintRotatingCard(config.hints, currentHole)
                AdSlot(AdPlacement.MINIGOLF_SCORING, courseId = config.courseID, rotation = currentHole, nav = nav)
                PuttTrainingCard(nav, compact = true)
            }
            BottomNav(
                currentHole = currentHole, holeCount = holeCount,
                onBack = { Haptics.selection(); currentHole -= 1 },
                onNext = {
                    // Ein Ass auf dieser Bahn wird gefeiert, sonst reicht ein Klopfer.
                    if (scores.any { it[currentHole] == 1 }) Haptics.celebrate() else Haptics.holeFinished()
                    currentHole += 1
                },
                onResult = { Haptics.celebrate(); showResults = true },
            )
        }
    }

    if (showResults) {
        MinigolfResultsSheet(
            playerNames = config.playerNames, numberOfHoles = holeCount, scores = scores,
            challenges = challenges, onFinish = ::finishGame, onDismiss = { showResults = false },
        )
    }
    if (showChallenges) {
        ChallengeSheet(challenges, { challenges = it }, onDismiss = { showChallenges = false })
    }
}

@Composable
private fun PlayerScoreCard(name: String, total: Int, rank: Int, strokes: Int, onMinus: () -> Unit, onPlus: () -> Unit) {
    Row(Modifier.mgCard(14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(Modifier.size(26.dp).background(rankColor(rank), CircleShape), contentAlignment = Alignment.Center) {
            MgText("${rank + 1}", MgFont.caption, Color.White, FontWeight.Bold)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            MgText(name, MgFont.headline, weight = FontWeight.SemiBold, maxLines = 1)
            MgText("Gesamt: $total", MgFont.caption, AppTheme.textSec)
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Icon(
                Icons.Filled.RemoveCircle, "Minus",
                tint = if (strokes > 0) AppTheme.gold else AppTheme.textSec.copy(alpha = 0.35f),
                modifier = Modifier.size(34.dp).clickable(onClick = onMinus),
            )
            MgText("$strokes", MgFont.title, weight = FontWeight.Bold, textAlign = TextAlign.Center, modifier = Modifier.width(40.dp))
            Icon(Icons.Filled.AddCircle, "Plus", tint = AppTheme.gold, modifier = Modifier.size(34.dp).clickable(onClick = onPlus))
        }
    }
}

private fun rankColor(rank: Int): Color = when (rank) {
    0 -> MgMedalGold
    1 -> Color.Gray
    2 -> MgBronze
    else -> AppTheme.textSec
}

/** Hinweis, solange keine Nebenwertung läuft. */
@Composable
private fun AddChallengesButton(onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))
            .clickable { Haptics.tap(); onClick() }.padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(Icons.Filled.EmojiEvents, null, tint = AppTheme.gold)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            MgText("Wettkampf dazunehmen", MgFont.subheadline, weight = FontWeight.Bold)
            MgText("Serie, Asse, Bahnenduell – zählt rückwirkend ab Bahn 1.", MgFont.caption, AppTheme.textSec)
        }
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textSec)
    }
}

@Composable
private fun BottomNav(currentHole: Int, holeCount: Int, onBack: () -> Unit, onNext: () -> Unit, onResult: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.bg).navigationBarsPadding().padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        val canBack = currentHole > 0
        Row(
            Modifier.weight(1f).alpha(if (canBack) 1f else 0.3f)
                .background(AppTheme.card, RoundedCornerShape(12.dp))
                .clickable(enabled = canBack, onClick = onBack)
                .padding(vertical = 14.dp),
            horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, null, tint = AppTheme.gold, modifier = Modifier.size(20.dp))
            MgText("Zurück", MgFont.subheadline, weight = FontWeight.Bold)
        }
        val last = currentHole >= holeCount - 1
        Row(
            Modifier.weight(1f).background(AppTheme.gold, RoundedCornerShape(12.dp))
                .clickable(onClick = if (last) onResult else onNext)
                .padding(vertical = 14.dp),
            horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
        ) {
            MgText(if (last) "Ergebnis" else "Weiter", MgFont.subheadline, Color.White, FontWeight.Bold)
            if (!last) Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Color.White, modifier = Modifier.size(20.dp))
        }
    }
}

// MARK: - Sheets

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ChallengeSheet(selection: List<MinigolfChallenge>, onChange: (List<MinigolfChallenge>) -> Unit, onDismiss: () -> Unit) {
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = state, containerColor = AppTheme.bg) {
        SheetHeader("Wettkämpfe", onTrailing = onDismiss)
        Column(
            Modifier.verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            MgText(
                "Wettkämpfe zählen immer über die ganze Runde – auch wenn du sie erst jetzt einschaltest.",
                MgFont.caption, AppTheme.textSec,
            )
            ChallengeSelectionList(selection, onChange)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun MinigolfResultsSheet(
    playerNames: List<String>,
    numberOfHoles: Int,
    scores: List<List<Int>>,
    challenges: List<MinigolfChallenge>,
    onFinish: (() -> Unit)?,
    onDismiss: () -> Unit,
) {
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = state, containerColor = AppTheme.bg) {
        SheetHeader("Ergebnis", onTrailing = onDismiss)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            MinigolfResultsContent(playerNames, numberOfHoles, scores, challenges)
            if (onFinish != null) {
                MgPillButton(
                    "Spiel beenden & speichern", Icons.Filled.CheckCircle, AppTheme.gold, Color.White,
                    Modifier.fillMaxWidth(), radius = 14.dp, vertical = 16.dp, size = MgFont.headline,
                    haptic = { Haptics.celebrate() }, onClick = onFinish,
                )
            }
        }
    }
}

@Composable
internal fun MinigolfResultsContent(
    playerNames: List<String>,
    numberOfHoles: Int,
    scores: List<List<Int>>,
    challenges: List<MinigolfChallenge>,
) {
    data class Entry(val index: Int, val name: String, val total: Int)
    val ranked = playerNames.indices.map { Entry(it, playerNames[it], scores.getOrNull(it)?.sum() ?: 0) }.sortedBy { it.total }

    // Rangliste
    Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))) {
        ranked.forEachIndexed { place, e ->
            Row(
                Modifier.padding(horizontal = 12.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                MgText(
                    when (place) { 0 -> "🥇"; 1 -> "🥈"; 2 -> "🥉"; else -> "${place + 1}." },
                    if (place < 3) MgFont.title2 else MgFont.body,
                    textAlign = TextAlign.Center, modifier = Modifier.width(36.dp),
                )
                MgText(e.name, MgFont.headline, weight = FontWeight.SemiBold, maxLines = 1, modifier = Modifier.weight(1f))
                MgText("${e.total}", MgFont.headline, if (place == 0) MgMedalGold else AppTheme.text, FontWeight.Bold)
                MgText("Schl.", MgFont.caption, AppTheme.textSec)
            }
            if (place < ranked.size - 1) HorizontalDivider(Modifier.padding(start = 60.dp), color = AppTheme.text.copy(alpha = 0.12f))
        }
    }

    if (challenges.isNotEmpty()) AwardsCard(playerNames, scores, challenges)

    // Scorecard
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        MgText("Scorecard", MgFont.headline, weight = FontWeight.SemiBold)
        Box(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))) {
            Column(Modifier.horizontalScroll(rememberScrollState()).padding(12.dp)) {
                Row(Modifier.height(26.dp), verticalAlignment = Alignment.CenterVertically) {
                    MgText("Spieler", MgFont.caption, weight = FontWeight.Bold, modifier = Modifier.width(80.dp))
                    for (h in 0 until numberOfHoles) {
                        MgText("${h + 1}", MgFont.caption, AppTheme.textSec, textAlign = TextAlign.Center, modifier = Modifier.width(28.dp))
                    }
                    MgText("∑", MgFont.caption, weight = FontWeight.Bold, textAlign = TextAlign.End, modifier = Modifier.width(36.dp))
                }
                HorizontalDivider(Modifier.width((80 + 28 * numberOfHoles + 36).dp), color = AppTheme.text.copy(alpha = 0.12f))
                ranked.forEach { e ->
                    Row(Modifier.height(28.dp), verticalAlignment = Alignment.CenterVertically) {
                        MgText(e.name, MgFont.caption, maxLines = 1, modifier = Modifier.width(80.dp))
                        for (h in 0 until numberOfHoles) {
                            val s = scores.getOrNull(e.index)?.getOrNull(h) ?: 0
                            MgText(
                                if (s == 0) "–" else "$s", MgFont.caption,
                                when (s) { 1 -> AppTheme.gold; 0 -> AppTheme.textSec; else -> AppTheme.text },
                                textAlign = TextAlign.Center, modifier = Modifier.width(28.dp),
                            )
                        }
                        MgText("${e.total}", MgFont.caption, weight = FontWeight.Bold, textAlign = TextAlign.End, modifier = Modifier.width(36.dp))
                    }
                }
            }
        }
    }
    Spacer(Modifier.height(4.dp))
}
