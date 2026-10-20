package app.golftrack.feature.records

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.ConfirmationNumber
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.RepeatOne
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material.icons.filled.SupervisedUserCircle
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.data.GameMode
import app.golftrack.data.RoundTrack
import app.golftrack.data.TrackPoint
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/** iOS-Systemfarben (Dunkelmodus), wie sie in den Swift-Views verwendet werden. */
internal object IosColor {
    val orange = Color(0xFFFF9F0A)
    val red = Color(0xFFFF453A)
    val purple = Color(0xFFBF5AF2)
    val blue = Color(0xFF0A84FF)
    val yellow = Color(0xFFFFD60A)
    val green = Color(0xFF30D158)
    val gray = Color(0xFF8E8E93)
}

/** iOS-Schriftgrößen (Dynamic Type „Large"). */
internal object IosFont {
    val largeTitle: TextUnit = 34.sp
    val title2: TextUnit = 22.sp
    val title3: TextUnit = 20.sp
    val headline: TextUnit = 17.sp
    val body: TextUnit = 17.sp
    val subheadline: TextUnit = 15.sp
    val footnote: TextUnit = 13.sp
    val caption: TextUnit = 12.sp
    val caption2: TextUnit = 11.sp
}

/** Wie `golfScoreColor` in Extensions.swift. */
internal fun golfScoreColor(diff: Int?): Color = when {
    diff == null -> AppTheme.text
    diff < 0 -> AppTheme.gold
    diff == 0 -> AppTheme.text
    diff == 1 -> IosColor.orange
    else -> IosColor.red
}

private val abbreviatedFmt = DateTimeFormatter.ofPattern("d. MMM yyyy", Locale.GERMAN)
private val completeFmt = DateTimeFormatter.ofPattern("EEEE, d. MMMM yyyy", Locale.GERMAN)
private val dayMonthFmt = DateTimeFormatter.ofPattern("d. MMM", Locale.GERMAN)

private fun zoned(ms: Long) = Instant.ofEpochMilli(ms).atZone(ZoneId.systemDefault())

/** `date.formatted(date: .abbreviated, time: .omitted)` → „20. Okt. 2026". */
internal fun formatDateAbbreviated(ms: Long): String = zoned(ms).format(abbreviatedFmt)

/** `date.formatted(date: .complete, time: .omitted)` → „Dienstag, 20. Oktober 2026". */
internal fun formatDateComplete(ms: Long): String = zoned(ms).format(completeFmt)

/** „20. Okt." für Diagrammachsen. */
internal fun formatDayMonth(ms: Long): String = zoned(ms).format(dayMonthFmt)

internal fun fmt1(v: Double): String = String.format(Locale.US, "%.1f", v)
internal fun fmt0(v: Double): String = String.format(Locale.US, "%.0f", v)

/** Symbol je Spielform – Gegenstück zu `GameMode.sfSymbol`. */
internal fun gameModeIcon(mode: GameMode): ImageVector = when (mode) {
    GameMode.STROKE_PLAY -> Icons.Filled.SportsGolf
    GameMode.STABLEFORD -> Icons.Filled.Stars
    GameMode.ERADO -> Icons.Filled.ConfirmationNumber
    GameMode.SKINS -> Icons.Filled.Verified
    GameMode.DUPLICATE_STABLEFORD -> Icons.Filled.Repeat
    GameMode.MATCHPLAY -> Icons.Filled.People
    GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD, GameMode.BETTER_BALL_MATCHPLAY -> Icons.Filled.LocalFireDepartment
    GameMode.SCRAMBLE_2_MANN -> Icons.Filled.People
    GameMode.VIERER -> Icons.Filled.Sync
    GameMode.GREENSOME -> Icons.Filled.SupervisedUserCircle
    GameMode.SCRAMBLE_MATCHPLAY -> Icons.Filled.Groups
    GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD -> Icons.Filled.Whatshot
    GameMode.SCRAMBLE_TEAM -> Icons.Filled.Groups
    GameMode.MATCH_NET -> Icons.Filled.BarChart
    GameMode.DUPLICATE_SCRAMBLE -> Icons.Filled.RepeatOne
    GameMode.IRISH_RUMBLE -> Icons.Filled.Eco
}

// --- Laufspur-Helfer (wie RoundTrack.swift) ---

internal val TrackPoint.isValid: Boolean get() = coordinate.isValid

/** Dauer in Sekunden – läuft eine Aufzeichnung noch, bis jetzt. */
internal val RoundTrack.durationSeconds: Double
    get() = ((endedAt ?: System.currentTimeMillis()) - startedAt) / 1000.0

internal val RoundTrack.totalDistanceMeters: Double
    get() {
        val pts = points.filter { it.isValid }
        if (pts.size < 2) return 0.0
        var sum = 0.0
        for (i in 1 until pts.size) sum += pts[i].coordinate.distanceTo(pts[i - 1].coordinate)
        return sum
    }

/** Laufspur einmal nach Loch gruppiert – wie `PreparedRound` auf iOS. */
internal class PreparedRound(val round: app.golftrack.data.Round) {
    private val byHole: Map<Int, List<TrackPoint>> = round.track?.points?.groupBy { it.holeNumber } ?: emptyMap()
    fun points(hole: Int): List<TrackPoint> = (byHole[hole] ?: emptyList()).sortedBy { it.timeOffset }
}

// --- Kleine UI-Bausteine ---

/** `ContentUnavailableView` – Symbol, Titel, Beschreibung mittig. */
@Composable
internal fun EmptyState(icon: ImageVector, title: String, description: String, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().padding(32.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(icon, contentDescription = null, tint = AppTheme.textSec, modifier = Modifier.size(48.dp))
            Text(title, color = AppTheme.text, fontSize = IosFont.title3, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            Text(description, color = AppTheme.textSec, fontSize = IosFont.subheadline, textAlign = TextAlign.Center)
        }
    }
}

/** Bestätigungsdialog im App-Stil (statt `confirmationDialog`). */
@Composable
internal fun ConfirmDialog(
    title: String,
    message: String?,
    confirmText: String,
    destructive: Boolean = true,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = AppTheme.card,
        title = { Text(title, color = AppTheme.text) },
        text = message?.let { { Text(it, color = AppTheme.textSec) } },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(confirmText, color = if (destructive) IosColor.red else AppTheme.gold, fontWeight = FontWeight.SemiBold)
            }
        },
        dismissButton = {
            TextButton(onClick = { Haptics.tap(); onDismiss() }) { Text("Abbrechen", color = AppTheme.gold) }
        },
    )
}

/** Hinweisdialog mit nur „OK". */
@Composable
internal fun InfoDialog(title: String, message: String, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = AppTheme.card,
        title = { Text(title, color = AppTheme.text) },
        text = { Text(message, color = AppTheme.textSec) },
        confirmButton = { TextButton(onClick = { Haptics.tap(); onDismiss() }) { Text("OK", color = AppTheme.gold) } },
    )
}

/** Überschrift über einer Listen-Sektion (wie `Section("…")` in `.insetGrouped`). */
@Composable
internal fun SectionHeader(text: String, modifier: Modifier = Modifier, color: Color = AppTheme.textSec) {
    Text(
        text.uppercase(Locale.GERMAN), color = color, fontSize = IosFont.footnote,
        modifier = modifier.padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 6.dp),
    )
}

@Composable
internal fun SectionFooter(text: String, modifier: Modifier = Modifier) {
    Text(
        text, color = AppTheme.textSec, fontSize = IosFont.caption,
        modifier = modifier.padding(start = 16.dp, end = 16.dp, top = 6.dp, bottom = 4.dp),
    )
}

/** Gruppierte Karte für Listenzeilen (`.insetGrouped`-Sektion). */
@Composable
internal fun GroupCard(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Column(
        modifier.fillMaxWidth().padding(horizontal = 16.dp)
            .background(AppTheme.card, RoundedCornerShape(12.dp)),
    ) { content() }
}

/** Kapsel-Abzeichen (Konfidenz, Belastbarkeit …). */
@Composable
internal fun CapsuleBadge(text: String, color: Color) {
    Text(
        text, color = color, fontSize = IosFont.caption2, fontWeight = FontWeight.Bold,
        modifier = Modifier.background(color.copy(alpha = 0.15f), RoundedCornerShape(50)).padding(horizontal = 7.dp, vertical = 2.dp),
    )
}

/** Textknopf in der Werkzeugleiste. */
@Composable
internal fun ToolbarTextButton(text: String, color: Color = AppTheme.gold, enabled: Boolean = true, bold: Boolean = false, onClick: () -> Unit) {
    Text(
        text,
        color = if (enabled) color else color.copy(alpha = 0.35f),
        fontSize = IosFont.body,
        fontWeight = if (bold) FontWeight.SemiBold else FontWeight.Normal,
        modifier = Modifier.clickable(enabled = enabled) { onClick() }.padding(horizontal = 12.dp, vertical = 8.dp),
    )
}
