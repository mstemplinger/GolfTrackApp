package app.golftrack.feature.records

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/** Ergebnis des Scorecard-Scans – wie `ParsedScorecardData`. */
internal data class ParsedScorecardData(
    val name: String = "",
    val parValues: List<Int> = emptyList(),
    val hcpValues: List<Int> = emptyList(),
    val holeLengths: List<Int> = emptyList(),
    val courseRating: Double? = null,
    val slopeRating: Int? = null,
) {
    val numberOfHoles: Int get() = if (parValues.isEmpty()) 18 else parValues.size
}

/**
 * Wie ScorecardParserService.swift: Texterkennung (hier ML Kit, gebündeltes
 * Modell – läuft ohne Play-Dienste), danach regelbasierte Auswertung.
 */
internal object ScorecardParser {

    class ParserError(message: String) : Exception(message)

    suspend fun parse(context: Context, uri: Uri): ParsedScorecardData =
        parse(runCatching { InputImage.fromFilePath(context, uri) }.getOrElse {
            throw ParserError("Das Bild konnte nicht verarbeitet werden.")
        })

    suspend fun parse(bitmap: Bitmap): ParsedScorecardData = parse(InputImage.fromBitmap(bitmap, 0))

    private suspend fun parse(image: InputImage): ParsedScorecardData {
        val text = recognize(image)
        val lines = text.textBlocks.flatMap { b -> b.lines.map { it.text.trim() } }
        return parseWithRegex(lines, tableRows(text))
    }

    private suspend fun recognize(image: InputImage): Text {
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        return try {
            suspendCancellableCoroutine { cont ->
                recognizer.process(image)
                    .addOnSuccessListener { cont.resume(it) }
                    .addOnFailureListener { cont.resumeWithException(it) }
            }
        } finally {
            recognizer.close()
        }
    }

    /**
     * ML Kit liefert Textblöcke, keine Tabellenzeilen. Damit die Zahlenreihen
     * einer Scorecard wieder zusammenkommen, werden alle Wörter nach ihrer
     * vertikalen Lage zu Zeilen gruppiert und von links nach rechts gelesen.
     */
    private fun tableRows(text: Text): List<String> {
        data class W(val s: String, val cx: Float, val cy: Float, val h: Float)
        val words = text.textBlocks.flatMap { b -> b.lines.flatMap { l -> l.elements } }.mapNotNull { e ->
            val r = e.boundingBox ?: return@mapNotNull null
            W(e.text, r.exactCenterX(), r.exactCenterY(), r.height().toFloat().coerceAtLeast(1f))
        }
        if (words.isEmpty()) return emptyList()
        val medianH = words.map { it.h }.sorted()[words.size / 2]
        val rows = mutableListOf<MutableList<W>>()
        for (w in words.sortedBy { it.cy }) {
            val row = rows.lastOrNull()
            if (row != null && kotlin.math.abs(row.map { it.cy }.average() - w.cy) < medianH * 0.5) row += w
            else rows += mutableListOf(w)
        }
        return rows.map { r -> r.sortedBy { it.cx }.joinToString(" ") { it.s } }
    }

    /** Regelbasierte Auswertung (Regex-Fallback von iOS). */
    fun parseWithRegex(lines: List<String>, rows: List<String> = emptyList()): ParsedScorecardData {
        // Platzname: erste Zeile, die nach Titel aussieht
        var name = ""
        for (line in lines) {
            val words = line.split(" ").filter { it.isNotEmpty() }
            if (words.size >= 2 && line.length > 4 && !line.startsWith("Loch") && !line.startsWith("Hole")) {
                if (!Regex("^\\d[\\d\\s]+$").matches(line)) { name = line; break }
            }
        }

        // Zahlenreihen mit 9 oder 18 Werten finden
        val numericRows = mutableListOf<List<Int>>()
        for (line in rows + lines) {
            var numbers = line.split(Regex("\\s+")).mapNotNull { it.trim('|', '.', ',', ':', ';', '[', ']', '(', ')').toIntOrNull() }
            // Eine angehängte Summe (OUT/IN) gehört nicht zu den Lochwerten.
            if (numbers.size == 10 && numbers.last() == numbers.take(9).sum()) numbers = numbers.take(9)
            if ((numbers.size == 9 || numbers.size == 18) && numbers.all { it in 1..999 }) numericRows += numbers
        }

        // Reihen einordnen
        var pars = emptyList<Int>()
        var hcps = emptyList<Int>()
        var lengths = emptyList<Int>()
        for (row in numericRows) {
            val isPar = row.all { it in 3..5 }
            val isHcp = row.all { it in 1..18 } && row.toSet().size == row.size
            val isDistance = row.all { it in 50..700 }
            when {
                isPar && pars.isEmpty() -> pars = row
                isHcp && hcps.isEmpty() -> hcps = row
                isDistance && lengths.isEmpty() -> lengths = row
            }
        }

        // Course Rating / Slope
        val full = (lines + rows).joinToString("\n")
        val cr = Regex("CR[:\\s]*(\\d{2,3}[,.]\\d)").find(full)?.groupValues?.get(1)?.replace(',', '.')?.toDoubleOrNull()
        val sr = Regex("SR[:\\s]*(\\d{2,3})").find(full)?.groupValues?.get(1)?.toIntOrNull()

        return ParsedScorecardData(name, pars, hcps, lengths, cr, sr)
    }
}
