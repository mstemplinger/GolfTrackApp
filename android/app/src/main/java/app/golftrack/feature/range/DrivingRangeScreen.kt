package app.golftrack.feature.range

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import app.golftrack.data.DistanceUnit
import app.golftrack.data.GolfBag
import app.golftrack.data.GolfStore
import app.golftrack.data.rememberPrefString
import app.golftrack.feature.profile.AchievementStore
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme

fun NavGraphBuilder.rangeRoutes(nav: NavController) {
    composable(Routes.DRIVING_RANGE) { DrivingRangeScreen(nav) }
    composable(Routes.RANGE_HISTORY) { RangeHistoryScreen(nav) }
}

/** Display-Wert (m oder y) zurück in Meter. */
internal fun DistanceUnit.toMeters(value: Int): Double =
    if (this == DistanceUnit.METERS) value.toDouble() else value / 1.09361

@Composable
internal fun rememberDistanceUnit(): DistanceUnit {
    val raw by rememberPrefString("distanceUnit", DistanceUnit.METERS.raw)
    return DistanceUnit.fromRaw(raw)
}

/**
 * Driving Range wie DrivingRangeView.swift: Schläger wählen, geschlagene Weite
 * eintragen, mit früheren Einheiten vergleichen. Eine nicht beendete Einheit
 * wird beim nächsten Öffnen fortgesetzt.
 */
@Composable
fun DrivingRangeScreen(nav: NavController) {
    val ctx = LocalContext.current
    remember { RangeStore.init(ctx) }
    val rangeData by RangeStore.data.collectAsState()
    val golf by GolfStore.data.collectAsState()
    val unit = rememberDistanceUnit()
    var rangeBagName by rememberPrefString("rangeBagName")
    var lastClub by rememberPrefString("rangeLastClub")
    val focus = LocalFocusManager.current

    // Neueste zuerst wie die @Query auf iOS.
    val sessions = rangeData.sessions.sortedByDescending { it.date }
    var sessionId by rememberSaveable { mutableStateOf<String?>(null) }
    val session = sessions.firstOrNull { it.id == sessionId }
    var selectedClub by rememberSaveable { mutableStateOf("") }
    /** Weite in der Anzeige-Einheit (m oder y) */
    var distance by rememberSaveable { mutableStateOf(150) }
    var finished by remember { mutableStateOf<RangeSession?>(null) }

    val bags = golf.bags.sortedBy { it.createdAt }
    val activeBag: GolfBag? = bags.firstOrNull { it.name == rangeBagName } ?: bags.firstOrNull()
    val clubNames = activeBag?.sortedClubs?.filter { !it.isPutter }?.map { it.name }.orEmpty()
        .ifEmpty { RangeClubDefaults.names }

    // Alle Schläge vor der laufenden Einheit – die Messlatte zum Vergleich.
    val earlierStats = RangeClubStats.byClub(sessions.filter { it.id != session?.id }.flatMap { it.shots })
    val sessionStats = RangeClubStats.byClub(session?.shots.orEmpty())

    fun select(name: String) {
        selectedClub = name
        lastClub = name
        // Vorschlag: der letzte Schlag mit diesem Schläger, sonst sein Durchschnitt.
        val last = session?.sortedShots?.lastOrNull { it.clubName == name }?.distanceMeters
        val guess = last ?: earlierStats[name]?.average
            ?: activeBag?.clubs?.firstOrNull { it.name == name }?.averageDistance?.toDouble()
        if (guess != null) distance = unit.value(guess)
    }

    LaunchedEffect(Unit) {
        if (sessionId == null) sessionId = sessions.firstOrNull { it.endedAt == null }?.id
        if (selectedClub.isEmpty()) select(if (lastClub in clubNames) lastClub else clubNames.firstOrNull().orEmpty())
    }

    fun saveShot() {
        if (selectedClub.isEmpty() || distance <= 0) return
        val shot = RangeShot(clubName = selectedClub, distanceMeters = unit.toMeters(distance))
        val current = session ?: RangeSession().also { sessionId = it.id }
        RangeStore.upsert(current.copy(shots = current.shots + shot))
        focus.clearFocus()
    }

    fun undoLastShot() {
        val s = session ?: return
        val last = s.sortedShots.lastOrNull() ?: return
        RangeStore.upsert(s.copy(shots = s.shots.filter { it.id != last.id }))
    }

    fun finish() {
        val s = session ?: return
        val done = s.copy(endedAt = System.currentTimeMillis())
        RangeStore.upsert(done)
        AchievementStore.evaluateRange(RangeStore.data.value.sessions)
        finished = done
    }

    // Leere Einheiten nicht aufheben; angefangene bleiben offen und werden fortgesetzt.
    fun close() {
        val s = session
        if (s != null && s.shots.isEmpty()) RangeStore.delete(s.id)
        else AchievementStore.evaluateRange(RangeStore.data.value.sessions)
        nav.popBackStack()
    }

    BackHandler(enabled = finished == null) { close() }

    AppScaffold(
        "Driving Range",
        onBack = { close() },
        actions = {
            IconButton(onClick = { Haptics.tap(); nav.navigate(Routes.RANGE_HISTORY) }) {
                Icon(Icons.Filled.ShowChart, "Range-Verlauf", tint = AppTheme.gold)
            }
        },
    ) { m ->
        Column(
            m.verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            SessionHeader(session?.shots.orEmpty(), unit)
            ClubPicker(
                clubNames, selectedClub, sessionStats, bags, activeBag,
                onBag = { Haptics.selection(); rangeBagName = it.name },
                onSelect = { Haptics.selection(); select(it) },
            )
            EntryCard(
                distance, unit,
                onDistance = { distance = maxOf(0, it) },
                earlier = earlierStats[selectedClub], today = sessionStats[selectedClub],
                canSave = selectedClub.isNotEmpty() && distance > 0,
                onSave = { Haptics.stroke(); saveShot() },
            )
            if (session != null && session.shots.isNotEmpty()) {
                ShotList(
                    session, unit, earlierStats,
                    onUndo = { Haptics.light(); undoLastShot() },
                    onFinish = { Haptics.celebrate(); finish() },
                )
            }
        }
    }

    finished?.let { done ->
        val earlier = RangeStore.data.value.sessions.filter { it.date < done.date }.flatMap { it.shots }
        RangeSessionSummary(done, earlier, unit) {
            finished = null
            nav.popBackStack()
        }
    }
}

// --- Kopf ---

@Composable
private fun SessionHeader(shots: List<RangeShot>, unit: DistanceUnit) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        HeaderStat("${shots.size}", "Bälle", Modifier.weight(1f))
        VerticalDivider(Modifier.height(34.dp), color = AppTheme.cardAlt)
        HeaderStat("${shots.map { it.clubName }.toSet().size}", "Schläger", Modifier.weight(1f))
        VerticalDivider(Modifier.height(34.dp), color = AppTheme.cardAlt)
        HeaderStat(shots.maxOfOrNull { it.distanceMeters }?.let { unit.format(it) } ?: "–", "Weitester", Modifier.weight(1f))
    }
}

@Composable
private fun HeaderStat(value: String, label: String, modifier: Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(value, color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text(label, color = AppTheme.textSec, fontSize = 12.sp)
    }
}

// --- Schlägerwahl ---

@Composable
private fun ClubPicker(
    clubNames: List<String>,
    selected: String,
    sessionStats: Map<String, RangeClubStats>,
    bags: List<GolfBag>,
    activeBag: GolfBag?,
    onBag: (GolfBag) -> Unit,
    onSelect: (String) -> Unit,
) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Schläger wählen", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            if (bags.size > 1) {
                var open by remember { mutableStateOf(false) }
                Box {
                    Row(
                        Modifier.clip(RoundedCornerShape(6.dp)).clickable { Haptics.tap(); open = true },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.ShoppingBag, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                        Spacer(Modifier.width(4.dp))
                        Text(activeBag?.name.orEmpty(), color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                    DropdownMenu(open, { open = false }, containerColor = AppTheme.cardAlt) {
                        bags.forEach { bag ->
                            DropdownMenuItem(
                                text = { Text(bag.name, color = AppTheme.text) },
                                trailingIcon = if (bag.id == activeBag?.id) {
                                    { Icon(Icons.Filled.CheckCircle, null, tint = AppTheme.gold) }
                                } else null,
                                onClick = { open = false; onBag(bag) },
                            )
                        }
                    }
                }
            }
        }
        // Raster wie GridItem(.adaptive(minimum: 84)).
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val cols = maxOf(1, ((maxWidth + 8.dp) / (84.dp + 8.dp)).toInt())
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                clubNames.chunked(cols).forEach { row ->
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        row.forEach { name ->
                            ClubChip(name, name == selected, sessionStats[name]?.count ?: 0, Modifier.weight(1f)) { onSelect(name) }
                        }
                        repeat(cols - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
        }
    }
}

@Composable
private fun ClubChip(name: String, selected: Boolean, count: Int, modifier: Modifier, onClick: () -> Unit) {
    val fg = if (selected) Color(0xFF1A3821) else AppTheme.text
    Column(
        modifier.clip(RoundedCornerShape(12.dp)).background(if (selected) AppTheme.gold else AppTheme.cardAlt)
            .clickable { onClick() }.padding(vertical = 10.dp, horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        Text(name, color = fg, fontSize = 15.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
        Text(if (count > 0) "$count×" else " ", color = fg.copy(alpha = 0.8f), fontSize = 11.sp)
    }
}

// --- Eingabe ---

@Composable
private fun EntryCard(
    distance: Int,
    unit: DistanceUnit,
    onDistance: (Int) -> Unit,
    earlier: RangeClubStats?,
    today: RangeClubStats?,
    canSave: Boolean,
    onSave: () -> Unit,
) {
    val focus = LocalFocusManager.current
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Text("Wie weit hast du geschlagen?", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            StepButton(-5) { onDistance(distance - 5) }
            StepButton(-1) { onDistance(distance - 1) }
            Row(Modifier.weight(1f), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.Bottom) {
                BasicTextField(
                    value = if (distance == 0) "" else distance.toString(),
                    onValueChange = { t -> onDistance(t.filter { it.isDigit() }.take(4).toIntOrNull() ?: 0) },
                    singleLine = true,
                    textStyle = TextStyle(color = AppTheme.text, fontSize = 40.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center),
                    cursorBrush = SolidColor(AppTheme.gold),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = { focus.clearFocus() }),
                    modifier = Modifier.widthIn(min = 70.dp, max = 110.dp),
                )
                Spacer(Modifier.width(4.dp))
                Text(unit.unitLabel, color = AppTheme.textSec, fontSize = 20.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 8.dp))
            }
            StepButton(1) { onDistance(distance + 1) }
            StepButton(5) { onDistance(distance + 5) }
        }

        // Ø und Bestweite dieses Schlägers aus früheren Einheiten und von heute.
        if (earlier != null || today != null) {
            val highlight = if (today != null && earlier != null) {
                if (today.average >= earlier.average) AppTheme.scoreColor(-1) else AppTheme.scoreColor(1)
            } else null
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                CompareStat("Ø bisher", earlier?.let { unit.format(it.average) } ?: "–", Modifier.weight(1f))
                CompareStat("Bestweite", earlier?.let { unit.format(it.best) } ?: "–", Modifier.weight(1f))
                CompareStat("Ø heute", today?.let { unit.format(it.average) } ?: "–", Modifier.weight(1f), highlight)
            }
        } else {
            Text(
                "Erster Schlag mit diesem Schläger – ab jetzt kannst du dich vergleichen.",
                color = AppTheme.textSec, fontSize = 12.sp,
            )
        }

        Row(
            Modifier.fillMaxWidth().alpha(if (canSave) 1f else 0.5f).clip(RoundedCornerShape(14.dp)).background(AppTheme.gold)
                .clickable(enabled = canSave) { onSave() }.padding(vertical = 16.dp),
            horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.AddCircle, null, tint = AppTheme.onGold, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
            Text("Schlag speichern", color = AppTheme.onGold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun StepButton(step: Int, onClick: () -> Unit) {
    Box(
        Modifier.size(40.dp).clip(CircleShape).background(AppTheme.cardAlt).clickable { Haptics.selection(); onClick() },
        contentAlignment = Alignment.Center,
    ) {
        Text(if (step > 0) "+$step" else "$step", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun CompareStat(label: String, value: String, modifier: Modifier, highlight: Color? = null) {
    Column(
        modifier.background(AppTheme.cardDark, RoundedCornerShape(10.dp)).padding(vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        Text(value, color = highlight ?: AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        Text(label, color = AppTheme.textSec, fontSize = 11.sp)
    }
}

// --- Schläge dieser Einheit ---

@Composable
private fun ShotList(
    session: RangeSession,
    unit: DistanceUnit,
    earlierStats: Map<String, RangeClubStats>,
    onUndo: () -> Unit,
    onFinish: () -> Unit,
) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Diese Einheit", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            Row(
                Modifier.clip(RoundedCornerShape(6.dp)).clickable { onUndo() },
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.AutoMirrored.Filled.Undo, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                Spacer(Modifier.width(4.dp))
                Text("Letzten löschen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
        }
        session.sortedShots.reversed().take(12).forEach { shot ->
            // Weiter als alles, was dieser Schläger früher geschafft hat.
            val record = earlierStats[shot.clubName]?.let { shot.distanceMeters > it.best } == true
            Row(Modifier.padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(shot.clubName, color = AppTheme.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
                if (record) {
                    Icon(Icons.Filled.Star, "Neue Bestweite", tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                    Spacer(Modifier.width(6.dp))
                }
                Text(unit.format(shot.distanceMeters), color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            }
        }
        GreenWideButton("Einheit beenden", Icons.Filled.CheckCircle, Modifier.padding(top = 6.dp), onFinish)
    }
}

@Composable
internal fun GreenWideButton(text: String, icon: ImageVector, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Row(
        modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(AppTheme.greenMid)
            .clickable { onClick() }.padding(vertical = 14.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = Color.White, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(6.dp))
        Text(text, color = Color.White, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
    }
}
