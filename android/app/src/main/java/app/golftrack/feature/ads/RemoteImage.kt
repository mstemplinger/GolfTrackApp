package app.golftrack.feature.ads

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.LruCache
import androidx.compose.foundation.Image
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.URL

/** Kleiner Bildlader ohne Fremdbibliothek (für Anzeigenbilder), Zwischenspeicher im Arbeitsspeicher. */
internal object RemoteImages {
    private val cache = object : LruCache<String, Bitmap>(8 * 1024 * 1024) {
        override fun sizeOf(key: String, value: Bitmap) = value.byteCount
    }

    fun cached(url: String): Bitmap? = cache.get(url)

    suspend fun load(url: String): Bitmap? {
        cache.get(url)?.let { return it }
        return withContext(Dispatchers.IO) {
            runCatching {
                val c = URL(url).openConnection() as HttpURLConnection
                try {
                    c.connectTimeout = 10_000
                    c.readTimeout = 15_000
                    if (c.responseCode !in 200..299) return@runCatching null
                    val bytes = c.inputStream.use { it.readBytes() }
                    val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)
                    var sample = 1
                    while (opts.outWidth / sample > 600 || opts.outHeight / sample > 600) sample *= 2
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })
                } finally {
                    c.disconnect()
                }
            }.getOrNull()?.also { cache.put(url, it) }
        }
    }
}

/** Bild aus dem Netz; bis es geladen ist (oder wenn es fehlt) steht `placeholder`. */
@Composable
internal fun RemoteImage(
    url: String,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
    placeholder: @Composable () -> Unit,
) {
    val bitmap by produceState(RemoteImages.cached(url), url) { value = RemoteImages.load(url) }
    val b = bitmap
    if (b != null) Image(b.asImageBitmap(), contentDescription = null, modifier = modifier, contentScale = contentScale)
    else placeholder()
}
