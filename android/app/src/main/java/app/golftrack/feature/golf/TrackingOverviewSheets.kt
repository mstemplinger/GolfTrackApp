package app.golftrack.feature.golf

import androidx.compose.foundation.background
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
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Loop
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.data.Course
import app.golftrack.data.GolfStore
import app.golftrack.data.HoleScore
import app.golftrack.data.LatLon
import app.golftrack.data.Round
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Wie HoleTrackingOverviewSheet.swift: was das Tracking über dieses Loch weiß. */
@Composable
fun HoleTrackingOverviewSheet(round: Round, course: Course?, score: HoleScore, par: Int, here: LatLon?, onDismiss: () -> Unit) {
    val unit = rememberDistanceUnit()
    val hole = score.holeNumber
    var corridor by remember { mutableStateOf<HoleCorridor?>(null) }
    var loading by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        val rounds = GolfStore.current.rounds
        corridor = course?.let { c -> withContext(Dispatchers.Default) { FairwayCorridorInference.corridor(hole, c, rounds.filter { it.courseId == c.id }) } }
        loading = false
    }

    val tee = course?.teeCoordinate(hole)
    val green = course?.flagCoordinate(hole)
    val pin = if (score.pinLatitude != null && score.pinLongitude != null) LatLon(score.pinLatitude, score.pinLongitude) else null
    val walk = round.track?.points(hole)?.filter { it.isValid }?.sortedBy { it.timeOffset }?.map { it.coordinate }.orEmpty()
    val length = course?.holeLengths?.getOrNull(hole - 1)?.takeIf { it > 0 }
    val hcp = course?.hcpValues?.getOrNull(hole - 1)

    FullSheet(onDismiss) {
        Column(Modifier.fillMaxSize()) {
            SheetTopBar("Loch $hole", leading = { BarButton("Fertig") { Haptics.tap(); onDismiss() } })
            if (loading) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = AppTheme.gold) }
            } else {
                val c = corridor
                val items = buildList<MapItem> {
                    if (c != null && c.corridorPolygon.size >= 4) add(MapItem.Area(c.corridorPolygon, goldA(0.20f), goldA(0.6f), 2f))
                    if (c != null && c.centerline.size >= 2) add(MapItem.Line(c.centerline, AppTheme.gold, 3f))
                    if (walk.size >= 2) add(MapItem.Line(walk, IosColors.cyan.copy(alpha = 0.9f), 3f))
                    score.sortedShots.forEach { s ->
                        add(MapItem.Line(listOf(s.from, s.to), Color.White.copy(alpha = 0.7f), 2f, dashed = true))
                        add(MapItem.Dot(s.from, Color.White, sizeDp = 20, text = "${s.shotNumber}", fg = AppTheme.bg))
                    }
                    tee?.let { add(MapItem.Dot(it, IosColors.blue, icon = MapIcon.GOLFER)) }
                    green?.let { add(MapItem.Dot(it, IosColors.red, icon = MapIcon.FLAG)) }
                    // Der Pin kann vom Grün-Mittelpunkt abweichen, wenn er selbst gesetzt wurde.
                    if (pin != null && green != null && pin != green) add(MapItem.Dot(pin, AppTheme.gold, icon = MapIcon.PIN))
                }
                GolfMap(
                    items = items, modifier = Modifier.weight(1f).fillMaxWidth(), satellite = true, userLocation = here,
                    initialFit = listOfNotNull(tee, green, pin) + walk + score.sortedShots.flatMap { listOf(it.from, it.to) },
                )
                Column(
                    Modifier.fillMaxWidth().background(AppTheme.card).padding(16.dp).navigationBarsPadding(),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Capsule("Par $par", AppTheme.gold, fontSize = 12)
                        if (hcp != null) Capsule("HCP $hcp", AppTheme.textSec, AppTheme.textSec.copy(alpha = 0.14f))
                        if (length != null) Capsule("$length m", AppTheme.textSec, AppTheme.textSec.copy(alpha = 0.14f))
                        Spacer(Modifier.weight(1f))
                        if (score.strokes > 0) Text("${score.strokes} Schläge", color = AppTheme.text, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                        if (c != null) LegendItem(AppTheme.gold, "Fairway")
                        if (walk.size >= 2) LegendItem(IosColors.cyan, "deine Spur")
                        if (score.sortedShots.isNotEmpty()) LegendItem(Color.White, "Schläge")
                    }
                    HorizontalDivider(color = AppTheme.cardAlt)
                    if (c != null) {
                        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            Stat(Icons.Filled.SwapHoriz, unit.format(c.averageWidthMeters), "Korridor")
                            Stat(Icons.Filled.Straighten, unit.format(c.axisLengthMeters), "Abschlag→Grün")
                            Stat(Icons.Filled.Loop, "${c.roundCount}", "Runden")
                        }
                        Text(
                            when (c.reliability) {
                                Reliability.GOOD -> "Aus mehreren Runden gerechnet – trotzdem eine Schätzung."
                                Reliability.THIN -> "Noch wenige Runden, der Korridor kann daneben liegen."
                                Reliability.VERY_THIN -> "Aus sehr wenigen Daten – nur ein grober Anhaltspunkt."
                            },
                            color = if (c.reliability == Reliability.GOOD) AppTheme.textSec else IosColors.orange, fontSize = 11.sp,
                        )
                    } else {
                        Text(
                            if (tee == null || green == null)
                                "Für dieses Loch sind noch keine Abschlag- und Grünpositionen gespeichert. Sie entstehen aus den aufgezeichneten Runden."
                            else
                                "Noch kein Fairway-Verlauf für dieses Loch – dafür braucht es Messpunkte zwischen Abschlag und Grün. Par-3-Löcher werden übersprungen.",
                            color = AppTheme.textSec, fontSize = 12.sp,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun LegendItem(color: Color, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(14.dp).height(4.dp).background(color, RoundedCornerShape(50)))
        Spacer(Modifier.width(5.dp))
        Text(text, color = AppTheme.textSec, fontSize = 11.sp)
    }
}

@Composable
private fun Stat(icon: ImageVector, value: String, label: String) {
    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(12.dp))
            Spacer(Modifier.width(5.dp))
            Text(value, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        }
        Text(label, color = AppTheme.textTer, fontSize = 11.sp)
    }
}

/** Wie RoundTrackingOverviewSheet.swift: Karte mit allen Fairways plus Lochtabelle. */
@Composable
fun RoundTrackingOverviewSheet(round: Round, course: Course?, currentHole: Int, here: LatLon?, onDismiss: () -> Unit) {
    val unit = rememberDistanceUnit()
    val data by GolfStore.data.collectAsState()
    val live = data.round(round.id) ?: round
    var corridors by remember { mutableStateOf<List<HoleCorridor>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        val rounds = GolfStore.current.rounds
        corridors = course?.let { c -> withContext(Dispatchers.Default) { FairwayCorridorInference.corridors(c, rounds) } }.orEmpty()
        loading = false
    }

    val scores = live.sortedScores
    val walkSegments = live.track?.points?.filter { it.isValid }?.groupBy { it.holeNumber }?.toSortedMap()
        ?.mapNotNull { (_, pts) -> pts.sortedBy { it.timeOffset }.map { it.coordinate }.takeIf { it.size > 1 } }.orEmpty()

    FullSheet(onDismiss) {
        Column(Modifier.fillMaxSize()) {
            SheetTopBar("Runde im Überblick", leading = { BarButton("Fertig") { Haptics.tap(); onDismiss() } })
            if (loading) {
                Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
                    CircularProgressIndicator(color = AppTheme.gold)
                    Text("Platz wird ausgewertet …", color = AppTheme.textSec, modifier = Modifier.padding(top = 10.dp))
                }
                return@Column
            }
            val tees = course?.let { c -> (1..maxOf(1, c.numberOfHoles)).mapNotNull { h -> c.teeCoordinate(h)?.let { h to it } } }.orEmpty()
            val items = buildList<MapItem> {
                corridors.forEach { c ->
                    val cur = c.holeNumber == currentHole
                    if (c.corridorPolygon.size >= 4) add(MapItem.Area(c.corridorPolygon, goldA(if (cur) 0.30f else 0.16f), goldA(if (cur) 0.85f else 0.45f), if (cur) 2.5f else 1.5f))
                    if (c.centerline.size >= 2) add(MapItem.Line(c.centerline, goldA(if (cur) 1f else 0.55f), if (cur) 3f else 2f))
                }
                walkSegments.forEach { add(MapItem.Line(it, IosColors.cyan.copy(alpha = 0.75f), 2.5f)) }
                tees.forEach { (h, p) ->
                    val cur = h == currentHole
                    add(MapItem.Dot(p, if (cur) AppTheme.gold else AppTheme.cardDark, sizeDp = if (cur) 28 else 22, text = "$h",
                        fg = if (cur) AppTheme.onGold else Color.White, border = Color.White.copy(alpha = 0.6f)))
                }
            }
            GolfMap(
                items = items, modifier = Modifier.height(340.dp).fillMaxWidth(), satellite = true, userLocation = here,
                initialFit = tees.map { it.second } + walkSegments.flatten() +
                    listOfNotNull(course?.latitude?.let { la -> course.longitude?.let { lo -> LatLon(la, lo) } }),
            )
            // Kennzahlen
            Row(Modifier.fillMaxWidth().background(AppTheme.cardDark).padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                SummaryItem(live.scoreLabel(course), "Score", AppTheme.scoreColor(live.scoreToPar(course)))
                SummaryDivider()
                SummaryItem("${live.totalStrokes}", "Schläge")
                SummaryDivider()
                SummaryItem("${course?.totalPar ?: 0}", "Par gesamt")
                SummaryDivider()
                SummaryItem("${live.playedScores.size}/${scores.size}", "gespielt")
                val t = live.track
                if (t != null && t.points.size > 1) {
                    SummaryDivider()
                    SummaryItem(unit.format(t.totalDistanceMeters), "gelaufen")
                }
            }
            // Lochtabelle
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(12.dp).navigationBarsPadding()) {
                Column(Modifier.fillMaxWidth().background(AppTheme.card)) {
                    Row(Modifier.padding(horizontal = 16.dp, vertical = 10.dp)) {
                        HeaderCell("Loch", 52, TextAlign.Start)
                        HeaderCell("Par", 44)
                        HeaderCell("HCP", 48)
                        Text("Länge", color = AppTheme.textTer, fontSize = 11.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.End, modifier = Modifier.weight(1f))
                        HeaderCell("Score", 62)
                        HeaderCell("Fairway", 62)
                    }
                    scores.forEachIndexed { i, s ->
                        val h = s.holeNumber
                        val par = course?.par(h) ?: 4
                        val hcp = course?.hcpValues?.getOrNull(h - 1)
                        val len = course?.holeLengths?.getOrNull(h - 1) ?: 0
                        val cor = corridors.firstOrNull { it.holeNumber == h }
                        val cur = h == currentHole
                        Row(
                            Modifier.fillMaxWidth().background(if (cur) AppTheme.gold.copy(alpha = 0.07f) else Color.Transparent)
                                .padding(horizontal = 16.dp, vertical = 11.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Row(Modifier.width(52.dp), verticalAlignment = Alignment.CenterVertically) {
                                Text("$h", color = if (cur) AppTheme.gold else AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                                if (cur) { Spacer(Modifier.width(5.dp)); Box(Modifier.size(5.dp).background(AppTheme.gold, CircleShape)) }
                            }
                            Text("$par", color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.End, modifier = Modifier.width(44.dp))
                            Text(hcp?.toString() ?: "–", color = AppTheme.textTer, fontSize = 15.sp, textAlign = TextAlign.End, modifier = Modifier.width(48.dp))
                            Text(if (len > 0) unit.format(len.toDouble()) else "–", color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.End, modifier = Modifier.weight(1f))
                            Text(
                                if (s.strokes > 0) "${s.strokes}" else "–",
                                color = if (s.strokes > 0) AppTheme.scoreColor(s.strokes - par) else AppTheme.textTer,
                                fontSize = 15.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.End, modifier = Modifier.width(62.dp),
                            )
                            Box(Modifier.width(62.dp), contentAlignment = Alignment.CenterEnd) {
                                when {
                                    cor == null -> Icon(Icons.Filled.Remove, null, tint = AppTheme.textTer, modifier = Modifier.size(14.dp))
                                    cor.reliability == Reliability.GOOD -> Icon(Icons.Filled.CheckCircle, null, tint = AppTheme.green, modifier = Modifier.size(14.dp))
                                    else -> Icon(Icons.Outlined.Circle, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                                }
                            }
                        }
                        if (i < scores.lastIndex) HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(start = 16.dp))
                    }
                }
            }
        }
    }
}

@Composable
private fun HeaderCell(text: String, width: Int, align: TextAlign = TextAlign.End) =
    Text(text, color = AppTheme.textTer, fontSize = 11.sp, fontWeight = FontWeight.Bold, textAlign = align, modifier = Modifier.width(width.dp))

@Composable
private fun androidx.compose.foundation.layout.RowScope.SummaryItem(value: String, label: String, color: Color = AppTheme.text) {
    Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(value, color = color, fontSize = 15.sp, fontWeight = FontWeight.Bold, maxLines = 1)
        Text(label, color = AppTheme.textTer, fontSize = 11.sp, maxLines = 1)
    }
}

@Composable
private fun SummaryDivider() = Box(Modifier.width(1.dp).height(26.dp).background(AppTheme.cardAlt))
