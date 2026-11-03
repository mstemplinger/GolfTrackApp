package app.golftrack.feature.range

import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.UnfoldMore
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.navigation.NavController
import app.golftrack.data.DistanceUnit
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import java.text.SimpleDateFormat
import java.util.Locale
import kotlin.math.ceil
import kotlin.math.floor

private fun formatSessionDate(ms: Long): String = SimpleDateFormat("d. MMM yyyy, HH:mm", Locale.GERMANY).format(ms)
private fun formatAxisDate(ms: Long): String = SimpleDateFormat("d.M.", Locale.GERMANY).format(ms)

// --- Zusammenfassung nach einer Einheit ---

/**
 * Erscheint nach „Einheit beenden": je Schläger Ø und Bestweite von heute,
 * verglichen mit allen Einheiten davor.
 */
@Composable
internal fun RangeSessionSummary(session: RangeSession, earlierShots: List<RangeShot>, unit: DistanceUnit, onDone: () -> Unit) {
    val today = RangeClubStats.byClub(session.shots)
    val earlier = RangeClubStats.byClub(earlierShots)
    Dialog(
        onDismissRequest = onDone,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        Column(Modifier.fillMaxSize().background(AppTheme.bg).statusBarsPadding().navigationBarsPadding()) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp), horizontalArrangement = Arrangement.End) {
                Text(
                    "Fertig", color = AppTheme.gold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable { Haptics.tap(); onDone() }.padding(6.dp),
                )
            }
            Column(
                Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                Column(Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Icon(Icons.Filled.SportsGolf, null, tint = AppTheme.gold, modifier = Modifier.size(44.dp))
                    Text("Einheit gespeichert", color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                    Text("Bälle: ${session.shots.size} · Schläger: ${today.size}", color = AppTheme.textSec, fontSize = 15.sp)
                }
                Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(horizontal = 16.dp)) {
                    val clubs = session.clubNames.filter { it in today }
                    clubs.forEachIndexed { i, club ->
                        RangeClubCompareRow(today.getValue(club), earlier[club], unit)
                        if (i < clubs.lastIndex) HorizontalDivider(color = AppTheme.cardAlt)
                    }
                }
            }
        }
    }
}

/** Eine Zeile „Schläger – Ø heute – Unterschied zu früher – Bestweite". */
@Composable
private fun RangeClubCompareRow(stats: RangeClubStats, earlier: RangeClubStats?, unit: DistanceUnit) {
    Row(Modifier.fillMaxWidth().padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(stats.clubName, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            Text("Bälle: ${stats.count} · Bestweite ${unit.format(stats.best)}", color = AppTheme.textSec, fontSize = 12.sp)
        }
        if (earlier != null && stats.best > earlier.best) {
            Icon(Icons.Filled.Star, "Neue Bestweite", tint = AppTheme.gold, modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(12.dp))
        }
        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("Ø ${unit.format(stats.average)}", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            if (earlier != null) {
                val diff = unit.value(stats.average) - unit.value(earlier.average)
                Text(
                    if (diff >= 0) "+$diff ${unit.unitLabel}" else "$diff ${unit.unitLabel}",
                    color = AppTheme.scoreColor(if (diff >= 0) -1 else 1), fontSize = 12.sp, fontWeight = FontWeight.Bold,
                )
            } else {
                Text("Neu", color = AppTheme.textSec, fontSize = 12.sp)
            }
        }
    }
}

// --- Verlauf ---

private data class TrendPoint(val date: Long, val average: Double, val best: Double)

/** Entwicklung je Schläger über alle Einheiten plus Liste der Einheiten (RangeHistoryView.swift). */
@Composable
fun RangeHistoryScreen(nav: NavController) {
    val ctx = LocalContext.current
    remember { RangeStore.init(ctx) }
    val data by RangeStore.data.collectAsState()
    val unit = rememberDistanceUnit()
    val finished = data.sessions.filter { it.shots.isNotEmpty() }.sortedBy { it.date }
    // Schläger nach Häufigkeit – der meistgeschlagene steht vorn.
    val clubs = RangeClubStats.byClub(finished.flatMap { it.shots }).values
        .sortedWith(compareByDescending<RangeClubStats> { it.count }.thenBy { it.clubName })
    var chartClub by rememberSaveable { mutableStateOf("") }
    if (chartClub.isEmpty() && clubs.isNotEmpty()) chartClub = clubs.first().clubName
    var sessionToDelete by remember { mutableStateOf<RangeSession?>(null) }

    AppScaffold("Range-Verlauf", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            if (finished.isEmpty()) {
                EmptyState()
            } else {
                TrendCard(finished, clubs, chartClub, unit) { chartClub = it }
                ClubsCard(clubs, unit)
                SessionsCard(finished) { sessionToDelete = it }
            }
        }
    }

    sessionToDelete?.let { s ->
        AlertDialog(
            onDismissRequest = { sessionToDelete = null },
            containerColor = AppTheme.card,
            title = { Text("Einheit löschen?", color = AppTheme.text) },
            confirmButton = {
                TextButton(onClick = { Haptics.warning(); RangeStore.delete(s.id); sessionToDelete = null }) {
                    Text("Löschen", color = Color(0xFFFF453A))
                }
            },
            dismissButton = {
                TextButton(onClick = { Haptics.tap(); sessionToDelete = null }) { Text("Abbrechen", color = AppTheme.gold) }
            },
        )
    }
}

@Composable
private fun EmptyState() {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(30.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Icon(Icons.Filled.SportsGolf, null, tint = AppTheme.gold, modifier = Modifier.size(44.dp))
        Text("Noch keine Range-Einheit", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        Text(
            "Trage auf der Driving Range Schläger und Weite ein – hier siehst du dann, wie du dich entwickelst.",
            color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun TrendCard(
    finished: List<RangeSession>,
    clubs: List<RangeClubStats>,
    chartClub: String,
    unit: DistanceUnit,
    onClub: (String) -> Unit,
) {
    val trend = finished.mapNotNull { s ->
        val stats = RangeClubStats.of(chartClub, s.shots.filter { it.clubName == chartClub }.map { it.distanceMeters })
            ?: return@mapNotNull null
        TrendPoint(s.date, unit.value(stats.average).toDouble(), unit.value(stats.best).toDouble())
    }
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Entwicklung", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            var open by remember { mutableStateOf(false) }
            Box {
                Row(
                    Modifier.clip(RoundedCornerShape(6.dp)).clickable { Haptics.tap(); open = true },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(chartClub, color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Icon(Icons.Filled.UnfoldMore, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp))
                }
                DropdownMenu(open, { open = false }, containerColor = AppTheme.cardAlt) {
                    clubs.forEach { c ->
                        DropdownMenuItem(
                            text = { Text(c.clubName, color = AppTheme.text) },
                            onClick = { Haptics.selection(); open = false; onClub(c.clubName) },
                        )
                    }
                }
            }
        }
        if (trend.size >= 2) {
            TrendChart(trend, unit)
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Legend(AppTheme.gold, "Durchschnitt")
                Legend(AppTheme.green, "Bestweite")
            }
        } else {
            Text("Ab zwei Einheiten mit diesem Schläger siehst du hier deine Entwicklung.", color = AppTheme.textSec, fontSize = 12.sp)
        }
    }
}

@Composable
private fun Legend(color: Color, label: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(8.dp).background(color, CircleShape))
        Spacer(Modifier.width(5.dp))
        Text(label, color = AppTheme.textSec, fontSize = 11.sp)
    }
}

/** Linien für Ø (gold, mit Punkten) und Bestweite (grün, gestrichelt) über das Datum. */
@Composable
private fun TrendChart(points: List<TrendPoint>, unit: DistanceUnit) {
    val measurer = rememberTextMeasurer()
    val labelStyle = TextStyle(color = AppTheme.textTer, fontSize = 10.sp)
    Canvas(Modifier.fillMaxWidth().height(200.dp)) {
        val left = 36.dp.toPx()
        val bottom = 20.dp.toPx()
        val top = 26.dp.toPx()
        val w = size.width - left - 6.dp.toPx()
        val h = size.height - bottom - top

        // Achse ohne Null wie `.automatic(includesZero: false)`, auf glatte Werte gerundet.
        val values = points.flatMap { listOf(it.average, it.best) }
        val step = niceStep((values.max() - values.min()).coerceAtLeast(10.0) / 4)
        val yMin = floor(values.min() / step) * step
        val yMax = maxOf(ceil(values.max() / step) * step, yMin + step)
        val tMin = points.first().date.toDouble()
        val tSpan = (points.last().date - points.first().date).coerceAtLeast(1).toDouble()
        fun x(t: Long) = left + ((t - tMin) / tSpan * w).toFloat()
        fun y(v: Double) = top + (h - ((v - yMin) / (yMax - yMin) * h)).toFloat()

        var v = yMin
        while (v <= yMax + 0.001) {
            val yy = y(v)
            drawLine(Color.White.copy(alpha = 0.08f), Offset(left, yy), Offset(left + w, yy), 1f)
            drawLabel(measurer, "${v.toInt()}", Offset(0f, yy - 7.dp.toPx()), labelStyle)
            v += step
        }
        drawLabel(measurer, unit.unitLabel, Offset(0f, 0f), labelStyle)
        drawLabel(measurer, formatAxisDate(points.first().date), Offset(left, size.height - 14.dp.toPx()), labelStyle)
        val lastLabel = formatAxisDate(points.last().date)
        val lw = measurer.measure(lastLabel, labelStyle).size.width
        drawLabel(measurer, lastLabel, Offset(left + w - lw, size.height - 14.dp.toPx()), labelStyle)

        // Bestweite gestrichelt
        val best = Path().apply {
            points.forEachIndexed { i, p -> if (i == 0) moveTo(x(p.date), y(p.best)) else lineTo(x(p.date), y(p.best)) }
        }
        drawPath(best, AppTheme.green, style = Stroke(1.5.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(5.dp.toPx(), 4.dp.toPx()))))

        // Durchschnitt geglättet (Catmull-Rom) mit Punkten
        val pts = points.map { Offset(x(it.date), y(it.average)) }
        val avg = Path().apply {
            moveTo(pts[0].x, pts[0].y)
            for (i in 0 until pts.size - 1) {
                val p0 = pts.getOrElse(i - 1) { pts[i] }
                val p1 = pts[i]
                val p2 = pts[i + 1]
                val p3 = pts.getOrElse(i + 2) { p2 }
                cubicTo(
                    p1.x + (p2.x - p0.x) / 6f, p1.y + (p2.y - p0.y) / 6f,
                    p2.x - (p3.x - p1.x) / 6f, p2.y - (p3.y - p1.y) / 6f,
                    p2.x, p2.y,
                )
            }
        }
        drawPath(avg, AppTheme.gold, style = Stroke(2.dp.toPx(), cap = StrokeCap.Round))
        pts.forEach { drawCircle(AppTheme.gold, 3.5.dp.toPx(), it) }
    }
}

private fun niceStep(raw: Double): Double {
    val candidates = listOf(1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 50.0, 100.0)
    return candidates.firstOrNull { it >= raw } ?: 100.0
}

private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawLabel(m: TextMeasurer, text: String, at: Offset, style: TextStyle) {
    drawText(m, text, at, style)
}

@Composable
private fun ClubsCard(clubs: List<RangeClubStats>, unit: DistanceUnit) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text("Deine Weiten", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(bottom = 6.dp))
        clubs.forEach { c ->
            Row(Modifier.padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(c.clubName, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Text("Bälle: ${c.count}", color = AppTheme.textSec, fontSize = 12.sp)
                }
                Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text("Ø ${unit.format(c.average)}", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Text("Bestweite ${unit.format(c.best)}", color = AppTheme.textSec, fontSize = 12.sp)
                }
            }
        }
    }
}

@Composable
private fun SessionsCard(finished: List<RangeSession>, onDelete: (RangeSession) -> Unit) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text("Einheiten", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(bottom = 6.dp))
        finished.reversed().forEach { s ->
            Row(Modifier.padding(vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(formatSessionDate(s.date), color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Text(
                        "Bälle: ${s.shots.size} · ${s.clubNames.joinToString(", ")}",
                        color = AppTheme.textSec, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
                    )
                }
                Icon(
                    Icons.Filled.Delete, "Einheit löschen", tint = AppTheme.textTer,
                    modifier = Modifier.clip(CircleShape).clickable { Haptics.tap(); onDelete(s) }.padding(6.dp).size(20.dp),
                )
            }
        }
    }
}
