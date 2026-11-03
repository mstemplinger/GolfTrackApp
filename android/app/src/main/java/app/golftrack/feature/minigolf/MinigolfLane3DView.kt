package app.golftrack.feature.minigolf

import android.graphics.Canvas as NativeCanvas
import android.graphics.Paint
import android.graphics.Path
import android.os.Build
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.calculatePan
import androidx.compose.foundation.gestures.calculateZoom
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import androidx.compose.ui.input.pointer.positionChanged
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.max
import kotlin.math.tan

/**
 * Drehbares 3D-Modell einer Normbahn – wie MinigolfLane3DView.swift, ohne
 * SceneKit: eigene Projektion auf einem Compose-Canvas, Flächen nach Tiefe
 * sortiert. Ein Finger dreht, zwei Finger zoomen und verschieben, der Knopf
 * oben rechts springt zurück.
 */
@Composable
internal fun MinigolfLane3DView(
    lane: MinigolfStandardLane,
    showsIdealLine: Boolean,
    modifier: Modifier = Modifier,
) {
    var model by remember(lane.normNumber) { mutableStateOf<MinigolfLaneModel?>(null) }
    LaunchedEffect(lane.normNumber) {
        model = withContext(Dispatchers.Default) { MinigolfLaneModel.build(lane) }
    }
    var camera by remember(lane.normNumber) { mutableStateOf(OrbitCamera.home) }
    var time by remember { mutableFloatStateOf(0f) }
    val scope = rememberCoroutineScope()
    val reset = remember { Animatable(0f) }

    // Ball in echter Zeit, nur solange die Idealspur sichtbar ist.
    LaunchedEffect(showsIdealLine, model) {
        if (!showsIdealLine || model == null) return@LaunchedEffect
        val start = withFrameNanos { it }
        while (true) {
            withFrameNanos { time = (it - start) / 1e9f }
        }
    }

    val renderer = remember(model) { model?.let { LaneRenderer(it) } }

    Box(
        modifier
            .background(AppTheme.cardDark)
            .semantics { contentDescription = "3D-Modell der Bahn ${lane.name}" },
    ) {
        if (renderer != null) {
            Canvas(
                Modifier.fillMaxSize().pointerInput(lane.normNumber) {
                    awaitEachGesture {
                        awaitFirstDown(requireUnconsumed = false)
                        do {
                            val event = awaitPointerEvent()
                            val pressed = event.changes.filter { it.pressed }
                            val perPixel = camera.distance / renderer.focal(size.height.toFloat())
                            if (pressed.size >= 2) {
                                val zoom = event.calculateZoom()
                                val pan = event.calculatePan()
                                camera = camera.zoomed(zoom).panned(pan.x, pan.y, perPixel)
                            } else if (pressed.size == 1) {
                                val d = pressed[0].positionChange()
                                camera = camera.rotated(d.x, d.y)
                            }
                            event.changes.forEach { if (it.positionChanged()) it.consume() }
                        } while (event.changes.any { it.pressed })
                    }
                },
            ) {
                renderer.draw(this, camera, showsIdealLine, time)
            }
        }

        Box(
            Modifier.align(Alignment.TopEnd).padding(8.dp).size(30.dp)
                .background(Color.Black.copy(alpha = 0.35f), CircleShape)
                .clickable {
                    Haptics.tap()
                    val from = camera
                    scope.launch {
                        reset.snapTo(0f)
                        reset.animateTo(1f, tween(500)) { camera = from.lerp(OrbitCamera.home, value) }
                    }
                }
                .semantics { contentDescription = "Ansicht zurücksetzen" },
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.Refresh, null, tint = Color.White, modifier = Modifier.size(16.dp))
        }
    }
}

/** Vollbild-Ansicht des 3D-Modells. */
@Composable
internal fun MinigolfLane3DFullscreen(
    lane: MinigolfStandardLane,
    showsIdealLine: Boolean,
    onToggleIdealLine: () -> Unit,
    onDismiss: () -> Unit,
) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        Box(Modifier.fillMaxSize().background(AppTheme.cardDark)) {
            MinigolfLane3DView(lane, showsIdealLine, Modifier.fillMaxSize())

            Row(
                Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 16.dp).padding(top = 8.dp, end = 40.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Box(
                    Modifier.background(Color.Black.copy(alpha = 0.35f), RoundedCornerShape(50))
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                ) {
                    MgText("${lane.normNumber}. ${lane.name}", MgFont.subheadline, Color.White, FontWeight.Bold, maxLines = 1)
                }
                Spacer(Modifier.weight(1f))
                Box(
                    Modifier.size(36.dp).background(Color.Black.copy(alpha = 0.35f), CircleShape)
                        .clickable { Haptics.tap(); onDismiss() }
                        .semantics { contentDescription = "Schließen" },
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.Close, null, tint = Color.White, modifier = Modifier.size(18.dp))
                }
            }

            Column(
                Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                MinigolfIdealLineToggle(showsIdealLine, onToggleIdealLine)
                MgText("Ein Finger dreht, zwei Finger zoomen und verschieben.", MgFont.caption2, Color.White.copy(alpha = 0.7f))
            }
        }
    }
}

/** Schalter für die Idealspur – als Kapsel, passend zum 3D-Modell. */
@Composable
internal fun MinigolfIdealLineToggle(isOn: Boolean, onToggle: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier
            .background(if (isOn) MinigolfLaneModel.idealColor else Color.Black.copy(alpha = 0.35f), RoundedCornerShape(50))
            .clickable { Haptics.selection(); onToggle() }
            .padding(horizontal = 12.dp, vertical = 7.dp)
            .semantics { contentDescription = if (isOn) "Idealspur an" else "Idealspur aus" },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        val tint = if (isOn) Color.Black else Color.White
        Icon(if (isOn) Icons.Filled.Visibility else Icons.Filled.VisibilityOff, null, tint = tint, modifier = Modifier.size(14.dp))
        MgText("Idealspur", MgFont.caption, tint, FontWeight.Bold)
    }
}

// MARK: - Renderer

/**
 * Maleralgorithmus: Dreiecke nach Tiefe des Schwerpunkts sortiert, Rückseiten
 * weggelassen, Licht vorab eingerechnet. Idealspur und Ball sind zur Kamera
 * gedrehte Flächen und laufen in derselben Sortierung mit, damit Hindernisse
 * sie verdecken. Gezeichnet wird mit einem einzigen `drawVertices`.
 */
private class LaneRenderer(private val model: MinigolfLaneModel) {
    private val fovY = Math.toRadians(38.0).toFloat()
    private val near = 0.05f

    private val n = model.triangleCount
    private val segs = max(0, model.idealSamples.size - 1)
    private val ballTris = 16
    /** Zusatzflächen: je Spursegment 2 Dreiecke plus der Ball. */
    private val extraTris = segs * 2 + ballTris
    private val extraVerts = FloatArray(extraTris * 6)
    private val extraColors = IntArray(extraTris * 3)

    private val keys = LongArray(n + segs + 1)
    private val sx = FloatArray(n * 3)
    private val sy = FloatArray(n * 3)
    private val outVerts = FloatArray((n + extraTris) * 6)
    private val outColors = IntArray((n + extraTris) * 3)
    private val floorVerts = FloatArray(model.floor.size / 3 * 2)
    private val floorColors = IntArray(model.floor.size / 3) { model.floorColor }
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val path = Path()

    private val idealArgb = MinigolfLaneModel.idealColor.toArgb()

    fun focal(height: Float) = height / 2 / tan(fovY / 2)

    fun draw(scope: DrawScope, cam: OrbitCamera, showIdeal: Boolean, time: Float) {
        val w = scope.size.width
        val h = scope.size.height
        val focal = focal(h)
        val cx = w / 2
        val cy = h / 2

        val eye = cam.eye
        val f = (cam.target - eye).normalized()
        val r = (f cross V3(0f, 1f, 0f)).normalized()
        val u = r cross f
        val ex = eye.x; val ey = eye.y; val ez = eye.z

        fun depth(x: Float, y: Float, z: Float) = (x - ex) * f.x + (y - ey) * f.y + (z - ez) * f.z

        // Boden zuerst.
        var floorCount = 0
        val fl = model.floor
        var t = 0
        while (t < fl.size / 9) {
            var ok = true
            for (k in 0 until 3) {
                val o = t * 9 + k * 3
                val dx = fl[o] - ex; val dy = fl[o + 1] - ey; val dz = fl[o + 2] - ez
                val z = dx * f.x + dy * f.y + dz * f.z
                if (z < near) { ok = false; break }
                floorVerts[floorCount * 6 + k * 2] = cx + (dx * r.x + dy * r.y + dz * r.z) * focal / z
                floorVerts[floorCount * 6 + k * 2 + 1] = cy - (dx * u.x + dy * u.y + dz * u.z) * focal / z
            }
            if (ok) floorCount++
            t++
        }

        // Dreiecke der Bahn.
        var count = 0
        val v = model.vertices
        val nm = model.normals
        val ce = model.centroids
        for (i in 0 until n) {
            val flag = model.flags[i].toInt()
            if (flag and MinigolfLaneModel.FLAG_IDEAL.toInt() != 0 && !showIdeal) continue
            if (flag and MinigolfLaneModel.FLAG_TWO_SIDED.toInt() == 0) {
                val facing = nm[i * 3] * (ex - ce[i * 3]) + nm[i * 3 + 1] * (ey - ce[i * 3 + 1]) + nm[i * 3 + 2] * (ez - ce[i * 3 + 2])
                if (facing <= 0) continue
            }
            var ok = true
            for (k in 0 until 3) {
                val o = i * 9 + k * 3
                val dx = v[o] - ex; val dy = v[o + 1] - ey; val dz = v[o + 2] - ez
                val z = dx * f.x + dy * f.y + dz * f.z
                if (z < near) { ok = false; break }
                sx[i * 3 + k] = cx + (dx * r.x + dy * r.y + dz * r.z) * focal / z
                sy[i * 3 + k] = cy - (dx * u.x + dy * u.y + dz * u.z) * focal / z
            }
            if (!ok) continue
            val d = depth(ce[i * 3], ce[i * 3 + 1], ce[i * 3 + 2]) + model.bias[i]
            keys[count++] = key(d, i)
        }

        // Idealspur als zur Kamera gedrehte Bänder, Ball als Scheibe.
        var extraUsed = 0
        if (showIdeal) {
            val pts = model.idealSamples
            for (s in 0 until segs) {
                val a = pts[s]
                val b = pts[s + 1]
                val za = depth(a.x, a.y, a.z)
                val zb = depth(b.x, b.y, b.z)
                if (za < near || zb < near) continue
                val ax = cx + ((a - eye) dot r) * focal / za
                val ay = cy - ((a - eye) dot u) * focal / za
                val bx = cx + ((b - eye) dot r) * focal / zb
                val by = cy - ((b - eye) dot u) * focal / zb
                var nx = -(by - ay)
                var ny = bx - ax
                val len = kotlin.math.sqrt(nx * nx + ny * ny)
                if (len < 1e-3f) continue
                nx /= len; ny /= len
                val wa = max(1f, 0.011f * focal / za)
                val wb = max(1f, 0.011f * focal / zb)
                val o = extraUsed * 6
                val quad = floatArrayOf(
                    ax + nx * wa, ay + ny * wa, bx + nx * wb, by + ny * wb, bx - nx * wb, by - ny * wb,
                    ax + nx * wa, ay + ny * wa, bx - nx * wb, by - ny * wb, ax - nx * wa, ay - ny * wa,
                )
                quad.copyInto(extraVerts, o)
                for (k in 0 until 6) extraColors[extraUsed * 3 + k] = idealArgb
                // Spur liegt knapp über dem Filz – leicht nach vorn ziehen.
                keys[count++] = key((za + zb) / 2 - 0.03f, n + s, extraUsed)
                extraUsed += 2
            }
            ballState(model.ballPositions, time)?.let { (p, alpha) ->
                val z = depth(p.x, p.y, p.z)
                if (z >= near && alpha > 0.01f) {
                    val bx = cx + ((p - eye) dot r) * focal / z
                    val by = cy - ((p - eye) dot u) * focal / z
                    val rad = max(2f, MinigolfLaneCourse.BALL_RADIUS * focal / z)
                    val a = (alpha * 255).toInt()
                    val centerColor = android.graphics.Color.argb(a, 255, 255, 255)
                    val rimColor = android.graphics.Color.argb(a, 170, 175, 172)
                    val start = extraUsed
                    for (k in 0 until ballTris) {
                        val a0 = 2 * Math.PI * k / ballTris
                        val a1 = 2 * Math.PI * (k + 1) / ballTris
                        val o = extraUsed * 6
                        // Glanzpunkt leicht oben links.
                        extraVerts[o] = bx - rad * 0.25f; extraVerts[o + 1] = by - rad * 0.25f
                        extraVerts[o + 2] = bx + rad * kotlin.math.cos(a0).toFloat(); extraVerts[o + 3] = by + rad * kotlin.math.sin(a0).toFloat()
                        extraVerts[o + 4] = bx + rad * kotlin.math.cos(a1).toFloat(); extraVerts[o + 5] = by + rad * kotlin.math.sin(a1).toFloat()
                        extraColors[extraUsed * 3] = centerColor
                        extraColors[extraUsed * 3 + 1] = rimColor
                        extraColors[extraUsed * 3 + 2] = rimColor
                        extraUsed++
                    }
                    keys[count++] = key(z - 0.02f, n + segs, start)
                }
            }
        }

        keys.sort(0, count)

        // Fern nach nah zusammensetzen.
        var outTris = 0
        for (k in count - 1 downTo 0) {
            val idx = (keys[k] and 0xFFFFFFFFL).toInt()
            if (idx < n) {
                val o = outTris * 6
                for (j in 0 until 3) {
                    outVerts[o + j * 2] = sx[idx * 3 + j]
                    outVerts[o + j * 2 + 1] = sy[idx * 3 + j]
                    outColors[outTris * 3 + j] = model.colors[idx]
                }
                outTris++
            } else {
                val start = extraStart[idx - n]
                val triCount = if (idx - n < segs) 2 else ballTris
                for (q in 0 until triCount) {
                    extraVerts.copyInto(outVerts, outTris * 6, (start + q) * 6, (start + q + 1) * 6)
                    extraColors.copyInto(outColors, outTris * 3, (start + q) * 3, (start + q + 1) * 3)
                    outTris++
                }
            }
        }

        scope.drawIntoCanvas { canvas ->
            val nc = canvas.nativeCanvas
            nc.drawColor(AppTheme.cardDark.toArgb())
            drawTriangles(nc, floorVerts, floorColors, floorCount)
            drawTriangles(nc, outVerts, outColors, outTris)
        }
    }

    /** Anfang der Zusatzdreiecke je Spursegment bzw. Ball (in `extraVerts`). */
    private val extraStart = IntArray(segs + 1)

    /** Sortierschlüssel: Tiefe oben (positive Floats sortieren wie ihre Bits), Index unten. */
    private fun key(depth: Float, index: Int, extraOffset: Int = -1): Long {
        if (extraOffset >= 0) extraStart[index - n] = extraOffset
        val d = java.lang.Float.floatToIntBits(max(0f, depth)).toLong()
        return (d shl 32) or (index.toLong() and 0xFFFFFFFFL)
    }

    private fun drawTriangles(nc: NativeCanvas, verts: FloatArray, colors: IntArray, triangles: Int) {
        if (triangles == 0) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q || !nc.isHardwareAccelerated) {
            nc.drawVertices(
                NativeCanvas.VertexMode.TRIANGLES, triangles * 6, verts, 0,
                null, 0, colors, 0, null, 0, 0, paint,
            )
        } else {
            // Vor Android 10 kann die Hardware-Leinwand kein drawVertices.
            paint.style = Paint.Style.FILL
            for (t in 0 until triangles) {
                val o = t * 6
                path.reset()
                path.moveTo(verts[o], verts[o + 1])
                path.lineTo(verts[o + 2], verts[o + 3])
                path.lineTo(verts[o + 4], verts[o + 5])
                path.close()
                paint.color = colors[t * 3 + 1]
                nc.drawPath(path, paint)
            }
        }
    }
}
