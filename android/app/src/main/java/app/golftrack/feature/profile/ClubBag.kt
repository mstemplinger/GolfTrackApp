package app.golftrack.feature.profile

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.DistanceUnit
import app.golftrack.data.GolfBag
import app.golftrack.data.GolfClub
import app.golftrack.data.GolfStore
import app.golftrack.data.rememberPrefString
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

private val defaultClubs = listOf(
    Triple("Driver", 220, false), Triple("3 Wood", 195, false), Triple("5 Wood", 180, false),
    Triple("3 Eisen", 185, false), Triple("4 Eisen", 175, false), Triple("5 Eisen", 165, false),
    Triple("6 Eisen", 155, false), Triple("7 Eisen", 145, false), Triple("8 Eisen", 130, false),
    Triple("9 Eisen", 120, false), Triple("PW", 110, false), Triple("GW", 95, false),
    Triple("SW", 80, false), Triple("LW", 60, false), Triple("Putter", 10, true),
)

private fun updateBag(id: String, t: (GolfBag) -> GolfBag) {
    val b = GolfStore.current.bag(id) ?: return
    GolfStore.upsertBag(t(b))
}

private fun updateClub(bagId: String, clubId: String, t: (GolfClub) -> GolfClub) =
    updateBag(bagId) { b -> b.copy(clubs = b.clubs.map { if (it.id == clubId) t(it) else it }) }

@Composable
private fun TextInputDialog(title: String, placeholder: String, initial: String, confirm: String, onDismiss: () -> Unit, onConfirm: (String) -> Unit) {
    var text by remember { mutableStateOf(initial) }
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = AppTheme.card,
        title = { Text(title, color = AppTheme.text) },
        text = {
            OutlinedTextField(
                text, { text = it }, singleLine = true, placeholder = { Text(placeholder, color = AppTheme.textTer) },
                colors = fieldColors(),
            )
        },
        confirmButton = {
            TextButton(onClick = { onConfirm(text.trim()) }) { Text(confirm, color = AppTheme.gold, fontWeight = FontWeight.SemiBold) }
        },
        dismissButton = { TextButton(onClick = { Haptics.tap(); onDismiss() }) { Text("Abbrechen", color = AppTheme.textSec) } },
    )
}

@Composable
internal fun fieldColors() = OutlinedTextFieldDefaults.colors(
    focusedTextColor = AppTheme.text, unfocusedTextColor = AppTheme.text,
    focusedBorderColor = AppTheme.gold, unfocusedBorderColor = AppTheme.cardAlt,
    cursorColor = AppTheme.gold, focusedContainerColor = AppTheme.cardAlt, unfocusedContainerColor = AppTheme.cardAlt,
)

/** Übersicht aller Bags wie `BagManagerView`. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun BagManagerScreen(nav: NavController) {
    val data by GolfStore.data.collectAsState()
    val bags = data.bags.sortedBy { it.createdAt }
    var showAdd by remember { mutableStateOf(false) }
    var renaming by remember { mutableStateOf<GolfBag?>(null) }
    var menuFor by remember { mutableStateOf<String?>(null) }

    AppScaffold("Schläger-Bags", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            if (bags.isEmpty()) {
                Column(
                    Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Icon(Icons.Filled.ShoppingBag, null, tint = AppTheme.textTer, modifier = Modifier.size(40.dp))
                    Text("Noch keine Bags", color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    Text("Erstelle dein erstes Schläger-Bag.", color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.Center)
                    Row(
                        Modifier.clip(RoundedCornerShape(12.dp)).background(AppTheme.gold).clickable {
                            Haptics.success()
                            GolfStore.upsertBag(
                                GolfBag(name = "Standard", clubs = defaultClubs.mapIndexed { i, (n, d, p) ->
                                    GolfClub(name = n, defaultDistance = d, order = i, isPutter = p)
                                }),
                            )
                        }.padding(horizontal = 20.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.Download, null, tint = AppTheme.onGold, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Standard-Bag erstellen", color = AppTheme.onGold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    }
                }
            } else {
                GroupCard {
                    bags.forEachIndexed { i, bag ->
                        Box {
                            Row(
                                Modifier.fillMaxWidth()
                                    .combinedClickable(
                                        onClick = { Haptics.tap(); nav.navigate(ProfileExtraRoutes.bag(bag.id)) },
                                        onLongClick = { Haptics.medium(); menuFor = bag.id },
                                    )
                                    .padding(horizontal = 16.dp, vertical = 12.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                IconBadge(Icons.Filled.ShoppingBag, AppTheme.gold, 44.dp, 10.dp)
                                Spacer(Modifier.width(14.dp))
                                Column(Modifier.weight(1f)) {
                                    Text(bag.name, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                                    val putters = bag.clubs.count { it.isPutter }
                                    Text(
                                        "${bag.clubs.size} Schläger" + if (putters > 0) " · $putters Putter" else "",
                                        color = AppTheme.textSec, fontSize = 12.sp,
                                    )
                                }
                                Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))
                            }
                            DropdownMenu(expanded = menuFor == bag.id, onDismissRequest = { menuFor = null }, containerColor = AppTheme.cardAlt) {
                                DropdownMenuItem(
                                    text = { Text("Umbenennen", color = AppTheme.text) },
                                    leadingIcon = { Icon(Icons.Filled.Edit, null, tint = iosOrange) },
                                    onClick = { Haptics.tap(); menuFor = null; renaming = bag },
                                )
                                DropdownMenuItem(
                                    text = { Text("Löschen", color = iosRed) },
                                    leadingIcon = { Icon(Icons.Filled.Delete, null, tint = iosRed) },
                                    onClick = { Haptics.warning(); menuFor = null; GolfStore.deleteBag(bag.id) },
                                )
                            }
                        }
                        if (i < bags.lastIndex) RowDivider(74.dp)
                    }
                }
                Text(
                    "Lange tippen zum Umbenennen oder Löschen.", color = AppTheme.textTer, fontSize = 12.sp,
                    modifier = Modifier.padding(horizontal = 16.dp),
                )
            }
            GoldWideButton("Neues Bag erstellen") { showAdd = true }
        }
    }

    if (showAdd) {
        TextInputDialog("Neues Bag", "z. B. Turnier-Bag", "", "Erstellen", { showAdd = false }) { name ->
            if (name.isNotEmpty()) {
                Haptics.success()
                GolfStore.upsertBag(GolfBag(name = name))
            }
            showAdd = false
        }
    }
    renaming?.let { bag ->
        TextInputDialog("Bag umbenennen", "Name", bag.name, "Speichern", { renaming = null }) { name ->
            Haptics.success()
            if (name.isNotEmpty()) updateBag(bag.id) { it.copy(name = name) }
            renaming = null
        }
    }
}

@Composable
internal fun GoldWideButton(text: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(AppTheme.gold)
            .clickable { Haptics.tap(); onClick() }.padding(vertical = 15.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.AddCircle, null, tint = AppTheme.onGold, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(8.dp))
        Text(text, color = AppTheme.onGold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
    }
}

/** Ein Bag wie `ClubBagView`. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ClubBagScreen(nav: NavController, bagId: String) {
    val data by GolfStore.data.collectAsState()
    val unitRaw by rememberPrefString("distanceUnit", DistanceUnit.METERS.raw)
    val unit = DistanceUnit.fromRaw(unitRaw)
    val bag = data.bag(bagId)
    var detailClubId by remember { mutableStateOf<String?>(null) }
    var menuFor by remember { mutableStateOf<String?>(null) }

    AppScaffold(bag?.name ?: "Bag", onBack = { nav.popBackStack() }) { m ->
        if (bag == null) return@AppScaffold
        val clubs = bag.sortedClubs
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            if (clubs.isEmpty()) {
                Column(
                    Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Icon(Icons.Filled.SportsGolf, null, tint = AppTheme.textTer, modifier = Modifier.size(40.dp))
                    Text("Keine Schläger", color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    Text("Füge deine Schläger zu diesem Bag hinzu.", color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.Center)
                }
            } else {
                val measured = clubs.count { it.hasUserData }
                if (measured > 0) {
                    Row(
                        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.BarChart, null, tint = AppTheme.gold, modifier = Modifier.size(24.dp))
                        Spacer(Modifier.width(12.dp))
                        Column {
                            Text("$measured von ${clubs.size} Schlägern gemessen", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                            Text("Tippe auf einen Schläger für Details & Verlauf", color = AppTheme.textSec, fontSize = 12.sp)
                        }
                    }
                }
                GroupCard {
                    clubs.forEachIndexed { i, club ->
                        Box {
                            ClubRow(club, unit, Modifier.combinedClickable(
                                onClick = { Haptics.tap(); detailClubId = club.id },
                                onLongClick = { Haptics.medium(); menuFor = club.id },
                            ))
                            DropdownMenu(expanded = menuFor == club.id, onDismissRequest = { menuFor = null }, containerColor = AppTheme.cardAlt) {
                                DropdownMenuItem(
                                    text = { Text("Löschen", color = iosRed) },
                                    leadingIcon = { Icon(Icons.Filled.Delete, null, tint = iosRed) },
                                    onClick = {
                                        Haptics.warning(); menuFor = null
                                        updateBag(bagId) { b -> b.copy(clubs = b.clubs.filter { it.id != club.id }) }
                                    },
                                )
                            }
                        }
                        if (i < clubs.lastIndex) RowDivider(56.dp)
                    }
                }
            }
            GoldWideButton("Schläger hinzufügen") { nav.navigate(ProfileExtraRoutes.addClub(bagId)) }
        }
    }

    val club = bag?.clubs?.firstOrNull { it.id == detailClubId }
    if (bag != null && club != null) ClubDetailSheet(bag.id, club, unit) { detailClubId = null }
}

@Composable
private fun ClubRow(club: GolfClub, unit: DistanceUnit, modifier: Modifier) {
    Row(modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
        val bg = if (club.isPutter) Color(0xFF0A84FF).copy(alpha = 0.18f) else if (club.hasUserData) AppTheme.gold.copy(alpha = 0.2f) else AppTheme.cardAlt
        val fg = if (club.isPutter) Color(0xFF0A84FF) else if (club.hasUserData) AppTheme.gold else AppTheme.textSec
        Box(Modifier.size(36.dp).background(bg, RoundedCornerShape(8.dp)), contentAlignment = Alignment.Center) {
            Icon(if (club.isPutter) Icons.Filled.Flag else Icons.Filled.SportsGolf, null, tint = fg, modifier = Modifier.size(16.dp))
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(club.name, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                if (club.isPutter) {
                    Spacer(Modifier.width(6.dp))
                    Text(
                        "PUTTER", color = Color(0xFF0A84FF), fontSize = 9.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp,
                        modifier = Modifier.background(Color(0xFF0A84FF).copy(alpha = 0.15f), CircleShape).padding(horizontal = 5.dp, vertical = 2.dp),
                    )
                }
            }
            if (club.hasUserData) {
                Text(if (club.shotCount == 1) "Ø aus 1 Messung" else "Ø aus ${club.shotCount} Messungen", color = AppTheme.gold, fontSize = 12.sp)
            } else {
                Text("Voreinstellung", color = AppTheme.textTer, fontSize = 12.sp)
            }
        }
        Column(horizontalAlignment = Alignment.End) {
            Text(unit.format(club.averageDistance.toDouble()), color = if (club.hasUserData) AppTheme.gold else AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            if (club.hasUserData && club.shotCount >= 2) {
                Text(
                    "${unit.value(club.minDistance.toDouble())}–${unit.value(club.maxDistance.toDouble())} ${unit.unitLabel}",
                    color = AppTheme.textTer, fontSize = 10.sp,
                )
            }
        }
        Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(16.dp))
    }
}

/** Wie `ClubDetailSheet`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ClubDetailSheet(bagId: String, club: GolfClub, unit: DistanceUnit, onDone: () -> Unit) {
    var confirmReset by remember { mutableStateOf(false) }
    ModalBottomSheet(onDismissRequest = onDone, containerColor = AppTheme.bg, sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)) {
        Column(Modifier.navigationBarsPadding().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).padding(bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                TextButton(onClick = { Haptics.tap(); onDone() }) { Text("Fertig", color = AppTheme.gold) }
                Text(club.name, color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
                if (club.hasUserData) {
                    TextButton(onClick = { Haptics.tap(); confirmReset = true }) { Text("Zurücksetzen", color = iosRed, fontSize = 12.sp) }
                } else Spacer(Modifier.width(80.dp))
            }
            // Durchschnitt
            Column(
                Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                Text(if (club.hasUserData) "DEIN DURCHSCHNITT" else "VOREINSTELLUNG", color = AppTheme.textTer, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.sp)
                Text(unit.format(club.averageDistance.toDouble()), color = if (club.hasUserData) AppTheme.gold else AppTheme.textSec, fontSize = 52.sp, fontWeight = FontWeight.Bold)
                if (club.hasUserData) {
                    Text(if (club.shotCount == 1) "aus 1 Messung" else "aus ${club.shotCount} Messungen", color = AppTheme.textSec, fontSize = 15.sp)
                    if (club.shotCount >= 2) {
                        Row(Modifier.padding(top = 4.dp), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("Min", color = AppTheme.textTer, fontSize = 12.sp)
                                Text(unit.format(club.minDistance.toDouble()), color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                            }
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("Max", color = AppTheme.textTer, fontSize = 12.sp)
                                Text(unit.format(club.maxDistance.toDouble()), color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                } else {
                    Text("Noch keine eigenen Messungen", color = AppTheme.textTer, fontSize = 12.sp)
                    Text("Schläge werden automatisch beim Aufzeichnen eingetragen.", color = AppTheme.textTer, fontSize = 12.sp, textAlign = TextAlign.Center)
                }
            }
            // Putter
            Row(
                Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                IconBadge(Icons.Filled.Flag, Color(0xFF0A84FF), circle = true)
                Spacer(Modifier.width(14.dp))
                Column(Modifier.weight(1f)) {
                    Text("Ist ein Putter", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Text("Putts werden beim Schlag automatisch hochgezählt", color = AppTheme.textSec, fontSize = 12.sp)
                }
                GoldSwitch(club.isPutter) { v -> updateClub(bagId, club.id) { it.copy(isPutter = v) } }
            }
            if (!club.hasUserData) {
                Column(
                    Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Text("VOREINSTELLUNG ANPASSEN", color = AppTheme.textTer, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.sp)
                    DistanceStepper(unit.format(club.defaultDistance.toDouble()), club.defaultDistance > 5, club.defaultDistance < 400,
                        onDec = { updateClub(bagId, club.id) { it.copy(defaultDistance = it.defaultDistance - 5) } },
                        onInc = { updateClub(bagId, club.id) { it.copy(defaultDistance = it.defaultDistance + 5) } },
                    )
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text("ALLE MESSUNGEN", color = AppTheme.textTer, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.sp, modifier = Modifier.padding(horizontal = 4.dp))
                    Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))) {
                        val list = club.measuredDistances
                        list.indices.reversed().forEach { i ->
                            Row(Modifier.padding(horizontal = 16.dp, vertical = 11.dp)) {
                                Text("Messung ${i + 1}", color = AppTheme.textSec, fontSize = 15.sp, modifier = Modifier.weight(1f))
                                Text(unit.format(list[i]), color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                            }
                            if (i > 0) HorizontalDivider(Modifier.padding(start = 16.dp), color = AppTheme.cardAlt)
                        }
                    }
                }
            }
        }
    }
    if (confirmReset) {
        AlertDialog(
            onDismissRequest = { confirmReset = false },
            containerColor = AppTheme.card,
            title = { Text("Alle ${club.shotCount} Messungen löschen?", color = AppTheme.text) },
            text = { Text("Der Durchschnitt wird auf die Voreinstellung (${club.defaultDistance} m) zurückgesetzt.", color = AppTheme.textSec) },
            confirmButton = {
                TextButton(onClick = {
                    Haptics.warning(); confirmReset = false
                    updateClub(bagId, club.id) { it.copy(measuredDistances = emptyList()) }
                }) { Text("Messungen löschen", color = iosRed) }
            },
            dismissButton = { TextButton(onClick = { Haptics.tap(); confirmReset = false }) { Text("Abbrechen", color = AppTheme.gold) } },
        )
    }
}

@Composable
private fun DistanceStepper(label: String, canDec: Boolean, canInc: Boolean, onDec: () -> Unit, onInc: () -> Unit, color: Color = AppTheme.text) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
        Icon(
            Icons.Filled.RemoveCircle, "Weniger", tint = if (canDec) AppTheme.gold else AppTheme.textTer,
            modifier = Modifier.size(36.dp).clip(CircleShape).clickable(enabled = canDec) { Haptics.selection(); onDec() },
        )
        Text(label, color = color, fontSize = 28.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center, modifier = Modifier.widthIn(min = 110.dp))
        Icon(
            Icons.Filled.AddCircle, "Mehr", tint = if (canInc) AppTheme.gold else AppTheme.textTer,
            modifier = Modifier.size(36.dp).clip(CircleShape).clickable(enabled = canInc) { Haptics.stroke(); onInc() },
        )
    }
}

private val categories: List<Pair<String, List<Triple<String, Int, Boolean>>>> = listOf(
    "Hölzer" to listOf(Triple("Driver", 220, false), Triple("3 Wood", 195, false), Triple("5 Wood", 180, false), Triple("7 Wood", 165, false)),
    "Hybride" to listOf(Triple("2 Hybrid", 195, false), Triple("3 Hybrid", 185, false), Triple("4 Hybrid", 175, false), Triple("5 Hybrid", 165, false)),
    "Eisen" to listOf(
        Triple("2 Eisen", 200, false), Triple("3 Eisen", 185, false), Triple("4 Eisen", 175, false), Triple("5 Eisen", 165, false),
        Triple("6 Eisen", 155, false), Triple("7 Eisen", 145, false), Triple("8 Eisen", 130, false), Triple("9 Eisen", 120, false),
    ),
    "Wedges" to listOf(
        Triple("PW", 110, false), Triple("GW", 95, false), Triple("AW", 90, false), Triple("52°", 88, false), Triple("SW", 80, false),
        Triple("54°", 83, false), Triple("56°", 78, false), Triple("58°", 68, false), Triple("LW", 60, false), Triple("60°", 55, false),
    ),
    "Putter" to listOf(Triple("Putter", 10, true)),
)

/** Wie `AddClubSheet` – als eigene Seite. */
@Composable
fun AddClubScreen(nav: NavController, bagId: String) {
    val data by GolfStore.data.collectAsState()
    val bag = data.bag(bagId)
    val existing = bag?.clubs?.map { it.name }?.toSet() ?: emptySet()
    var showCustom by remember { mutableStateOf(false) }
    var customName by remember { mutableStateOf("") }
    var customDist by remember { mutableIntStateOf(150) }
    var customPutter by remember { mutableStateOf(false) }

    fun add(name: String, dist: Int, putter: Boolean) = updateBag(bagId) { b ->
        b.copy(clubs = b.clubs + GolfClub(name = name, defaultDistance = dist, order = b.clubs.size, isPutter = putter))
    }

    AppScaffold("Schläger hinzufügen", onBack = { nav.popBackStack() }, actions = {
        TextButton(onClick = { Haptics.tap(); nav.popBackStack() }) { Text("Fertig", color = AppTheme.gold, fontWeight = FontWeight.SemiBold) }
    }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                CategoryTitle("Eigener Schläger")
                Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))) {
                    Row(
                        Modifier.fillMaxWidth().clickable { Haptics.tap(); showCustom = !showCustom }.padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(Modifier.size(34.dp).background(AppTheme.cardAlt, RoundedCornerShape(8.dp)), contentAlignment = Alignment.Center) {
                            Icon(if (showCustom) Icons.Filled.Remove else Icons.Filled.Add, null, tint = AppTheme.textSec, modifier = Modifier.size(16.dp))
                        }
                        Spacer(Modifier.width(14.dp))
                        Text("Schläger manuell eingeben", color = AppTheme.textSec, fontSize = 15.sp)
                    }
                    AnimatedVisibility(showCustom) {
                        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                            HorizontalDivider(color = AppTheme.cardAlt)
                            OutlinedTextField(
                                customName, { customName = it }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                                placeholder = { Text("Name", color = AppTheme.textTer) }, colors = fieldColors(),
                            )
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                IconBadge(Icons.Filled.Flag, Color(0xFF0A84FF), 34.dp, circle = true)
                                Spacer(Modifier.width(14.dp))
                                Text("Ist ein Putter", color = AppTheme.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
                                GoldSwitch(customPutter) { customPutter = it }
                            }
                            if (!customPutter) {
                                DistanceStepper("$customDist m", customDist > 5, customDist < 400,
                                    onDec = { customDist -= 5 }, onInc = { customDist += 5 }, color = AppTheme.gold)
                            }
                            val ok = customName.isNotBlank()
                            Box(
                                Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                                    .background(if (ok) AppTheme.gold else AppTheme.gold.copy(alpha = 0.4f))
                                    .clickable(enabled = ok) {
                                        Haptics.success()
                                        add(customName.trim(), if (customPutter) 10 else customDist, customPutter)
                                        customName = ""; customPutter = false; customDist = 150; showCustom = false
                                    }
                                    .padding(vertical = 14.dp),
                                contentAlignment = Alignment.Center,
                            ) { Text("Hinzufügen", color = AppTheme.onGold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold) }
                        }
                    }
                }
            }
            categories.forEach { (title, clubs) ->
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    CategoryTitle(title)
                    Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))) {
                        clubs.forEachIndexed { i, (name, dist, putter) ->
                            val added = name in existing
                            Row(
                                Modifier.fillMaxWidth().alpha(if (added) 0.5f else 1f).padding(horizontal = 14.dp, vertical = 11.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                val c = if (putter) Color(0xFF0A84FF) else AppTheme.gold
                                Box(Modifier.size(34.dp).background(c.copy(alpha = if (putter) 0.15f else 0.12f), RoundedCornerShape(8.dp)), contentAlignment = Alignment.Center) {
                                    Icon(if (putter) Icons.Filled.Flag else Icons.Filled.SportsGolf, null, tint = c, modifier = Modifier.size(15.dp))
                                }
                                Spacer(Modifier.width(14.dp))
                                Column(Modifier.weight(1f)) {
                                    Text(name, color = if (added) AppTheme.textTer else AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                                    Text(if (putter) "Putter · Auto-Putts" else "Ø $dist m", color = AppTheme.textTer, fontSize = 12.sp)
                                }
                                if (added) {
                                    Icon(Icons.Filled.CheckCircle, null, tint = iosGreen.copy(alpha = 0.6f), modifier = Modifier.size(24.dp))
                                } else {
                                    Icon(
                                        Icons.Filled.AddCircle, "Hinzufügen", tint = AppTheme.gold,
                                        modifier = Modifier.size(26.dp).clip(CircleShape).clickable { Haptics.success(); add(name, dist, putter) },
                                    )
                                }
                            }
                            if (i < clubs.lastIndex) RowDivider(62.dp)
                        }
                    }
                }
            }
            Spacer(Modifier.height(20.dp))
        }
    }
}

@Composable
private fun CategoryTitle(t: String) {
    Text(t.uppercase(), color = AppTheme.textTer, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.5.sp, modifier = Modifier.padding(start = 4.dp))
}
