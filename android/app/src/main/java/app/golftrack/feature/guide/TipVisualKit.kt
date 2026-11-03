package app.golftrack.feature.guide

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotateRad
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.ui.theme.AppTheme
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

// Nachbau von TipVisualKit.swift: Rahmen, Zeitsteuerung, Golfer-Figur und Zeichenhilfen.
// Alle Koordinaten in dp (wie Punkte auf iOS).

internal val tipRed = rgb(0.92f, 0.32f, 0.28f)

// MARK: - Rahmen

/** Gemeinsamer Rahmen aller Tipp-Grafiken: Bühne mit Rasenverlauf, darunter Fußzeile. */
@Composable
internal fun TipVisualCard(
    height: Dp = 220.dp,
    stage: @Composable BoxScope.(w: Float, h: Float) -> Unit,
    footer: @Composable ColumnScope.() -> Unit,
) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        BoxWithConstraints(
            Modifier.fillMaxWidth().height(height).clip(RoundedCornerShape(12.dp)).background(lawnGradient).clipToBounds(),
        ) { stage(maxWidth.value, maxHeight.value) }
        footer()
    }
}

internal val lawnGradient = Brush.verticalGradient(listOf(AppTheme.green.copy(alpha = 0f), AppTheme.green.copy(alpha = 0.35f)))

/** Phasenanzeige unter einer Grafik (folgt der Animation, nicht antippbar). */
@Composable
internal fun PhasePills(labels: List<String>, active: Int, color: Color) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        labels.forEachIndexed { i, label ->
            Box(
                Modifier.weight(1f).background(if (i == active) color else Color.White.copy(alpha = 0.07f), RoundedCornerShape(50))
                    .padding(vertical = 7.dp, horizontal = 4.dp),
                contentAlignment = Alignment.Center,
            ) {
                BasicText(
                    label, maxLines = 1,
                    style = TextStyle(
                        color = if (i == active) AppTheme.bg else AppTheme.textSec,
                        fontWeight = FontWeight.Bold, textAlign = TextAlign.Center,
                    ),
                    autoSize = TextAutoSize.StepBased(minFontSize = 8.sp, maxFontSize = IosFont.caption2),
                )
            }
        }
    }
}

/** Einzeiliger Hinweis in Akzentfarbe, z. B. was gerade passiert. */
@Composable
internal fun TipHint(text: String, color: Color) {
    T(text, IosFont.caption, color, FontWeight.Bold, modifier = Modifier.fillMaxWidth(), align = TextAlign.Center)
}

// MARK: - Zeitsteuerung

/** Sekunden seit 1970, jedes Bild neu – Ersatz für `TimelineView(.animation)`. */
@Composable
internal fun rememberLoopSeconds(): Double {
    var t by remember { mutableDoubleStateOf(System.currentTimeMillis() / 1000.0) }
    LaunchedEffect(Unit) {
        while (true) {
            withFrameNanos { }
            t = System.currentTimeMillis() / 1000.0
        }
    }
    return t
}

/** Hilfen für zeitgesteuerte Endlosschleifen. */
internal object Loop {
    /** Position innerhalb einer Periode in Sekunden. */
    fun local(t: Double, period: Double): Double = t % period

    fun smooth(x: Double): Double {
        val c = x.coerceIn(0.0, 1.0)
        return c * c * (3 - 2 * c)
    }

    /** Weicher Verlauf 0…1 zwischen den Zeitpunkten a und b. */
    fun ramp(x: Double, a: Double, b: Double): Double = smooth((x - a) / (b - a))

    fun lerp(a: Double, b: Double, f: Double): Double = a + (b - a) * f

    data class Step(val index: Int, val next: Int, val f: Double, val shown: Int)

    /** Stationen nacheinander: je `hold` Sekunden stehen, dann `move` Sekunden Übergang. */
    fun step(t: Double, count: Int, hold: Double, move: Double): Step {
        val slot = hold + move
        val x = local(t, slot * count)
        val i = min((x / slot).toInt(), count - 1)
        val r = x - i * slot
        val f = if (r < hold) 0.0 else smooth((r - hold) / move)
        val next = (i + 1) % count
        return Step(i, next, f, if (f > 0.5) next else i)
    }

    /** Wert zwischen den Stationen aus `step`. */
    fun value(values: List<Double>, s: Step): Double = lerp(values[s.index], values[s.next], s.f)
}

// MARK: - Zeichenfläche

/** Zeichenfläche in dp-Koordinaten mit Text-Unterstützung. */
@Composable
internal fun TipCanvas(modifier: Modifier = Modifier.fillMaxSize(), draw: TipDraw.() -> Unit) {
    val tm = rememberTextMeasurer()
    Canvas(modifier) {
        val k = density
        val w = size.width / k
        val h = size.height / k
        scale(k, k, pivot = Offset.Zero) { TipDraw(this, tm, w, h).draw() }
    }
}

internal fun pt(x: Float, y: Float) = Offset(x, y)
internal fun pt(x: Double, y: Double) = Offset(x.toFloat(), y.toFloat())

internal class TipDraw(val ds: DrawScope, private val tm: TextMeasurer, val w: Float, val h: Float) {
    private fun stroke(width: Float, dash: FloatArray?, cap: StrokeCap = StrokeCap.Round) =
        Stroke(width, cap = cap, join = StrokeJoin.Round, pathEffect = dash?.let { PathEffect.dashPathEffect(it) })

    /** Linie mit runden Enden. */
    fun line(points: List<Offset>, color: Color, width: Float, dash: FloatArray? = null) {
        val p = Path().apply {
            moveTo(points[0].x, points[0].y)
            points.drop(1).forEach { lineTo(it.x, it.y) }
        }
        ds.drawPath(p, color, style = stroke(width, dash))
    }

    fun line(a: Offset, b: Offset, color: Color, width: Float, dash: FloatArray? = null) = line(listOf(a, b), color, width, dash)

    fun circle(c: Offset, r: Float, color: Color) = ds.drawCircle(color, r, c)

    fun ring(c: Offset, r: Float, color: Color, width: Float, dash: FloatArray? = null) =
        ds.drawCircle(color, r, c, style = stroke(width, dash, StrokeCap.Butt))

    fun ellipse(rect: Rect, color: Color) = ds.drawOval(color, rect.topLeft, rect.size)
    fun ellipse(rect: Rect, brush: Brush, alpha: Float = 1f) = ds.drawOval(brush, rect.topLeft, rect.size, alpha)
    fun strokeEllipse(rect: Rect, color: Color, width: Float, dash: FloatArray? = null) =
        ds.drawOval(color, rect.topLeft, rect.size, style = stroke(width, dash, StrokeCap.Butt))

    fun roundRect(rect: Rect, radius: Float, color: Color) =
        ds.drawRoundRect(color, rect.topLeft, rect.size, CornerRadius(radius, radius))

    fun fill(path: Path, color: Color) = ds.drawPath(path, color)
    fun fill(path: Path, brush: Brush) = ds.drawPath(path, brush)
    fun stroke(path: Path, color: Color, width: Float, dash: FloatArray? = null, cap: StrokeCap = StrokeCap.Round) =
        ds.drawPath(path, color, style = stroke(width, dash, cap))

    /** Golfball mit leichtem Schatten. */
    fun ball(c: Offset, r: Float = 4.5f) {
        circle(Offset(c.x + 0.6f, c.y + 1.2f), r, Color.Black.copy(alpha = 0.35f))
        circle(c, r, Color.White)
    }

    /** Fahne mit Loch, Fuß bei `base`. */
    fun flag(base: Offset, color: Color, height: Float = 34f) {
        ellipse(Rect(base.x - 6, base.y - 2, base.x + 6, base.y + 2), Color.Black.copy(alpha = 0.5f))
        line(base, Offset(base.x, base.y - height), white(0.9f), 1.6f)
        val f = Path().apply {
            moveTo(base.x, base.y - height)
            lineTo(base.x + 14, base.y - height + 5)
            lineTo(base.x, base.y - height + 10)
            close()
        }
        fill(f, color)
    }

    /**
     * Text an einer Stelle zeichnen. `ax`/`ay` legen den Ankerpunkt fest
     * (0.5/0.5 = Mitte, 0 = links, 1 = rechts).
     */
    fun label(
        text: String, at: Offset, color: Color, size: Float = 11f, weight: FontWeight = FontWeight.Normal,
        ax: Float = 0.5f, ay: Float = 0.5f, mono: Boolean = false, rounded: Boolean = false,
    ) {
        val k = ds.density
        val layout = tm.measure(
            text,
            TextStyle(
                color = color, fontSize = (size / ds.fontScale).sp, fontWeight = weight,
                fontFeatureSettings = if (mono) "tnum" else null,
                fontFamily = if (rounded) FontFamily.SansSerif else null,
            ),
        )
        ds.withTransform({
            translate(at.x, at.y)
            scale(1 / k, 1 / k, pivot = Offset.Zero)
        }) {
            drawText(layout, topLeft = Offset(-layout.size.width * ax, -layout.size.height * ay))
        }
    }
}

// MARK: - Bézier

/** Punkt auf einer quadratischen Bézierkurve. */
internal fun quadPoint(a: Offset, c: Offset, b: Offset, t: Double): Offset {
    val tf = t.toFloat()
    val u = 1 - tf
    return Offset(u * u * a.x + 2 * u * tf * c.x + tf * tf * b.x, u * u * a.y + 2 * u * tf * c.y + tf * tf * b.y)
}

/** Teilstück einer quadratischen Bézierkurve von 0 bis `t` als Pfad. */
internal fun quadPath(a: Offset, c: Offset, b: Offset, upTo: Double, steps: Int = 40): Path {
    val p = Path()
    p.moveTo(a.x, a.y)
    val n = max((steps * upTo).toInt(), 1)
    for (i in 1..n) {
        val q = quadPoint(a, c, b, upTo * i / n)
        p.lineTo(q.x, q.y)
    }
    return p
}

// MARK: - Golfer-Posen

/**
 * Pose als Werte: Hüftversatz in dp, Arm- und Schlägerwinkel in Grad
 * (90° = senkrecht nach unten), `finish` 0…1 hebt die hintere Ferse.
 */
internal data class GolferPose(val hipShift: Float, val arm: Float, val club: Float, val finish: Float) {
    /** Weniger Hüftbewegung, damit Kopf und Achse ruhig bleiben. */
    fun steady(factor: Float = 0.3f) = copy(hipShift = hipShift * factor)

    companion object {
        // Schlägerwinkel bewusst über 360° bzw. unter 0°: so dreht der Schläger beim
        // Interpolieren in Schwungrichtung (Rückschwung 90→360, Durchschwung 360→−165,
        // Treffmoment bei 90°) statt auf dem kürzeren, falschen Weg.
        val address = GolferPose(0f, 90f, 90f, 0f)
        val top = GolferPose(-9f, 218f, 360f, 0f)
        val finished = GolferPose(18f, -40f, -165f, 1f)

        fun lerp(a: GolferPose, b: GolferPose, f: Double): GolferPose {
            val ff = f.toFloat()
            fun l(x: Float, y: Float) = x + (y - x) * ff
            return GolferPose(l(a.hipShift, b.hipShift), l(a.arm, b.arm), l(a.club, b.club), l(a.finish, b.finish))
        }

        /** Pose zur Zeit `x` aus Schlüsselbildern (Sekunde, Pose), weich interpoliert. */
        fun keyframes(frames: List<Pair<Double, GolferPose>>, x: Double): GolferPose {
            val first = frames.firstOrNull() ?: return address
            if (x <= first.first) return first.second
            for (i in 0 until frames.size - 1) {
                val a = frames[i]
                val b = frames[i + 1]
                if (x <= b.first) return lerp(a.second, b.second, Loop.ramp(x, a.first, b.first))
            }
            return frames.last().second
        }
    }
}

/** Gelenkpunkte der Figur, aus der Pose berechnet. */
internal class GolferJoints(pose: GolferPose, center: Float, ground: Float) {
    val trailAnkle: Offset
    val leadAnkle: Offset
    val trailKnee: Offset
    val leadKnee: Offset
    val trailHip: Offset
    val leadHip: Offset
    val trailShoulder: Offset
    val leadShoulder: Offset
    val neck: Offset
    val head: Offset
    val trailElbow: Offset
    val leadElbow: Offset
    val hands: Offset
    val clubHead: Offset

    init {
        val heel = pose.finish * 9
        trailAnkle = Offset(center - 44 + pose.finish * 12, ground - 6 - heel)
        leadAnkle = Offset(center + 44, ground - 6)

        val hip = Offset(center + pose.hipShift, ground - 86)
        trailHip = Offset(hip.x - 10, hip.y)
        leadHip = Offset(hip.x + 10, hip.y)
        // Knie leicht gebeugt; im Finish knickt das hintere Knie zum Ziel ein
        trailKnee = Offset((trailAnkle.x + trailHip.x) / 2 + 3 + pose.finish * 16, ground - 46)
        leadKnee = Offset((leadAnkle.x + leadHip.x) / 2 - 3, ground - 46)

        // Oberkörper folgt der Hüfte nur zum Teil, der Kopf bleibt fast ruhig
        val chest = Offset(center + pose.hipShift * 0.35f, ground - 140)
        trailShoulder = Offset(chest.x - 17, chest.y)
        leadShoulder = Offset(chest.x + 17, chest.y)
        neck = Offset(chest.x, chest.y - 6)
        head = Offset(chest.x - pose.hipShift * 0.1f, chest.y - 20)

        fun point(from: Offset, angle: Float, length: Float): Offset {
            val r = angle * Math.PI / 180
            return Offset(from.x + (cos(r) * length).toFloat(), from.y + (sin(r) * length).toFloat())
        }
        hands = point(Offset(chest.x, chest.y + 4), pose.arm, 62f)
        clubHead = point(hands, pose.club, 70f)

        // Ellbogen: Mitte zwischen Schulter und Händen, leicht nach außen
        trailElbow = Offset((trailShoulder.x + hands.x) / 2 - 3, (trailShoulder.y + hands.y) / 2)
        leadElbow = Offset((leadShoulder.x + hands.x) / 2 + 3, (leadShoulder.y + hands.y) / 2)
    }
}

private val shirt = white(0.96f)
private val shirtDark = white(0.80f)
private val pants = rgb(0.24f, 0.27f, 0.33f)
private val pantsDark = rgb(0.18f, 0.20f, 0.25f)
private val skin = rgb(0.92f, 0.74f, 0.60f)
private val shoe = white(0.98f)

/** Golfer mit Kleidung: Polo, Hose, Kappe, Handschuh, Schuhe. */
internal fun TipDraw.golfer(pose: GolferPose, center: Float, ground: Float, accent: Color) {
    val j = GolferJoints(pose, center, ground)
    fun limb(pts: List<Offset>, width: Float, color: Color) = line(pts, color, width)

    // Schatten am Boden
    val shadowW = 120f
    val sx = center - shadowW / 2 + pose.hipShift * 0.5f
    ellipse(Rect(sx, ground - 3, sx + shadowW, ground + 4), Color.Black.copy(alpha = 0.25f))

    // Schläger hinter den Armen
    limb(listOf(j.hands, j.clubHead), 2.6f, white(0.75f))
    val r = atan2(j.clubHead.y - j.hands.y, j.clubHead.x - j.hands.x)
    ds.withTransform({
        translate(j.clubHead.x, j.clubHead.y)
        rotateRad(r, pivot = Offset.Zero)
    }) { drawRoundRect(accent, Offset(-5f, -3.5f), Size(12f, 7f), CornerRadius(3f, 3f)) }

    // Beine: hinteres etwas dunkler für Tiefe
    limb(listOf(j.trailHip, j.trailKnee, j.trailAnkle), 15f, pantsDark)
    limb(listOf(j.leadHip, j.leadKnee, j.leadAnkle), 15f, pants)

    // Schuhe
    for ((ankle, dir, lift) in listOf(Triple(j.trailAnkle, -1f, pose.finish), Triple(j.leadAnkle, 1f, 0f))) {
        ds.rotateRad(-dir * lift * 0.9f, pivot = Offset(ankle.x, ankle.y + 4)) {
            drawRoundRect(shoe, Offset(ankle.x - 10 + dir * 3, ankle.y - 1), Size(20f, 9f), CornerRadius(4.5f, 4.5f))
        }
    }

    // Oberkörper: Polo als Trapez von Schultern zur Hüfte
    val torso = Path().apply {
        moveTo(j.trailShoulder.x - 2, j.trailShoulder.y - 2)
        lineTo(j.leadShoulder.x + 2, j.leadShoulder.y - 2)
        lineTo(j.leadHip.x + 4, j.leadHip.y + 2)
        lineTo(j.trailHip.x - 4, j.trailHip.y + 2)
        close()
    }
    fill(torso, shirt)
    stroke(torso, shirt, 8f)
    // Gürtel
    limb(listOf(Offset(j.trailHip.x - 6, j.trailHip.y + 1), Offset(j.leadHip.x + 6, j.leadHip.y + 1)), 4f, white(0.2f))

    // Hals und Kopf mit Kappe
    limb(listOf(j.neck, Offset(j.head.x, j.head.y + 8)), 8f, skin)
    ellipse(Rect(j.head.x - 10, j.head.y - 11, j.head.x + 10, j.head.y + 11), skin)
    ds.drawArc(
        accent, startAngle = 180f, sweepAngle = 180f, useCenter = true,
        topLeft = Offset(j.head.x - 10.5f, j.head.y - 2 - 10.5f), size = Size(21f, 21f),
    )
    limb(listOf(Offset(j.head.x - 11, j.head.y - 2), Offset(j.head.x + 11, j.head.y - 2)), 3f, accent)

    // Arme: Ärmel oben, Unterarm, Handschuh an den Händen
    for ((shoulder, elbow, sleeve) in listOf(Triple(j.trailShoulder, j.trailElbow, shirtDark), Triple(j.leadShoulder, j.leadElbow, shirt))) {
        limb(listOf(shoulder, elbow, j.hands), 8.5f, skin)
        val sleeveEnd = Offset(shoulder.x + (elbow.x - shoulder.x) * 0.55f, shoulder.y + (elbow.y - shoulder.y) * 0.55f)
        limb(listOf(shoulder, sleeveEnd), 11f, sleeve)
    }
    circle(j.hands, 6f, Color.White)
}

/** Bodenlinie über die ganze Breite. */
internal fun TipDraw.groundLine(ground: Float, inset: Float = 12f) =
    line(Offset(inset, ground), Offset(w - inset, ground), Color.White.copy(alpha = 0.25f), 1f)
