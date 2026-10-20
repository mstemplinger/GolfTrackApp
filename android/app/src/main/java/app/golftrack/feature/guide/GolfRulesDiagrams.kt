package app.golftrack.feature.guide

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale
import androidx.compose.ui.layout.layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

// Nachbau von GolfRulesDiagrams.swift mit Compose Canvas. Alle Koordinaten in dp
// (wie Punkte auf iOS); `Stage` liefert Breite/Höhe wie GeometryReader.

// MARK: - Design Tokens

private object GC {
    val bg = rgb(0.06f, 0.11f, 0.06f)
    val grass = rgb(0.13f, 0.52f, 0.18f)
    val grassDark = rgb(0.05f, 0.28f, 0.09f)
    val rough = rgb(0.09f, 0.36f, 0.12f)
    val sand = rgb(0.87f, 0.76f, 0.51f)
    val sandDark = rgb(0.72f, 0.60f, 0.36f)
    val water = rgb(0.07f, 0.38f, 0.80f)
    val waterDark = rgb(0.03f, 0.20f, 0.52f)
    val optYellow = rgb(1.00f, 0.84f, 0.10f)
    val optRed = rgb(0.92f, 0.22f, 0.18f)
    val optGreen = rgb(0.16f, 0.88f, 0.44f)
    val optOrange = rgb(0.98f, 0.56f, 0.08f)
    val flagRed = rgb(0.90f, 0.18f, 0.18f)
}

private val W = Color.White
private fun Color.a(alpha: Float) = copy(alpha = alpha * this.alpha)

// MARK: - Bausteine

/** Text mit fester Größe in Punkten – Diagramme skalieren nicht mit der Schriftgröße. */
@Composable
internal fun DText(
    text: String,
    size: Float,
    color: Color,
    weight: FontWeight = FontWeight.Normal,
    modifier: Modifier = Modifier,
    align: TextAlign? = null,
    italic: Boolean = false,
    maxLines: Int = Int.MAX_VALUE,
) {
    val fs = LocalDensity.current.fontScale
    androidx.compose.material3.Text(
        text, modifier, color = color, fontSize = (size / fs).sp, fontWeight = weight,
        textAlign = align, lineHeight = (size * 1.2f / fs).sp, maxLines = maxLines,
        fontStyle = if (italic) FontStyle.Italic else FontStyle.Normal,
    )
}

/** Fläche mit fester Höhe; der Inhalt bekommt Breite und Höhe in dp. */
@Composable
private fun Stage(modifier: Modifier, content: @Composable BoxScope.(w: Float, h: Float) -> Unit) {
    BoxWithConstraints(modifier.clipToBounds()) {
        content(maxWidth.value, maxHeight.value)
    }
}

/** Zentriert den Inhalt auf (x, y) – wie `.position(x:y:)` in SwiftUI. */
@Composable
internal fun At(x: Float, y: Float, content: @Composable () -> Unit) {
    Box(
        Modifier.layout { m, c ->
            val p = m.measure(c.copy(minWidth = 0, minHeight = 0))
            layout(0, 0) { p.place(x.dp.roundToPx() - p.width / 2, y.dp.roundToPx() - p.height / 2) }
        },
    ) { content() }
}

/** Zeichenfläche in dp-Koordinaten. */
@Composable
internal fun Draw(block: DrawScope.() -> Unit) {
    Canvas(Modifier.fillMaxSize()) { scale(density, density, pivot = Offset.Zero) { block() } }
}

private fun dashed(width: Float, on: Float, off: Float) =
    Stroke(width, pathEffect = PathEffect.dashPathEffect(floatArrayOf(on, off)))

private fun arrowPath(from: Offset, to: Offset): Path {
    val angle = atan2(to.y - from.y, to.x - from.x)
    val h = 10f
    val a1 = angle - Math.PI.toFloat() / 6
    val a2 = angle + Math.PI.toFloat() / 6
    return Path().apply {
        moveTo(from.x, from.y); lineTo(to.x, to.y)
        moveTo(to.x, to.y); lineTo(to.x - h * cos(a1), to.y - h * sin(a1))
        moveTo(to.x, to.y); lineTo(to.x - h * cos(a2), to.y - h * sin(a2))
    }
}

private fun DrawScope.arrow(from: Offset, to: Offset, color: Color, width: Float = 2f) =
    drawPath(arrowPath(from, to), color, style = Stroke(width))

private fun DrawScope.line(from: Offset, to: Offset, color: Color, width: Float, dash: FloatArray? = null) =
    drawLine(color, from, to, width, pathEffect = dash?.let { PathEffect.dashPathEffect(it) })

private fun DrawScope.circleAt(c: Offset, diameter: Float, color: Color) = drawCircle(color, diameter / 2, c)

private fun DrawScope.ringAt(c: Offset, diameter: Float, color: Color, stroke: Stroke) =
    drawCircle(color, diameter / 2, c, style = stroke)

private fun DrawScope.ovalAt(c: Offset, w: Float, h: Float, color: Color, style: Stroke? = null) =
    if (style == null) drawOval(color, Offset(c.x - w / 2, c.y - h / 2), Size(w, h))
    else drawOval(color, Offset(c.x - w / 2, c.y - h / 2), Size(w, h), style = style)

private fun DrawScope.ovalAt(c: Offset, w: Float, h: Float, brush: Brush) =
    drawOval(brush, Offset(c.x - w / 2, c.y - h / 2), Size(w, h))

/** Diagonaler Verlauf von oben links nach unten rechts über ein Rechteck. */
private fun diag(colors: List<Color>, left: Float, top: Float, w: Float, h: Float) =
    Brush.linearGradient(colors, Offset(left, top), Offset(left + w, top + h))

/** Golfball mit Verlauf und Schatten. */
private fun DrawScope.ball(c: Offset, size: Float = 12f, color: Color = Color.White) {
    drawCircle(Color.Black.copy(alpha = 0.25f), size / 2 + 1.5f, c + Offset(0f, 2f))
    drawCircle(
        Brush.radialGradient(listOf(color, color.a(0.75f)), center = Offset(c.x - size / 2, c.y - size / 2), radius = size),
        size / 2, c,
    )
}

/** Fähnchen wie `FlagPath` – (left, top) ist die Ecke an der Fahnenstange. */
private fun DrawScope.flag(left: Float, top: Float, w: Float, h: Float, color: Color) {
    drawPath(Path().apply {
        moveTo(left, top); lineTo(left + w, top + h * 0.3f); lineTo(left, top + h * 0.6f); close()
    }, color)
}

@Composable
private fun Chip(text: String, bg: Color = W.a(0.12f), fg: Color = W, icon: String? = null) {
    Row(
        Modifier.background(bg, RoundedCornerShape(50)).padding(horizontal = 8.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) SfIcon(icon, fg.a(0.8f), 9.dp)
        DText(text, 10f, fg, FontWeight.SemiBold, maxLines = 1)
    }
}

/** Kreis mit Buchstabe/Ziffer (Optionen, Markierungen). */
@Composable
private fun Badge(text: String, color: Color, diameter: Dp, size: Float, fg: Color = Color.Black) {
    Box(Modifier.size(diameter).background(color, CircleShape), contentAlignment = Alignment.Center) {
        DText(text, size, fg, FontWeight.Black)
    }
}

@Composable
private fun DiagramCard(title: String, icon: String, content: @Composable ColumnScope.() -> Unit) {
    val shape = RoundedCornerShape(16.dp)
    Column(Modifier.fillMaxWidth().clip(shape).background(GC.bg).border(1.dp, W.a(0.09f), shape)) {
        DiagramHeader(title, icon)
        content()
    }
}

@Composable
private fun DiagramHeader(title: String, icon: String) {
    Row(
        Modifier.fillMaxWidth().background(W.a(0.06f)).padding(horizontal = 14.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        SfIcon(icon, GC.optGreen, 11.dp)
        DText(title, 11f, W.a(0.9f), FontWeight.SemiBold, Modifier.weight(1f), maxLines = 1)
        SfIcon("info.circle", W.a(0.25f), 10.dp)
    }
}

@Composable
private fun HDivider(color: Color, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().height(0.5.dp).background(color))
}

// MARK: - 1. Abschlag

@Composable
fun TeeBoxDiagram() {
    DiagramCard("Abschlagsbereich – Vogelperspektive", "figure.golf") {
        Stage(Modifier.fillMaxWidth().height(200.dp).background(Brush.verticalGradient(listOf(GC.grassDark, GC.rough.a(0.8f))))) { w, h ->
            val bW = w * 0.50f; val bH = h * 0.33f
            val bX = (w - bW) / 2; val bY = h * 0.44f
            val ballY = bY + bH * 0.48f
            Draw {
                // Fairway-Korridor
                drawRoundRect(
                    Brush.verticalGradient(listOf(GC.grass.a(0.5f), GC.grassDark.a(0.3f)), 0f, h),
                    Offset(w / 2 - w * 0.16f, 0f), Size(w * 0.32f, h), CornerRadius(40f),
                )
                // Abschlagsbereich
                drawRoundRect(GC.grass.a(0.6f), Offset(bX, bY), Size(bW, bH), CornerRadius(6f))
                drawRoundRect(W.a(0.65f), Offset(bX, bY), Size(bW, bH), CornerRadius(6f), style = dashed(1.5f, 5f, 4f))
                // Breite
                arrow(Offset(bX + 4, bY - 11), Offset(bX + bW - 4, bY - 11), W.a(0.6f), 1.5f)
                // 2 Schlägerlängen
                line(Offset(bX + bW + 14, bY), Offset(bX + bW + 14, bY + bH), GC.optYellow.a(0.8f), 1.5f, floatArrayOf(4f, 3f))
                arrow(Offset(bX + bW + 14, bY + 6), Offset(bX + bW + 14, bY + bH - 6), GC.optYellow.a(0.8f), 1.5f)
                // Abschlagmarkierungen
                for (x in listOf(bX, bX + bW)) {
                    circleAt(Offset(x, bY), 18f, GC.optRed.a(0.25f))
                    circleAt(Offset(x, bY), 12f, GC.optRed)
                    ringAt(Offset(x, bY), 12f, W.a(0.6f), Stroke(1f))
                }
                // Ball auf dem Tee
                line(Offset(w / 2, ballY + 7), Offset(w / 2, ballY + 16), GC.sand, 2f)
                ball(Offset(w / 2, ballY), 13f)
                // Richtung Loch
                arrow(Offset(w / 2, bY - 32), Offset(w / 2, h * 0.05f), GC.optGreen, 2.5f)
            }
            At(w / 2, bY - 22) { DText("Abschlagbreite", 9f, W.a(0.65f), FontWeight.Medium) }
            At(bX + bW + 31, bY + bH / 2) { DText("2 SL", 9f, GC.optYellow, FontWeight.Bold, Modifier.rotate(90f)) }
            At(w / 2, h * 0.13f) { Chip("Richtung Loch", GC.optGreen.a(0.2f), GC.optGreen) }
            At(w / 2, bY + bH + 18) { Chip("✓ Erlaubter Bereich", GC.optGreen.a(0.18f), GC.optGreen) }
        }
    }
}

// MARK: - 2. Penalty Area

@Composable
fun PenaltyAreaDiagram() {
    DiagramCard("Penalty Area – Erleichterungsoptionen", "drop.fill") {
        Box(Modifier.fillMaxWidth().height(215.dp)) {
            Stage(Modifier.fillMaxSize()) { w, h ->
                Box(Modifier.fillMaxSize().background(diag(listOf(GC.grassDark, GC.rough.a(0.7f)), 0f, 0f, w, h)))
                val cx = w * 0.40f; val cy = h * 0.45f
                val wW = w * 0.38f; val wH = h * 0.38f
                val c = Offset(cx, cy)
                val tee = Offset(w * 0.10f, h * 0.22f)
                val entry = Offset(cx - wW * 0.1f, cy + wH * 0.3f)
                val optA = Offset(w * 0.08f, h * 0.80f)
                val optB = Offset(w * 0.75f, cy)
                Draw {
                    ovalAt(c, wW + 24, wH + 24, GC.waterDark.a(0.25f))
                    ovalAt(c, wW + 14, wH + 14, GC.waterDark.a(0.35f))
                    ovalAt(c, wW, wH, diag(listOf(GC.water, GC.waterDark), cx - wW / 2, cy - wH / 2, wW, wH))
                    ovalAt(Offset(cx - wW * 0.08f, cy - wH * 0.12f), wW * 0.5f, wH * 0.25f, W.a(0.08f))
                    ovalAt(c, wW + 10, wH + 10, GC.optYellow.a(0.85f), dashed(2f, 6f, 4f))
                    ovalAt(c, wW + 22, wH + 22, GC.optRed.a(0.75f), dashed(2f, 6f, 4f))
                    // Flugbahn
                    drawPath(Path().apply {
                        moveTo(tee.x, tee.y); quadraticTo(w * 0.26f, h * 0.03f, entry.x, entry.y)
                    }, W.a(0.45f), style = dashed(1.5f, 5f, 4f))
                    // Eintrittspunkt
                    circleAt(entry, 16f, GC.optYellow.a(0.3f))
                    circleAt(entry, 10f, GC.optYellow)
                    ball(tee, 10f)
                    // Option A – hintere Linie
                    drawPath(Path().apply {
                        moveTo(tee.x, tee.y); lineTo(entry.x, entry.y); lineTo(optA.x, optA.y)
                    }, GC.optYellow.a(0.6f), style = dashed(1.5f, 5f, 4f))
                    circleAt(optA, 26f, GC.optYellow.a(0.2f))
                    // Option B – 2 SL seitlich (nur rot)
                    circleAt(optB, 52f, GC.optRed.a(0.12f))
                    ringAt(optB, 52f, GC.optRed.a(0.35f), dashed(1.5f, 4f, 3f))
                    circleAt(optB, 26f, GC.optRed.a(0.2f))
                }
                At(cx, cy) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        SfIcon("drop.fill", W.a(0.7f), 14.dp)
                        DText("Penalty Area", 9f, W.a(0.7f), FontWeight.Bold)
                    }
                }
                At(entry.x, entry.y) { DText("E", 7f, Color.Black, FontWeight.Black) }
                At(optA.x, optA.y) { Badge("A", GC.optYellow, 20.dp, 10f) }
                At(optB.x, optB.y) { Badge("B", GC.optRed, 20.dp, 10f, fg = Color.White) }
                At(w * 0.81f, cy + 26) { DText("2 SL", 8f, GC.optRed.a(0.8f), FontWeight.Bold) }
            }
            // Legende
            Row(
                Modifier.align(Alignment.BottomCenter).padding(start = 12.dp, end = 12.dp, bottom = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Chip("A – Hintere Linie (+1)", GC.optYellow.a(0.18f), GC.optYellow)
                Chip("B – 2 SL seitlich, nur 🔴 (+1)", GC.optRed.a(0.18f), GC.optRed)
            }
        }
    }
}

// MARK: - 3. Bunker

@Composable
fun BunkerDiagram() {
    DiagramCard("Bunker – Regeln & Erleichterungsoptionen", "circle.bottomhalf.filled") {
        Stage(Modifier.fillMaxWidth().height(120.dp).background(Brush.verticalGradient(listOf(GC.grassDark, GC.rough.a(0.7f))))) { w, h ->
            val bx = w * 0.38f; val by = h * 0.18f
            val bW = w * 0.42f; val bH = h * 0.64f
            val center = Offset(bx + bW / 2, by + bH / 2)
            val noX = Offset(w * 0.28f, h * 0.20f)
            Draw {
                ovalAt(center + Offset(0f, 3f), bW + 8, bH + 8, Color.Black.a(0.3f))
                ovalAt(center, bW, bH, diag(listOf(GC.sand, GC.sandDark), bx, by, bW, bH))
                // Sandstruktur
                for (i in 0 until 20) {
                    val fx = (i % 5) / 4f
                    val fy = (i / 5) / 3f
                    circleAt(Offset(bx + bW * (0.15f + fx * 0.7f), by + bH * (0.15f + fy * 0.7f)), 3f, GC.sandDark.a(0.5f))
                }
                ball(Offset(bx + bW / 2, by + bH * 0.5f), 13f)
                // Schläger
                line(Offset(w * 0.28f, h * 0.05f), Offset(bx + bW * 0.35f, by + bH * 0.45f), Color.Black.a(0.25f), 6f)
                line(Offset(w * 0.28f, h * 0.05f), Offset(bx + bW * 0.35f, by + bH * 0.45f), IosColor.gray.a(0.85f), 4f)
                // Verbot
                circleAt(noX, 28f, GC.optRed.a(0.15f))
                ringAt(noX, 28f, GC.optRed, Stroke(1.5f))
            }
            At(bx + bW / 2, by + bH * 0.82f) { DText("BUNKER", 11f, GC.sandDark.a(0.7f), FontWeight.Black) }
            At(noX.x, noX.y) { SfIcon("xmark", GC.optRed, 12.dp) }
            At(w * 0.18f, h * 0.06f) { Chip("Sand nicht berühren!", GC.optRed.a(0.20f), GC.optRed) }
        }
        // Optionen
        Column(Modifier.fillMaxWidth().background(W.a(0.04f))) {
            HDivider(W.a(0.08f))
            Column(Modifier.padding(10.dp), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    BunkerOption("1", "Schlag & Distanz", "+1", GC.optOrange, Modifier.weight(1f))
                    BunkerOption("2", "Im Bunker, hintere Linie", "+1", GC.optYellow, Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    BunkerOption("3", "Im Bunker, seitlich 2 SL", "+1", GC.optYellow, Modifier.weight(1f))
                    BunkerOption("4", "Außerhalb Bunker", "+2", GC.optRed, Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun BunkerOption(n: String, label: String, cost: String, color: Color, modifier: Modifier) {
    Row(
        modifier.background(color.a(0.08f), RoundedCornerShape(8.dp)).padding(horizontal = 8.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(7.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        Badge(n, color, 18.dp, 10f)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            DText(label, 9f, W.a(0.9f), FontWeight.SemiBold)
            DText(cost, 9f, color, FontWeight.Bold)
        }
    }
}

// MARK: - 4. Unspielbar – 3 Optionen

@Composable
fun UnplayableDiagram() {
    DiagramCard("Unspielbare Lage – 3 Optionen (je +1 Schlag)", "exclamationmark.triangle.fill") {
        Stage(Modifier.fillMaxWidth().height(220.dp)) { w, h ->
            Box(Modifier.fillMaxSize().background(diag(listOf(GC.rough.a(0.8f), GC.grassDark), 0f, 0f, w, h)))
            val ballPt = Offset(w * 0.50f, h * 0.50f)
            val holePt = Offset(w * 0.50f, h * 0.08f)
            val opt1 = Offset(w * 0.50f, h * 0.86f)
            val opt2 = Offset(w * 0.13f, h * 0.70f)
            val opt3 = Offset(w * 0.84f, h * 0.50f)
            Draw {
                // Achse Loch–Ball (Option 2)
                line(holePt, Offset(w * 0.10f, h * 0.92f), GC.optYellow.a(0.3f), 1.5f, floatArrayOf(5f, 4f))
                // 2-SL-Radius (Option 3)
                ringAt(ballPt, 68f, GC.optGreen.a(0.3f), dashed(1.5f, 4f, 4f))
                arrow(ballPt, opt1, GC.optOrange.a(0.9f), 2f)
                arrow(ballPt, opt2, GC.optYellow.a(0.9f), 2f)
                arrow(ballPt, opt3, GC.optGreen.a(0.9f), 2f)
                // Loch mit Fahne
                line(holePt, holePt - Offset(0f, 14f), W, 1.5f)
                flag(holePt.x, holePt.y - 14f, 10f, 9f, GC.flagRed)
                circleAt(holePt, 10f, Color.Black)
                // Ball (unspielbar)
                circleAt(ballPt, 30f, GC.optRed.a(0.2f))
                circleAt(ballPt, 22f, GC.rough.a(0.8f))
                ball(ballPt, 14f)
            }
            At(ballPt.x + 6, ballPt.y - 6) { SfIcon("xmark", GC.optRed, 8.dp) }
            At(opt1.x, opt1.y + 18) { OptBadge("1", "Schlag &\nDistanz", GC.optOrange) }
            At(opt2.x - 14, opt2.y + 20) { OptBadge("2", "Hintere\nLinie", GC.optYellow) }
            At(opt3.x + 18, opt3.y + 20) { OptBadge("3", "2 SL\nseitlich", GC.optGreen) }
        }
    }
}

@Composable
private fun OptBadge(n: String, label: String, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Badge(n, color, 22.dp, 11f)
        DText(label, 9f, color, FontWeight.SemiBold, align = TextAlign.Center)
    }
}

// MARK: - 5. Putting Green

@Composable
fun PuttingGreenDiagram() {
    DiagramCard("Putting Green – Regeln auf einen Blick", "circle.fill") {
        Box(Modifier.fillMaxWidth().height(210.dp)) {
            Stage(Modifier.fillMaxSize()) { w, h ->
                Box(Modifier.fillMaxSize().background(diag(listOf(GC.grassDark, GC.bg), 0f, 0f, w, h)))
                val cx = w * 0.38f; val cy = h * 0.50f
                val c = Offset(cx, cy)
                val hole = Offset(cx, cy - h * 0.18f)
                Draw {
                    ovalAt(c, w * 0.60f + 28, h * 0.72f + 28, GC.grass.a(0.07f))
                    ovalAt(c, w * 0.60f + 16, h * 0.72f + 16, GC.grass.a(0.1f))
                    ovalAt(c, w * 0.60f, h * 0.72f, diag(listOf(GC.grass.a(0.75f), GC.grassDark.a(0.9f)), cx - w * 0.3f, cy - h * 0.36f, w * 0.6f, h * 0.72f))
                    // Mählinien
                    for (i in 0 until 5) {
                        val y2 = cy - h * 0.28f + i * (h * 0.56f / 4)
                        line(Offset(cx - w * 0.27f, y2), Offset(cx + w * 0.27f, y2), W.a(0.04f), 3f)
                    }
                    circleAt(hole, 20f, Color.Black.a(0.4f))
                    circleAt(hole, 16f, Color.Black)
                    // Fahnenstange und Fahne
                    line(hole, Offset(cx, cy - h * 0.52f), W.a(0.85f), 2f)
                    flag(cx, cy - h * 0.47f - 7f, 20f, 14f, GC.flagRed)
                    ball(Offset(cx - w * 0.14f, cy + h * 0.12f), 12f)
                    // Ballmarker
                    drawRoundRect(
                        rgb(0.6f, 0.45f, 0.15f), Offset(cx - w * 0.14f - 7f, cy + h * 0.23f - 2.5f), Size(14f, 5f), CornerRadius(2.5f),
                    )
                    // Pitchmarke
                    ovalAt(Offset(cx + w * 0.08f, cy + h * 0.05f), 13f, 8f, rgb(0.5f, 0.3f, 0.1f), Stroke(1.5f))
                }
                At(cx + w * 0.16f, cy + h * 0.03f) { SfIcon("checkmark.circle.fill", GC.optGreen, 13.dp) }
            }
            // Hinweise
            Column(
                Modifier.align(Alignment.BottomEnd).padding(end = 12.dp, bottom = 10.dp)
                    .background(Color.Black.a(0.55f), RoundedCornerShape(10.dp)).padding(10.dp),
                verticalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                AnnotRow("⛳", "Fahne drin lassen – straflos", GC.optGreen)
                AnnotRow("⚪", "Ball markieren & reinigen", W.a(0.9f))
                AnnotRow("▬", "Marker direkt hinter Ball", rgb(0.75f, 0.55f, 0.2f))
                AnnotRow("✓", "Pitchmarks reparieren", GC.optGreen)
                AnnotRow("✗", "Normalen Verschleiß nicht", GC.optRed)
            }
        }
    }
}

@Composable
private fun AnnotRow(icon: String, text: String, color: Color) {
    Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(14.dp), contentAlignment = Alignment.Center) { DText(icon, 10f, W) }
        DText(text, 9f, color)
    }
}

// MARK: - 6. Aus (Out of Bounds)

@Composable
fun OutOfBoundsDiagram() {
    DiagramCard("Außerhalb der Grenzen (AUS)", "xmark.circle.fill") {
        Stage(Modifier.fillMaxWidth().height(200.dp)) { w, h ->
            val boundary = w * 0.60f
            val tee = Offset(w * 0.14f, h * 0.65f)
            val obBall = Offset(w * 0.80f, h * 0.42f)
            Draw {
                drawRect(
                    Brush.horizontalGradient(listOf(GC.grass.a(0.4f), GC.grassDark.a(0.7f)), 0f, boundary),
                    Offset.Zero, Size(boundary, h),
                )
                drawRect(
                    Brush.horizontalGradient(listOf(GC.optRed.a(0.08f), GC.optRed.a(0.18f)), boundary, w),
                    Offset(boundary, 0f), Size(w - boundary, h),
                )
                line(Offset(boundary, 0f), Offset(boundary, h), W.a(0.7f), 2f)
                // Auspfähle
                for (frac in listOf(0.12f, 0.35f, 0.58f, 0.82f)) {
                    val y = h * frac
                    drawPath(Path().apply {
                        moveTo(boundary, y - 6.5f); lineTo(boundary - 3.5f, y - 11.5f); lineTo(boundary + 3.5f, y - 11.5f); close()
                    }, W.a(0.9f))
                    drawRect(W.a(0.85f), Offset(boundary - 1.25f, y - 6.5f), Size(2.5f, 18f))
                }
                // Flugbahn
                drawPath(Path().apply {
                    moveTo(tee.x, tee.y); quadraticTo(w * 0.47f, h * 0.07f, obBall.x, obBall.y)
                }, W.a(0.45f), style = dashed(1.5f, 5f, 4f))
                ball(tee, 11f)
                circleAt(obBall, 18f, GC.optRed.a(0.3f))
                circleAt(obBall, 12f, GC.optRed.a(0.8f))
                // Zurück zum Abschlag
                arrow(Offset(w * 0.46f, h * 0.65f), Offset(w * 0.18f, h * 0.65f), GC.optOrange, 2f)
            }
            At(boundary * 0.42f, h * 0.10f) { Chip("Im Spiel", GC.optGreen.a(0.2f), GC.optGreen) }
            At(boundary + (w - boundary) * 0.5f, h * 0.10f) { Chip("AUS", GC.optRed.a(0.25f), GC.optRed, icon = "xmark") }
            At(tee.x, h * 0.76f) { DText("Abschlag", 8f, W.a(0.55f)) }
            At(obBall.x, obBall.y) { SfIcon("xmark", W, 8.dp) }
            At(w * 0.32f, h * 0.82f) { Chip("+1 → zurück zum Abschlag", GC.optOrange.a(0.2f), GC.optOrange) }
            At(boundary / 2, h * 0.93f) { Chip("◻ Weiße Pfähle = Grenze", Color.Transparent, W.a(0.45f)) }
        }
    }
}

// MARK: - 7. Drop-Verfahren

@Composable
fun DropProcedureDiagram() {
    DiagramCard("Drop-Verfahren – Regel 14.3", "arrow.down.circle.fill") {
        Row(Modifier.fillMaxWidth().height(200.dp)) {
            Stage(Modifier.width(130.dp).fillMaxHeight().background(Brush.verticalGradient(listOf(GC.grassDark, GC.rough.a(0.7f))))) { w, h ->
                val ref = Offset(w * 0.50f, h * 0.60f)
                val dropped = Offset(w * 0.35f, h * 0.53f)
                Draw {
                    circleAt(ref, w * 0.55f, GC.optYellow.a(0.06f))
                    ringAt(ref, w * 0.55f, GC.optYellow.a(0.6f), dashed(2f, 5f, 4f))
                    circleAt(ref, 16f, GC.optOrange.a(0.3f))
                    circleAt(ref, 10f, GC.optOrange)
                    drawPath(Path().apply {
                        moveTo(w * 0.50f, h * 0.06f); quadraticTo(w * 0.18f, h * 0.22f, dropped.x, dropped.y)
                    }, W.a(0.55f), style = dashed(1.5f, 4f, 3f))
                    ball(dropped, 11f)
                }
                At(ref.x, h * 0.73f) { DText("Referenz", 8f, GC.optOrange.a(0.8f)) }
                At(w * 0.50f, h * 0.08f) { DText("✋", 22f, W) }
                At(w * 0.50f, h * 0.24f) { Chip("Kniehöhe", W.a(0.12f), W.a(0.75f)) }
            }
            Column(
                Modifier.weight(1f).fillMaxHeight().background(W.a(0.03f)).padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(7.dp, Alignment.CenterVertically),
            ) {
                DropRule("checkmark.circle.fill", "Aus Kniehöhe loslassen", GC.optGreen)
                DropRule("checkmark.circle.fill", "Innerhalb der Zone landen", GC.optGreen)
                DropRule("checkmark.circle.fill", "Nicht näher zum Loch", GC.optGreen)
                HDivider(W.a(0.1f), Modifier.padding(vertical = 2.dp))
                DropRule("xmark.circle.fill", "Nicht platzieren", GC.optRed)
                DropRule("xmark.circle.fill", "Außerhalb Zone → neu droppen", GC.optRed)
                DropRule("arrow.clockwise", "3. Versuch → platzieren", GC.optYellow)
            }
        }
    }
}

@Composable
private fun DropRule(icon: String, text: String, color: Color) {
    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Box(Modifier.width(14.dp), contentAlignment = Alignment.Center) { SfIcon(icon, color, 12.dp) }
        DText(text, 10f, W.a(0.85f))
    }
}

// MARK: - 8. Ballsuche / 3 Minuten

@Composable
fun BallSearchDiagram() {
    DiagramCard("Suchzeit – max. 3 Minuten (Regel 18.2)", "timer") {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            // Zeitleiste
            Stage(Modifier.padding(start = 14.dp, end = 14.dp, top = 10.dp).fillMaxWidth().height(44.dp)) { w, _ ->
                val barH = 22f
                Draw {
                    drawRoundRect(W.a(0.08f), Offset.Zero, Size(w, barH), CornerRadius(barH / 2))
                    drawRoundRect(
                        Brush.horizontalGradient(listOf(GC.optGreen, GC.optYellow, GC.optOrange, GC.optRed), 0f, w),
                        Offset.Zero, Size(w, barH), CornerRadius(barH / 2),
                    )
                    for (min in 0..3) {
                        val x = w * min / 3
                        line(Offset(x, -6f), Offset(x, barH + 6), GC.bg.a(0.6f), 1.5f)
                    }
                }
                for (min in 0..3) {
                    At(w * min / 3, barH + 18) { DText("$min min", 9f, W.a(0.8f), FontWeight.SemiBold, maxLines = 1) }
                }
            }
            Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp)) {
                EventChip("Suche beginnt", GC.optGreen, "play.fill")
                Spacer(Modifier.weight(1f))
                EventChip("VERLOREN", GC.optRed, "xmark.circle.fill")
            }
            HDivider(W.a(0.08f), Modifier.padding(horizontal = 14.dp))
            Column(Modifier.padding(start = 14.dp, end = 14.dp, bottom = 12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                StepRow("1", "Provisorischen Ball spielen (vor der Suche!)", GC.optGreen)
                StepRow("2", "Max. 3 Minuten suchen", GC.optYellow)
                StepRow("3", "Nicht gefunden → Provisorischer Ball gilt (+1)", GC.optOrange)
                StepRow("⚠", "Kein prov. Ball? → Zurück zum Abschlag (+1)", GC.optRed)
            }
        }
    }
}

@Composable
private fun EventChip(text: String, color: Color, icon: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
        SfIcon(icon, color, 10.dp)
        DText(text, 9f, color, FontWeight.Bold)
    }
}

@Composable
private fun StepRow(n: String, text: String, color: Color) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Badge(n, color, 18.dp, 10f)
        DText(text, 10f, W.a(0.85f), modifier = Modifier.padding(top = 2.dp))
    }
}

// MARK: - 9. Wertungstabelle

private data class ScoreRow(val name: String, val par: String, val points: Int, val color: Color)

private val scoreRows = listOf(
    ScoreRow("Condor / Albatross", "−4 / −3", 5, rgb(0.70f, 0.20f, 0.80f)),
    ScoreRow("Eagle", "−2", 4, rgb(0.90f, 0.65f, 0.00f)),
    ScoreRow("Birdie", "−1", 3, rgb(0.12f, 0.80f, 0.28f)),
    ScoreRow("Par", " 0", 2, rgb(0.25f, 0.55f, 0.95f)),
    ScoreRow("Bogey", "+1", 1, rgb(0.95f, 0.60f, 0.10f)),
    ScoreRow("Double Bogey", "+2", 0, rgb(0.88f, 0.25f, 0.20f)),
    ScoreRow("Triple+ Bogey", "+3+", 0, rgb(0.55f, 0.08f, 0.08f)),
)

@Composable
fun ScoringTableDiagram() {
    val shape = RoundedCornerShape(16.dp)
    Column(Modifier.fillMaxWidth().clip(shape).background(GC.bg).border(1.dp, W.a(0.09f), shape)) {
        Row(Modifier.fillMaxWidth().background(W.a(0.05f)).padding(horizontal = 14.dp, vertical = 8.dp)) {
            DText("Bezeichnung", 10f, W.a(0.45f), FontWeight.Bold, Modifier.weight(1f))
            DText("vs. Par", 10f, W.a(0.45f), FontWeight.Bold, Modifier.width(52.dp), TextAlign.Center)
            DText("Stableford", 10f, W.a(0.45f), FontWeight.Bold, Modifier.width(80.dp), TextAlign.End)
        }
        scoreRows.forEachIndexed { i, row ->
            Row(
                Modifier.fillMaxWidth().background(row.color.a(0.07f)).padding(horizontal = 14.dp, vertical = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(9.dp).background(row.color, CircleShape))
                    DText(row.name, 13f, W.a(0.95f), FontWeight.SemiBold)
                }
                DText(row.par, 13f, row.color, FontWeight.Bold, Modifier.width(52.dp), TextAlign.Center)
                Box(Modifier.width(80.dp), contentAlignment = Alignment.CenterEnd) { StablefordBadge(row.points, row.color) }
            }
            if (i < scoreRows.lastIndex) HDivider(W.a(0.06f))
        }
    }
}

@Composable
private fun StablefordBadge(points: Int, color: Color) {
    if (points == 0) {
        DText("0 Pkt.", 12f, W.a(0.28f))
    } else {
        Row(horizontalArrangement = Arrangement.spacedBy(3.dp), verticalAlignment = Alignment.CenterVertically) {
            repeat(minOf(points, 4)) { Box(Modifier.size(6.dp).background(color, CircleShape)) }
            DText("$points Pkt.", 12f, color, FontWeight.SemiBold, maxLines = 1)
        }
    }
}

// MARK: - 10. Matchplay

@Composable
fun MatchplayDiagram() {
    val shape = RoundedCornerShape(16.dp)
    Column(Modifier.fillMaxWidth().clip(shape).background(GC.bg).border(1.dp, W.a(0.09f), shape)) {
        DiagramHeader("Matchplay – Lochspiel-Wertung", "person.2.fill")
        Row(Modifier.fillMaxWidth().height(androidx.compose.foundation.layout.IntrinsicSize.Min)) {
            MatchPlayer("Spieler A", "3", GC.optGreen, 0.06f, Modifier.weight(1f))
            Column(
                Modifier.width(110.dp).padding(vertical = 18.dp),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                DText("VS", 10f, W.a(0.3f), FontWeight.ExtraBold)
                Column(
                    Modifier.background(GC.optGreen.a(0.10f), RoundedCornerShape(10.dp)).padding(horizontal = 12.dp, vertical = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp),
                ) {
                    DText("2 up", 22f, GC.optGreen, FontWeight.Black)
                    DText("Führung A", 9f, W.a(0.45f), FontWeight.Medium)
                }
                Chip("noch 4 Löcher", W.a(0.08f), W.a(0.55f))
            }
            MatchPlayer("Spieler B", "1", GC.optOrange, 0.05f, Modifier.weight(1f))
        }
        HDivider(W.a(0.06f))
        Row(
            Modifier.fillMaxWidth().background(W.a(0.03f)).padding(horizontal = 14.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            ResultHint("2 up", "Vorsprung 2 Löcher", GC.optGreen, Modifier.weight(1f))
            ResultHint("3&2", "3 Löcher Vorsp., 2 zu spielen → Sieg", GC.optOrange, Modifier.weight(1f))
            ResultHint("A.S.", "All Square = Gleichstand", W.a(0.5f), Modifier.weight(1f))
        }
    }
}

@Composable
private fun MatchPlayer(name: String, holes: String, color: Color, bgAlpha: Float, modifier: Modifier) {
    Column(
        modifier.fillMaxHeight().background(color.a(bgAlpha)).padding(vertical = 18.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterVertically),
    ) {
        Chip(name, color.a(0.2f), color)
        DText(holes, 44f, color, FontWeight.Black)
        DText("gewonnene Löcher", 10f, W.a(0.5f), align = TextAlign.Center)
    }
}

@Composable
private fun ResultHint(code: String, desc: String, color: Color, modifier: Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        DText(code, 10f, color, FontWeight.Black)
        DText(desc, 8f, W.a(0.4f), maxLines = 2)
    }
}
