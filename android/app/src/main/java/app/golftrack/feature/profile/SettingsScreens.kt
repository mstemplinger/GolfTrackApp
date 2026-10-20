package app.golftrack.feature.profile

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Help
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.PanTool
import androidx.compose.material.icons.filled.Percent
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.TouchApp
import androidx.compose.material.icons.filled.Vibration
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.WbCloudy
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material.icons.filled.Timeline
import androidx.compose.material.icons.filled.Looks3
import androidx.compose.material.icons.filled.Looks4
import androidx.compose.material.icons.filled.LooksOne
import androidx.compose.material.icons.filled.LooksTwo
import androidx.compose.material.icons.filled.Gavel
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.navigation.NavController
import app.golftrack.BuildConfig
import app.golftrack.data.GolfStore
import app.golftrack.data.Prefs
import app.golftrack.data.rememberPrefBool
import app.golftrack.data.rememberPrefInt
import app.golftrack.feature.home.HomeExtraRoutes
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.GoldButton
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LocationService
import app.golftrack.ui.common.Routes
import app.golftrack.ui.onboarding.LaunchKeys
import app.golftrack.ui.theme.AppTheme
import java.util.Locale

private fun openAppSettings(ctx: android.content.Context) {
    runCatching {
        ctx.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${ctx.packageName}")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }
}

/** Einstellungen wie SettingsView.swift (ohne API-Einstellungen – die gehören zum Caddy). */
@Composable
fun SettingsScreen(nav: NavController) {
    var haptics by rememberPrefBool(Haptics.ENABLED_KEY, true)
    AppScaffold("Einstellungen", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp)) {
            SectionHeader("Daten")
            GroupCard {
                ListRow(Icons.Filled.Place, "Golfplätze", onClick = { nav.navigate(Routes.COURSES) }, trailing = { Chevron() })
                RowDivider(52.dp)
                ListRow(Icons.AutoMirrored.Filled.DirectionsWalk, "Positions-Tracking", onClick = { nav.navigate(ProfileExtraRoutes.TRACKING) }, trailing = { Chevron() })
                RowDivider(52.dp)
                ListRow(Icons.Filled.WbCloudy, "Golf-Wetter", onClick = { nav.navigate(HomeExtraRoutes.WEATHER_SETTINGS) }, trailing = { Chevron() })
            }
            Spacer(Modifier.height(20.dp))
            SectionHeader("Bedienung")
            GroupCard {
                ListRow(Icons.Filled.Vibration, "Haptisches Feedback", trailing = {
                    GoldSwitch(haptics) { v ->
                        haptics = v
                        // Beim Einschalten sofort spürbar bestätigen.
                        if (v) Haptics.success()
                    }
                })
            }
            SectionFooter("Kurze Vibrationen bei Aktionen wie Schlagzählung, Lochwechsel und Rundenabschluss.")
            Spacer(Modifier.height(20.dp))
            SectionHeader("Hilfe & Rechtliches")
            GroupCard {
                ListRow(Icons.Filled.Help, "Hilfe & Anleitung", onClick = { nav.navigate(Routes.HELP) }, trailing = { Chevron() })
                RowDivider(52.dp)
                ListRow(Icons.Filled.PanTool, "Datenschutz", onClick = { nav.navigate(ProfileExtraRoutes.PRIVACY) }, trailing = { Chevron() })
                RowDivider(52.dp)
                ListRow(Icons.Filled.Description, "Impressum", onClick = { nav.navigate(ProfileExtraRoutes.IMPRINT) }, trailing = { Chevron() })
            }
            Spacer(Modifier.height(20.dp))
            SectionHeader("App-Info")
            GroupCard {
                InfoRow("Version", BuildConfig.VERSION_NAME)
                RowDivider(16.dp)
                InfoRow("Gebaut mit", "Kotlin & Jetpack Compose")
            }
        }
    }
}

@Composable
internal fun Chevron() = Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))

@Composable
private fun InfoRow(label: String, value: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 13.dp)) {
        Text(label, color = AppTheme.textSec, fontSize = 15.sp, modifier = Modifier.weight(1f))
        Text(value, color = AppTheme.textSec, fontSize = 15.sp)
    }
}

// --- Positions-Tracking (TrackingSettingsView.swift) ---

private const val TRACKING_KEY = "tracking.roundPath.enabled"

@Composable
fun TrackingSettingsScreen(nav: NavController) {
    val ctx = LocalContext.current
    val data by GolfStore.data.collectAsState()
    var enabled by rememberPrefBool(TRACKING_KEY)
    var confirmDelete by remember { mutableStateOf(false) }
    var hasPermission by remember { mutableStateOf(LocationService.hasPermission(ctx)) }
    LifecycleResumeEffect(Unit) {
        hasPermission = LocationService.hasPermission(ctx)
        onPauseOrDispose { }
    }
    val tracked = data.rounds.filter { it.track != null }
    val totalPoints = tracked.sumOf { it.track?.points?.size ?: 0 }
    // Etwa 40 Byte je Punkt (fünf Zahlen).
    val kb = totalPoints * 40 / 1024.0
    val coursesWithData = data.courses.filter { c -> tracked.any { it.courseId == c.id } }.sortedBy { it.name.lowercase() }

    AppScaffold("Positions-Tracking", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp)) {
            SectionHeader("Positions-Tracking")
            GroupCard {
                ListRow(title = "Laufspur aufzeichnen", subtitle = "Nur während einer laufenden Runde", trailing = { GoldSwitch(enabled) { enabled = it } })
            }
            SectionFooter("Während einer Runde wird alle paar Meter deine Position gespeichert. Daraus leitet die App Abschlag- und Grünpositionen der Löcher ab – so bekommst du die Entfernung zur Fahne ohne den Pin selbst zu setzen.\n\nDie Daten bleiben auf deinem Gerät und werden nicht übertragen. Du kannst sie jederzeit hier löschen.")

            if (enabled) {
                Spacer(Modifier.height(20.dp))
                SectionHeader("Status")
                GroupCard {
                    if (hasPermission) {
                        ListRow(Icons.Filled.CheckCircle, "Standortzugriff erlaubt", iconTint = AppTheme.green)
                    } else {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Filled.Warning, null, tint = iosOrange, modifier = Modifier.size(20.dp))
                                Spacer(Modifier.width(10.dp))
                                Text("Standortzugriff nicht erlaubt", color = iosOrange, fontSize = 15.sp)
                            }
                            Text("Ohne Standortzugriff kann keine Laufspur aufgezeichnet werden. Die App fragt beim Start der nächsten Runde danach.", color = AppTheme.textSec, fontSize = 12.sp)
                            Text(
                                "In den Android-Einstellungen öffnen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold,
                                modifier = Modifier.clickable { Haptics.tap(); openAppSettings(ctx) },
                            )
                        }
                    }
                }
                SectionFooter("Android zeichnet während der Runde weiter auf, solange GolfTrack geöffnet ist. Rechne mit etwas mehr Akkuverbrauch als ohne Tracking.")
            }

            if (coursesWithData.isNotEmpty()) {
                Spacer(Modifier.height(20.dp))
                SectionHeader("Loch-Positionen ableiten")
                GroupCard {
                    coursesWithData.forEachIndexed { i, c ->
                        val count = tracked.count { it.courseId == c.id }
                        ListRow(
                            title = c.name,
                            subtitle = "${c.holePositionCount}/${c.numberOfHoles} Löcher mit Position · Aufzeichnungen: $count",
                            trailing = { Chevron() },
                            onClick = { nav.navigate(Routes.courseEdit(c.id)) },
                        )
                        if (i < coursesWithData.lastIndex) RowDivider(16.dp)
                    }
                }
                SectionFooter("Ab etwa drei aufgezeichneten Runden pro Platz werden die Schätzungen deutlich stabiler.")
            }

            Spacer(Modifier.height(20.dp))
            SectionHeader("Gespeicherte Daten")
            GroupCard {
                InfoRow("Aufzeichnungen", "${tracked.size}")
                RowDivider(16.dp)
                InfoRow("GPS-Punkte", "$totalPoints")
                RowDivider(16.dp)
                InfoRow("Speicherbedarf", String.format(Locale.GERMANY, "%.1f KB", kb))
                if (tracked.isNotEmpty()) {
                    RowDivider(16.dp)
                    ListRow(Icons.Filled.Delete, "Alle Laufspuren löschen", iconTint = iosRed, onClick = { confirmDelete = true })
                }
            }
            SectionFooter("Das Löschen entfernt nur die Laufspuren. Runden, Scores und bereits übernommene Loch-Positionen bleiben erhalten.")
        }
    }
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            containerColor = AppTheme.card,
            title = { Text("Alle Laufspuren löschen?", color = AppTheme.text) },
            text = { Text("Alle gespeicherten Laufspuren werden endgültig entfernt ($totalPoints GPS-Punkte).", color = AppTheme.textSec) },
            confirmButton = {
                TextButton(onClick = {
                    Haptics.warning(); confirmDelete = false
                    GolfStore.update { d -> d.copy(rounds = d.rounds.map { it.copy(track = null) }) }
                }) { Text("Löschen", color = iosRed) }
            },
            dismissButton = { TextButton(onClick = { Haptics.tap(); confirmDelete = false }) { Text("Abbrechen", color = AppTheme.gold) } },
        )
    }
}

// --- Benachrichtigungen (NotificationSettingsView.swift) ---

@Composable
fun NotificationSettingsScreen(nav: NavController) {
    val ctx = LocalContext.current
    var inactivity by rememberPrefBool("notif.inactivity.enabled", true)
    var inactivityDays by rememberPrefInt("notif.inactivity.days", 5)
    var openRound by rememberPrefBool("notif.openRound.enabled", true)
    var roundInactivity by rememberPrefBool("notif.roundInactivity.enabled", true)
    var roundMinutes by rememberPrefInt("notif.roundInactivity.minutes", 45)
    var canPost by remember { mutableStateOf(Reminders.canPost(ctx)) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { canPost = it }
    LifecycleResumeEffect(Unit) {
        canPost = Reminders.canPost(ctx)
        onPauseOrDispose { }
    }
    LaunchedEffect(Unit) {
        if (!canPost && Build.VERSION.SDK_INT >= 33 && !Prefs.bool("notif.permissionAsked")) {
            Prefs.set("notif.permissionAsked", true)
            launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    AppScaffold("Benachrichtigungen", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            if (!canPost) {
                Row(
                    Modifier.fillMaxWidth().background(Color.Red.copy(alpha = 0.1f), RoundedCornerShape(14.dp)).padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.NotificationsOff, null, tint = iosRed, modifier = Modifier.size(24.dp))
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text("Benachrichtigungen gesperrt", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                        Text("Bitte in den Android-Einstellungen aktivieren.", color = AppTheme.textSec, fontSize = 12.sp)
                    }
                    Text("Öffnen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.clickable { Haptics.tap(); openAppSettings(ctx) })
                }
            }
            ToggleCard(Icons.Filled.NotificationsActive, AppTheme.gold, "Inaktivitätserinnerung", "Erinnert dich wenn du längere Zeit nicht gespielt hast", inactivity, {
                inactivity = it
                Reminders.rescheduleInactivity(ctx, inactivityDays)
            }) {
                PickerRow("Erinnerung nach", inactivityDays, listOf(3 to "3 Tagen", 5 to "5 Tagen", 7 to "7 Tagen", 14 to "14 Tagen")) {
                    inactivityDays = it
                    Reminders.rescheduleInactivity(ctx, it)
                }
            }
            ToggleCard(Icons.Filled.Flag, Color(0xFF4DD980), "Offene Runde", "Erinnert dich am nächsten Morgen an eine unfertige Runde", openRound, {
                openRound = it
                if (!it) Reminders.cancelOpenRound(ctx)
            })
            ToggleCard(Icons.Filled.Schedule, iosOrange, "Pause-Erinnerung", "Erinnert dich während einer Runde, wenn du längere Zeit nichts eingetragen hast", roundInactivity, { roundInactivity = it }) {
                PickerRow("Erinnerung nach", roundMinutes, listOf(20 to "20 Min.", 30 to "30 Min.", 45 to "45 Min.", 60 to "60 Min.")) { roundMinutes = it }
            }
            Text(
                "Benachrichtigungen werden nur als lokale Erinnerungen verschickt – keine Werbung, keine Server.",
                color = AppTheme.textTer, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 16.dp),
            )
        }
    }
}

@Composable
private fun ToggleCard(
    icon: ImageVector, color: Color, title: String, subtitle: String, checked: Boolean, onChange: (Boolean) -> Unit,
    extra: (@Composable () -> Unit)? = null,
) {
    GroupCard {
        Row(Modifier.padding(horizontal = 18.dp, vertical = 16.dp), verticalAlignment = Alignment.CenterVertically) {
            IconBadge(icon, color)
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(title, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                Text(subtitle, color = AppTheme.textSec, fontSize = 12.sp)
            }
            GoldSwitch(checked, onChange)
        }
        if (extra != null) {
            AnimatedVisibility(checked) {
                Column {
                    RowDivider()
                    extra()
                }
            }
        }
    }
}

@Composable
private fun PickerRow(label: String, value: Int, options: List<Pair<Int, String>>, onSelect: (Int) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Row(Modifier.fillMaxWidth().padding(start = 72.dp, end = 18.dp, top = 12.dp, bottom = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, color = AppTheme.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
        Box {
            Row(Modifier.clickable { Haptics.tap(); open = true }, verticalAlignment = Alignment.CenterVertically) {
                Text(options.firstOrNull { it.first == value }?.second ?: "$value", color = AppTheme.gold, fontSize = 15.sp)
                Icon(Icons.Filled.KeyboardArrowDown, null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
            }
            DropdownMenu(open, { open = false }, containerColor = AppTheme.cardAlt) {
                options.forEach { (v, l) ->
                    DropdownMenuItem(text = { Text(l, color = AppTheme.text) }, onClick = { Haptics.selection(); open = false; onSelect(v) })
                }
            }
        }
    }
}

// --- Hilfe (HelpView.swift) ---

private data class HelpItem(val icon: ImageVector, val color: Color, val title: String, val content: String)

private val helpSections: List<Triple<String, ImageVector, List<HelpItem>>> = listOf(
    Triple("Erste Schritte", Icons.Filled.Flag, listOf(
        HelpItem(Icons.Filled.LooksOne, AppTheme.gold, "Golfplatz hinzufügen", "Gehe zu Profil > Golfplätze verwalten und tippe auf '+'. Du kannst Plätze manuell anlegen oder aus dem Platzverzeichnis übernehmen."),
        HelpItem(Icons.Filled.LooksTwo, AppTheme.gold, "Neue Runde starten", "Tippe auf der Startseite auf 'Neue Runde spielen'. Wähle Platz, Datum und Spielmodus. Bei Mehrspieler-Modi kannst du direkt die Namen der Mitspieler eingeben. Dann auf 'Starten'."),
        HelpItem(Icons.Filled.Looks3, AppTheme.gold, "Scorecard ausfüllen", "Erfasse Schlag für Schlag deine Scores. Mit den Pfeilen navigierst du zwischen den Löchern. Wenn du fertig bist, tippe auf 'Abschließen'."),
        HelpItem(Icons.Filled.Looks4, AppTheme.gold, "Statistiken ansehen", "In der Statistik siehst du deine Entwicklung über alle Runden: Score-Verlauf, Fairway-Trefferquote, Grün in Regulierung und Putt-Durchschnitt."),
    )),
    Triple("Scorecard", Icons.Filled.Description, listOf(
        HelpItem(Icons.Filled.SportsGolf, AppTheme.gold, "Schläge & Putts", "Stelle mit + und - die Anzahl der Schläge und Putts pro Loch ein. GolfTrack berechnet automatisch Score vs. Par, Stableford-Punkte und Matchplay-Ergebnis."),
        HelpItem(Icons.Filled.CheckCircle, AppTheme.gold, "Fairway & GIR", "Fairway Hit: Hast du den Fairway beim Abschlag getroffen? GIR (Grün in Regulierung): Hast du das Grün in Par minus 2 Schlägen erreicht?"),
        HelpItem(Icons.Filled.Place, AppTheme.gold, "Schlag-Tracking auf der Karte", "Tippe auf das Karten-Symbol in der Scorecard, um deine Schläge auf einer Karte zu tracken. Setze Abschlag und Landepunkt per Tipp oder nutze 'Standort' für deine aktuelle GPS-Position."),
    )),
    Triple("Spielmodi", Icons.Filled.EmojiEvents, listOf(
        HelpItem(Icons.Filled.SportsGolf, iosOrange, "Zählspiel", "Die klassische Spielform. Jeder Schlag zählt. Wer am Ende die wenigsten Schläge hat, gewinnt."),
        HelpItem(Icons.Filled.Star, iosOrange, "Stableford", "Punkte statt Schläge: Albatross=5, Eagle=4, Birdie=3, Par=2, Bogey=1, Double+=0. Wer die meisten Punkte sammelt, gewinnt."),
        HelpItem(Icons.Filled.Groups, iosOrange, "Matchplay", "Loch für Loch gegen einen Gegner. Wer das Loch gewinnt, führt um einen Punkt. Wer mehr Löcher vorne hat als noch zu spielen sind, gewinnt (z. B. 3&2)."),
        HelpItem(Icons.Filled.EmojiEvents, iosOrange, "Skins", "Jedes Loch hat einen Skin. Wer das Loch mit dem niedrigsten Score gewinnt, erhält den Skin. Bei Gleichstand wird der Skin aufs nächste Loch übertragen (Carryover)."),
        HelpItem(Icons.Filled.Whatshot, iosOrange, "Better Ball", "Im 2er-Team: Der bessere Score pro Loch zählt für das Team, entweder im Zählspiel oder Stableford-Modus."),
        HelpItem(Icons.Filled.Groups, iosOrange, "2-Mann Scramble", "Beide Partner schlagen ab. Der beste Abschlag wird gewählt, beide spielen von dort weiter. Der gemeinsame Team-Score wird eingetragen."),
    )),
    Triple("Schlag-Tracking", Icons.Filled.Map, listOf(
        HelpItem(Icons.Filled.MyLocation, iosPurple, "GPS-Standort verwenden", "Tippe auf 'Standort' im Banner, um deinen aktuellen GPS-Standort als Abschlag oder Treffpunkt zu setzen. Stelle sicher, dass der Standortzugriff in den Android-Einstellungen für GolfTrack erlaubt ist."),
        HelpItem(Icons.Filled.TouchApp, iosPurple, "Karte antippen", "Tippe direkt auf die Karte, um Abschlag (blau) und Treffpunkt (orange) zu platzieren. GolfTrack berechnet die Distanz automatisch in Metern und Yards."),
        HelpItem(Icons.AutoMirrored.Filled.Undo, iosPurple, "Rückgängig", "Der Zurück-Button macht schrittweise rückgängig: zuerst den Treffpunkt, dann den Abschlag, dann den letzten gespeicherten Schlag."),
    )),
    Triple("Statistiken", Icons.Filled.BarChart, listOf(
        HelpItem(Icons.Filled.ShowChart, iosTeal, "Score-Verlauf", "Zeigt deinen Score vs. Par über alle abgeschlossenen Runden als Liniendiagramm. Ein fallender Wert bedeutet Verbesserung."),
        HelpItem(Icons.Filled.Percent, iosTeal, "Fairway & GIR", "Prozentualer Anteil der getroffenen Fairways und Grüns in Regulierung. Hohe GIR-Werte sind ein Zeichen für gutes Kurzspiel."),
        HelpItem(Icons.Filled.SportsGolf, iosTeal, "Putt-Durchschnitt", "Durchschnittliche Putt-Anzahl pro Loch über alle Runden. Der Benchmark für gute Spieler liegt bei 1,7-1,8 Putts pro Loch."),
    )),
)

@Composable
fun HelpScreen(nav: NavController) {
    AppScaffold("Hilfe & Anleitung", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp)) {
            helpSections.forEach { (title, icon, items) ->
                Row(Modifier.padding(start = 16.dp, top = 12.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(icon, null, tint = AppTheme.textSec, modifier = Modifier.size(14.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(title.uppercase(), color = AppTheme.textSec, fontSize = 12.sp, letterSpacing = 0.5.sp)
                }
                GroupCard {
                    items.forEachIndexed { i, item ->
                        HelpRow(item)
                        if (i < items.lastIndex) RowDivider(56.dp)
                    }
                }
                Spacer(Modifier.height(12.dp))
            }
            Row(Modifier.padding(start = 16.dp, top = 12.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Gavel, null, tint = AppTheme.textSec, modifier = Modifier.size(14.dp))
                Spacer(Modifier.width(6.dp))
                Text("RECHTLICHES", color = AppTheme.textSec, fontSize = 12.sp, letterSpacing = 0.5.sp)
            }
            GroupCard {
                ListRow(title = "Datenschutz", trailing = { Chevron() }, onClick = { nav.navigate(ProfileExtraRoutes.PRIVACY) })
                RowDivider(16.dp)
                ListRow(title = "Impressum", trailing = { Chevron() }, onClick = { nav.navigate(ProfileExtraRoutes.IMPRINT) })
            }
        }
    }
}

@Composable
private fun HelpRow(item: HelpItem) {
    var expanded by remember { mutableStateOf(false) }
    Column(Modifier.fillMaxWidth().clickable { Haptics.tap(); expanded = !expanded }.padding(horizontal = 16.dp, vertical = 12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(item.icon, null, tint = item.color, modifier = Modifier.size(24.dp))
            Spacer(Modifier.width(12.dp))
            Text(item.title, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            Icon(if (expanded) Icons.Filled.KeyboardArrowUp else Icons.Filled.KeyboardArrowDown, null, tint = AppTheme.textSec, modifier = Modifier.size(18.dp))
        }
        AnimatedVisibility(expanded) {
            Text(item.content, color = AppTheme.textSec, fontSize = 15.sp, modifier = Modifier.padding(top = 8.dp, start = 36.dp))
        }
    }
}

// --- Datenschutz & Impressum ---

@Composable
fun PrivacyScreen(nav: NavController) {
    AppScaffold("Datenschutz", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            LegalBlock("Datenschutz auf einen Blick", listOf("GolfTrack speichert deine Daten (Runden, Scores, Statistiken) lokal auf deinem Gerät. Es werden keine Analyse- oder Tracking-Dienste eingesetzt. Einzelne Funktionen nutzen externe Dienste (Platzverzeichnis, Wetter, Anzeigen) — dabei werden nur die unten beschriebenen Daten übertragen, und nur wenn du die jeweilige Funktion aktiv verwendest."))
            LegalBlock("Gespeicherte Daten", listOf("Die App speichert deine Runden, Scores, Golfplätze und Schlag-Tracking-Daten ausschließlich im lokalen App-Speicher deines Geräts. Diese Daten verlassen dein Gerät nicht."))
            LegalBlock("Standortzugriff", listOf("GolfTrack kann deinen GPS-Standort für das Schlag-Tracking auf der Karte verwenden. Der Standortzugriff erfolgt nur während der App-Nutzung und die Koordinaten werden ausschließlich lokal auf deinem Gerät gespeichert."))
            LegalBlock("Wetterdaten (Open-Meteo)", listOf("Für die Wetteranzeige werden die ungefähren Koordinaten deines Standorts bzw. des Golfplatzes an den Wetterdienst Open-Meteo (open-meteo.com) übertragen. Es werden keine weiteren personenbezogenen Daten übermittelt."))
            LegalBlock("Platzverzeichnis (golftrack.app)", listOf("Die App lädt das Verzeichnis der eingetragenen Golf- und Minigolfanlagen von golftrack.app. Dabei wird nur der Abruf selbst übertragen; dein Standort oder deine Runden werden nicht mitgeschickt. Wie bei jedem Abruf im Netz sieht der Server dabei deine IP-Adresse."))
            LegalBlock("Anzeigen in der Zählkarte", listOf("Anzeigen der Anlagen kommen ebenfalls von golftrack.app. Damit die Anlagen wissen, wie oft ihre Anzeige gesehen und angetippt wurde, meldet die App gebündelt die Kennung der Anzeige, die Art des Ereignisses und die Anzahl zurück. Es wird keine Kennung deines Geräts und kein Profil über dich gebildet."))
            LegalBlock("Deine Rechte", listOf("Da alle Daten lokal auf deinem Gerät gespeichert sind, hast du jederzeit die volle Kontrolle. Du kannst alle Daten durch Löschen der App vollständig entfernen."))
        }
    }
}

@Composable
fun ImprintScreen(nav: NavController) {
    AppScaffold("Impressum", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            LegalBlock("Angaben gemäß § 5 DDG", listOf("Name: Tobias Aufschläger", "Adresse: Ilztalstraße 5, 94116 Hutthurm, Deutschland", "E-Mail: contact@golftrack.app"), bullets = true)
            LegalBlock("Verantwortlich für den Inhalt", listOf("Tobias Aufschläger, Anschrift wie oben"), bullets = true)
            LegalBlock("Streitbeilegung", listOf(
                "Plattform der EU-Kommission zur Online-Streitbeilegung: ec.europa.eu/consumers/odr",
                "Ich bin nicht verpflichtet und nicht bereit, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.",
            ), bullets = true)
            LegalBlock("Haftungsausschluss", listOf(
                "Alle angezeigten Scores, Statistiken und Distanzen werden automatisch berechnet und dienen nur zur Information.",
                "Für die Richtigkeit der Daten wird keine Haftung übernommen.",
                "GolfTrack ist kein offizielles Produkt des DGV, der EGA oder eines anderen Golfverbands.",
            ), bullets = true)
            LegalBlock("Urheberrecht", listOf(
                "Das Design und der Quellcode der App sind urheberrechtlich geschützt.",
                "Wetterdaten werden von Open-Meteo bereitgestellt.",
                "Kartendaten © OpenStreetMap-Mitwirkende.",
            ), bullets = true)
            LegalBlock("App-Version", listOf("GolfTrack ${BuildConfig.VERSION_NAME}", "Gebaut mit Kotlin & Jetpack Compose"), bullets = true)
        }
    }
}

// --- Was ist neu (WhatsNewView.swift) ---

@Composable
fun WhatsNewScreen(nav: NavController) {
    var tracking by rememberPrefBool(TRACKING_KEY)
    var didEnable by remember { mutableStateOf(false) }
    val highlights = listOf(
        Triple(Icons.AutoMirrored.Filled.DirectionsWalk, "Deine Laufspur", "Wenn du es erlaubst, merkt sich GolfTrack während der Runde alle paar Meter deine Position. Nach der Runde siehst du deinen Weg über den Platz auf der Karte."),
        Triple(Icons.Filled.Flag, "Abschlag und Grün von allein", "Aus deinen Runden schätzt die App, wo Abschlag und Fahne jedes Lochs liegen. Danach steht die Entfernung zur Fahne da, ohne dass du den Pin selbst setzen musst."),
        Triple(Icons.Filled.Timeline, "Fairway-Verlauf", "Nach ein paar Runden zeichnet die App, wo das Fairway ungefähr verläuft – Doglegs inklusive. Je mehr Runden, desto genauer."),
    )
    AppScaffold("", onBack = { Prefs.set(LaunchKeys.WHATS_NEW_SEEN, LaunchKeys.WHATS_NEW_RELEASE); nav.popBackStack() }) { m ->
        Column(m) {
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(22.dp)) {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Neu in GolfTrack", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    Text("Dein Weg über den Platz", color = AppTheme.text, fontSize = 28.sp, fontWeight = FontWeight.Bold)
                    Text("GolfTrack kann jetzt aufzeichnen, wo du auf dem Platz unterwegs warst – und daraus lernen, wie die Löcher liegen.", color = AppTheme.textSec, fontSize = 15.sp)
                }
                highlights.forEach { (icon, title, text) ->
                    Row {
                        IconBadge(icon, AppTheme.gold, 44.dp, circle = true)
                        Spacer(Modifier.width(14.dp))
                        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(title, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                            Text(text, color = AppTheme.textSec, fontSize = 13.sp)
                        }
                    }
                }
                Row(Modifier.fillMaxWidth().background(AppTheme.cardDark, RoundedCornerShape(14.dp)).padding(14.dp)) {
                    Icon(Icons.Filled.PanTool, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(10.dp))
                    Text("Die Aufzeichnung ist standardmäßig aus und läuft nur während einer Runde. Die Daten bleiben auf deinem Gerät und werden nicht übertragen. Du kannst das Tracking jederzeit in den Einstellungen abschalten und die Aufzeichnungen dort löschen.", color = AppTheme.textSec, fontSize = 12.sp)
                }
            }
            Column(Modifier.background(AppTheme.cardDark).padding(horizontal = 20.dp, vertical = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                if (didEnable || tracking) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.CheckCircle, null, tint = AppTheme.green, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Aufzeichnung aktiviert – sie startet mit deiner nächsten Runde.", color = AppTheme.textSec, fontSize = 12.sp)
                    }
                } else {
                    GoldButton("Aufzeichnung einschalten") { Haptics.success(); tracking = true; didEnable = true }
                }
                Text(
                    if (didEnable) "Weiter" else "Später entscheiden",
                    color = if (didEnable) AppTheme.text else AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.fillMaxWidth().clickable {
                        Haptics.tap()
                        Prefs.set(LaunchKeys.WHATS_NEW_SEEN, LaunchKeys.WHATS_NEW_RELEASE)
                        nav.popBackStack()
                    }.padding(vertical = 12.dp),
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                )
            }
        }
    }
}
