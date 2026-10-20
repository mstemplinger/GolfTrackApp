package app.golftrack.feature.minigolf

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalCafe
import androidx.compose.material.icons.filled.LocalParking
import androidx.compose.material.icons.filled.MedicalServices
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Umbrella
import androidx.compose.material.icons.filled.Wc
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.data.catalog.CourseHint
import app.golftrack.data.catalog.CourseHintKind
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// MARK: - Bausteine im iOS-Stil

internal object MgFont {
    val title = 28.sp
    val title2 = 22.sp
    val title3 = 20.sp
    val headline = 17.sp
    val body = 17.sp
    val subheadline = 15.sp
    val caption = 12.sp
    val caption2 = 11.sp
}

internal val MgRed = Color(0xFFFF453A)
internal val MgMedalGold = Color(0.85f, 0.65f, 0.1f)
internal val MgBronze = Color(0.72f, 0.45f, 0.2f)
internal val MgOnGoldDark = Color(0.06f, 0.14f, 0.08f)

internal fun Modifier.mgCard(radius: Dp = 16.dp, color: Color = AppTheme.card, padding: Dp = 16.dp): Modifier =
    this.fillMaxWidth().background(color, RoundedCornerShape(radius)).padding(padding)

/** Klickbar mit Haptik `Haptics.tap()` (wie iOS-Knöpfe mit Haptik im Action-Block). */
internal fun Modifier.tapClick(haptic: () -> Unit = { Haptics.tap() }, onClick: () -> Unit): Modifier =
    this.clickable { haptic(); onClick() }

@Composable
internal fun MgText(
    text: String,
    size: TextUnit = MgFont.body,
    color: Color = AppTheme.text,
    weight: FontWeight? = null,
    modifier: Modifier = Modifier,
    maxLines: Int = Int.MAX_VALUE,
    textAlign: androidx.compose.ui.text.style.TextAlign? = null,
) = Text(
    text, modifier = modifier, color = color, fontSize = size, fontWeight = weight,
    maxLines = maxLines, overflow = TextOverflow.Ellipsis, textAlign = textAlign,
    style = TextStyle(fontFeatureSettings = "tnum"),
)

/** `Label(title, systemImage:)` – Symbol in Gold, Text weiß. */
@Composable
internal fun MgLabel(
    text: String,
    icon: ImageVector,
    size: TextUnit = MgFont.headline,
    weight: FontWeight = FontWeight.SemiBold,
    iconTint: Color = AppTheme.gold,
    color: Color = AppTheme.text,
    modifier: Modifier = Modifier,
) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(icon, null, tint = iconTint, modifier = Modifier.size((size.value + 2).dp))
        MgText(text, size, color, weight)
    }
}

/** Knopf mit Symbol und Text, volle Breite – „Hinzufügen", „Fortsetzen" … */
@Composable
internal fun MgPillButton(
    text: String,
    icon: ImageVector?,
    background: Color,
    foreground: Color,
    modifier: Modifier = Modifier,
    radius: Dp = 10.dp,
    vertical: Dp = 10.dp,
    size: TextUnit = MgFont.subheadline,
    haptic: () -> Unit = { Haptics.tap() },
    onClick: () -> Unit,
) {
    Row(
        modifier.background(background, RoundedCornerShape(radius)).clickable { haptic(); onClick() }
            .padding(vertical = vertical, horizontal = 8.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            Icon(icon, null, tint = foreground, modifier = Modifier.size((size.value + 2).dp))
            Spacer(Modifier.width(6.dp))
        }
        MgText(text, size, foreground, FontWeight.Bold)
    }
}

/** Kleiner runder Zähler (Spieleranzahl, Wettkämpfe). */
@Composable
internal fun CountBadge(n: Int, size: Dp = 26.dp, fontSize: TextUnit = MgFont.subheadline) {
    Box(Modifier.size(size).background(AppTheme.gold, CircleShape), contentAlignment = Alignment.Center) {
        MgText("$n", fontSize, Color.White, FontWeight.Bold)
    }
}

internal fun formatDateTime(millis: Long): String =
    SimpleDateFormat("d. MMM yyyy, HH:mm", Locale.GERMAN).format(Date(millis)) + " Uhr"

// MARK: - Spieler

@Composable
internal fun PlayerNameRow(index: Int, value: String, onChange: (String) -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(10.dp))
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Box(Modifier.size(24.dp).background(AppTheme.gold.copy(alpha = 0.75f), CircleShape), contentAlignment = Alignment.Center) {
            MgText("${index + 1}", MgFont.caption, Color.White, FontWeight.Bold)
        }
        Box(Modifier.weight(1f)) {
            if (value.isEmpty()) MgText("Spieler ${index + 1}", MgFont.body, AppTheme.textTer)
            BasicTextField(
                value = value,
                onValueChange = onChange,
                singleLine = true,
                textStyle = TextStyle(color = AppTheme.text, fontSize = MgFont.body),
                cursorBrush = SolidColor(AppTheme.gold),
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words),
                modifier = Modifier.fillMaxWidth(),
            )
        }
    }
}

/** „Hinzufügen" / „Entfernen" unter der Spielerliste – bis zu 8 Spieler. */
@Composable
internal fun PlayerCountButtons(count: Int, onAdd: () -> Unit, onRemove: () -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        if (count < 8) {
            MgPillButton("Hinzufügen", Icons.Filled.Add, AppTheme.gold.copy(alpha = 0.12f), AppTheme.gold,
                Modifier.weight(1f), onClick = onAdd)
        }
        if (count > 1) {
            MgPillButton("Entfernen", Icons.Filled.Remove, MgRed.copy(alpha = 0.1f), MgRed,
                Modifier.weight(1f), haptic = { Haptics.light() }, onClick = onRemove)
        }
    }
}

@Composable
internal fun PlayersEditor(names: List<String>, onNames: (List<String>) -> Unit) {
    Column(Modifier.animateContentSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        names.forEachIndexed { i, n ->
            PlayerNameRow(i, n) { v -> onNames(names.toMutableList().also { it[i] = v }) }
        }
    }
}

// MARK: - Hinweise der Anlage (CourseHints.swift)

internal val CourseHintKind.icon: ImageVector
    get() = when (this) {
        CourseHintKind.toilet -> Icons.Filled.Wc
        CourseHintKind.shelter -> Icons.Filled.Umbrella
        CourseHintKind.drinks -> Icons.Filled.LocalCafe
        CourseHintKind.food -> Icons.Filled.Restaurant
        CourseHintKind.rental -> Icons.Filled.SportsGolf
        CourseHintKind.parking -> Icons.Filled.LocalParking
        CourseHintKind.water -> Icons.Filled.WaterDrop
        CourseHintKind.firstAid -> Icons.Filled.MedicalServices
        CourseHintKind.info -> Icons.Filled.Info
    }

/** Der Hinweis, der bei Loch `rotation` an der Reihe ist (auch für negative Werte). */
internal fun List<CourseHint>.hintForRotation(rotation: Int): CourseHint? =
    if (isEmpty()) null else this[((rotation % size) + size) % size]

/** Alle Hinweise am Stück – auf dem Willkommensbildschirm. */
@Composable
internal fun CourseHintsCard(hints: List<CourseHint>) {
    if (hints.isEmpty()) return
    Column(Modifier.mgCard(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        MgText("Gut zu wissen", MgFont.subheadline, AppTheme.gold, FontWeight.Bold)
        hints.forEach { hint ->
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Icon(hint.kind.icon, null, tint = AppTheme.gold, modifier = Modifier.width(22.dp).size(18.dp))
                MgText(hint.text, MgFont.subheadline, AppTheme.textSec, modifier = Modifier.weight(1f))
            }
        }
    }
}

/** Ein einzelner Hinweis, der mit dem Loch wechselt. */
@Composable
internal fun CourseHintRotatingCard(hints: List<CourseHint>, rotation: Int) {
    val hint = hints.hintForRotation(rotation) ?: return
    Row(Modifier.mgCard(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(hint.kind.icon, null, tint = AppTheme.gold, modifier = Modifier.size(24.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            MgText("Gut zu wissen", MgFont.caption2, AppTheme.gold.copy(alpha = 0.8f), FontWeight.SemiBold)
            MgText(hint.text, MgFont.subheadline, AppTheme.textSec)
        }
    }
}

// MARK: - Wettkämpfe (MinigolfChallengeViews.swift)

/** Liste zum An- und Abwählen der Wettkämpfe. */
@Composable
internal fun ChallengeSelectionList(selection: List<MinigolfChallenge>, onChange: (List<MinigolfChallenge>) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        MinigolfChallenge.entries.forEach { c ->
            val isOn = c in selection
            val bg by animateColorAsState(if (isOn) AppTheme.gold.copy(alpha = 0.12f) else AppTheme.cardAlt, label = "bg")
            Row(
                Modifier.fillMaxWidth()
                    .background(bg, RoundedCornerShape(10.dp))
                    .border(1.dp, if (isOn) AppTheme.gold.copy(alpha = 0.5f) else Color.Transparent, RoundedCornerShape(10.dp))
                    .clickable {
                        Haptics.selection()
                        onChange(if (isOn) selection - c else selection + c)
                    }
                    .padding(horizontal = 12.dp, vertical = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Box(
                    Modifier.size(30.dp).background(if (isOn) AppTheme.gold else AppTheme.gold.copy(alpha = 0.15f), CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(c.icon, null, tint = if (isOn) Color.White else AppTheme.gold, modifier = Modifier.size(16.dp))
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    MgText(c.displayName, MgFont.subheadline, weight = FontWeight.Bold)
                    MgText(c.rule, MgFont.caption, AppTheme.textSec)
                }
                Icon(
                    if (isOn) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked, null,
                    tint = if (isOn) AppTheme.gold else AppTheme.textSec.copy(alpha = 0.4f),
                    modifier = Modifier.size(22.dp),
                )
            }
        }
    }
}

/** Karte für den Einrichten-Bildschirm. */
@Composable
internal fun ChallengeSetupCard(
    selection: List<MinigolfChallenge>,
    onChange: (List<MinigolfChallenge>) -> Unit,
    initiallyExpanded: Boolean = true,
) {
    var expanded by remember { mutableStateOf(initiallyExpanded) }
    Column(Modifier.mgCard().animateContentSize(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            Modifier.fillMaxWidth().clickable { Haptics.tap(); expanded = !expanded },
            verticalAlignment = Alignment.CenterVertically,
        ) {
            MgLabel("Wettkämpfe", Icons.Filled.EmojiEvents)
            Spacer(Modifier.weight(1f))
            if (selection.isNotEmpty()) {
                CountBadge(selection.size)
                Spacer(Modifier.width(8.dp))
            }
            Icon(if (expanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore, null, tint = AppTheme.textSec)
        }
        if (expanded) {
            MgText(
                "Nebenwertungen zusätzlich zur Schlagzahl – jede hat ihren eigenen Sieger. Lässt sich auch während der Runde noch ändern.",
                MgFont.caption, AppTheme.textSec,
            )
            ChallengeSelectionList(selection, onChange)
        } else if (selection.isNotEmpty()) {
            MgText(selection.joinToString(" · ") { it.displayName }, MgFont.caption, AppTheme.textSec, maxLines = 2)
        }
    }
}

/** Live-Stand während der Runde. */
@Composable
internal fun ChallengeLiveCard(
    playerNames: List<String>,
    scores: List<List<Int>>,
    challenges: List<MinigolfChallenge>,
    onEdit: (() -> Unit)?,
) {
    val results = MinigolfChallengeEngine.results(challenges, scores, playerNames)
    Column(Modifier.mgCard(14.dp, padding = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MgLabel("Wettkämpfe", Icons.Filled.EmojiEvents, MgFont.subheadline, FontWeight.Bold)
            Spacer(Modifier.weight(1f))
            if (onEdit != null) {
                MgText("Ändern", MgFont.caption, AppTheme.gold, FontWeight.Bold,
                    Modifier.clickable { Haptics.tap(); onEdit() }.padding(4.dp))
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            results.forEach { r ->
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    MgText(r.challenge.trophy, MgFont.caption)
                    MgText(r.challenge.displayName, MgFont.caption, AppTheme.textSec, FontWeight.Bold)
                    Spacer(Modifier.weight(1f))
                    val v = r.leaderValueText
                    if (v != null) {
                        MgText(r.leaderNames, MgFont.caption, weight = FontWeight.Bold, maxLines = 1,
                            modifier = Modifier.weight(1f, fill = false))
                        MgText(v, MgFont.caption, AppTheme.gold)
                    } else {
                        MgText("noch offen", MgFont.caption, AppTheme.textSec)
                    }
                }
            }
        }
    }
}

/** Pokale im Ergebnis. */
@Composable
internal fun AwardsCard(playerNames: List<String>, scores: List<List<Int>>, challenges: List<MinigolfChallenge>) {
    val results = MinigolfChallengeEngine.results(challenges, scores, playerNames)
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        MgText("Pokale", MgFont.headline, weight = FontWeight.SemiBold)
        results.forEach { r ->
            Column(Modifier.mgCard(14.dp, padding = 12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    MgText(r.challenge.trophy, MgFont.title3)
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        MgText(r.challenge.displayName, MgFont.subheadline, weight = FontWeight.Bold)
                        if (r.leaders.isEmpty()) {
                            MgText("Kein Sieger – niemand hat es geschafft.", MgFont.caption, AppTheme.textSec)
                        } else {
                            MgText(
                                if (r.leaders.size > 1) "Geteilt: ${r.leaderNames}" else r.leaderNames,
                                MgFont.caption, AppTheme.gold, FontWeight.Bold,
                            )
                        }
                    }
                    r.leaderValueText?.let { MgText(it, MgFont.subheadline, AppTheme.gold, FontWeight.Bold) }
                }
                // Vollständige Wertung, damit man den Abstand sieht
                Column(Modifier.padding(start = 2.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    r.standings.forEach { s ->
                        Row {
                            MgText(s.name, MgFont.caption, AppTheme.textSec, maxLines = 1, modifier = Modifier.weight(1f))
                            MgText(r.valueText(s), MgFont.caption, AppTheme.textSec)
                        }
                    }
                }
            }
        }
    }
}

/** Kopfzeile für Sheets: Titel mittig, rechts „Fertig". */
@Composable
internal fun SheetHeader(title: String, trailing: String = "Fertig", onTrailing: () -> Unit, leading: (@Composable RowScope.() -> Unit)? = null) {
    Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp)) {
        Row(Modifier.align(Alignment.CenterStart)) { leading?.invoke(this) }
        MgText(title, MgFont.headline, weight = FontWeight.SemiBold, modifier = Modifier.align(Alignment.Center))
        MgText(trailing, MgFont.body, AppTheme.gold, FontWeight.SemiBold,
            Modifier.align(Alignment.CenterEnd).clickable { Haptics.tap(); onTrailing() }.padding(6.dp))
    }
}

@Composable
internal fun Fade(visible: Boolean, content: @Composable () -> Unit) {
    AnimatedVisibility(visible) { content() }
}
