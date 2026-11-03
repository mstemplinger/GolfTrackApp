package app.golftrack.feature.guide

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.delay

// MARK: - TipVisual

/** Animierte Grafik, die einen Tipp in der Detailansicht veranschaulicht. */
enum class TipVisual {
    // Anfänger
    GRIP, STANCE, EYE_ON_BALL, TEMPO, CHIP,
    // Technik
    SPINE_AXIS, HIP_ROTATION, WEIGHT_SHIFT, SWING_PATH, IMPACT,
    // Mental Game
    PRE_SHOT_ROUTINE, ONE_SHOT, ACCEPT_BOGEY, VISUALIZATION, PRESSURE,
    // Strategie
    COURSE_MANAGEMENT, HANDICAP_STROKES, WIND, PUTT_STRATEGY, RISK_REWARD,
}

@Composable
fun TipVisualView(visual: TipVisual, color: Color) {
    when (visual) {
        TipVisual.GRIP -> GripVisual(color)
        TipVisual.STANCE -> StanceVisual(color)
        TipVisual.EYE_ON_BALL -> EyeOnBallVisual(color)
        TipVisual.TEMPO -> TempoVisual(color)
        TipVisual.CHIP -> ChipVisual(color)
        TipVisual.SPINE_AXIS -> SpineAxisVisual(color)
        TipVisual.HIP_ROTATION -> HipRotationVisual(color)
        TipVisual.WEIGHT_SHIFT -> WeightShiftVisual(color)
        TipVisual.SWING_PATH -> SwingPathVisual(color)
        TipVisual.IMPACT -> ImpactVisual(color)
        TipVisual.PRE_SHOT_ROUTINE -> PreShotRoutineVisual(color)
        TipVisual.ONE_SHOT -> OneShotVisual(color)
        TipVisual.ACCEPT_BOGEY -> AcceptBogeyVisual(color)
        TipVisual.VISUALIZATION -> VisualizationVisual(color)
        TipVisual.PRESSURE -> PressureVisual(color)
        TipVisual.COURSE_MANAGEMENT -> CourseManagementVisual(color)
        TipVisual.HANDICAP_STROKES -> HandicapStrokesVisual(color)
        TipVisual.WIND -> WindVisual(color)
        TipVisual.PUTT_STRATEGY -> PuttStrategyVisual(color)
        TipVisual.RISK_REWARD -> RiskRewardVisual(color)
    }
}

// MARK: - Gewichtsverlagerung

private class WeightPhase(val name: String, val hint: String, val lead: Int, val pose: GolferPose)

private val weightPhases = listOf(
    WeightPhase("Ansprechen", "Gewicht gleich verteilt", 50, GolferPose.address),
    WeightPhase("Rückschwung", "Aufs hintere Bein laden", 30, GolferPose.top),
    WeightPhase("Finish", "Alles aufs vordere Bein", 90, GolferPose.finished),
)

/**
 * Golfer frontal gesehen (Rechtshänder, Ziel rechts im Bild). Drei Phasen laufen
 * automatisch durch; Antippen einer Phase hält die Animation dort an.
 */
@Composable
private fun WeightShiftVisual(color: Color) {
    var index by remember { mutableIntStateOf(0) }
    var autoPlay by remember { mutableStateOf(true) }
    val phase = weightPhases[index]

    LaunchedEffect(autoPlay) {
        while (autoPlay) {
            delay(2200)
            if (!autoPlay) break
            index = (index + 1) % weightPhases.size
        }
    }

    // Feder wie `.spring(response: 0.7, dampingFraction: 0.8)`
    fun <T> sp() = spring<T>(dampingRatio = 0.8f, stiffness = 80f)
    val hip by animateFloatAsState(phase.pose.hipShift, sp(), label = "hip")
    val arm by animateFloatAsState(phase.pose.arm, sp(), label = "arm")
    val club by animateFloatAsState(phase.pose.club, sp(), label = "club")
    val finish by animateFloatAsState(phase.pose.finish, sp(), label = "finish")
    val leadAnim by animateFloatAsState(phase.lead / 100f, sp(), label = "lead")
    val pose = GolferPose(hip, arm, club, finish)

    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        // Bühne mit Golfer, Boden, Druckpunkten unter den Füßen
        TipCanvas(Modifier.fillMaxWidth().height(250.dp).clip(RoundedCornerShape(12.dp)).background(lawnGradient)) {
            val ground = h - 38
            val center = w / 2
            val trailX = center - 46
            val leadX = center + 46

            line(Offset(12f, ground), Offset(w - 12, ground), Color.White.copy(alpha = 0.25f), 1f)

            fun glow(x: Float, amount: Float) {
                val gw = 30 + 60 * amount
                val gh = 10 + 14 * amount
                ellipse(
                    Rect(x - gw / 2, ground - gh / 2, x + gw / 2, ground + gh / 2),
                    Brush.radialGradient(listOf(color.copy(alpha = 0.9f), color.copy(alpha = 0f)), Offset(x, ground), 40f),
                    alpha = 0.25f + 0.75f * amount,
                )
            }
            glow(trailX, 1 - leadAnim)
            glow(leadX, leadAnim)

            // Ball (verschwindet nach dem Treffer)
            if (phase.pose.finish <= 0.5f) ball(Offset(center, ground - 4.5f))

            golfer(pose, center, ground, color)

            label("Ziel →", Offset(w - 36, 16f), AppTheme.textTer, 11f, FontWeight.Bold)

            // Prozentwerte unter den Füßen
            fun percent(x: Float, value: Int, caption: String) {
                label("$value %", Offset(x, ground + 16), AppTheme.text, 12f, FontWeight.Bold, mono = true)
                label(caption, Offset(x, ground + 30), AppTheme.textTer, 11f)
            }
            percent(trailX, 100 - phase.lead, "hinten")
            percent(leadX, phase.lead, "vorne")
        }

        // Balken: hinten | vorne
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            BoxWithConstraints(Modifier.fillMaxWidth().height(10.dp)) {
                val trailWidth = maxWidth * (1 - leadAnim)
                Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                    Box(
                        Modifier.width((trailWidth - 1.dp).coerceAtLeast(0.dp)).fillMaxHeight()
                            .background(Color.White.copy(alpha = 0.22f), RoundedCornerShape(5.dp)),
                    )
                    Box(Modifier.weight(1f).fillMaxHeight().background(color, RoundedCornerShape(5.dp)))
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                T("Hinteres Bein", IosFont.caption2, AppTheme.textTer)
                Spacer(Modifier.weight(1f))
                AnimatedContent(phase.hint, transitionSpec = { fadeIn() togetherWith fadeOut() }, label = "hint") {
                    T(it, IosFont.caption2, color)
                }
                Spacer(Modifier.weight(1f))
                T("Vorderes Bein", IosFont.caption2, AppTheme.textTer)
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            weightPhases.forEachIndexed { i, p ->
                Box(
                    Modifier.weight(1f).clip(RoundedCornerShape(50))
                        .background(if (i == index) color else Color.White.copy(alpha = 0.07f))
                        .clickable {
                            Haptics.selection()
                            autoPlay = false
                            index = i
                        }
                        .padding(vertical = 8.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    T(p.name, IosFont.caption, if (i == index) AppTheme.bg else AppTheme.textSec, FontWeight.Bold, maxLines = 1)
                }
            }
        }
    }
}
