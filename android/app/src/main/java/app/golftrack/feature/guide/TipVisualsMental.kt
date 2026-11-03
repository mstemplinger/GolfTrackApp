package app.golftrack.feature.guide

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import app.golftrack.ui.theme.AppTheme
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin

// Nachbau von TipVisualsMental.swift.

// MARK: - Pre-Shot Routine

private val routineSteps = listOf(
    "figure.stand" to "Hinter den Ball stellen",
    "scope" to "Ziellinie sehen",
    "arrow.triangle.2.circlepath" to "Zwei Probeschwünge",
    "figure.walk" to "Einsteigen",
    "line.diagonal.arrow" to "Ausrichtung prüfen",
    "figure.golf" to "Schlagen",
)

/** Sechs Schritte im Kreis, die Markierung läuft immer gleich herum. */
@Composable
internal fun PreShotRoutineVisual(color: Color) {
    val slot = 1.2
    val total = slot * routineSteps.size
    val x = Loop.local(rememberLoopSeconds(), total)
    val current = (x / slot).toInt().coerceIn(0, routineSteps.lastIndex)
    TipVisualCard(230.dp, stage = { w, h ->
        val c = Offset(w / 2, h / 2)
        val r = 80f
        TipCanvas {
            ring(c, r, Color.White.copy(alpha = 0.1f), 3f)
            ds.drawArc(
                color, -90f, (360 * x / total).toFloat(), useCenter = false,
                topLeft = Offset(c.x - r, c.y - r), size = Size(2 * r, 2 * r), style = Stroke(3f, cap = StrokeCap.Round),
            )
        }
        routineSteps.forEachIndexed { i, (icon, _) ->
            val a = (-90 + i * 60.0) * PI / 180
            val active = i == current
            val scale by animateFloatAsState(if (active) 1.18f else 1f, spring(dampingRatio = 0.6f, stiffness = 320f), label = "step$i")
            At((c.x + cos(a) * r).toFloat(), (c.y + sin(a) * r).toFloat()) {
                Box(contentAlignment = Alignment.Center) {
                    // Leuchten statt Schatten um den aktiven Schritt
                    if (active) Box(Modifier.size(50.dp).background(color.copy(alpha = 0.25f), CircleShape))
                    Box(
                        Modifier.size(38.dp).graphicsLayer { scaleX = scale; scaleY = scale }
                            .background(if (i <= current) color else AppTheme.cardAlt, CircleShape),
                        contentAlignment = Alignment.Center,
                    ) { SfIcon(icon, if (i <= current) AppTheme.bg else AppTheme.textSec, 17.dp) }
                }
            }
        }
        At(c.x, c.y) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                DText("${current + 1}", 30f, color, FontWeight.Black)
                DText(routineSteps[current].second, 12f, AppTheme.text, FontWeight.Bold, Modifier.width(100.dp), TextAlign.Center)
            }
        }
    }) {
        TipHint("Jedes Mal gleich – das beruhigt das Nervensystem", color)
    }
}

// MARK: - Einen Schlag nach dem anderen

private class Shot(val icon: String, val name: String, val good: Boolean)

private val oneShots = listOf(
    Shot("figure.golf", "Abschlag", true),
    Shot("xmark", "Ins Rough", false),
    Shot("arrow.up.forward", "Raus aufs Fairway", true),
    Shot("flag.fill", "Aufs Grün", true),
    Shot("circle.circle", "Putt", true),
)

/** Schläge ziehen vorbei: der missglückte wird abgehakt, im Fokus steht nur der nächste. */
@Composable
internal fun OneShotVisual(color: Color) {
    val t = rememberLoopSeconds()
    val s = Loop.step(t, oneShots.size, 1.6, 0.7)
    // Vom letzten Schlag springt die Reihe ohne Zurückspulen an den Anfang
    val pos = s.index + if (s.next == 0) 0.0 else s.f
    TipVisualCard(200.dp, stage = { w, h ->
        val c = Offset(w / 2, h / 2 - 10)
        val ringScale = (1 + 0.06 * sin(t * 2.4)).toFloat()
        At(c.x, c.y) {
            Box(Modifier.size(92.dp).graphicsLayer { scaleX = ringScale; scaleY = ringScale }.border(2.dp, color.copy(alpha = 0.5f), CircleShape))
        }
        oneShots.forEachIndexed { i, shot ->
            val d = i - pos
            val tint = if (shot.good) color else tipRed
            val scale = (1 - min(abs(d), 2.0) * 0.28).toFloat()
            val alpha = max(0.0, 1 - abs(d) * 0.55).toFloat()
            // Position: Kreismitte auf der Mittellinie, Beschriftung darunter
            At((c.x + d * 112).toFloat(), c.y + 14) {
                Column(
                    Modifier.graphicsLayer { scaleX = scale; scaleY = scale; this.alpha = alpha },
                    horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Box(
                        Modifier.size(72.dp).background(
                            if (d < -0.5) AppTheme.cardAlt else tint.copy(alpha = if (abs(d) < 0.5) 1f else 0.25f), CircleShape,
                        ),
                        contentAlignment = Alignment.Center,
                    ) { SfIcon(if (d < -0.5) "checkmark" else shot.icon, if (abs(d) < 0.5) AppTheme.bg else AppTheme.textSec, 30.dp) }
                    DText(shot.name, 12f, AppTheme.text, FontWeight.Bold, maxLines = 1)
                }
            }
        }
    }) {
        val good = oneShots[s.shown].good
        TipHint(if (good) "Nur der nächste Schlag zählt" else "Fehler passiert – durchatmen und abhaken", if (good) color else tipRed)
    }
}

// MARK: - Bogey akzeptieren

private val bogeySteady = listOf(1, 1, 1, 1, 1, 1, 1, 1, 1)
private val bogeyRisky = listOf(0, 2, 0, 3, 1, 0, 2, -1, 3)
private val doubleOrange = rgb(0.98f, 0.56f, 0.08f)

/** Neun Löcher im Vergleich: konstant Bogey gegen Achterbahn mit Doppelbogeys. */
@Composable
internal fun AcceptBogeyVisual(color: Color) {
    val x = Loop.local(rememberLoopSeconds(), 7.5)
    val shown = min(9, (x / 0.38).toInt())
    TipVisualCard(190.dp, stage = { _, _ ->
        Column(
            Modifier.align(Alignment.Center).fillMaxWidth().padding(horizontal = 14.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            BogeyRow("Bogey-Golf", bogeySteady, shown, color)
            BogeyRow("Auf Risiko", bogeyRisky, shown, color)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                BogeyKey(color, "Bogey")
                BogeyKey(doubleOrange, "Doppel")
                BogeyKey(tipRed, "Triple")
            }
        }
    }) {
        TipHint("Wer Doppelbogeys vermeidet, spielt die bessere Runde", color)
    }
}

@Composable
private fun BogeyRow(title: String, scores: List<Int>, shown: Int, color: Color) {
    val total = scores.take(shown).sum()
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            DText(title, 12f, AppTheme.text, FontWeight.Bold)
            Spacer(Modifier.weight(1f))
            DText(if (total >= 0) "+$total" else "$total", 15f, if (shown == 9) AppTheme.text else AppTheme.textSec, FontWeight.Bold)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            for (i in 0 until 9) {
                val v = scores[i]
                val on = i < shown
                val scale by animateFloatAsState(if (on) 1f else 0.7f, spring(dampingRatio = 0.6f, stiffness = 440f), label = "cell$i")
                Box(
                    Modifier.weight(1f).height(26.dp).graphicsLayer { scaleX = scale; scaleY = scale }
                        .background(if (on) bogeyFill(v, color) else Color.White.copy(alpha = 0.06f), RoundedCornerShape(5.dp)),
                    contentAlignment = Alignment.Center,
                ) {
                    if (on) {
                        DText(
                            if (v == 0) "P" else if (v > 0) "+$v" else "$v", 11f,
                            if (v <= 0) AppTheme.text else AppTheme.bg, FontWeight.Bold,
                        )
                    }
                }
            }
        }
    }
}

private fun bogeyFill(v: Int, color: Color): Color = when {
    v < 0 -> AppTheme.green
    v == 0 -> Color.White.copy(alpha = 0.18f)
    v == 1 -> color
    v == 2 -> doubleOrange
    else -> tipRed
}

@Composable
private fun BogeyKey(c: Color, text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(10.dp).background(c, RoundedCornerShape(2.dp)))
        DText(text, 11f, AppTheme.textTer)
    }
}

// MARK: - Visualisierung

/** Erst die Flugbahn im Kopf zeichnen, dann den Ball genau so fliegen lassen. */
@Composable
internal fun VisualizationVisual(color: Color) {
    val x = Loop.local(rememberLoopSeconds(), 6.0)
    val phase = if (x < 1.8) 0 else if (x < 2.7) 1 else 2
    TipVisualCard(200.dp, stage = { _, _ ->
        TipCanvas {
            val ground = h - 34
            val ball = Offset(36f, ground - 4.5f)
            val land = Offset(w - 84, ground - 4.5f)
            val pin = Offset(w - 56, ground)
            val control = Offset((ball.x + land.x) / 2, 0f)

            line(Offset(10f, ground), Offset(w - 10, ground), Color.White.copy(alpha = 0.25f), 1f)
            ellipse(Rect(pin.x - 50, ground - 3, pin.x + 50, ground + 5), AppTheme.green)
            flag(pin, color, 40f)

            // Gedachte Flugbahn
            val sketch = Loop.ramp(x, 0.2, 1.6)
            val ghostAlpha = (1 - Loop.ramp(x, 4.6, 5.6)).toFloat()
            stroke(quadPath(ball, control, land, sketch), Color.White.copy(alpha = 0.55f * ghostAlpha), 1.6f, floatArrayOf(3f, 5f))
            // Landepunkt
            if (x > 1.8) {
                val pulse = Loop.ramp(x, 1.8, 2.6).toFloat()
                ring(land, 6 + 10 * pulse, color.copy(alpha = ghostAlpha * (1 - pulse * 0.5f)), 2f)
            }
            // Echter Ball
            val fly = Loop.ramp(x, 2.8, 4.1)
            var p = ball
            if (x >= 2.8 && x < 4.1) {
                p = quadPoint(ball, control, land, fly)
                stroke(quadPath(ball, control, land, fly), color, 2.2f)
            } else if (x >= 4.1) {
                val roll = Loop.ramp(x, 4.1, 4.7).toFloat()
                p = Offset(land.x + (pin.x - 8 - land.x) * roll, land.y)
                stroke(quadPath(ball, control, land, 1.0), color.copy(alpha = ghostAlpha), 2.2f)
            }
            ball(p)
        }
        // Gedankenblase beim Sehen
        if (phase < 2) At(30f, 28f) { SfIcon("brain.head.profile", color, 24.dp) }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            TipHint(
                listOf(
                    "Ziel und Flugbahn vor dem inneren Auge zeichnen",
                    "Den Ball landen sehen",
                    "Der Körper schlägt, was der Kopf gesehen hat",
                )[phase],
                color,
            )
            PhasePills(listOf("Flugbahn sehen", "Landung sehen", "Schlagen"), phase, color)
        }
    }
}

// MARK: - Umgang mit Druck

/** Atemkreis: 4 s ein, 2 s halten, 6 s aus – der Puls sinkt. */
@Composable
internal fun PressureVisual(color: Color) {
    val t = rememberLoopSeconds()
    val x = Loop.local(t, 12.0)
    val scale = when {
        x < 4 -> Loop.lerp(0.55, 1.0, Loop.smooth(x / 4))
        x < 6 -> 1.0
        else -> Loop.lerp(1.0, 0.55, Loop.smooth((x - 6) / 6))
    }.toFloat()
    val bpm = if (x < 6) Loop.lerp(84.0, 98.0, Loop.smooth(x / 6)) else Loop.lerp(98.0, 84.0, Loop.smooth((x - 6) / 6))
    val label = if (x < 4) "Einatmen" else if (x < 6) "Halten" else "Ausatmen"
    val left = if (x < 4) 4 - x else if (x < 6) 6 - x else 12 - x
    val beat = max(0.0, sin(t * PI * 2 * bpm / 60)).pow(12).toFloat()
    TipVisualCard(220.dp, stage = { _, _ ->
        TipCanvas {
            val c = Offset(w / 2, h / 2)
            val r = 90 * scale
            // Verlauf von innen (Radius 10) nach außen (Radius 100), mitskaliert
            ds.drawCircle(
                Brush.radialGradient(
                    0f to color.copy(alpha = 0.55f), 0.1f to color.copy(alpha = 0.55f), 1f to color.copy(alpha = 0.08f),
                    center = c, radius = 100 * scale,
                ),
                r, c,
            )
            ring(c, r, color.copy(alpha = 0.6f), 2f)
            label(label, Offset(c.x, c.y - 9), AppTheme.text, 17f, FontWeight.SemiBold)
            label("${ceil(left).toInt()} s", Offset(c.x, c.y + 12), AppTheme.textSec, 12f, FontWeight.Bold, mono = true)
        }
        Row(
            Modifier.align(Alignment.TopEnd).padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically,
        ) {
            val s = 1 + 0.25f * beat
            Box(Modifier.graphicsLayer { scaleX = s; scaleY = s }) { SfIcon("heart.fill", tipRed, 16.dp) }
            DText("${bpm.toInt()} bpm", 12f, AppTheme.textSec, FontWeight.Bold)
        }
    }) {
        TipHint("Langsam ausatmen senkt den Puls – Nervosität ist Energie", color)
    }
}
