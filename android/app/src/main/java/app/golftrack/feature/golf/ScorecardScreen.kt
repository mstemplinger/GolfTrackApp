package app.golftrack.feature.golf

import android.Manifest
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
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
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.filled.Autorenew
import androidx.compose.material.icons.filled.ConfirmationNumber
import androidx.compose.material.icons.filled.DragHandle
import androidx.compose.material.icons.filled.ExpandCircleDown
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.SupervisedUserCircle
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.GameMode
import app.golftrack.data.GameScoringEngine
import app.golftrack.data.GolfStore
import app.golftrack.data.HoleOutcome
import app.golftrack.data.Prefs
import app.golftrack.data.Round
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Placeholder
import app.golftrack.ui.common.Routes
import app.golftrack.ui.common.rememberLocation
import app.golftrack.ui.theme.AppTheme

/** Wie ScorecardView.swift: Loch für Loch zählen, Spielstand, Mini-Scorecard. */
@Composable
fun ScorecardScreen(nav: NavController, roundId: String) {
    val ctx = LocalContext.current
    val data by GolfStore.data.collectAsState()
    val round = data.round(roundId)
    if (round == null) {
        Placeholder("Runde nicht gefunden")
        return
    }
    val course = data.course(round.courseId)
    val sorted = round.sortedScores
    var currentIndex by rememberSaveable { mutableIntStateOf(0) }
    if (currentIndex > sorted.lastIndex) currentIndex = maxOf(0, sorted.lastIndex)
    val here = rememberLocation(highAccuracy = true)
    val isTracking by RoundTracker.isTracking.collectAsState()
    val pointCount by RoundTracker.pointCount.collectAsState()

    var showFinish by remember { mutableStateOf(false) }
    var showCancel by remember { mutableStateOf(false) }
    var showBackfill by remember { mutableStateOf(false) }
    var showComplete by rememberSaveable { mutableStateOf(false) }
    var showShake by remember { mutableStateOf(false) }
    var showCourseInfo by remember { mutableStateOf(false) }

    fun par(hole: Int) = course?.par(hole) ?: 4

    // Laufspur – nur wenn in den Einstellungen erlaubt; endet beim Verlassen.
    DisposableEffect(roundId) {
        if (!round.isComplete) RoundTracker.start(ctx, roundId, currentIndex + 1)
        onDispose {
            RoundTracker.stop()
            RoundReminders.cancelRoundInactivity(ctx)
        }
    }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle) {
        val obs = LifecycleEventObserver { _, e -> if (e == Lifecycle.Event.ON_STOP) RoundTracker.flush() }
        lifecycle.addObserver(obs)
        onDispose { lifecycle.removeObserver(obs) }
    }
    // Berechtigung kam erst nach dem Öffnen (wie `pendingStart` auf iOS) → jetzt starten.
    LaunchedEffect(here != null) {
        if (here != null && !round.isComplete && !RoundTracker.isTracking.value) RoundTracker.start(ctx, roundId, currentIndex + 1)
    }
    LaunchedEffect(currentIndex) { RoundTracker.setCurrentHole(currentIndex + 1) }
    LaunchedEffect(currentIndex, round.totalStrokes) {
        if (!round.isComplete) RoundReminders.rescheduleRoundInactivity(ctx)
    }

    // Einmalig um Erlaubnis für Erinnerungen bitten (Android 13+).
    val notifLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {}
    LaunchedEffect(Unit) {
        if (Build.VERSION.SDK_INT >= 33 && !RoundReminders.canPost(ctx) && !Prefs.bool("notif.android.asked")) {
            Prefs.set("notif.android.asked", true)
            notifLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    ShakeEffect { if (!showShake) showShake = true }

    fun goPrevious() {
        if (currentIndex <= 0) return
        Haptics.selection(); currentIndex--
    }

    fun goNext() {
        if (currentIndex >= sorted.lastIndex) return
        val s = sorted.getOrNull(currentIndex)
        if (s != null && s.strokes > 0) hapticScore(s.strokes - par(s.holeNumber)) else Haptics.selection()
        currentIndex++
    }

    Column(Modifier.fillMaxSize().background(AppTheme.bg)) {
        SheetTopBar(
            title = "",
            leading = { BarButton("Abbrechen", color = AppTheme.textSec) { Haptics.tap(); showCancel = true } },
            trailing = {
                if (course != null && (course.hcpValues.isNotEmpty() || course.facilityNotes.isNotEmpty())) {
                    BarIconButton(Icons.Filled.Info, tint = AppTheme.textSec, description = "Platzinfo") { Haptics.tap(); showCourseInfo = true }
                }
                BarButton("Abschließen", bold = true) { Haptics.tap(); showFinish = true }
            },
            center = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(round.gameMode.icon, null, tint = AppTheme.gold, modifier = Modifier.size(13.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(round.gameMode.displayName, color = AppTheme.textSec, fontSize = 12.sp, maxLines = 1)
                }
            },
        )
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            sorted.getOrNull(currentIndex)?.let { score ->
                HoleScoring(
                    nav = nav, round = round, course = course, score = score, par = par(score.holeNumber),
                    holeCount = sorted.size, here = here,
                    onPrevious = ::goPrevious, onNext = ::goNext,
                )
            }
            if (round.gameMode.isMultiplayer) GameStatusBanner(round, course)
            if (isTracking) {
                Row(
                    Modifier.padding(horizontal = 16.dp).padding(top = 4.dp).fillMaxWidth()
                        .background(AppTheme.cardDark, RoundedCornerShape(10.dp)).padding(horizontal = 12.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.AutoMirrored.Filled.DirectionsWalk, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Laufspur wird aufgezeichnet · $pointCount Punkte", color = AppTheme.textSec, fontSize = 11.sp)
                }
            }
            MiniScorecard(round, course, currentIndex, Modifier.padding(top = 8.dp, bottom = 8.dp))
            Spacer(Modifier.navigationBarsPadding())
        }
    }

    // --- Dialoge ---

    fun presentCompletion() { showComplete = true }

    if (showFinish) {
        AlertDialog(
            onDismissRequest = { showFinish = false },
            title = { Text("Runde abschließen?") },
            text = { Text("Die Runde wird als abgeschlossen gespeichert.") },
            confirmButton = {
                TextButton(onClick = {
                    showFinish = false
                    Haptics.celebrate()
                    RoundTracker.stop()
                    GolfStore.updateRound(roundId) { it.copy(isComplete = true) }
                    // Inaktivitätserinnerung: 5 Tage nach der abgeschlossenen Runde
                    RoundReminders.scheduleInactivity(ctx, 5)
                    RoundReminders.cancelOpenRound(ctx)
                    RoundReminders.cancelRoundInactivity(ctx)
                    // Zu kurze Aufzeichnung: erst klären, ob nachgetragen wurde.
                    val r = GolfStore.current.round(roundId)
                    if (r?.track?.looksBackfilled(r.playedScores.size) == true) showBackfill = true else presentCompletion()
                }) { Text("Abschließen", color = AppTheme.gold, fontWeight = FontWeight.Bold) }
            },
            dismissButton = { TextButton(onClick = { Haptics.tap(); showFinish = false }) { Text("Weiter spielen", color = AppTheme.textSec) } },
            containerColor = AppTheme.card,
        )
    }
    if (showBackfill) {
        val r = GolfStore.current.round(roundId)
        val minutes = Math.round((r?.track?.durationSeconds ?: 0.0) / 60).toInt()
        AlertDialog(
            onDismissRequest = {},
            title = { Text("Runde nachgetragen?") },
            text = {
                Text("Für ${r?.playedScores?.size ?: 0} Löcher wurden nur $minutes Minuten aufgezeichnet – das ist für eine gespielte Runde zu kurz. Wenn du die Runde nachgetragen hast, zeigt die Laufspur nicht den Platz, sondern wo du beim Eintragen warst. Solche Spuren verfälschen die Abschlag-, Grün- und Fairway-Erkennung.")
            },
            confirmButton = {
                TextButton(onClick = {
                    Haptics.warning()
                    GolfStore.updateRound(roundId) { it.copy(track = null) }
                    showBackfill = false
                    presentCompletion()
                }) { Text("Nachgetragen – Spur löschen", color = IosColors.red) }
            },
            dismissButton = {
                TextButton(onClick = { Haptics.tap(); showBackfill = false; presentCompletion() }) {
                    Text("Ich habe gespielt – behalten", color = AppTheme.gold, fontWeight = FontWeight.Bold)
                }
            },
            containerColor = AppTheme.card,
        )
    }
    if (showCancel) {
        AlertDialog(
            onDismissRequest = { showCancel = false },
            title = { Text("Runde verlassen?") },
            text = { Text("Dein Fortschritt wird gespeichert. Du kannst die Runde auf der Startseite fortsetzen oder dort löschen.") },
            confirmButton = {
                TextButton(onClick = { Haptics.warning(); showCancel = false; nav.popBackStack() }) { Text("Verlassen", color = IosColors.red) }
            },
            dismissButton = { TextButton(onClick = { Haptics.tap(); showCancel = false }) { Text("Weiter spielen", color = AppTheme.gold, fontWeight = FontWeight.Bold) } },
            containerColor = AppTheme.card,
        )
    }
    if (showShake) {
        AlertDialog(
            onDismissRequest = { showShake = false },
            title = { Text("Spielregeln anzeigen?") },
            text = { Text("Möchtest du die wichtigsten Golfregeln nachschlagen?") },
            confirmButton = {
                TextButton(onClick = { Haptics.tap(); showShake = false; nav.navigate(Routes.RULES) }) { Text("Anzeigen", color = AppTheme.gold, fontWeight = FontWeight.Bold) }
            },
            dismissButton = { TextButton(onClick = { Haptics.tap(); showShake = false }) { Text("Abbrechen", color = AppTheme.textSec) } },
            containerColor = AppTheme.card,
        )
    }
    if (showCourseInfo && course != null) {
        CourseInfoSheet(course) { showCourseInfo = false }
    }
    if (showComplete) {
        RoundCompleteSheet(
            nav = nav, round = round, course = course,
            onDone = {
                showComplete = false
                nav.popBackStack()
            },
            onShowDetail = {
                showComplete = false
                nav.navigate(Routes.roundDetail(roundId)) { popUpTo(Routes.PLAY_ROUND) { inclusive = true } }
            },
        )
    }
}

// MARK: - Spielstand-Banner

@Composable
private fun BannerRow(content: @Composable () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.cardDark).padding(vertical = 7.dp, horizontal = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) { content() }
}

@Composable
private fun BIcon(icon: ImageVector, color: Color, rotation: Float = 0f) =
    Icon(icon, null, tint = color, modifier = Modifier.size(16.dp).rotate(rotation))

@Composable
private fun BText(text: String, color: Color = AppTheme.textSec, bold: Boolean = false, size: Int = 12) =
    Text(text, color = color, fontSize = size.sp, fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal)

private fun diffColor(diff: Int) = if (diff < 0) AppTheme.gold else if (diff > 0) IosColors.orange else AppTheme.text

private fun playedPar(round: Round, course: Course?, exclude: Set<Int> = emptySet()): Int =
    round.sortedScores.filter { it.strokes > 0 && it.holeNumber !in exclude }
        .sumOf { course?.parValues?.getOrNull(it.holeNumber - 1) ?: 0 }

@Composable
private fun GameStatusBanner(round: Round, course: Course?) {
    when (round.gameMode) {
        GameMode.MATCHPLAY -> MatchBanner(GameScoringEngine.matchplayStatus(round))
        GameMode.BETTER_BALL_MATCHPLAY -> MatchBanner(GameScoringEngine.betterBallMatchplayStatus(round))
        GameMode.SKINS -> {
            val summary = GameScoringEngine.skinsResult(round)
            val mine = summary.skinsPerPlayer[0] ?: 0
            val names = round.otherPlayerNames
            val totals = (1..maxOf(1, names.size)).map { summary.skinsPerPlayer[it] ?: 0 }
            BannerRow {
                BIcon(Icons.Filled.Verified, IosColors.orange)
                BText("Skins: Du $mine", if (mine >= (totals.maxOrNull() ?: 0)) AppTheme.gold else AppTheme.text, bold = true)
                if (names.isNotEmpty()) {
                    BText("–")
                    names.forEachIndexed { i, n -> BText("${n.ifEmpty { "Sp.${i + 2}" }} ${totals.getOrElse(i) { 0 }}", AppTheme.text, bold = true) }
                }
                if (summary.openSkins > 0) BText("(${summary.openSkins} offen)")
            }
        }
        GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD -> {
            val stableford = round.gameMode == GameMode.BETTER_BALL_STABLEFORD
            val total = GameScoringEngine.betterBallTeamTotal(round, course, stableford)
            BannerRow {
                BIcon(Icons.Filled.LocalFireDepartment, IosColors.orange)
                BText("Team ${round.otherPlayerNames.firstOrNull() ?: "Partner"}")
                if (stableford) BText("$total Punkte", AppTheme.gold, bold = true)
                else { val d = total - playedPar(round, course); BText(diffLabel(d), diffColor(d), bold = true) }
            }
        }
        GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD -> {
            val stableford = round.gameMode == GameMode.BEST_BALL_STABLEFORD
            val total = GameScoringEngine.bestBallTeamTotal(round, course, stableford)
            BannerRow {
                BIcon(Icons.Filled.Whatshot, IosColors.orange)
                BText("Best Ball – ${1 + round.otherPlayerNames.size} Spieler")
                if (stableford) BText("$total Punkte", AppTheme.gold, bold = true)
                else { val d = total - playedPar(round, course); BText(diffLabel(d), diffColor(d), bold = true) }
            }
        }
        GameMode.SCRAMBLE_2_MANN, GameMode.SCRAMBLE_TEAM, GameMode.VIERER, GameMode.GREENSOME -> {
            val (icon, label) = when (round.gameMode) {
                GameMode.SCRAMBLE_TEAM -> Icons.Filled.Groups to "Team Scramble"
                GameMode.VIERER -> Icons.Filled.Autorenew to "Vierer"
                GameMode.GREENSOME -> Icons.Filled.SupervisedUserCircle to "Greensome"
                else -> Icons.Filled.Group to "2-Mann Scramble"
            }
            val partners = round.otherPlayerNames.filter { it.isNotEmpty() }.joinToString(", ")
            val d = round.totalStrokes - playedPar(round, course)
            BannerRow {
                BIcon(icon, AppTheme.gold)
                BText(label + if (partners.isEmpty()) "" else " – $partners")
                if (round.totalStrokes > 0) BText(diffLabel(d), diffColor(d), bold = true)
            }
        }
        GameMode.ERADO -> EradoBanner(round, course)
        else -> {}
    }
}

@Composable
private fun MatchBanner(status: app.golftrack.data.MatchplayStatus) {
    val (rot, color) = when {
        status.holesUp > 0 -> 180f to AppTheme.gold
        status.holesUp < 0 -> 0f to IosColors.red
        else -> 0f to AppTheme.textSec
    }
    BannerRow {
        if (status.holesUp == 0) BIcon(Icons.Filled.DragHandle, color) else BIcon(Icons.Filled.ExpandCircleDown, color, rot)
        BText(status.statusLabel, color, bold = true)
        if (status.isFinished) BText("• Runde beendet")
    }
}

@Composable
private fun EradoBanner(round: Round, course: Course?) {
    val result = GameScoringEngine.eradoResult(round, course)
    val d = result.total - playedPar(round, course, result.scratchedHoles)
    BannerRow {
        BIcon(Icons.Filled.ConfirmationNumber, IosColors.purple)
        BText("Erado")
        if (result.total > 0) BText("${result.total} (${diffLabel(d)})", diffColor(d), bold = true)
        if (result.scratchedHoles.isNotEmpty()) {
            BText("Streich: " + result.scratchedHoles.sorted().joinToString(", ") { "L$it" }, size = 11)
        }
    }
}

// MARK: - Mini-Scorecard

private const val LABEL_W = 50
private const val CELL_W = 34
private const val TOTAL_W = 40

private data class Cell(
    val text: String,
    val color: Color,
    val circle: Color? = null,
    val rect: Color? = null,
    val bold: Boolean = true,
    val size: Int = 12,
    val strike: Boolean = false,
)

@Composable
private fun CardRow(label: String, labelColor: Color, labelBold: Boolean, cells: List<Cell>, total: String, totalColor: Color = AppTheme.text, highlight: Int? = null) {
    Row(Modifier.height(26.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, color = labelColor, fontSize = 12.sp, fontWeight = if (labelBold) FontWeight.Bold else FontWeight.Normal,
            maxLines = 1, modifier = Modifier.width(LABEL_W.dp))
        cells.forEachIndexed { i, c ->
            Box(
                Modifier.width(CELL_W.dp).height(22.dp)
                    .background(if (highlight == i) AppTheme.gold.copy(alpha = 0.12f) else Color.Transparent, RoundedCornerShape(4.dp)),
                contentAlignment = Alignment.Center,
            ) {
                c.circle?.let { Box(Modifier.size(22.dp).background(it, CircleShape)) }
                c.rect?.let { Box(Modifier.width(28.dp).height(20.dp).background(it, RoundedCornerShape(4.dp))) }
                Text(
                    c.text, color = c.color, fontSize = c.size.sp,
                    fontWeight = if (c.bold) FontWeight.Bold else FontWeight.Normal, textAlign = TextAlign.Center,
                    textDecoration = if (c.strike) TextDecoration.LineThrough else null, maxLines = 1,
                )
            }
        }
        Text(total, color = totalColor, fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.End, modifier = Modifier.width(TOTAL_W.dp))
    }
}

private fun scoreBg(diff: Int, has: Boolean): Color? =
    if (!has) null else if (diff < 0) AppTheme.gold.copy(alpha = 0.3f) else if (diff > 0) IosColors.orange.copy(alpha = 0.25f) else null

private fun scoreFg(diff: Int) = diffColor(diff)

private fun strokeCell(strokes: Int, par: Int): Cell {
    val d = strokes - par
    return if (strokes > 0) Cell("$strokes", scoreFg(d), circle = scoreBg(d, true), size = 10) else Cell("·", AppTheme.textSec, size = 10)
}

private fun pointsCell(strokes: Int, par: Int, bold: Boolean = true): Cell {
    val pts = if (strokes > 0) GameMode.stablefordPoints(strokes, par) else 0
    val c = if (pts >= 3) AppTheme.gold else if (pts == 0) AppTheme.textSec else AppTheme.text
    return Cell(if (strokes > 0) "$pts" else "·", c, bold = bold)
}

private fun outcomeCell(o: HoleOutcome): Cell = when (o) {
    HoleOutcome.PLAYER -> Cell("W", AppTheme.gold)
    HoleOutcome.OPPONENT -> Cell("L", IosColors.red)
    HoleOutcome.HALVED -> Cell("H", AppTheme.textSec)
    HoleOutcome.NOT_PLAYED -> Cell("·", AppTheme.textSec)
}

@Composable
private fun MiniScorecard(round: Round, course: Course?, currentIndex: Int, modifier: Modifier = Modifier) {
    val scroll = rememberScrollState()
    val density = LocalDensity.current
    val sorted = round.sortedScores
    fun par(h: Int) = course?.par(h) ?: 4
    LaunchedEffect(currentIndex) {
        val cell = with(density) { CELL_W.dp.toPx() }
        val label = with(density) { (LABEL_W + 16).dp.toPx() }
        val target = (label + cell * currentIndex + cell / 2 - scroll.viewportSize / 2f).toInt()
        scroll.animateScrollTo(target.coerceIn(0, scroll.maxValue))
    }

    Box(modifier.fillMaxWidth().background(AppTheme.cardDark).padding(vertical = 8.dp)) {
        Column(Modifier.horizontalScroll(scroll).padding(horizontal = 16.dp)) {
            CardRow("Loch", AppTheme.text, true, sorted.mapIndexed { i, s ->
                Cell("${s.holeNumber}", if (i == currentIndex) AppTheme.gold else AppTheme.text)
            }, "∑", highlight = currentIndex)
            CardRow("Par", AppTheme.textSec, false, sorted.mapIndexed { i, s ->
                Cell("${par(s.holeNumber)}", if (i == currentIndex) AppTheme.gold else AppTheme.textSec, bold = false)
            }, "${course?.totalPar ?: 0}")

            val names = round.otherPlayerNames
            fun short(i: Int, fallback: String) = names.getOrNull(i)?.takeIf { it.isNotEmpty() }?.take(6) ?: fallback

            @Composable
            fun scoreRow() = CardRow("Score", AppTheme.textSec, false, sorted.map { strokeCell(it.strokes, par(it.holeNumber)) },
                if (round.totalStrokes > 0) "${round.totalStrokes}" else "-")

            @Composable
            fun stablefordRow() = CardRow("Punkte", AppTheme.textSec, false, sorted.map { pointsCell(it.strokes, par(it.holeNumber)) },
                "${round.totalStablefordPoints(course)}", AppTheme.gold)

            @Composable
            fun opponentRow(index: Int, label: String, stableford: Boolean = false) = CardRow(label, AppTheme.textSec, false, sorted.map {
                val st = round.opponentScore(index, it.holeNumber)?.strokes ?: 0
                if (stableford) pointsCell(st, par(it.holeNumber), bold = false) else strokeCell(st, par(it.holeNumber))
            }, "-")

            when (round.gameMode) {
                GameMode.MATCHPLAY -> {
                    scoreRow()
                    opponentRow(1, short(0, "Gegner"))
                    CardRow("Ergebnis", AppTheme.textSec, false, sorted.map {
                        outcomeCell(GameScoringEngine.matchplayHoleOutcome(it.strokes, round.opponentScore(1, it.holeNumber)?.strokes ?: 0))
                    }, "")
                }
                GameMode.STABLEFORD -> stablefordRow()
                GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD -> {
                    val sf = round.gameMode == GameMode.BETTER_BALL_STABLEFORD
                    if (sf) stablefordRow() else scoreRow()
                    opponentRow(1, short(0, "Partner"), sf)
                    CardRow("Team", AppTheme.text, true, sorted.map { hs ->
                        val partner = round.opponentScore(1, hs.holeNumber)
                        val p = par(hs.holeNumber)
                        val v = GameScoringEngine.betterBallHoleValue(hs, partner, p, sf)
                        val played = hs.strokes > 0 || (partner?.strokes ?: 0) > 0
                        when {
                            !played -> Cell("·", AppTheme.textSec)
                            sf -> Cell("$v", if (v >= 3) AppTheme.gold else if (v == 0) AppTheme.textSec else AppTheme.text)
                            else -> Cell("$v", scoreFg(v - p))
                        }
                    }, "${GameScoringEngine.betterBallTeamTotal(round, course, sf)}", AppTheme.gold)
                }
                GameMode.BETTER_BALL_MATCHPLAY -> {
                    scoreRow()
                    opponentRow(1, short(0, "Partner"))
                    if (names.size >= 2) opponentRow(2, short(1, "Gegner 1"))
                    if (names.size >= 3) opponentRow(3, short(2, "Gegner 2"))
                    CardRow("Ergebnis", AppTheme.textSec, false, sorted.map { hs ->
                        val h = hs.holeNumber
                        val partner = round.opponentScore(1, h)?.strokes ?: 0
                        val o1 = round.opponentScore(2, h)?.strokes ?: 0
                        val o2 = round.opponentScore(3, h)?.strokes ?: 0
                        val myBest = if (partner > 0) minOf(hs.strokes, partner) else hs.strokes
                        val oppBest = if (o1 <= 0) 0 else if (o2 > 0) minOf(o1, o2) else o1
                        outcomeCell(if (oppBest > 0 && myBest > 0) GameScoringEngine.matchplayHoleOutcome(myBest, oppBest) else HoleOutcome.NOT_PLAYED)
                    }, "")
                }
                GameMode.SKINS -> {
                    scoreRow()
                    val summary = GameScoringEngine.skinsResult(round)
                    CardRow("Skins", AppTheme.textSec, false, sorted.map { hs ->
                        when (val w = summary.holeWinners[hs.holeNumber]) {
                            null -> Cell("·", AppTheme.textSec, size = 9)
                            -1 -> Cell("=", AppTheme.textSec, size = 9)
                            0 -> Cell("Du", AppTheme.gold, size = 9)
                            else -> Cell(names.getOrNull(w - 1)?.takeIf { it.isNotEmpty() }?.take(2) ?: "G$w", IosColors.orange, size = 9)
                        }
                    }, "${summary.skinsPerPlayer[0] ?: 0}", AppTheme.gold)
                }
                GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD -> {
                    val sf = round.gameMode == GameMode.BEST_BALL_STABLEFORD
                    if (sf) stablefordRow() else scoreRow()
                    names.forEachIndexed { i, n -> opponentRow(i + 1, n.ifEmpty { "Sp.${i + 2}" }.take(6), sf) }
                    CardRow("Best", AppTheme.text, true, sorted.map { hs ->
                        val pv = course?.parValues?.getOrNull(hs.holeNumber - 1) ?: return@map Cell("·", AppTheme.text, bold = false)
                        val v = GameScoringEngine.bestBallHoleValue(round, hs, pv, sf)
                        val hasAny = hs.strokes > 0 || (1..3).any { (round.opponentScore(it, hs.holeNumber)?.strokes ?: 0) > 0 }
                        when {
                            !hasAny -> Cell("·", AppTheme.textSec)
                            sf -> Cell("$v", if (v >= 3) AppTheme.gold else if (v == 0) AppTheme.textSec else AppTheme.text)
                            else -> Cell("$v", scoreFg(v - pv))
                        }
                    }, "${GameScoringEngine.bestBallTeamTotal(round, course, sf)}", AppTheme.gold)
                }
                GameMode.ERADO -> {
                    val result = GameScoringEngine.eradoResult(round, course)
                    CardRow("Erado", IosColors.purple, true, sorted.map { s ->
                        val scratched = s.holeNumber in result.scratchedHoles
                        val d = s.strokes - par(s.holeNumber)
                        if (scratched) Cell(if (s.strokes > 0) "${s.strokes}" else "·", IosColors.purple, rect = IosColors.purple.copy(alpha = 0.15f), size = 10, strike = true)
                        else strokeCell(s.strokes, par(s.holeNumber)).let { if (s.strokes > 0) it.copy(color = scoreFg(d)) else it }
                    }, if (result.total > 0) "${result.total}" else "-", IosColors.purple)
                }
                else -> scoreRow()
            }
        }
    }
}
