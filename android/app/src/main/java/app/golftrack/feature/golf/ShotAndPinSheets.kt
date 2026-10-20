package app.golftrack.feature.golf

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.data.GolfStore
import app.golftrack.data.LatLon
import app.golftrack.data.Round
import app.golftrack.data.Shot
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

/** Wie PinSetterView.swift: Lochposition auf dem Luftbild setzen oder verschieben. */
@Composable
fun PinSetterSheet(initial: LatLon?, here: LatLon?, onSave: (LatLon) -> Unit, onDismiss: () -> Unit) {
    val unit = rememberDistanceUnit()
    var pending by remember { mutableStateOf(initial) }
    val mapState = rememberGolfMapState()

    FullSheet(onDismiss) {
        Column(Modifier.fillMaxSize()) {
            SheetTopBar("Pin setzen", leading = { BarButton("Abbrechen") { Haptics.tap(); onDismiss() } })
            Box(Modifier.weight(1f).fillMaxWidth()) {
                GolfMap(
                    items = listOfNotNull(pending?.let {
                        MapItem.Dot(it, IosColors.red, sizeDp = 32, icon = MapIcon.FLAG, bottomAnchor = true, draggable = true,
                            onDragEnd = { p -> pending = p })
                    }),
                    modifier = Modifier.fillMaxSize(),
                    state = mapState,
                    satellite = true,
                    userLocation = here,
                    initialFit = listOfNotNull(initial ?: here),
                    onTap = { Haptics.heavy(); pending = it },
                )
                // Hinweis oben
                Row(
                    Modifier.align(Alignment.TopCenter).padding(horizontal = 16.dp, vertical = 8.dp).padding(end = 48.dp).fillMaxWidth()
                        .background(AppTheme.cardDark.copy(alpha = 0.88f), RoundedCornerShape(12.dp)).padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.Place, null, tint = AppTheme.gold, modifier = Modifier.size(22.dp))
                    Spacer(Modifier.width(10.dp))
                    Text("Tippe auf die Karte oder ziehe den Pin, um das Loch zu markieren", color = AppTheme.text, fontSize = 14.sp, fontWeight = FontWeight.Bold)
                }
            }
            // Unteres Panel
            Column(
                Modifier.fillMaxWidth().background(AppTheme.cardDark).padding(horizontal = 16.dp).padding(top = 16.dp, bottom = 16.dp).navigationBarsPadding(),
                verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                val p = pending
                if (p != null && here != null) {
                    Row(Modifier.padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.SwapHoriz, null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Entfernung:", color = AppTheme.textSec, fontSize = 15.sp)
                        Spacer(Modifier.width(6.dp))
                        Text(unit.format(p.distanceTo(here)), color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    }
                }
                Row(
                    Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(12.dp)).clickable {
                        Haptics.tap()
                        here?.let { pending = it; mapState.center(it, 18.5) }
                    }.padding(vertical = 13.dp),
                    horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.MyLocation, null, tint = AppTheme.text, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Meinen Standort verwenden", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                }
                Box(
                    Modifier.fillMaxWidth().background(if (p != null) AppTheme.gold else AppTheme.card, RoundedCornerShape(14.dp))
                        .clickable {
                            if (p != null) { Haptics.success(); onSave(p) } else Haptics.tap()
                            onDismiss()
                        }.padding(vertical = 16.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        if (p != null) "Speichern" else "Ohne Pin schließen",
                        color = if (p != null) AppTheme.onGold else AppTheme.textSec, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                    )
                }
            }
        }
    }
}

private enum class Placing(val label: String, val color: Color) {
    FROM("Abschlag", IosColors.blue), TO("Treffpunkt", IosColors.orange)
}

/** Wie ShotTrackerView.swift: Schläge auf der Karte erfassen (Abschlag → Treffpunkt). */
@Composable
fun ShotTrackerSheet(round: Round, hole: Int, here: LatLon?, onDismiss: () -> Unit) {
    val data by GolfStore.data.collectAsState()
    val unit = rememberDistanceUnit()
    val holeScore = data.round(round.id)?.score(hole)
    val shots = holeScore?.sortedShots.orEmpty()
    var from by remember { mutableStateOf<LatLon?>(null) }
    var to by remember { mutableStateOf<LatLon?>(null) }
    var placing by remember { mutableStateOf(Placing.FROM) }
    var selectedClub by remember { mutableStateOf("") }
    var satellite by remember { mutableStateOf(false) }
    var noLocation by remember { mutableStateOf(false) }
    val mapState = rememberGolfMapState()

    val fallbackClubs = listOf("Driver", "3 Wood", "5 Wood", "4 Eisen", "5 Eisen", "6 Eisen", "7 Eisen", "8 Eisen", "9 Eisen", "PW", "GW", "SW", "LW", "Putter")
    val allClubs = data.bags.flatMap { it.clubs }.sortedBy { it.order }
    val clubNames = if (allClubs.isEmpty()) fallbackClubs else allClubs.map { it.name }.distinct()
    val canUndo = from != null || shots.isNotEmpty()

    fun handleTap(c: LatLon) {
        Haptics.heavy()
        when (placing) {
            Placing.FROM -> { from = c; placing = Placing.TO }
            Placing.TO -> to = c
        }
    }

    fun useCurrentLocation() {
        val c = here
        if (c == null) { Haptics.error(); noLocation = true; return }
        handleTap(c)
        mapState.center(c, 17.5)
    }

    fun saveShot() {
        val f = from ?: return
        val t = to ?: return
        Haptics.success()
        val dist = f.distanceTo(t)
        updateHole(round.id, hole) { hs ->
            hs.copy(shots = hs.shots + Shot(hs.sortedShots.size + 1, f.lat, f.lon, t.lat, t.lon, selectedClub))
        }
        // Distanz automatisch in die Schläger-Datenbank eintragen
        if (selectedClub.isNotEmpty()) {
            GolfStore.current.bags.firstOrNull { b -> b.clubs.any { it.name == selectedClub } }?.let { bag ->
                var done = false
                GolfStore.upsertBag(bag.copy(clubs = bag.clubs.map {
                    if (!done && it.name == selectedClub) { done = true; it.addMeasurement(dist) } else it
                }))
            }
        }
        // Nächster Schlag beginnt, wo dieser endete
        from = t; to = null; selectedClub = ""; placing = Placing.TO
    }

    fun undo() {
        when {
            to != null -> to = null
            from != null -> { from = null; placing = Placing.FROM }
            shots.isNotEmpty() -> {
                val last = shots.last()
                updateHole(round.id, hole) { hs -> hs.copy(shots = hs.shots.filter { it.shotNumber != last.shotNumber }) }
            }
        }
    }

    fun clearAll() {
        updateHole(round.id, hole) { it.copy(shots = emptyList()) }
        from = null; to = null; placing = Placing.FROM; selectedClub = ""
    }

    val items = buildList<MapItem> {
        shots.forEach { s ->
            add(MapItem.Line(listOf(s.from, s.to), goldA(0.7f), 2f))
            add(MapItem.Dot(s.to, Color.White, sizeDp = 26, icon = MapIcon.TARGET, fg = IosColors.orange))
            add(MapItem.Dot(s.from, IosColors.blue, sizeDp = 28, text = "${s.shotNumber}"))
        }
        val f = from
        val t = to
        if (f != null && t != null) add(MapItem.Line(listOf(f, t), AppTheme.gold, 2.5f))
        if (t != null) add(MapItem.Dot(t, Color.White, sizeDp = 26, icon = MapIcon.TARGET, fg = IosColors.orange))
        if (f != null) add(MapItem.Dot(f, IosColors.blue, sizeDp = 28, text = "${shots.size + 1}"))
    }

    FullSheet(onDismiss) {
        Column(Modifier.fillMaxSize()) {
            SheetTopBar(
                "Loch $hole – Schläge",
                leading = { BarButton("Fertig") { Haptics.tap(); onDismiss() } },
                trailing = {
                    if (canUndo) BarIconButton(Icons.AutoMirrored.Filled.Undo, description = "Rückgängig") { Haptics.light(); undo() }
                    if (shots.isNotEmpty() || from != null) BarButton("Alle löschen", color = IosColors.red) { Haptics.warning(); clearAll() }
                },
            )
            // Hinweisleiste
            Row(
                Modifier.fillMaxWidth().background(placing.color.copy(alpha = 0.08f)).padding(horizontal = 14.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(if (placing == Placing.FROM) Icons.Filled.SportsGolf else Icons.Filled.GpsFixed, null, tint = placing.color, modifier = Modifier.width(22.dp))
                Spacer(Modifier.width(10.dp))
                Column(Modifier.weight(1f)) {
                    Text(placing.label + " setzen", color = placing.color, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Text("Tippe auf Karte oder nutze deinen Standort", color = AppTheme.textSec, fontSize = 12.sp)
                }
                Row(
                    Modifier.background(placing.color, RoundedCornerShape(50)).clickable { Haptics.tap(); useCurrentLocation() }
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.MyLocation, null, tint = Color.White, modifier = Modifier.size(12.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("Standort", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            }
            Box(Modifier.weight(1f).fillMaxWidth()) {
                GolfMap(
                    items = items, modifier = Modifier.fillMaxSize(), state = mapState, satellite = satellite,
                    userLocation = here, initialFit = shots.flatMap { listOf(it.from, it.to) }.ifEmpty { listOfNotNull(here) },
                    onTap = ::handleTap,
                )
                SatelliteToggle(satellite, Modifier.align(Alignment.TopStart).padding(12.dp)) { satellite = !satellite }
            }
            // Unteres Panel
            Column(
                Modifier.fillMaxWidth().background(AppTheme.card).heightIn(max = 320.dp).verticalScroll(rememberScrollState())
                    .padding(vertical = 10.dp).navigationBarsPadding(),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                val f = from
                val t = to
                if (f != null && t != null) {
                    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(unit.format(f.distanceTo(t)), color = AppTheme.gold, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                            Text(unit.displayName, color = AppTheme.textSec, fontSize = 12.sp)
                        }
                        Spacer(Modifier.weight(1f))
                        Text("Speichern", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.background(AppTheme.gold, RoundedCornerShape(10.dp)).clickable { saveShot() }
                                .padding(horizontal = 16.dp, vertical = 9.dp))
                    }
                    HorizontalDivider(color = AppTheme.cardAlt)
                }
                if (f != null) {
                    Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        clubNames.forEach { c ->
                            val sel = selectedClub == c
                            Text(c, color = if (sel) Color.White else AppTheme.text, fontSize = 12.sp,
                                modifier = Modifier.background(if (sel) AppTheme.gold else Color.Gray.copy(alpha = 0.15f), RoundedCornerShape(50))
                                    .clickable { Haptics.selection(); selectedClub = c }.padding(horizontal = 10.dp, vertical = 6.dp))
                        }
                    }
                    HorizontalDivider(color = AppTheme.cardAlt)
                }
                if (shots.isNotEmpty()) {
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Gespeicherte Schläge", color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 16.dp))
                        shots.forEach { s ->
                            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Filled.SportsGolf, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp))
                                Spacer(Modifier.width(6.dp))
                                Text("Schlag ${s.shotNumber}", color = AppTheme.text, fontSize = 15.sp)
                                if (s.club.isNotEmpty()) Text(" · ${s.club}", color = AppTheme.textSec, fontSize = 12.sp)
                                Spacer(Modifier.weight(1f))
                                Text(unit.format(s.distanceMeters), color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        }
    }

    if (noLocation) {
        AlertDialog(
            onDismissRequest = { noLocation = false },
            title = { Text("Standort nicht verfügbar") },
            text = { Text("Stelle sicher, dass der Standortzugriff erlaubt ist.") },
            confirmButton = { TextButton(onClick = { Haptics.tap(); noLocation = false }) { Text("OK", color = AppTheme.gold) } },
            containerColor = AppTheme.card,
        )
    }
}
