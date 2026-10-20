package app.golftrack.feature.records

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.drawable.BitmapDrawable
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Public
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import app.golftrack.data.LatLon
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LocationService
import app.golftrack.ui.theme.AppTheme
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.OnlineTileSourceBase
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.BoundingBox
import org.osmdroid.util.GeoPoint
import org.osmdroid.util.MapTileIndex
import org.osmdroid.views.CustomZoomButtonsController
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import org.osmdroid.views.overlay.Polygon
import org.osmdroid.views.overlay.Polyline
import org.osmdroid.views.overlay.ScaleBarOverlay
import org.osmdroid.views.overlay.mylocation.GpsMyLocationProvider
import org.osmdroid.views.overlay.mylocation.MyLocationNewOverlay

/*
 * Kartenbausteine für Verlauf und Platzverwaltung: osmdroid in einer AndroidView,
 * Luftbild über Esri World Imagery (wie auf der Website), sonst OpenStreetMap.
 * Ersetzt die MapKit-`Map` mit `.automatic`-Kamera: die Karte passt sich beim
 * ersten Layout an alle Inhalte an.
 */

/** Esri World Imagery – Kachel-URL ist z/y/x, deshalb eigene Quelle. */
internal object EsriWorldImagery : OnlineTileSourceBase(
    "EsriWorldImagery", 0, 19, 256, "",
    arrayOf("https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/"),
    "Esri, Maxar, Earthstar Geographics",
) {
    override fun getTileURLString(pMapTileIndex: Long): String =
        baseUrl + "${MapTileIndex.getZoom(pMapTileIndex)}/${MapTileIndex.getY(pMapTileIndex)}/${MapTileIndex.getX(pMapTileIndex)}"
}

internal data class MapLine(
    val points: List<LatLon>,
    val color: Color,
    val widthDp: Float = 3f,
    val dashed: Boolean = false,
)

internal data class MapArea(
    val points: List<LatLon>,
    val fill: Color,
    val stroke: Color,
    val widthDp: Float = 1.5f,
)

internal enum class PinSymbol { TEE, FLAG }

internal sealed interface PinStyle {
    /** Gefüllter Punkt mit weißem Rand (Start/Ende, Landepunkt). */
    data class Dot(val color: Color, val sizeDp: Float = 11f, val borderDp: Float = 2f) : PinStyle
    /** Kreis mit Zahl (Schlagnummer). */
    data class Numbered(val color: Color, val text: String, val sizeDp: Float = 22f) : PinStyle
    /** Leerer Ring (gespeicherte Position zum Vergleich). */
    data class Ring(val color: Color, val sizeDp: Float = 16f, val widthDp: Float = 2f) : PinStyle
    /** Kreis mit Symbol (Abschlag/Grün). */
    data class Symbol(val color: Color, val symbol: PinSymbol, val sizeDp: Float = 28f) : PinStyle
}

internal data class MapPin(val at: LatLon, val style: PinStyle, val title: String = "")

private var osmConfigured = false

private fun ensureOsmConfig(ctx: Context) {
    if (osmConfigured) return
    Configuration.getInstance().load(ctx, ctx.getSharedPreferences("osmdroid", Context.MODE_PRIVATE))
    Configuration.getInstance().userAgentValue = "app.golftrack"
    osmConfigured = true
}

/**
 * Karte mit Linien, Flächen und Markern. `interactive = false` ergibt die
 * nicht bedienbare Vorschau in Karten (wie `.allowsHitTesting(false)`).
 * Der Ausschnitt wird an alle Inhalte angepasst, sobald sich `fitKey` ändert.
 */
@SuppressLint("ClickableViewAccessibility")
@Composable
internal fun OsmMap(
    modifier: Modifier = Modifier,
    satellite: Boolean,
    interactive: Boolean,
    lines: List<MapLine> = emptyList(),
    areas: List<MapArea> = emptyList(),
    pins: List<MapPin> = emptyList(),
    fitKey: Any? = Unit,
) {
    var mapRef by remember { mutableStateOf<MapView?>(null) }
    val state = remember { object { var fittedKey: Any? = null; var satellite: Boolean? = null } }

    AndroidView(
        modifier = modifier,
        factory = { ctx ->
            ensureOsmConfig(ctx)
            MapView(ctx).apply {
                isTilesScaledToDpi = true
                setMultiTouchControls(interactive)
                zoomController.setVisibility(CustomZoomButtonsController.Visibility.NEVER)
                isHorizontalMapRepetitionEnabled = false
                isVerticalMapRepetitionEnabled = false
                minZoomLevel = 3.0
                maxZoomLevel = 20.0
                if (!interactive) setOnTouchListener { _, _ -> true }
                if (interactive) {
                    overlays.add(ScaleBarOverlay(this).apply { setAlignBottom(true); setCentred(true) })
                    if (LocationService.hasPermission(ctx)) {
                        overlays.add(MyLocationNewOverlay(GpsMyLocationProvider(ctx), this).apply { enableMyLocation() })
                    }
                }
                mapRef = this
            }
        },
        update = { map ->
            if (state.satellite != satellite) {
                map.setTileSource(if (satellite) EsriWorldImagery else TileSourceFactory.MAPNIK)
                state.satellite = satellite
            }
            val keep = map.overlays.filter { it is ScaleBarOverlay || it is MyLocationNewOverlay }
            map.overlays.clear()
            map.overlays.addAll(keep)
            val density = map.context.resources.displayMetrics.density
            for (a in areas) {
                if (a.points.size < 3) continue
                map.overlays.add(Polygon(map).apply {
                    points = a.points.map { GeoPoint(it.lat, it.lon) }
                    fillPaint.color = a.fill.toArgb()
                    outlinePaint.color = a.stroke.toArgb()
                    outlinePaint.strokeWidth = a.widthDp * density
                    setOnClickListener { _, _, _ -> true }
                })
            }
            for (l in lines) {
                if (l.points.size < 2) continue
                map.overlays.add(Polyline(map).apply {
                    setPoints(l.points.map { GeoPoint(it.lat, it.lon) })
                    outlinePaint.color = l.color.toArgb()
                    outlinePaint.strokeWidth = l.widthDp * density
                    outlinePaint.strokeCap = Paint.Cap.ROUND
                    outlinePaint.strokeJoin = Paint.Join.ROUND
                    outlinePaint.isAntiAlias = true
                    if (l.dashed) outlinePaint.pathEffect = DashPathEffect(floatArrayOf(6 * density, 4 * density), 0f)
                    setOnClickListener { _, _, _ -> true }
                })
            }
            for (p in pins) {
                map.overlays.add(Marker(map).apply {
                    position = GeoPoint(p.at.lat, p.at.lon)
                    icon = BitmapDrawable(map.context.resources, pinBitmap(p.style, density))
                    setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_CENTER)
                    title = p.title
                    setOnMarkerClickListener { _, _ -> true }
                })
            }
            if (state.fittedKey != fitKey) {
                state.fittedKey = fitKey
                val all = lines.flatMap { it.points } + areas.flatMap { it.points } + pins.map { it.at }
                fitTo(map, all.filter { it.isValid }, density)
            }
            map.invalidate()
        },
    )

    DisposableEffect(Unit) {
        onDispose {
            mapRef?.overlays?.filterIsInstance<MyLocationNewOverlay>()?.forEach { it.disableMyLocation() }
            mapRef?.onDetach()
        }
    }
}

private fun fitTo(map: MapView, points: List<LatLon>, density: Float) {
    if (points.isEmpty()) {
        map.controller.setZoom(5.0)
        map.controller.setCenter(GeoPoint(51.0, 10.0))
        return
    }
    val run = {
        if (points.size == 1 || points.all { it == points[0] }) {
            map.controller.setZoom(17.0)
            map.controller.setCenter(GeoPoint(points[0].lat, points[0].lon))
        } else {
            var north = points.maxOf { it.lat }
            var south = points.minOf { it.lat }
            var east = points.maxOf { it.lon }
            var west = points.minOf { it.lon }
            // Mindestausdehnung, sonst zoomt die Karte bei kurzen Spuren zu weit hinein.
            val minSpan = 0.0006
            if (north - south < minSpan) { val c = (north + south) / 2; north = c + minSpan / 2; south = c - minSpan / 2 }
            if (east - west < minSpan) { val c = (east + west) / 2; east = c + minSpan / 2; west = c - minSpan / 2 }
            map.zoomToBoundingBox(BoundingBox(north, east, south, west), false, (28 * density).toInt())
        }
    }
    if (map.width > 0 && map.height > 0) run() else map.addOnFirstLayoutListener { _, _, _, _, _ -> run() }
}

/** Zeichnet die Markergrafik – Ersatz für die SwiftUI-`Annotation`-Views. */
private fun pinBitmap(style: PinStyle, density: Float): Bitmap {
    val shadow = 2 * density
    fun bmp(sizeDp: Float): Pair<Bitmap, android.graphics.Canvas> {
        val px = (sizeDp * density + shadow * 2).toInt().coerceAtLeast(4)
        val b = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
        return b to android.graphics.Canvas(b)
    }
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    return when (style) {
        is PinStyle.Dot -> {
            val (b, c) = bmp(style.sizeDp)
            val cx = b.width / 2f
            val r = style.sizeDp * density / 2
            paint.color = android.graphics.Color.WHITE
            c.drawCircle(cx, cx, r, paint)
            paint.color = style.color.toArgb()
            c.drawCircle(cx, cx, r - style.borderDp * density * 0.75f, paint)
            b
        }
        is PinStyle.Numbered -> {
            val (b, c) = bmp(style.sizeDp)
            val cx = b.width / 2f
            val r = style.sizeDp * density / 2
            paint.color = android.graphics.Color.argb(90, 0, 0, 0)
            c.drawCircle(cx, cx + density, r, paint)
            paint.color = style.color.toArgb()
            c.drawCircle(cx, cx, r, paint)
            paint.color = android.graphics.Color.WHITE
            paint.textSize = 10 * density
            paint.isFakeBoldText = true
            paint.textAlign = Paint.Align.CENTER
            c.drawText(style.text, cx, cx - (paint.descent() + paint.ascent()) / 2, paint)
            b
        }
        is PinStyle.Ring -> {
            val (b, c) = bmp(style.sizeDp)
            val cx = b.width / 2f
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = style.widthDp * density
            paint.color = style.color.toArgb()
            c.drawCircle(cx, cx, style.sizeDp * density / 2 - paint.strokeWidth / 2, paint)
            b
        }
        is PinStyle.Symbol -> {
            val (b, c) = bmp(style.sizeDp)
            val cx = b.width / 2f
            val r = style.sizeDp * density / 2
            paint.color = android.graphics.Color.argb(100, 0, 0, 0)
            c.drawCircle(cx, cx + density, r, paint)
            paint.color = style.color.toArgb()
            c.drawCircle(cx, cx, r, paint)
            paint.color = android.graphics.Color.WHITE
            val u = r / 10f
            when (style.symbol) {
                PinSymbol.FLAG -> {
                    paint.strokeWidth = 1.4f * u
                    c.drawLine(cx - 2.5f * u, cx - 5.5f * u, cx - 2.5f * u, cx + 5.5f * u, paint)
                    val path = Path().apply {
                        moveTo(cx - 2.5f * u, cx - 5.5f * u)
                        lineTo(cx + 4.5f * u, cx - 3f * u)
                        lineTo(cx - 2.5f * u, cx - 0.5f * u)
                        close()
                    }
                    c.drawPath(path, paint)
                }
                PinSymbol.TEE -> {
                    // Ball auf dem Tee
                    c.drawCircle(cx, cx - 2.2f * u, 2.8f * u, paint)
                    val path = Path().apply {
                        moveTo(cx - 2.6f * u, cx + 0.8f * u)
                        lineTo(cx + 2.6f * u, cx + 0.8f * u)
                        lineTo(cx + 0.7f * u, cx + 2.2f * u)
                        lineTo(cx + 0.5f * u, cx + 6f * u)
                        lineTo(cx - 0.5f * u, cx + 6f * u)
                        lineTo(cx - 0.7f * u, cx + 2.2f * u)
                        close()
                    }
                    c.drawPath(path, paint)
                }
            }
            b
        }
    }
}

/**
 * Vollbildkarte wie das `fullScreenCover` auf iOS: „Schließen" links, Titel,
 * rechts Umschalter Karte/Luftbild, unten optional eine Legende.
 */
@Composable
internal fun FullscreenMapDialog(
    title: String,
    initialSatellite: Boolean,
    onClose: () -> Unit,
    bottom: (@Composable () -> Unit)? = null,
    map: @Composable (satellite: Boolean, modifier: Modifier) -> Unit,
) {
    var satellite by remember { mutableStateOf(initialSatellite) }
    Dialog(
        onDismissRequest = onClose,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        Column(Modifier.fillMaxSize().background(AppTheme.bg)) {
            Box(Modifier.fillMaxWidth().statusBarsPadding().height(52.dp)) {
                Text(
                    "Schließen", color = AppTheme.gold, fontSize = IosFont.body,
                    modifier = Modifier.align(Alignment.CenterStart)
                        .clickable { Haptics.tap(); onClose() }.padding(horizontal = 16.dp, vertical = 10.dp),
                )
                Text(
                    title, color = AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center, modifier = Modifier.align(Alignment.Center),
                )
                IconButton(
                    onClick = { Haptics.selection(); satellite = !satellite },
                    modifier = Modifier.align(Alignment.CenterEnd),
                ) {
                    Icon(if (satellite) Icons.Filled.Map else Icons.Filled.Public, contentDescription = "Kartenstil", tint = AppTheme.gold)
                }
            }
            Box(Modifier.fillMaxWidth().weight(1f)) {
                map(satellite, Modifier.fillMaxSize())
            }
            if (bottom != null) {
                Row(Modifier.fillMaxWidth().background(AppTheme.cardDark).navigationBarsPadding()) { bottom() }
            } else {
                Box(Modifier.navigationBarsPadding())
            }
        }
    }
}
