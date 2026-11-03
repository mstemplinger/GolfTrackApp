package app.golftrack.feature.golf

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.ui.theme.AppTheme

/**
 * Wie RoundLoadingView.swift: kurze Ladeseite vor der Runde. Lädt nichts – sie
 * gibt den einen Hinweis mit, auf den die Positionsdaten angewiesen sind:
 * Schlag sofort nach dem Schlagen eintragen.
 */
object RoundLoading {
    private const val DURATION_MS = 4000
    /** Die ersten Runden immer, danach jede siebte. */
    private const val ALWAYS_FIRST = 8
    private const val INTERVAL = 7

    /** `startCount` = Zahl der bisherigen Rundenstarts (vor diesem). */
    fun shouldShow(startCount: Int): Boolean =
        startCount < ALWAYS_FIRST || (startCount - ALWAYS_FIRST + 1) % INTERVAL == 0

    @Composable
    fun Screen(courseName: String, onFinished: () -> Unit) {
        val finished by rememberUpdatedState(onFinished)
        val progress = remember { Animatable(0f) }
        val pulse by rememberInfiniteTransition(label = "pulse")
            .animateFloat(0.94f, 1.08f, infiniteRepeatable(tween(900), RepeatMode.Reverse), label = "p")

        LaunchedEffect(Unit) {
            progress.animateTo(1f, tween(DURATION_MS, easing = LinearEasing))
            finished()
        }

        Box(
            Modifier.fillMaxSize().background(AppTheme.bg)
                // Tipps fallen nicht auf die Seite darunter durch.
                .clickable(remember { MutableInteractionSource() }, indication = null) {},
        ) {
            Column(
                Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(horizontal = 28.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.weight(1f))
                Box(contentAlignment = Alignment.Center) {
                    Box(Modifier.size(132.dp).scale(pulse).background(AppTheme.gold.copy(alpha = 0.14f), CircleShape))
                    Icon(Icons.Filled.SportsGolf, null, tint = AppTheme.gold, modifier = Modifier.size(56.dp))
                }
                Text(
                    "SO FUNKTIONIERT’S", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
                    letterSpacing = 0.8.sp, modifier = Modifier.padding(top = 28.dp),
                )
                Text(
                    "Schlag sofort eintragen, direkt nachdem du geschlagen hast.",
                    color = AppTheme.text, fontSize = 30.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.SansSerif,
                    textAlign = TextAlign.Center, lineHeight = 34.sp, modifier = Modifier.padding(top = 10.dp),
                )
                Text(
                    "Nur so stimmt die Position jedes Schlags auf dem Platz.",
                    color = AppTheme.textSec, fontSize = 17.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(top = 14.dp),
                )
                Spacer(Modifier.weight(1f))
                Column(Modifier.fillMaxWidth().padding(bottom = 12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    LinearProgressIndicator(
                        progress = { progress.value }, modifier = Modifier.fillMaxWidth(),
                        color = AppTheme.gold, trackColor = AppTheme.cardAlt,
                    )
                    Text("Platzdaten werden geladen …", color = AppTheme.textSec, fontSize = 13.sp, modifier = Modifier.padding(top = 10.dp))
                    Text(courseName, color = AppTheme.textTer, fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                        maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(top = 4.dp))
                }
            }
        }
    }
}
