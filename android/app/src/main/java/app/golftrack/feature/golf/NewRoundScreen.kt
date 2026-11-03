package app.golftrack.feature.golf

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.filled.UnfoldMore
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextOverflow
import app.golftrack.data.Course
import app.golftrack.data.GameModeCategory
import app.golftrack.data.HandicapCalculator
import app.golftrack.data.TeeColor
import app.golftrack.data.rememberPrefInt
import app.golftrack.data.rememberPrefString
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.toMutableStateList
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.snapshots.SnapshotStateList
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.feature.lobby.LobbyCard
import app.golftrack.feature.lobby.LobbyService
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

/**
 * Wie NewRoundView.swift: Platz, Spielform (Einzel/Partner/Team), Bag, Abschlag,
 * Datum, Spieler → Runde starten (mit Ladeseite und Eintrage-Hinweis).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewRoundScreen(nav: NavController, preselectedCourseId: String?, preselectedMode: GameMode = GameMode.STROKE_PLAY) {
    val ctx = LocalContext.current
    val data by GolfStore.data.collectAsState()
    val courses = remember(data.courses) { data.courses.sortedBy { it.name.lowercase() } }
    val bags = remember(data.bags) { data.bags.sortedBy { it.createdAt } }
    val catalog by CourseCatalog.golfCourses.collectAsState()
    val playerName by rememberPrefString("playerName", "Golfer")
    // Zuletzt gespielte Abschlagfarbe – Vorauswahl für die nächste Runde.
    var lastTeeColorRaw by rememberPrefString("lastTeeColor", TeeColor.YELLOW.raw)
    // Wie oft hier schon eine Runde gestartet wurde – steuert die Ladeseite.
    var roundStartCount by rememberPrefInt("roundStartCount")

    var selectedCourseId by rememberSaveable { mutableStateOf(preselectedCourseId) }
    var selectedBagId by rememberSaveable { mutableStateOf<String?>(null) }
    var selectedTeeRaw by rememberSaveable { mutableStateOf<String?>(null) }
    var roundDate by rememberSaveable { mutableStateOf(System.currentTimeMillis()) }
    var selectedMode by rememberSaveable { mutableStateOf(preselectedMode) }
    var category by rememberSaveable { mutableStateOf(preselectedMode.category) }
    val otherPlayers = rememberSaveable(
        saver = listSaver<SnapshotStateList<String>, String>(save = { it.toList() }, restore = { it.toMutableStateList() }),
    ) {
        mutableStateListOf<String>().apply { repeat(maxOf(1, preselectedMode.minOtherPlayers)) { add("") } }
    }
    var warnMissingNames by remember { mutableStateOf(false) }
    var showSelector by remember { mutableStateOf(false) }
    var showModePicker by remember { mutableStateOf(false) }
    var showDatePicker by remember { mutableStateOf(false) }
    var showBagMenu by remember { mutableStateOf(false) }
    var showLoading by remember { mutableStateOf(false) }
    var initialized by rememberSaveable { mutableStateOf(false) }
    // Platz-IDs vor dem Sprung zur Platzverwaltung – ein danach neuer Platz wird gewählt.
    var knownCourseIds by remember { mutableStateOf<Set<String>?>(null) }

    val selectedCourse = data.course(selectedCourseId)
    val selectedBag = data.bag(selectedBagId)
    val selectedTee = TeeColor.fromRaw(selectedTeeRaw)
    val teeColors = selectedCourse?.availableTeeColors ?: TeeColor.commonSet
    val availableModes = remember { GameMode.entries.filter { it.isAvailable } }
    val modesInCategory = availableModes.filter { it.category == category }
    // Freunde aus der Lobby, die bei Spielformen mit Mitspielern als Mitspieler in die Runde gehen.
    val lobbySession by LobbyService.session.collectAsState()
    val lobbyState by LobbyService.state.collectAsState()
    val lobbyFriends = if (lobbySession != null && selectedMode.isMultiplayer)
        lobbyState?.others.orEmpty().take(selectedMode.maxOtherPlayers) else emptyList()

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
    // Gespeicherte Plätze kennen die Farben des Verzeichnisses erst, wenn sie
    // dort nachgetragen wurden – beim Rundenstart einmal nachziehen.
    LaunchedEffect(selectedCourseId, catalog) {
        val course = selectedCourse ?: return@LaunchedEffect
        if (course.tees.isNotEmpty()) return@LaunchedEffect
        val entry = catalog.firstOrNull { it.name.equals(course.name, ignoreCase = true) && it.tees.isNotEmpty() } ?: return@LaunchedEffect
        GolfStore.upsertCourse(course.copy(tees = entry.tees))
    }
    // Vorauswahl: bisherige Wahl, sonst die zuletzt gespielte Farbe, sonst Gelb.
    LaunchedEffect(teeColors) {
        if (selectedTee != null && selectedTee in teeColors) return@LaunchedEffect
        val last = TeeColor.fromRaw(lastTeeColorRaw)
        selectedTeeRaw = (if (last != null && last in teeColors) last
            else if (TeeColor.YELLOW in teeColors) TeeColor.YELLOW else teeColors.firstOrNull())?.raw
    }

    fun selectMode(mode: GameMode) {
        selectedMode = mode
        val needed = mode.minOtherPlayers
        if (needed == 0) { otherPlayers.clear(); otherPlayers.add("") }
        else {
            while (otherPlayers.size < needed) otherPlayers.add("")
            while (otherPlayers.size > mode.maxOtherPlayers) otherPlayers.removeAt(otherPlayers.lastIndex)
        }
        // Auswahl über „Alle erklärt“ kann die Kategorie wechseln.
        if (category != mode.category) category = mode.category
        warnMissingNames = false
    }

    fun openCourseManager() {
        Haptics.tap()
        knownCourseIds = data.courses.map { it.id }.toSet()
        nav.navigate(Routes.COURSES)
    }

    fun startRound() {
        val course = GolfStore.current.course(selectedCourseId) ?: return
        var validNames = if (selectedMode.isMultiplayer) otherPlayers.filter { it.isNotBlank() } else emptyList()
        // Freunde aus der Lobby zuerst – ihre Schläge kommen von ihrem Handy.
        val friends = lobbyFriends
        if (friends.isNotEmpty()) validNames = (friends.map { it.name } + validNames).take(selectedMode.maxOtherPlayers)
        val holes = (1..course.numberOfHoles).map { HoleScore(holeNumber = it) }
        // Mitspieler starten wie der eigene Spieler mit 0 Schlägen.
        val phs = (1..course.numberOfHoles).flatMap { h ->
            validNames.mapIndexed { idx, name -> PlayerHoleScore(idx + 1, name, h, 0) }
        }
        val round = Round(
            date = roundDate, courseId = course.id, gameModeRaw = selectedMode.raw, bagId = selectedBagId,
            otherPlayerNames = validNames, holeScores = holes, playerHoleScores = phs,
            teeColorRaw = selectedTee?.raw ?: "",
            lobbyCode = LobbyService.code ?: "",
            lobbyMemberIDsRaw = friends.joinToString("|") { it.id },
        )
        selectedTee?.let { lastTeeColorRaw = it.raw }
        GolfStore.upsertRound(round)
        // Offene-Runde-Erinnerung: falls die Runde morgen früh noch nicht abgeschlossen ist
        RoundReminders.scheduleOpenRound(ctx, course.name)
        nav.navigate(Routes.playRound(round.id)) { popUpTo(Routes.NEW_ROUND) { inclusive = true } }
    }

    fun handleStart() {
        val hasEmpty = selectedMode.isMultiplayer && lobbyFriends.isEmpty() && otherPlayers.any { it.isBlank() }
        if (hasEmpty && !warnMissingNames) {
            Haptics.warning()
            warnMissingNames = true
            return
        }
        warnMissingNames = false
        Haptics.medium()
        val showHint = RoundLoading.shouldShow(roundStartCount)
        roundStartCount += 1
        if (showHint) showLoading = true else startRound()
    }

    Box(Modifier.fillMaxSize()) {
    Column(Modifier.fillMaxSize().background(AppTheme.bg)) {
        SheetTopBar(
            "Neue Runde",
            leading = { BarIconButton(Icons.Filled.Close, tint = AppTheme.textSec, description = "Schließen") { Haptics.tap(); nav.popBackStack() } },
        )
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).padding(top = 8.dp, bottom = 16.dp).imePadding(),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            // Platz
            FormSection("Platz", accessory = {
                Row(Modifier.clickable { openCourseManager() }, verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Add, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("Platz hinzufügen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            }) {
                val noCourses = courses.isEmpty() && catalog.isEmpty()
                FormCard(Modifier.clickable { Haptics.tap(); if (noCourses) openCourseManager() else showSelector = true }) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            Modifier.size(40.dp).background(
                                if (selectedCourse != null) AppTheme.gold else AppTheme.gold.copy(alpha = 0.15f), RoundedCornerShape(11.dp),
                            ),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(if (noCourses) Icons.Filled.Add else Icons.Filled.Flag, null,
                                tint = if (selectedCourse != null) IosColors.onGoldDark else AppTheme.gold, modifier = Modifier.size(18.dp))
                        }
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            when {
                                selectedCourse != null -> {
                                    Text(selectedCourse.name, color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                                        maxLines = 1, overflow = TextOverflow.Ellipsis)
                                    Text("${selectedCourse.numberOfHoles} Löcher · Par ${selectedCourse.totalPar}", color = AppTheme.textSec, fontSize = 12.sp)
                                }
                                noCourses -> Text("Ersten Platz hinzufügen", color = AppTheme.gold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                                else -> Text("Platz wählen …", color = AppTheme.textSec, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                            }
                        }
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))
                    }
                }
            }

            // Spielform
            FormSection("Spielform", accessory = {
                Text("Alle erklärt", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.clickable { Haptics.tap(); showModePicker = true })
            }) {
                FormCard {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Row(Modifier.fillMaxWidth().background(AppTheme.cardDark, RoundedCornerShape(50)).padding(3.dp)) {
                            listOf(GameModeCategory.INDIVIDUAL to "Einzel", GameModeCategory.PARTNER to "Partner", GameModeCategory.TEAM to "Team")
                                .forEach { (value, title) ->
                                    val sel = category == value
                                    Box(
                                        Modifier.weight(1f).background(if (sel) AppTheme.gold else Color.Transparent, RoundedCornerShape(50))
                                            .clickable {
                                                if (sel) return@clickable
                                                Haptics.selection()
                                                category = value
                                                if (selectedMode.category != value) availableModes.firstOrNull { it.category == value }?.let { selectMode(it) }
                                            }
                                            .padding(vertical = 7.dp),
                                        contentAlignment = Alignment.Center,
                                    ) {
                                        Text(title, color = if (sel) IosColors.onGoldDark else AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                                    }
                                }
                        }
                        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                            modesInCategory.forEach { mode ->
                                val sel = selectedMode == mode
                                // Mehrere Formen heißen gleich („Better Ball“) – dann hilft der Untertitel.
                                val twins = modesInCategory.count { it.displayName == mode.displayName }
                                val title = if (twins > 1 && mode.subtitle.isNotEmpty()) "${mode.displayName} · ${mode.subtitle}" else mode.displayName
                                Chip(sel, onClick = { Haptics.selection(); selectMode(mode) }, background = if (sel) AppTheme.gold.copy(alpha = 0.16f) else AppTheme.cardAlt) {
                                    Text(title, color = if (sel) AppTheme.gold else AppTheme.text.copy(alpha = 0.85f), fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                                }
                            }
                        }
                        Row(verticalAlignment = Alignment.Top) {
                            Icon(selectedMode.icon, null, tint = AppTheme.gold, modifier = Modifier.width(20.dp).size(16.dp))
                            Spacer(Modifier.width(8.dp))
                            Text(selectedMode.shortDesc(), color = AppTheme.textSec, fontSize = 12.sp)
                        }
                    }
                }
            }

            // Bag
            if (bags.isNotEmpty()) {
                FormSection("Bag") {
                    Box {
                        FormCard(Modifier.clickable { Haptics.tap(); showBagMenu = true }) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Filled.ShoppingBag, null, tint = if (selectedBag != null) AppTheme.gold else AppTheme.textSec,
                                    modifier = Modifier.width(28.dp).size(22.dp))
                                Spacer(Modifier.width(12.dp))
                                Text(selectedBag?.name ?: "Ohne Bag", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                                selectedBag?.let { Text("${it.clubs.size} Schläger", color = AppTheme.textSec, fontSize = 12.sp) }
                                if (bags.size > 1 || selectedBag == null) {
                                    Spacer(Modifier.width(8.dp))
                                    Icon(Icons.Filled.UnfoldMore, null, tint = AppTheme.textTer, modifier = Modifier.size(14.dp))
                                }
                            }
                        }
                        DropdownMenu(showBagMenu, onDismissRequest = { showBagMenu = false }, containerColor = AppTheme.card) {
                            bags.forEach { bag ->
                                DropdownMenuItem(
                                    text = { Text(bag.name, color = AppTheme.text) },
                                    leadingIcon = if (bag.id == selectedBagId) { { Icon(Icons.Filled.Check, null, tint = AppTheme.gold) } } else null,
                                    onClick = { Haptics.selection(); selectedBagId = bag.id; showBagMenu = false },
                                )
                            }
                            HorizontalDivider(color = AppTheme.cardAlt)
                            DropdownMenuItem(
                                text = { Text("Ohne Bag", color = AppTheme.text) },
                                leadingIcon = { Icon(Icons.Filled.Close, null, tint = AppTheme.textSec) },
                                onClick = { Haptics.selection(); selectedBagId = null; showBagMenu = false },
                            )
                        }
                    }
                }
            }

            // Abschlag
            if (selectedCourse != null) {
                FormSection("Abschlag") {
                    FormCard(padding = 8) {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                teeColors.forEach { tee ->
                                    val sel = selectedTee == tee
                                    Chip(sel, onClick = { Haptics.selection(); selectedTeeRaw = tee.raw },
                                        background = if (sel) AppTheme.gold.copy(alpha = 0.16f) else Color.Transparent, horizontal = 14) {
                                        TeeDot(tee, 12)
                                        Spacer(Modifier.width(7.dp))
                                        Text(tee.displayName, color = if (sel) AppTheme.gold else AppTheme.text.copy(alpha = 0.85f),
                                            fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                                    }
                                }
                            }
                            teeInfo(selectedCourse, selectedTee)?.let {
                                Text(it, color = AppTheme.textSec, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 6.dp).padding(bottom = 2.dp))
                            }
                        }
                    }
                }
            }

            // Datum
            FormSection("Datum") {
                FormCard(padding = 10) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.CalendarMonth, null, tint = AppTheme.gold, modifier = Modifier.width(28.dp).size(22.dp))
                        Spacer(Modifier.width(12.dp))
                        Text(
                            SimpleDateFormat("dd.MM.yyyy", Locale.GERMANY).format(roundDate),
                            color = AppTheme.gold,
                            modifier = Modifier.background(AppTheme.cardAlt, RoundedCornerShape(8.dp))
                                .clickable { Haptics.tap(); showDatePicker = true }
                                .padding(horizontal = 12.dp, vertical = 6.dp),
                        )
                    }
                }
            }

            // Spieler
            FormSection("Spieler") {
                FormCard {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        PlayerRow(playerName.take(1).uppercase()) {
                            Text(playerName, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            Text("HCP ${HandicapCalculator.displayString(data.completedRounds, data)}", color = AppTheme.textSec,
                                fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                        }
                        if (selectedMode.isMultiplayer) {
                            otherPlayers.forEachIndexed { i, name ->
                                val empty = name.isBlank()
                                val canRemove = otherPlayers.size > selectedMode.minOtherPlayers
                                PlayerRow(if (empty) "${i + 2}" else name.take(1).uppercase(), highlight = warnMissingNames && empty) {
                                    Box(Modifier.weight(1f)) {
                                        if (name.isEmpty()) Text(playerPlaceholder(selectedMode, i + 2), color = AppTheme.textTer, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                                        BasicTextField(
                                            value = name,
                                            onValueChange = { otherPlayers[i] = it; if (warnMissingNames) warnMissingNames = false },
                                            singleLine = true,
                                            textStyle = TextStyle(color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.SemiBold),
                                            cursorBrush = SolidColor(AppTheme.gold),
                                            keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words),
                                            modifier = Modifier.fillMaxWidth(),
                                        )
                                    }
                                    if (canRemove) {
                                        Icon(
                                            Icons.Filled.RemoveCircle, "Spieler entfernen", tint = AppTheme.textTer,
                                            modifier = Modifier.size(24.dp).clickable { Haptics.light(); otherPlayers.removeAt(i) },
                                        )
                                    }
                                }
                            }
                            if (otherPlayers.size < selectedMode.maxOtherPlayers) {
                                Row(
                                    Modifier.fillMaxWidth().clickable { Haptics.tap(); otherPlayers.add("") },
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Icon(Icons.Filled.AddCircle, null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
                                    Spacer(Modifier.width(8.dp))
                                    Text("Spieler hinzufügen", color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                                }
                            }
                        }
                    }
                }
                val footer = when {
                    warnMissingNames -> null
                    selectedMode.isMultiplayer -> playerFooter(selectedMode).takeIf { it.isNotEmpty() }
                    else -> "Mitspieler trägst du bei Partner- und Team-Spielformen ein."
                }
                if (warnMissingNames) {
                    Row(Modifier.padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Warning, null, tint = IosColors.orange, modifier = Modifier.size(14.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Namen eingeben oder erneut drücken, um ohne Namen zu starten.", color = AppTheme.textSec, fontSize = 12.sp)
                    }
                } else if (footer != null) {
                    Text(footer, color = AppTheme.textSec, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 4.dp))
                }
            }

            // Freunde (Lobby)
            FormSection("Freunde") {
                LobbyCard(
                    selectedCourse = selectedCourse,
                    courses = courses,
                    playerName = playerName,
                    onSelectCourse = { selectedCourseId = it },
                )
            }
        }

        // Start-Knopf unten (safeAreaInset)
        Box(Modifier.fillMaxWidth().background(AppTheme.bg.copy(alpha = 0.96f)).navigationBarsPadding().padding(start = 16.dp, end = 16.dp, top = 10.dp, bottom = 6.dp)) {
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
                    color = if (selectedCourse == null) AppTheme.textSec else IosColors.onGoldDark, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                )
            }
        }
    }

    AnimatedVisibility(showLoading, enter = fadeIn(tween(250)), exit = fadeOut(tween(350))) {
        RoundLoading.Screen(selectedCourse?.name ?: "") {
            startRound()
            showLoading = false
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
            onSelect = { selectMode(it); showModePicker = false },
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

/** „CR 71,2 · Slope 130 · 5.533 m“ – nur was für den Abschlag bekannt ist. */
private fun teeInfo(course: Course, color: TeeColor?): String? {
    val tee = course.tee(color) ?: return null
    val parts = buildList {
        tee.courseRating?.let { add("CR " + String.format(Locale.GERMANY, "%.1f", it)) }
        tee.slopeRating?.let { add("Slope $it") }
        val total = tee.holeLengths.sumOf { maxOf(0, it) }
        if (total > 0) add(String.format(Locale.GERMANY, "%,d m", total))
    }
    return parts.takeIf { it.isNotEmpty() }?.joinToString(" · ")
}

/** Abschnitt mit kleiner Großbuchstaben-Überschrift wie `section(_:)` in NewRoundView. */
@Composable
private fun FormSection(title: String, accessory: (@Composable () -> Unit)? = null, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(title.uppercase(), color = AppTheme.textTer, fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.6.sp, modifier = Modifier.weight(1f))
            accessory?.invoke()
        }
        content()
    }
}

@Composable
private fun FormCard(modifier: Modifier = Modifier, padding: Int = 12, content: @Composable () -> Unit) {
    Box(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(AppTheme.card).then(modifier).padding(padding.dp),
    ) { content() }
}

@Composable
private fun Chip(
    selected: Boolean, onClick: () -> Unit, background: Color, horizontal: Int = 13,
    content: @Composable androidx.compose.foundation.layout.RowScope.() -> Unit,
) {
    Row(
        Modifier.clip(RoundedCornerShape(50)).background(background)
            .border(1.dp, if (selected) AppTheme.gold.copy(alpha = 0.6f) else Color.Transparent, RoundedCornerShape(50))
            .clickable { onClick() }.padding(horizontal = horizontal.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) { content() }
}

@Composable
private fun PlayerRow(initial: String, highlight: Boolean = false, content: @Composable androidx.compose.foundation.layout.RowScope.() -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(
            Modifier.size(32.dp).background((if (highlight) IosColors.orange else AppTheme.gold).copy(alpha = 0.85f), CircleShape),
            contentAlignment = Alignment.Center,
        ) { Text(initial.ifEmpty { "?" }, color = IosColors.onGoldDark, fontSize = 15.sp, fontWeight = FontWeight.Bold) }
        content()
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
