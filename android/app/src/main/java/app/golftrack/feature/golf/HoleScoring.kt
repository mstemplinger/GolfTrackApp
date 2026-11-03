package app.golftrack.feature.golf

import app.golftrack.feature.ads.AdPlacement
import app.golftrack.feature.ads.AdSlot

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Autorenew
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.LocationOff
import androidx.compose.material.icons.filled.NearMe
import androidx.compose.material.icons.filled.PinDrop
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.SupervisedUserCircle
import androidx.compose.material.icons.filled.SwapVert
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.DistanceUnit
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
import app.golftrack.data.ScoreEntry
import app.golftrack.data.Shot
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.data.rememberPrefBool
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlin.math.abs

/**
 * Wie HoleScoringView.swift – ein Loch zählen: große Lochnummer, Distanz LIVE,
 * Schlägerempfehlung, großer Schlagzähler, eigene Karten für Mitspieler, Lochleiste.
 */
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
    /** Sprung auf ein bestimmtes Loch (1-basiert) über die Lochleiste. */
    onSelectHole: (Int) -> Unit = {},
) {
    val data by GolfStore.data.collectAsState()
    val catalog by CourseCatalog.golfCourses.collectAsState()
    val unit = rememberDistanceUnit()
    val hole = score.holeNumber
    val roundId = round.id
    val mode = round.gameMode

    val clubs: List<GolfClub> = data.bag(round.bagId)?.sortedClubs
        ?: data.bags.flatMap { it.clubs }.sortedBy { it.order }

    var showShotTracker by remember { mutableStateOf(false) }
    var shotTrackerPlayer by remember { mutableStateOf<PlayerHoleScore?>(null) }
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
    // Spielformen mit gemeinsamem Ball – dort gibt es nur einen Team-Score.
    val playsOwnBall = mode !in setOf(
        GameMode.SCRAMBLE_2_MANN, GameMode.SCRAMBLE_TEAM, GameMode.VIERER, GameMode.GREENSOME, GameMode.SCRAMBLE_MATCHPLAY,
    )
    // Jeder Mitspieler bekommt eine eigene Scorekarte, sobald er seinen eigenen Ball spielt.
    val showsPartnerCards = mode.isMultiplayer && playsOwnBall && opponents.isNotEmpty()

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
    // Mehr als 2 km zur Fahne: niemand steht auf diesem Loch.
    val isAwayFromCourse = (distanceToPin ?: 0.0) > 2000

    fun recommendedClub(meters: Double): GolfClub? =
        clubs.minByOrNull { abs(it.averageDistance - meters.toInt()) }

    fun isPutterName(name: String): Boolean = clubs.firstOrNull { it.name == name }?.isPutter ?: (name == "Putter")

    /**
     * Zählt einen Schlag und hängt den aktuellen Standort als Lage an die
     * GPS-Kette des Spielers: Der vorige Schlag endet hier, der neue beginnt hier.
     */
    fun EntryFields.addingStroke(): EntryFields {
        val shotNum = strokes + 1
        var shots = shots
        if (here != null) {
            val prev = sortedShots.lastOrNull()
            if (prev != null) shots = shots.map { if (it.shotNumber == prev.shotNumber) it.copy(toLatitude = here.lat, toLongitude = here.lon) else it }
            // Lage sofort speichern – auch wenn die Schlägerwahl übersprungen wird.
            if (shots.none { it.shotNumber == shotNum }) shots = shots + Shot(shotNum, here.lat, here.lon, here.lat, here.lon)
        }
        return copy(strokes = strokes + 1, shots = shots)
    }

    fun addStroke(player: Int, entry: ScoreEntry): Int {
        Haptics.stroke()
        updateEntry(roundId, player, hole) { it.addingStroke() }
        return entry.strokes + 1
    }

    fun removeStroke(player: Int, entry: ScoreEntry) {
        if (entry.strokes <= 0) return
        Haptics.light()
        val removing = entry.strokes
        updateEntry(roundId, player, hole) { e ->
            val shot = e.shots.firstOrNull { it.shotNumber == removing }
            val putts = if (shot != null && clubs.firstOrNull { it.name == shot.club }?.isPutter == true && e.putts > 0) e.putts - 1 else e.putts
            e.copy(strokes = maxOf(0, e.strokes - 1), putts = putts, shots = e.shots.filter { it.shotNumber != removing })
        }
    }

    /** Ein Putt ist auch ein Schlag: zählt ihn mit und trägt den Putter ein, ohne Schlägerauswahl. */
    fun addPutt(player: Int, entry: ScoreEntry) {
        Haptics.stroke()
        val shotNum = entry.strokes + 1
        val putter = clubs.firstOrNull { it.isPutter }?.name ?: "Putter"
        updateEntry(roundId, player, hole) { e ->
            val f = e.addingStroke()
            val shots = if (f.shots.any { it.shotNumber == shotNum }) f.shots.map { if (it.shotNumber == shotNum) it.copy(club = putter) else it }
            // Ohne GPS trotzdem ein Schlag ohne Lage, damit der Schläger festgehalten ist.
            else f.shots + Shot(shotNum, 0.0, 0.0, 0.0, 0.0, putter)
            f.copy(putts = f.putts + 1, shots = shots)
        }
    }

    /** War der letzte Schlag ein Putt, nimmt Minus ihn ganz zurück; sonst nur den Putt. */
    fun removePutt(player: Int, entry: ScoreEntry) {
        if (entry.putts <= 0) return
        val lastIsPutt = entry.shots.firstOrNull { it.shotNumber == entry.strokes }?.let { isPutterName(it.club) } ?: false
        if (lastIsPutt && entry.strokes > 0) removeStroke(player, entry)
        else {
            Haptics.light()
            updateEntry(roundId, player, hole) { it.copy(putts = maxOf(0, it.putts - 1)) }
        }
    }

    fun openClubPickerIfWanted() {
        if (clubs.isNotEmpty() && !round.hidesClubPicker) showClubPicker = true
    }

    /**
     * Nimmt den aktuellen Standort als Abschlag: für den Platz (je Farbe) und als
     * Startpunkt von Schlag 1. Jeder weitere Tipp auf Plus hängt den nächsten GPS-Punkt an.
     */
    fun setTee() {
        val loc = here
        if (loc == null) { Haptics.warning(); showNoGps = true; return }
        Haptics.stroke()
        course?.let { GolfStore.upsertCourse(it.withTee(hole, loc, round.teeColor)) }
        updateHole(roundId, hole) { hs ->
            val shots = if (hs.shots.any { it.shotNumber == 1 }) hs.shots else hs.shots + Shot(1, loc.lat, loc.lon, loc.lat, loc.lon)
            hs.copy(strokes = if (hs.strokes == 0) 1 else hs.strokes, shots = shots)
        }
        pendingLocation = loc
        pendingShotNumber = 1
        openClubPickerIfWanted()
    }

    fun displayName(opp: PlayerHoleScore) = opp.playerName.ifEmpty { "Spieler ${opp.playerIndex + 1}" }
    fun roleLabel(opp: PlayerHoleScore): String? =
        if (mode != GameMode.BETTER_BALL_MATCHPLAY) null else if (opp.playerIndex == 1) "Partner" else "Gegner ${opp.playerIndex - 1}"

    Column(
        Modifier.padding(horizontal = 16.dp).padding(top = 8.dp, bottom = 8.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        HoleHeader(round, course, score, par, holeCount, mode, unit, onPrevious, onNext)

        PinDistanceCard(
            hasPin = pin != null, distance = distanceToPin, away = isAwayFromCourse, unit = unit,
            onOverview = { Haptics.tap(); showHoleOverview = true },
            onPin = { Haptics.tap(); showPinSetter = true },
        )

        // Empfehlung plus die beiden Nachbarn in der Distanz – kürzer und länger.
        if (!isAwayFromCourse && distanceToPin != null) {
            recommendedClub(distanceToPin)?.let { club ->
                val candidates = clubs.filter { !it.isPutter }.sortedBy { it.averageDistance }
                val i = candidates.indexOfFirst { it.id == club.id }
                val neighbours = if (i < 0) emptyList() else listOfNotNull(candidates.getOrNull(i - 1), candidates.getOrNull(i + 1))
                ClubRecommendationCard(club, neighbours, unit)
            }
        }

        if (showsPartnerCards) PlayerNameLabel("Du")

        StrokeCounterCard(
            strokes = score.strokes,
            lastClub = lastClubName(score),
            showsRestore = round.hidesClubPicker && clubs.isNotEmpty(),
            onMinus = { removeStroke(0, score) },
            onPlus = {
                val n = addStroke(0, score)
                pendingLocation = here
                pendingShotNumber = n
                openClubPickerIfWanted()
            },
            onRestore = { Haptics.selection(); GolfStore.updateRound(roundId) { it.copy(hidesClubPicker = false) } },
        )
        SecondaryStats(score, par, roundId, 0, onAddPutt = { addPutt(0, score) }, onRemovePutt = { removePutt(0, score) })

        if (showsPartnerCards) {
            opponents.forEach { opp ->
                PartnerCard(
                    opp, displayName(opp), roleLabel(opp), par, unit,
                    onMinus = { removeStroke(opp.playerIndex, opp) },
                    onPlus = { addStroke(opp.playerIndex, opp) },
                    onAddPutt = { addPutt(opp.playerIndex, opp) },
                    onRemovePutt = { removePutt(opp.playerIndex, opp) },
                    onShots = { Haptics.tap(); shotTrackerPlayer = opp },
                    roundId = roundId,
                )
            }
        }

        if (mode.isMultiplayer && opponents.isNotEmpty()) {
            Column {
                HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(horizontal = 16.dp))
                Box(Modifier.padding(top = 12.dp)) {
                    val partner = opponents.firstOrNull()?.playerName?.takeIf { it.isNotEmpty() } ?: "Partner"
                    when (mode) {
                        GameMode.SCRAMBLE_2_MANN -> SharedNote(Icons.Filled.Group, "2-Mann Scramble mit $partner", "Tragt den gemeinsamen Team-Score oben ein.")
                        GameMode.SCRAMBLE_TEAM -> SharedNote(
                            Icons.Filled.Groups,
                            "Team Scramble - " + opponents.joinToString(", ") { it.playerName.ifEmpty { "Spieler ${it.playerIndex + 1}" } },
                            "Alle schlagen ab. Tragt den gemeinsamen Team-Score oben ein.",
                        )
                        GameMode.VIERER -> SharedNote(Icons.Filled.Autorenew, "Vierer mit $partner", "Ihr spielt abwechselnd mit einem Ball. Tragt den gemeinsamen Score ein.")
                        GameMode.GREENSOME -> SharedNote(Icons.Filled.SupervisedUserCircle, "Greensome mit $partner", "Beide schlagen ab - bester Teeshot, dann Wechselschlag.")
                        else -> OpponentSection(round, score, par, opponents, showsPartnerCards, ::roleLabel)
                    }
                }
            }
        }

        HoleStrip(round, hole, onSelectHole)

        // Score gesamt → Rundenübersicht
        Row(
            Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))
                .clickable { Haptics.tap(); showRoundOverview = true }.padding(horizontal = 18.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("SCORE GESAMT", color = AppTheme.textTer, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.5.sp, modifier = Modifier.weight(1f))
            Text("${round.totalStrokes}", color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.SansSerif)
            Spacer(Modifier.width(8.dp))
            val stp = round.scoreToPar(course)
            val c = when { stp == null -> AppTheme.text; stp < 0 -> AppTheme.gold; stp == 0 -> AppTheme.text; stp <= 2 -> IosColors.orange; else -> IosColors.red }
            Text(round.scoreLabel(course), color = c, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            Spacer(Modifier.width(4.dp))
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))
        }

        // Abschlag setzen bzw. Schläge aufzeichnen – für diese Farbe noch kein
        // Abschlag bekannt und in dieser Runde noch nichts erfasst.
        val needsTee = course != null && !course.hasOwnTeeCoordinate(hole, round.teeColor) && score.shots.isEmpty()
        if (needsTee) {
            GoldAction(Icons.Filled.SportsGolf, "Abschlag setzen") {
                Haptics.tap()
                if (teeHintShown) setTee() else showTeeHint = true
            }
        } else {
            val n = score.shots.size
            GoldAction(
                Icons.Filled.PinDrop,
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
    shotTrackerPlayer?.let { opp ->
        ShotTrackerSheet(round, hole, here, playerIndex = opp.playerIndex, playerName = displayName(opp)) { shotTrackerPlayer = null }
    }
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
            onHideForRound = {
                GolfStore.updateRound(roundId) { it.copy(hidesClubPicker = true) }
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

/** Schläger des zuletzt gespielten Schlags mit eingetragenem Schläger. */
private fun lastClubName(entry: ScoreEntry): String? = entry.sortedShots.lastOrNull { it.club.isNotEmpty() }?.club

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

// MARK: - Lochkopf

@Composable
private fun HoleHeader(
    round: Round, course: Course?, score: HoleScore, par: Int, holeCount: Int, mode: GameMode, unit: DistanceUnit,
    onPrevious: () -> Unit, onNext: () -> Unit,
) {
    val hole = score.holeNumber
    val diff = score.strokes - par
    val tee = round.teeColor
    Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp), verticalAlignment = Alignment.Top) {
        Column(Modifier.weight(1f)) {
            Text(course?.name ?: "Runde", color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
                maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text("AKTUELLES LOCH", color = AppTheme.textTer, fontSize = 9.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.sp,
                modifier = Modifier.padding(top = 6.dp))
            AnimatedContent(hole, transitionSpec = { fadeIn(tween(180)) togetherWith fadeOut(tween(180)) }, label = "hole") { h ->
                Text(String.format("%02d", h), color = AppTheme.gold, fontSize = 72.sp, fontWeight = FontWeight.Black,
                    fontStyle = FontStyle.Italic, lineHeight = 74.sp, modifier = Modifier.offset(y = (-4).dp))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                course?.hcpValues?.getOrNull(hole - 1)?.let { HeaderPill { PillIcon(Icons.Filled.SwapVert); PillText("HCP $it") } }
                val len = course?.holeLength(hole, tee)
                if (len != null) {
                    HeaderPill {
                        if (tee != null) TeeDot(tee, 8) else PillIcon(Icons.Filled.Straighten)
                        PillText(unit.format(len.toDouble()))
                    }
                } else if (tee != null) {
                    HeaderPill { TeeDot(tee, 8); PillText(tee.displayName) }
                }
            }
        }
        Column(horizontalAlignment = Alignment.End) {
            Row(Modifier.padding(top = 2.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                NavCircle(Icons.AutoMirrored.Filled.KeyboardArrowLeft, "Vorheriges Loch", hole > 1, onPrevious)
                NavCircle(Icons.AutoMirrored.Filled.KeyboardArrowRight, "Nächstes Loch", hole < holeCount, onNext)
            }
            Text("PAR $par", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.sp,
                modifier = Modifier.padding(top = 18.dp))
            // Badge und Punkte erst, wenn ein Schlag eingetragen ist.
            if (score.strokes > 0) {
                val c = when { diff < 0 -> AppTheme.gold; diff == 0 -> AppTheme.text; diff == 1 -> IosColors.orange; else -> IosColors.red }
                Text(scoreName(score.strokes, diff), color = c, fontSize = 15.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 10.dp).background(c.copy(alpha = 0.15f), RoundedCornerShape(50)).padding(horizontal = 12.dp, vertical = 5.dp))
                if (mode == GameMode.STABLEFORD) {
                    val pts = GameMode.stablefordPoints(score.strokes, par)
                    Text("$pts Pkt", color = if (pts >= 3) AppTheme.gold else if (pts == 0) AppTheme.textTer else AppTheme.text,
                        fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(top = 10.dp))
                }
            }
        }
    }
}

@Composable
private fun HeaderPill(content: @Composable RowScope.() -> Unit) {
    Row(
        Modifier.background(AppTheme.cardAlt, RoundedCornerShape(50)).padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp),
    ) { content() }
}

@Composable
private fun PillIcon(icon: ImageVector) = Icon(icon, null, tint = AppTheme.textSec, modifier = Modifier.size(11.dp))

@Composable
private fun PillText(text: String) = Text(text, color = AppTheme.textSec, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)

@Composable
private fun NavCircle(icon: ImageVector, description: String, enabled: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.size(34.dp).background(AppTheme.card, CircleShape).clickable(enabled = enabled) { onClick() },
        contentAlignment = Alignment.Center,
    ) { Icon(icon, description, tint = if (enabled) AppTheme.gold else AppTheme.textTer, modifier = Modifier.size(20.dp)) }
}

// MARK: - Distanz zur Fahne

@Composable
private fun PinDistanceCard(hasPin: Boolean, distance: Double?, away: Boolean, unit: DistanceUnit, onOverview: () -> Unit, onPin: () -> Unit) {
    if (hasPin) {
        Row(
            Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(18.dp)).padding(start = 16.dp, end = 10.dp, top = 10.dp, bottom = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Tippen öffnet die Loch-Übersicht mit allem, was das Tracking weiß.
            Row(Modifier.weight(1f).clickable { onOverview() }.padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.NearMe, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(10.dp))
                when {
                    away -> Text("Du bist nicht am Platz", color = AppTheme.textSec, fontSize = 15.sp)
                    distance != null -> Text("Noch ${unit.format(distance)} zum Loch", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                    else -> Text("Standort wird ermittelt …", color = AppTheme.textSec, fontSize = 15.sp)
                }
                Spacer(Modifier.weight(1f))
                if (distance != null && !away) {
                    Text("LIVE", color = IosColors.onGoldDark, fontSize = 10.sp, fontWeight = FontWeight.Black,
                        modifier = Modifier.background(AppTheme.gold, RoundedCornerShape(50)).padding(horizontal = 6.dp, vertical = 3.dp))
                }
            }
            Spacer(Modifier.width(10.dp))
            // Pin neu setzen – klein, weil er meist automatisch stimmt.
            Box(
                Modifier.size(34.dp).background(AppTheme.cardAlt, CircleShape).clickable { onPin() },
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Filled.PinDrop, "Pin aktualisieren", tint = AppTheme.textSec, modifier = Modifier.size(16.dp)) }
        }
    } else {
        Row(
            Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(18.dp))
                .clickable { onPin() }.padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Icons.Filled.PinDrop, null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(10.dp))
            Text("Lochposition festlegen", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))
        }
    }
}

@Composable
private fun ClubRecommendationCard(club: GolfClub, neighbours: List<GolfClub>, unit: DistanceUnit) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(18.dp)).padding(horizontal = 16.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Column(Modifier.weight(1f, fill = false)) {
            Text("EMPFOHLEN", color = AppTheme.gold, fontSize = 9.sp, fontWeight = FontWeight.Black, letterSpacing = 1.2.sp)
            Text(club.name, color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Black, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        Text("Ø ${unit.format(club.averageDistance.toDouble())}", color = AppTheme.textSec, fontSize = 12.sp)
        Spacer(Modifier.weight(1f))
        neighbours.forEach { c ->
            Box(Modifier.height(30.dp).background(AppTheme.cardAlt, RoundedCornerShape(9.dp)).padding(horizontal = 9.dp), contentAlignment = Alignment.Center) {
                Text(c.name, color = AppTheme.text.copy(alpha = 0.8f), fontSize = 12.sp, fontWeight = FontWeight.Bold, maxLines = 1)
            }
        }
    }
}

// MARK: - Schlagzähler

@Composable
private fun StrokeCounterCard(
    strokes: Int, lastClub: String?, showsRestore: Boolean,
    onMinus: () -> Unit, onPlus: () -> Unit, onRestore: () -> Unit,
) {
    Box(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(22.dp))) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text("SCHLÄGE", color = AppTheme.textTer, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.5.sp)
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                RoundButton(Icons.Filled.Remove, "Schlag abziehen", 68, 26, AppTheme.cardAlt,
                    if (strokes > 0) AppTheme.text else AppTheme.textTer, enabled = strokes > 0, onClick = onMinus)
                Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                    AnimatedContent(strokes, transitionSpec = { fadeIn(tween(150)) togetherWith fadeOut(tween(150)) }, label = "strokes") { s ->
                        Text("$s", color = if (s > 0) AppTheme.text else AppTheme.textTer, fontSize = 96.sp, fontWeight = FontWeight.Black,
                            lineHeight = 98.sp, maxLines = 1, textAlign = TextAlign.Center)
                    }
                    // Zuletzt verwendeter Schläger – Platz bleibt reserviert, damit die Zahl nicht springt.
                    Text(lastClub ?: " ", color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
                }
                RoundButton(Icons.Filled.Add, "Schlag hinzufügen", 68, 26, AppTheme.gold, IosColors.onGoldDark, onClick = onPlus)
            }
        }
        AnimatedVisibility(showsRestore, Modifier.align(Alignment.TopEnd).padding(10.dp), enter = scaleIn() + fadeIn(), exit = scaleOut() + fadeOut()) {
            Box(
                Modifier.size(32.dp).background(AppTheme.gold.copy(alpha = 0.15f), CircleShape).clickable { onRestore() }
                    .semantics { contentDescription = "Schlägerauswahl einblenden" },
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Filled.SportsGolf, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp)) }
        }
    }
}

@Composable
private fun RoundButton(
    icon: ImageVector, description: String?, size: Int, iconSize: Int, bg: Color, tint: Color,
    enabled: Boolean = true, onClick: () -> Unit,
) {
    Box(
        Modifier.size(size.dp).background(bg, CircleShape).clickable(enabled = enabled) { onClick() },
        contentAlignment = Alignment.Center,
    ) { Icon(icon, description, tint = tint, modifier = Modifier.size(iconSize.dp)) }
}

// MARK: - Mitspieler-Karten

@Composable
private fun PlayerNameLabel(name: String) {
    Text(name, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp).padding(top = 4.dp))
}

/**
 * Kompakte Scorekarte eines Mitspielers: Schläge mit GPS-Kette, Putts,
 * Fairway und GIR – wie die eigene, nur kleiner, damit alle untereinander passen.
 */
@Composable
private fun PartnerCard(
    opp: PlayerHoleScore, name: String, role: String?, par: Int, unit: DistanceUnit,
    onMinus: () -> Unit, onPlus: () -> Unit, onAddPutt: () -> Unit, onRemovePutt: () -> Unit, onShots: () -> Unit,
    roundId: String,
) {
    val played = opp.strokes > 0
    val d = opp.strokes - par
    Column(
        Modifier.fillMaxWidth().background(AppTheme.cardDark.copy(alpha = 0.6f), RoundedCornerShape(20.dp))
            .border(1.dp, AppTheme.cardAlt, RoundedCornerShape(20.dp)).padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Column(Modifier.weight(1f, fill = false)) {
                Text(name, color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                if (role != null) Text(role, color = AppTheme.textSec, fontSize = 11.sp)
            }
            if (played) {
                Text(if (d == 0) "Par" else if (d > 0) "+$d" else "$d",
                    color = if (d < 0) AppTheme.gold else if (d > 0) IosColors.orange else AppTheme.text,
                    fontSize = 12.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.background(AppTheme.cardAlt, RoundedCornerShape(50)).padding(horizontal = 8.dp, vertical = 3.dp))
            }
            Spacer(Modifier.weight(1f))
            RoundButton(Icons.Filled.Remove, "Schlag abziehen – $name", 46, 18, AppTheme.cardAlt,
                if (played) AppTheme.text else AppTheme.textTer, enabled = played, onClick = onMinus)
            Text("${opp.strokes}", color = if (played) AppTheme.text else AppTheme.textTer, fontSize = 40.sp, fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center, modifier = Modifier.defaultMinSize(minWidth = 44.dp))
            RoundButton(Icons.Filled.Add, "Schlag hinzufügen – $name", 46, 18, AppTheme.gold, IosColors.onGoldDark, onClick = onPlus)
        }
        SecondaryStats(opp, par, roundId, opp.playerIndex, onAddPutt, onRemovePutt)
        Row(Modifier.fillMaxWidth().clickable { onShots() }.padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.PinDrop, null, tint = AppTheme.textSec, modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(6.dp))
            val n = opp.shots.size
            Text(
                if (n == 0) "Schläge auf der Karte" else "$n ${if (n == 1) "Schlag" else "Schläge"} erfasst · ${unit.format(opp.totalDistanceMeters)}",
                color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f),
            )
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textSec, modifier = Modifier.size(14.dp))
        }
    }
}

// MARK: - Putts, Fairway, GIR

@Composable
private fun SecondaryStats(entry: ScoreEntry, par: Int, roundId: String, player: Int, onAddPutt: () -> Unit, onRemovePutt: () -> Unit) {
    val hole = entry.holeNumber
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Column(
            Modifier.weight(1f).background(AppTheme.card, RoundedCornerShape(16.dp)).padding(vertical = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text("Putts", color = AppTheme.textSec, fontSize = 12.sp)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                RoundButton(Icons.Filled.Remove, "Putt abziehen", 28, 12, AppTheme.cardAlt,
                    if (entry.putts > 0) AppTheme.text else AppTheme.textTer, enabled = entry.putts > 0, onClick = onRemovePutt)
                Text("${entry.putts}", color = AppTheme.text, fontSize = 24.sp, fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center, modifier = Modifier.defaultMinSize(minWidth = 26.dp))
                RoundButton(Icons.Filled.Add, "Putt hinzufügen", 28, 12, AppTheme.gold.copy(alpha = 0.15f), AppTheme.gold, onClick = onAddPutt)
            }
        }
        if (par > 3) {
            ToggleBox("Fairway", entry.fairwayHit) { hit -> updateEntry(roundId, player, hole) { it.copy(fairwayHit = hit) } }
        }
        ToggleBox("GIR", entry.greenInRegulation) { hit -> updateEntry(roundId, player, hole) { it.copy(greenInRegulation = hit) } }
    }
}

@Composable
private fun RowScope.ToggleBox(label: String, value: Boolean, onChange: (Boolean) -> Unit) {
    Column(
        Modifier.weight(1f).background(if (value) AppTheme.gold.copy(alpha = 0.1f) else AppTheme.card, RoundedCornerShape(16.dp))
            .clickable {
                val hit = !value
                if (hit) Haptics.success() else Haptics.selection()
                onChange(hit)
            }
            .semantics { contentDescription = "$label: ${if (value) "Ja" else "Nein"}" }
            .padding(vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(label, color = AppTheme.textSec, fontSize = 12.sp)
        Icon(if (value) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked, null,
            tint = if (value) AppTheme.gold else AppTheme.textTer, modifier = Modifier.size(26.dp))
    }
}

// MARK: - Lochleiste

@Composable
private fun HoleStrip(round: Round, current: Int, onSelectHole: (Int) -> Unit) {
    val scroll = rememberScrollState()
    val density = LocalDensity.current
    val holes = round.sortedScores
    val index = holes.indexOfFirst { it.holeNumber == current }.coerceAtLeast(0)
    LaunchedEffect(index, scroll.viewportSize) {
        val step = with(density) { 36.dp.toPx() }
        val half = with(density) { 15.dp.toPx() }
        val target = (step * index + half - scroll.viewportSize / 2f).toInt()
        scroll.animateScrollTo(target.coerceIn(0, scroll.maxValue))
    }
    Row(Modifier.fillMaxWidth().horizontalScroll(scroll).padding(horizontal = 2.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        holes.forEach { h ->
            val isCurrent = h.holeNumber == current
            val played = h.strokes > 0
            Box(
                Modifier.size(30.dp)
                    .background(if (isCurrent) AppTheme.gold else if (played) AppTheme.cardAlt else AppTheme.cardDark, CircleShape)
                    .clickable { if (!isCurrent) onSelectHole(h.holeNumber) }
                    .semantics { contentDescription = "Loch ${h.holeNumber}" },
                contentAlignment = Alignment.Center,
            ) {
                Text("${h.holeNumber}", fontSize = 12.sp, fontWeight = FontWeight.Bold,
                    color = if (isCurrent) IosColors.onGoldDark else if (played) AppTheme.text else AppTheme.textTer)
            }
        }
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
private fun OpponentSection(
    round: Round, score: HoleScore, par: Int, opponents: List<PlayerHoleScore>,
    showsPartnerCards: Boolean, roleLabel: (PlayerHoleScore) -> String?,
) {
    val mode = round.gameMode
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        // Mit eigenen Karten stehen die Mitspieler schon oben – hier bleibt nur die Auswertung des Lochs.
        if (!showsPartnerCards) {
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
                val role = roleLabel(opp)
                Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(opp.playerName.ifEmpty { "Spieler ${opp.playerIndex + 1}" }, color = AppTheme.text, fontSize = 15.sp)
                        if (role != null) Text(role, color = AppTheme.textSec, fontSize = 11.sp)
                    }
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        RoundButton(Icons.Filled.Remove, null, 28, 16, AppTheme.cardAlt,
                            if (opp.strokes > 0) AppTheme.text else AppTheme.textSec, enabled = opp.strokes > 0) {
                            Haptics.light(); updateOpponent(round.id, opp.playerIndex, opp.holeNumber, opp.strokes - 1)
                        }
                        Text("${opp.strokes}", color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold,
                            modifier = Modifier.defaultMinSize(minWidth = 28.dp), textAlign = TextAlign.Center)
                        RoundButton(Icons.Filled.Add, null, 28, 16, AppTheme.cardAlt, AppTheme.text) {
                            Haptics.stroke(); updateOpponent(round.id, opp.playerIndex, opp.holeNumber, opp.strokes + 1)
                        }
                    }
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
    unit: DistanceUnit,
    onPick: (GolfClub) -> Unit,
    onHideForRound: () -> Unit,
    onDismiss: () -> Unit,
) {
    val sheet = rememberModalBottomSheetState(skipPartiallyExpanded = false)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheet, containerColor = AppTheme.bg) {
        Column(Modifier.fillMaxWidth()) {
            Box(Modifier.fillMaxWidth().padding(horizontal = 8.dp)) {
                Text("Überspringen", color = AppTheme.textSec, fontSize = 16.sp,
                    modifier = Modifier.align(Alignment.CenterStart).clickable { Haptics.tap(); onDismiss() }.padding(8.dp))
                Text("Schlag $strokeNumber – Schläger?", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.align(Alignment.Center))
                Box(
                    Modifier.align(Alignment.CenterEnd).size(40.dp).clickable { Haptics.tap(); onHideForRound() }
                        .semantics { contentDescription = "Schlägerauswahl für diese Runde ausblenden" },
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.Filled.VisibilityOff, null, tint = AppTheme.textSec, modifier = Modifier.size(20.dp)) }
            }
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
private fun ClubButton(club: GolfClub, isRecommended: Boolean, unit: DistanceUnit, onClick: () -> Unit) {
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
