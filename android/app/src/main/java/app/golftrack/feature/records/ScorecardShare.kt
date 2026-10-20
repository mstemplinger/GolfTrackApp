package app.golftrack.feature.records

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.FileProvider
import app.golftrack.data.Course
import app.golftrack.data.Round
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/*
 * Teilen der Scorecard als Bild – Gegenstück zu ScorecardShareCard.swift.
 * Statt `ImageRenderer` wird die Karte direkt auf ein Bitmap gezeichnet
 * (390 pt breit, Faktor 3 wie auf iOS) und per Android-Share-Intent geteilt.
 */

internal data class ScorecardShareData(
    val courseName: String,
    val date: Long,
    val gameModeName: String,
    val holes: List<HoleEntry>,
    val totalPar: Int,
) {
    data class HoleEntry(val number: Int, val strokes: Int, val par: Int)

    val totalStrokes: Int get() = holes.sumOf { it.strokes }
    val scoreToPar: Int get() = totalStrokes - totalPar

    companion object {
        fun from(round: Round, course: Course?): ScorecardShareData {
            val sorted = round.holeScores.sortedBy { it.holeNumber }
            val pars = course?.parValues ?: List(sorted.size) { 4 }
            return ScorecardShareData(
                courseName = course?.name ?: "Unbekannter Platz",
                date = round.date,
                gameModeName = round.gameMode.displayName,
                holes = sorted.mapIndexed { i, hs -> HoleEntry(hs.holeNumber, hs.strokes, pars.getOrNull(i) ?: 4) },
                totalPar = course?.totalPar ?: 0,
            )
        }
    }
}

private fun rgb(r: Int, g: Int, b: Int, a: Float = 1f): Int = android.graphics.Color.argb((a * 255).toInt(), r, g, b)
private fun white(a: Float) = rgb(255, 255, 255, a)

private val GOLD = rgb(0xC9, 0xA0, 0x35)
private val GREEN_UP = rgb(0x66, 0xD9, 0x7F)
private val RED = rgb(0xFF, 0x66, 0x66)

/** Zeichnet die Share-Karte (Aufbau wie ScorecardShareCard.swift). */
internal fun renderScorecardBitmap(data: ScorecardShareData, scale: Float = 3f): Bitmap {
    val width = 390f
    val is18 = data.holes.size > 9
    val cellW = if (is18) 28f else 34f
    val front = data.holes.take(9)
    val back = data.holes.drop(9)

    val headerH = 82f
    val colHeaderH = 18f
    val rowH = 25f
    val totalH = 30f
    val footerH = 36f
    var gridH = 6f + colHeaderH + rowH
    if (is18) gridH += 4f + colHeaderH + rowH
    gridH += 2f + totalH + 6f
    val height = headerH + gridH + footerH

    val bmp = Bitmap.createBitmap((width * scale).toInt(), (height * scale).toInt(), Bitmap.Config.ARGB_8888)
    val c = Canvas(bmp)
    c.scale(scale, scale)
    val clip = Path().apply { addRoundRect(RectF(0f, 0f, width, height), 20f, 20f, Path.Direction.CW) }
    c.clipPath(clip)

    val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    fun rect(l: Float, t: Float, r: Float, b: Float, color: Int) { fill.color = color; c.drawRect(l, t, r, b, fill) }
    fun text(s: String, x: Float, baseline: Float, size: Float, color: Int, bold: Boolean = false, heavy: Boolean = false, align: Paint.Align = Paint.Align.LEFT) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = size
            this.color = color
            textAlign = align
            typeface = when {
                heavy -> Typeface.create("sans-serif-black", Typeface.NORMAL)
                bold -> Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                else -> Typeface.DEFAULT
            }
        }
        c.drawText(s, x, baseline, p)
    }
    fun centered(s: String, cx: Float, top: Float, h: Float, size: Float, color: Int, bold: Boolean = false) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = size; this.color = color; textAlign = Paint.Align.CENTER
            typeface = if (bold) Typeface.create(Typeface.DEFAULT, Typeface.BOLD) else Typeface.DEFAULT
        }
        c.drawText(s, cx, top + h / 2 - (p.descent() + p.ascent()) / 2, p)
    }

    val d = data.scoreToPar
    val scoreLabel = if (d == 0) "E" else if (d > 0) "+$d" else "$d"
    val scoreColor = when {
        d < 0 -> GREEN_UP
        d == 0 -> white(1f)
        d <= 5 -> GOLD
        else -> RED
    }

    // Hintergrund
    rect(0f, 0f, width, height, rgb(0x0E, 0x27, 0x18))

    // Kopf
    rect(0f, 0f, width, headerH, rgb(0x16, 0x34, 0x21))
    val nameMax = width - 18f - 18f - 110f
    var name = data.courseName
    val namePaint = Paint().apply { textSize = 17f; typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD) }
    if (namePaint.measureText(name) > nameMax) {
        while (name.isNotEmpty() && namePaint.measureText("$name…") > nameMax) name = name.dropLast(1)
        name = "${name.trimEnd()}…"
    }
    text(name, 18f, 14f + 16f, 17f, white(1f), bold = true)
    text(formatDateAbbreviated(data.date), 18f, 14f + 16f + 20f, 12f, white(0.55f))
    text(data.gameModeName, 18f, 14f + 16f + 20f + 18f, 12f, GOLD, bold = true)
    text(scoreLabel, width - 18f, 14f + 34f, 34f, scoreColor, heavy = true, align = Paint.Align.RIGHT)
    text("${data.totalStrokes} Schläge", width - 18f, 14f + 34f + 18f, 12f, white(0.65f), align = Paint.Align.RIGHT)

    // Raster
    var y = headerH + 6f
    fun rowLeft(count: Int) = (width - (64f + count * cellW)) / 2
    fun headers(holes: List<ScorecardShareData.HoleEntry>) {
        val x0 = rowLeft(holes.size)
        centered("Par", x0 + 32f + 16f, y, colHeaderH, 8f, white(0.35f), bold = true)
        holes.forEachIndexed { i, h -> centered("${h.number}", x0 + 64f + i * cellW + cellW / 2, y, colHeaderH, 8f, white(0.35f), bold = true) }
        y += colHeaderH
    }
    fun nine(label: String, holes: List<ScorecardShareData.HoleEntry>) {
        val x0 = rowLeft(holes.size)
        rect(x0, y, x0 + 64f + holes.size * cellW, y + rowH, rgb(0x1C, 0x41, 0x29, 0.5f))
        centered(label, x0 + 16f, y, rowH, 9f, GOLD, bold = true)
        centered("${holes.sumOf { it.par }}", x0 + 48f, y, rowH, 10f, white(0.55f), bold = true)
        holes.forEachIndexed { i, h ->
            val diff = h.strokes - h.par
            val (bg, fg) = when {
                h.strokes == 0 -> 0 to white(0.25f)
                diff <= -2 -> rgb(0x66, 0xD9, 0x7F, 0.25f) to GREEN_UP
                diff == -1 -> rgb(0x66, 0xD9, 0x7F, 0.12f) to GREEN_UP
                diff == 0 -> 0 to white(1f)
                diff == 1 -> rgb(0xC9, 0xA0, 0x35, 0.18f) to GOLD
                else -> rgb(0xFF, 0x66, 0x66, 0.18f) to RED
            }
            val l = x0 + 64f + i * cellW
            if (bg != 0) rect(l, y, l + cellW, y + rowH, bg)
            centered(if (h.strokes == 0) "–" else "${h.strokes}", l + cellW / 2, y, rowH, 11f, fg, bold = true)
        }
        y += rowH
    }
    headers(front)
    nine("OUT", front)
    if (is18) {
        y += 4f
        headers(back)
        nine("IN", back)
    }
    y += 2f
    rect(0f, y, width, y + totalH, rgb(0x16, 0x34, 0x21))
    centered("TOT", 16f, y, totalH, 9f, GOLD, bold = true)
    centered("${data.totalPar}", 48f, y, totalH, 10f, white(0.55f), bold = true)
    text("${data.totalStrokes}", width - 14f, y + totalH / 2 + 7f, 20f, scoreColor, heavy = true, align = Paint.Align.RIGHT)

    // Fuß
    val fy = height - footerH
    rect(0f, fy, width, height, rgb(0x11, 0x2D, 0x1C))
    fill.color = GOLD
    c.drawCircle(18f + 5f, fy + footerH / 2, 4f, fill)
    text("GolfTrack", 18f + 14f, fy + footerH / 2 + 4.5f, 12f, white(0.45f), bold = true)
    text("Erstellt mit GolfTrack", width - 18f, fy + footerH / 2 + 4f, 11f, white(0.25f), align = Paint.Align.RIGHT)

    return bmp
}

/** Rendert die Scorecard und öffnet das Android-Teilen-Menü. */
internal suspend fun shareScorecard(context: Context, round: Round, course: Course?) {
    val data = ScorecardShareData.from(round, course)
    val uri = withContext(Dispatchers.IO) {
        val bmp = renderScorecardBitmap(data)
        runCatching { writeShareImage(context, bmp) }.getOrNull()
    }
    val intent = if (uri != null) {
        Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    } else {
        // Ohne Speicherort für das Bild wenigstens das Ergebnis als Text teilen.
        Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            val d = data.scoreToPar
            val label = if (d == 0) "E" else if (d > 0) "+$d" else "$d"
            putExtra(
                Intent.EXTRA_TEXT,
                "${data.courseName} · ${formatDateAbbreviated(data.date)}\n${data.gameModeName}: $label (${data.totalStrokes} Schläge)\nErstellt mit GolfTrack",
            )
        }
    }
    context.startActivity(Intent.createChooser(intent, null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
}

/**
 * Bild ablegen und eine teilbare `content://`-URI liefern. Bevorzugt einen
 * FileProvider (`<paket>.fileprovider`, falls im Manifest eingetragen), sonst
 * MediaStore (ab Android 10 ohne Berechtigung).
 */
private fun writeShareImage(context: Context, bmp: Bitmap): Uri? {
    val authority = "${context.packageName}.fileprovider"
    val hasProvider = runCatching {
        context.packageManager.resolveContentProvider(authority, 0) != null
    }.getOrDefault(false)
    if (hasProvider) {
        val dir = File(context.cacheDir, "shared").apply { mkdirs() }
        val file = File(dir, "golftrack-scorecard.png")
        file.outputStream().use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
        return FileProvider.getUriForFile(context, authority, file)
    }
    if (Build.VERSION.SDK_INT >= 29) {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "GolfTrack-Scorecard-${System.currentTimeMillis()}.png")
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/GolfTrack")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val resolver = context.contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return null
        resolver.openOutputStream(uri)?.use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
        values.clear()
        values.put(MediaStore.Images.Media.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return uri
    }
    return null
}
