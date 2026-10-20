package app.golftrack.feature.records

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.GameMode
import app.golftrack.data.GameScoringEngine
import app.golftrack.data.GolfStore
import app.golftrack.data.HoleOutcome
import app.golftrack.data.HoleScore
import app.golftrack.data.Round
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.launch
import java.util.Locale

/** Wie RoundDetailView.swift. */
@Composable
internal fun RoundDetailScreen(nav: NavController, roundId: String) {
    val data by GolfStore.data.collectAsState()
    val round = data.round(roundId)
    val course = data.course(round?.courseId)
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()

    AppScaffold(
        title = course?.name ?: "Runde",
        onBack = { nav.popBackStack() },
        actions = {
            if (round != null) {
                IconButton(onClick = {
                    Haptics.tap()
                    scope.launch { shareScorecard(ctx, round, course) }
                }) { Icon(Icons.Filled.Share, contentDescription = "Teilen", tint = AppTheme.gold) }
                IconButton(onClick = {
                    Haptics.medium()
                    GolfStore.updateRound(round.id) { it.copy(isComplete = false) }
                    nav.navigate(Routes.playRound(round.id))
                }) { Icon(Icons.Filled.Edit, contentDescription = "Bearbeiten", tint = AppTheme.gold) }
            }
        },
    ) { m ->
        if (round == null) {
            EmptyState(Icons.Filled.Edit, "Runde nicht gefunden", "Diese Runde wurde gelöscht.", m)
            return@AppScaffold
        }
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            SummaryCard(round, course)
            StatsGrid(round, course)
            ScorecardSection(round, course)
            if (round.holeScores.any { it.shots.isNotEmpty() }) RoundShotMapCard(round)
            if ((round.track?.points?.size ?: 0) > 1) {
                RoundTrackMapCard(round, course, onDeriveGeometry = { c -> nav.navigate(RecordsInternalRoutes.geometry(c.id)) })
            }
            val totalDistance = round.sortedScores.sumOf { it.totalDistanceMeters }
            if (totalDistance > 0) DistanceSection(round, totalDistance)
            if (round.notes.isNotEmpty()) NotesSection(round.notes)
        }
    }
}

// MARK: - Zusammenfassung

@Composable
private fun SummaryCard(round: Round, course: Course?) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(16.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(course?.name ?: "Unbekannter Platz", color = AppTheme.text, fontSize = IosFont.title3, fontWeight = FontWeight.Bold)
            Text(formatDateComplete(round.date), color = AppTheme.textSec, fontSize = IosFont.subheadline)
            if (course != null) {
                Text("${course.numberOfHoles} Loch · Par ${course.totalPar}", color = AppTheme.textSec, fontSize = IosFont.caption)
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Icon(gameModeIcon(round.gameMode), contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                Text(round.gameMode.displayName, color = AppTheme.gold, fontSize = IosFont.caption)
            }
        }
        Spacer(Modifier.width(8.dp))
        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(4.dp)) {
            MainScore(round, course)
        }
    }
}

@Composable
private fun BigValue(value: String, color: Color, label: String, extra: String? = null) {
    Text(value, color = color, fontSize = IosFont.largeTitle, fontWeight = FontWeight.Bold)
    Text(label, color = AppTheme.textSec, fontSize = IosFont.subheadline)
    if (extra != null) Text(extra, color = AppTheme.textSec, fontSize = IosFont.caption)
}

@Composable
private fun MainScore(round: Round, course: Course?) {
    when (round.gameMode) {
        GameMode.MATCHPLAY, GameMode.BETTER_BALL_MATCHPLAY -> {
            val status = if (round.gameMode == GameMode.MATCHPLAY) GameScoringEngine.matchplayStatus(round)
            else GameScoringEngine.betterBallMatchplayStatus(round)
            val color = when {
                status.playerLeads -> AppTheme.gold
                status.opponentLeads -> IosColor.red
                else -> AppTheme.text
            }
            Text(status.statusLabel, color = color, fontSize = IosFont.headline, fontWeight = FontWeight.Bold, textAlign = TextAlign.End)
        }
        GameMode.STABLEFORD -> BigValue("${round.totalStablefordPoints(course)}", AppTheme.gold, "Punkte")
        GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD -> {
            val sf = round.gameMode == GameMode.BETTER_BALL_STABLEFORD
            BigValue("${GameScoringEngine.betterBallTeamTotal(round, course, sf)}", if (sf) AppTheme.gold else AppTheme.text,
                if (sf) "Team Punkte" else "Team Schläge")
        }
        GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD -> {
            val sf = round.gameMode == GameMode.BEST_BALL_STABLEFORD
            BigValue("${GameScoringEngine.bestBallTeamTotal(round, course, sf)}", if (sf) AppTheme.gold else AppTheme.text,
                if (sf) "Team Punkte" else "Best Ball Schläge")
        }
        GameMode.SKINS -> BigValue("${GameScoringEngine.skinsResult(round).skinsPerPlayer[0] ?: 0}", IosColor.orange, "Skins")
        GameMode.ERADO -> {
            val r = GameScoringEngine.eradoResult(round, course)
            val holes = r.scratchedHoles.sorted().joinToString(", ") { "L$it" }
            BigValue("${r.total}", IosColor.purple, "Erado Score", if (r.scratchedHoles.isNotEmpty()) "Streich: $holes" else null)
        }
        else -> BigValue(round.scoreLabel(course), golfScoreColor(round.scoreToPar(course)), "${round.totalStrokes} Schläge")
    }
}

// MARK: - Kennzahlen

@Composable
private fun StatsGrid(round: Round, course: Course?) {
    val fwOpp = round.fairwayOpportunities(course)
    val girOpp = round.girOpportunities
    Row(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        StatCell("${round.totalPutts}", "Putts")
        VerticalDivider(Modifier.height(44.dp), color = AppTheme.textTer.copy(alpha = 0.4f))
        StatCell(if (fwOpp > 0) "${round.fairwaysHit}/$fwOpp" else "-", "Fairways")
        VerticalDivider(Modifier.height(44.dp), color = AppTheme.textTer.copy(alpha = 0.4f))
        StatCell(if (girOpp > 0) "${round.greensInRegulation}/$girOpp" else "-", "GIR")
        VerticalDivider(Modifier.height(44.dp), color = AppTheme.textTer.copy(alpha = 0.4f))
        StatCell(if (girOpp > 0) fmt1(round.totalPutts.toDouble() / girOpp) else "-", "Ø Putts")
    }
}

@Composable
private fun RowScope.StatCell(value: String, label: String) {
    Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(value, color = AppTheme.text, fontSize = IosFont.title3, fontWeight = FontWeight.Bold)
        Text(label, color = AppTheme.textSec, fontSize = IosFont.caption)
    }
}

// MARK: - Scorecard

private val labelW = 52.dp
private val cellW = 34.dp
private val totalW = 40.dp

@Composable
private fun ScorecardSection(round: Round, course: Course?) {
    val scores = round.sortedScores
    fun par(s: HoleScore): Int = course?.parValues?.getOrNull(s.holeNumber - 1) ?: 4
    val parTexts = scores.map { s -> course?.parValues?.getOrNull(s.holeNumber - 1)?.toString() ?: "-" }

    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text("Scorecard", color = AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold)
        Box(Modifier.horizontalScroll(rememberScrollState())) {
            Column(
                Modifier.background(AppTheme.card, RoundedCornerShape(14.dp)).padding(horizontal = 12.dp, vertical = 8.dp),
            ) {
                TextRow("Loch", scores.map { "${it.holeNumber}" }, "∑", bold = true)
                HorizontalDivider(color = AppTheme.textTer.copy(alpha = 0.4f))
                TextRow("Par", parTexts, "${course?.totalPar ?: 0}", muted = true)
                TableRow("Score", "${round.totalStrokes}") {
                    scores.forEach { s -> ScoreBubble(s.strokes, par(s), played = s.strokes > 0) }
                }
                ModeRows(round, course, scores, ::par)
                HorizontalDivider(color = AppTheme.textTer.copy(alpha = 0.4f))
                TextRow("Putts", scores.map { "${it.putts}" }, "${round.totalPutts}", muted = true)
            }
        }
    }
}

@Composable
private fun ModeRows(round: Round, course: Course?, scores: List<HoleScore>, par: (HoleScore) -> Int) {
    val names = round.otherPlayerNames
    fun short(i: Int, fallback: String) = names.getOrNull(i)?.takeIf { it.isNotEmpty() }?.take(6) ?: fallback
    when (round.gameMode) {
        GameMode.MATCHPLAY -> {
            OpponentRow(round, scores, names.firstOrNull()?.take(6) ?: "Gegner", 1, par)
            TableRow("Ergebnis", "") {
                scores.forEach { s ->
                    val o = GameScoringEngine.matchplayHoleOutcome(s.strokes, round.opponentScore(1, s.holeNumber)?.strokes ?: 0)
                    OutcomeCell(o)
                }
            }
        }
        GameMode.STABLEFORD -> TextRow(
            "Punkte",
            scores.map { s ->
                val p = course?.parValues?.getOrNull(s.holeNumber - 1)
                if (p == null || s.strokes <= 0) "·" else "${GameMode.stablefordPoints(s.strokes, p)}"
            },
            "${round.totalStablefordPoints(course)}",
        )
        GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD -> {
            val sf = round.gameMode == GameMode.BETTER_BALL_STABLEFORD
            OpponentRow(round, scores, names.firstOrNull()?.take(6) ?: "Partner", 1, par)
            TextRow(
                "Team",
                scores.map { s ->
                    val partner = round.opponentScore(1, s.holeNumber)
                    val p = course?.parValues?.getOrNull(s.holeNumber - 1)
                    val played = s.strokes > 0 || (partner?.strokes ?: 0) > 0
                    if (p == null || !played) "·" else "${GameScoringEngine.betterBallHoleValue(s, partner, p, sf)}"
                },
                "${GameScoringEngine.betterBallTeamTotal(round, course, sf)}",
                bold = true,
            )
        }
        GameMode.BETTER_BALL_MATCHPLAY -> {
            OpponentRow(round, scores, short(0, "Partner"), 1, par)
            OpponentRow(round, scores, short(1, "Gegner 1"), 2, par)
            if (names.size >= 3) OpponentRow(round, scores, short(2, "Gegner 2"), 3, par)
            TableRow("Ergebnis", "") {
                scores.forEach { s ->
                    val h = s.holeNumber
                    val partner = round.opponentScore(1, h)?.takeIf { it.strokes > 0 }
                    val o1 = round.opponentScore(2, h)?.takeIf { it.strokes > 0 }
                    val o2 = round.opponentScore(3, h)?.takeIf { it.strokes > 0 }
                    val myBest = partner?.let { minOf(s.strokes, it.strokes) } ?: s.strokes
                    val oppBest = if (o1 == null) 0 else o2?.let { minOf(o1.strokes, it.strokes) } ?: o1.strokes
                    val outcome = if (oppBest > 0 && myBest > 0) GameScoringEngine.matchplayHoleOutcome(myBest, oppBest)
                    else HoleOutcome.NOT_PLAYED
                    OutcomeCell(outcome)
                }
            }
        }
        GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD -> {
            val sf = round.gameMode == GameMode.BEST_BALL_STABLEFORD
            TextRow(
                "Best",
                scores.map { s ->
                    val p = course?.parValues?.getOrNull(s.holeNumber - 1) ?: return@map "·"
                    val v = GameScoringEngine.bestBallHoleValue(round, s, p, sf)
                    val any = s.strokes > 0 || (1..3).any { (round.opponentScore(it, s.holeNumber)?.strokes ?: 0) > 0 }
                    if (any) "$v" else "·"
                },
                "${GameScoringEngine.bestBallTeamTotal(round, course, sf)}",
                bold = true,
            )
        }
        GameMode.SKINS -> {
            val summary = GameScoringEngine.skinsResult(round)
            TextRow(
                "Skins",
                scores.map { s ->
                    when (val idx = summary.holeWinners[s.holeNumber]) {
                        null -> "·"
                        -1 -> "="
                        0 -> "Du"
                        else -> names.getOrNull(idx - 1)?.takeIf { it.isNotEmpty() }?.take(2) ?: "G$idx"
                    }
                },
                "${summary.skinsPerPlayer[0] ?: 0}",
            )
        }
        GameMode.ERADO -> {
            val r = GameScoringEngine.eradoResult(round, course)
            TextRow(
                "Erado",
                scores.map { s -> if (s.holeNumber in r.scratchedHoles) "(-)" else if (s.strokes > 0) "${s.strokes}" else "·" },
                "${r.total}",
            )
        }
        else -> {}
    }
}

@Composable
private fun TableRow(label: String, total: String, bold: Boolean = false, muted: Boolean = false, cells: @Composable RowScope.() -> Unit) {
    Row(Modifier.height(30.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(
            label, modifier = Modifier.width(labelW), fontSize = IosFont.caption, maxLines = 1,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
            color = if (muted) AppTheme.textSec else AppTheme.text,
        )
        cells()
        Text(total, modifier = Modifier.width(totalW), textAlign = TextAlign.End, fontSize = IosFont.caption, fontWeight = FontWeight.Bold, color = AppTheme.text)
    }
}

@Composable
private fun TextRow(label: String, values: List<String>, total: String, bold: Boolean = false, muted: Boolean = false) {
    TableRow(label, total, bold, muted) {
        values.forEach { v ->
            Text(
                v, modifier = Modifier.width(cellW), textAlign = TextAlign.Center, fontSize = IosFont.caption, maxLines = 1,
                fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
                color = if (muted) AppTheme.textSec else AppTheme.text,
            )
        }
    }
}

@Composable
private fun ScoreBubble(strokes: Int, par: Int, played: Boolean = true) {
    val d = strokes - par
    val bg = when {
        !played -> Color.Transparent
        d < 0 -> AppTheme.gold.copy(alpha = 0.25f)
        d > 0 -> IosColor.orange.copy(alpha = 0.2f)
        else -> Color.Transparent
    }
    val fg = when {
        !played -> AppTheme.textSec
        d < 0 -> AppTheme.gold
        d > 0 -> IosColor.orange
        else -> AppTheme.text
    }
    Box(Modifier.width(cellW), contentAlignment = Alignment.Center) {
        Box(Modifier.size(24.dp).background(bg, CircleShape), contentAlignment = Alignment.Center) {
            Text(if (played) "$strokes" else "·", color = fg, fontSize = 10.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun OpponentRow(round: Round, scores: List<HoleScore>, label: String, playerIndex: Int, par: (HoleScore) -> Int) {
    TableRow(label, "-") {
        scores.forEach { s ->
            val st = round.opponentScore(playerIndex, s.holeNumber)?.strokes ?: 0
            ScoreBubble(st, par(s), played = st > 0)
        }
    }
}

@Composable
private fun OutcomeCell(o: HoleOutcome) {
    val color = when (o) {
        HoleOutcome.PLAYER -> AppTheme.gold
        HoleOutcome.OPPONENT -> IosColor.red
        else -> AppTheme.textSec
    }
    Text(o.shortLabel, modifier = Modifier.width(cellW), textAlign = TextAlign.Center, fontSize = IosFont.caption, fontWeight = FontWeight.Bold, color = color)
}

// MARK: - Distanzen & Notizen

private fun formatMeters(m: Double): String =
    if (m >= 1000) String.format(Locale.US, "%.2f km", m / 1000) else String.format(Locale.US, "%.0f m", m)

@Composable
private fun DistanceSection(round: Round, total: Double) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.AutoMirrored.Filled.DirectionsWalk, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(6.dp))
            Text("Distanzen (GPS)", color = AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            Text(formatMeters(total), color = AppTheme.gold, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold)
        }
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            round.sortedScores.filter { it.totalDistanceMeters > 0 }.forEach { s ->
                Column(
                    Modifier.background(AppTheme.cardDark, RoundedCornerShape(10.dp)).padding(horizontal = 10.dp, vertical = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    Text("L${s.holeNumber}", color = AppTheme.textSec, fontSize = IosFont.caption2)
                    Text(formatMeters(s.totalDistanceMeters), color = AppTheme.text, fontSize = IosFont.caption, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
private fun NotesSection(notes: String) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Notizen", color = AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold)
        Text(
            notes, color = AppTheme.textSec, fontSize = IosFont.subheadline,
            modifier = Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(16.dp),
        )
    }
}
