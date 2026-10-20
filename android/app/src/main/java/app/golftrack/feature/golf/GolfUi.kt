package app.golftrack.feature.golf

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Assessment
import androidx.compose.material.icons.filled.Autorenew
import androidx.compose.material.icons.filled.ConfirmationNumber
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalDrink
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.LocalParking
import androidx.compose.material.icons.filled.MedicalServices
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.RepeatOne
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material.icons.filled.SupervisedUserCircle
import androidx.compose.material.icons.filled.Umbrella
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Wc
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import app.golftrack.data.DistanceUnit
import app.golftrack.data.GameMode
import app.golftrack.data.GolfStore
import app.golftrack.data.HoleScore
import app.golftrack.data.Round
import app.golftrack.data.catalog.CourseHintKind
import app.golftrack.data.rememberPrefString
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

/* Gemeinsame Kleinteile des Golf-Bereichs: iOS-Systemfarben, Symbole, Kopfzeilen. */

/** iOS-Systemfarben (dunkles Erscheinungsbild). */
object IosColors {
    val orange = Color(0xFFFF9F0A)
    val red = Color(0xFFFF453A)
    val blue = Color(0xFF0A84FF)
    val purple = Color(0xFFBF5AF2)
    val cyan = Color(0xFF64D2FF)
    val live = Color(0xFF33D966)
    /** Dunkelgrüne Schrift auf Gold-Knöpfen wie `Color(red: 0.06, green: 0.14, blue: 0.08)`. */
    val onGoldDark = Color(0xFF0F2414)
}

/** Einheit live aus den Einstellungen (wie `@AppStorage(DistanceUnit.storageKey)`). */
@Composable
fun rememberDistanceUnit(): DistanceUnit {
    val raw by rememberPrefString("distanceUnit", DistanceUnit.METERS.raw)
    return DistanceUnit.fromRaw(raw)
}

/** Symbol wie `GameMode.sfSymbol`. */
val GameMode.icon: ImageVector
    get() = when (this) {
        GameMode.STROKE_PLAY -> Icons.Filled.SportsGolf
        GameMode.STABLEFORD -> Icons.Filled.Stars
        GameMode.ERADO -> Icons.Filled.ConfirmationNumber
        GameMode.SKINS -> Icons.Filled.Verified
        GameMode.DUPLICATE_STABLEFORD -> Icons.Filled.Repeat
        GameMode.MATCHPLAY -> Icons.Filled.People
        GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD, GameMode.BETTER_BALL_MATCHPLAY -> Icons.Filled.LocalFireDepartment
        GameMode.SCRAMBLE_2_MANN -> Icons.Filled.Group
        GameMode.VIERER -> Icons.Filled.Autorenew
        GameMode.GREENSOME -> Icons.Filled.SupervisedUserCircle
        GameMode.SCRAMBLE_MATCHPLAY -> Icons.Filled.Groups
        GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD -> Icons.Filled.Whatshot
        GameMode.SCRAMBLE_TEAM -> Icons.Filled.Groups
        GameMode.MATCH_NET -> Icons.Filled.Assessment
        GameMode.DUPLICATE_SCRAMBLE -> Icons.Filled.RepeatOne
        GameMode.IRISH_RUMBLE -> Icons.Filled.Eco
    }

/** Kurzbeschreibung wie `modeShortDesc` in NewRoundView. */
fun GameMode.shortDesc(): String = when (this) {
    GameMode.STROKE_PLAY -> "Klassisches Zählspiel – jeder Schlag zählt"
    GameMode.STABLEFORD -> "Punkte statt Schläge – Birdie=3, Par=2, Bogey=1"
    GameMode.MATCHPLAY -> "Loch für Loch gegen einen Gegner"
    GameMode.SKINS -> "Niedrigster Score gewinnt den Skin – Unentschieden trägt über"
    GameMode.ERADO -> "Zählspiel – die schlechtesten Löcher werden gestrichen"
    GameMode.BETTER_BALL_STROKE -> "Bester Score pro Loch zählt für das 2er-Team"
    GameMode.BETTER_BALL_STABLEFORD -> "Beste Stableford-Punkte pro Loch für das Team"
    GameMode.SCRAMBLE_2_MANN -> "Beide schlagen ab – bester Abschlag wird gespielt"
    GameMode.VIERER -> "Ein Ball, zwei Spieler – abwechselnd schlagen (Wechselschlag)"
    GameMode.GREENSOME -> "Beide schlagen ab, bester Teeshot – dann Wechselschlag"
    GameMode.BETTER_BALL_MATCHPLAY -> "2 gegen 2 – bester Ball pro Team, Matchplay-Wertung"
    GameMode.BEST_BALL_STROKE -> "3–4 Spieler – bester Score pro Loch zählt für das Team"
    GameMode.BEST_BALL_STABLEFORD -> "3–4 Spieler – beste Stableford-Punkte pro Loch zählen"
    GameMode.SCRAMBLE_TEAM -> "3–4 Spieler – alle schlagen ab, bester Abschlag gespielt"
    else -> description.take(60) + "…"
}

val CourseHintKind.icon: ImageVector
    get() = when (this) {
        CourseHintKind.toilet -> Icons.Filled.Wc
        CourseHintKind.shelter -> Icons.Filled.Umbrella
        CourseHintKind.drinks -> Icons.Filled.LocalDrink
        CourseHintKind.food -> Icons.Filled.Restaurant
        CourseHintKind.rental -> Icons.Filled.SportsGolf
        CourseHintKind.parking -> Icons.Filled.LocalParking
        CourseHintKind.water -> Icons.Filled.WaterDrop
        CourseHintKind.firstAid -> Icons.Filled.MedicalServices
        CourseHintKind.info -> Icons.Filled.Info
    }

/** Ergebnis zum Par: unter Par gold, Par weiß, Bogey orange, schlechter rot. */
fun golfScoreColor(diff: Int): Color = when {
    diff < 0 -> AppTheme.gold
    diff == 0 -> AppTheme.text
    diff == 1 -> IosColors.orange
    else -> IosColors.red
}

/** Vorzeichen-Label wie „E", „+3", „-2". */
fun diffLabel(diff: Int): String = when {
    diff == 0 -> "E"
    diff > 0 -> "+$diff"
    else -> "$diff"
}

/** Haptik nach Ergebnis zum Par – wie `Haptics.score(relativeToPar:)`. */
fun hapticScore(relativeToPar: Int) = when {
    relativeToPar < -1 -> Haptics.celebrate()
    relativeToPar == -1 -> Haptics.success()
    relativeToPar == 0 -> Haptics.success()
    relativeToPar == 1 -> Haptics.light()
    else -> Haptics.warning()
}

// --- Speicher-Helfer ---

fun updateHole(roundId: String, hole: Int, transform: (HoleScore) -> HoleScore) {
    GolfStore.updateRound(roundId) { r ->
        val hs = r.score(hole) ?: HoleScore(holeNumber = hole)
        r.withHoleScore(transform(hs))
    }
}

fun updateOpponent(roundId: String, playerIndex: Int, hole: Int, strokes: Int) {
    GolfStore.updateRound(roundId) { r ->
        r.copy(playerHoleScores = r.playerHoleScores.map {
            if (it.playerIndex == playerIndex && it.holeNumber == hole) it.copy(strokes = strokes) else it
        })
    }
}

fun Round.parFor(hole: Int, pars: List<Int>?): Int = pars?.getOrNull(hole - 1) ?: 4

// --- Layout-Bausteine ---

/** Bildschirmfüllendes „Sheet" wie `.sheet`/`.fullScreenCover` auf iOS. */
@Composable
fun FullSheet(onDismiss: () -> Unit, content: @Composable () -> Unit) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        Box(Modifier.fillMaxSize().background(AppTheme.bg)) { content() }
    }
}

/** Kopfzeile im Stil der iOS-Navigationsleiste (inline-Titel). */
@Composable
fun SheetTopBar(
    title: String,
    leading: (@Composable RowScope.() -> Unit)? = null,
    trailing: (@Composable RowScope.() -> Unit)? = null,
    background: Color = AppTheme.bg,
    center: (@Composable () -> Unit)? = null,
) {
    Box(
        Modifier.fillMaxWidth().background(background).statusBarsPadding()
            .padding(horizontal = 8.dp, vertical = 10.dp),
    ) {
        Row(Modifier.align(Alignment.CenterStart), verticalAlignment = Alignment.CenterVertically) { leading?.invoke(this) }
        Box(Modifier.align(Alignment.Center).padding(horizontal = 96.dp)) {
            if (center != null) center()
            else Text(title, color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
        }
        Row(
            Modifier.align(Alignment.CenterEnd), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) { trailing?.invoke(this) }
    }
}

/** Textknopf in der Kopfzeile. */
@Composable
fun BarButton(text: String, color: Color = AppTheme.gold, bold: Boolean = false, onClick: () -> Unit) {
    Text(
        text, color = color, fontSize = 16.sp, fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
        modifier = Modifier.clickable { onClick() }.padding(horizontal = 8.dp, vertical = 6.dp),
    )
}

@Composable
fun BarIconButton(icon: ImageVector, tint: Color = AppTheme.gold, description: String? = null, onClick: () -> Unit) {
    Box(Modifier.size(40.dp).clickable { onClick() }, contentAlignment = Alignment.Center) {
        Icon(icon, contentDescription = description, tint = tint, modifier = Modifier.size(22.dp))
    }
}

/** Abschnittsüberschrift wie die Section-Header in iOS-Formularen. */
@Composable
fun SectionHeader(text: String, modifier: Modifier = Modifier) {
    Text(
        text.uppercase(), color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Medium,
        modifier = modifier.padding(start = 16.dp, top = 18.dp, bottom = 6.dp),
    )
}

@Composable
fun SectionFooter(text: String) {
    Text(text, color = AppTheme.textSec, fontSize = 12.sp, modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 6.dp))
}

/** Gruppierte Liste mit abgerundeten Ecken (insetGrouped). */
@Composable
fun GroupCard(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Column(modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(12.dp))) { content() }
}

/** Kleines Abzeichen in Kapselform. */
@Composable
fun Capsule(text: String, color: Color, bg: Color = color.copy(alpha = 0.15f), fontSize: Int = 12) {
    Text(
        text, color = color, fontSize = fontSize.sp, fontWeight = FontWeight.Bold,
        modifier = Modifier.background(bg, RoundedCornerShape(50)).padding(horizontal = 10.dp, vertical = 4.dp),
    )
}
