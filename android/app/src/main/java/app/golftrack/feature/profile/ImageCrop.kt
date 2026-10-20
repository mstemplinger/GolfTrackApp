package app.golftrack.feature.profile

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import java.io.File
import java.io.FileOutputStream

/** Bilder laden/speichern – verkleinert, Ausrichtung aus den EXIF-Daten berücksichtigt. */
internal object ImageTools {
    fun decode(ctx: Context, uri: Uri, maxSide: Int = 2048): Bitmap? = runCatching {
        if (Build.VERSION.SDK_INT >= 28) {
            val src = ImageDecoder.createSource(ctx.contentResolver, uri)
            ImageDecoder.decodeBitmap(src) { dec, info, _ ->
                val w = info.size.width; val h = info.size.height
                val scale = maxOf(1f, maxOf(w, h) / maxSide.toFloat())
                dec.setTargetSize((w / scale).toInt(), (h / scale).toInt())
                dec.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            }
        } else {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            ctx.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
            var sample = 1
            while (maxOf(bounds.outWidth, bounds.outHeight) / sample > maxSide) sample *= 2
            val bmp = ctx.contentResolver.openInputStream(uri)?.use {
                BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = sample })
            } ?: return null
            val orientation = ctx.contentResolver.openInputStream(uri)?.use {
                ExifInterface(it).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            } ?: ExifInterface.ORIENTATION_NORMAL
            val deg = when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
            if (deg == 0f) bmp else Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, Matrix().apply { postRotate(deg) }, true)
        }
    }.getOrNull()

    fun saveJpeg(bmp: Bitmap, file: File, quality: Int = 85) {
        file.parentFile?.mkdirs()
        val tmp = File(file.parentFile, file.name + ".tmp")
        FileOutputStream(tmp).use { bmp.compress(Bitmap.CompressFormat.JPEG, quality, it) }
        tmp.renameTo(file)
    }

    fun load(file: File, maxSide: Int = 2048): Bitmap? = runCatching {
        if (!file.exists()) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.path, bounds)
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > maxSide) sample *= 2
        BitmapFactory.decodeFile(file.path, BitmapFactory.Options().apply { inSampleSize = sample })
    }.getOrNull()
}

/** Profilbild wie `ProfileImageStore` – eine JPEG-Datei im App-Speicher. */
internal object ProfileImageStore {
    private fun file(ctx: Context) = File(ctx.filesDir, "profile_image.jpg")
    fun save(ctx: Context, bmp: Bitmap) = ImageTools.saveJpeg(bmp, file(ctx))
    fun load(ctx: Context): Bitmap? = ImageTools.load(file(ctx), 600)
}

/**
 * Runder Ausschnitt wie ImageCropView.swift: Ziehen & Zoomen, der Ring bleibt
 * immer vollständig mit Bild bedeckt.
 */
@Composable
internal fun ImageCropDialog(image: Bitmap, onCancel: () -> Unit, onCrop: (Bitmap) -> Unit) {
    Dialog(
        onDismissRequest = onCancel,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        BoxWithConstraints(Modifier.fillMaxSize().background(Color.Black)) {
            val density = LocalDensity.current
            val viewW = with(density) { maxWidth.toPx() }
            val viewH = with(density) { maxHeight.toPx() }
            val cropPx = with(density) { 280.dp.toPx() }

            // Bildgröße bei Zoom 1 (füllend im Rahmen).
            val imgAspect = image.width.toFloat() / image.height
            val base = if (imgAspect > viewW / viewH) Size(viewH * imgAspect, viewH) else Size(viewW, viewW / imgAspect)
            val minScale = minOf(1f, cropPx / minOf(base.width, base.height))
            val maxScale = 6f

            var scale by remember { mutableFloatStateOf(1f) }
            var offset by remember { mutableStateOf(Offset.Zero) }

            fun clamp(o: Offset, s: Float): Offset {
                val maxX = maxOf(0f, (base.width * s - cropPx) / 2)
                val maxY = maxOf(0f, (base.height * s - cropPx) / 2)
                return Offset(o.x.coerceIn(-maxX, maxX), o.y.coerceIn(-maxY, maxY))
            }

            Image(
                image.asImageBitmap(), null,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
                    .pointerInput(Unit) {
                        detectTransformGestures { _, pan, zoom, _ ->
                            val s = (scale * zoom).coerceIn(minScale, maxScale)
                            scale = s
                            offset = clamp(offset + pan, s)
                        }
                    }
                    .graphicsLayer {
                        scaleX = scale; scaleY = scale
                        translationX = offset.x; translationY = offset.y
                    },
            )
            // Abdunklung mit kreisrundem Ausschnitt
            Canvas(Modifier.fillMaxSize().graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }) {
                drawRect(Color.Black.copy(alpha = 0.55f))
                drawCircle(Color.Black, radius = cropPx / 2, center = center, blendMode = BlendMode.Clear)
                drawCircle(AppTheme.gold, radius = cropPx / 2, center = center, style = Stroke(2.dp.toPx()))
            }
            Column(Modifier.fillMaxSize().safeDrawingPadding()) {
                Row(Modifier.fillMaxWidth().padding(8.dp)) {
                    TextButton(onClick = { Haptics.tap(); onCancel() }) { Text("Abbrechen", color = Color.White, fontSize = 16.sp) }
                    Spacer(Modifier.weight(1f))
                    TextButton(onClick = {
                        Haptics.success()
                        onCrop(cropBitmap(image, base, scale, offset, cropPx))
                    }) { Text("Übernehmen", color = AppTheme.gold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold) }
                }
                Spacer(Modifier.weight(1f))
                Text(
                    "Ziehen & Zoomen zum Anpassen", color = Color.White.copy(alpha = 0.6f), fontSize = 12.sp,
                    modifier = Modifier.align(Alignment.CenterHorizontally).padding(bottom = 40.dp),
                )
            }
        }
    }
}

/** Rechnet den sichtbaren Ring auf das Originalbild zurück (Ausgabe 600 × 600). */
private fun cropBitmap(image: Bitmap, base: Size, scale: Float, offset: Offset, cropPx: Float): Bitmap {
    val out = 600
    val result = Bitmap.createBitmap(out, out, Bitmap.Config.ARGB_8888)
    val canvas = android.graphics.Canvas(result)
    val k = out / cropPx
    val scaledW = base.width * scale
    val scaledH = base.height * scale
    val m = Matrix()
    m.postScale(scaledW / image.width, scaledH / image.height)
    m.postTranslate(-scaledW / 2 + offset.x + cropPx / 2, -scaledH / 2 + offset.y + cropPx / 2)
    m.postScale(k, k)
    canvas.drawBitmap(image, m, android.graphics.Paint(android.graphics.Paint.FILTER_BITMAP_FLAG))
    return result
}
