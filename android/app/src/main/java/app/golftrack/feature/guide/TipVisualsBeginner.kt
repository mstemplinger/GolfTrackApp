package app.golftrack.feature.guide

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotateRad
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.golftrack.ui.theme.AppTheme
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sin

// Nachbau von TipVisualsBeginner.swift.

// MARK: - Griff entspannen

/** Druckanzeige 1–10: Zeiger springt von „zu fest“ in den lockeren Bereich. */
@Composable
internal fun GripVisual(color: Color) {
    val s = Loop.step(rememberLoopSeconds(), 2, 2.2, 1.1)
    val value = Loop.value(listOf(9.0, 4.5), s)
    TipVisualCard(200.dp, stage = { w, h ->
        val c = Offset(w / 2, h - 44)
        TipCanvas {
            val r = 100f
            fun angle(v: Double) = (180 + (v - 1) / 9 * 180).toFloat()
            fun arc(a: Double, b: Double, col: Color) = ds.drawArc(
                col, angle(a), angle(b) - angle(a), useCenter = false,
                topLeft = Offset(c.x - r, c.y - r), size = Size(2 * r, 2 * r), style = Stroke(14f, cap = StrokeCap.Butt),
            )
            arc(1.0, 3.2, Color.White.copy(alpha = 0.18f))
            arc(3.3, 6.2, color)
            arc(6.3, 10.0, tipRed.copy(alpha = 0.8f))
            for (v in 1..10) {
                val a = angle(v.toDouble()) * PI / 180
                val p1 = pt(c.x + cos(a) * (r - 13), c.y + sin(a) * (r - 13))
                val p2 = pt(c.x + cos(a) * (r - 19), c.y + sin(a) * (r - 19))
                line(p1, p2, Color.White.copy(alpha = 0.35f), 1.5f)
            }
            val a = angle(value) * PI / 180
            line(c, pt(c.x + cos(a) * (r - 8), c.y + sin(a) * (r - 8)), Color.White, 3.5f)
            circle(c, 8f, Color.White)
            circle(c, 3.5f, AppTheme.bg)
            label("locker", Offset(c.x - 100, c.y + 18), AppTheme.textTer)
            label("fest", Offset(c.x + 100, c.y + 18), AppTheme.textTer)
            label("Griffdruck ${value.roundToInt()} / 10", Offset(c.x, c.y + 26), AppTheme.text, 12f, FontWeight.Bold, mono = true)
        }
        At(c.x, c.y - 140) { SfIcon("bird.fill", color, 20.dp) }
    }) {
        TipHint(
            if (s.shown == 0) "Zu fest: Handgelenke blockieren, Distanz geht verloren" else "Wie einen Vogel halten – fest genug, aber locker",
            if (s.shown == 0) tipRed else color,
        )
    }
}

// MARK: - Standfläche prüfen

/** Draufsicht: Fußabstand und Ballposition je nach Schläger. */
@Composable
internal fun StanceVisual(color: Color) {
    val s = Loop.step(rememberLoopSeconds(), 3, 2.0, 0.9)
    val half = Loop.value(listOf(30.0, 42.0, 56.0), s).toFloat()   // halber Fußabstand
    val ballX = Loop.value(listOf(0.0, 10.0, 38.0), s).toFloat()   // Ball relativ zur Mitte
    TipVisualCard(210.dp, stage = { _, _ ->
        TipCanvas {
            val cx = w / 2
            val shoulderY = 58f
            val feetY = 112f
            val ballY = 168f
            val shoulder = 42f

            // Schulterbreite als Hilfslinien
            for (dx in listOf(-shoulder, shoulder)) {
                line(Offset(cx + dx, shoulderY), Offset(cx + dx, ballY + 18), Color.White.copy(alpha = 0.25f), 1f, floatArrayOf(3f, 4f))
            }
            // Oberkörper von oben: Schultern und Kopf
            line(Offset(cx - shoulder, shoulderY), Offset(cx + shoulder, shoulderY), white(0.96f), 16f)
            circle(Offset(cx, shoulderY + 2), 13f, color)

            // Füße, Spitzen leicht nach außen
            for (side in listOf(-1f, 1f)) {
                val c = Offset(cx + side * half, feetY)
                ds.rotateRad(-side * 0.2f, pivot = c) {
                    drawRoundRect(Color.White, Offset(c.x - 8, c.y - 17), Size(16f, 34f), CornerRadius(8f, 8f))
                }
            }
            // Maß zwischen den Füßen
            val my = feetY + 30
            line(Offset(cx - half, my), Offset(cx + half, my), color, 1.5f)
            for (side in listOf(-1f, 1f)) {
                line(Offset(cx + side * half, my - 5), Offset(cx + side * half, my + 5), color, 1.5f)
            }
            // Schläger und Ball
            val ball = Offset(cx + ballX, ballY)
            line(Offset(cx, shoulderY + 22), Offset(ball.x - 4, ball.y - 8), white(0.75f), 2.2f)
            ball(ball, 5f)

            label("Ziel →", Offset(w - 30, 16f), AppTheme.textTer, 11f, FontWeight.Bold)
        }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            TipHint(
                listOf("Etwas enger, Ball in der Mitte", "Schulterbreit, Ball leicht vorne", "Breiter, Ball an der vorderen Ferse")[s.shown],
                color,
            )
            PhasePills(listOf("Kurzes Eisen", "Mittleres Eisen", "Holz / Driver"), s.shown, color)
        }
    }
}

// MARK: - Auge auf dem Ball

private val eyeFrames = listOf(
    0.0 to GolferPose.address, 0.8 to GolferPose.address, 2.0 to GolferPose.top, 2.5 to GolferPose.finished,
    3.7 to GolferPose.finished, 4.6 to GolferPose.address, 5.0 to GolferPose.address,
)

/** Schwung mit Blicklinie: Kopf bleibt ruhig, der Blick bleibt auch nach dem Treffer am Punkt. */
@Composable
internal fun EyeOnBallVisual(color: Color) {
    val x = Loop.local(rememberLoopSeconds(), 5.0)
    val pose = GolferPose.keyframes(eyeFrames, x).steady(0.25f)
    val hit = x > 2.25 && x < 4.5
    TipVisualCard(240.dp, stage = { _, _ ->
        TipCanvas {
            val center = w / 2
            val ground = h - 30
            val j = GolferJoints(pose, center, ground)
            val ball = Offset(center, ground - 4.5f)
            // Blick hängt nach dem Treffer noch kurz am Punkt, dann geht der Kopf mit
            val gaze = (1 - Loop.ramp(x, 2.9, 3.3)).toFloat()
            groundLine(ground)
            // Kopfhöhe als Referenz
            val headY = GolferJoints(GolferPose.address, center, ground).head.y
            line(Offset(center - 70, headY - 12), Offset(center + 70, headY - 12), Color.White.copy(alpha = 0.18f), 1f, floatArrayOf(4f, 4f))
            golfer(pose, center, ground, color)
            if (!hit) ball(ball)
            val eye = Offset(j.head.x + 4, j.head.y + 4)
            line(eye, ball, color.copy(alpha = gaze), 2.2f, floatArrayOf(3f, 4f))
            ring(ball, (9 + 2 * sin(x * 6)).toFloat(), color.copy(alpha = gaze), 1.6f)
        }
    }) {
        TipHint(if (hit) "Kopf unten lassen, bis der Ball weg ist" else "Einen Punkt am Ball fixieren", color)
    }
}

// MARK: - Tempo ist alles

private val tempoFrames = listOf(
    0.0 to GolferPose.address, 0.4 to GolferPose.address, 1.9 to GolferPose.top, 2.4 to GolferPose.finished,
    3.5 to GolferPose.finished, 4.4 to GolferPose.address, 4.8 to GolferPose.address,
)

/** Rückschwung dreimal so lang wie der Durchschwung, mit Taktpunkten. */
@Composable
internal fun TempoVisual(color: Color) {
    val x = Loop.local(rememberLoopSeconds(), 4.8)
    val pose = GolferPose.keyframes(tempoFrames, x)
    val beats = listOf(0.9, 1.4, 1.9, 2.15)
    TipVisualCard(240.dp, stage = { _, _ ->
        TipCanvas {
            val center = w / 2
            val ground = h - 30
            groundLine(ground)
            golfer(pose, center, ground, color)
            if (!(x > 2.15 && x < 4.4)) ball(Offset(center, ground - 4.5f))
            label("3 : 1", Offset(40f, 30f), color.copy(alpha = 0.85f), 26f, FontWeight.Black)
        }
    }) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            beats.forEachIndexed { i, beat ->
                val on = x >= beat && x < 4.0
                val d = if (i == 3) 16.dp else 12.dp
                Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(5.dp)) {
                    val scale = if (on && x - beat < 0.15) 1.3f else 1f
                    Box(
                        Modifier.size(d).graphicsLayer { scaleX = scale; scaleY = scale }
                            .background(if (on) color else Color.White.copy(alpha = 0.12f), CircleShape),
                    )
                    T(listOf("eins", "zwei", "drei", "Schlag")[i], IosFont.caption2, if (on) AppTheme.text else AppTheme.textTer, FontWeight.Bold)
                }
                if (i == 2) Box(Modifier.width(1.dp).height(28.dp).background(Color.White.copy(alpha = 0.15f)))
            }
        }
    }
}

// MARK: - Chip-Technik

private val chipBase = GolferPose(6f, 90f, 90f, 0f)
private val chipBack = GolferPose(6f, 120f, 114f, 0f)
private val chipThrough = GolferPose(7f, 62f, 64f, 0f)
private val chipFrames = listOf(
    0.0 to chipBase, 0.5 to chipBase, 1.3 to chipBack, 1.75 to chipThrough, 2.9 to chipThrough, 3.6 to chipBase, 4.0 to chipBase,
)

/** Kurze Pendelbewegung aus den Schultern, Dreieck bleibt fest, Ball rollt aus. */
@Composable
internal fun ChipVisual(color: Color) {
    val x = Loop.local(rememberLoopSeconds(), 4.0)
    val pose = GolferPose.keyframes(chipFrames, x)
    TipVisualCard(240.dp, stage = { _, _ ->
        TipCanvas {
            val center = w / 2 - 30
            val ground = h - 30
            val j = GolferJoints(pose, center, ground)
            groundLine(ground)
            flag(Offset(w - 34, ground), color, 40f)
            golfer(pose, center, ground, color)

            // Dreieck Schultern–Hände
            val tri = Path().apply {
                moveTo(j.trailShoulder.x, j.trailShoulder.y)
                lineTo(j.leadShoulder.x, j.leadShoulder.y)
                lineTo(j.hands.x, j.hands.y)
                close()
            }
            fill(tri, color.copy(alpha = 0.18f))
            stroke(tri, color, 1.5f, floatArrayOf(4f, 3f), StrokeCap.Butt)

            // Ball: kurzer Flug, dann Rollen
            val start = Offset(center, ground - 4.5f)
            val end = Offset(w - 48, ground - 4.5f)
            val land = Offset(center + (end.x - center) * 0.35f, start.y)
            var ball = start
            if (x > 1.52 && x < 3.4) {
                val fly = Loop.ramp(x, 1.52, 1.95)
                ball = if (fly < 1) {
                    quadPoint(start, Offset((start.x + land.x) / 2, start.y - 34), land, fly)
                } else {
                    val roll = (1 - (1 - min((x - 1.95) / 1.0, 1.0)).pow(2)).toFloat()
                    Offset(land.x + (end.x - land.x) * roll, start.y)
                }
            }
            if (x < 3.4) ball(ball)
            label("60 % vorne", Offset(center + 46, ground + 16), AppTheme.textSec, 11f, FontWeight.Bold)
        }
    }) {
        TipHint("Pendel aus den Schultern – das Dreieck bleibt fest", color)
    }
}
