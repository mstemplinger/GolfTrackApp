package app.golftrack.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

/*
 * Kleine Bausteine für Listen im iOS-Stil (insetGrouped): Karten mit Zeilen,
 * farbiges Icon-Kästchen, Abschnittsüberschrift und -fußzeile.
 */

internal val iosBlue = Color(0xFF4DB3FF)
internal val iosOrange = Color(0xFFFF9F0A)
internal val iosRed = Color(0xFFFF453A)
internal val iosGreen = Color(0xFF34C759)
internal val iosTeal = Color(0xFF66CCE6)
internal val iosPurple = Color(0xFFBF5AF2)

@Composable
internal fun IconBadge(icon: ImageVector, color: Color, size: Dp = 40.dp, corner: Dp = 9.dp, circle: Boolean = false) {
    Box(
        Modifier.size(size).background(color.copy(alpha = 0.18f), if (circle) CircleShape else RoundedCornerShape(corner)),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, null, tint = color, modifier = Modifier.size(size * 0.45f)) }
}

/** Gruppe von Zeilen auf einer Karte. */
@Composable
internal fun GroupCard(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Column(modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)), content = content)
}

@Composable
internal fun RowDivider(start: Dp = 62.dp) {
    HorizontalDivider(Modifier.padding(start = start), color = AppTheme.cardAlt, thickness = 0.7.dp)
}

@Composable
internal fun SectionHeader(text: String, modifier: Modifier = Modifier) {
    Text(
        text.uppercase(), color = AppTheme.textSec, fontSize = 12.sp, letterSpacing = 0.5.sp,
        modifier = modifier.padding(start = 16.dp, bottom = 6.dp, top = 8.dp),
    )
}

@Composable
internal fun SectionFooter(text: String, modifier: Modifier = Modifier) {
    Text(text, color = AppTheme.textSec, fontSize = 12.sp, modifier = modifier.padding(start = 16.dp, end = 16.dp, top = 6.dp))
}

/** Zeile mit Icon-Kästchen, Titel und Pfeil – wie `settingsRow` im Profil. */
@Composable
internal fun NavRow(
    icon: ImageVector,
    color: Color,
    title: String,
    trailing: @Composable RowScope.() -> Unit = {
        Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))
    },
    onClick: () -> Unit,
) {
    Row(
        Modifier.fillMaxWidth().clickable { Haptics.tap(); onClick() }.padding(horizontal = 18.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconBadge(icon, color)
        Spacer(Modifier.width(14.dp))
        Text(title, color = AppTheme.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
        trailing()
    }
}

/** Einfache Zeile (Listenstil) mit Icon und Titel. */
@Composable
internal fun ListRow(
    icon: ImageVector? = null,
    title: String,
    iconTint: Color = AppTheme.gold,
    subtitle: String? = null,
    trailing: @Composable RowScope.() -> Unit = {},
    onClick: (() -> Unit)? = null,
) {
    var m = Modifier.fillMaxWidth()
    if (onClick != null) m = m.clickable { Haptics.tap(); onClick() }
    Row(m.padding(horizontal = 16.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
        if (icon != null) {
            Icon(icon, null, tint = iconTint, modifier = Modifier.size(22.dp))
            Spacer(Modifier.width(14.dp))
        }
        Column(Modifier.weight(1f)) {
            Text(title, color = AppTheme.text, fontSize = 15.sp)
            if (subtitle != null) Text(subtitle, color = AppTheme.textSec, fontSize = 12.sp)
        }
        trailing()
    }
}

@Composable
internal fun GoldSwitch(checked: Boolean, onChange: (Boolean) -> Unit) {
    Switch(
        checked = checked,
        onCheckedChange = { Haptics.selection(); onChange(it) },
        colors = SwitchDefaults.colors(
            checkedThumbColor = androidx.compose.ui.graphics.Color.White,
            checkedTrackColor = AppTheme.gold,
            uncheckedThumbColor = AppTheme.textSec,
            uncheckedTrackColor = AppTheme.cardAlt,
            uncheckedBorderColor = AppTheme.cardAlt,
        ),
    )
}

/** Segmentierte Auswahl wie `.pickerStyle(.segmented)`. */
@Composable
internal fun <T> Segmented(options: List<Pair<T, String>>, selected: T, modifier: Modifier = Modifier, onSelect: (T) -> Unit) {
    SingleChoiceSegmentedButtonRow(modifier) {
        options.forEachIndexed { i, (value, label) ->
            SegmentedButton(
                selected = value == selected,
                onClick = { if (value != selected) { Haptics.selection(); onSelect(value) } },
                shape = SegmentedButtonDefaults.itemShape(i, options.size),
                icon = {},
                colors = SegmentedButtonDefaults.colors(
                    activeContainerColor = AppTheme.gold,
                    activeContentColor = AppTheme.onGold,
                    inactiveContainerColor = AppTheme.cardAlt,
                    inactiveContentColor = AppTheme.text,
                    activeBorderColor = AppTheme.cardAlt,
                    inactiveBorderColor = AppTheme.cardAlt,
                ),
            ) { Text(label, fontSize = 13.sp, maxLines = 1) }
        }
    }
}

/** Kleiner Textblock mit Überschrift (Datenschutz/Impressum). */
@Composable
internal fun LegalBlock(title: String, lines: List<String>, bullets: Boolean = false) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(12.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(title, color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        lines.forEach { Text(if (bullets) "• $it" else it, color = AppTheme.textSec, fontSize = 14.sp) }
    }
}

@Composable
internal fun VSpace(h: Dp) = Spacer(Modifier.height(h))
