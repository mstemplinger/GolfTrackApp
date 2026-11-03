package app.golftrack.ui.common

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.text.TextUtils
import android.text.TextPaint
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.IosShare
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/*
 * Runde teilen: Text, Ergebniskarte und Knopf – für Golf und Minigolf,
 * wie GolfTrackShared/RoundShare.swift.
 *
 * Geteilt wird ein freundlicher Text mit den wichtigsten Zahlen, ein Link zum
 * Laden der App und ein Bild der Runde. Der Link führt auf `golftrack.app/laden`,
 * die Weiche zwischen App Store und Android-APK.
 */

// MARK: - Inhalt

/** Eine Runde, so wie sie geteilt wird – reine Werte, damit Golf und Minigolf denselben Text und dieselbe Karte erzeugen. */
data class RoundShareSummary(
    val kind: Kind,
    val courseName: String?,
    /** Millisekunden; `null`, wenn das Datum nicht bekannt ist – dann fehlt es im Text. */
    val dateMillis: Long?,
    val holesPlayed: Int,
    val holesTotal: Int,
    val totalStrokes: Int,
    val scoreToPar: Int? = null,
    /** Schläge je Loch bzw. Bahn bei einer Einzelrunde, 0 = nicht gespielt. */
    val holeStrokes: List<Int> = emptyList(),
    /** Rangliste, nur bei Minigolf mit mehreren Spielern. */
    val ranking: List<Player> = emptyList(),
) {
    enum class Kind { GOLF, MINIGOLF }

    /** `place`: 0 = vorn. Gleich viele Schläge teilen sich den Platz. */
    data class Player(val name: String, val total: Int, val place: Int)

    val isGroup: Boolean get() = ranking.size > 1

    companion object {
        /**
         * Golf. `pars` leer (oder andere Länge), wenn der Platz keine Par-Werte
         * hat – dann bleibt der Stand gegen Par weg.
         */
        fun golf(courseName: String?, dateMillis: Long?, strokes: List<Int>, pars: List<Int>): RoundShareSummary {
            val hasPar = pars.size == strokes.size
            val toPar = if (hasPar) strokes.zip(pars).filter { it.first > 0 }.sumOf { it.first - it.second } else null
            return RoundShareSummary(
                kind = Kind.GOLF,
                courseName = courseName,
                dateMillis = dateMillis,
                holesPlayed = strokes.count { it > 0 },
                holesTotal = strokes.size,
                totalStrokes = strokes.sum(),
                scoreToPar = if (strokes.any { it > 0 }) toPar else null,
                holeStrokes = strokes,
            )
        }

        /** Minigolf, eine Zeile in `scores` je Spieler. Bei einem Spieler zählt dessen Runde, bei mehreren die Rangliste. */
        fun minigolf(
            playerNames: List<String>,
            scores: List<List<Int>>,
            numberOfHoles: Int,
            courseName: String?,
            dateMillis: Long?,
        ): RoundShareSummary {
            val totals = scores.map { it.sum() }
            val ranking = playerNames.indices.map { i ->
                val own = totals.getOrElse(i) { 0 }
                Player(playerNames[i], own, totals.count { it < own })
            }.sortedBy { it.total }
            return RoundShareSummary(
                kind = Kind.MINIGOLF,
                courseName = courseName,
                dateMillis = dateMillis,
                holesPlayed = scores.maxOfOrNull { row -> row.count { it > 0 } } ?: 0,
                holesTotal = numberOfHoles,
                totalStrokes = totals.firstOrNull() ?: 0,
                scoreToPar = null,
                holeStrokes = if (playerNames.size == 1) scores.firstOrNull().orEmpty() else emptyList(),
                ranking = if (playerNames.size > 1) ranking else emptyList(),
            )
        }
    }
}

// MARK: - Text

object RoundShareText {
    /** Weiche zwischen App Store und Android-APK auf der eigenen Seite. */
    const val DOWNLOAD_URL = "https://golftrack.app/laden"

    fun message(summary: RoundShareSummary): String {
        val lines = mutableListOf(intro(summary))
        val details = detailParts(summary)
        if (details.isNotEmpty()) lines += details.joinToString(" · ")
        if (summary.isGroup) {
            lines += ""
            lines += summary.ranking.map { "${medal(it.place)} ${it.name} – ${it.total} Schläge" }
        }
        lines += ""
        lines += "Gezählt mit GolfTrack. Hol dir die App auch: $DOWNLOAD_URL"
        return lines.joinToString("\n")
    }

    private fun intro(summary: RoundShareSummary): String {
        val course = summary.courseName
        if (summary.isGroup) {
            return if (course != null) "Schau mal, wie unsere Minigolf-Runde auf $course gelaufen ist:"
            else "Schau mal, wie unsere Minigolf-Runde gelaufen ist:"
        }
        val strokes = "${summary.totalStrokes} Schläge"
        return if (course != null) "Schau mal, ich habe gerade auf $course $strokes gebraucht!"
        else "Schau mal, ich habe gerade $strokes gebraucht!"
    }

    fun detailParts(summary: RoundShareSummary): List<String> {
        val parts = mutableListOf<String>()
        summary.dateMillis?.let { parts += SimpleDateFormat("d. MMMM yyyy", Locale.GERMAN).format(Date(it)) }
        parts += holesText(summary)
        summary.scoreToPar?.let { parts += if (it == 0) "Par gespielt" else "${signed(it)} zu Par" }
        return parts
    }

    fun holesText(summary: RoundShareSummary): String {
        val played = summary.holesPlayed
        val total = summary.holesTotal
        val complete = played >= total
        return when (summary.kind) {
            RoundShareSummary.Kind.GOLF -> if (complete) "$total Löcher" else "$played von $total Löchern"
            RoundShareSummary.Kind.MINIGOLF -> if (complete) "$total Bahnen" else "$played von $total Bahnen"
        }
    }

    fun signed(value: Int): String = if (value > 0) "+$value" else "$value"

    fun medal(place: Int): String = when (place) {
        0 -> "🥇"
        1 -> "🥈"
        2 -> "🥉"
        else -> "${place + 1}."
    }
}

// MARK: - Ergebniskarte

/**
 * Das Bild zum Teilen, direkt auf ein Bitmap gezeichnet (390 pt breit,
 * Faktor 3 wie `ImageRenderer` auf iOS). Farben aus `AppTheme`.
 */
object RoundShareCard {
    const val WIDTH = 390f

    fun render(summary: RoundShareSummary, scale: Float = 3f): Bitmap {
        val pad = 18f
        val headerH = 68f
        val footerH = 36f
        val rows = summary.ranking.take(6)
        val bodyH = if (summary.isGroup) pad * 2 + rows.size * 46f else pad * 2 + 70f
        val showGrid = !summary.isGroup && summary.holeStrokes.isNotEmpty()
        val cellGap = 5f
        val cellH = 34f
        val gridRows = if (showGrid) (summary.holeStrokes.size + 8) / 9 else 0
        val gridH = if (showGrid) gridRows * cellH + (gridRows - 1) * cellGap + pad else 0f
        val height = headerH + bodyH + gridH + footerH

        val bmp = Bitmap.createBitmap((WIDTH * scale).toInt(), (height * scale).toInt(), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        c.scale(scale, scale)
        c.clipPath(Path().apply { addRoundRect(RectF(0f, 0f, WIDTH, height), 20f, 20f, Path.Direction.CW) })

        val fill = Paint(Paint.ANTI_ALIAS_FLAG)
        fun rect(l: Float, t: Float, r: Float, b: Float, color: Color, radius: Float = 0f) {
            fill.color = color.toArgb()
            if (radius > 0) c.drawRoundRect(RectF(l, t, r, b), radius, radius, fill) else c.drawRect(l, t, r, b, fill)
        }
        fun paint(size: Float, color: Color, weight: Int = Typeface.NORMAL, align: Paint.Align = Paint.Align.LEFT, family: String? = null) =
            TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = size
                this.color = color.toArgb()
                textAlign = align
                typeface = if (family != null) Typeface.create(family, weight) else Typeface.create(Typeface.DEFAULT, weight)
            }
        fun text(s: String, x: Float, baseline: Float, p: TextPaint, maxWidth: Float? = null) {
            val shown = if (maxWidth != null) TextUtils.ellipsize(s, p, maxWidth, TextUtils.TruncateAt.END).toString() else s
            c.drawText(shown, x, baseline, p)
        }
        fun centered(s: String, cx: Float, cy: Float, p: TextPaint) {
            p.textAlign = Paint.Align.CENTER
            c.drawText(s, cx, cy - (p.descent() + p.ascent()) / 2, p)
        }

        // Hintergrund
        rect(0f, 0f, WIDTH, height, AppTheme.bg)

        // Kopf
        rect(0f, 0f, WIDTH, headerH, AppTheme.card)
        fill.color = AppTheme.gold.copy(alpha = 0.15f).toArgb()
        c.drawCircle(pad + 20f, headerH / 2, 20f, fill)
        centered(if (summary.kind == RoundShareSummary.Kind.GOLF) "⛳" else "🏁", pad + 20f, headerH / 2, paint(18f, AppTheme.gold))
        val titleX = pad + 40f + 12f
        val title = summary.courseName ?: if (summary.kind == RoundShareSummary.Kind.GOLF) "Golf" else "Minigolf"
        text(title, titleX, headerH / 2 - 3f, paint(17f, AppTheme.text, Typeface.BOLD), WIDTH - titleX - pad)
        val subtitle = buildList {
            summary.dateMillis?.let { add(SimpleDateFormat("d. MMM yyyy", Locale.GERMAN).format(Date(it))) }
            add(RoundShareText.holesText(summary))
        }.joinToString(" · ")
        text(subtitle, titleX, headerH / 2 + 15f, paint(12f, AppTheme.textSec), WIDTH - titleX - pad)

        var y = headerH + pad
        if (summary.isGroup) {
            val listH = rows.size * 46f
            rect(pad, y, WIDTH - pad, y + listH, AppTheme.card, 14f)
            rows.forEachIndexed { i, player ->
                val cy = y + i * 46f + 23f
                val medalSize = if (player.place < 3) 22f else 17f
                centered(RoundShareText.medal(player.place), pad + 12f + 18f, cy, paint(medalSize, AppTheme.textSec, Typeface.BOLD))
                val totalP = paint(20f, if (player.place == 0) AppTheme.gold else AppTheme.text, Typeface.BOLD, Paint.Align.RIGHT)
                val unitP = paint(12f, AppTheme.textSec, align = Paint.Align.RIGHT)
                val unitW = unitP.measureText("Schl.")
                text("Schl.", WIDTH - pad - 12f, cy + 6f, unitP)
                val totalRight = WIDTH - pad - 12f - unitW - 6f
                text("${player.total}", totalRight, cy + 7f, totalP)
                val nameX = pad + 12f + 36f + 12f
                val nameMax = totalRight - totalP.measureText("${player.total}") - 8f - nameX
                text(player.name, nameX, cy + 6f, paint(17f, AppTheme.text, Typeface.BOLD), nameMax)
                if (i < rows.size - 1) rect(pad + 60f, y + (i + 1) * 46f - 0.5f, WIDTH - pad, y + (i + 1) * 46f + 0.5f, AppTheme.cardAlt)
            }
            y += listH + pad
        } else {
            val baseline = y + 58f
            val bigP = paint(64f, AppTheme.gold, Typeface.BOLD, family = "sans-serif-black")
            val big = "${summary.totalStrokes}"
            text(big, pad, baseline, bigP)
            text("Schläge", pad + bigP.measureText(big) + 10f, baseline, paint(20f, AppTheme.textSec, Typeface.BOLD))
            summary.scoreToPar?.let { toPar ->
                val label = if (toPar == 0) "Par" else RoundShareText.signed(toPar)
                val p = paint(22f, AppTheme.scoreColor(toPar), Typeface.BOLD)
                val w = p.measureText(label) + 24f
                rect(WIDTH - pad - w, baseline - 30f, WIDTH - pad, baseline + 6f, AppTheme.card, 18f)
                centered(label, WIDTH - pad - w / 2, baseline - 12f, p)
            }
            y += 70f + pad
        }

        if (showGrid) {
            val cellW = (WIDTH - 2 * pad - 8 * cellGap) / 9
            summary.holeStrokes.forEachIndexed { i, strokes ->
                val col = i % 9
                val row = i / 9
                val l = pad + col * (cellW + cellGap)
                val t = y - pad + row * (cellH + cellGap)
                rect(l, t, l + cellW, t + cellH, AppTheme.cardAlt, 7f)
                centered("${i + 1}", l + cellW / 2, t + 10f, paint(8f, AppTheme.textTer, Typeface.BOLD))
                centered(
                    if (strokes > 0) "$strokes" else "–", l + cellW / 2, t + 23f,
                    paint(13f, if (strokes == 1) AppTheme.gold else AppTheme.text, Typeface.BOLD),
                )
            }
            y += gridH - pad + pad
        }

        // Fuß
        val fy = height - footerH
        rect(0f, fy, WIDTH, height, AppTheme.cardDark)
        fill.color = AppTheme.gold.toArgb()
        c.drawCircle(pad + 5f, fy + footerH / 2, 4f, fill)
        text("GolfTrack", pad + 14f, fy + footerH / 2 + 4.5f, paint(12f, AppTheme.textSec, Typeface.BOLD))
        text("golftrack.app", WIDTH - pad, fy + footerH / 2 + 4f, paint(11f, AppTheme.textTer, align = Paint.Align.RIGHT))
        return bmp
    }
}

// MARK: - Teilen

/**
 * Öffnet das Android-Teilen-Menü mit Text, Link und Ergebniskarte. `image`
 * ersetzt die gemeinsame Karte (z. B. die ausführliche Golf-Scorecard).
 * Fehlt ein Speicherort für das Bild, wird nur der Text geteilt.
 */
suspend fun shareRound(context: Context, summary: RoundShareSummary, image: Bitmap? = null) {
    val message = RoundShareText.message(summary)
    val uri = withContext(Dispatchers.IO) {
        runCatching { writeRoundImage(context, image ?: RoundShareCard.render(summary)) }.getOrNull()
    }
    val intent = Intent(Intent.ACTION_SEND).apply {
        putExtra(Intent.EXTRA_TEXT, message)
        if (uri != null) {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = android.content.ClipData.newRawUri(null, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } else {
            type = "text/plain"
        }
    }
    context.startActivity(Intent.createChooser(intent, null).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
}

/** Bild im Cache (`cache/shared/`, siehe res/xml/file_paths.xml) ablegen und per FileProvider freigeben. */
private fun writeRoundImage(context: Context, bmp: Bitmap): Uri {
    val dir = File(context.cacheDir, "shared").apply { mkdirs() }
    val file = File(dir, "golftrack-runde.png")
    file.outputStream().use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
    return FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
}

// MARK: - Knopf

/**
 * Gut sichtbarer Knopf am Ende der Runde. Öffnet das Teilen-Menü mit Text,
 * Link und Ergebniskarte. `image` liefert optional ein eigenes Bild statt der Karte.
 */
@Composable
fun RoundShareButton(
    summary: RoundShareSummary,
    modifier: Modifier = Modifier,
    image: (() -> Bitmap?)? = null,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var busy by remember { mutableStateOf(false) }
    val ink = Color(0xFF0F2414)
    Row(
        modifier.fillMaxWidth()
            .background(AppTheme.gold, RoundedCornerShape(16.dp))
            .clickable(enabled = !busy) {
                Haptics.tap()
                busy = true
                scope.launch {
                    try {
                        shareRound(context, summary, image?.invoke())
                    } finally {
                        busy = false
                    }
                }
            }
            .padding(horizontal = 14.dp, vertical = 12.dp)
            .testTag("roundShareButton"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(
            Modifier.size(44.dp).background(Color.Black.copy(alpha = 0.12f), RoundedCornerShape(12.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Filled.IosShare, null, tint = ink, modifier = Modifier.size(22.dp))
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text("Runde teilen", color = ink, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
            Text(
                "Ergebnis und Link für Freunde – oder als Bild in Fotos sichern",
                color = ink, fontSize = 12.sp, modifier = Modifier.alpha(0.75f),
            )
        }
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = ink, modifier = Modifier.alpha(0.6f))
    }
}
