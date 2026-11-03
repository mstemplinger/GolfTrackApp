package app.golftrack.feature.lobby

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.EncodeHintType
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.GlobalHistogramBinarizer
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/*
 * QR-Code der Lobby – Anzeige für den Gastgeber und Erkennung für Gäste.
 * Ohne Google-Play-Dienste: Erzeugen und Lesen über zxing (core).
 */

object LobbyQr {
    /** QR-Code als Bitmap, ein Pixel je Modul (wird ohne Glättung vergrößert). */
    fun bitmap(text: String): Bitmap? = runCatching {
        val hints = mapOf(EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.M, EncodeHintType.MARGIN to 0)
        val matrix = QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, 0, 0, hints)
        val w = matrix.width
        val h = matrix.height
        val pixels = IntArray(w * h) { i -> if (matrix.get(i % w, i / w)) android.graphics.Color.BLACK else android.graphics.Color.WHITE }
        Bitmap.createBitmap(pixels, w, h, Bitmap.Config.ARGB_8888)
    }.getOrNull()

    /** Fünf Ziffern aus dem Inhalt eines QR-Codes – Link oder nackter Code. */
    fun code(payload: String): String? {
        val trimmed = payload.trim()
        val uri = runCatching { Uri.parse(trimmed) }.getOrNull()
        val segs = uri?.pathSegments.orEmpty()
        if (uri?.scheme != null && segs.size >= 2 && segs[segs.size - 2] == "lobby") {
            val last = segs.last()
            return last.takeIf { it.length == 5 && it.all(Char::isDigit) }
        }
        if (uri?.scheme == "golftrack" && uri.host == "lobby") {
            return segs.firstOrNull()?.takeIf { it.length == 5 && it.all(Char::isDigit) }
        }
        return trimmed.takeIf { it.length == 5 && it.all(Char::isDigit) }
    }

    /** Sucht im Foto einen Lobby-QR-Code. `null`, wenn keiner erkannt wird. */
    suspend fun decode(ctx: Context, uri: Uri): String? = withContext(Dispatchers.Default) {
        val bmp = runCatching { load(ctx, uri) }.getOrNull() ?: return@withContext null
        decode(bmp)
    }

    fun decode(bmp: Bitmap): String? {
        val w = bmp.width
        val h = bmp.height
        val pixels = IntArray(w * h)
        bmp.getPixels(pixels, 0, w, 0, 0, w, h)
        val source = RGBLuminanceSource(w, h, pixels)
        val hints = mapOf(
            DecodeHintType.TRY_HARDER to true,
            DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE),
        )
        for (binary in listOf(BinaryBitmap(HybridBinarizer(source)), BinaryBitmap(GlobalHistogramBinarizer(source)))) {
            val text = runCatching { QRCodeReader().decode(binary, hints).text }.getOrNull() ?: continue
            code(text)?.let { return it }
        }
        return null
    }

    /** Foto verkleinert laden – zxing braucht keine 12 Megapixel. */
    private fun load(ctx: Context, uri: Uri): Bitmap? {
        val maxSide = 1600
        if (Build.VERSION.SDK_INT >= 28) {
            val src = ImageDecoder.createSource(ctx.contentResolver, uri)
            return ImageDecoder.decodeBitmap(src) { decoder, info, _ ->
                val longest = maxOf(info.size.width, info.size.height)
                if (longest > maxSide) {
                    val f = maxSide.toFloat() / longest
                    decoder.setTargetSize((info.size.width * f).toInt(), (info.size.height * f).toInt())
                }
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            }
        }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSide) sample *= 2
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        return ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, opts) }
    }
}

/** QR-Code der Lobby auf weißem Grund (wie `LobbyQRCode`). */
@Composable
fun LobbyQrCode(code: String, modifier: Modifier = Modifier) {
    val image = remember(code) { LobbyQr.bitmap(LobbyService.joinUrl(code))?.asImageBitmap() } ?: return
    Image(
        image, contentDescription = "QR-Code",
        filterQuality = FilterQuality.None,
        contentScale = ContentScale.Fit,
        modifier = modifier.background(Color.White, RoundedCornerShape(10.dp)).padding(6.dp),
    )
}
