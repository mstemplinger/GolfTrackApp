package app.golftrack.feature.minigolf

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.RoundRect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import app.golftrack.ui.theme.AppTheme
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

internal val SketchTargetColor = Color(0.35f, 0.80f, 0.50f)

/**
 * Schematische Draufsicht einer genormten Bahn – wie MinigolfLaneSketch.swift.
 * Absichtlich nicht maßstäblich. Abschlag links, Ziel rechts.
 * `lineWidth` in Punkten (wird mit der Bildschirmdichte umgerechnet).
 */
@Composable
internal fun MinigolfLaneSketch(shape: LaneShape, glyph: LaneGlyph, lineWidth: Float = 1.6f, modifier: Modifier = Modifier) {
    Canvas(modifier.aspectRatio(3f)) {
        val lw = lineWidth * density
        val g = SketchGeometry(size, shape)
        drawLane(g, lw)
        drawTarget(g, lw)
        drawTee(g, lw)
        drawGlyph(glyph, g, lw)
    }
}

private val laneColor = Color.White.copy(alpha = 0.55f)
private val fillColor = Color.White.copy(alpha = 0.07f)
private val teeColor = Color.White.copy(alpha = 0.22f)

private class SketchGeometry(val size: Size, val shape: LaneShape) {
    val inset = max(6f, size.height * 0.10f)
    val midY = size.height / 2
    /** Halbe Bahnbreite (Bahn 0,90 m, Zielkreis 1,40 m). */
    val half = size.height * 0.19f
    val laneTop = midY - half
    val laneBottom = midY + half
    val laneLeft = inset

    val targetRadius = when (shape) {
        LaneShape.straight -> half * 1.55f
        LaneShape.tiltedCircle -> size.height * 0.44f
        LaneShape.jump -> size.height * 0.30f
    }
    val targetCenter = Offset(size.width - inset - targetRadius, midY)

    /** Rechtes Ende des geraden Bahnteils. */
    val laneRight = when (shape) {
        LaneShape.straight -> targetCenter.x - targetRadius * 0.25f
        LaneShape.tiltedCircle -> targetCenter.x - targetRadius * 0.55f
        LaneShape.jump -> laneLeft + (size.width - 2 * inset) * 0.34f
    }

    val laneRect = Rect(laneLeft, laneTop, laneRight, laneBottom)

    /** Punkt auf der Bahnachse bei `t` (0 = Abschlag, 1 = Ende des geraden Teils). */
    fun x(t: Float) = laneLeft + (laneRight - laneLeft) * t
    /** Punkt quer zur Bahn (-1 = obere Bande, 1 = untere Bande). */
    fun y(t: Float) = midY + half * t
    fun p(tx: Float, ty: Float) = Offset(x(tx), y(ty))
}

private fun circleRect(c: Offset, r: Float) = Rect(c.x - r, c.y - r, c.x + r, c.y + r)

private fun DrawScope.drawLane(g: SketchGeometry, lw: Float) {
    val lane = Path().apply { addRoundRect(RoundRect(g.laneRect, CornerRadius(g.half * 0.25f))) }
    drawPath(lane, fillColor)
    drawPath(lane, laneColor, style = Stroke(lw))
    if (g.shape == LaneShape.jump) {
        // Zwischen Rampe und Netz gibt es keine Bahn – gestrichelte Fluglinie.
        val flight = Path().apply {
            moveTo(g.laneRight, g.midY)
            quadraticTo(
                (g.laneRight + g.targetCenter.x) / 2, g.midY - g.size.height * 0.34f,
                g.targetCenter.x - g.targetRadius, g.midY,
            )
        }
        drawPath(flight, AppTheme.gold.copy(alpha = 0.7f),
            style = Stroke(lw, pathEffect = PathEffect.dashPathEffect(floatArrayOf(4 * density, 3 * density))))
    }
}

private fun DrawScope.drawTarget(g: SketchGeometry, lw: Float) {
    val r = g.targetRadius
    drawCircle(fillColor, r, g.targetCenter)
    drawCircle(if (g.shape == LaneShape.jump) AppTheme.gold else SketchTargetColor, r, g.targetCenter, style = Stroke(lw))

    if (g.shape == LaneShape.tiltedCircle) {
        // Neigung andeuten: kurze Hangstriche am oberen Kreisrand.
        for (i in 0 until 5) {
            val a = (PI * (1.12 + 0.19 * i)).toFloat()
            val outer = Offset(g.targetCenter.x + cos(a) * r, g.targetCenter.y + sin(a) * r)
            val inner = Offset(g.targetCenter.x + cos(a) * r * 0.78f, g.targetCenter.y + sin(a) * r * 0.78f)
            drawLine(laneColor.copy(alpha = 0.55f * 0.7f), outer, inner, lw * 0.7f)
        }
    }

    if (g.shape != LaneShape.jump) {
        drawCircle(SketchTargetColor, max(2f, g.half * 0.24f), g.targetCenter)
    } else {
        // Netzring
        drawCircle(AppTheme.gold, r * 0.55f, g.targetCenter, style = Stroke(lw))
    }
}

private fun DrawScope.drawTee(g: SketchGeometry, lw: Float) {
    val w = (g.laneRight - g.laneLeft) * 0.09f
    drawRect(teeColor, Offset(g.laneLeft + lw, g.laneTop + lw), Size(w, g.half * 2 - lw * 2))
    drawCircle(Color.White, max(1.5f, g.half * 0.17f), Offset(g.laneLeft + w / 2, g.midY))
}

private fun DrawScope.drawGlyph(glyph: LaneGlyph, g: SketchGeometry, lw: Float) {
    val gold = AppTheme.gold
    val goldSoft = AppTheme.gold.copy(alpha = 0.35f)
    fun stroke(path: Path, color: Color, width: Float) = drawPath(path, color, style = Stroke(width))
    fun fillStroke(path: Path) { drawPath(path, goldSoft); stroke(path, gold, lw) }
    fun line(a: Offset, b: Offset, color: Color, width: Float) = drawLine(color, a, b, width)

    when (glyph) {
        LaneGlyph.keines -> {}

        LaneGlyph.pyramiden -> {
            for ((t, side) in listOf(0.42f to -1f, 0.60f to 1f)) {
                fillStroke(Path().apply {
                    moveTo(g.x(t - 0.09f), g.y(side))
                    lineTo(g.x(t + 0.09f), g.y(side))
                    lineTo(g.x(t), g.y(side * -0.15f))
                    close()
                })
            }
        }

        LaneGlyph.salto -> {
            val r = g.half * 0.85f
            drawCircle(gold, r, Offset(g.x(0.5f), g.midY - r * 0.15f), style = Stroke(lw * 1.2f))
            line(g.p(0.34f, -0.5f), g.p(0.34f, 0.5f), gold, lw)
            line(g.p(0.66f, -0.5f), g.p(0.66f, 0.5f), gold, lw)
        }

        LaneGlyph.niere -> {
            val rect = Rect(Offset(g.x(0.40f), g.y(-0.7f)), Size((g.laneRight - g.laneLeft) * 0.20f, g.half * 1.4f))
            fillStroke(Path().apply { addRoundRect(RoundRect(rect, CornerRadius(rect.height / 2))) })
            line(Offset(rect.left, g.midY), Offset(rect.right, g.midY), Color.White.copy(alpha = 0.85f), lw * 1.4f)
        }

        LaneGlyph.doppelwellen -> {
            for (t in listOf(0.42f, 0.60f)) {
                stroke(Path().apply {
                    moveTo(g.x(t), g.y(-1f))
                    quadraticTo(g.x(t) + g.half * 0.7f, g.midY, g.x(t), g.y(1f))
                }, gold, lw * 1.2f)
            }
        }

        LaneGlyph.liegendeSchleife -> {
            val r = g.half * 0.95f
            val c = Offset(g.x(0.5f), g.midY)
            drawArc(gold, 35f, 290f, false, Offset(c.x - r, c.y - r), Size(r * 2, r * 2), style = Stroke(lw * 1.2f))
            drawCircle(goldSoft, r * 0.5f, c, style = Stroke(lw))
        }

        LaneGlyph.bruecke, LaneGlyph.mittelhuegel -> hill(g, lw, 0.5f, 0.16f)

        LaneGlyph.passagen -> {
            line(Offset(g.x(0.36f), g.midY), Offset(g.x(0.70f), g.midY), gold, lw * 1.2f)
            hill(g, lw, 0.53f, 0.12f, -1f, -0.05f)
            hill(g, lw, 0.53f, 0.12f, 0.05f, 1f)
        }

        LaneGlyph.sprungschanze -> {
            stroke(Path().apply {
                moveTo(g.x(0.55f), g.y(-1f))
                lineTo(g.x(1f), g.y(-1f))
                lineTo(g.x(1f), g.y(1f))
                lineTo(g.x(0.55f), g.y(1f))
            }, gold, lw)
            line(g.p(0.55f, 1f), g.p(1f, -1f), goldSoft, lw)
        }

        LaneGlyph.zielkreisfenster, LaneGlyph.auflaufkeil -> {
            val t = if (glyph == LaneGlyph.auflaufkeil) 0.58f else 0.66f
            line(g.p(t, -1f), g.p(t, -0.22f), gold, lw * 1.6f)
            line(g.p(t, 0.22f), g.p(t, 1f), gold, lw * 1.6f)
            if (glyph == LaneGlyph.auflaufkeil) {
                line(g.p(t - 0.16f, -1f), g.p(t, -1f), goldSoft, lw * 2.2f)
                line(g.p(t - 0.16f, 1f), g.p(t, 1f), goldSoft, lw * 2.2f)
            }
        }

        LaneGlyph.rohr -> {
            val len = (g.laneRight - g.laneLeft) * 0.22f
            val rect = Rect(Offset(g.x(0.52f), g.midY - g.half * 0.22f), Size(len, g.half * 0.44f))
            fillStroke(Path().apply { addRoundRect(RoundRect(rect, CornerRadius(rect.height / 2))) })
            line(Offset(rect.center.x, g.y(-1f)), Offset(rect.center.x, rect.top), gold, lw * 1.4f)
            line(Offset(rect.center.x, rect.bottom), Offset(rect.center.x, g.y(1f)), gold, lw * 1.4f)
        }

        LaneGlyph.staebe -> {
            for ((t, side) in listOf(0.34f to -1f, 0.52f to 1f, 0.70f to -1f)) {
                line(g.p(t, side), g.p(t, side * -0.35f), gold, lw * 1.6f)
            }
        }

        LaneGlyph.labyrinth -> {
            val side = g.half * 1.5f
            val rect = Rect(Offset(g.x(0.5f) - side / 2, g.midY - side / 2), Size(side, side))
            drawRect(gold, rect.topLeft, rect.size, style = Stroke(lw))
            drawRect(goldSoft, Offset(rect.center.x - side * 0.14f, rect.center.y - side * 0.18f),
                Size(side * 0.28f, side * 0.36f), style = Stroke(lw))
            // Vier Eingänge auf der Abschlagseite, einer offen.
            for (i in 0 until 4) {
                val y = rect.top + side * (0.2f + 0.2f * i)
                line(Offset(rect.left - g.half * 0.35f, y), Offset(rect.left, y),
                    if (i == 2) Color.White.copy(alpha = 0.85f) else goldSoft, lw)
            }
        }

        LaneGlyph.kegel -> {
            for (t in listOf(0.42f, 0.62f)) {
                val r = g.half * 0.55f
                val c = Offset(g.x(t), g.midY + if (t < 0.5f) -g.half * 0.35f else g.half * 0.35f)
                drawCircle(goldSoft, r, c)
                drawCircle(gold, r, c, style = Stroke(lw))
                drawCircle(gold, r * 0.45f, c, style = Stroke(lw * 0.8f))
            }
        }

        LaneGlyph.doppelkeile -> {
            for (side in listOf(-1f, 1f)) {
                fillStroke(Path().apply {
                    moveTo(g.x(0.40f), g.y(side))
                    lineTo(g.x(0.66f), g.y(side))
                    lineTo(g.x(0.66f), g.y(side * 0.2f))
                    close()
                })
            }
        }

        LaneGlyph.vulkan -> {
            val r = g.half * 1.05f
            val c = Offset(g.x(0.62f), g.midY)
            for (f in listOf(1f, 0.62f)) drawCircle(gold, r * f, c, style = Stroke(lw))
        }

        LaneGlyph.vHindernis -> {
            line(g.p(0.38f, -1f), g.p(0.74f, -0.18f), gold, lw * 1.6f)
            line(g.p(0.38f, 1f), g.p(0.74f, 0.18f), gold, lw * 1.6f)
        }

        LaneGlyph.winkel -> line(g.p(0.34f, -1f), g.p(0.62f, 0.35f), gold, lw * 1.8f)

        LaneGlyph.blitz -> {
            line(g.p(0.26f, -1f), g.p(0.50f, 0.25f), gold, lw * 1.8f)
            line(g.p(0.52f, 1f), g.p(0.76f, -0.25f), gold, lw * 1.8f)
        }

        LaneGlyph.plateau -> {
            val rect = Rect(Offset(g.x(0.52f), g.y(-0.78f)), Size((g.laneRight - g.laneLeft) * 0.34f, g.half * 1.56f))
            fillStroke(Path().apply { addRoundRect(RoundRect(rect, CornerRadius(g.half * 0.2f))) })
            line(Offset(g.x(0.36f), g.midY - g.half * 0.24f), Offset(rect.left, g.midY - g.half * 0.24f), gold, lw)
            line(Offset(g.x(0.36f), g.midY + g.half * 0.24f), Offset(rect.left, g.midY + g.half * 0.24f), gold, lw)
        }

        LaneGlyph.steilschraege -> {
            for (i in 0 until 4) {
                val t = 0.34f + 0.11f * i
                line(g.p(t, -1f), g.p(t + 0.06f, 1f), goldSoft, lw)
            }
        }

        LaneGlyph.rampe -> {
            line(g.p(0.46f, -1f), g.p(0.46f, 1f), gold, lw * 1.4f)
            line(g.p(0.62f, -1f), g.p(0.62f, 1f), gold, lw * 1.4f)
            line(Offset(g.x(0.46f), g.midY), Offset(g.x(0.62f), g.midY), goldSoft, lw)
        }

        LaneGlyph.raute -> {
            fillStroke(Path().apply {
                moveTo(g.x(0.40f), g.midY)
                lineTo(g.x(0.54f), g.y(-0.8f))
                lineTo(g.x(0.68f), g.midY)
                lineTo(g.x(0.54f), g.y(0.8f))
                close()
            })
        }

        LaneGlyph.zielhuegel -> drawCircle(gold, g.targetRadius * 0.72f, g.targetCenter, style = Stroke(lw))
    }
}

/** Hügel quer über die Bahn – als Höhenlinien angedeutet. */
private fun DrawScope.hill(g: SketchGeometry, lw: Float, t: Float, width: Float, from: Float = -1f, to: Float = 1f) {
    listOf(-width, 0f, width).forEachIndexed { i, off ->
        drawLine(
            AppTheme.gold.copy(alpha = if (i == 1) 1f else 0.35f),
            g.p(t + off, from), g.p(t + off, to),
            if (i == 1) lw * 1.4f else lw,
        )
    }
}
