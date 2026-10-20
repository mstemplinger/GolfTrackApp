package app.golftrack.ui.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/** Farben wie `AppTheme` in GolfTrackShared/AppTheme.swift – nicht abweichen. */
object AppTheme {
    val bg = Color(0xFF0E2718)
    val card = Color(0xFF163421)
    val cardAlt = Color(0xFF1C4129)
    val cardDark = Color(0xFF112D1C)

    val gold = Color(0xFFC9A035)
    val goldDark = Color(0xFFA27F27)
    val green = Color(0xFF28824B)
    val greenMid = Color(0xFF1C6138)

    val text = Color.White
    val textSec = Color.White.copy(alpha = 0.60f)
    val textTer = Color.White.copy(alpha = 0.40f)

    val tabBg = cardDark

    /** Text auf Gold-Knöpfen. */
    val onGold = Color(0xFF1A3821)

    fun scoreColor(scoreToPar: Int?): Color = when {
        scoreToPar == null -> Color.White
        scoreToPar < 0 -> Color(0xFF66D980)
        scoreToPar == 0 -> Color.White
        scoreToPar <= 2 -> Color(0xFFFFBF4D)
        else -> Color(0xFFFF6666)
    }
}

private val colors = darkColorScheme(
    primary = AppTheme.gold,
    onPrimary = AppTheme.onGold,
    secondary = AppTheme.green,
    onSecondary = Color.White,
    background = AppTheme.bg,
    onBackground = Color.White,
    surface = AppTheme.card,
    onSurface = Color.White,
    surfaceVariant = AppTheme.cardAlt,
    onSurfaceVariant = AppTheme.textSec,
    surfaceContainer = AppTheme.cardDark,
    surfaceContainerHigh = AppTheme.card,
    surfaceContainerHighest = AppTheme.cardAlt,
    outline = Color.White.copy(alpha = 0.15f),
)

@Composable
fun GolfTrackTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = colors, content = content)
}

fun Modifier.appBackground(): Modifier = this.background(AppTheme.bg)

fun Modifier.cardStyle(): Modifier =
    this.background(AppTheme.card, RoundedCornerShape(16.dp))

fun Modifier.goldButtonBackground(): Modifier =
    this.fillMaxWidth().background(AppTheme.gold, RoundedCornerShape(14.dp)).padding(vertical = 16.dp)
