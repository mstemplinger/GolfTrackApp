package app.golftrack.feature.golf

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.OpenInFull
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material.icons.filled.SportsScore
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.TableChart
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.LatLon
import app.golftrack.data.Round
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LaterBadge
import app.golftrack.ui.common.LaterFeature
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme
import java.util.Locale

// MARK: - Platzinfo

/** Wie CourseInfoSheet.swift: Scorecard (HCP, Längen, Par), Platzhinweise, Platzdaten. */
@Composable
fun CourseInfoSheet(course: Course, onDismiss: () -> Unit) {
    val hasHoleData = course.hcpValues.isNotEmpty() && course.holeLengths.isNotEmpty()
    FullSheet(onDismiss) {
        Column(Modifier.fillMaxSize()) {
            SheetTopBar("Platzinfo", trailing = { BarButton("Fertig") { Haptics.tap(); onDismiss() } })
            Column(
                Modifier.verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 12.dp).navigationBarsPadding(),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                if (hasHoleData) {
                    Column {
                        InfoSectionHeader(Icons.Filled.TableChart, "Scorecard")
                        Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))) {
                            TableRow("Loch", "HCP", "Meter", "Par", header = true)
                            HorizontalDivider(color = AppTheme.cardAlt)
                            val holes = course.numberOfHoles
                            for (h in 1..9) {
                                TableRow("$h", hcpText(course, h), lengthText(course, h), parText(course, h))
                                if (h < 9) HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(start = 16.dp))
                            }
                            SumRow("OUT", course.holeLengths.takeIf { it.size >= 9 }?.take(9)?.sum()?.let { "$it m" }, course.parValues.takeIf { it.size >= 9 }?.take(9)?.sum())
                            HorizontalDivider(color = AppTheme.cardAlt)
                            if (holes > 9) {
                                for (h in 10..18) {
                                    TableRow("$h", hcpText(course, h), lengthText(course, h), parText(course, h))
                                    if (h < 18) HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(start = 16.dp))
                                }
                                SumRow("IN", course.holeLengths.takeIf { it.size >= 18 }?.drop(9)?.sum()?.let { "$it m" }, course.parValues.takeIf { it.size >= 18 }?.drop(9)?.sum())
                                HorizontalDivider(color = AppTheme.cardAlt)
                            }
                            SumRow("GESAMT", course.holeLengths.takeIf { it.size >= holes && holes > 0 }?.sum()?.let { "$it m" }, course.totalPar, total = true)
                        }
                    }
                }
                if (course.facilityNotes.isNotEmpty()) {
                    Column {
                        InfoSectionHeader(Icons.Filled.Info, "Platzhinweise")
                        val lines = course.facilityNotes.lines().map { it.trim() }.filter { it.isNotEmpty() }
                        Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))) {
                            lines.forEachIndexed { i, line ->
                                Row(Modifier.padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.Top) {
                                    Icon(facilityIcon(line), null, tint = AppTheme.gold, modifier = Modifier.width(20.dp).size(16.dp).padding(top = 1.dp))
                                    Spacer(Modifier.width(12.dp))
                                    Text(line, color = AppTheme.text, fontSize = 15.sp)
                                }
                                if (i < lines.lastIndex) HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(start = 48.dp))
                            }
                        }
                    }
                }
                Column {
                    InfoSectionHeader(Icons.Filled.BarChart, "Platzdaten")
                    Row(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)), verticalAlignment = Alignment.CenterVertically) {
                        StatCell("${course.numberOfHoles}", "Löcher")
                        VerticalDivider(Modifier.height(40.dp), color = AppTheme.cardAlt)
                        StatCell("Par ${course.totalPar}", "Gesamt")
                        VerticalDivider(Modifier.height(40.dp), color = AppTheme.cardAlt)
                        StatCell(String.format(Locale.GERMANY, "%.1f", course.courseRating), "CR")
                        VerticalDivider(Modifier.height(40.dp), color = AppTheme.cardAlt)
                        StatCell("${course.slopeRating}", "Slope")
                    }
                }
            }
        }
    }
}

private fun hcpText(c: Course, h: Int) = c.hcpValues.getOrNull(h - 1)?.toString() ?: "–"
private fun lengthText(c: Course, h: Int) = c.holeLengths.getOrNull(h - 1)?.let { "$it m" } ?: "–"
private fun parText(c: Course, h: Int) = c.parValues.getOrNull(h - 1)?.toString() ?: "–"

private fun facilityIcon(line: String): ImageVector {
    val l = line.lowercase()
    return when {
        "toilette" in l -> Icons.AutoMirrored.Filled.DirectionsWalk
        "trinkwasser" in l -> Icons.Filled.WaterDrop
        "defibrillator" in l -> Icons.Filled.Favorite
        "entfernungs" in l -> Icons.Filled.Straighten
        "biotop" in l -> Icons.Filled.Spa
        "platzregel" in l -> Icons.Filled.Warning
        "lochspiel" in l || "zählspiel" in l -> Icons.Filled.Flag
        "kontakt" in l || "www." in l -> Icons.Filled.Language
        else -> Icons.Filled.Info
    }
}

@Composable
private fun InfoSectionHeader(icon: ImageVector, title: String) {
    Row(Modifier.padding(horizontal = 4.dp).padding(top = 4.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(13.dp))
        Spacer(Modifier.width(6.dp))
        Text(title.uppercase(), color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
    }
}

@Composable
private fun TableRow(hole: String, hcp: String, length: String, par: String, header: Boolean = false) {
    val size = if (header) 12.sp else 16.sp
    val weight = if (header) FontWeight.Bold else FontWeight.Normal
    val parColor = when { header -> AppTheme.textSec; par == "3" -> IosColors.blue; par == "5" -> AppTheme.gold; else -> AppTheme.text }
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(hole, color = if (header) AppTheme.textSec else AppTheme.text, fontSize = size, fontWeight = weight, modifier = Modifier.width(44.dp))
        Spacer(Modifier.weight(1f))
        Text(hcp, color = AppTheme.textSec, fontSize = size, fontWeight = weight, textAlign = TextAlign.Center, modifier = Modifier.width(44.dp))
        Text(length, color = if (header) AppTheme.textSec else AppTheme.text, fontSize = size, fontWeight = weight, textAlign = TextAlign.End, modifier = Modifier.width(64.dp))
        Text(par, color = parColor, fontSize = size, fontWeight = FontWeight.Bold, textAlign = TextAlign.End, modifier = Modifier.width(40.dp))
    }
}

@Composable
private fun SumRow(label: String, length: String?, par: Int?, total: Boolean = false) {
    val c = if (total) AppTheme.gold else AppTheme.textSec
    Row(
        Modifier.fillMaxWidth().background(if (total) AppTheme.gold.copy(alpha = 0.07f) else AppTheme.cardAlt.copy(alpha = 0.5f))
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, color = c, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.width(60.dp))
        Spacer(Modifier.weight(1f))
        Text(length ?: "–", color = c, fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.End, modifier = Modifier.width(64.dp))
        Text(par?.toString() ?: "–", color = c, fontSize = 12.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.End, modifier = Modifier.width(40.dp))
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.StatCell(value: String, label: String) {
    Column(Modifier.weight(1f).padding(vertical = 14.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(value, color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
        Text(label, color = AppTheme.textSec, fontSize = 12.sp)
    }
}

// MARK: - Runde abgeschlossen

/**
 * Wie RoundCompleteSheet.swift. Statt der Audio-Empfehlungen aus dem Training
 * (auf Android noch nicht enthalten) ein Hinweis mit „Später"-Abzeichen; ohne
 * Game Center.
 */
@Composable
fun RoundCompleteSheet(nav: NavController, round: Round, course: Course?, onDone: () -> Unit, onShowDetail: () -> Unit) {
    val pulseT = rememberInfiniteTransition(label = "pulse")
    val pulse by pulseT.animateFloat(0f, 1f, infiniteRepeatable(tween(1100), RepeatMode.Reverse), label = "p")

    FullSheet(onDone) {
        Column(Modifier.fillMaxSize().statusBarsPadding()) {
            Column(
                Modifier.weight(1f).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                // Kopf
                Column(Modifier.fillMaxWidth().padding(top = 32.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Box(Modifier.size(72.dp).background(AppTheme.gold.copy(alpha = 0.15f), CircleShape), contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.SportsScore, null, tint = AppTheme.gold, modifier = Modifier.size(34.dp))
                    }
                    Text("Runde abgeschlossen!", color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    if (course != null) Text(course.name, color = AppTheme.textSec, fontSize = 15.sp)
                }
                // Score-Karte
                Row(
                    Modifier.padding(horizontal = 16.dp).fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))
                        .padding(vertical = 14.dp, horizontal = 24.dp),
                    horizontalArrangement = Arrangement.spacedBy(24.dp, Alignment.CenterHorizontally),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    ScoreBox("${round.totalStrokes}", "Schläge")
                    if (round.totalPutts > 0) {
                        VerticalDivider(Modifier.height(40.dp), color = AppTheme.cardAlt)
                        ScoreBox("${round.totalPutts}", "Putts")
                    }
                    VerticalDivider(Modifier.height(40.dp), color = AppTheme.cardAlt)
                    ScoreBox("${round.holeScores.size}", "Löcher")
                }
                // Audio-Training zur Runde – kommt auf Android später
                Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Headphones, null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Passend zu dieser Runde", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                        LaterBadge()
                    }
                    Text("Audio-Lektionen, die genau die Schwächen dieser Runde angehen", color = AppTheme.textSec, fontSize = 12.sp)
                    Row(
                        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))
                            .clickable { Haptics.tap(); nav.navigate(Routes.comingLater(LaterFeature.AUDIOBOOKS)) }.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(Modifier.size(52.dp).background(AppTheme.gold.copy(alpha = 0.18f), RoundedCornerShape(12.dp)), contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.Headphones, null, tint = AppTheme.gold, modifier = Modifier.size(22.dp))
                        }
                        Spacer(Modifier.width(14.dp))
                        Column(Modifier.weight(1f)) {
                            Text(LaterFeature.AUDIOBOOKS.title, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                            Text(LaterFeature.AUDIOBOOKS.text, color = AppTheme.textSec, fontSize = 12.sp)
                        }
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer)
                    }
                }
                // Runde im Detail
                Text(
                    "Runde im Detail ansehen", color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().clickable { Haptics.tap(); onShowDetail() }.padding(vertical = 8.dp),
                )
                Spacer(Modifier.height(8.dp))
            }
            // Fertig
            Box(Modifier.fillMaxWidth().background(AppTheme.bg).padding(horizontal = 16.dp, vertical = 8.dp).navigationBarsPadding()) {
                Box(
                    Modifier.fillMaxWidth().scale(1f + 0.03f * pulse)
                        .background(AppTheme.gold.copy(alpha = 0.7f + 0.3f * pulse), RoundedCornerShape(14.dp))
                        .clickable { Haptics.tap(); onDone() }.padding(vertical = 16.dp),
                    contentAlignment = Alignment.Center,
                ) { Text("Fertig", color = Color.Black, fontSize = 17.sp, fontWeight = FontWeight.Bold) }
            }
        }
    }
}

@Composable
private fun ScoreBox(value: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(value, color = AppTheme.gold, fontSize = 32.sp, fontWeight = FontWeight.Bold)
        Text(label, color = AppTheme.textSec, fontSize = 12.sp)
    }
}

// MARK: - Schläge auf der Karte (für die Rundendetails)

private val holePalette = listOf(
    Color(0xFF3385F5), Color(0xFFF58533), Color(0xFF38C761), Color(0xFFC74DF5), Color(0xFFF54747),
    Color(0xFF1ACCC7), Color(0xFFD9B333), Color(0xFF66CC66), Color(0xFFE66699), Color(0xFF6666E6),
)

/**
 * Wie RoundShotMapCard in RoundShotMapView.swift – kompakte Karte aller
 * getrackten Schläge, Farbe je Loch, mit Vollbild. Öffentlich, damit die
 * Rundendetails (anderes Paket) sie einbinden können.
 */
@Composable
fun RoundShotMapCard(round: Round, modifier: Modifier = Modifier) {
    var expanded by remember { mutableStateOf(false) }
    var satellite by remember { mutableStateOf(false) }
    val holes = round.sortedScores.filter { it.sortedShots.isNotEmpty() }
    val colored = holes.mapIndexed { i, hs -> hs to holePalette[i % holePalette.size] }
    if (colored.isEmpty()) return

    fun items(): List<MapItem> = buildList {
        colored.forEach { (hs, c) ->
            hs.sortedShots.forEach { s ->
                add(MapItem.Line(listOf(s.from, s.to), c.copy(alpha = 0.85f), 2.5f))
                add(MapItem.Dot(s.to, c.copy(alpha = 0.75f), sizeDp = 9, border = Color.White))
                add(MapItem.Dot(s.from, c, sizeDp = 22, text = "${s.shotNumber}"))
            }
        }
    }
    val allPoints: List<LatLon> = colored.flatMap { (hs, _) -> hs.sortedShots.flatMap { listOf(it.from, it.to) } }

    @Composable
    fun legend(bold: Boolean) {
        if (colored.size > 1) {
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                colored.forEach { (hs, c) ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(8.dp).background(c, CircleShape))
                        Spacer(Modifier.width(5.dp))
                        Text("Loch ${hs.holeNumber}", color = if (bold) AppTheme.text else AppTheme.textSec, fontSize = if (bold) 12.sp else 11.sp,
                            fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal)
                    }
                }
            }
        }
    }

    Column(modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Map, null, tint = AppTheme.text, modifier = Modifier.size(16.dp))
            Spacer(Modifier.width(6.dp))
            Text("Schläge auf der Karte", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            Row(Modifier.clickable { Haptics.tap(); expanded = true }, verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.OpenInFull, null, tint = AppTheme.gold, modifier = Modifier.size(12.dp))
                Spacer(Modifier.width(4.dp))
                Text("Vollbild", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
        }
        Box(Modifier.fillMaxWidth().height(220.dp).background(AppTheme.cardDark, RoundedCornerShape(12.dp))) {
            GolfMap(items(), Modifier.matchParentSize(), satellite = satellite, interactive = false, initialFit = allPoints)
            // Kompakte Karte nimmt keine Gesten an – Tippen öffnet das Vollbild.
            Box(Modifier.matchParentSize().clickable { Haptics.tap(); expanded = true })
        }
        legend(false)
    }

    if (expanded) {
        FullSheet({ expanded = false }) {
            Column(Modifier.fillMaxSize()) {
                SheetTopBar(
                    "Schlagkarte",
                    leading = { BarButton("Schließen") { Haptics.tap(); expanded = false } },
                    trailing = { SatelliteToggle(satellite) { satellite = !satellite } },
                )
                GolfMap(items(), Modifier.weight(1f).fillMaxWidth(), satellite = satellite, initialFit = allPoints)
                if (colored.size > 1) {
                    Box(Modifier.fillMaxWidth().background(AppTheme.cardDark).padding(horizontal = 16.dp, vertical = 10.dp).navigationBarsPadding()) { legend(true) }
                }
            }
        }
    }
}
