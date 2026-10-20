package app.golftrack.feature.profile

import android.graphics.Bitmap
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.OutlinedFlag
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.AppFocus
import app.golftrack.data.DistanceUnit
import app.golftrack.data.GolfData
import app.golftrack.data.GolfStore
import app.golftrack.data.HandicapCalculator
import app.golftrack.data.rememberPrefBool
import app.golftrack.data.rememberPrefString
import app.golftrack.feature.minigolf.MinigolfRoutes
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LaterBadge
import app.golftrack.ui.common.LaterFeature
import app.golftrack.ui.common.Routes
import app.golftrack.ui.onboarding.LaunchKeys
import app.golftrack.ui.onboarding.LaunchOverlays
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.Locale

private fun golferTitle(completed: List<app.golftrack.data.Round>): String {
    val rounds = completed.size
    val best = completed.map { it.totalStrokes }.filter { it > 0 }.minOrNull() ?: 999
    return when (rounds) {
        0 -> "Einsteiger"
        in 1..4 -> "Anfänger"
        in 5..14 -> "Amateur"
        in 15..29 -> if (best <= 90) "Fortgeschrittener" else "Regelmäßiger Golfer"
        in 30..59 -> if (best <= 85) "Clubspieler" else "Fortgeschrittener"
        in 60..99 -> if (best <= 80) "Singlestelliger Golfer" else "Erfahrener Clubspieler"
        else -> when {
            best <= 72 -> "Profi-Niveau"
            best <= 76 -> "Scratch Golfer"
            best <= 80 -> "Singlestelliger Golfer"
            else -> "Veteran"
        }
    }
}

/** Profil-Tab wie ProfileView.swift. */
@Composable
fun ProfileScreen(nav: NavController) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val data by GolfStore.data.collectAsState()
    var playerName by rememberPrefString("playerName", "Golfer")
    var editing by remember { mutableStateOf(false) }
    var draft by remember { mutableStateOf("") }
    var profileImage by remember { mutableStateOf<Bitmap?>(null) }
    var toCrop by remember { mutableStateOf<Bitmap?>(null) }
    val completed = data.completedRounds

    LaunchedEffect(Unit) { profileImage = withContext(Dispatchers.IO) { ProfileImageStore.load(ctx) } }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) scope.launch { toCrop = withContext(Dispatchers.IO) { ImageTools.decode(ctx, uri) } }
    }

    Box(Modifier.fillMaxSize().background(AppTheme.bg)) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(top = 4.dp, bottom = 30.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Text(
                "Profil", color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold,
                modifier = Modifier.padding(horizontal = 16.dp).padding(top = 16.dp),
            )
            // Avatar + Name
            Column(
                Modifier.padding(horizontal = 16.dp).fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Box(Modifier.clickable {
                    Haptics.tap()
                    picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }) {
                    Box(Modifier.size(88.dp).clip(CircleShape).background(AppTheme.gold.copy(alpha = 0.2f)), contentAlignment = Alignment.Center) {
                        val img = profileImage
                        if (img != null) Image(img.asImageBitmap(), null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                        else Text(playerName.take(1).uppercase(), color = AppTheme.gold, fontSize = 38.sp, fontWeight = FontWeight.Bold)
                    }
                    Box(
                        Modifier.align(Alignment.BottomEnd).offset(4.dp, 4.dp).size(28.dp).background(AppTheme.gold, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) { Icon(Icons.Filled.CameraAlt, null, tint = Color(0xFF1A3821), modifier = Modifier.size(14.dp)) }
                }
                if (editing) {
                    val save = {
                        Haptics.success()
                        if (draft.isNotBlank()) playerName = draft.trim()
                        editing = false
                    }
                    Row(Modifier.padding(horizontal = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                        BasicTextField(
                            draft, { draft = it }, singleLine = true,
                            textStyle = TextStyle(color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center),
                            cursorBrush = SolidColor(AppTheme.gold),
                            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                            keyboardActions = KeyboardActions(onDone = { save() }),
                            modifier = Modifier.weight(1f).background(AppTheme.card, RoundedCornerShape(10.dp))
                                .border(1.5.dp, AppTheme.gold, RoundedCornerShape(10.dp)).padding(horizontal = 12.dp, vertical = 8.dp),
                        )
                        Spacer(Modifier.width(8.dp))
                        Icon(Icons.Filled.CheckCircle, "Speichern", tint = AppTheme.gold, modifier = Modifier.size(28.dp).clip(CircleShape).clickable { save() })
                    }
                } else {
                    Row(
                        Modifier.clip(RoundedCornerShape(8.dp)).clickable { Haptics.tap(); draft = playerName; editing = true },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(playerName, color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                        Spacer(Modifier.width(6.dp))
                        Icon(Icons.Filled.Edit, null, tint = AppTheme.textSec, modifier = Modifier.size(14.dp))
                    }
                }
                Text(golferTitle(completed), color = AppTheme.textSec, fontSize = 15.sp)
            }

            // Kennzahlen
            Row(Modifier.padding(horizontal = 16.dp).height(IntrinsicSize.Min), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                val best = completed.mapNotNull { r -> r.totalStrokes.takeIf { it > 0 } }.minOrNull()?.toString() ?: "–"
                val putts = completed.filter { it.totalPutts > 0 }.map { it.totalPutts }
                val avgPutts = if (putts.isEmpty()) "–" else String.format(Locale.GERMANY, "%.0f", putts.average())
                StatBox("${completed.size}", "Runden", Modifier.weight(1f))
                StatBox(best, "Bestleistung", Modifier.weight(1f))
                StatBox(avgPutts, "Ø Putts", Modifier.weight(1f))
            }

            Box(Modifier.padding(horizontal = 16.dp)) { HandicapCard(data) }
            Box(Modifier.padding(horizontal = 16.dp)) { DocumentsCard(nav, limit = 4) }
            Box(Modifier.padding(horizontal = 16.dp)) { AchievementsCard(data) }
            Box(Modifier.padding(horizontal = 16.dp)) { SettingsSection(nav) }
        }
        LaunchOverlays(nav)
    }

    toCrop?.let { img ->
        ImageCropDialog(img, onCancel = { toCrop = null }) { cropped ->
            profileImage = cropped
            toCrop = null
            scope.launch(Dispatchers.IO) { ProfileImageStore.save(ctx, cropped) }
        }
    }
}

@Composable
private fun StatBox(value: String, label: String, modifier: Modifier) {
    Column(
        modifier.fillMaxHeight().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(value, color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text(label, color = AppTheme.textSec, fontSize = 12.sp)
    }
}

@Composable
private fun HandicapCard(data: GolfData) {
    val completed = data.completedRounds
    val info = HandicapCalculator.progressInfo(completed, data)
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text("Handicap Index", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                Text("World Handicap System (WHS)", color = AppTheme.textSec, fontSize = 12.sp)
            }
            Icon(Icons.Filled.EmojiEvents, null, tint = AppTheme.gold)
        }
        HorizontalDivider(color = AppTheme.cardAlt)
        if (info != null) {
            Row(verticalAlignment = Alignment.Bottom) {
                Text(String.format(Locale.GERMANY, "%.1f", info.handicapIndex), color = AppTheme.gold, fontSize = 42.sp, fontWeight = FontWeight.Bold)
                Spacer(Modifier.width(6.dp))
                Text("HCP", color = AppTheme.textSec, fontSize = 20.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 8.dp))
                Spacer(Modifier.weight(1f))
                Column(horizontalAlignment = Alignment.End, modifier = Modifier.padding(bottom = 8.dp)) {
                    Text("Beste ${info.usedRounds} von ${info.eligibleRounds}", color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    info.bestDifferentials.minOrNull()?.let {
                        Text("Bestes Diff.: ${String.format(Locale.GERMANY, "%.1f", it)}", color = AppTheme.textTer, fontSize = 12.sp)
                    }
                }
            }
            Row(Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(8.dp)).padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Info, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                Spacer(Modifier.width(8.dp))
                Text("Durchschnitt der ${info.usedRounds} besten Score-Differentials × 0,96", color = AppTheme.textSec, fontSize = 12.sp)
            }
            if (info.allDifferentials.isNotEmpty()) {
                val best = info.allDifferentials.withIndex().sortedBy { it.value }.take(info.usedRounds).map { it.index }.toSet()
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Score Differentials (letzte Runden)", color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    info.allDifferentials.withIndex().chunked(5).forEach { row ->
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            row.forEach { (i, d) ->
                                val used = i in best
                                Text(
                                    String.format(Locale.GERMANY, "%.1f", d),
                                    color = if (used) AppTheme.gold else AppTheme.textTer, fontSize = 12.sp,
                                    fontWeight = if (used) FontWeight.Bold else FontWeight.Normal, textAlign = TextAlign.Center,
                                    modifier = Modifier.weight(1f).background(if (used) AppTheme.gold.copy(alpha = 0.15f) else AppTheme.cardAlt, RoundedCornerShape(6.dp)).padding(vertical = 6.dp),
                                )
                            }
                            repeat(5 - row.size) { Spacer(Modifier.weight(1f)) }
                        }
                    }
                }
            }
        } else {
            Column(Modifier.fillMaxWidth().padding(vertical = 10.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Icon(Icons.Filled.OutlinedFlag, null, tint = AppTheme.textTer, modifier = Modifier.size(30.dp))
                Text("Noch nicht genug Daten", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                val missing = maxOf(0, 3 - completed.size)
                Text(
                    when {
                        missing <= 0 -> "Für einen vollständigen Index werden Runden mit Course-Rating & Slope-Rating benötigt."
                        missing == 1 -> "Spiele noch 1 Runde, um einen Handicap-Index zu erhalten."
                        else -> "Spiele noch $missing Runden, um einen Handicap-Index zu erhalten."
                    },
                    color = AppTheme.textTer, fontSize = 12.sp, textAlign = TextAlign.Center,
                )
            }
        }
    }
}

@Composable
private fun SettingsSection(nav: NavController) {
    var focus by rememberPrefString("appFocus", AppFocus.GOLF.raw)
    var unit by rememberPrefString("distanceUnit", DistanceUnit.METERS.raw)
    var intro by rememberPrefBool(LaunchKeys.SHOW_INTRO)
    var hasSeenOnboarding by rememberPrefBool(LaunchKeys.HAS_SEEN_ONBOARDING)
    val blue = Color(0xFF4DB3FF)

    GroupCard {
        Row(Modifier.padding(horizontal = 18.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            IconBadge(Icons.Filled.TrackChanges, AppTheme.gold)
            Spacer(Modifier.width(14.dp))
            Text("Schwerpunkt", color = AppTheme.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
            Segmented(listOf(AppFocus.GOLF.raw to "Golf", AppFocus.MINIGOLF.raw to "Minigolf"), focus, Modifier.width(170.dp)) { focus = it }
        }
        RowDivider()
        Row(Modifier.padding(horizontal = 18.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            IconBadge(Icons.Filled.Straighten, blue)
            Spacer(Modifier.width(14.dp))
            Text("Distanzeinheit", color = AppTheme.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
            Segmented(listOf(DistanceUnit.METERS.raw to "Meter", DistanceUnit.YARDS.raw to "Yards"), DistanceUnit.fromRaw(unit).raw, Modifier.width(160.dp)) { unit = it }
        }
        RowDivider()
        Row(Modifier.padding(horizontal = 18.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            IconBadge(Icons.Filled.AutoAwesome, AppTheme.gold)
            Spacer(Modifier.width(14.dp))
            Text("Intro beim Start", color = AppTheme.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
            GoldSwitch(intro) { intro = it }
        }
        RowDivider()
        NavRow(Icons.Filled.ShoppingBag, AppTheme.gold, "Schläger-Bags") { nav.navigate(Routes.CLUB_BAG) }
        RowDivider()
        NavRow(Icons.Filled.Place, AppTheme.gold, "Golfplätze verwalten") { nav.navigate(Routes.COURSES) }
        RowDivider()
        NavRow(Icons.AutoMirrored.Filled.DirectionsWalk, Color(0xFF66CCE6), "Positions-Tracking") { nav.navigate(ProfileExtraRoutes.TRACKING) }
        RowDivider()
        NavRow(Icons.Filled.SportsGolf, Color(0xFF4DD980), "Minigolf") { nav.navigate(Routes.MINIGOLF) }
        RowDivider()
        NavRow(Icons.Filled.GpsFixed, blue, "Distanz & Karte") { nav.navigate(MinigolfRoutes.TOOLS) }
        RowDivider()
        NavRow(Icons.Filled.NotificationsActive, Color(0xFFFFBF33), "Benachrichtigungen") { nav.navigate(ProfileExtraRoutes.NOTIFICATIONS) }
        RowDivider()
        NavRow(Icons.Filled.Settings, Color(0xFF9980FF), "Einstellungen") { nav.navigate(Routes.SETTINGS) }
        RowDivider()
        NavRow(Icons.Filled.Help, Color(0xFFFF994D), "Hilfe & Anleitung") { nav.navigate(Routes.HELP) }
        RowDivider()
        NavRow(Icons.Filled.Headphones, AppTheme.gold, "Training & Audiobooks", trailing = {
            LaterBadge()
            Spacer(Modifier.width(6.dp))
            Chevron()
        }) { nav.navigate(Routes.comingLater(LaterFeature.AUDIOBOOKS)) }
        RowDivider()
        NavRow(Icons.Filled.AutoAwesome, AppTheme.gold, "Was ist neu") { nav.navigate(LaunchKeys.WHATS_NEW_ROUTE) }
        RowDivider()
        NavRow(Icons.Filled.PlayCircle, AppTheme.gold, "Tutorial neu starten", trailing = {
            Icon(Icons.Filled.Refresh, null, tint = AppTheme.textTer, modifier = Modifier.size(16.dp))
        }) { hasSeenOnboarding = false }
    }
}
