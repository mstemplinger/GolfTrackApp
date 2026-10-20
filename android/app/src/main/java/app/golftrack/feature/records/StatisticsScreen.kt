package app.golftrack.feature.records

import android.graphics.Paint
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.GolfData
import app.golftrack.data.GolfStore
import app.golftrack.data.HandicapCalculator
import app.golftrack.data.Round
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.theme.AppTheme
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max

/** Wie StatisticsView.swift – nur abgeschlossene Runden. */
@Composable
internal fun StatisticsScreen(nav: NavController) {
    val data by GolfStore.data.collectAsState()
    val rounds = data.completedRounds
    val unit = rememberDistanceUnit()

    AppScaffold("Statistiken", onBack = { nav.popBackStack() }) { m ->
        if (rounds.isEmpty()) {
            EmptyState(Icons.Filled.BarChart, "Keine Statistiken", "Spiele Runden, um Statistiken zu sehen", m)
            return@AppScaffold
        }
        val last10 = rounds.take(10).reversed()
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            OverviewGrid(rounds, data)
            if (last10.size >= 2) TrendChart(last10, data)
            AveragesCard(rounds, data)
            val clubStats = clubStats(rounds)
            if (clubStats.isNotEmpty()) ClubDistanceCard(clubStats, unit)
        }
    }
}

private fun pct(num: Int, den: Int) = fmt0(num.toDouble() / den * 100) + "%"

@Composable
private fun OverviewGrid(rounds: List<Round>, data: GolfData) {
    fun course(r: Round): Course? = data.course(r.courseId)
    val scores = rounds.mapNotNull { it.scoreToPar(course(it)) }
    val best = scores.minOrNull()?.let { if (it < 0) "$it" else if (it == 0) "E" else "+$it" } ?: "-"
    val avg = if (scores.isEmpty()) "-" else scores.average().let { if (it < 0) fmt1(it) else "+" + fmt1(it) }
    val avgPutts = fmt1(rounds.sumOf { it.totalPutts }.toDouble() / rounds.size)
    val girRounds = rounds.filter { it.girOpportunities > 0 }
    val gir = if (girRounds.isEmpty()) "–" else pct(girRounds.sumOf { it.greensInRegulation }, girRounds.sumOf { it.girOpportunities })

    val cards = listOf(
        StatCardData("Runden gespielt", "${rounds.size}", Icons.Filled.Flag, AppTheme.gold),
        StatCardData("Handicap (WHS)", HandicapCalculator.displayString(rounds, data), Icons.Filled.EmojiEvents, IosColor.yellow),
        StatCardData("Bestleistung", best, Icons.Filled.Star, IosColor.orange),
        StatCardData("Ø Score vs. Par", avg, Icons.AutoMirrored.Filled.TrendingUp, IosColor.blue),
        StatCardData("Ø Putts/Runde", avgPutts, Icons.Filled.Circle, IosColor.purple),
        StatCardData("GIR", gir, Icons.Filled.GpsFixed, AppTheme.gold),
    )
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        cards.chunked(2).forEach { pair ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                pair.forEach { StatCard(it, Modifier.weight(1f)) }
            }
        }
    }
}

private data class StatCardData(val title: String, val value: String, val icon: ImageVector, val color: Color)

@Composable
private fun StatCard(d: StatCardData, modifier: Modifier) {
    Column(
        modifier.background(AppTheme.card, RoundedCornerShape(14.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(d.icon, contentDescription = null, tint = d.color, modifier = Modifier.size(22.dp))
        Text(d.value, color = AppTheme.text, fontSize = IosFont.title2, fontWeight = FontWeight.Bold)
        Text(d.title, color = AppTheme.textSec, fontSize = IosFont.caption, maxLines = 2)
    }
}

/** Score-Verlauf: Fläche zur Par-Linie, Catmull-Rom-Linie, Punkte mit Beschriftung. */
@Composable
private fun TrendChart(last10: List<Round>, data: GolfData) {
    val values = last10.map { it.scoreToPar(data.course(it.courseId)) }
    val gold = AppTheme.gold
    val labelColor = AppTheme.textSec
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Text("Score-Verlauf (letzte ${last10.size} Runden)", color = AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold)
        Canvas(Modifier.fillMaxWidth().height(180.dp)) {
            val present = values.filterNotNull()
            if (present.isEmpty()) return@Canvas
            val dp = density
            val axisW = 28 * dp
            val xLabelH = 18 * dp
            val padTop = 16 * dp
            val padBottom = 16 * dp
            val plotW = size.width - axisW
            val plotH = size.height - xLabelH - padTop - padBottom
            // Y-Bereich mit Par (0) und etwas Luft, auf „schöne" Schritte gerundet.
            var lo = minOf(0, present.min()).toDouble()
            var hi = maxOf(0, present.max()).toDouble()
            if (hi - lo < 4) { hi += 2; lo -= 2 }
            val step = niceStep((hi - lo) / 4)
            lo = floor(lo / step) * step
            hi = ceil(hi / step) * step
            fun yOf(v: Double) = padTop + ((hi - v) / (hi - lo) * plotH).toFloat()
            val n = values.size
            fun xOf(i: Int) = if (n == 1) plotW / 2 else (plotW * (0.04f + 0.92f * i / (n - 1)))

            val text = Paint(Paint.ANTI_ALIAS_FLAG).apply { textSize = 11 * dp; color = labelColor.toArgb() }

            // Raster + Y-Achse rechts (wie Swift Charts)
            var g = lo
            while (g <= hi + 1e-9) {
                val y = yOf(g)
                drawLine(Color.White.copy(alpha = 0.08f), Offset(0f, y), Offset(plotW, y), strokeWidth = 1f)
                text.textAlign = Paint.Align.LEFT
                drawContext.canvas.nativeCanvas.drawText(
                    if (g > 0) "+${g.toInt()}" else "${g.toInt()}", plotW + 6 * dp, y + 4 * dp, text,
                )
                g += step
            }
            // Par-Linie gestrichelt
            val y0 = yOf(0.0)
            drawLine(
                Color.White.copy(alpha = 0.3f), Offset(0f, y0), Offset(plotW, y0), strokeWidth = 1.5f * dp,
                pathEffect = PathEffect.dashPathEffect(floatArrayOf(6 * dp, 4 * dp)),
            )

            val pts = values.mapIndexedNotNull { i, v -> v?.let { Offset(xOf(i), yOf(it.toDouble())) to it } }

            // Flächen je Punkt zur Par-Linie (wie AreaMark mit Farbe je Vorzeichen)
            if (pts.size >= 2) {
                for (k in 0 until pts.size - 1) {
                    val (a, va) = pts[k]
                    val (b, _) = pts[k + 1]
                    val area = Path().apply {
                        moveTo(a.x, y0); lineTo(a.x, a.y); lineTo(b.x, b.y); lineTo(b.x, y0); close()
                    }
                    drawPath(area, if (va < 0) gold.copy(alpha = 0.15f) else IosColor.orange.copy(alpha = 0.1f))
                }
                // Catmull-Rom-Linie
                val line = Path().apply {
                    moveTo(pts[0].first.x, pts[0].first.y)
                    for (k in 0 until pts.size - 1) {
                        val p0 = pts[maxOf(0, k - 1)].first
                        val p1 = pts[k].first
                        val p2 = pts[k + 1].first
                        val p3 = pts[minOf(pts.size - 1, k + 2)].first
                        val c1 = Offset(p1.x + (p2.x - p0.x) / 6f, p1.y + (p2.y - p0.y) / 6f)
                        val c2 = Offset(p2.x - (p3.x - p1.x) / 6f, p2.y - (p3.y - p1.y) / 6f)
                        cubicTo(c1.x, c1.y, c2.x, c2.y, p2.x, p2.y)
                    }
                }
                drawPath(line, gold, style = Stroke(width = 2 * dp))
            }
            // Punkte + Werte
            text.textAlign = Paint.Align.CENTER
            text.textSize = 11 * dp
            for ((p, v) in pts) {
                drawCircle(gold, radius = 4 * dp, center = p)
                val label = if (v < 0) "$v" else if (v == 0) "E" else "+$v"
                val ly = if (v < 0) p.y + 15 * dp else p.y - 8 * dp
                drawContext.canvas.nativeCanvas.drawText(label, p.x, ly, text)
            }
            // X-Achse: Datum
            text.textSize = 10 * dp
            val every = if (n > 6) 2 else 1
            last10.forEachIndexed { i, r ->
                if (i % every != 0 && i != n - 1) return@forEachIndexed
                drawContext.canvas.nativeCanvas.drawText(formatDayMonth(r.date), xOf(i), size.height - 4 * dp, text)
            }
        }
    }
}

private fun niceStep(raw: Double): Double {
    val candidates = listOf(1.0, 2.0, 5.0, 10.0, 20.0, 25.0, 50.0)
    return candidates.firstOrNull { it >= raw } ?: max(50.0, ceil(raw / 50) * 50)
}

@Composable
private fun AveragesCard(rounds: List<Round>, data: GolfData) {
    val fw = rounds.filter { it.fairwayOpportunities(data.course(it.courseId)) > 0 }
    val fwText = if (fw.isEmpty()) "-" else pct(fw.sumOf { it.fairwaysHit }, fw.sumOf { it.fairwayOpportunities(data.course(it.courseId)) })
    val gir = rounds.filter { it.girOpportunities > 0 }
    val girText = if (gir.isEmpty()) "-" else pct(gir.sumOf { it.greensInRegulation }, gir.sumOf { it.girOpportunities })
    val strokes = fmt1(rounds.sumOf { it.totalStrokes }.toDouble() / rounds.size)

    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Text("Durchschnittswerte", color = AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold)
        StatRow("Fairways getroffen", fwText)
        HorizontalDivider(color = AppTheme.textTer.copy(alpha = 0.4f))
        StatRow("Greens in Regulation", girText)
        HorizontalDivider(color = AppTheme.textTer.copy(alpha = 0.4f))
        StatRow("Ø Schläge pro Runde", strokes)
    }
}

@Composable
private fun StatRow(label: String, value: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(label, color = AppTheme.textSec, fontSize = IosFont.body, modifier = Modifier.weight(1f))
        Text(value, color = AppTheme.text, fontSize = IosFont.body, fontWeight = FontWeight.Bold)
    }
}

private data class ClubStat(val club: String, val avgMeters: Double, val count: Int)

private fun clubStats(rounds: List<Round>): List<ClubStat> =
    rounds.flatMap { r -> r.holeScores.flatMap { it.shots } }
        .filter { it.club.isNotEmpty() && it.distanceMeters > 1 }
        .groupBy { it.club }
        .map { (club, shots) -> ClubStat(club, shots.sumOf { it.distanceMeters } / shots.size, shots.size) }
        .sortedByDescending { it.avgMeters }

@Composable
private fun ClubDistanceCard(stats: List<ClubStat>, unit: app.golftrack.data.DistanceUnit) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.SportsGolf, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(6.dp))
            Text("Schlägerdistanzen (Ø)", color = AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold)
        }
        stats.forEachIndexed { i, s ->
            if (i > 0) HorizontalDivider(color = AppTheme.textTer.copy(alpha = 0.4f))
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(s.club, color = AppTheme.text, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold)
                    Text("${s.count} ${if (s.count == 1) "Schlag" else "Schläge"} gemessen", color = AppTheme.textSec, fontSize = IosFont.caption)
                }
                Text(unit.format(s.avgMeters), color = AppTheme.gold, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold)
            }
        }
    }
}
