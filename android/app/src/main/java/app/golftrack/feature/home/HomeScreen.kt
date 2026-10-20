package app.golftrack.feature.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.LocationOff
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Restore
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Thermostat
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.Air
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.navigation.NavController
import app.golftrack.R
import app.golftrack.data.AppFocus
import app.golftrack.data.Course
import app.golftrack.data.GolfData
import app.golftrack.data.GolfStore
import app.golftrack.data.HandicapCalculator
import app.golftrack.data.Round
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.data.rememberPrefString
import app.golftrack.feature.minigolf.MinigolfGameStore
import app.golftrack.feature.minigolf.MinigolfHistoryEntry
import app.golftrack.feature.minigolf.MinigolfRoutes
import app.golftrack.feature.minigolf.SavedMinigolfGame
import app.golftrack.feature.profile.Reminders
import app.golftrack.ui.DeepLinks
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LaterBadge
import app.golftrack.ui.common.LaterFeature
import app.golftrack.ui.common.LocationService
import app.golftrack.ui.common.Routes
import app.golftrack.ui.common.rememberLocation
import app.golftrack.ui.onboarding.LaunchOverlays
import app.golftrack.ui.theme.AppTheme
import java.text.SimpleDateFormat
import java.util.Locale

internal fun formatDateShort(ms: Long): String = SimpleDateFormat("d. MMM yyyy", Locale.GERMANY).format(ms)

/** Startseite wie HomeView.swift – Golf- oder Minigolf-Schwerpunkt. */
@Composable
fun HomeScreen(nav: NavController) {
    val ctx = LocalContext.current
    val data by GolfStore.data.collectAsState()
    val playerName by rememberPrefString("playerName", "Golfer")
    val focus by rememberPrefString("appFocus", AppFocus.GOLF.raw)
    val weather by GolfWeather.state.collectAsState()
    val rules = rememberGolfWeatherRules()
    val suggestion by NearbyCourses.suggestion.collectAsState()
    val newNearby by NearbyCourses.newNearby.collectAsState()

    // Standort: fragt einmal nach der Berechtigung (wie das Wetter auf iOS).
    val here = rememberLocation(highAccuracy = false)

    var minigolfSaved by remember { mutableStateOf<SavedMinigolfGame?>(null) }
    var minigolfHistory by remember { mutableStateOf<List<MinigolfHistoryEntry>>(emptyList()) }
    LifecycleResumeEffect(Unit) {
        minigolfSaved = MinigolfGameStore.load()
        minigolfHistory = MinigolfGameStore.loadHistory()
        onPauseOrDispose { }
    }

    LaunchedEffect(Unit) {
        if (!weather.hasData && LocationService.hasPermission(ctx)) GolfWeather.fetch(ctx)
        CourseCatalog.checkForUpdates()
        Reminders.onAppStart(ctx)
    }
    LaunchedEffect(here != null) {
        if (here != null && !weather.hasData && !weather.isLoading && weather.selectedCourseName == null) GolfWeather.fetch(ctx)
    }
    // Ohne geladenes Verzeichnis gäbe es nichts zu vergleichen.
    val remoteGolf by CourseCatalog.remoteGolfCourses.collectAsState()
    LaunchedEffect(here, remoteGolf) { here?.let { NearbyCourses.update(it) } }

    val completed = data.completedRounds
    val incomplete = data.sortedRounds.filter { !it.isComplete }
    var roundToDelete by remember { mutableStateOf<Round?>(null) }

    Box(Modifier.fillMaxSize().background(AppTheme.bg)) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(top = 8.dp, bottom = 30.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            TopBar(onTutorial = { nav.navigate(Routes.TUTORIAL) })
            GreetingCard(playerName, weather, data)

            suggestion?.let { NearbyCard(it, onStart = { DeepLinks.open(DeepLinks.Link(it.kind, it.slug), nav) }) }
            if (newNearby.isNotEmpty()) {
                NewNearbyCard(newNearby, onStart = { DeepLinks.open(DeepLinks.Link(it.kind, it.slug), nav) })
            }

            val openWeather = { if (weather.hasData) { Haptics.tap(); nav.navigate(Routes.WEATHER) } }
            if (focus == AppFocus.MINIGOLF.raw) {
                MinigolfStatsRow(minigolfHistory)
                WeatherCard(weather, rules, data, onClick = openWeather)
                minigolfSaved?.let { game ->
                    MinigolfResumeCard(
                        game,
                        onResume = { Haptics.medium(); nav.navigate(MinigolfRoutes.PLAY) },
                        onDiscard = { Haptics.warning(); MinigolfGameStore.clear(); minigolfSaved = null },
                    )
                }
                GoldActionButton("Minigolf-Spiel starten", Icons.Filled.AddCircle) { nav.navigate(Routes.MINIGOLF) }
                if (minigolfHistory.isNotEmpty()) MinigolfHistoryCard(minigolfHistory) { nav.navigate(MinigolfRoutes.HISTORY) }
                // Laufende Golfrunden bleiben auch im Minigolf-Modus sichtbar.
                if (incomplete.isNotEmpty()) ActiveRoundsCard(incomplete, data, { nav.navigate(Routes.playRound(it.id)) }) { roundToDelete = it }
                Row(Modifier.padding(horizontal = 16.dp)) {
                    GreenButton("Minigolf-Verlauf", Icons.Filled.History, Modifier.weight(1f)) { nav.navigate(MinigolfRoutes.HISTORY) }
                }
            } else {
                StatsRow(completed, data)
                WeatherCard(weather, rules, data, onClick = openWeather)
                if (completed.isNotEmpty()) TrainingProgressCard(completed.size)
                if (incomplete.isNotEmpty()) ActiveRoundsCard(incomplete, data, { nav.navigate(Routes.playRound(it.id)) }) { roundToDelete = it }
                GoldActionButton("Neue Runde spielen", Icons.Filled.AddCircle) { nav.navigate(Routes.newRound()) }
                Row(Modifier.padding(horizontal = 16.dp).height(IntrinsicSize.Min), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    GreenButton("Platzreife lernen", Icons.Filled.School, Modifier.weight(1f).fillMaxHeight()) { nav.navigate(Routes.PLATZREIFE) }
                    GreenButton("Verlauf", Icons.Filled.History, Modifier.weight(1f).fillMaxHeight()) { nav.navigate(Routes.HISTORY) }
                }
            }

            CaddyButton { nav.navigate(Routes.comingLater(LaterFeature.CADDY)) }
        }

        LaunchOverlays(nav)
    }

    roundToDelete?.let { r ->
        AlertDialog(
            onDismissRequest = { roundToDelete = null },
            containerColor = AppTheme.card,
            title = { Text("Runde abbrechen?", color = AppTheme.text) },
            text = { Text("Die Runde wird unwiderruflich gelöscht.", color = AppTheme.textSec) },
            confirmButton = {
                TextButton(onClick = { Haptics.warning(); GolfStore.deleteRound(r.id); roundToDelete = null }) {
                    Text("Runde löschen", color = Color(0xFFFF453A))
                }
            },
            dismissButton = {
                TextButton(onClick = { Haptics.tap(); roundToDelete = null }) { Text("Abbrechen", color = AppTheme.gold) }
            },
        )
    }
}

// --- Bausteine ---

private val cardModifier = Modifier.padding(horizontal = 16.dp)

@Composable
private fun TopBar(onTutorial: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        Image(
            painterResource(R.mipmap.ic_launcher), null,
            modifier = Modifier.size(34.dp).clip(RoundedCornerShape(8.dp)), contentScale = ContentScale.Crop,
        )
        Spacer(Modifier.width(10.dp))
        Text("GolfTrack", color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
        Box(
            Modifier.clip(CircleShape).background(AppTheme.card).clickable { Haptics.tap(); onTutorial() }.padding(10.dp),
        ) { Icon(Icons.Filled.Lightbulb, "Tutorial", tint = AppTheme.gold, modifier = Modifier.size(22.dp)) }
    }
}

@Composable
private fun GreetingCard(playerName: String, weather: WeatherState, data: GolfData) {
    Row(
        cardModifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Willkommen zurück,", color = AppTheme.textSec, fontSize = 15.sp)
            Text("$playerName!", color = AppTheme.text, fontSize = 28.sp, fontWeight = FontWeight.Bold)
        }
        WeatherPill(weather, data)
    }
}

@Composable
private fun WeatherPill(weather: WeatherState, data: GolfData) {
    when {
        weather.isLoading -> Box(Modifier.size(44.dp), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = AppTheme.gold, strokeWidth = 2.dp, modifier = Modifier.size(22.dp))
        }
        weather.hasData -> Row(
            Modifier.background(AppTheme.cardAlt, CircleShape).padding(horizontal = 10.dp, vertical = 7.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(weather.symbol.icon, null, tint = weather.symbol.tint, modifier = Modifier.size(22.dp))
            Spacer(Modifier.width(6.dp))
            Column {
                Text(weather.temperature, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                Text(weather.conditionText, color = AppTheme.textSec, fontSize = 10.sp, maxLines = 1)
            }
        }
        weather.authDenied -> Row(
            Modifier.background(iosOrangeHome.copy(alpha = 0.12f), CircleShape).padding(horizontal = 10.dp, vertical = 7.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.LocationOff, null, tint = iosOrangeHome, modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(4.dp))
            Text("Standort gesperrt", color = iosOrangeHome, fontSize = 12.sp)
        }
        else -> WeatherLocationMenu(data) { open ->
            val err = weather.errorMessage != null
            Row(
                Modifier.clip(CircleShape).background(AppTheme.cardAlt).clickable { open() }.padding(horizontal = 10.dp, vertical = 7.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.MyLocation, null, tint = if (err) iosOrangeHome else AppTheme.gold, modifier = Modifier.size(13.dp))
                Spacer(Modifier.width(4.dp))
                Text(
                    if (err) "Erneut versuchen" else "Wetter",
                    color = if (err) iosOrangeHome else AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}

private val iosOrangeHome = Color(0xFFFF9F0A)

/** Auswahl „Mein Standort" oder ein eigener Platz mit Koordinaten. */
@Composable
private fun WeatherLocationMenu(data: GolfData, anchor: @Composable (open: () -> Unit) -> Unit) {
    val ctx = LocalContext.current
    var open by remember { mutableStateOf(false) }
    val courses = data.courses.filter { it.latitude != null && it.longitude != null }.sortedBy { it.name.lowercase() }
    Box {
        anchor { Haptics.tap(); open = true }
        DropdownMenu(expanded = open, onDismissRequest = { open = false }, containerColor = AppTheme.cardAlt) {
            DropdownMenuItem(
                text = { Text("Mein Standort", color = AppTheme.text) },
                leadingIcon = { Icon(Icons.Filled.MyLocation, null, tint = AppTheme.gold) },
                onClick = { Haptics.selection(); open = false; GolfWeather.fetch(ctx) },
            )
            if (courses.isNotEmpty()) HorizontalDivider(color = AppTheme.card)
            courses.forEach { c: Course ->
                DropdownMenuItem(
                    text = { Text(c.name, color = AppTheme.text) },
                    leadingIcon = { Icon(Icons.Filled.Flag, null, tint = AppTheme.gold) },
                    onClick = {
                        Haptics.selection(); open = false
                        GolfWeather.fetchForCoordinate(c.latitude!!, c.longitude!!, c.name)
                    },
                )
            }
        }
    }
}

@Composable
private fun StatsRow(completed: List<Round>, data: GolfData) {
    val last = completed.firstOrNull()
    val lastCourse = data.course(last?.courseId)
    Row(cardModifier.height(IntrinsicSize.Min), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        StatCard("Handicap", HandicapCalculator.displayString(completed, data), "WHS", AppTheme.gold, AppTheme.text, Modifier.weight(1f))
        if (last != null) {
            val stp = last.scoreToPar(lastCourse)
            StatCard(
                "Letzte Runde", "${last.totalStrokes}", last.scoreLabel(lastCourse),
                if (stp != null && stp <= 0) AppTheme.gold else if (stp != null) Color.White.copy(alpha = 0.6f) else AppTheme.textSec,
                AppTheme.text, Modifier.weight(1f),
            )
        } else {
            StatCard("Letzte Runde", "–", "Noch keine Runde", AppTheme.textTer, AppTheme.textSec, Modifier.weight(1f), boldFoot = false)
        }
    }
}

@Composable
private fun StatCard(
    label: String, value: String, foot: String, footColor: Color, valueColor: Color,
    modifier: Modifier, boldFoot: Boolean = true,
) {
    Column(
        modifier.fillMaxHeight().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(label, color = AppTheme.textSec, fontSize = 12.sp)
        Text(value, color = valueColor, fontSize = 32.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.SansSerif, maxLines = 1)
        Text(foot, color = footColor, fontSize = 11.sp, fontWeight = if (boldFoot) FontWeight.Bold else FontWeight.Normal, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

@Composable
private fun MinigolfStatsRow(history: List<MinigolfHistoryEntry>) {
    val averages = history.mapNotNull { e ->
        if (e.numberOfHoles <= 0) return@mapNotNull null
        val best = e.scores.map { it.sum() }.minOrNull() ?: return@mapNotNull null
        if (best <= 0) null else best.toDouble() / e.numberOfHoles
    }
    val bestAvg = averages.minOrNull()?.let { String.format(Locale.GERMANY, "%.1f", it) } ?: "–"
    val empty = history.isEmpty()
    Row(cardModifier.height(IntrinsicSize.Min), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        StatCard(
            "Bester Schnitt", bestAvg, if (empty) "Noch kein Spiel" else "Schläge pro Loch",
            if (empty) AppTheme.textTer else AppTheme.gold, if (empty) AppTheme.textSec else AppTheme.text, Modifier.weight(1f),
        )
        StatCard(
            "Partien", if (empty) "–" else "${history.size}",
            history.firstOrNull()?.let { formatDateShort(it.dateMillis) } ?: "Starte dein erstes Spiel",
            if (empty) AppTheme.textTer else AppTheme.gold, if (empty) AppTheme.textSec else AppTheme.text,
            Modifier.weight(1f), boldFoot = !empty,
        )
    }
}

@Composable
private fun WeatherCard(weather: WeatherState, rules: GolfWeatherRules, data: GolfData, onClick: () -> Unit) {
    if (!weather.hasData) return
    val good = weather.isGoodGolfWeather(rules)
    val badge = if (good) goodColor else warnColor
    Column(
        cardModifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(AppTheme.card).clickable { onClick() }.padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            WeatherLocationMenu(data) { open ->
                Row(Modifier.clip(RoundedCornerShape(6.dp)).clickable { open() }, verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        if (weather.selectedCourseName == null) Icons.Filled.MyLocation else Icons.Filled.Flag, null,
                        tint = AppTheme.text, modifier = Modifier.size(13.dp),
                    )
                    Spacer(Modifier.width(5.dp))
                    Text(
                        weather.locationName.ifEmpty { "Aktuelles Wetter" }, color = AppTheme.text, fontSize = 15.sp,
                        fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.widthIn(max = 170.dp),
                    )
                    Icon(Icons.Filled.KeyboardArrowDown, null, tint = AppTheme.text, modifier = Modifier.size(16.dp))
                }
            }
            Spacer(Modifier.weight(1f))
            Row(
                Modifier.background(badge.copy(alpha = 0.12f), CircleShape).padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(6.dp).background(badge, CircleShape))
                Spacer(Modifier.width(4.dp))
                Text(weather.golfWeatherLabel(rules), color = badge, fontSize = 12.sp, fontWeight = FontWeight.Bold, maxLines = 1)
            }
        }
        Row(Modifier.height(IntrinsicSize.Min), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Icon(weather.symbol.icon, null, tint = weather.symbol.tint, modifier = Modifier.size(38.dp))
                Text(weather.temperature, color = AppTheme.text, fontSize = 28.sp, fontWeight = FontWeight.Bold)
                Text(weather.conditionText, color = AppTheme.textSec, fontSize = 12.sp, textAlign = TextAlign.Center)
            }
            VerticalDivider(Modifier.height(70.dp), color = AppTheme.cardAlt)
            Column(Modifier.weight(1f).padding(start = 12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                WeatherDetail(Icons.Filled.Thermostat, "Gefühlt", weather.feelsLike)
                WeatherDetail(Icons.Filled.Air, "Wind", weather.windSpeed)
                WeatherDetail(Icons.Filled.WaterDrop, "Feuchte", weather.humidity)
                WeatherDetail(Icons.Filled.WbSunny, "UV", weather.uvIndex)
            }
        }
        // Die Karte öffnet beim Antippen die Vorhersage – ohne Hinweis sieht man das nicht.
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End, verticalAlignment = Alignment.CenterVertically) {
            Text("Tippe für mehr Infos", color = AppTheme.textSec, fontSize = 11.sp)
            Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textSec, modifier = Modifier.size(14.dp))
        }
    }
}

@Composable
internal fun WeatherDetail(icon: ImageVector, label: String, value: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
        Spacer(Modifier.width(6.dp))
        Text(label, color = AppTheme.textSec, fontSize = 12.sp, modifier = Modifier.weight(1f))
        Text(value, color = AppTheme.text, fontSize = 12.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun TrainingProgressCard(count: Int) {
    val pct = minOf(1f, count / 20f)
    Column(
        cardModifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row {
            Text("Trainingsfortschritt", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            Text("${(pct * 100).toInt()} %", color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        }
        Text("Richtung 20 Runden für vollen WHS-Index", color = AppTheme.textSec, fontSize = 12.sp)
        Box(Modifier.fillMaxWidth().height(8.dp).background(AppTheme.cardAlt, CircleShape)) {
            Box(Modifier.fillMaxWidth(pct).height(8.dp).background(AppTheme.gold, CircleShape))
        }
    }
}

@Composable
private fun ActiveRoundsCard(rounds: List<Round>, data: GolfData, onOpen: (Round) -> Unit, onDelete: (Round) -> Unit) {
    Column(
        cardModifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("Aktive Runden", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        rounds.forEach { r ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                DarkRoundRow(r, data.course(r.courseId), Modifier.weight(1f)) { Haptics.tap(); onOpen(r) }
                Spacer(Modifier.width(10.dp))
                Icon(
                    Icons.Filled.Cancel, "Runde abbrechen", tint = AppTheme.textTer,
                    modifier = Modifier.size(26.dp).clip(CircleShape).clickable { Haptics.tap(); onDelete(r) },
                )
            }
        }
    }
}

@Composable
internal fun DarkRoundRow(round: Round, course: Course?, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Row(
        modifier.clip(RoundedCornerShape(12.dp)).background(AppTheme.cardAlt).clickable { onClick() }.padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(course?.name ?: "Unbekannter Platz", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(formatDateShort(round.date), color = AppTheme.textSec, fontSize = 12.sp)
        }
        if (round.isComplete) {
            Column(horizontalAlignment = Alignment.End) {
                Text(round.scoreLabel(course), color = AppTheme.gold, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                Text("${round.totalStrokes}", color = AppTheme.textSec, fontSize = 12.sp)
            }
        } else {
            Text(
                "Aktiv", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold,
                modifier = Modifier.background(AppTheme.gold.copy(alpha = 0.25f), CircleShape).padding(horizontal = 10.dp, vertical = 4.dp),
            )
        }
        Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))
    }
}

@Composable
private fun GoldActionButton(text: String, icon: ImageVector, onClick: () -> Unit) {
    Row(
        cardModifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(AppTheme.gold)
            .clickable { Haptics.medium(); onClick() }.padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = AppTheme.onGold, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(8.dp))
        Text(text, color = AppTheme.onGold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun GreenButton(text: String, icon: ImageVector, modifier: Modifier, onClick: () -> Unit) {
    Row(
        modifier.clip(RoundedCornerShape(14.dp)).background(AppTheme.greenMid)
            .clickable { Haptics.tap(); onClick() }.padding(vertical = 14.dp, horizontal = 8.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = Color.White, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(6.dp))
        Text(text, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
    }
}

@Composable
private fun MinigolfResumeCard(game: SavedMinigolfGame, onResume: () -> Unit, onDiscard: () -> Unit) {
    Column(
        cardModifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Restore, null, tint = AppTheme.text, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(6.dp))
            Text("Angefangenes Spiel", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        }
        Text(
            "${game.playerNames.joinToString(", ")} · Loch ${game.currentHole + 1} von ${game.numberOfHoles}",
            color = AppTheme.textSec, fontSize = 12.sp,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(
                Modifier.weight(1f).clip(RoundedCornerShape(10.dp)).background(AppTheme.gold).clickable { onResume() }.padding(vertical = 10.dp),
                horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.PlayArrow, null, tint = AppTheme.onGold, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(4.dp))
                Text("Fortsetzen", color = AppTheme.onGold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            }
            Row(
                Modifier.weight(1f).clip(RoundedCornerShape(10.dp)).background(Color.Red.copy(alpha = 0.12f)).clickable { onDiscard() }.padding(vertical = 10.dp),
                horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Delete, null, tint = Color(0xFFFF453A), modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(4.dp))
                Text("Verwerfen", color = Color(0xFFFF453A), fontSize = 15.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun MinigolfHistoryCard(history: List<MinigolfHistoryEntry>, onOpen: () -> Unit) {
    Column(
        cardModifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Letzte Partien", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            if (history.size > 3) {
                Text(
                    "Alle anzeigen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.clickable { Haptics.tap(); onOpen() },
                )
            }
        }
        history.take(3).forEach { e ->
            val totals = e.scores.map { it.sum() }
            val winner = totals.indices.minByOrNull { totals[it] }
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(AppTheme.cardAlt)
                    .clickable { Haptics.tap(); onOpen() }.padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text(winner?.let { e.playerNames.getOrNull(it) } ?: "Partie", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold, maxLines = 1)
                    Text("${e.numberOfHoles} Löcher · ${e.playerNames.size} Spieler", color = AppTheme.textSec, fontSize = 12.sp, maxLines = 1)
                    e.courseName?.let { name ->
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Place, null, tint = AppTheme.textSec, modifier = Modifier.size(11.dp))
                            Spacer(Modifier.width(3.dp))
                            Text(name, color = AppTheme.textSec, fontSize = 11.sp, maxLines = 1)
                        }
                    }
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(winner?.let { "${totals[it]}" } ?: "–", color = AppTheme.gold, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                    Text(formatDateShort(e.dateMillis), color = AppTheme.textSec, fontSize = 12.sp)
                }
                Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))
            }
        }
    }
}

@Composable
private fun CaddyButton(onClick: () -> Unit) {
    Row(
        cardModifier.fillMaxWidth().clip(RoundedCornerShape(16.dp))
            .background(Brush.linearGradient(listOf(Color(0xFF1F4D1F), Color(0xFF143314))))
            .border(1.dp, AppTheme.gold.copy(alpha = 0.35f), RoundedCornerShape(16.dp))
            .clickable { Haptics.tap(); onClick() }
            .padding(horizontal = 20.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.GraphicEq, null, tint = Color.White, modifier = Modifier.size(24.dp))
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text("Caddy – Golf-Assistent", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
            Text("Regeln, Tipps & Strategien", color = Color.White.copy(alpha = 0.7f), fontSize = 12.sp)
        }
        LaterBadge()
        Spacer(Modifier.width(6.dp))
        Icon(Icons.Filled.ChevronRight, null, tint = Color.White.copy(alpha = 0.5f), modifier = Modifier.size(18.dp))
    }
}

// --- Platz in der Nähe ---

@Composable
private fun NearbyCard(platz: NearbyCourses.NearbyCourse, onStart: () -> Unit) {
    Row(
        cardModifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            if (platz.kind == DeepLinks.Kind.GOLF) Icons.Filled.Flag else Icons.Filled.SportsGolf, null,
            tint = AppTheme.gold, modifier = Modifier.size(28.dp),
        )
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text("Du bist hier", color = AppTheme.gold.copy(alpha = 0.85f), fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
            Text(platz.name, color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, maxLines = 2)
            val m = Math.round(platz.distance)
            Text(
                if (platz.location.isEmpty()) "$m m entfernt" else "${platz.location} · $m m",
                color = AppTheme.textSec, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
            )
        }
        Spacer(Modifier.width(8.dp))
        Text(
            "Starten", color = Color(0xFF0F2414), fontSize = 15.sp, fontWeight = FontWeight.Bold,
            modifier = Modifier.clip(CircleShape).background(AppTheme.gold).clickable { Haptics.medium(); onStart() }
                .padding(horizontal = 16.dp, vertical = 9.dp),
        )
        Icon(
            Icons.Filled.Close, "Ausblenden", tint = AppTheme.textTer,
            modifier = Modifier.padding(start = 4.dp).clip(CircleShape).clickable { Haptics.tap(); NearbyCourses.dismissSuggestion() }.padding(6.dp).size(14.dp),
        )
    }
}

@Composable
private fun NewNearbyCard(plaetze: List<NearbyCourses.NearbyCourse>, onStart: (NearbyCourses.NearbyCourse) -> Unit) {
    Column(
        cardModifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.AutoAwesome, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(6.dp))
            Text(
                if (plaetze.size == 1) "Neuer Platz in deiner Nähe" else "Neue Plätze in deiner Nähe",
                color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f),
            )
            Icon(
                Icons.Filled.Close, "Ausblenden", tint = AppTheme.textTer,
                modifier = Modifier.clip(CircleShape).clickable { Haptics.tap(); NearbyCourses.dismissNewNearby() }.padding(6.dp).size(14.dp),
            )
        }
        plaetze.take(3).forEach { p ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    if (p.kind == DeepLinks.Kind.GOLF) Icons.Filled.Flag else Icons.Filled.SportsGolf, null,
                    tint = AppTheme.gold, modifier = Modifier.size(22.dp),
                )
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(p.name, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, maxLines = 2)
                    val km = "${Math.round(p.distance / 1000)} km"
                    Text(if (p.location.isEmpty()) km else "${p.location} · $km", color = AppTheme.textSec, fontSize = 12.sp, maxLines = 1)
                }
                Text(
                    "Starten", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.clip(CircleShape).background(AppTheme.gold.copy(alpha = 0.18f))
                        .clickable { Haptics.medium(); onStart(p) }.padding(horizontal = 12.dp, vertical = 7.dp),
                )
            }
        }
    }
}

