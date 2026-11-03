package app.golftrack.feature.minigolf

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import app.golftrack.ui.theme.AppTheme
import kotlin.math.PI
import kotlin.math.asin
import kotlin.math.atan2
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Dreidimensionales Modell einer genormten Miniaturgolfbahn mit Idealspur –
 * wie MinigolfLane3DModel.swift, aber als Dreiecksliste für den eigenen
 * Canvas-Renderer statt SceneKit.
 *
 * In Metern gebaut: Bahn 0,90 m breit, Zielkreis 1,40 m, Gesamtlänge um 6,25 m.
 * Koordinaten: x längs der Bahn, y nach oben, z quer (+z = rechte Bande).
 * Die Bahnmitte liegt im Ursprung, damit die Kamera um die Bahn kreist.
 *
 * Geometrie und Kollisionskörper kommen aus `MinigolfLaneCourse`, die Idealspur
 * ist ein simulierter Schlag (`MinigolfBallSimulation`) mit den Werten aus
 * `MinigolfLaneShots`. Sie ist – wie der Tipp – eine Empfehlung der App, keine Regel.
 */
internal class MinigolfLaneModel private constructor(
    /** Je Dreieck 9 Koordinaten. */
    val vertices: FloatArray,
    /** Je Dreieck Normale und Schwerpunkt (je 3). */
    val normals: FloatArray,
    val centroids: FloatArray,
    /** Fertig schattierte Farbe je Dreieck. */
    val colors: IntArray,
    /** Bit 0: beidseitig, Bit 1: gehört zur Idealspur. */
    val flags: ByteArray,
    /** Tiefenversatz (negativ = weiter vorn), gegen Flackern bei aufliegenden Flächen. */
    val bias: FloatArray,
    /** Boden: wird immer zuerst gezeichnet, er verdeckt nie etwas. */
    val floor: FloatArray,
    val floorColor: Int,
    /** Ausgedünnte Spur für die Linie. */
    val idealSamples: List<V3>,
    /** Ballmitte je Zeitschritt der Simulation. */
    val ballPositions: List<V3>,
) {
    val triangleCount: Int get() = colors.size

    companion object {
        /** Farbe der Idealspur, auch für Legende und Schalter. */
        val idealColor = Color(0.42f, 0.86f, 1.0f)

        const val FLAG_TWO_SIDED: Byte = 1
        const val FLAG_IDEAL: Byte = 2

        /** Ausgangsposition der Kamera schräg hinter dem Abschlag. */
        val homeEye = V3(-4.3f, 3.3f, 4.4f)
        val homeTarget = V3(0.2f, 0f, 0f)

        fun build(lane: MinigolfStandardLane): MinigolfLaneModel {
            val course = MinigolfLaneCourse(lane)
            val run = MinigolfBallSimulation.run(course, MinigolfLaneShots.shot(lane))
            return Builder(course, run).build()
        }
    }

    // MARK: - Aufbau

    private class Builder(val course: MinigolfLaneCourse, val run: MinigolfBallRun) {
        private val lane get() = course.lane
        private val half = MinigolfLaneCourse.HALF
        private val base = MinigolfLaneCourse.BASE
        private val bandeHeight = MinigolfLaneCourse.BANDE_HEIGHT
        private val bandeThickness = MinigolfLaneCourse.BANDE_THICKNESS

        private val felt = Color(0.21f, 0.55f, 0.33f)
        private val feltDark = Color(0.17f, 0.47f, 0.28f)
        private val tee = Color(0.62f, 0.74f, 0.64f)
        private val bande = Color(0.90f, 0.90f, 0.90f)
        private val obstacle = AppTheme.gold
        private val holeColor = Color(0.04f, 0.04f, 0.04f)

        private val mesh = Mesh()
        /** Bahnmitte in den Ursprung. */
        private val offset = V3(-course.extent / 2, 0f, 0f)

        fun build(): MinigolfLaneModel {
            mesh.xf = { it + offset }
            buildLane()
            buildTarget()
            mesh.xf = { it + offset }
            mesh.rot = { it }
            for (part in course.parts) render(part)
            buildDecorations()
            val samples = buildIdealLine(run.positions)
            return MinigolfLaneModel(
                vertices = mesh.v.toFloatArray(),
                normals = mesh.n.toFloatArray(),
                centroids = mesh.c.toFloatArray(),
                colors = mesh.col.toIntArray(),
                flags = mesh.flags.toByteArray(),
                bias = mesh.bias.toFloatArray(),
                floor = buildFloor(),
                floorColor = AppTheme.bg.toArgb(),
                idealSamples = samples.map { it + offset },
                ballPositions = run.positions.map { it + offset },
            )
        }

        private fun surfaceColor(s: MinigolfLaneCourse.Surface) = when (s) {
            MinigolfLaneCourse.Surface.FELT -> felt
            MinigolfLaneCourse.Surface.OBSTACLE -> obstacle
            MinigolfLaneCourse.Surface.BANDE -> bande
        }

        // MARK: Bahn

        private fun buildLane() {
            val wallEnd = course.wallEnd
            val surfaceEnd = if (course.circleCenter == null) wallEnd else wallEnd + 0.02f
            // Nur Oberseiten: die Seiten verdecken Banden und Zielkreis ohnehin, und
            // deckungsgleiche Flächen würden beim Sortieren flackern. Abschlag und
            // Filz liegen deshalb nebeneinander statt übereinander.
            val up = V3(0f, 1f, 0f)
            mesh.quad(V3(0f, 0f, -half), V3(0.35f, 0f, -half), V3(0.35f, 0f, half), V3(0f, 0f, half), tee, up)
            mesh.quad(V3(0.35f, 0f, -half), V3(surfaceEnd, 0f, -half), V3(surfaceEnd, 0f, half), V3(0.35f, 0f, half), felt, up)
            if (course.circleCenter == null) {
                // Bahnende vor der Schanze-Landezone.
                mesh.quad(V3(surfaceEnd, base, -half), V3(surfaceEnd, base, half), V3(surfaceEnd, 0f, half), V3(surfaceEnd, 0f, -half), felt, V3(1f, 0f, 0f))
            }

            // Banden folgen dem Gelände, damit sie bei Steilschräge & Co. nicht im Boden stecken.
            for (side in listOf(-1f, 1f)) {
                val z = side * (half + bandeThickness / 2)
                val top = mutableListOf<V2>()
                var x = -bandeThickness
                while (x < wallEnd) {
                    top += V2(x, max(0f, course.laneTerrain(max(0f, x), side * half)) + bandeHeight)
                    x += 0.05f
                }
                top += V2(wallEnd, course.laneTerrain(wallEnd, side * half) + bandeHeight)
                val outline = listOf(V2(-bandeThickness, base)) + top + listOf(V2(wallEnd, base))
                mesh.profile(outline, z - bandeThickness / 2, z + bandeThickness / 2, bande)
            }
            mesh.prism(rect(-bandeThickness, 0f, -half, half), base, bandeHeight, bande)
        }

        private fun buildTarget() {
            val cx = course.circleCenter ?: return
            val radius = course.circleRadius
            val tilt = course.tilt
            // Gruppe: um x geneigt, bei (cx, targetY, 0).
            val ct = cos(tilt)
            val st = sin(tilt)
            val groupRot: (V3) -> V3 = { p -> V3(p.x, p.y * ct - p.z * st, p.y * st + p.z * ct) }
            val origin = V3(cx, course.targetY, 0f) + offset
            mesh.rot = groupRot
            mesh.xf = { p -> groupRot(p) + origin }

            // Zielkreis samt Sockel bis zum Boden. Beim geneigten Kreis reicht der
            // Sockel nur bis knapp unter die tiefste Stelle, die Bande verdeckt den Rest.
            val top = 0.004f
            val bottom = if (tilt > 0) -0.03f else base - course.targetY
            // Nur die Oberseite – Rand und Sockel stecken in der Kreisbande.
            mesh.disk(V3(0f, top, 0f), radius, feltDark, bias = 0f, rings = 6, segments = 48)

            // Bande um den Kreis, offen dort, wo die Bahn einmündet.
            val open = PI.toFloat() - asin(half / radius)
            val extra = if (tilt > 0) 0.3f else 0f
            mesh.arcWall(V2.ZERO, radius, radius + bandeThickness, -open, open, bottom - extra, bandeHeight - bottom + extra, bande)

            if (lane.glyph == LaneGlyph.zielhuegel) {
                mesh.frustum(0f, 0f, 0.30f, 0.06f, 0f, 0.14f, obstacle)
            }
            if (lane.glyph == LaneGlyph.doppelkeile) {
                // Schüssel: Rand um das Ziel.
                mesh.torusFlat(V3.ZERO, 0.15f, 0.022f, obstacle)
            }
            if (course.holeInCircle) {
                mesh.disk(V3(0f, course.circleTerrain(0f, 0f) + 0.006f, 0f), MinigolfLaneCourse.HOLE_RADIUS, holeColor, bias = -0.06f)
            }

        }

        // MARK: Hindernisse

        private fun render(part: MinigolfLaneCourse.Part) {
            when (part) {
                is MinigolfLaneCourse.Part.Box ->
                    mesh.prism(rect(part.x0, part.x1, part.z0, part.z1), part.y0, part.y1, surfaceColor(part.surface))
                is MinigolfLaneCourse.Part.Wall -> {
                    val d = (part.to - part.from).let { it / it.length }
                    val n = V2(-d.y, d.x) * (part.thickness / 2)
                    mesh.prism(listOf(part.from - n, part.to - n, part.to + n, part.from + n), 0f, part.height, obstacle)
                }
                is MinigolfLaneCourse.Part.Plate -> mesh.prism(part.outline, part.y0, part.y0 + part.height, obstacle)
                is MinigolfLaneCourse.Part.ArcWall ->
                    mesh.arcWall(part.center, part.radiusIn, part.radiusOut, part.from, part.to, part.y0, part.height, obstacle)
                is MinigolfLaneCourse.Part.Pyramid -> mesh.pyramid(part.x, part.z, part.width, part.height, obstacle)
                is MinigolfLaneCourse.Part.Cone ->
                    mesh.frustum(part.x, part.z, part.bottomRadius, part.topRadius, 0f, part.height, obstacle)
                is MinigolfLaneCourse.Part.Cylinder ->
                    mesh.cylinder(part.x, part.z, part.radius, 0f, part.height, obstacle)
                is MinigolfLaneCourse.Part.Ring ->
                    mesh.torusUpright(V3(part.x, part.radius, part.z), part.radius, part.pipe, obstacle)
                is MinigolfLaneCourse.Part.Pipe -> mesh.tubeX(part.x0, part.x1, part.axisY, part.inner, part.outer, obstacle)
                is MinigolfLaneCourse.Part.Profile -> mesh.profile(part.outline, part.z0, part.z1, surfaceColor(part.surface))
            }
        }

        /** Teile ohne Einfluss auf den Ball: Netz der Sprungschanze, Löcher außerhalb des Zielkreises. */
        private fun buildDecorations() {
            when (val goal = course.goal) {
                is MinigolfLaneCourse.Goal.Net -> {
                    val netCenter = goal.center
                    val radius = goal.radius
                    // Netz: Ring, darunter hängendes Netz, Mast.
                    mesh.torusFlat(netCenter, radius, 0.014f, obstacle)
                    mesh.frustum(
                        netCenter.x, netCenter.z, 0.05f, radius, netCenter.y - 0.3f, netCenter.y,
                        Color(0.95f, 0.95f, 0.95f, 0.35f), twoSided = true, cap = false,
                    )
                    val poleTop = netCenter.y + 0.06f
                    mesh.cylinder(netCenter.x + radius + 0.05f, 0f, 0.02f, base, poleTop, bande, segments = 12)
                    mesh.prism(
                        rect(netCenter.x + radius - 0.02f, netCenter.x + radius + 0.07f, -0.015f, 0.015f),
                        netCenter.y - 0.01f, netCenter.y + 0.02f, bande,
                    )
                }
                is MinigolfLaneCourse.Goal.Hole, is MinigolfLaneCourse.Goal.Chamber ->
                    if (!course.holeInCircle) {
                        mesh.disk(goal.point + V3(0f, 0.006f, 0f), MinigolfLaneCourse.HOLE_RADIUS, holeColor, bias = -0.06f)
                    }
            }
        }

        // MARK: Idealspur

        /**
         * Spur ungeglättet: Punkte werden nur ausgedünnt, Knicke (Abpraller)
         * bleiben erhalten. Dazu die Startmarke am Abschlag.
         */
        private fun buildIdealLine(positions: List<V3>): List<V3> {
            if (positions.size < 2) return positions
            val samples = mutableListOf(positions[0])
            val kink = cos(6f * PI.toFloat() / 180f)
            for (i in 1 until positions.size - 1) {
                val d1 = positions[i] - positions[i - 1]
                val d2 = positions[i + 1] - positions[i]
                val l1 = d1.length
                val l2 = d2.length
                val bent = l1 > 1e-6f && l2 > 1e-6f && (d1 dot d2) / (l1 * l2) < kink
                if (bent || dist(samples.last(), positions[i]) >= 0.03f) samples += positions[i]
            }
            samples += positions.last()

            // Startmarke: flacher Ring am Abschlag.
            mesh.annulus(V3(samples[0].x, 0.006f, samples[0].z), 0.042f, 0.058f, idealColor, ideal = true)
            return samples
        }

        private fun buildFloor(): FloatArray {
            val out = ArrayList<Float>()
            val y = base - 0.001f
            val step = 1f
            var x = -20f
            while (x < 20f) {
                var z = -20f
                while (z < 20f) {
                    out.addAll(listOf(x, y, z, x + step, y, z, x + step, y, z + step))
                    out.addAll(listOf(x, y, z, x + step, y, z + step, x, y, z + step))
                    z += step
                }
                x += step
            }
            return out.toFloatArray()
        }
    }
}

private fun rect(x0: Float, x1: Float, z0: Float, z1: Float) = listOf(V2(x0, z0), V2(x1, z0), V2(x1, z1), V2(x0, z1))

// MARK: - Dreiecksliste

/**
 * Sammelt schattierte Dreiecke. Große Flächen werden unterteilt, damit das
 * Sortieren nach Tiefe (Maleralgorithmus) auch neben langen Flächen stimmt.
 */
private class Mesh {
    val v = ArrayList<Float>()
    val n = ArrayList<Float>()
    val c = ArrayList<Float>()
    val col = ArrayList<Int>()
    val flags = ArrayList<Byte>()
    val bias = ArrayList<Float>()

    var xf: (V3) -> V3 = { it }
    var rot: (V3) -> V3 = { it }

    private val light = V3(-2f, 6f, 3f).normalized()
    private val maxEdge = 0.26f

    /** Dreieck in lokalen Koordinaten; `out` zeigt nach außen und legt die Umlaufrichtung fest. */
    fun tri(a: V3, b: V3, c: V3, color: Color, out: V3?, twoSided: Boolean = false, ideal: Boolean = false, bias: Float = 0f) {
        addWorld(xf(a), xf(b), xf(c), color, out?.let(rot), twoSided, ideal, bias, 0)
    }

    private fun addWorld(a: V3, b: V3, c: V3, color: Color, out: V3?, twoSided: Boolean, ideal: Boolean, bias: Float, depth: Int) {
        val ab = dist(a, b)
        val bc = dist(b, c)
        val ca = dist(c, a)
        val longest = maxOf(ab, bc, ca)
        if (longest > maxEdge && depth < 10) {
            // An der längsten Kante teilen.
            when (longest) {
                ab -> { val m = (a + b) * 0.5f; addWorld(a, m, c, color, out, twoSided, ideal, bias, depth + 1); addWorld(m, b, c, color, out, twoSided, ideal, bias, depth + 1) }
                bc -> { val m = (b + c) * 0.5f; addWorld(a, b, m, color, out, twoSided, ideal, bias, depth + 1); addWorld(a, m, c, color, out, twoSided, ideal, bias, depth + 1) }
                else -> { val m = (c + a) * 0.5f; addWorld(a, b, m, color, out, twoSided, ideal, bias, depth + 1); addWorld(m, b, c, color, out, twoSided, ideal, bias, depth + 1) }
            }
            return
        }
        var normal = (b - a) cross (c - a)
        if (normal.length < 1e-10f) return
        normal = normal.normalized()
        var p1 = b
        var p2 = c
        if (out != null && (normal dot out) < 0) { normal = V3(-normal.x, -normal.y, -normal.z); p1 = c; p2 = b }
        val lambert = normal dot light
        val k = 0.45f + 0.65f * (if (twoSided) kotlin.math.abs(lambert) else max(0f, lambert))
        val shaded = if (ideal) color else Color(
            min(1f, color.red * k), min(1f, color.green * k), min(1f, color.blue * k), color.alpha,
        )
        for (p in listOf(a, p1, p2)) { v += p.x; v += p.y; v += p.z }
        n += normal.x; n += normal.y; n += normal.z
        val centroid = (a + p1 + p2) / 3f
        this.c += centroid.x; this.c += centroid.y; this.c += centroid.z
        col += shaded.toArgb()
        flags += ((if (twoSided) MinigolfLaneModel.FLAG_TWO_SIDED.toInt() else 0) or
            (if (ideal) MinigolfLaneModel.FLAG_IDEAL.toInt() else 0)).toByte()
        this.bias += bias
    }

    fun quad(a: V3, b: V3, c: V3, d: V3, color: Color, out: V3?, twoSided: Boolean = false, bias: Float = 0f) {
        // Gitter, damit lange Flächen nicht in schmale Splitter zerfallen.
        val nu = max(1, ceil(max(dist(a, b), dist(d, c)) / maxEdge).toInt())
        val nv = max(1, ceil(max(dist(a, d), dist(b, c)) / maxEdge).toInt())
        fun at(u: Float, w: Float): V3 {
            val p = a + (b - a) * u
            val q = d + (c - d) * u
            return p + (q - p) * w
        }
        for (i in 0 until nu) for (j in 0 until nv) {
            val u0 = i.toFloat() / nu
            val u1 = (i + 1f) / nu
            val w0 = j.toFloat() / nv
            val w1 = (j + 1f) / nv
            val p00 = at(u0, w0)
            val p10 = at(u1, w0)
            val p11 = at(u1, w1)
            val p01 = at(u0, w1)
            tri(p00, p10, p11, color, out, twoSided, bias = bias)
            tri(p00, p11, p01, color, out, twoSided, bias = bias)
        }
    }

    /** Senkrechter Körper mit Grundriss (x, z) von y0 bis y1 – Kiste, Wand, Platte. Ohne Unterseite. */
    fun prism(outline: List<V2>, y0: Float, y1: Float, color: Color, bias: Float = 0f) {
        val ccw = signedArea(outline) > 0
        for (i in outline.indices) {
            val p = outline[i]
            val q = outline[(i + 1) % outline.size]
            val dx = q.x - p.x
            val dz = q.y - p.y
            val out = if (ccw) V3(dz, 0f, -dx) else V3(-dz, 0f, dx)
            quad(V3(p.x, y0, p.y), V3(q.x, y0, q.y), V3(q.x, y1, q.y), V3(p.x, y1, p.y), color, out, bias = bias)
        }
        for ((i, j, k) in triangulate(outline)) {
            tri(V3(outline[i].x, y1, outline[i].y), V3(outline[j].x, y1, outline[j].y), V3(outline[k].x, y1, outline[k].y),
                color, V3(0f, 1f, 0f), bias = bias)
        }
    }

    /** Körper mit Seitenprofil (x, y), quer über z0…z1 extrudiert. */
    fun profile(outline: List<V2>, z0: Float, z1: Float, color: Color) {
        val ccw = signedArea(outline) > 0
        for (i in outline.indices) {
            val p = outline[i]
            val q = outline[(i + 1) % outline.size]
            if (dist(p, q) < 1e-6f) continue
            val dx = q.x - p.x
            val dy = q.y - p.y
            val out = if (ccw) V3(dy, -dx, 0f) else V3(-dy, dx, 0f)
            quad(V3(p.x, p.y, z0), V3(q.x, q.y, z0), V3(q.x, q.y, z1), V3(p.x, p.y, z1), color, out)
        }
        for ((i, j, k) in triangulate(outline)) {
            for ((z, dir) in listOf(z0 to -1f, z1 to 1f)) {
                tri(V3(outline[i].x, outline[i].y, z), V3(outline[j].x, outline[j].y, z), V3(outline[k].x, outline[k].y, z),
                    color, V3(0f, 0f, dir))
            }
        }
    }

    /** Ringförmige Wand von Winkel `from` bis `to` (0 = Spielrichtung, positiv zur rechten Bande). */
    fun arcWall(center: V2, rIn: Float, rOut: Float, from: Float, to: Float, y0: Float, height: Float, color: Color) {
        val steps = 48
        val y1 = y0 + height
        fun pt(r: Float, a: Float, y: Float) = V3(center.x + r * cos(a), y, center.y + r * sin(a))
        for (i in 0 until steps) {
            val a0 = from + (to - from) * i / steps
            val a1 = from + (to - from) * (i + 1) / steps
            val am = (a0 + a1) / 2
            val radial = V3(cos(am), 0f, sin(am))
            quad(pt(rOut, a0, y0), pt(rOut, a1, y0), pt(rOut, a1, y1), pt(rOut, a0, y1), color, radial)
            quad(pt(rIn, a0, y0), pt(rIn, a1, y0), pt(rIn, a1, y1), pt(rIn, a0, y1), color, radial * -1f)
            quad(pt(rIn, a0, y1), pt(rIn, a1, y1), pt(rOut, a1, y1), pt(rOut, a0, y1), color, V3(0f, 1f, 0f))
        }
        for ((a, s) in listOf(from to -1f, to to 1f)) {
            val tangent = V3(-sin(a), 0f, cos(a)) * s
            quad(pt(rIn, a, y0), pt(rOut, a, y0), pt(rOut, a, y1), pt(rIn, a, y1), color, tangent)
        }
    }

    fun pyramid(x: Float, z: Float, width: Float, height: Float, color: Color) {
        val w = width / 2
        val apex = V3(x, height, z)
        val corners = listOf(V3(x - w, 0f, z - w), V3(x + w, 0f, z - w), V3(x + w, 0f, z + w), V3(x - w, 0f, z + w))
        for (i in 0 until 4) {
            val a = corners[i]
            val b = corners[(i + 1) % 4]
            val mid = (a + b) * 0.5f
            tri(a, b, apex, color, V3(mid.x - x, 0.3f, mid.z - z))
        }
    }

    /** Kegelstumpf um (x, z) von y0 (Radius `r0`) bis y1 (Radius `r1`). */
    fun frustum(x: Float, z: Float, r0: Float, r1: Float, y0: Float, y1: Float, color: Color,
                segments: Int = 32, twoSided: Boolean = false, cap: Boolean = true) {
        for (i in 0 until segments) {
            val a0 = 2 * PI.toFloat() * i / segments
            val a1 = 2 * PI.toFloat() * (i + 1) / segments
            val am = (a0 + a1) / 2
            val out = V3(cos(am), (r0 - r1) / max(1e-4f, y1 - y0), sin(am))
            quad(
                V3(x + r0 * cos(a0), y0, z + r0 * sin(a0)), V3(x + r0 * cos(a1), y0, z + r0 * sin(a1)),
                V3(x + r1 * cos(a1), y1, z + r1 * sin(a1)), V3(x + r1 * cos(a0), y1, z + r1 * sin(a0)),
                color, out, twoSided,
            )
            if (cap && r1 > 0) {
                tri(V3(x, y1, z), V3(x + r1 * cos(a0), y1, z + r1 * sin(a0)), V3(x + r1 * cos(a1), y1, z + r1 * sin(a1)),
                    color, V3(0f, 1f, 0f), twoSided)
            }
        }
    }

    fun cylinder(x: Float, z: Float, r: Float, y0: Float, y1: Float, color: Color, segments: Int = 32) {
        frustum(x, z, r, r, y0, y1, color, segments)
    }

    /** Flache Scheibe (Loch). */
    fun disk(center: V3, r: Float, color: Color, bias: Float, rings: Int = 1, segments: Int = 20) {
        for (i in 0 until segments) {
            val a0 = 2 * PI.toFloat() * i / segments
            val a1 = 2 * PI.toFloat() * (i + 1) / segments
            for (k in 0 until rings) {
                val r0 = r * k / rings
                val r1 = r * (k + 1) / rings
                val p00 = center + V3(r0 * cos(a0), 0f, r0 * sin(a0))
                val p01 = center + V3(r0 * cos(a1), 0f, r0 * sin(a1))
                val p10 = center + V3(r1 * cos(a0), 0f, r1 * sin(a0))
                val p11 = center + V3(r1 * cos(a1), 0f, r1 * sin(a1))
                tri(p00, p10, p11, color, V3(0f, 1f, 0f), bias = bias)
                if (k > 0) tri(p00, p11, p01, color, V3(0f, 1f, 0f), bias = bias)
            }
        }
    }

    /** Flacher Ring, beidseitig sichtbar (Startmarke). */
    fun annulus(center: V3, rIn: Float, rOut: Float, color: Color, ideal: Boolean) {
        val segments = 24
        for (i in 0 until segments) {
            val a0 = 2 * PI.toFloat() * i / segments
            val a1 = 2 * PI.toFloat() * (i + 1) / segments
            val p0 = center + V3(rIn * cos(a0), 0f, rIn * sin(a0))
            val p1 = center + V3(rOut * cos(a0), 0f, rOut * sin(a0))
            val p2 = center + V3(rOut * cos(a1), 0f, rOut * sin(a1))
            val p3 = center + V3(rIn * cos(a1), 0f, rIn * sin(a1))
            tri(p0, p1, p2, color, V3(0f, 1f, 0f), twoSided = true, ideal = ideal, bias = -0.02f)
            tri(p0, p2, p3, color, V3(0f, 1f, 0f), twoSided = true, ideal = ideal, bias = -0.02f)
        }
    }

    /** Liegender Ring (Torus in der x-z-Ebene). */
    fun torusFlat(center: V3, ring: Float, pipe: Float, color: Color) =
        torus(center, ring, pipe, color) { u, v -> V3((ring + pipe * cos(v)) * cos(u), pipe * sin(v), (ring + pipe * cos(v)) * sin(u)) to V3(cos(u), 0f, sin(u)) * ring }

    /** Senkrechter Ring in der x-y-Ebene (Salto). */
    fun torusUpright(center: V3, ring: Float, pipe: Float, color: Color) =
        torus(center, ring, pipe, color) { u, v -> V3((ring + pipe * cos(v)) * cos(u), (ring + pipe * cos(v)) * sin(u), pipe * sin(v)) to V3(cos(u), sin(u), 0f) * ring }

    private inline fun torus(center: V3, ring: Float, pipe: Float, color: Color, point: (Float, Float) -> Pair<V3, V3>) {
        val nu = 36
        val nv = 8
        for (i in 0 until nu) for (j in 0 until nv) {
            val u0 = 2 * PI.toFloat() * i / nu
            val u1 = 2 * PI.toFloat() * (i + 1) / nu
            val v0 = 2 * PI.toFloat() * j / nv
            val v1 = 2 * PI.toFloat() * (j + 1) / nv
            val (p00, _) = point(u0, v0)
            val (p10, _) = point(u1, v0)
            val (p11, _) = point(u1, v1)
            val (p01, _) = point(u0, v1)
            val (mid, axis) = point((u0 + u1) / 2, (v0 + v1) / 2)
            val out = mid - axis
            tri(center + p00, center + p10, center + p11, color, out)
            tri(center + p00, center + p11, center + p01, color, out)
        }
    }

    /** Rohr längs x mit Achse auf Höhe `axisY`. */
    fun tubeX(x0: Float, x1: Float, axisY: Float, inner: Float, outer: Float, color: Color) {
        val segments = 24
        fun p(x: Float, r: Float, a: Float) = V3(x, axisY + r * sin(a), r * cos(a))
        for (i in 0 until segments) {
            val a0 = 2 * PI.toFloat() * i / segments
            val a1 = 2 * PI.toFloat() * (i + 1) / segments
            val am = (a0 + a1) / 2
            val radial = V3(0f, sin(am), cos(am))
            quad(p(x0, outer, a0), p(x1, outer, a0), p(x1, outer, a1), p(x0, outer, a1), color, radial)
            quad(p(x0, inner, a0), p(x1, inner, a0), p(x1, inner, a1), p(x0, inner, a1), color, radial * -1f)
            for ((x, dir) in listOf(x0 to -1f, x1 to 1f)) {
                quad(p(x, inner, a0), p(x, outer, a0), p(x, outer, a1), p(x, inner, a1), color, V3(dir, 0f, 0f))
            }
        }
    }

    // MARK: Polygone

    private fun signedArea(points: List<V2>): Float {
        var a = 0f
        for (i in points.indices) {
            val p = points[i]
            val q = points[(i + 1) % points.size]
            a += p.x * q.y - q.x * p.y
        }
        return a / 2
    }

    /** Ohrenschneiden für einfache Polygone; gibt Indextripel zurück. */
    private fun triangulate(points: List<V2>): List<Triple<Int, Int, Int>> {
        val idx = points.indices.filter { i -> dist(points[i], points[(i + 1) % points.size]) > 1e-6f }.toMutableList()
        val ccw = signedArea(points) > 0
        val result = mutableListOf<Triple<Int, Int, Int>>()
        fun cross(o: V2, a: V2, b: V2) = (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        fun inside(p: V2, a: V2, b: V2, c: V2): Boolean {
            val d1 = cross(a, b, p)
            val d2 = cross(b, c, p)
            val d3 = cross(c, a, p)
            val neg = d1 < -1e-7f || d2 < -1e-7f || d3 < -1e-7f
            val pos = d1 > 1e-7f || d2 > 1e-7f || d3 > 1e-7f
            return !(neg && pos)
        }
        var guard = 0
        while (idx.size > 3 && guard < 10_000) {
            guard++
            var clipped = false
            for (k in idx.indices) {
                val i0 = idx[(k - 1 + idx.size) % idx.size]
                val i1 = idx[k]
                val i2 = idx[(k + 1) % idx.size]
                val a = points[i0]
                val b = points[i1]
                val c = points[i2]
                val turn = cross(a, b, c) * (if (ccw) 1 else -1)
                if (turn < -1e-9f) continue
                if (turn > 1e-9f && idx.any { it != i0 && it != i1 && it != i2 && inside(points[it], a, b, c) && points[it] != a && points[it] != b && points[it] != c }) continue
                if (turn > 1e-9f) result += Triple(i0, i1, i2)
                idx.removeAt(k)
                clipped = true
                break
            }
            if (!clipped) break
        }
        if (idx.size == 3) result += Triple(idx[0], idx[1], idx[2])
        else if (idx.size > 3) for (k in 1 until idx.size - 1) result += Triple(idx[0], idx[k], idx[k + 1])
        return result
    }
}

// MARK: - Kamera

/** Kreisende Kamera um einen Zielpunkt. */
internal data class OrbitCamera(val target: V3, val yaw: Float, val pitch: Float, val distance: Float) {
    val eye: V3
        get() = target + V3(cos(pitch) * cos(yaw), sin(pitch), cos(pitch) * sin(yaw)) * distance

    companion object {
        val home: OrbitCamera = run {
            val d = MinigolfLaneModel.homeEye - MinigolfLaneModel.homeTarget
            val len = d.length
            OrbitCamera(MinigolfLaneModel.homeTarget, atan2(d.z, d.x), asin(d.y / len), len)
        }
    }

    fun lerp(to: OrbitCamera, t: Float): OrbitCamera {
        var dy = to.yaw - yaw
        while (dy > PI) dy -= 2 * PI.toFloat()
        while (dy < -PI) dy += 2 * PI.toFloat()
        return OrbitCamera(
            target + (to.target - target) * t,
            yaw + dy * t,
            pitch + (to.pitch - pitch) * t,
            distance + (to.distance - distance) * t,
        )
    }

    fun rotated(dx: Float, dy: Float) = copy(
        yaw = yaw + dx * 0.008f,
        pitch = (pitch + dy * 0.008f).coerceIn(0.04f, 1.5f),
    )

    fun zoomed(factor: Float) = copy(distance = (distance / factor).coerceIn(0.8f, 16f))

    /** Verschieben in Bildschirmrichtung; `perPixel` = Meter je Pixel auf Zielhöhe. */
    fun panned(dx: Float, dy: Float, perPixel: Float): OrbitCamera {
        val f = (target - eye).normalized()
        val right = (f cross V3(0f, 1f, 0f)).normalized()
        val up = right cross f
        return copy(target = target - right * (dx * perPixel) + up * (dy * perPixel))
    }
}

/** Aus der Simulation: Ballposition und Deckkraft zum Zeitpunkt `t` (Sekunden) der Endlosschleife. */
internal fun ballState(positions: List<V3>, t: Float): Pair<V3, Float>? {
    if (positions.size < 2) return null
    val dt = MinigolfBallSimulation.DT
    val roll = (positions.size - 1) * dt
    // Einblenden 0,2 s, warten 0,4 s, rollen, 1 s liegen, ausblenden 0,3 s.
    val cycle = 0.2f + 0.4f + roll + 1.0f + 0.3f
    val s = t % cycle
    return when {
        s < 0.2f -> positions.first() to s / 0.2f
        s < 0.6f -> positions.first() to 1f
        s < 0.6f + roll -> positions[min(positions.size - 1, ((s - 0.6f) / dt).toInt())] to 1f
        s < 1.6f + roll -> positions.last() to 1f
        else -> positions.last() to max(0f, 1f - (s - 1.6f - roll) / 0.3f)
    }
}
