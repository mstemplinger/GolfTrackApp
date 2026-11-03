package app.golftrack.feature.guide

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.golftrack.ui.theme.AppTheme
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

// Nachbau von TipVisualsTechnique.swift.

// MARK: - Schwungachse halten

private val axisFrames = listOf(
    0.0 to GolferPose.address, 0.7 to GolferPose.address, 1.9 to GolferPose.top, 2.4 to GolferPose.finished,
    3.5 to GolferPose.finished, 4.4 to GolferPose.address, 4.8 to GolferPose.address,
)

/** Schwung um eine feste Achse durch Kopf und Hüfte. */
@Composable
internal fun SpineAxisVisual(color: Color) {
    val x = Loop.local(rememberLoopSeconds(), 4.8)
    val pose = GolferPose.keyframes(axisFrames, x).steady(0.15f)
    TipVisualCard(240.dp, stage = { _, _ ->
        TipCanvas {
            val center = w / 2
            val ground = h - 30
            val a = GolferJoints(GolferPose.address, center, ground)
            groundLine(ground)
            golfer(pose, center, ground, color)

            val top = Offset(center, a.head.y - 26)
            val bottom = Offset(center, a.trailHip.y + 14)
            line(top, bottom, color, 2f, floatArrayOf(6f, 4f))
            // Drehpfeil um die Achse auf Brusthöhe
            val y = a.trailShoulder.y + 22
            val sweep = Loop.ramp(x, 0.7, 1.9) - Loop.ramp(x, 1.9, 2.4) * 2
            strokeEllipse(Rect(center - 34, y - 7, center + 34, y + 7), color.copy(alpha = 0.35f), 1.5f)
            val t = PI / 2 + sweep * PI
            circle(pt(center + cos(t) * 34, y + sin(t) * 7), 4f, color)
            circle(top, 4f, color)
            circle(bottom, 4f, color)
            label("Achse", Offset(center + 52, a.trailHip.y + 14), color, 11f, FontWeight.Bold)
        }
    }) {
        TipHint("In der Vorbeuge bleiben – die Schultern drehen um die Achse", color)
    }
}

// MARK: - Hüftrotation

/** Draufsicht: Hüfte (dunkel) startet den Durchschwung, Schultern (hell) folgen. */
@Composable
internal fun HipRotationVisual(color: Color) {
    val s = Loop.step(rememberLoopSeconds(), 4, 1.1, 0.7)
    val hip = Loop.value(listOf(-45.0, -15.0, 35.0, 80.0), s)
    val shoulder = Loop.value(listOf(-90.0, -80.0, 10.0, 100.0), s)
    TipVisualCard(210.dp, stage = { _, _ ->
        TipCanvas {
            val c = Offset(w / 2, h / 2 - 6)
            fun bar(angle: Double, length: Float, col: Color, width: Float) {
                val r = angle * PI / 180
                val dx = (cos(r) * length / 2).toFloat()
                val dy = (sin(r) * length / 2).toFloat()
                line(Offset(c.x - dx, c.y - dy), Offset(c.x + dx, c.y + dy), col, width)
            }
            // Ausgangsstellung parallel zur Ziellinie
            line(Offset(c.x - 70, c.y), Offset(c.x + 70, c.y), Color.White.copy(alpha = 0.2f), 1f, floatArrayOf(4f, 4f))
            bar(shoulder, 112f, white(0.96f), 16f)
            bar(hip, 70f, rgb(0.30f, 0.34f, 0.42f), 18f)
            circle(c, 14f, color)
            // Ball vor dem Golfer
            ball(Offset(c.x, c.y + 70), 5f)
            label("Ziel →", Offset(w - 30, 16f), AppTheme.textTer, 11f, FontWeight.Bold)
            label("Draufsicht", Offset(40f, 16f), AppTheme.textTer)
        }
        Row(
            Modifier.align(Alignment.BottomCenter).padding(bottom = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            HipLegend(white(0.96f), "Schultern ${abs(shoulder).roundToInt()}°")
            HipLegend(rgb(0.42f, 0.47f, 0.56f), "Hüfte ${abs(hip).roundToInt()}°")
        }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            TipHint(
                listOf(
                    "Ausholen: Schultern drehen weiter als die Hüfte",
                    "Die Hüfte dreht zuerst zum Ziel",
                    "Arme und Schultern folgen von selbst",
                    "Hüfte und Brust zeigen zum Ziel",
                )[s.shown],
                color,
            )
            PhasePills(listOf("Ausholen", "Hüfte startet", "Treffen", "Finish"), s.shown, color)
        }
    }
}

@Composable
private fun HipLegend(c: Color, text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(14.dp, 6.dp).background(c, RoundedCornerShape(50)))
        DText(text, 11f, AppTheme.textSec, FontWeight.Bold)
    }
}

// MARK: - Flaches Anspiel

/**
 * Draufsicht: Der Golfer steht oben, „innen“ ist seine Körperseite der Ziellinie.
 * Abwechselnd die Bahn von innen nach außen (Draw) und von außen nach innen (Slice).
 */
@Composable
internal fun SwingPathVisual(color: Color) {
    val period = 4.2
    val t = rememberLoopSeconds()
    val good = (t / period).toLong() % 2 == 0L
    val x = Loop.local(t, period)
    val col = if (good) color else tipRed
    TipVisualCard(230.dp, stage = { _, _ ->
        TipCanvas {
            val lineY = 132f
            val ball = Offset(122f, lineY)
            val flag = Offset(w - 34, lineY)

            // Seiten der Ziellinie
            ds.drawRect(Color.White.copy(alpha = 0.05f), Offset.Zero, Size(w, lineY))
            label("innen", Offset(14f, lineY - 14), AppTheme.textSec, 12f, FontWeight.Bold, ax = 0f)
            label("außen", Offset(14f, lineY + 16), AppTheme.textSec, 12f, FontWeight.Bold, ax = 0f)

            // Golfer von oben: Schultern und Kappe, Blick zum Ball
            val body = Offset(ball.x, 40f)
            line(Offset(body.x - 34, body.y), Offset(body.x + 34, body.y), white(0.96f), 16f)
            circle(body, 12f, color)
            line(Offset(body.x - 12, body.y + 9), Offset(body.x + 12, body.y + 9), color, 3f)
            label("Du", Offset(body.x + 44, body.y), AppTheme.textTer, ax = 0f)

            // Ziellinie zur Fahne
            line(Offset(64f, lineY), Offset(w - 20, lineY), Color.White.copy(alpha = 0.35f), 1.2f, floatArrayOf(5f, 5f))
            circle(flag, 10f, AppTheme.green.copy(alpha = 0.9f))
            flag(flag, color, 26f)
            label("Ziellinie", Offset((ball.x + flag.x) / 2, lineY - 9), AppTheme.textTer)

            // Schlägerbahn mit Pfeil
            val from = if (good) Offset(ball.x - 62, lineY - 44) else Offset(ball.x - 62, lineY + 44)
            val to = if (good) Offset(ball.x + 62, lineY + 44) else Offset(ball.x + 62, lineY - 44)
            line(from, to, col.copy(alpha = 0.4f), 2f, floatArrayOf(4f, 4f))
            val ang = atan2((to.y - from.y).toDouble(), (to.x - from.x).toDouble())
            for (d in listOf(-0.5, 0.5)) {
                line(to, pt(to.x - 11 * cos(ang + d), to.y - 11 * sin(ang + d)), col.copy(alpha = 0.6f), 2f)
            }
            val swing = Loop.ramp(x, 0.3, 1.2).toFloat()
            val head = Offset(from.x + (to.x - from.x) * swing, from.y + (to.y - from.y) * swing)
            if (x > 0.3) line(from, head, col, 3.5f)
            if (swing > 0 && swing < 1) {
                ds.drawRoundRect(white(0.88f), Offset(head.x - 4, head.y - 11), Size(8f, 22f), CornerRadius(3f, 3f))
            }

            // Ballflug: Draw zurück zur Fahne bzw. Slice weg
            val fly = Loop.ramp(x, 0.8, 2.6)
            val end = if (good) flag else Offset(flag.x - 24, lineY + 70)
            val control = if (good) Offset((ball.x + flag.x) / 2, lineY + 58) else Offset((ball.x + flag.x) / 2, lineY - 58)
            if (x > 0.8) stroke(quadPath(ball, control, end, fly), col, 2f)
            ball(if (x > 0.8) quadPoint(ball, control, end, fly) else ball, 5f)
            if (x > 2.6) {
                label(
                    if (good) "Draw" else "Slice", Offset(end.x - 6, end.y + if (good) 22 else -14), col, 12f, FontWeight.Bold, ax = 1f,
                )
            }
        }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            TipHint(
                if (good) "Richtig: Schläger kommt von innen und schwingt nach außen durch"
                else "Falsch: Schläger kommt von außen quer über den Ball",
                col,
            )
            PhasePills(listOf("Von innen (Inside-Out)", "Von außen (Over the Top)"), if (good) 0 else 1, col)
        }
    }
}

// MARK: - Trefferfläche kontrollieren

private class Hit(val x: Float, val y: Float, val distance: Int, val name: String)

private val impactHits = listOf(
    Hit(0f, 2f, 100, "Mitte"),
    Hit(34f, -4f, 88, "Spitze"),
    Hit(-3f, -6f, 98, "fast Mitte"),
    Hit(-36f, 6f, 86, "Ferse"),
    Hit(4f, 4f, 100, "Mitte"),
)

/** Schlagfläche mit Treffermarken und der Distanz, die jeder Treffer bringt. */
@Composable
internal fun ImpactVisual(color: Color) {
    val slot = 1.5
    val x = Loop.local(rememberLoopSeconds(), slot * impactHits.size)
    val current = (x / slot).toInt().coerceIn(0, impactHits.lastIndex)
    val pop = Loop.ramp(x - current * slot, 0.0, 0.25).toFloat()
    val hit = impactHits[current]
    val good = hit.distance >= 98
    val barColor = if (good) color else tipRed
    val fraction by animateFloatAsState((hit.distance - 75) / 25f, spring(dampingRatio = 0.8f, stiffness = 160f), label = "impact")
    TipVisualCard(200.dp, stage = { _, _ ->
        TipCanvas {
            val c = Offset(w / 2, h / 2 - 4)
            // Eisen-Schlagfläche
            val face = Path().apply {
                moveTo(c.x - 92, c.y - 22)
                quadraticTo(c.x, c.y - 40, c.x + 96, c.y - 44)
                quadraticTo(c.x + 112, c.y + 20, c.x + 86, c.y + 40)
                lineTo(c.x - 88, c.y + 38)
                quadraticTo(c.x - 100, c.y + 10, c.x - 92, c.y - 22)
                close()
            }
            fill(face, Brush.verticalGradient(listOf(white(0.86f), white(0.62f)), startY = c.y - 44, endY = c.y + 40))
            // Schaft
            line(Offset(c.x - 92, c.y - 20), Offset(c.x - 120, c.y - 92), white(0.7f), 6f)
            // Rillen
            for (i in 0 until 6) {
                val y = c.y - 22 + i * 10
                line(Offset(c.x - 70, y), Offset(c.x + 76, y - 3), Color.Black.copy(alpha = 0.18f), 1.2f)
            }
            // Sweetspot
            ellipse(
                Rect(c.x - 26, c.y - 20, c.x + 26, c.y + 20),
                Brush.radialGradient(listOf(color.copy(alpha = 0.55f), color.copy(alpha = 0f)), c, 26f),
            )
            // Treffer bis jetzt
            for (i in 0..current) {
                val p = Offset(c.x + impactHits[i].x, c.y + impactHits[i].y)
                val isNow = i == current
                val r = if (isNow) 4 + 5 * (1 - pop) + 2 else 4f
                circle(p, r, if (isNow) AppTheme.bg else AppTheme.bg.copy(alpha = 0.35f))
                if (isNow) ring(p, 10 + 10 * pop, color.copy(alpha = 1 - pop), 2f)
            }
        }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                T(hit.name, IosFont.caption, AppTheme.text, FontWeight.Bold)
                Spacer(Modifier.weight(1f))
                T("${hit.distance} % Distanz", IosFont.caption, barColor, FontWeight.Bold)
            }
            Box(Modifier.fillMaxWidth().height(8.dp).background(Color.White.copy(alpha = 0.1f), RoundedCornerShape(50))) {
                Box(Modifier.fillMaxWidth(fraction.coerceIn(0f, 1f)).fillMaxHeight().background(barColor, RoundedCornerShape(50)))
            }
            T("Außerhalb der Mitte gehen 10–15 % Länge verloren", IosFont.caption2, AppTheme.textTer)
        }
    }
}
