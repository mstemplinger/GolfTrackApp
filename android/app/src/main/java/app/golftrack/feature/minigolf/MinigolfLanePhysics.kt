package app.golftrack.feature.minigolf

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.asin
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt

/*
 * Bahngeometrie, Ballsimulation und Schlagwerte der 28 Normbahnen –
 * 1:1 nach MinigolfLanePhysics.swift. Reine Mathematik, ohne Android.
 */

// MARK: - Vektoren

internal data class V2(val x: Float, val y: Float) {
    operator fun plus(o: V2) = V2(x + o.x, y + o.y)
    operator fun minus(o: V2) = V2(x - o.x, y - o.y)
    operator fun times(s: Float) = V2(x * s, y * s)
    operator fun div(s: Float) = V2(x / s, y / s)
    operator fun unaryMinus() = V2(-x, -y)
    infix fun dot(o: V2) = x * o.x + y * o.y
    val length: Float get() = sqrt(x * x + y * y)
    val lengthSquared: Float get() = x * x + y * y

    companion object {
        val ZERO = V2(0f, 0f)
    }
}

internal operator fun Float.times(v: V2) = V2(this * v.x, this * v.y)
internal fun dist(a: V2, b: V2) = (a - b).length

internal data class V3(val x: Float, val y: Float, val z: Float) {
    operator fun plus(o: V3) = V3(x + o.x, y + o.y, z + o.z)
    operator fun minus(o: V3) = V3(x - o.x, y - o.y, z - o.z)
    operator fun times(s: Float) = V3(x * s, y * s, z * s)
    operator fun div(s: Float) = V3(x / s, y / s, z / s)
    infix fun dot(o: V3) = x * o.x + y * o.y + z * o.z
    infix fun cross(o: V3) = V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x)
    val length: Float get() = sqrt(x * x + y * y + z * z)
    fun normalized(): V3 = length.let { if (it > 1e-9f) this / it else this }

    companion object {
        val ZERO = V3(0f, 0f, 0f)
    }
}

internal operator fun Float.times(v: V3) = V3(this * v.x, this * v.y, this * v.z)
internal fun dist(a: V3, b: V3) = (a - b).length

private const val PI_F = PI.toFloat()

// MARK: - Geometrie

/**
 * Geometrie einer Normbahn – gemeinsame Grundlage für das 3D-Modell und die
 * Ballsimulation, damit Spur und sichtbare Körper nicht auseinanderlaufen.
 *
 * Koordinaten in Metern: x längs (0 = Abschlag), y oben, z quer (+z = rechte Bande).
 */
internal class MinigolfLaneCourse(val lane: MinigolfStandardLane) {

    companion object {
        const val BALL_RADIUS = 0.03f
        const val HALF = 0.45f            // halbe Bahnbreite
        const val BANDE_HEIGHT = 0.08f
        const val BANDE_THICKNESS = 0.04f
        const val HOLE_RADIUS = 0.05f
        /** Unterkante des Sockels, auf dem Bahn und Zielkreis stehen. */
        const val BASE = -0.2f

        /** Halbe Kosinuswelle der Breite `width` um `center`. */
        fun bump(x: Float, center: Float, width: Float, height: Float): Float {
            val u = (x - center) / (width / 2)
            if (abs(u) >= 1) return 0f
            return height * (1 + cos(PI_F * u)) / 2
        }
    }

    enum class Surface { FELT, OBSTACLE, BANDE }

    /**
     * Körper auf der Bahn. Alle außer `Profile` und nicht festen Kegeln sind
     * zugleich Kollisionskörper.
     */
    sealed class Part {
        data class Box(val x0: Float, val x1: Float, val z0: Float, val z1: Float, val y0: Float, val y1: Float,
                       val surface: Surface, val chamfer: Float) : Part()
        /** Gerade Wand zwischen zwei Punkten der Draufsicht (x, z). */
        data class Wall(val from: V2, val to: V2, val height: Float, val thickness: Float) : Part()
        /** Flacher Körper mit Grundriss (x, z). */
        data class Plate(val outline: List<V2>, val y0: Float, val height: Float) : Part()
        /** Ringförmige Wand, Winkel 0 = Spielrichtung, positiv zur rechten Bande. */
        data class ArcWall(val center: V2, val radiusIn: Float, val radiusOut: Float, val from: Float, val to: Float,
                           val y0: Float, val height: Float) : Part()
        data class Pyramid(val x: Float, val z: Float, val width: Float, val height: Float) : Part()
        data class Cone(val x: Float, val z: Float, val bottomRadius: Float, val topRadius: Float, val height: Float,
                        val solid: Boolean) : Part()
        data class Cylinder(val x: Float, val z: Float, val radius: Float, val height: Float) : Part()
        /** Senkrechter Ring (Salto), steht bei (x, z) auf der Bahn. */
        data class Ring(val x: Float, val z: Float, val radius: Float, val pipe: Float) : Part()
        /** Rohr längs der Bahn. */
        data class Pipe(val x0: Float, val x1: Float, val axisY: Float, val inner: Float, val outer: Float) : Part()
        /** Geländekörper mit Seitenprofil (x, y) – die Höhe steckt in `laneTerrain`, keine Kollision. */
        data class Profile(val outline: List<V2>, val z0: Float, val z1: Float, val surface: Surface) : Part()
    }

    /** Senkrechter Looping: Ball läuft innen im Kreis um (x, centerY). */
    data class Salto(val x: Float, val centerY: Float, val radius: Float, val halfGap: Float, val shift: Float)

    /** Liegende Schleife: Rinne um `center`, der Ball läuft einmal ganz herum. */
    data class Rinne(
        val center: V2,
        val radius: Float,
        val entryZ: ClosedFloatingPointRange<Float>,
        val maxSpeed: Float,
        /** Winkel über die volle Runde hinaus, an dem die Auslauflippe den Ball freigibt. */
        val exitExtra: Float = 0f,
    )

    data class Pipe(val x0: Float, val x1: Float, val inner: Float)

    sealed class Goal {
        data class Hole(val p: V3) : Goal()
        /** Labyrinth: Loch oder liegen bleiben in der Zielkammer. */
        data class Chamber(val hole: V3, val x: ClosedFloatingPointRange<Float>, val z: ClosedFloatingPointRange<Float>) : Goal()
        /** Sprungschanze: Ball fällt von oben durch den Netzring. */
        data class Net(val center: V3, val radius: Float) : Goal()

        val point: V3
            get() = when (this) {
                is Hole -> p
                is Chamber -> hole
                is Net -> center
            }
    }

    /** Ende der Banden des geraden Teils. */
    var wallEnd = 0f; private set
    /** Mitte und Radius des Zielkreises (bei der Sprungschanze null). */
    var circleCenter: Float? = null; private set
    var circleRadius = 0.7f; private set
    var tilt = 0f; private set
    var targetY = 0f; private set
    var extent = 6.25f; private set

    /** Höhe der Bahnoberfläche im geraden Teil. */
    var laneTerrain: (Float, Float) -> Float = { _, _ -> 0f }; private set
    /** Zusätzliche Höhe im Zielkreis (Zielhügel), Koordinaten relativ zur Kreismitte. */
    var circleTerrain: (Float, Float) -> Float = { _, _ -> 0f }; private set

    val parts = mutableListOf<Part>()
    var goal: Goal = Goal.Hole(V3.ZERO); private set
    /** Liegt das Loch im Zielkreis (sonst gehört es zu einem Hindernis)? */
    var holeInCircle = true; private set
    var salto: Salto? = null; private set
    var rinne: Rinne? = null; private set
    var pipe: Pipe? = null; private set
    /** Bahn, auf der laut Tipp über Bande oder Hindernis gespielt wird. */
    var prefersBank = false; private set
    var colliders: List<MinigolfCollider> = emptyList(); private set

    init {
        when (lane.shape) {
            LaneShape.straight -> {
                circleCenter = 5.55f
                circleRadius = 0.70f
            }
            LaneShape.tiltedCircle -> {
                circleCenter = 4.45f
                circleRadius = 1.15f
                tilt = 0.10f
                extent = 5.6f
            }
            LaneShape.jump -> {
                circleCenter = null
                wallEnd = 2.5f
                extent = 4.4f
            }
        }
        circleCenter?.let { cx -> wallEnd = cx - sqrt(circleRadius * circleRadius - HALF * HALF) }
        buildObstacles()
        val cx = circleCenter
        if (holeInCircle && cx != null) {
            goal = Goal.Hole(V3(cx, targetY + circleTerrain(0f, 0f), 0f))
        }
        rinne?.let { rn ->
            rinne = rn.copy(exitExtra = atan2(rn.radius - goal.point.z, goal.point.x - rn.center.x))
        }
        buildColliders()
    }

    /** Höhe der Oberfläche an (x, z) – Bahn, Zielkreis oder (hinter der Schanze) der Boden. */
    fun ground(x: Float, z: Float): Float {
        val cx = circleCenter
        if (cx != null && x > wallEnd - 0.01f) {
            val dx = x - cx
            if (sqrt(dx * dx + z * z) <= circleRadius + 0.01f) {
                return targetY - z * sin(tilt) + circleTerrain(dx, z)
            }
        }
        if (cx == null && x > wallEnd) return BASE
        return laneTerrain(x, z)
    }

    // MARK: Hindernisse je Bahn

    private fun buildObstacles() {
        val h = HALF
        when (lane.glyph) {
            LaneGlyph.keines -> Unit

            LaneGlyph.pyramiden -> {
                prefersBank = true
                parts += Part.Pyramid(2.1f, -0.2f, 0.5f, 0.22f)
                parts += Part.Pyramid(3.0f, 0.2f, 0.5f, 0.22f)
            }

            LaneGlyph.salto -> {
                val s = Salto(x = 2.6f, centerY = 0.25f, radius = 0.22f, halfGap = 0.047f, shift = 0.04f)
                salto = s
                for (z in listOf(-0.09f, 0.09f)) parts += Part.Ring(s.x, z, 0.25f, 0.013f)
            }

            LaneGlyph.niere -> {
                for (side in listOf(-1f, 1f)) {
                    parts += Part.Box(1.4f, 2.4f, if (side < 0) -0.32f else 0.09f, if (side < 0) -0.09f else 0.32f,
                        0f, 0.12f, Surface.OBSTACLE, 0.06f)
                }
                // Tunneldach: liegt höher als der Ball, also keine Kollision.
                parts += Part.Box(1.45f, 2.35f, -0.1f, 0.1f, 0.08f, 0.12f, Surface.OBSTACLE, 0f)
            }

            LaneGlyph.doppelwellen -> {
                val waves = listOf(Triple(2.1f, 0.5f, 0.05f), Triple(3.0f, 0.5f, 0.05f))
                laneTerrain = { x, _ -> waves.fold(0f) { acc, w -> acc + bump(x, w.first, w.second, w.third) } }
                for (w in waves) bumpBody(w.first, w.second, w.third, -h, h)
            }

            LaneGlyph.liegendeSchleife -> {
                val c = V2(2.6f, 0f)
                parts += Part.ArcWall(c, 0.38f, 0.41f, 145 * PI_F / 180, (360 + 35) * PI_F / 180, 0f, 0.08f)
                parts += Part.Cylinder(c.x, c.y, 0.18f, 0.08f)
                rinne = Rinne(c, 0.35f, 0.21f..0.35f, 3.0f)
            }

            LaneGlyph.bruecke, LaneGlyph.mittelhuegel -> {
                val (w, ht) = if (lane.glyph == LaneGlyph.bruecke) 0.9f to 0.12f else 1.0f to 0.08f
                laneTerrain = { x, _ -> bump(x, 2.6f, w, ht) }
                bumpBody(2.6f, w, ht, -h, h)
            }

            LaneGlyph.sprungschanze -> {
                // Steile Schanze (Absprung gut 55°), danach fliegt der Ball frei.
                laneTerrain = { x, _ -> if (x > 1.7f) 0.25f * min(1f, (x - 1.7f) / 0.8f).pow(4.6f) else 0f }
                val ramp = mutableListOf(V2(1.7f, 0f))
                for (i in 1..24) {
                    val x = 1.7f + 0.8f * i / 24f
                    ramp += V2(x, laneTerrain(x, 0f))
                }
                ramp += V2(2.5f, 0f)
                parts += Part.Profile(ramp, -h, h, Surface.OBSTACLE)
                // Ringunterkante knapp 77 cm über dem Abschlag (Regel: 70–80 cm).
                goal = Goal.Net(V3(3.75f, 0.78f, 0f), 0.25f)
                holeInCircle = false
            }

            LaneGlyph.zielkreisfenster -> window(4.75f, 0f, 0.065f)

            LaneGlyph.auflaufkeil -> {
                laneTerrain = { x, _ ->
                    when {
                        x < 3.7f || x > 5.0f -> 0f
                        x < 4.5f -> 0.08f * (x - 3.7f) / 0.8f
                        x < 4.9f -> 0.08f
                        else -> 0.08f * (5.0f - x) / 0.1f
                    }
                }
                parts += Part.Profile(listOf(V2(3.7f, 0f), V2(4.5f, 0.08f), V2(4.9f, 0.08f), V2(5.0f, 0f)), -h, h, Surface.OBSTACLE)
                window(4.6f, 0.08f, 0.065f)
            }

            LaneGlyph.rohr -> {
                val p = Pipe(3.7f, 4.8f, 0.036f)
                pipe = p
                parts += Part.Pipe(p.x0, p.x1, 0.038f, p.inner, 0.05f)
                parts += Part.Box(4.22f, 4.28f, -h, -0.05f, 0f, 0.12f, Surface.OBSTACLE, 0f)
                parts += Part.Box(4.22f, 4.28f, 0.05f, h, 0f, 0.12f, Surface.OBSTACLE, 0f)
            }

            LaneGlyph.staebe -> {
                prefersBank = true
                for ((x, side) in listOf(1.7f to -1f, 2.6f to 1f, 3.5f to -1f)) {
                    val z0 = if (side < 0) -h else -0.16f
                    val z1 = if (side < 0) 0.16f else h
                    parts += Part.Box(x - 0.015f, x + 0.015f, z0, z1, 0.01f, 0.06f, Surface.OBSTACLE, 0f)
                }
            }

            LaneGlyph.labyrinth -> {
                val t = 0.03f
                val ht = 0.08f
                fun wallBox(x0: Float, x1: Float, z0: Float, z1: Float) {
                    parts += Part.Box(x0, x1, z0, z1, 0f, ht, Surface.OBSTACLE, 0f)
                }
                // Kasten mit vier Eingängen auf der Abschlagseite.
                wallBox(2.96f - t, 2.96f, -0.36f, 0.36f)
                wallBox(2.24f, 2.96f, -0.36f, -0.36f + t)
                wallBox(2.24f, 2.96f, 0.36f - t, 0.36f)
                for ((z0, z1) in listOf(-0.36f to -0.29f, -0.19f to -0.13f, -0.03f to 0.03f, 0.13f to 0.19f, 0.29f to 0.36f)) {
                    wallBox(2.24f, 2.24f + t, z0, z1)
                }
                // Hinter den falschen Eingängen ist zu.
                wallBox(2.34f, 2.34f + t, -0.30f, -0.02f)
                wallBox(2.34f, 2.34f + t, 0.18f, 0.30f)
                // Zielkammer in der Mitte, offen zum zweiten Eingang von rechts.
                wallBox(2.48f, 2.48f + t, -0.14f, 0.03f)
                wallBox(2.48f, 2.72f, -0.14f, -0.14f + t)
                wallBox(2.48f, 2.72f, 0.14f - t, 0.14f)
                wallBox(2.72f - t, 2.72f, -0.14f, 0.14f)
                val r = BALL_RADIUS
                goal = Goal.Chamber(V3(2.61f, 0f, 0f), (2.48f + t + r)..(2.72f - t - r), (-0.14f + t + r)..(0.14f - t - r))
                holeInCircle = false
            }

            LaneGlyph.kegel -> {
                prefersBank = true
                for ((x, z) in listOf(2.1f to -0.18f, 3.1f to 0.18f)) {
                    parts += Part.Cone(x, z, 0.24f, 0.08f, 0.12f, solid = true)
                }
            }

            LaneGlyph.doppelkeile -> {
                for (side in listOf(-1f, 1f)) {
                    parts += Part.Plate(listOf(V2(2.0f, side * h), V2(3.3f, side * h), V2(3.3f, side * 0.09f)), 0f, 0.08f)
                }
                // Schüssel: Rand um das Ziel.
                circleTerrain = { x, z -> bump(sqrt(x * x + z * z), 0.15f, 0.09f, 0.04f) }
            }

            LaneGlyph.passagen -> {
                parts += Part.Box(1.9f, 3.6f, -0.015f, 0.015f, 0f, 0.08f, Surface.OBSTACLE, 0f)
                laneTerrain = { x, _ -> bump(x, 2.75f, 0.5f, 0.07f) }
                bumpBody(2.75f, 0.5f, 0.07f, -h, -0.015f)
                bumpBody(2.75f, 0.5f, 0.07f, 0.015f, h)
            }

            LaneGlyph.vulkan -> {
                val c = V2(3.2f, 0f)
                laneTerrain = { x, z ->
                    val d = dist(V2(x, z), c)
                    0.18f * min(1f, max(0f, (0.42f - d) / 0.27f))
                }
                parts += Part.Cone(c.x, c.y, 0.42f, 0.15f, 0.18f, solid = false)
                goal = Goal.Hole(V3(c.x, 0.18f, c.y))
                holeInCircle = false
            }

            LaneGlyph.vHindernis -> {
                val x0 = if (lane.shape == LaneShape.tiltedCircle) 1.2f else 1.9f
                val x1 = if (lane.shape == LaneShape.tiltedCircle) 2.6f else 3.7f
                for (side in listOf(-1f, 1f)) {
                    parts += Part.Wall(V2(x0, side * h), V2(x1, side * 0.08f), 0.07f, 0.03f)
                }
            }

            LaneGlyph.winkel -> {
                prefersBank = true
                parts += Part.Wall(V2(1.77f, -h), V2(3.22f, 0.16f), 0.1f, 0.04f)
            }

            LaneGlyph.blitz -> {
                prefersBank = true
                parts += Part.Wall(V2(1.3f, -h), V2(2.6f, 0.11f), 0.1f, 0.04f)
                parts += Part.Wall(V2(2.7f, h), V2(3.95f, -0.11f), 0.1f, 0.04f)
            }

            LaneGlyph.plateau -> {
                val top = 0.15f
                laneTerrain = { x, z ->
                    when {
                        x in 3.6f..5.0f && abs(z) <= 0.35f -> top
                        x >= 2.8f && x < 3.6f && abs(z) <= 0.13f -> top * (x - 2.8f) / 0.8f
                        else -> 0f
                    }
                }
                parts += Part.Profile(listOf(V2(2.8f, 0f), V2(3.6f, top), V2(3.6f, 0f)), -0.13f, 0.13f, Surface.OBSTACLE)
                parts += Part.Box(2.8f, 3.6f, -0.16f, -0.13f, 0f, top + 0.04f, Surface.OBSTACLE, 0f)
                parts += Part.Box(2.8f, 3.6f, 0.13f, 0.16f, 0f, top + 0.04f, Surface.OBSTACLE, 0f)
                parts += Part.Box(3.6f, 5.0f, -0.35f, 0.35f, 0f, top, Surface.OBSTACLE, 0.02f)
                goal = Goal.Hole(V3(4.3f, top, 0f))
                holeInCircle = false
            }

            LaneGlyph.steilschraege -> {
                val top = 0.3f
                targetY = top
                laneTerrain = { x, _ ->
                    when {
                        x < 1.8f -> 0f
                        x < 3.8f -> top * (x - 1.8f) / 2.0f
                        else -> top
                    }
                }
                parts += Part.Profile(
                    listOf(V2(1.8f, 0f), V2(3.8f, top), V2(wallEnd + 0.02f, top), V2(wallEnd + 0.02f, 0f)),
                    -h, h, Surface.FELT,
                )
            }

            LaneGlyph.rampe -> {
                laneTerrain = { x, _ ->
                    when {
                        x >= 2.4f && x < 3.0f -> 0.12f * (x - 2.4f) / 0.6f
                        x >= 3.0f && x <= 3.25f -> 0.12f
                        else -> 0f
                    }
                }
                parts += Part.Profile(listOf(V2(2.4f, 0f), V2(3.0f, 0.12f), V2(3.25f, 0.12f), V2(3.25f, 0f)), -h, h, Surface.OBSTACLE)
            }

            LaneGlyph.raute -> {
                prefersBank = true
                parts += Part.Plate(listOf(V2(2.08f, 0f), V2(2.81f, -0.36f), V2(3.54f, 0f), V2(2.81f, 0.36f)), 0f, 0.08f)
            }

            LaneGlyph.zielhuegel -> {
                circleTerrain = { x, z ->
                    val d = sqrt(x * x + z * z)
                    0.14f * min(1f, max(0f, (0.30f - d) / 0.24f))
                }
            }
        }
    }

    private fun bumpBody(center: Float, width: Float, height: Float, z0: Float, z1: Float) {
        val outline = (0..20).map { i ->
            val x = center - width / 2 + width * i / 20f
            V2(x, bump(x, center, width, height))
        }
        parts += Part.Profile(outline, z0, z1, Surface.OBSTACLE)
    }

    /** Quermauer mit schmalem Fenster in der Mitte. */
    private fun window(x: Float, y0: Float, gap: Float) {
        parts += Part.Box(x, x + 0.06f, -HALF, -gap, 0f, y0 + 0.13f, Surface.OBSTACLE, 0f)
        parts += Part.Box(x, x + 0.06f, gap, HALF, 0f, y0 + 0.13f, Surface.OBSTACLE, 0f)
    }

    // MARK: Kollisionskörper

    private fun buildColliders() {
        val h = HALF
        val t = BANDE_THICKNESS
        val r = BALL_RADIUS
        val list = mutableListOf<MinigolfCollider>()
        fun rect(x0: Float, x1: Float, z0: Float, z1: Float) = listOf(V2(x0, z0), V2(x1, z0), V2(x1, z1), V2(x0, z1))
        // Banden: seitlich und hinter dem Abschlag, immer höher als der Ball.
        list += MinigolfCollider(MinigolfCollider.Shape.Polygon(rect(-t, wallEnd, -h - t, -h), 0f), bande = true)
        list += MinigolfCollider(MinigolfCollider.Shape.Polygon(rect(-t, wallEnd, h, h + t), 0f), bande = true)
        list += MinigolfCollider(MinigolfCollider.Shape.Polygon(rect(-t, 0f, -h - t, h + t), 0f), bande = true)
        circleCenter?.let { cx ->
            val open = PI_F - asin(h / circleRadius)
            list += MinigolfCollider(
                MinigolfCollider.Shape.Sector(V2(cx, 0f), circleRadius, circleRadius + t, -open, open), bande = true,
            )
        }

        for (part in parts) {
            when (part) {
                is Part.Box -> {
                    val c = minOf(part.chamfer, (part.x1 - part.x0) / 2, (part.z1 - part.z0) / 2)
                    list += MinigolfCollider(
                        MinigolfCollider.Shape.Polygon(rect(part.x0 + c, part.x1 - c, part.z0 + c, part.z1 - c), c),
                        part.y0, part.y1,
                    )
                }
                is Part.Wall -> {
                    val d = (part.to - part.from).let { it / it.length }
                    val n = V2(-d.y, d.x) * (part.thickness / 2)
                    list += MinigolfCollider(
                        MinigolfCollider.Shape.Polygon(listOf(part.from - n, part.to - n, part.to + n, part.from + n), 0f),
                        0f, part.height,
                    )
                }
                is Part.Plate -> list += MinigolfCollider(MinigolfCollider.Shape.Polygon(part.outline, 0f), part.y0, part.y0 + part.height)
                is Part.ArcWall -> list += MinigolfCollider(
                    MinigolfCollider.Shape.Sector(part.center, part.radiusIn, part.radiusOut, part.from, part.to),
                    part.y0, part.y0 + part.height,
                )
                is Part.Pyramid -> {
                    // Querschnitt auf Höhe der Ballmitte – dort berührt der Ball die Flanke.
                    val w = part.width / 2 * (1 - r / part.height)
                    list += MinigolfCollider(MinigolfCollider.Shape.Polygon(rect(part.x - w, part.x + w, part.z - w, part.z + w), 0f), 0f, part.height)
                }
                is Part.Cone -> {
                    if (!part.solid) continue
                    val radius = part.bottomRadius + (part.topRadius - part.bottomRadius) * r / part.height
                    list += MinigolfCollider(MinigolfCollider.Shape.Circle(V2(part.x, part.z), radius), 0f, part.height)
                }
                is Part.Cylinder -> list += MinigolfCollider(MinigolfCollider.Shape.Circle(V2(part.x, part.z), part.radius), 0f, part.height)
                is Part.Ring -> {
                    // Nur der untere Teil des Rings liegt in Ballhöhe.
                    val foot = sqrt(part.radius * part.radius - (part.radius - 2 * r) * (part.radius - 2 * r))
                    list += MinigolfCollider(
                        MinigolfCollider.Shape.Polygon(rect(part.x - foot, part.x + foot, part.z - part.pipe, part.z + part.pipe), 0f),
                        0f, 2 * part.radius,
                    )
                }
                is Part.Pipe -> list += MinigolfCollider(
                    MinigolfCollider.Shape.Polygon(rect(part.x0, part.x1, -part.outer, part.outer), 0f),
                    0f, part.axisY + part.outer,
                )
                is Part.Profile -> continue
            }
        }
        colliders = list
    }
}

/** Kollisionskörper in der Draufsicht (x, z) mit Höhenbereich. */
internal class MinigolfCollider(
    val shape: Shape,
    val y0: Float = -10f,
    val y1: Float = 10f,
    bande: Boolean = false,
) {
    val isBande = bande

    sealed class Shape {
        /** Einfaches Polygon, um `rounding` aufgeweitet (abgerundete Kanten). */
        data class Polygon(val points: List<V2>, val rounding: Float) : Shape()
        data class Circle(val center: V2, val radius: Float) : Shape()
        /** Kreisringausschnitt von Winkel `from` bis `to`. */
        data class Sector(val center: V2, val radiusIn: Float, val radiusOut: Float, val from: Float, val to: Float) : Shape()
    }

    /**
     * Versperrt der Körper einen Ball, dessen Unterkante auf Höhe `bottom` liegt?
     * Kanten unter gut 1 cm (Rampe → Plateau) rollt der Ball hinauf.
     */
    fun blocks(ballBottom: Float): Boolean =
        y0 < ballBottom + 2 * MinigolfLaneCourse.BALL_RADIUS - 0.004f && y1 > ballBottom + 0.012f

    /** Vorzeichenbehafteter Abstand von `p` zur Oberfläche und Normale nach außen. */
    fun distance(p: V2): Pair<Float, V2> = when (shape) {
        is Shape.Circle -> {
            val d = p - shape.center
            val len = d.length
            (len - shape.radius) to (if (len > 1e-6f) d / len else V2(1f, 0f))
        }

        is Shape.Polygon -> {
            val points = shape.points
            var best = Float.MAX_VALUE
            var closest = p
            var inside = false
            var j = points.size - 1
            for (i in points.indices) {
                val a = points[j]
                val b = points[i]
                val q = closestOnSegment(p, a, b)
                val d = (p - q).lengthSquared
                if (d < best) { best = d; closest = q }
                if ((b.y > p.y) != (a.y > p.y) && p.x < (a.x - b.x) * (p.y - b.y) / (a.y - b.y) + b.x) {
                    inside = !inside
                }
                j = i
            }
            val dist = sqrt(best)
            if (dist <= 1e-7f) {
                -shape.rounding to V2(1f, 0f)
            } else {
                val n = (p - closest) / dist
                if (inside) (-dist - shape.rounding) to -n else (dist - shape.rounding) to n
            }
        }

        is Shape.Sector -> {
            val c = shape.center
            val d = p - c
            val rho = d.length
            val u = if (rho > 1e-6f) d / rho else V2(1f, 0f)
            var rel = atan2(d.y, d.x) - shape.from
            rel -= 2 * PI_F * floor(rel / (2 * PI_F))
            if (rel <= shape.to - shape.from) {
                when {
                    rho < shape.radiusIn -> (shape.radiusIn - rho) to -u
                    rho > shape.radiusOut -> (rho - shape.radiusOut) to u
                    rho - shape.radiusIn < shape.radiusOut - rho -> -(rho - shape.radiusIn) to -u
                    else -> -(shape.radiusOut - rho) to u
                }
            } else {
                // Außerhalb des Winkelbereichs: nächste Stirnseite.
                var best: Pair<Float, V2> = Float.MAX_VALUE to u
                for (a in listOf(shape.from, shape.to)) {
                    val dir = V2(cos(a), sin(a))
                    val q = closestOnSegment(p, c + shape.radiusIn * dir, c + shape.radiusOut * dir)
                    val dd = dist(p, q)
                    if (dd < best.first) best = dd to (if (dd > 1e-7f) (p - q) / dd else u)
                }
                best
            }
        }
    }

    private fun closestOnSegment(p: V2, a: V2, b: V2): V2 {
        val ab = b - a
        val len2 = ab.lengthSquared
        if (len2 <= 1e-12f) return a
        val t = min(1f, max(0f, ((p - a) dot ab) / len2))
        return a + t * ab
    }
}

// MARK: - Simulation

/** Schlag vom Abschlag: Querposition, Richtung (Grad, positiv zur rechten Bande) und Tempo. */
internal data class MinigolfShot(val z: Float, val angle: Float, val speed: Float)

/** Ergebnis eines simulierten Schlags. */
internal class MinigolfBallRun {
    enum class Outcome {
        HOLED,      // im Loch bzw. im Netz
        RESTING,    // in der Zielkammer liegen geblieben
        MISSED,
    }

    var outcome = Outcome.MISSED
    /** Ballmitte je Zeitschritt (`MinigolfBallSimulation.DT`), leer ohne Aufzeichnung. */
    val positions = ArrayList<V3>()
    /** Anschläge an Banden bzw. Hindernissen. */
    var bandeHits = 0
    var obstacleHits = 0
    /** Sonderweg (Salto, Schleife, Rohr) durchlaufen. */
    var passedFeature = false
    var duration = 0f
    /** Index in `positions`, ab dem der Ball ins Loch bzw. Netz fällt. */
    var sinkIndex: Int? = null

    val success: Boolean get() = outcome != Outcome.MISSED
}

/**
 * Rollender Ball auf der Bahnoberfläche, feste Zeitschritte.
 *
 * Modell: Rollen ohne Gleiten (Hangabtrieb 5/7 g sin α), Rollreibung als
 * konstante Verzögerung, Abpraller mit Restitution an allen Kollisionskörpern,
 * freier Flug mit g, wo das Gelände schneller abfällt, als der Ball fällt.
 * Salto, liegende Schleife und Rohr laufen geführt, aber mit derselben Reibung.
 */
internal object MinigolfBallSimulation {
    const val DT = 0.001f
    const val G = 9.81f
    /** Rollreibung auf Eternit/Filz in m/s². */
    const val ROLLING_DECEL = 0.45f
    const val RESTITUTION = 0.7f
    /** Anteil der Tangentialgeschwindigkeit, der einen Anschlag übersteht. */
    const val TANGENTIAL_KEEP = 0.96f
    const val START_X = 0.25f
    const val MAX_TIME = 25f

    private sealed class Mode {
        object Ground : Mode()
        object Air : Mode()
        data class Salto(val phi: Float, val speed: Float, val z0: Float) : Mode()
        data class Rinne(val phi: Float, val speed: Float, val radius0: Float) : Mode()
        data class Pipe(val speed: Float, val z0: Float, val x0: Float) : Mode()
        data class Sinking(val t: Float, val from: V3, val to: V3, val speed: Float) : Mode()
    }

    fun run(course: MinigolfLaneCourse, shot: MinigolfShot, record: Boolean = true): MinigolfBallRun {
        val r = MinigolfLaneCourse.BALL_RADIUS
        val gravity = V3(0f, -G, 0f)
        val run = MinigolfBallRun()
        var c = V3(START_X, course.ground(START_X, shot.z) + r, shot.z)
        val a0 = shot.angle * PI_F / 180
        var v = V3(cos(a0), 0f, sin(a0)) * shot.speed
        var mode: Mode = Mode.Ground
        var t = 0f
        var slowFor = 0f
        var overHole = false
        val goalPoint = course.goal.point
        if (record) { run.positions.ensureCapacity(8000); run.positions += c }

        fun normal(x: Float, z: Float): V3 {
            val e = 0.002f
            val hx = (course.ground(x + e, z) - course.ground(x - e, z)) / (2 * e)
            val hz = (course.ground(x, z + e) - course.ground(x, z - e)) / (2 * e)
            return V3(-hx, 1f, -hz).normalized()
        }

        // Salto, Schleife und Rohr sind vorgeschriebene Wege, das Netz sowieso.
        var needsFeature = course.salto != null || course.rinne != null || course.pipe != null
        if (course.goal is MinigolfLaneCourse.Goal.Net) needsFeature = true

        fun finish(outcome: MinigolfBallRun.Outcome): MinigolfBallRun {
            run.outcome = if (needsFeature && !run.passedFeature) MinigolfBallRun.Outcome.MISSED else outcome
            run.duration = t
            return run
        }

        while (t < MAX_TIME) {
            t += DT
            when (val m = mode) {
                is Mode.Sinking -> {
                    // Ball rollt zur Lochmitte bzw. ins Netz und fällt.
                    val len = max(dist(m.from, m.to), 1e-4f)
                    val s2 = m.t + DT * max(m.speed, 0.3f) / len
                    c = m.from + (m.to - m.from) * min(1f, s2)
                    if (record) run.positions += c
                    if (s2 >= 1) return finish(MinigolfBallRun.Outcome.HOLED)
                    mode = m.copy(t = s2)
                    continue
                }

                is Mode.Salto -> {
                    val s = course.salto ?: return finish(MinigolfBallRun.Outcome.MISSED)
                    var phi = m.phi
                    var speed = m.speed
                    val normalAcc = speed * speed / s.radius + G * cos(phi)
                    if (normalAcc < 0 || speed <= 0) return finish(MinigolfBallRun.Outcome.MISSED)   // fällt aus dem Looping
                    speed -= DT * ((5f / 7f) * G * sin(phi) + ROLLING_DECEL / G * normalAcc)
                    phi += DT * speed / s.radius
                    val z = m.z0 + s.shift * min(1f, phi / (2 * PI_F))
                    if (phi >= 2 * PI_F) {
                        run.passedFeature = true
                        c = V3(s.x, course.ground(s.x, z) + r, z)
                        v = V3(speed, 0f, 0f)
                        mode = Mode.Ground
                    } else {
                        c = V3(s.x + s.radius * sin(phi), s.centerY - s.radius * cos(phi), z)
                        mode = Mode.Salto(phi, speed, m.z0)
                    }
                    if (record) run.positions += c
                    continue
                }

                is Mode.Rinne -> {
                    val rn = course.rinne ?: return finish(MinigolfBallRun.Outcome.MISSED)
                    var phi = m.phi
                    var speed = m.speed
                    val radius = m.radius0 + (rn.radius - m.radius0) * min(1f, phi / (PI_F / 2))
                    // Reibung am Boden und an der Außenwand (Fliehkraft drückt dagegen).
                    speed -= DT * (ROLLING_DECEL + 0.012f * speed * speed / radius)
                    if (speed <= 0) return finish(MinigolfBallRun.Outcome.MISSED)
                    phi += DT * speed / radius
                    val a = PI_F / 2 - phi
                    c = V3(rn.center.x + radius * cos(a), r, rn.center.y + radius * sin(a))
                    if (phi >= 2 * PI_F + rn.exitExtra) {
                        run.passedFeature = true
                        v = speed * V3(sin(a), 0f, -cos(a))
                        mode = Mode.Ground
                    } else {
                        mode = Mode.Rinne(phi, speed, m.radius0)
                    }
                    if (record) run.positions += c
                    continue
                }

                is Mode.Pipe -> {
                    val p = course.pipe ?: return finish(MinigolfBallRun.Outcome.MISSED)
                    // Im Rohr etwas mehr Reibung, die Rohrwand zentriert den Ball.
                    val speed = m.speed - DT * ROLLING_DECEL * 1.3f
                    if (speed <= 0) return finish(MinigolfBallRun.Outcome.MISSED)    // bleibt im Rohr liegen
                    val x = c.x + speed * DT
                    val k = min(1f, (x - m.x0) / 0.12f)
                    c = V3(x, r + 0.002f, m.z0 * (1 - k))
                    if (x >= p.x1) {
                        run.passedFeature = true
                        v = V3(speed, 0f, 0f)
                        c = c.copy(y = course.ground(x, 0f) + r)
                        mode = Mode.Ground
                    } else {
                        mode = Mode.Pipe(speed, m.z0, m.x0)
                    }
                    if (record) run.positions += c
                    continue
                }

                Mode.Ground, Mode.Air -> Unit
            }

            val grounded = mode == Mode.Ground
            val prev = c

            // Beschleunigung: Hangabtrieb (rollend 5/7) und Rollreibung bzw. freier Fall.
            var acc = gravity
            if (grounded) {
                val n = normal(c.x, c.z)
                val gN = n * (gravity dot n)
                val gT = gravity - gN
                acc = gN + gT * (5f / 7f)
                val vt = v - n * (v dot n)
                val speedT = vt.length
                val friction = ROLLING_DECEL * n.y
                if (speedT <= friction * DT) {
                    v -= vt
                    if ((gT * (5f / 7f)).length <= friction) { v = V3.ZERO; acc = V3.ZERO }
                } else {
                    acc -= vt * (friction / speedT)
                }
            }
            c += v * DT + acc * (0.5f * DT * DT)
            v += acc * DT

            // Bodenkontakt: unter das Gelände → zurück auf die Oberfläche, Normalanteil weg;
            // fällt das Gelände schneller ab als der Ball → Flug.
            val hNew = course.ground(c.x, c.z)
            if (c.y - r <= hNew) {
                val n = normal(c.x, c.z)
                c = c.copy(y = hNew + r)
                val vn = v dot n
                if (vn < 0) v -= n * vn
                mode = Mode.Ground
            } else if (grounded && c.y - r < hNew + 1e-6f) {
                c = c.copy(y = hNew + r)
            } else {
                mode = Mode.Air
            }

            // Sonderwege.
            // Salto: Durchgang zwischen den Ringen, Ausgang um `shift` versetzt.
            val s = course.salto
            if (s != null && prev.x < s.x && c.x >= s.x && v.x > 0 &&
                c.z >= -s.halfGap && c.z <= s.halfGap - s.shift && mode == Mode.Ground
            ) {
                mode = Mode.Salto(0f, v.x, c.z)
                c = V3(s.x, s.centerY - s.radius, c.z)
                if (record) run.positions += c
                continue
            }
            val rn = course.rinne
            if (rn != null && prev.x < rn.center.x && c.x >= rn.center.x && v.x > 0 &&
                (c.z - rn.center.y) in rn.entryZ && mode == Mode.Ground
            ) {
                val speed = V2(v.x, v.z).length
                if (speed > rn.maxSpeed) return finish(MinigolfBallRun.Outcome.MISSED)   // hebt aus der Rinne
                mode = Mode.Rinne(0f, speed, c.z - rn.center.y)
                c = V3(rn.center.x, r, c.z)
                if (record) run.positions += c
                continue
            }
            val p = course.pipe
            if (p != null && c.x + r >= p.x0 && prev.x + r < p.x0 && abs(c.z) <= p.inner && v.x > 0) {
                mode = Mode.Pipe(v.x, c.z, c.x)
                if (record) run.positions += c
                continue
            }

            // Kollisionen in der Draufsicht, zweimal für Ecken.
            repeat(2) {
                for (col in course.colliders) {
                    if (!col.blocks(c.y - r)) continue
                    val pp = V2(c.x, c.z)
                    val (d, n) = col.distance(pp)
                    if (d >= r) continue
                    val q = pp + n * (r - d)
                    c = V3(q.x, c.y, q.y)
                    var vh = V2(v.x, v.z)
                    val vn = vh dot n
                    if (vn < 0) {
                        val tangential = vh - n * vn
                        vh = tangential * TANGENTIAL_KEEP - n * (RESTITUTION * vn)
                        v = V3(vh.x, v.y, vh.y)
                        if (-vn > 0.05f) {
                            if (col.isBande) run.bandeHits += 1 else run.obstacleHits += 1
                        }
                    }
                }
            }
            if (record) run.positions += c

            // Bahn verlassen: darf nicht passieren, gilt als Fehlschlag.
            if (abs(c.z) > 1.5f || c.x < -0.2f || c.x > course.extent + 1.5f || c.y < MinigolfLaneCourse.BASE - 0.5f) {
                return finish(MinigolfBallRun.Outcome.MISSED)
            }

            // Ziel.
            when (val goal = course.goal) {
                is MinigolfLaneCourse.Goal.Net -> {
                    val center = goal.center
                    if (mode == Mode.Air && prev.y >= center.y && c.y < center.y && v.y < 0 &&
                        dist(V2(c.x, c.z), V2(center.x, center.z)) <= goal.radius - 0.014f - r
                    ) {
                        run.passedFeature = true
                        val bottom = V3(center.x, center.y - 0.22f, center.z)
                        run.sinkIndex = run.positions.size
                        mode = Mode.Sinking(0f, c, bottom, v.length)
                        continue
                    }
                }
                is MinigolfLaneCourse.Goal.Hole, is MinigolfLaneCourse.Goal.Chamber -> if (mode == Mode.Ground) {
                    val horiz = V2(c.x - goalPoint.x, c.z - goalPoint.z)
                    val d = horiz.length
                    if (d < MinigolfLaneCourse.HOLE_RADIUS && abs(c.y - r - goalPoint.y) < 0.02f) {
                        val vh = V2(v.x, v.z)
                        val speed = vh.length
                        if (!overHole) {
                            overHole = true
                            // Fällt, wenn die Zeit über dem Loch für einen Fall um den Ballradius reicht.
                            val dir = if (speed > 1e-4f) vh / speed else V2(1f, 0f)
                            val off = -horiz
                            val perp = abs(dir.x * off.y - dir.y * off.x)
                            val rh = MinigolfLaneCourse.HOLE_RADIUS
                            val chord = 2 * sqrt(max(0f, rh * rh - perp * perp))
                            val capture = chord / sqrt(2 * r / G)
                            if (speed <= capture) {
                                val bottom = V3(goalPoint.x, goalPoint.y + r - 2.2f * r, goalPoint.z)
                                run.sinkIndex = run.positions.size
                                mode = Mode.Sinking(0f, c, bottom, speed)
                                continue
                            }
                        } else if (speed < 0.02f) {
                            val bottom = V3(goalPoint.x, goalPoint.y + r - 2.2f * r, goalPoint.z)
                            run.sinkIndex = run.positions.size
                            mode = Mode.Sinking(0f, c, bottom, 0.3f)
                            continue
                        }
                    } else {
                        overHole = false
                    }
                }
            }

            // Liegen geblieben?
            if (mode == Mode.Ground && v.length < 0.003f) {
                slowFor += DT
                if (slowFor > 0.3f) {
                    val goal = course.goal
                    if (goal is MinigolfLaneCourse.Goal.Chamber && c.x in goal.x && c.z in goal.z) {
                        return finish(MinigolfBallRun.Outcome.RESTING)
                    }
                    return finish(MinigolfBallRun.Outcome.MISSED)
                }
            } else {
                slowFor = 0f
            }
        }
        return finish(MinigolfBallRun.Outcome.MISSED)
    }
}

// MARK: - Schlagwerte

/**
 * Vorab gesuchte Schläge je Normbahn (Raster über Abschlagposition, Richtung und
 * Tempo, danach verfeinert). Zur Laufzeit wird nur noch einmal simuliert.
 */
internal object MinigolfLaneShots {
    fun shot(lane: MinigolfStandardLane): MinigolfShot = shots[lane.normNumber] ?: MinigolfShot(0f, 0f, 2f)

    val shots: Map<Int, MinigolfShot> = mapOf(
        1 to MinigolfShot(-0.03f, 24.2f, 2.54f), // Pyramiden
        2 to MinigolfShot(0.25f, 19f, 3.98f), // Salto
        3 to MinigolfShot(-0.15f, 5.2f, 2.86f), // Schräger Kreis mit Niere
        4 to MinigolfShot(-0.12f, 1.3f, 2.28f), // Doppelwellen
        5 to MinigolfShot(0f, 7.9f, 2.84f), // Liegende Schleife
        6 to MinigolfShot(0f, 0f, 2.28f), // Brücke
        7 to MinigolfShot(0f, 0f, 4.8f), // Sprungschanze mit Netz
        8 to MinigolfShot(0f, 0f, 2.28f), // Gerade Bahn mit Zielkreisfenster
        9 to MinigolfShot(0f, -0.2f, 2.34f), // Rohr
        10 to MinigolfShot(-0.32f, 34.6f, 5.74f), // Stäbe
        11 to MinigolfShot(0.22f, -3.8f, 1.5f), // Labyrinth
        12 to MinigolfShot(0f, 23.7f, 2.54f), // Stumpfe Kegel
        13 to MinigolfShot(-0.1f, 1f, 2.5f), // Doppelkeile
        14 to MinigolfShot(-0.2f, 2.1f, 2.24f), // Passagen
        15 to MinigolfShot(0f, 0f, 2.28f), // Mittelhügel
        16 to MinigolfShot(-0.1f, 2f, 2.5f), // Vulkan
        17 to MinigolfShot(0f, 0f, 2.28f), // V-Hindernis
        18 to MinigolfShot(0f, 0.1f, 2.74f), // Winkel
        19 to MinigolfShot(0f, 4.7f, 2.84f), // Blitz
        20 to MinigolfShot(0f, 0f, 2.28f), // Gerade Bahn ohne Hindernisse
        21 to MinigolfShot(-0.15f, 20f, 2.3f), // Schräger Kreis ohne Hindernisse
        22 to MinigolfShot(0f, 0f, 2.5f), // Plateau
        23 to MinigolfShot(0.02f, -0.3f, 2.44f), // Auflaufkeil mit Zielfenster
        24 to MinigolfShot(-0.03f, 0.2f, 3.08f), // Steilschräge ohne Hindernisse
        25 to MinigolfShot(-0.28f, 6.8f, 2.88f), // Schräger Kreis mit V-Hindernis
        26 to MinigolfShot(-0.03f, 0.3f, 2.56f), // Gerade Bahn mit Rampe
        27 to MinigolfShot(-0.08f, 11.3f, 2.36f), // Raute
        28 to MinigolfShot(0f, 0f, 2.74f), // Gerade Bahn mit Zielhügel
    )
}
