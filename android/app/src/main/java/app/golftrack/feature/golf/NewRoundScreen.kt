package app.golftrack.feature.golf

import androidx.compose.animation.animateColorAsState
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
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDefaults
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.toMutableStateList
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.snapshots.SnapshotStateList
import app.golftrack.data.catalog.CourseCatalog
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.GameMode
import app.golftrack.data.GolfBag
import app.golftrack.data.GolfStore
import app.golftrack.data.HoleScore
import app.golftrack.data.PlayerHoleScore
import app.golftrack.data.Round
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/** Wie NewRoundView.swift: Platz, Bag, Datum, Spielmodus, Mitspieler → Runde starten. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewRoundScreen(nav: NavController, preselectedCourseId: String?, preselectedMode: GameMode = GameMode.STROKE_PLAY) {
    val ctx = LocalContext.current
    val data by GolfStore.data.collectAsState()
    val courses = remember(data.courses) { data.courses.sortedBy { it.name.lowercase() } }
    val bags = remember(data.bags) { data.bags.sortedBy { it.createdAt } }
    val catalog by CourseCatalog.golfCourses.collectAsState()

    var selectedCourseId by rememberSaveable { mutableStateOf(preselectedCourseId) }
    var selectedBagId by rememberSaveable { mutableStateOf<String?>(null) }
    var roundDate by rememberSaveable { mutableStateOf(System.currentTimeMillis()) }
    var selectedMode by rememberSaveable { mutableStateOf(preselectedMode) }
    val otherPlayers = rememberSaveable(
        saver = listSaver<SnapshotStateList<String>, String>(save = { it.toList() }, restore = { it.toMutableStateList() }),
    ) {
        mutableStateListOf<String>().apply { repeat(maxOf(1, preselectedMode.minOtherPlayers)) { add("") } }
    }
    var warnMissingNames by remember { mutableStateOf(false) }
    var showSelector by remember { mutableStateOf(false) }
    var showModePicker by remember { mutableStateOf(false) }
    var showDatePicker by remember { mutableStateOf(false) }
    var initialized by rememberSaveable { mutableStateOf(false) }
    // Platz-IDs vor dem Sprung zur Platzverwaltung – ein danach neuer Platz wird gewählt.
    var knownCourseIds by remember { mutableStateOf<Set<String>?>(null) }

    val selectedCourse = data.course(selectedCourseId)

    LaunchedEffect(Unit) {
        if (!initialized) {
            initialized = true
            if (selectedCourseId == null && courses.size == 1) selectedCourseId = courses.first().id
            if (selectedBagId == null) selectedBagId = bags.firstOrNull()?.id
        }
    }
    LaunchedEffect(data.courses) {
        val known = knownCourseIds ?: return@LaunchedEffect
        data.courses.firstOrNull { it.id !in known }?.let { selectedCourseId = it.id; knownCourseIds = null }
    }

    fun adjustPlayers(mode: GameMode) {
        val needed = mode.minOtherPlayers
        if (needed == 0) { otherPlayers.clear(); otherPlayers.add(""); return }
        while (otherPlayers.size < needed) otherPlayers.add("")
        while (otherPlayers.size > mode.maxOtherPlayers) otherPlayers.removeAt(otherPlayers.lastIndex)
    }

    fun openCourseManager() {
        Haptics.tap()
        knownCourseIds = data.courses.map { it.id }.toSet()
        nav.navigate(Routes.COURSES)
    }

    fun startRound() {
        val course = selectedCourse ?: return
        val validNames = if (selectedMode.isMultiplayer) otherPlayers.filter { it.isNotBlank() } else emptyList()
        val holes = (1..course.numberOfHoles).map { HoleScore(holeNumber = it) }
        val phs = (1..course.numberOfHoles).flatMap { h ->
            validNames.mapIndexed { idx, name -> PlayerHoleScore(idx + 1, name, h, course.par(h)) }
        }
        val round = Round(
            date = roundDate, courseId = course.id, gameModeRaw = selectedMode.raw, bagId = selectedBagId,
            otherPlayerNames = validNames, holeScores = holes, playerHoleScores = phs,
        )
        GolfStore.upsertRound(round)
        // Offene-Runde-Erinnerung: falls die Runde morgen früh noch nicht abgeschlossen ist
        RoundReminders.scheduleOpenRound(ctx, course.name)
        nav.navigate(Routes.playRound(round.id)) { popUpTo(Routes.NEW_ROUND) { inclusive = true } }
    }

    fun handleStart() {
        val hasEmpty = selectedMode.isMultiplayer && otherPlayers.any { it.isBlank() }
        if (hasEmpty && !warnMissingNames) {
            Haptics.warning()
            warnMissingNames = true
            return
        }
        warnMissingNames = false
        Haptics.medium()
        startRound()
    }

    Column(Modifier.fillMaxSize().background(AppTheme.bg)) {
        SheetTopBar(
            "Neue Runde",
            leading = { BarIconButton(Icons.Filled.Close, tint = AppTheme.textSec, description = "Schließen") { Haptics.tap(); nav.popBackStack() } },
        )
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).imePadding(),
        ) {
            // Platz
            Row(verticalAlignment = Alignment.Bottom) {
                SectionHeader("Platz", Modifier.weight(1f))
                Row(
                    Modifier.clickable { openCourseManager() }.padding(bottom = 6.dp, end = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.Add, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                    Text("Platz hinzufügen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            }
            GroupCard {
                if (courses.isEmpty() && catalog.isEmpty()) {
                    Row(
                        Modifier.fillMaxWidth().clickable { openCourseManager() }.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.AddCircle, null, tint = AppTheme.gold)
                        Spacer(Modifier.width(8.dp))
                        Text("Ersten Platz hinzufügen", color = AppTheme.gold)
                    }
                } else {
                    Row(
                        Modifier.fillMaxWidth().clickable { Haptics.tap(); showSelector = true }
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.Place, null, tint = if (selectedCourse != null) AppTheme.gold else AppTheme.textSec, modifier = Modifier.size(26.dp))
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            if (selectedCourse != null) {
                                Text(selectedCourse.name, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                                Text("${selectedCourse.numberOfHoles} Löcher · Par ${selectedCourse.totalPar}", color = AppTheme.textSec, fontSize = 12.sp)
                            } else {
                                Text("Platz wählen …", color = AppTheme.textSec)
                            }
                        }
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer)
                    }
                }
            }

            // Schläger-Bag (nur wenn Bags existieren)
            if (bags.isNotEmpty()) {
                SectionHeader("Schläger-Bag")
                GroupCard {
                    bags.forEachIndexed { i, bag ->
                        BagRow(bag, selected = bag.id == selectedBagId) {
                            Haptics.selection()
                            selectedBagId = if (selectedBagId == bag.id) null else bag.id
                        }
                        if (i < bags.lastIndex) HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(start = 54.dp))
                    }
                }
            }

            // Datum
            SectionHeader("Datum")
            GroupCard {
                Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("Datum", color = AppTheme.text, modifier = Modifier.weight(1f))
                    Text(
                        SimpleDateFormat("dd.MM.yyyy", Locale.GERMANY).format(roundDate),
                        color = AppTheme.gold,
                        modifier = Modifier.background(AppTheme.cardAlt, RoundedCornerShape(8.dp))
                            .clickable { Haptics.tap(); showDatePicker = true }
                            .padding(horizontal = 12.dp, vertical = 6.dp),
                    )
                }
            }

            // Spielmodus
            SectionHeader("Spielmodus")
            GroupCard {
                Row(
                    Modifier.fillMaxWidth().clickable { Haptics.tap(); showModePicker = true }.padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(selectedMode.icon, null, tint = AppTheme.gold, modifier = Modifier.width(32.dp).size(24.dp))
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(selectedMode.displayName, color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                        Text(selectedMode.shortDesc(), color = AppTheme.textSec, fontSize = 12.sp)
                    }
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer)
                }
            }

            // Mitspieler
            if (selectedMode.isMultiplayer) {
                SectionHeader("Spieler")
                GroupCard {
                    otherPlayers.forEachIndexed { i, name ->
                        val empty = name.isBlank()
                        val warn = warnMissingNames && empty
                        Row(
                            Modifier.fillMaxWidth()
                                .background(if (warn) IosColors.red.copy(alpha = 0.12f) else Color.Transparent)
                                .padding(horizontal = 16.dp, vertical = 14.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(Icons.Filled.Person, null, tint = if (warn) IosColors.red else AppTheme.gold, modifier = Modifier.width(24.dp))
                            Spacer(Modifier.width(8.dp))
                            Box(Modifier.weight(1f)) {
                                if (name.isEmpty()) Text(playerPlaceholder(selectedMode, i + 2), color = AppTheme.textTer)
                                BasicTextField(
                                    value = name,
                                    onValueChange = { otherPlayers[i] = it; if (warnMissingNames) warnMissingNames = false },
                                    singleLine = true,
                                    textStyle = TextStyle(color = AppTheme.text, fontSize = 16.sp),
                                    cursorBrush = SolidColor(AppTheme.gold),
                                    modifier = Modifier.fillMaxWidth(),
                                )
                            }
                        }
                        HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(start = 48.dp))
                    }
                    if (otherPlayers.size < selectedMode.maxOtherPlayers) {
                        ActionRow(Icons.Filled.Add, "Spieler hinzufügen", AppTheme.gold) { Haptics.tap(); otherPlayers.add("") }
                    }
                    if (otherPlayers.size > selectedMode.minOtherPlayers) {
                        ActionRow(Icons.Filled.Remove, "Spieler entfernen", IosColors.red) {
                            Haptics.light(); otherPlayers.removeAt(otherPlayers.lastIndex)
                        }
                    }
                }
                if (warnMissingNames) {
                    Row(Modifier.padding(start = 16.dp, top = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Warning, null, tint = IosColors.orange, modifier = Modifier.size(14.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Namen eingeben oder erneut drücken, um ohne Namen zu starten.", color = AppTheme.textSec, fontSize = 12.sp)
                    }
                } else if (playerFooter(selectedMode).isNotEmpty()) {
                    SectionFooter(playerFooter(selectedMode))
                }
            }
            Spacer(Modifier.height(24.dp))
        }

        // Start-Knopf unten (safeAreaInset)
        Box(Modifier.fillMaxWidth().background(AppTheme.card).navigationBarsPadding().padding(horizontal = 16.dp, vertical = 10.dp)) {
            val bg by animateColorAsState(
                when {
                    selectedCourse == null -> Color.Gray.copy(alpha = 0.3f)
                    warnMissingNames -> IosColors.orange
                    else -> AppTheme.gold
                }, label = "startBg",
            )
            Box(
                Modifier.fillMaxWidth().background(bg, RoundedCornerShape(14.dp))
                    .clickable(enabled = selectedCourse != null) { handleStart() }
                    .padding(vertical = 16.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    if (warnMissingNames) "Ohne Namen starten – erneut drücken" else "Runde starten",
                    color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }

    if (showSelector) {
        CourseSelectorSheet(
            selectedCourseId = selectedCourseId,
            onSelect = { selectedCourseId = it; showSelector = false },
            onDismiss = { showSelector = false },
        )
    }
    if (showModePicker) {
        GameModePickerSheet(
            selected = selectedMode,
            onSelect = { selectedMode = it; adjustPlayers(it); warnMissingNames = false; showModePicker = false },
            onDismiss = { showModePicker = false },
        )
    }
    if (showDatePicker) {
        val utc = remember {
            // DatePicker arbeitet in UTC-Mitternacht – Uhrzeit der Runde bleibt erhalten.
            val local = Calendar.getInstance().apply { timeInMillis = roundDate }
            Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
                clear(); set(local.get(Calendar.YEAR), local.get(Calendar.MONTH), local.get(Calendar.DAY_OF_MONTH))
            }.timeInMillis
        }
        val state = rememberDatePickerState(initialSelectedDateMillis = utc)
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    Haptics.tap()
                    state.selectedDateMillis?.let { sel ->
                        val u = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { timeInMillis = sel }
                        roundDate = Calendar.getInstance().apply {
                            timeInMillis = roundDate
                            set(u.get(Calendar.YEAR), u.get(Calendar.MONTH), u.get(Calendar.DAY_OF_MONTH))
                        }.timeInMillis
                    }
                    showDatePicker = false
                }) { Text("OK", color = AppTheme.gold) }
            },
            dismissButton = { TextButton(onClick = { showDatePicker = false }) { Text("Abbrechen", color = AppTheme.textSec) } },
            colors = DatePickerDefaults.colors(containerColor = AppTheme.card),
        ) { DatePicker(state = state) }
    }
}

@Composable
private fun BagRow(bag: GolfBag, selected: Boolean, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(if (selected) AppTheme.gold.copy(alpha = 0.08f) else Color.Transparent)
            .clickable { onClick() }.padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.ShoppingBag, null, tint = if (selected) AppTheme.gold else AppTheme.textSec, modifier = Modifier.size(24.dp))
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(bag.name, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            Text("${bag.clubs.size} Schläger", color = AppTheme.textSec, fontSize = 12.sp)
        }
        if (selected) Icon(Icons.Filled.CheckCircle, null, tint = AppTheme.gold)
    }
}

@Composable
private fun ActionRow(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String, color: Color, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable { onClick() }.padding(horizontal = 16.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = color, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(8.dp))
        Text(text, color = color, fontSize = 15.sp)
    }
}

private fun playerPlaceholder(mode: GameMode, index: Int): String = when (mode) {
    GameMode.MATCHPLAY -> "Gegner Name"
    GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD, GameMode.SCRAMBLE_2_MANN,
    GameMode.VIERER, GameMode.GREENSOME -> "Partner Name"
    GameMode.BETTER_BALL_MATCHPLAY -> when (index) { 2 -> "Partner Name"; 3 -> "Gegner 1"; else -> "Gegner 2" }
    GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD, GameMode.SCRAMBLE_TEAM -> "Mitspieler ${index - 1} Name"
    else -> "Spieler $index Name"
}

private fun playerFooter(mode: GameMode): String = when (mode) {
    GameMode.MATCHPLAY -> "Dein Gegner für das Matchplay."
    GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD -> "Dein Partner – der bessere Score pro Loch zählt für das Team."
    GameMode.SCRAMBLE_2_MANN -> "Dein Partner – beide schlagen ab, der beste wird gewählt."
    GameMode.VIERER -> "Dein Partner – ihr spielt abwechselnd mit einem Ball (Wechselschlag)."
    GameMode.GREENSOME -> "Dein Partner – beide schlagen ab, bester Abschlag gewählt, dann Wechselschlag."
    GameMode.BETTER_BALL_MATCHPLAY -> "Zuerst dein Partner, dann deine Gegner eintragen. Pro Team zählt der bessere Score."
    GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD -> "Alle Mitspieler eintragen – der beste Score pro Loch zählt fürs Team."
    GameMode.SCRAMBLE_TEAM -> "Alle Mitspieler – alle schlagen ab, bester Abschlag wird gespielt."
    GameMode.SKINS -> "Spieler, die gegeneinander um Skins spielen."
    else -> ""
}

/** Wie GameModePickerView.swift – Liste der verfügbaren Spielformen mit Info-Knopf. */
@Composable
fun GameModePickerSheet(selected: GameMode, onSelect: (GameMode) -> Unit, onDismiss: () -> Unit) {
    var detail by remember { mutableStateOf<GameMode?>(null) }
    FullSheet(onDismiss) {
        Column(Modifier.fillMaxSize()) {
            SheetTopBar("Spielmodus wählen", leading = { BarButton("Zurück") { Haptics.tap(); onDismiss() } })
            Column(Modifier.verticalScroll(rememberScrollState()).navigationBarsPadding()) {
                GameMode.entries.filter { it.isAvailable }.forEach { mode ->
                    val sel = mode == selected
                    Row(
                        Modifier.fillMaxWidth().background(if (sel) AppTheme.gold.copy(alpha = 0.10f) else AppTheme.card),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Row(
                            Modifier.weight(1f).clickable { Haptics.success(); onSelect(mode) }.padding(start = 16.dp, top = 12.dp, bottom = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(
                                Modifier.size(40.dp).background(if (sel) AppTheme.gold.copy(alpha = 0.15f) else AppTheme.cardAlt, CircleShape),
                                contentAlignment = Alignment.Center,
                            ) { Icon(mode.icon, null, tint = if (sel) AppTheme.gold else AppTheme.textSec, modifier = Modifier.size(20.dp)) }
                            Spacer(Modifier.width(14.dp))
                            Column(Modifier.weight(1f)) {
                                Text(mode.displayName, color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                                Text(gameModeListDesc(mode), color = AppTheme.textSec, fontSize = 12.sp)
                            }
                            if (sel) Icon(Icons.Filled.CheckCircle, null, tint = AppTheme.gold, modifier = Modifier.size(24.dp))
                        }
                        Box(
                            Modifier.clickable { Haptics.tap(); detail = mode }.padding(horizontal = 12.dp).height(44.dp),
                            contentAlignment = Alignment.Center,
                        ) { Icon(Icons.Filled.Info, contentDescription = "Info", tint = AppTheme.textSec, modifier = Modifier.size(20.dp)) }
                    }
                    HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(start = 70.dp))
                }
            }
        }
    }
    detail?.let { mode ->
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { detail = null },
            icon = { Icon(mode.icon, null, tint = AppTheme.gold) },
            title = { Text(if (mode.subtitle.isEmpty()) mode.displayName else "${mode.displayName} · ${mode.subtitle}") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(mode.category.title, color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                    Text(mode.description, color = AppTheme.text)
                    val players = when {
                        mode.maxOtherPlayers == 0 -> "Einzelspieler"
                        mode.minOtherPlayers == mode.maxOtherPlayers -> "${mode.minOtherPlayers + 1} Spieler"
                        else -> "${mode.minOtherPlayers + 1}–${mode.maxOtherPlayers + 1} Spieler"
                    }
                    Text(players, color = AppTheme.textSec, fontSize = 13.sp)
                }
            },
            confirmButton = { TextButton(onClick = { Haptics.tap(); detail = null }) { Text("Fertig", color = AppTheme.gold) } },
            containerColor = AppTheme.card,
        )
    }
}

/** Leicht kürzere Texte als in NewRoundView – wie `shortDesc` in GameModePickerView. */
private fun gameModeListDesc(mode: GameMode): String = when (mode) {
    GameMode.VIERER -> "Ein Ball, zwei Spieler – abwechselnd schlagen"
    GameMode.BEST_BALL_STROKE -> "3–4 Spieler – bester Score pro Loch zählt"
    GameMode.BEST_BALL_STABLEFORD -> "3–4 Spieler – beste Stableford-Punkte pro Loch"
    else -> mode.shortDesc().removeSuffix("…")
}
