package app.golftrack.feature.lobby

import android.content.Intent
import android.net.Uri
import android.text.format.DateUtils
import androidx.activity.compose.BackHandler
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.LocationOff
import androidx.compose.material.icons.filled.PersonOff
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import app.golftrack.data.LatLon
import app.golftrack.data.Round
import app.golftrack.feature.golf.BarButton
import app.golftrack.feature.golf.FullSheet
import app.golftrack.feature.golf.GolfMap
import app.golftrack.feature.golf.MapItem
import app.golftrack.feature.golf.SheetTopBar
import app.golftrack.feature.golf.rememberGolfMapState
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

private val darkText = Color(0xFF0F2414)
private val orange = Color(0xFFFF9500)
private val online = Color(0xFF34C759)

// MARK: - Runde ↔ Lobby

/**
 * Verbindet die offene Zählkarte mit der Lobby (wie die `.onAppear`/`.onChange`-
 * Teile in ScorecardView.swift): eigenen Stand melden, Freunde abholen,
 * im Hintergrund pausieren.
 */
@Composable
fun LobbyRoundEffect(round: Round, currentHole: Int) {
    val ctx = LocalContext.current
    val session by LobbyService.session.collectAsState()
    val linked = round.lobbyCode.isNotEmpty() && session?.code == round.lobbyCode && !round.isComplete
    val latest by rememberUpdatedState(round)
    val lifecycle = LocalLifecycleOwner.current.lifecycle

    DisposableEffect(linked, round.id, lifecycle) {
        if (!linked) return@DisposableEffect onDispose {}
        LobbyService.attach(latest, ctx)
        val obs = LifecycleEventObserver { _, e ->
            when (e) {
                Lifecycle.Event.ON_START -> { LobbyService.onForeground(ctx); LobbyService.attach(latest, ctx) }
                Lifecycle.Event.ON_STOP -> LobbyService.onBackground(ctx)
                else -> {}
            }
        }
        lifecycle.addObserver(obs)
        onDispose {
            lifecycle.removeObserver(obs)
            LobbyService.detach(latest, ctx)
            LobbyService.pauseIfIdle()
        }
    }

    // Ändert sich bei jedem Schlag, Putt, Schläger und Lochwechsel – Auslöser,
    // den eigenen Stand an die Lobby zu melden.
    val signature = if (!linked) "" else "$currentHole|" + round.sortedScores.joinToString("|") { s ->
        "${s.strokes}.${s.putts}.${if (s.fairwayHit) 1 else 0}${if (s.greenInRegulation) 1 else 0}." +
            s.sortedShots.joinToString(",") { it.club }
    }
    LaunchedEffect(signature) {
        if (linked) LobbyService.publish(latest, currentHole)
    }
}

/** Ob die Runde mit der gerade offenen Lobby verbunden ist. */
@Composable
fun isLobbyRound(round: Round): Boolean {
    val session by LobbyService.session.collectAsState()
    return round.lobbyCode.isNotEmpty() && session?.code == round.lobbyCode
}

// MARK: - Leiste

/** Leiste unter der Lochkarte: wo die Freunde aus der Lobby gerade stehen. */
@Composable
fun LobbyStrip(pars: List<Int>, modifier: Modifier = Modifier, onOpen: () -> Unit) {
    val state by LobbyService.state.collectAsState()
    val others = state?.others.orEmpty()
    if (others.isEmpty()) return
    Row(
        modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))
            .clickable { Haptics.tap(); onOpen() }
            .padding(horizontal = 12.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.Group, "Lobby öffnen", tint = AppTheme.gold, modifier = Modifier.size(15.dp))
        Spacer(Modifier.width(10.dp))
        Row(Modifier.weight(1f).horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            others.forEach { member -> Chip(member, pars) }
        }
        Spacer(Modifier.width(10.dp))
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer, modifier = Modifier.size(16.dp))
    }
}

@Composable
private fun Chip(member: LobbyMember, pars: List<Int>) {
    Row(
        Modifier.background(AppTheme.bg, RoundedCornerShape(50)).padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(5.dp),
    ) {
        Box(Modifier.size(6.dp).background(if (member.isStale) AppTheme.textTer else online, CircleShape))
        Text(member.name, color = AppTheme.text, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
        Text(LobbyFormat.toPar(member.toPar(pars)), color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
        if (member.currentHole > 0) Text("L${member.currentHole}", color = AppTheme.textSec, fontSize = 11.sp)
    }
}

// MARK: - Live-Ansicht

/**
 * Die Lobby während der Runde: Ergebnisse aller, Schläge der Freunde je Loch
 * und – wenn eingeschaltet – die Karte, auf der man sich wiederfindet.
 */
@Composable
fun LobbyLiveSheet(pars: List<Int>, here: LatLon?, onDismiss: () -> Unit) {
    val state by LobbyService.state.collectAsState()
    var mapTab by remember { mutableStateOf(false) }
    var detailId by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(Unit) { LobbyService.refresh() }
    LaunchedEffect(here) { LobbyService.noteLocation(here) }

    FullSheet(onDismiss) {
        val detail = detailId
        if (detail != null) {
            BackHandler { detailId = null }
            MemberDetail(detail, pars) { detailId = null }
            return@FullSheet
        }
        Column(Modifier.fillMaxSize()) {
            SheetTopBar(
                LobbyService.code?.let { "Lobby $it" } ?: "Lobby",
                trailing = { BarButton("Fertig", bold = true) { Haptics.tap(); onDismiss() } },
            )
            val s = state
            if (s == null) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = AppTheme.gold) }
                return@Column
            }
            Row(
                Modifier.padding(horizontal = 16.dp, vertical = 8.dp).fillMaxWidth()
                    .background(AppTheme.cardDark, RoundedCornerShape(9.dp)).padding(2.dp),
            ) {
                listOf(false to "Ergebnisse", true to "Karte").forEach { (value, title) ->
                    val sel = mapTab == value
                    Box(
                        Modifier.weight(1f).background(if (sel) AppTheme.cardAlt else Color.Transparent, RoundedCornerShape(7.dp))
                            .clickable { if (!sel) { Haptics.selection(); mapTab = value } }.padding(vertical = 6.dp),
                        contentAlignment = Alignment.Center,
                    ) { Text(title, color = AppTheme.text, fontSize = 13.sp, fontWeight = if (sel) FontWeight.SemiBold else FontWeight.Normal) }
                }
            }
            if (mapTab) MapTab(s, Modifier.weight(1f)) else ScoresTab(s, pars, Modifier.weight(1f)) { detailId = it }
        }
    }
}

@Composable
private fun ScoresTab(state: LobbyState, pars: List<Int>, modifier: Modifier, onOpen: (String) -> Unit) {
    val ranked = state.members.sortedWith(compareBy<LobbyMember>({ it.toPar(pars) ?: Int.MAX_VALUE }, { it.name }))
    Column(modifier.verticalScroll(rememberScrollState()).padding(16.dp).navigationBarsPadding()) {
        Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(12.dp))) {
            ranked.forEachIndexed { i, member ->
                Row(
                    Modifier.fillMaxWidth().clickable { Haptics.tap(); onOpen(member.id) }.padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Initial(member.name, alpha = if (member.id == state.me) 0.85f else 0.55f)
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(if (member.id == state.me) "${member.name} (du)" else member.name, color = AppTheme.text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                        Text(status(member), color = AppTheme.textSec, fontSize = 12.sp)
                    }
                    Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(LobbyFormat.toPar(member.toPar(pars)), color = AppTheme.gold, fontSize = 20.sp, fontWeight = FontWeight.Black)
                        Text("${member.totalStrokes} Schläge", color = AppTheme.textSec, fontSize = 11.sp)
                    }
                    Spacer(Modifier.width(6.dp))
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer, modifier = Modifier.size(16.dp))
                }
                if (i < ranked.lastIndex) HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(start = 58.dp))
            }
        }
        Text(
            "Jeder zählt auf seinem eigenen Handy. Aktualisiert sich alle paar Sekunden.",
            color = AppTheme.textSec, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp),
        )
    }
}

private fun status(member: LobbyMember): String {
    val parts = mutableListOf<String>()
    if (member.currentHole > 0) parts += "Loch ${member.currentHole}"
    parts += "${member.playedHoles.size} gespielt"
    if (member.isStale) parts += "zuletzt ${relative(member.seenAtMillis)}"
    return parts.joinToString(" · ")
}

private fun relative(millis: Long): String =
    DateUtils.getRelativeTimeSpanString(millis, System.currentTimeMillis(), DateUtils.MINUTE_IN_MILLIS).toString()

@Composable
private fun MapTab(state: LobbyState, modifier: Modifier) {
    if (!state.tracking) {
        Column(
            modifier.fillMaxWidth().padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp, Alignment.CenterVertically),
        ) {
            Icon(Icons.Filled.LocationOff, null, tint = AppTheme.textSec, modifier = Modifier.size(44.dp))
            Text("Orten ist aus", color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
            Text(
                if (LobbyService.isHost) "Schalte „Gegenseitig orten“ beim Rundenstart in der Lobby ein."
                else "Der Gastgeber hat das gegenseitige Orten nicht eingeschaltet.",
                color = AppTheme.textSec, fontSize = 14.sp, textAlign = TextAlign.Center,
            )
        }
        return
    }
    val ctx = LocalContext.current
    val me by LobbyService.myLocation.collectAsState()
    val share by LobbyService.shareLocation.collectAsState()
    val located = state.others.filter { it.location != null }
    val mapState = rememberGolfMapState()
    val items = located.map { m ->
        MapItem.Dot(m.location!!.point, AppTheme.gold, sizeDp = 34, text = m.name.take(1).uppercase(), fg = darkText, border = Color.White)
    }
    Column(modifier.fillMaxWidth()) {
        GolfMap(
            items = items,
            modifier = Modifier.fillMaxWidth().weight(1f),
            state = mapState,
            satellite = true,
            userLocation = me,
            initialFit = located.map { it.location!!.point } + listOfNotNull(me),
        )
        Column(
            Modifier.fillMaxWidth().heightIn(max = 260.dp).verticalScroll(rememberScrollState()).padding(12.dp).navigationBarsPadding(),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (!share) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.LocationOff, null, tint = orange, modifier = Modifier.size(13.dp))
                    Spacer(Modifier.width(5.dp))
                    Text("Du teilst deinen Standort gerade nicht.", color = orange, fontSize = 12.sp)
                }
            }
            if (located.isEmpty()) {
                Text(
                    "Noch kein Standort von deinen Freunden – sie müssen ihn in der Lobby teilen und die Runde gestartet haben.",
                    color = AppTheme.textSec, fontSize = 12.sp, textAlign = TextAlign.Center,
                )
            }
            located.forEach { member ->
                val loc = member.location!!
                Row(
                    Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(12.dp)).padding(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(member.name, color = AppTheme.text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                        Text(locationText(loc, me), color = AppTheme.textSec, fontSize = 12.sp)
                    }
                    RoundIcon(Icons.Filled.GpsFixed, "${member.name} auf der Karte zeigen") {
                        Haptics.tap(); mapState.center(loc.point, 17.5)
                    }
                    Spacer(Modifier.width(8.dp))
                    RoundIcon(Icons.AutoMirrored.Filled.DirectionsWalk, "Zu ${member.name} gehen") {
                        Haptics.tap()
                        val label = Uri.encode(member.name)
                        val uri = Uri.parse("geo:${loc.lat},${loc.lon}?q=${loc.lat},${loc.lon}($label)")
                        runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, uri)) }
                    }
                }
            }
        }
    }
}

@Composable
private fun RoundIcon(icon: androidx.compose.ui.graphics.vector.ImageVector, description: String, onClick: () -> Unit) {
    Box(
        Modifier.size(36.dp).background(AppTheme.gold.copy(alpha = 0.15f), CircleShape).clickable { onClick() },
        contentAlignment = Alignment.Center,
    ) { Icon(icon, description, tint = AppTheme.gold, modifier = Modifier.size(18.dp)) }
}

private fun locationText(location: LobbyLocation, me: LatLon?): String {
    val age = relative(location.atMillis)
    me ?: return age
    val meters = me.distanceTo(location.point).roundToInt()
    return "$meters m ${LobbyFormat.compass(me, location.point)} · $age"
}

// MARK: - Mitspieler im Detail

/** Schläge eines Mitspielers Loch für Loch, mit Schlägern und Längen. */
@Composable
private fun MemberDetail(memberId: String, pars: List<Int>, onBack: () -> Unit) {
    val state by LobbyService.state.collectAsState()
    val member = state?.members?.firstOrNull { it.id == memberId }
    Column(Modifier.fillMaxSize()) {
        SheetTopBar(member?.name ?: "", leading = { BarButton("Zurück") { Haptics.tap(); onBack() } })
        if (member == null) {
            Column(
                Modifier.fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(10.dp, Alignment.CenterVertically),
            ) {
                Icon(Icons.Filled.PersonOff, null, tint = AppTheme.textSec, modifier = Modifier.size(44.dp))
                Text("Nicht mehr in der Lobby", color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
            }
            return@Column
        }
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp).navigationBarsPadding(),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            if (member.playedHoles.isEmpty()) {
                Text(
                    "${member.name} hat noch kein Loch gespielt.", color = AppTheme.textSec,
                    modifier = Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(12.dp)).padding(14.dp),
                )
            }
            member.playedHoles.sortedByDescending { it.hole }.forEach { hole ->
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("LOCH ${hole.hole}", color = AppTheme.textTer, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(horizontal = 4.dp))
                    Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(12.dp)).padding(horizontal = 14.dp, vertical = 10.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Stat("Schläge", "${hole.strokes}")
                            Stat("Putts", "${hole.putts}")
                            pars.getOrNull(hole.hole - 1)?.let { Stat("Par", "$it") }
                            if (hole.fairway) Badge("Fairway")
                            if (hole.gir) { Spacer(Modifier.width(6.dp)); Badge("GIR") }
                        }
                        hole.shots.forEach { shot ->
                            HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(vertical = 8.dp))
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text("${shot.n}.", color = AppTheme.textTer, fontSize = 12.sp, modifier = Modifier.width(24.dp))
                                Text(shot.club.ifEmpty { "Schlag" }, color = AppTheme.text, fontSize = 14.sp, modifier = Modifier.weight(1f))
                                shot.meters?.takeIf { it > 0 }?.let { Text("${it.toInt()} m", color = AppTheme.textSec, fontSize = 14.sp) }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Stat(label: String, value: String) {
    Column(Modifier.widthIn(min = 52.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(1.dp)) {
        Text(value, color = AppTheme.gold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        Text(label, color = AppTheme.textSec, fontSize = 11.sp)
    }
}

@Composable
private fun Badge(text: String) {
    Text(
        text, color = AppTheme.gold, fontSize = 11.sp, fontWeight = FontWeight.Bold,
        modifier = Modifier.background(AppTheme.gold.copy(alpha = 0.2f), RoundedCornerShape(50)).padding(horizontal = 6.dp, vertical = 3.dp),
    )
}

// MARK: - Formate

object LobbyFormat {
    fun toPar(value: Int?): String = when {
        value == null -> "–"
        value == 0 -> "E"
        value > 0 -> "+$value"
        else -> "$value"
    }

    /** Himmelsrichtung von `from` nach `to` (N, NO, O, …). */
    fun compass(from: LatLon, to: LatLon): String {
        val lat1 = Math.toRadians(from.lat)
        val lat2 = Math.toRadians(to.lat)
        val dLon = Math.toRadians(to.lon - from.lon)
        val y = sin(dLon) * cos(lat2)
        val x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        val bearing = (Math.toDegrees(atan2(y, x)) + 360) % 360
        val names = listOf("N", "NO", "O", "SO", "S", "SW", "W", "NW")
        return names[((bearing + 22.5) / 45).toInt() % 8]
    }
}
