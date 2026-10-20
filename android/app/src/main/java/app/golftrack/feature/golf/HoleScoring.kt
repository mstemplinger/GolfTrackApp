package app.golftrack.feature.golf

import app.golftrack.feature.ads.AdPlacement
import app.golftrack.feature.ads.AdSlot

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
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
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.AddCircleOutline
import androidx.compose.material.icons.filled.Autorenew
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.LocationOff
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.SupervisedUserCircle
import androidx.compose.material.icons.filled.SwapVert
import androidx.compose.material.icons.outlined.LocationOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.VerticalDivider
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.GameMode
import app.golftrack.data.GameScoringEngine
import app.golftrack.data.GolfBag
import app.golftrack.data.GolfClub
import app.golftrack.data.GolfStore
import app.golftrack.data.HoleOutcome
import app.golftrack.data.HoleScore
import app.golftrack.data.LatLon
import app.golftrack.data.PlayerHoleScore
import app.golftrack.data.Round
import app.golftrack.data.Shot
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.data.rememberPrefBool
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlin.math.abs

/** Wie HoleScoringView.swift – ein Loch zählen: Entfernung, Schläge, Putts, Mitspieler. */
@Composable
fun HoleScoring(
    nav: NavController,
    round: Round,
    course: Course?,
    score: HoleScore,
    par: Int,
    holeCount: Int,
    here: LatLon?,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
) {
    val data by GolfStore.data.collectAsState()
    val catalog by CourseCatalog.golfCourses.collectAsState()
    val unit = rememberDistanceUnit()
    val hole = score.holeNumber
    val roundId = round.id

    val clubs: List<GolfClub> = data.bag(round.bagId)?.sortedClubs
        ?: data.bags.flatMap { it.clubs }.sortedBy { it.order }

    var showShotTracker by remember { mutableStateOf(false) }
    var showPinSetter by remember { mutableStateOf(false) }
    var showHoleOverview by remember { mutableStateOf(false) }
    var showRoundOverview by remember { mutableStateOf(false) }
    var showClubPicker by remember { mutableStateOf(false) }
    var pendingLocation by remember { mutableStateOf<LatLon?>(null) }
    var pendingShotNumber by remember { mutableIntStateOf(0) }
    var showTeeHint by remember { mutableStateOf(false) }
    var showNoGps by remember { mutableStateOf(false) }
    var teeHintShown by rememberPrefBool("hint.teeSetter.shown")
    val trackingEnabled by rememberPrefBool(RoundTracker.ENABLED_KEY)

    // Platz im Verzeichnis – über den Namen gesucht (wie iOS).
    val catalogEntry = course?.name?.lowercase()?.let { n -> catalog.firstOrNull { it.name.lowercase() == n } }
    val hints = catalogEntry?.hints.orEmpty()

    val opponents = round.playerHoleScores.filter { it.holeNumber == hole }.sortedBy { it.playerIndex }

    LaunchedEffect(Unit) { if (clubs.isEmpty()) seedDefaultClubs(round) }

    // Hinterlegte (ggf. abgeleitete) Fahnenposition übernehmen, solange kein eigener Pin gesetzt ist.
    LaunchedEffect(hole, course?.flagLatitudes, course?.flagLongitudes) {
        val flag = course?.flagCoordinate(hole) ?: return@LaunchedEffect
        val cur = GolfStore.current.round(roundId)?.score(hole) ?: return@LaunchedEffect
        if (cur.hasPinLocation && !cur.pinIsAutomatic) return@LaunchedEffect
        if (cur.pinLatitude == flag.lat && cur.pinLongitude == flag.lon && cur.pinIsAutomatic) return@LaunchedEffect
        updateHole(roundId, hole) { it.copy(pinLatitude = flag.lat, pinLongitude = flag.lon, pinIsAutomatic = true) }
    }

    val pin = if (score.pinLatitude != null && score.pinLongitude != null) LatLon(score.pinLatitude, score.pinLongitude) else null
    val distanceToPin = if (pin != null && here != null) pin.distanceTo(here) else null

    fun recommendedClub(meters: Double): GolfClub? =
        clubs.minByOrNull { abs(it.averageDistance - meters.toInt()) }

    fun insertShot(number: Int, at: LatLon) {
        updateHole(roundId, hole) { hs ->
            if (hs.shots.any { it.shotNumber == number }) hs
            else hs.copy(shots = hs.shots + Shot(number, at.lat, at.lon, at.lat, at.lon))
        }
    }

    fun setTee() {
        val loc = here
        if (loc == null) { Haptics.warning(); showNoGps = true; return }
        Haptics.stroke()
        course?.let { GolfStore.upsertCourse(it.withTee(hole, loc)) }
        updateHole(roundId, hole) { if (it.strokes == 0) it.copy(strokes = 1) else it }
        insertShot(1, loc)
        pendingLocation = loc
        pendingShotNumber = 1
        if (clubs.isNotEmpty()) showClubPicker = true
    }

    fun addStroke() {
        Haptics.stroke()
        val shotNum = score.strokes + 1
        updateHole(roundId, hole) { hs ->
            var shots = hs.shots
            // Ziel des vorigen Schlags = aktuelle Position
            if (here != null) {
                val prev = hs.sortedShots.lastOrNull()
                if (prev != null) shots = shots.map { if (it.shotNumber == prev.shotNumber) it.copy(toLatitude = here.lat, toLongitude = here.lon) else it }
                // Lage sofort speichern – auch wenn die Schlägerwahl übersprungen wird.
                if (shots.none { it.shotNumber == shotNum }) shots = shots + Shot(shotNum, here.lat, here.lon, here.lat, here.lon)
            }
            hs.copy(strokes = hs.strokes + 1, shots = shots)
        }
        pendingLocation = here
        pendingShotNumber = shotNum
        if (clubs.isNotEmpty()) showClubPicker = true
    }

    fun removeStroke() {
        if (score.strokes <= 1) return
        Haptics.light()
        val removing = score.strokes
        updateHole(roundId, hole) { hs ->
            val shot = hs.shots.firstOrNull { it.shotNumber == removing }
            var putts = hs.putts
            if (shot != null && clubs.firstOrNull { it.name == shot.club }?.isPutter == true && putts > 0) putts--
            hs.copy(strokes = hs.strokes - 1, putts = putts, shots = hs.shots.filter { it.shotNumber != removing })
        }
    }

    Column(
        Modifier.padding(horizontal = 16.dp).padding(top = 8.dp, bottom = 8.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        CourseHeader(course)
        HoleCard(score, par, holeCount, course, round.gameMode, onPrevious, onNext)

        // Entfernung zum Pin
        if (pin != null) {
            Column(
                Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(20.dp)).padding(horizontal = 16.dp, vertical = 14.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Row(
                    Modifier.fillMaxWidth().clickable { Haptics.tap(); showHoleOverview = true },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(Modifier.size(44.dp).background(AppTheme.gold.copy(alpha = 0.18f), CircleShape), contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.Flag, null, tint = AppTheme.gold, modifier = Modifier.size(20.dp))
                    }
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                        if (distanceToPin != null) {
                            Text(unit.format(distanceToPin), color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                            val club = recommendedClub(distanceToPin)
                            if (club != null) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Filled.SportsGolf, null, tint = AppTheme.gold, modifier = Modifier.size(11.dp))
                                    Spacer(Modifier.width(5.dp))
                                    Text("Empfehlung:", color = AppTheme.textSec, fontSize = 12.sp)
                                    Spacer(Modifier.width(5.dp))
                                    Text(club.name, color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                    Spacer(Modifier.width(5.dp))
                                    Text("(Ø ${unit.format(club.averageDistance.toDouble())})", color = AppTheme.textTer, fontSize = 12.sp)
                                }
                            } else {
                                Text("Noch ${distanceToPin.toInt()} m zum Loch", color = AppTheme.textSec, fontSize = 12.sp)
                            }
                        } else {
                            Text("Pin gesetzt", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                            Text("Standort wird ermittelt …", color = AppTheme.textSec, fontSize = 12.sp)
                        }
                    }
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer)
                }
                Row(Modifier.clickable { Haptics.tap(); showPinSetter = true }, verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Outlined.LocationOff, null, tint = AppTheme.textTer, modifier = Modifier.size(11.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("Pin aktualisieren", color = AppTheme.textTer, fontSize = 12.sp)
                }
            }
        } else {
            Row(
                Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))
                    .clickable { Haptics.tap(); showPinSetter = true }.padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Place, null, tint = AppTheme.textSec, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(10.dp))
                Text("Lochposition festlegen", color = AppTheme.textSec, fontSize = 15.sp, modifier = Modifier.weight(1f))
                Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer)
            }
        }

        // Schläge
        Column(
            Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(20.dp)).padding(vertical = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text("SCHLÄGE", color = AppTheme.textTer, fontSize = 9.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.5.sp)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(28.dp)) {
                Icon(
                    Icons.Filled.RemoveCircle, contentDescription = "Schlag entfernen",
                    tint = if (score.strokes > 1) AppTheme.gold else AppTheme.textTer,
                    modifier = Modifier.size(56.dp).clickable(enabled = score.strokes > 1) { removeStroke() },
                )
                AnimatedContent(score.strokes, transitionSpec = { fadeIn(tween(150)) togetherWith fadeOut(tween(150)) }, label = "strokes") { s ->
                    Text(
                        "$s", color = AppTheme.text, fontSize = 72.sp, fontWeight = FontWeight.Bold,
                        modifier = Modifier.defaultMinSize(minWidth = 80.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    )
                }
                Icon(
                    Icons.Filled.AddCircle, contentDescription = "Schlag hinzufügen", tint = AppTheme.gold,
                    modifier = Modifier.size(56.dp).clickable { addStroke() },
                )
            }
        }

        // Putts, Fairway, GIR
        Row(
            Modifier.fillMaxWidth().height(IntrinsicSize.Min).background(AppTheme.card, RoundedCornerShape(20.dp))
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Putts", color = AppTheme.textSec, fontSize = 12.sp)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Icon(
                        Icons.Filled.RemoveCircleOutline, null, tint = if (score.putts > 0) AppTheme.gold else AppTheme.textSec,
                        modifier = Modifier.size(28.dp).clickable(enabled = score.putts > 0) {
                            Haptics.light(); updateHole(roundId, hole) { it.copy(putts = maxOf(0, it.putts - 1)) }
                        },
                    )
                    Text("${score.putts}", color = AppTheme.text, fontSize = 28.sp, fontWeight = FontWeight.Bold, modifier = Modifier.defaultMinSize(minWidth = 28.dp),
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                    Icon(
                        Icons.Filled.AddCircleOutline, null, tint = AppTheme.gold,
                        modifier = Modifier.size(28.dp).clickable { Haptics.stroke(); updateHole(roundId, hole) { it.copy(putts = it.putts + 1) } },
                    )
                }
            }
            VerticalDivider(Modifier.height(50.dp).padding(horizontal = 8.dp), color = AppTheme.cardAlt)
            if (par > 3) {
                ToggleCell("Fairway", score.fairwayHit) { hit ->
                    if (hit) Haptics.success() else Haptics.selection()
                    updateHole(roundId, hole) { it.copy(fairwayHit = hit) }
                }
                VerticalDivider(Modifier.height(50.dp).padding(horizontal = 8.dp), color = AppTheme.cardAlt)
            }
            ToggleCell("GIR", score.greenInRegulation) { hit ->
                if (hit) Haptics.success() else Haptics.selection()
                updateHole(roundId, hole) { it.copy(greenInRegulation = hit) }
            }
        }

        if (round.gameMode.isMultiplayer && opponents.isNotEmpty()) {
            Column {
                HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(horizontal = 16.dp))
                Box(Modifier.padding(top = 12.dp)) {
                    val partner = opponents.firstOrNull()?.playerName?.takeIf { it.isNotEmpty() } ?: "Partner"
                    when (round.gameMode) {
                        GameMode.SCRAMBLE_2_MANN -> SharedNote(Icons.Filled.Group, "2-Mann Scramble mit $partner", "Tragt den gemeinsamen Team-Score oben ein.")
                        GameMode.SCRAMBLE_TEAM -> SharedNote(
                            Icons.Filled.Groups,
                            "Team Scramble - " + opponents.joinToString(", ") { it.playerName.ifEmpty { "Spieler ${it.playerIndex + 1}" } },
                            "Alle schlagen ab. Tragt den gemeinsamen Team-Score oben ein.",
                        )
                        GameMode.VIERER -> SharedNote(Icons.Filled.Autorenew, "Vierer mit $partner", "Ihr spielt abwechselnd mit einem Ball. Tragt den gemeinsamen Score ein.")
                        GameMode.GREENSOME -> SharedNote(Icons.Filled.SupervisedUserCircle, "Greensome mit $partner", "Beide schlagen ab - bester Teeshot, dann Wechselschlag.")
                        else -> OpponentSection(round, score, par, opponents)
                    }
                }
            }
        }

        // Score gesamt → Rundenübersicht
        Row(
            Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))
                .clickable { Haptics.tap(); showRoundOverview = true }.padding(horizontal = 18.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("SCORE GESAMT", color = AppTheme.textTer, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.5.sp, modifier = Modifier.weight(1f))
            val stp = round.scoreToPar(course)
            val c = when { stp == null -> AppTheme.text; stp < 0 -> AppTheme.gold; stp == 0 -> AppTheme.text; stp <= 2 -> IosColors.orange; else -> IosColors.red }
            Text(round.scoreLabel(course), color = c, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Spacer(Modifier.width(4.dp))
            Text("/ Loch $hole", color = AppTheme.textSec, fontSize = 15.sp)
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer)
        }

        // Abschlag setzen bzw. Schläge aufzeichnen
        val needsTee = course != null && course.teeCoordinate(hole) == null && score.shots.isEmpty()
        if (needsTee) {
            GoldAction(Icons.Filled.SportsGolf, "Abschlag setzen") {
                Haptics.tap()
                if (teeHintShown) setTee() else showTeeHint = true
            }
        } else {
            val n = score.shots.size
            GoldAction(
                Icons.Filled.Place,
                if (n == 0) "Schlag aufzeichnen" else "$n ${if (n == 1) "Schlag" else "Schläge"} erfasst",
                suffix = if (n > 0) "· ${unit.format(score.totalDistanceMeters)} gesamt" else null,
            ) { Haptics.tap(); showShotTracker = true }
        }

        // Hinweise der Anlage
        if (hints.isNotEmpty()) {
            val hint = hints[((hole % hints.size) + hints.size) % hints.size]
            Row(
                Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(hint.kind.icon, null, tint = AppTheme.gold, modifier = Modifier.width(28.dp).size(22.dp))
                Spacer(Modifier.width(12.dp))
                Column {
                    Text("Gut zu wissen", color = AppTheme.gold.copy(alpha = 0.8f), fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                    Text(hint.text, color = AppTheme.textSec, fontSize = 15.sp)
                }
            }
        }

        // Werbung wie auf iOS (ohne Werbefrei-Kauf in dieser Version).
        AdSlot(
            placement = AdPlacement.GOLF_SCORING,
            courseId = catalogEntry?.slug?.takeIf { it.isNotEmpty() } ?: course?.slug?.takeIf { it.isNotEmpty() },
            rotation = hole,
            nav = nav,
            coordinate = course?.let { c -> if (c.latitude != null && c.longitude != null) LatLon(c.latitude, c.longitude) else null },
        )
    }

    // --- Sheets & Dialoge ---
    if (showShotTracker) ShotTrackerSheet(round, hole, here) { showShotTracker = false }
    if (showPinSetter) {
        PinSetterSheet(initial = pin, here = here, onSave = { p ->
            updateHole(roundId, hole) { it.copy(pinLatitude = p.lat, pinLongitude = p.lon, pinIsAutomatic = false) }
        }) { showPinSetter = false }
    }
    if (showHoleOverview) HoleTrackingOverviewSheet(round, course, score, par, here) { showHoleOverview = false }
    if (showRoundOverview) RoundTrackingOverviewSheet(round, course, hole, here) { showRoundOverview = false }
    if (showClubPicker) {
        val recommended = if (pin != null && pendingLocation != null) recommendedClub(pin.distanceTo(pendingLocation!!)) else null
        ClubPickerSheet(
            clubs = clubs, recommended = recommended, strokeNumber = pendingShotNumber, gps = pendingLocation, unit = unit,
            onPick = { club ->
                val num = pendingShotNumber
                val gps = pendingLocation
                updateHole(roundId, hole) { hs ->
                    val putts = if (club.isPutter) hs.putts + 1 else hs.putts
                    // Mit GPS legt der Plus-Knopf den Schlag schon an – dann nur den Schläger nachtragen.
                    val shots = if (hs.shots.any { it.shotNumber == num }) hs.shots.map { if (it.shotNumber == num) it.copy(club = club.name) else it }
                    else hs.shots + Shot(num, gps?.lat ?: 0.0, gps?.lon ?: 0.0, gps?.lat ?: 0.0, gps?.lon ?: 0.0, club.name)
                    hs.copy(putts = putts, shots = shots)
                }
                showClubPicker = false
            },
            onDismiss = { showClubPicker = false },
        )
    }
    if (showTeeHint) {
        AlertDialog(
            onDismissRequest = { showTeeHint = false },
            title = { Text("So funktioniert's") },
            text = {
                Text(
                    "Stell dich auf den Abschlag und tippe auf „Abschlag setzen“. Deine Position wird als Abschlag dieses Lochs gespeichert.\n\nDanach zählst du wie gewohnt mit Plus: Jeder Tipp nimmt deinen aktuellen Standort als Lage des nächsten Schlags. Beim nächsten Mal kennt die App den Abschlag schon." +
                        if (trackingEnabled) "\n\nDas Positions-Tracking zeichnet dazwischen weiter deine Laufspur auf."
                        else "\n\nMit eingeschaltetem Positions-Tracking lernt die App Abschläge und Grüns zusätzlich aus deiner Laufspur.",
                )
            },
            confirmButton = { TextButton(onClick = { showTeeHint = false; teeHintShown = true; setTee() }) { Text("Abschlag setzen", color = AppTheme.gold, fontWeight = FontWeight.Bold) } },
            dismissButton = { TextButton(onClick = { showTeeHint = false }) { Text("Abbrechen", color = AppTheme.textSec) } },
            containerColor = AppTheme.card,
        )
    }
    if (showNoGps) {
        AlertDialog(
            onDismissRequest = { showNoGps = false },
            title = { Text("Kein GPS-Signal") },
            text = { Text("Warte kurz, bis dein Standort gefunden ist, und versuch es dann noch einmal.") },
            confirmButton = { TextButton(onClick = { showNoGps = false }) { Text("OK", color = AppTheme.gold) } },
            containerColor = AppTheme.card,
        )
    }
}

/** Standard-Schläger anlegen, wenn noch keine existieren (wie `seedDefaultClubs`). */
private fun seedDefaultClubs(round: Round) {
    val defaults = listOf(
        Triple("Driver", 220, false), Triple("3 Wood", 195, false), Triple("5 Wood", 180, false),
        Triple("3 Eisen", 185, false), Triple("4 Eisen", 175, false), Triple("5 Eisen", 165, false),
        Triple("6 Eisen", 155, false), Triple("7 Eisen", 145, false), Triple("8 Eisen", 130, false),
        Triple("9 Eisen", 120, false), Triple("PW", 110, false), Triple("GW", 95, false),
        Triple("SW", 80, false), Triple("LW", 60, false), Triple("Putter", 10, true),
    )
    val clubs = defaults.mapIndexed { i, (n, d, p) -> GolfClub(name = n, defaultDistance = d, order = i, isPutter = p) }
    val existing = GolfStore.current.bag(round.bagId)
    val bag = existing?.copy(clubs = existing.clubs + clubs) ?: GolfBag(name = "Standard", clubs = clubs)
    GolfStore.upsertBag(bag)
    if (existing == null) GolfStore.updateRound(round.id) { it.copy(bagId = bag.id) }
}

@Composable
private fun CourseHeader(course: Course?) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp).padding(bottom = 2.dp), verticalAlignment = Alignment.Top) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(course?.name ?: "Runde", color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
            if (course != null) Text("${course.numberOfHoles} Löcher · Par ${course.totalPar}", color = AppTheme.textSec, fontSize = 15.sp)
        }
        Row(Modifier.padding(top = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(7.dp).background(IosColors.live, CircleShape))
            Spacer(Modifier.width(5.dp))
            Text("LIVE", color = IosColors.live, fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.2.sp)
        }
    }
}

private fun scoreName(strokes: Int, diff: Int): String {
    if (strokes == 1) return "Hole in One!"
    return when {
        diff < -2 -> "Albatross"
        diff == -2 -> "Eagle"
        diff == -1 -> "Birdie"
        diff == 0 -> "Par"
        diff == 1 -> "Bogey"
        diff == 2 -> "Double"
        diff == 3 -> "Triple"
        else -> "+$diff"
    }
}

@Composable
private fun HoleCard(score: HoleScore, par: Int, holeCount: Int, course: Course?, mode: GameMode, onPrevious: () -> Unit, onNext: () -> Unit) {
    val hole = score.holeNumber
    val diff = score.strokes - par
    Row(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(20.dp)).padding(horizontal = 10.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            Modifier.width(36.dp).height(56.dp).clickable(enabled = hole > 1) { onPrevious() },
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Vorheriges Loch", tint = if (hole > 1) AppTheme.gold else AppTheme.textTer) }

        Column(Modifier.padding(start = 2.dp).weight(1f)) {
            Text("AKTUELLES LOCH", color = AppTheme.textTer, fontSize = 9.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.sp,
                modifier = Modifier.padding(bottom = 2.dp))
            AnimatedContent(hole, transitionSpec = { fadeIn(tween(180)) togetherWith fadeOut(tween(180)) }, label = "hole") { h ->
                Text(String.format("%02d", h), color = AppTheme.gold, fontSize = 64.sp, fontWeight = FontWeight.Black,
                    fontStyle = FontStyle.Italic, lineHeight = 66.sp)
            }
            Row(Modifier.padding(top = 4.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                course?.hcpValues?.getOrNull(hole - 1)?.let { SmallBadge(Icons.Filled.SwapVert, "HCP $it") }
                course?.holeLengths?.getOrNull(hole - 1)?.let { SmallBadge(Icons.Filled.Straighten, "$it m") }
            }
        }

        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.padding(end = 2.dp)) {
            Text("PAR $par", color = AppTheme.textSec, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.sp)
            if (score.strokes > 0) {
                val c = when { diff < 0 -> AppTheme.gold; diff == 0 -> AppTheme.text; diff == 1 -> IosColors.orange; else -> IosColors.red }
                Text(scoreName(score.strokes, diff), color = c, fontSize = 15.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.background(c.copy(alpha = 0.15f), RoundedCornerShape(50)).padding(horizontal = 12.dp, vertical = 5.dp))
                if (mode == GameMode.STABLEFORD) {
                    val pts = GameMode.stablefordPoints(score.strokes, par)
                    Text("$pts Pkt", color = if (pts >= 3) AppTheme.gold else if (pts == 0) AppTheme.textTer else AppTheme.text,
                        fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            }
        }

        Box(
            Modifier.width(36.dp).height(56.dp).clickable(enabled = hole < holeCount) { onNext() },
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, "Nächstes Loch", tint = if (hole < holeCount) AppTheme.gold else AppTheme.textTer) }
    }
}

@Composable
private fun SmallBadge(icon: ImageVector, text: String) {
    Row(
        Modifier.background(AppTheme.cardAlt, RoundedCornerShape(50)).padding(horizontal = 7.dp, vertical = 3.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = AppTheme.textSec, modifier = Modifier.size(10.dp))
        Spacer(Modifier.width(3.dp))
        Text(text, color = AppTheme.textSec, fontSize = 10.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun androidx.compose.foundation.layout.RowScope.ToggleCell(label: String, value: Boolean, onChange: (Boolean) -> Unit) {
    Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(label, color = AppTheme.textSec, fontSize = 12.sp)
        Switch(
            checked = value, onCheckedChange = onChange,
            colors = SwitchDefaults.colors(
                checkedTrackColor = AppTheme.gold, checkedThumbColor = Color.White,
                uncheckedTrackColor = AppTheme.cardAlt, uncheckedThumbColor = Color.White, uncheckedBorderColor = Color.Transparent,
            ),
        )
    }
}

@Composable
private fun GoldAction(icon: ImageVector, text: String, suffix: String? = null, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.gold, RoundedCornerShape(14.dp)).clickable { onClick() }.padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = IosColors.onGoldDark, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(8.dp))
        Text(text, color = IosColors.onGoldDark, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        if (suffix != null) {
            Spacer(Modifier.width(6.dp))
            Text(suffix, color = IosColors.onGoldDark.copy(alpha = 0.6f), fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun SharedNote(icon: ImageVector, title: String, subtitle: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(24.dp))
        Spacer(Modifier.width(10.dp))
        Column {
            Text(title, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            Text(subtitle, color = AppTheme.textSec, fontSize = 12.sp)
        }
    }
}

@Composable
private fun CenterBadge(text: String, color: Color) {
    Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp), contentAlignment = Alignment.Center) {
        Text(text, color = color, fontSize = 12.sp, fontWeight = FontWeight.Bold,
            modifier = Modifier.background(color.copy(alpha = 0.12f), RoundedCornerShape(50)).padding(horizontal = 12.dp, vertical = 5.dp))
    }
}

@Composable
private fun OpponentSection(round: Round, score: HoleScore, par: Int, opponents: List<PlayerHoleScore>) {
    val mode = round.gameMode
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            when (mode) {
                GameMode.MATCHPLAY -> "Gegner"
                GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD -> "Partner"
                GameMode.BETTER_BALL_MATCHPLAY -> "Partner & Gegner"
                else -> "Mitspieler"
            },
            color = AppTheme.textSec, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 16.dp),
        )
        opponents.forEach { opp ->
            val role = if (mode == GameMode.BETTER_BALL_MATCHPLAY) (if (opp.playerIndex == 1) "Partner" else "Gegner ${opp.playerIndex - 1}") else null
            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                Column(Modifier.weight(1f)) {
                    Text(opp.playerName.ifEmpty { "Spieler ${opp.playerIndex + 1}" }, color = AppTheme.text, fontSize = 15.sp)
                    if (role != null) Text(role, color = AppTheme.textSec, fontSize = 11.sp)
                }
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Icon(
                        Icons.Filled.RemoveCircle, null, tint = if (opp.strokes > 1) AppTheme.text else AppTheme.textSec,
                        modifier = Modifier.size(28.dp).clickable(enabled = opp.strokes > 1) {
                            Haptics.light(); updateOpponent(round.id, opp.playerIndex, opp.holeNumber, opp.strokes - 1)
                        },
                    )
                    Text("${opp.strokes}", color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold,
                        modifier = Modifier.defaultMinSize(minWidth = 28.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
                    Icon(
                        Icons.Filled.AddCircle, null, tint = AppTheme.text,
                        modifier = Modifier.size(28.dp).clickable {
                            Haptics.stroke(); updateOpponent(round.id, opp.playerIndex, opp.holeNumber, opp.strokes + 1)
                        },
                    )
                }
            }
        }
        when (mode) {
            GameMode.MATCHPLAY -> opponents.firstOrNull()?.let { opp ->
                val (l, c) = outcomeLabel(GameScoringEngine.matchplayHoleOutcome(score.strokes, opp.strokes), "Loch gewonnen", "Loch verloren")
                CenterBadge(l, c)
            }
            GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD -> opponents.firstOrNull()?.let { partner ->
                val sf = mode == GameMode.BETTER_BALL_STABLEFORD
                val v = GameScoringEngine.betterBallHoleValue(score, partner, par, sf)
                if (score.strokes > 0 || partner.strokes > 0) {
                    if (sf) CenterBadgePlain("Team: $v Punkte", if (v >= 3) AppTheme.gold else if (v == 0) AppTheme.textSec else AppTheme.text)
                    else {
                        val d = v - par
                        CenterBadgePlain("Team: $v Schläge (${if (d == 0) "Par" else if (d > 0) "+$d" else "$d"})",
                            if (d < 0) AppTheme.gold else if (d > 0) IosColors.orange else AppTheme.text)
                    }
                }
            }
            GameMode.BETTER_BALL_MATCHPLAY -> {
                val partner = opponents.firstOrNull { it.playerIndex == 1 }?.strokes ?: 0
                val o1 = opponents.firstOrNull { it.playerIndex == 2 }?.strokes ?: 0
                val o2 = opponents.firstOrNull { it.playerIndex == 3 }?.strokes ?: 0
                val myBest = if (partner > 0) minOf(score.strokes, partner) else score.strokes
                val oppBest = if (o1 <= 0) 0 else if (o2 > 0) minOf(o1, o2) else o1
                if (oppBest > 0) {
                    val (l, c) = outcomeLabel(GameScoringEngine.matchplayHoleOutcome(myBest, oppBest), "Team gewinnt Loch", "Team verliert Loch")
                    CenterBadge(l, c)
                }
            }
            GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD -> {
                val sf = mode == GameMode.BEST_BALL_STABLEFORD
                val v = GameScoringEngine.bestBallHoleValue(round, score, par, sf)
                if (score.strokes > 0 || opponents.any { it.strokes > 0 }) {
                    if (sf) CenterBadgePlain("Best Ball: $v Punkte", if (v >= 3) AppTheme.gold else if (v == 0) AppTheme.textSec else AppTheme.text)
                    else {
                        val d = v - par
                        CenterBadgePlain("Best Ball: $v (${if (d == 0) "Par" else if (d > 0) "+$d" else "$d"})",
                            if (d < 0) AppTheme.gold else if (d > 0) IosColors.orange else AppTheme.text)
                    }
                }
            }
            else -> {}
        }
    }
}

private fun outcomeLabel(o: HoleOutcome, win: String, loss: String): Pair<String, Color> = when (o) {
    HoleOutcome.PLAYER -> win to AppTheme.gold
    HoleOutcome.OPPONENT -> loss to IosColors.red
    HoleOutcome.HALVED -> "Unentschieden" to AppTheme.textSec
    HoleOutcome.NOT_PLAYED -> "Noch kein Ergebnis" to AppTheme.textSec
}

@Composable
private fun CenterBadgePlain(text: String, color: Color) {
    Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp), contentAlignment = Alignment.Center) {
        Text(text, color = color, fontSize = 12.sp, fontWeight = FontWeight.Bold)
    }
}

/** Wie ClubPickerSheet in HoleScoringView.swift – nach jedem Schlag den Schläger wählen. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ClubPickerSheet(
    clubs: List<GolfClub>,
    recommended: GolfClub?,
    strokeNumber: Int,
    gps: LatLon?,
    unit: app.golftrack.data.DistanceUnit,
    onPick: (GolfClub) -> Unit,
    onDismiss: () -> Unit,
) {
    val sheet = rememberModalBottomSheetState(skipPartiallyExpanded = false)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheet, containerColor = AppTheme.bg) {
        Column(Modifier.fillMaxWidth()) {
            Text("Überspringen", color = AppTheme.textSec, fontSize = 16.sp,
                modifier = Modifier.padding(start = 8.dp).clickable { Haptics.tap(); onDismiss() }.padding(8.dp))
            Text("Schlag $strokeNumber – Schläger?", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(bottom = 4.dp))
            Column(
                Modifier.verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).padding(top = 8.dp, bottom = 24.dp).navigationBarsPadding(),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                if (gps == null) {
                    Row(Modifier.padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.LocationOff, null, tint = AppTheme.textSec, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Kein GPS-Signal – Position nicht gespeichert", color = AppTheme.textSec, fontSize = 12.sp)
                    }
                }
                if (recommended != null) {
                    ClubButton(recommended, true, unit) { Haptics.tap(); onPick(recommended) }
                    if (clubs.size > 1) {
                        Text("Weitere Schläger", color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 4.dp).padding(top = 8.dp))
                    }
                }
                clubs.filter { it.id != recommended?.id }.forEach { c -> ClubButton(c, false, unit) { Haptics.tap(); onPick(c) } }
            }
        }
    }
}

@Composable
private fun ClubButton(club: GolfClub, isRecommended: Boolean, unit: app.golftrack.data.DistanceUnit, onClick: () -> Unit) {
    val accent = if (club.isPutter) IosColors.blue else AppTheme.gold
    var m = Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))
    if (isRecommended) m = m.border(1.5.dp, AppTheme.gold.copy(alpha = 0.6f), RoundedCornerShape(14.dp))
    Row(m.clickable { onClick() }.padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(40.dp).background(accent.copy(alpha = 0.15f), CircleShape), contentAlignment = Alignment.Center) {
            Icon(if (club.isPutter) Icons.Filled.Flag else Icons.Filled.SportsGolf, null, tint = accent, modifier = Modifier.size(18.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(club.name, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                if (club.isPutter) Tag("PUTTER", IosColors.blue)
                if (isRecommended) Tag("EMPFOHLEN", AppTheme.gold)
            }
            Text(
                if (club.isPutter) "Putts +1 automatisch" else "Ø ${unit.format(club.averageDistance.toDouble())}",
                color = if (club.isPutter) IosColors.blue.copy(alpha = 0.7f) else AppTheme.textSec, fontSize = 12.sp,
            )
        }
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer)
    }
}

@Composable
private fun Tag(text: String, color: Color) {
    Text(text, color = color, fontSize = 9.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp,
        modifier = Modifier.background(color.copy(alpha = 0.15f), RoundedCornerShape(50)).padding(horizontal = 5.dp, vertical = 2.dp))
}
