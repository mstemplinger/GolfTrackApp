package app.golftrack.feature.records

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.filled.AutoFixHigh
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.OpenInFull
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.SettingsInputAntenna
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.golftrack.data.Course
import app.golftrack.data.DistanceUnit
import app.golftrack.data.LatLon
import app.golftrack.data.Round
import app.golftrack.data.rememberPrefString
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

/** Farbfolge je Loch – gleich in Schlag- und Laufkarte (wie auf iOS). */
internal val holePalette = listOf(
    Color(0.20f, 0.52f, 0.96f), Color(0.96f, 0.52f, 0.20f), Color(0.22f, 0.78f, 0.38f),
    Color(0.78f, 0.30f, 0.96f), Color(0.96f, 0.28f, 0.28f), Color(0.10f, 0.80f, 0.78f),
    Color(0.85f, 0.70f, 0.20f), Color(0.40f, 0.80f, 0.40f), Color(0.90f, 0.40f, 0.60f),
    Color(0.40f, 0.40f, 0.90f),
)

@Composable
internal fun rememberDistanceUnit(): DistanceUnit {
    val raw by rememberPrefString("distanceUnit", DistanceUnit.METERS.raw)
    return DistanceUnit.fromRaw(raw)
}

@Composable
private fun CardHeader(icon: ImageVector, title: String, onExpand: (() -> Unit)?) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(6.dp))
        Text(title, color = AppTheme.text, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
        if (onExpand != null) {
            Row(
                Modifier.clickable { Haptics.tap(); onExpand() }.padding(4.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Icon(Icons.Filled.OpenInFull, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(13.dp))
                Text("Vollbild", color = AppTheme.gold, fontSize = IosFont.caption, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun HoleLegend(holes: List<Pair<Int, Color>>, large: Boolean = false) {
    Row(
        Modifier.horizontalScroll(rememberScrollState()).then(if (large) Modifier.padding(horizontal = 16.dp, vertical = 10.dp) else Modifier),
        horizontalArrangement = Arrangement.spacedBy(if (large) 12.dp else 10.dp),
    ) {
        holes.forEach { (n, c) ->
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                Box(Modifier.size(if (large) 9.dp else 8.dp).background(c, CircleShape))
                Text(
                    "Loch $n", color = if (large) AppTheme.text else AppTheme.textSec,
                    fontSize = if (large) IosFont.caption else IosFont.caption2,
                    fontWeight = if (large) FontWeight.Bold else FontWeight.Normal,
                )
            }
        }
    }
}

// MARK: - Schläge auf der Karte (RoundShotMapCard)

private data class ShotItem(val shotNumber: Int, val holeNumber: Int, val from: LatLon, val to: LatLon, val color: Color)

@Composable
internal fun RoundShotMapCard(round: Round) {
    var expanded by remember { mutableStateOf(false) }
    val items = remember(round) {
        round.sortedScores.filter { it.sortedShots.isNotEmpty() }.flatMapIndexed { i, hs ->
            val c = holePalette[i % holePalette.size]
            hs.sortedShots.map { ShotItem(it.shotNumber, hs.holeNumber, it.from, it.to, c) }
        }.filter { it.from.isValid && it.to.isValid }
    }
    val holes = items.map { it.holeNumber to it.color }.distinctBy { it.first }
    val lines = items.map { MapLine(listOf(it.from, it.to), it.color.copy(alpha = 0.85f), 2.5f) }
    val pins = items.flatMap {
        listOf(
            MapPin(it.to, PinStyle.Dot(it.color.copy(alpha = 0.75f), 9f, 1.5f)),
            MapPin(it.from, PinStyle.Numbered(it.color, "${it.shotNumber}")),
        )
    }

    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        CardHeader(Icons.Filled.Map, "Schläge auf der Karte") { expanded = true }
        OsmMap(
            Modifier.fillMaxWidth().height(220.dp).clip(RoundedCornerShape(12.dp)),
            satellite = false, interactive = false, lines = lines, pins = pins,
        )
        if (holes.size > 1) HoleLegend(holes)
    }

    if (expanded) {
        FullscreenMapDialog(
            title = "Schlagkarte", initialSatellite = false, onClose = { expanded = false },
            bottom = if (holes.size > 1) ({ HoleLegend(holes, large = true) }) else null,
        ) { sat, m -> OsmMap(m, satellite = sat, interactive = true, lines = lines, pins = pins) }
    }
}

// MARK: - Laufspur (RoundTrackMapCard)

private data class TrackSegment(val hole: Int, val coords: List<LatLon>, val color: Color)
private data class TrackStats(val distance: Double, val duration: Double, val pointCount: Int, val holeCount: Int)

@Composable
internal fun RoundTrackMapCard(round: Round, course: Course?, onDeriveGeometry: (Course) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    val unit = rememberDistanceUnit()
    val (segments, stats) = remember(round.track) { loadTrack(round) }

    val lines = segments.map { MapLine(it.coords, it.color.copy(alpha = 0.85f), 3f) }
    val pins = buildList {
        segments.firstOrNull()?.coords?.firstOrNull()?.let { add(MapPin(it, PinStyle.Dot(IosColor.green), "Start")) }
        segments.lastOrNull()?.coords?.lastOrNull()?.let { add(MapPin(it, PinStyle.Dot(IosColor.red), "Ende")) }
    }

    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        CardHeader(Icons.AutoMirrored.Filled.DirectionsWalk, "Laufspur", if (segments.isNotEmpty()) ({ expanded = true }) else null)
        if (segments.isEmpty()) {
            Text("Für diese Runde liegen noch keine verwertbaren GPS-Punkte vor.", color = AppTheme.textSec, fontSize = IosFont.caption)
        } else {
            OsmMap(
                Modifier.fillMaxWidth().height(220.dp).clip(RoundedCornerShape(12.dp)),
                satellite = true, interactive = false, lines = lines, pins = pins,
            )
            stats?.let { s ->
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp), modifier = Modifier.horizontalScroll(rememberScrollState())) {
                    StatItem(Icons.AutoMirrored.Filled.DirectionsWalk, unit.format(s.distance))
                    StatItem(Icons.Filled.Schedule, durationText(s.duration))
                    StatItem(Icons.Filled.Flag, "${s.holeCount} Löcher")
                    StatItem(Icons.Filled.SettingsInputAntenna, "${s.pointCount} Punkte")
                }
            }
            if (course != null) {
                Row(
                    Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(12.dp))
                        .clickable { Haptics.tap(); onDeriveGeometry(course) }.padding(vertical = 11.dp),
                    horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.AutoFixHigh, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Loch-Positionen ableiten", color = AppTheme.gold, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold)
                }
            }
        }
    }

    if (expanded) {
        FullscreenMapDialog(title = "Laufspur", initialSatellite = true, onClose = { expanded = false }) { sat, m ->
            OsmMap(m, satellite = sat, interactive = true, lines = lines, pins = pins)
        }
    }
}

private fun loadTrack(round: Round): Pair<List<TrackSegment>, TrackStats?> {
    val track = round.track ?: return emptyList<TrackSegment>() to null
    val points = track.points.filter { it.isValid }.sortedBy { it.timeOffset }
    if (points.size < 2) return emptyList<TrackSegment>() to null
    // Nach Loch gruppieren, Reihenfolge der Löcher wie gespielt.
    val order = mutableListOf<Int>()
    val grouped = mutableMapOf<Int, MutableList<LatLon>>()
    for (p in points) {
        grouped.getOrPut(p.holeNumber) { order.add(p.holeNumber); mutableListOf() }.add(p.coordinate)
    }
    val segments = order.mapIndexedNotNull { i, hole ->
        val coords = grouped[hole] ?: return@mapIndexedNotNull null
        if (coords.size < 2) null
        else TrackSegment(hole, coords, if (hole == 0) AppTheme.textTer else holePalette[i % holePalette.size])
    }
    val stats = TrackStats(track.totalDistanceMeters, track.durationSeconds, points.size, order.count { it > 0 })
    return segments to stats
}

private fun durationText(seconds: Double): String {
    val total = seconds.toInt()
    val h = total / 3600
    val m = (total % 3600) / 60
    return if (h > 0) "$h h $m min" else "$m min"
}

@Composable
private fun StatItem(icon: ImageVector, value: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Icon(icon, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(12.dp))
        Text(value, color = AppTheme.textSec, fontSize = IosFont.caption2)
    }
}
