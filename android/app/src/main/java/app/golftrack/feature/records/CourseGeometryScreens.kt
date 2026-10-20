package app.golftrack.feature.records

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.LocationOff
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.Polyline
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.SquareFoot
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.GolfStore
import app.golftrack.data.Prefs
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.GoldButton
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.builtins.ListSerializer

/** In dieser Sitzung übernommene Löcher je Platz (für das Häkchen in der Liste). */
private object AppliedHoles {
    val byCourse = mutableStateMapOf<String, Set<Int>>()
    fun add(courseId: String, holes: Collection<Int>) {
        byCourse[courseId] = (byCourse[courseId] ?: emptySet()) + holes
    }
}

private fun applySuggestions(course: Course, items: List<HoleGeometrySuggestion>, minConfidence: Double) {
    val current = GolfStore.current.course(course.id) ?: course
    val (updated, applied) = CourseGeometryInference.apply(items, current, minConfidence)
    if (applied <= 0) return
    GolfStore.upsertCourse(updated)
    AppliedHoles.add(course.id, items.filter {
        it.isPlausible && ((it.tee != null && it.teeConfidence >= minConfidence) || (it.green != null && it.greenConfidence >= minConfidence))
    }.map { it.holeNumber })
}

@Composable
private fun rememberSuggestions(course: Course?): Pair<Boolean, List<HoleGeometrySuggestion>> {
    val rounds = GolfStore.data.collectAsState().value.rounds
    var calculating by remember { mutableStateOf(true) }
    var result by remember { mutableStateOf<List<HoleGeometrySuggestion>>(emptyList()) }
    LaunchedEffect(course?.id, course?.numberOfHoles, course?.holeLengths, rounds.size) {
        if (course == null) { calculating = false; return@LaunchedEffect }
        result = withContext(Dispatchers.Default) { CourseGeometryInference.suggestions(course, rounds) }
        calculating = false
    }
    return calculating to result
}

/** Wie CourseGeometryReviewView.swift. */
@Composable
internal fun CourseGeometryReviewScreen(nav: NavController, courseId: String) {
    val data by GolfStore.data.collectAsState()
    val course = data.course(courseId)
    val (calculating, suggestions) = rememberSuggestions(course)
    val usable = suggestions.filter { it.hasUsableSuggestion }
    val highCount = usable.count { it.isPlausible && minOf(it.teeConfidence, it.greenConfidence) >= 0.7 }
    val applied = AppliedHoles.byCourse[courseId] ?: emptySet()
    val unit = rememberDistanceUnit()

    AppScaffold(
        "Loch-Positionen", onBack = { nav.popBackStack() },
        actions = { ToolbarTextButton("Fertig", bold = true) { Haptics.tap(); nav.popBackStack() } },
    ) { m ->
        when {
            course == null -> EmptyState(Icons.Filled.LocationOff, "Platz nicht gefunden", "Dieser Platz wurde gelöscht.", m)
            calculating -> Box(m, contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    CircularProgressIndicator(color = AppTheme.gold)
                    Text("Laufspuren werden ausgewertet …", color = AppTheme.textSec)
                }
            }
            usable.isEmpty() -> EmptyState(
                Icons.AutoMirrored.Filled.DirectionsWalk, "Noch keine Daten zum Ableiten",
                "Aktiviere das Positions-Tracking in den Einstellungen und spiele eine Runde auf diesem Platz. Danach können Abschlag und Grün pro Loch geschätzt werden.",
                m,
            )
            else -> Column(m) {
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(vertical = 8.dp)) {
                    Column(
                        Modifier.fillMaxWidth().padding(horizontal = 16.dp).background(AppTheme.cardDark, RoundedCornerShape(12.dp)).padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Text("Wie das funktioniert", color = AppTheme.text, fontSize = IosFont.caption, fontWeight = FontWeight.Bold)
                        Text(
                            "Am Abschlag und am Grün stehst du still, dazwischen bewegst du dich. Aus dem ersten und letzten längeren Stillstand pro Loch werden Abschlag und Grün geschätzt. Getrackte Schläge und selbst gesetzte Pins zählen stärker als die Laufspur.",
                            color = AppTheme.textSec, fontSize = IosFont.caption,
                        )
                        Text(
                            "Je mehr Runden auf diesem Platz aufgezeichnet sind, desto genauer wird die Schätzung. Prüfe Vorschläge mit niedriger Konfidenz auf der Karte, bevor du sie übernimmst.",
                            color = AppTheme.textSec, fontSize = IosFont.caption,
                        )
                    }

                    SectionHeader("${usable.size} von ${course.numberOfHoles} Löchern ableitbar", Modifier.padding(top = 20.dp))
                    GroupCard {
                        usable.forEachIndexed { i, s ->
                            if (i > 0) FormDivider()
                            Row(
                                Modifier.fillMaxWidth().clickable { Haptics.tap(); nav.navigate(RecordsInternalRoutes.geometryHole(course.id, s.holeNumber)) }
                                    .padding(horizontal = 16.dp, vertical = 10.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                SuggestionRow(s, s.holeNumber in applied, unit, Modifier.weight(1f))
                                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = AppTheme.textTer)
                            }
                        }
                    }
                    SectionFooter("Bereits gespeichert: ${course.holePositionCount} von ${course.numberOfHoles} Löchern.")

                    if (course.holePositionCount > 0) {
                        Spacer(Modifier.height(20.dp))
                        GroupCard {
                            Row(
                                Modifier.fillMaxWidth().clickable { Haptics.tap(); nav.navigate(RecordsInternalRoutes.fairway(course.id)) }
                                    .padding(horizontal = 16.dp, vertical = 14.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Icon(Icons.Filled.Polyline, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(22.dp))
                                Spacer(Modifier.width(14.dp))
                                Text("Fairway-Verlauf", color = AppTheme.text, fontSize = IosFont.body, modifier = Modifier.weight(1f))
                                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = AppTheme.textTer)
                            }
                        }
                        SectionFooter("Schätzt aus den Messpunkten zwischen Abschlag und Grün, wo das Fairway ungefähr verläuft. Braucht gespeicherte Loch-Positionen.")
                    }
                }
                // Aktionsleiste unten
                Column(
                    Modifier.fillMaxWidth().background(AppTheme.cardDark).navigationBarsPadding().padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    GoldButton(
                        if (highCount > 0) "Hohe Konfidenz übernehmen ($highCount)" else "Keine Löcher mit hoher Konfidenz",
                        enabled = highCount > 0,
                    ) { Haptics.success(); applySuggestions(course, usable, 0.7) }
                    Text(
                        "Alle plausiblen Vorschläge übernehmen", color = AppTheme.text, fontSize = IosFont.subheadline,
                        fontWeight = FontWeight.Bold, textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(12.dp))
                            .clickable { Haptics.success(); applySuggestions(course, usable, 0.4) }.padding(vertical = 12.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun SuggestionRow(s: HoleGeometrySuggestion, applied: Boolean, unit: app.golftrack.data.DistanceUnit, modifier: Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Loch ${s.holeNumber}", color = AppTheme.text, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold)
            ConfidenceBadge(s.confidenceLevel)
            Spacer(Modifier.weight(1f))
            if (applied) Icon(Icons.Filled.CheckCircle, contentDescription = "Übernommen", tint = AppTheme.gold, modifier = Modifier.size(20.dp))
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Marker("Abschlag", s.tee != null)
            Marker("Grün", s.green != null)
            s.measuredLengthMeters?.let { Text("Länge ${unit.format(it)}", color = AppTheme.textSec, fontSize = IosFont.caption2) }
        }
        val expected = s.expectedLengthMeters
        val dev = s.lengthDeviation
        if (expected != null && dev != null) {
            val color = if (s.isPlausible) AppTheme.textSec else IosColor.orange
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Icon(
                    if (s.isPlausible) Icons.Filled.Verified else Icons.Filled.Warning, contentDescription = null,
                    tint = if (s.isPlausible) AppTheme.green else IosColor.orange, modifier = Modifier.size(12.dp),
                )
                Text("Scorecard: $expected m · Abweichung ${(dev * 100).toInt()} %", color = color, fontSize = IosFont.caption2)
            }
        }
        Text(
            "Runden: ${s.roundCount} · Streuung ±${maxOf(s.teeSpreadMeters, s.greenSpreadMeters).toInt()} m",
            color = AppTheme.textTer, fontSize = IosFont.caption2,
        )
    }
}

@Composable
private fun ConfidenceBadge(level: HoleGeometrySuggestion.ConfidenceLevel) {
    when (level) {
        HoleGeometrySuggestion.ConfidenceLevel.HIGH -> CapsuleBadge("hoch", AppTheme.green)
        HoleGeometrySuggestion.ConfidenceLevel.MEDIUM -> CapsuleBadge("mittel", AppTheme.gold)
        HoleGeometrySuggestion.ConfidenceLevel.LOW -> CapsuleBadge("niedrig", IosColor.orange)
    }
}

@Composable
private fun Marker(label: String, available: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(3.dp)) {
        Icon(
            if (available) Icons.Filled.Place else Icons.Filled.LocationOff, contentDescription = null,
            tint = if (available) AppTheme.gold else AppTheme.textTer, modifier = Modifier.size(12.dp),
        )
        Text(label, color = if (available) AppTheme.textSec else AppTheme.textTer, fontSize = IosFont.caption2)
    }
}

/** Detailansicht eines Lochs mit Karte – wie `HoleGeometryDetailView`. */
@Composable
internal fun HoleGeometryDetailScreen(nav: NavController, courseId: String, hole: Int) {
    val data by GolfStore.data.collectAsState()
    val course = data.course(courseId)
    val (calculating, suggestions) = rememberSuggestions(course)
    val s = suggestions.firstOrNull { it.holeNumber == hole }
    val unit = rememberDistanceUnit()
    var didApply by rememberSaveable { mutableStateOf(false) }

    AppScaffold("Loch $hole", onBack = { nav.popBackStack() }) { m ->
        if (course == null || s == null) {
            Box(m, contentAlignment = Alignment.Center) {
                if (calculating) CircularProgressIndicator(color = AppTheme.gold)
                else Text("Keine Daten für dieses Loch", color = AppTheme.textSec)
            }
            return@AppScaffold
        }
        val tracks = data.rounds.filter { it.courseId == course.id }.mapNotNull { r ->
            val coords = r.track?.points(hole)?.filter { it.isValid }?.sortedBy { it.timeOffset }?.map { it.coordinate }
            coords?.takeIf { it.size > 1 }
        }
        val lines = buildList {
            tracks.forEach { add(MapLine(it, AppTheme.textTer, 2f)) }
            if (s.tee != null && s.green != null) add(MapLine(listOf(s.tee, s.green), AppTheme.gold.copy(alpha = 0.8f), 2f, dashed = true))
        }
        val pins = buildList {
            course.flagCoordinate(hole)?.let { add(MapPin(it, PinStyle.Ring(AppTheme.gold), "gespeichert")) }
            s.tee?.let { add(MapPin(it, PinStyle.Symbol(IosColor.blue, PinSymbol.TEE), "Abschlag")) }
            s.green?.let { add(MapPin(it, PinStyle.Symbol(IosColor.red, PinSymbol.FLAG), "Grün")) }
        }
        Column(m) {
            OsmMap(Modifier.fillMaxWidth().weight(1f), satellite = true, interactive = true, lines = lines, pins = pins, fitKey = hole)
            Column(
                Modifier.fillMaxWidth().background(AppTheme.card).navigationBarsPadding().padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    val label = when (s.confidenceLevel) {
                        HoleGeometrySuggestion.ConfidenceLevel.HIGH -> "Konfidenz: hoch"
                        HoleGeometrySuggestion.ConfidenceLevel.MEDIUM -> "Konfidenz: mittel"
                        HoleGeometrySuggestion.ConfidenceLevel.LOW -> "Konfidenz: niedrig"
                    }
                    Text(label, color = AppTheme.text, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                    Text("Runden: ${s.roundCount}", color = AppTheme.textSec, fontSize = IosFont.caption)
                }
                s.measuredLengthMeters?.let { measured ->
                    val t = s.expectedLengthMeters?.let { "Abgeleitete Länge: ${unit.format(measured)} · Scorecard: $it m" }
                        ?: "Abgeleitete Länge: ${unit.format(measured)}"
                    Text(t, color = AppTheme.textSec, fontSize = IosFont.caption)
                }
                if (!s.isPlausible) {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Icon(Icons.Filled.Warning, contentDescription = null, tint = IosColor.orange, modifier = Modifier.size(16.dp))
                        Text(
                            "Die abgeleitete Länge passt nicht zur Scorecard – hier steckt wahrscheinlich ein GPS-Ausreißer oder ein falsch zugeordnetes Loch drin.",
                            color = IosColor.orange, fontSize = IosFont.caption,
                        )
                    }
                }
                GoldButton(if (didApply) "Übernommen" else "Für dieses Loch übernehmen", enabled = !didApply) {
                    Haptics.success()
                    applySuggestions(course, listOf(s), 0.0)
                    didApply = true
                }
            }
        }
    }
}

// MARK: - Fairway-Verlauf

private fun corridorPrefKey(courseId: String) = "fairwayCorridors.$courseId"
private val corridorSerializer = ListSerializer(HoleCorridor.serializer())

private fun loadStoredCorridors(courseId: String): List<HoleCorridor> =
    runCatching { GolfStore.json.decodeFromString(corridorSerializer, Prefs.string(corridorPrefKey(courseId), "[]")) }.getOrDefault(emptyList())

private fun storeCorridors(courseId: String, list: List<HoleCorridor>) =
    Prefs.set(corridorPrefKey(courseId), GolfStore.json.encodeToString(corridorSerializer, list))

/** Wie FairwayCorridorView.swift. */
@Composable
internal fun FairwayCorridorScreen(nav: NavController, courseId: String) {
    val data by GolfStore.data.collectAsState()
    val course = data.course(courseId)
    val unit = rememberDistanceUnit()
    val scope = rememberCoroutineScope()
    var corridors by remember { mutableStateOf(loadStoredCorridors(courseId)) }
    var selectedHole by rememberSaveable { mutableStateOf<Int?>(null) }
    var calculating by remember { mutableStateOf(false) }

    fun calculate() {
        val c = course ?: return
        scope.launch {
            calculating = true
            val rounds = GolfStore.current.rounds
            val result = withContext(Dispatchers.Default) { FairwayCorridorInference.corridors(c, rounds) }
            corridors = result
            storeCorridors(c.id, result)
            if (selectedHole == null) selectedHole = result.firstOrNull()?.holeNumber
            calculating = false
        }
    }

    LaunchedEffect(Unit) {
        if (selectedHole == null) selectedHole = corridors.firstOrNull()?.holeNumber
        // Neu rechnen, wenn nichts gespeichert ist oder seit der letzten Berechnung
        // Runden mit Laufspur dazugekommen sind.
        val tracked = data.rounds.count { it.courseId == courseId && it.track != null }
        val stored = corridors.maxOfOrNull { it.roundCount }
        if (corridors.isEmpty() || stored != tracked) calculate()
    }

    val selected = corridors.firstOrNull { it.holeNumber == selectedHole } ?: corridors.firstOrNull()

    AppScaffold(
        "Fairway-Verlauf", onBack = { nav.popBackStack() },
        actions = {
            IconButton(onClick = { Haptics.tap(); calculate() }, enabled = !calculating) {
                Icon(Icons.Filled.Refresh, contentDescription = "Neu berechnen", tint = AppTheme.gold)
            }
        },
    ) { m ->
        when {
            calculating -> Box(m, contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    CircularProgressIndicator(color = AppTheme.gold)
                    Text("Fairway-Verlauf wird berechnet …", color = AppTheme.textSec)
                }
            }
            corridors.isEmpty() || selected == null -> EmptyState(
                Icons.Filled.Polyline, "Kein Fairway-Verlauf ableitbar",
                "Dafür braucht es pro Loch Abschlag- und Grünposition sowie Messpunkte dazwischen – aus Laufspuren oder getrackten Schlägen. Par-3-Löcher werden übersprungen, dort gibt es kein Fairway.",
                m,
            )
            else -> Column(m) {
                Row(
                    Modifier.fillMaxWidth().background(AppTheme.cardDark).horizontalScroll(rememberScrollState())
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    corridors.forEach { c ->
                        val active = c.holeNumber == selected.holeNumber
                        Box(
                            Modifier.size(38.dp).background(if (active) AppTheme.gold else AppTheme.card, CircleShape)
                                .clickable { Haptics.selection(); selectedHole = c.holeNumber },
                            contentAlignment = Alignment.Center,
                        ) {
                            Text("${c.holeNumber}", color = if (active) AppTheme.onGold else AppTheme.text, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold)
                        }
                    }
                }
                val areas = if (selected.corridorPolygon.size >= 4)
                    listOf(MapArea(selected.corridorPolygon, AppTheme.gold.copy(alpha = 0.22f), AppTheme.gold.copy(alpha = 0.55f))) else emptyList()
                val lines = buildList {
                    add(MapLine(listOf(selected.tee, selected.green), Color.White.copy(alpha = 0.35f), 1f, dashed = true))
                    if (selected.centerline.size >= 2) add(MapLine(selected.centerline, AppTheme.gold, 3f))
                }
                val pins = listOf(
                    MapPin(selected.tee, PinStyle.Symbol(IosColor.blue, PinSymbol.TEE, 26f), "Abschlag"),
                    MapPin(selected.green, PinStyle.Symbol(IosColor.red, PinSymbol.FLAG, 26f), "Grün"),
                )
                OsmMap(
                    Modifier.fillMaxWidth().weight(1f), satellite = true, interactive = true,
                    lines = lines, areas = areas, pins = pins, fitKey = selected.holeNumber,
                )
                CorridorInfo(selected, unit)
            }
        }
    }
}

@Composable
private fun CorridorInfo(c: HoleCorridor, unit: app.golftrack.data.DistanceUnit) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card).navigationBarsPadding().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Loch ${c.holeNumber}", color = AppTheme.text, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold)
            when (c.reliability) {
                HoleCorridor.Reliability.GOOD -> CapsuleBadge("belastbar", AppTheme.green)
                HoleCorridor.Reliability.THIN -> CapsuleBadge("dünn", AppTheme.gold)
                HoleCorridor.Reliability.VERY_THIN -> CapsuleBadge("sehr dünn", IosColor.orange)
            }
            Spacer(Modifier.weight(1f))
            Text("Runden: ${c.roundCount}", color = AppTheme.textSec, fontSize = IosFont.caption)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            InfoStat(Icons.Filled.SwapHoriz, unit.format(c.averageWidthMeters))
            InfoStat(Icons.Filled.SquareFoot, unit.format(c.axisLengthMeters))
            InfoStat(Icons.Filled.BarChart, "Abdeckung ${(c.coverage * 100).toInt()} %")
        }
        val hint = when (c.reliability) {
            HoleCorridor.Reliability.GOOD -> "Aus mehreren Runden gerechnet. Trotzdem eine Schätzung – kein amtlicher Platzplan."
            HoleCorridor.Reliability.THIN -> "Noch wenige Runden. Der Korridor kann daneben liegen, vor allem an Doglegs."
            HoleCorridor.Reliability.VERY_THIN -> "Aus sehr wenigen Daten. Eine Laufspur ist nicht das Fairway – du läufst zu deinem Ball, über Wege und ins Rough. Betrachte das als groben Anhaltspunkt."
        }
        Text(hint, color = if (c.reliability == HoleCorridor.Reliability.GOOD) AppTheme.textSec else IosColor.orange, fontSize = IosFont.caption2)
    }
}

@Composable
private fun InfoStat(icon: androidx.compose.ui.graphics.vector.ImageVector, value: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        Icon(icon, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(12.dp))
        Text(value, color = AppTheme.textSec, fontSize = IosFont.caption2)
    }
}
