package app.golftrack.feature.golf

import android.content.Context
import android.graphics.Bitmap
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.drawable.BitmapDrawable
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.drawscope.CanvasDrawScope
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.vector.rememberVectorPainter
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import app.golftrack.data.LatLon
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import org.osmdroid.config.Configuration
import org.osmdroid.events.MapEventsReceiver
import org.osmdroid.tileprovider.tilesource.ITileSource
import org.osmdroid.tileprovider.tilesource.OnlineTileSourceBase
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.BoundingBox
import org.osmdroid.util.GeoPoint
import org.osmdroid.util.MapTileIndex
import org.osmdroid.views.CustomZoomButtonsController
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.MapEventsOverlay
import org.osmdroid.views.overlay.Marker
import org.osmdroid.views.overlay.Polygon
import org.osmdroid.views.overlay.Polyline
import java.io.File

/*
 * Karten des Golf-Bereichs auf osmdroid-Basis. Satellit = Esri World Imagery
 * (wie `.hybrid` auf iOS), Standard = OpenStreetMap. Die Inhalte werden
 * deklarativ als Liste von `MapItem`s übergeben und bei jeder Änderung neu
 * gezeichnet – die Datenmengen (ein Loch, eine Runde) sind klein.
 */

object EsriWorldImagery : OnlineTileSourceBase(
    "EsriWorldImagery", 1, 19, 256, ".jpg",
    arrayOf("https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/"),
    "Esri, Maxar, Earthstar Geographics",
) {
    override fun getTileURLString(pMapTileIndex: Long): String =
        baseUrl + MapTileIndex.getZoom(pMapTileIndex) + "/" + MapTileIndex.getY(pMapTileIndex) + "/" + MapTileIndex.getX(pMapTileIndex)
}

private var osmConfigured = false

private fun configureOsm(ctx: Context) {
    if (osmConfigured) return
    osmConfigured = true
    val cfg = Configuration.getInstance()
    cfg.userAgentValue = "app.golftrack"
    val base = File(ctx.cacheDir, "osmdroid")
    cfg.osmdroidBasePath = base
    cfg.osmdroidTileCache = File(base, "tiles")
}

enum class MapIcon { FLAG, GOLFER, PIN, TARGET }

/** Was auf der Karte liegt. */
sealed interface MapItem {
    data class Line(val points: List<LatLon>, val color: Color, val width: Float = 3f, val dashed: Boolean = false) : MapItem
    data class Area(val points: List<LatLon>, val fill: Color, val stroke: Color, val width: Float = 2f) : MapItem
    data class Dot(
        val at: LatLon,
        val bg: Color,
        val sizeDp: Int = 26,
        val text: String? = null,
        val icon: MapIcon? = null,
        val fg: Color = Color.White,
        val border: Color? = null,
        /** Unteres Ende statt Mitte an der Koordinate (Stecknadel). */
        val bottomAnchor: Boolean = false,
        val draggable: Boolean = false,
        val onDragEnd: ((LatLon) -> Unit)? = null,
    ) : MapItem
}

/** Steuert die Kamera von außen (z. B. „Meinen Standort verwenden"). */
class GolfMapState {
    internal var view: MapView? = null
    internal var didInitialFit = false
    internal var lastItems: List<MapItem>? = null
    internal var userMarker: Marker? = null

    fun center(p: LatLon, zoom: Double = 18.0, animate: Boolean = true) {
        val v = view ?: return
        if (animate) v.controller.animateTo(GeoPoint(p.lat, p.lon), zoom, 600L)
        else { v.controller.setZoom(zoom); v.controller.setCenter(GeoPoint(p.lat, p.lon)) }
    }

    fun fit(points: List<LatLon>, animate: Boolean = false) {
        val v = view ?: return
        val pts = points.filter { it.isValid }
        if (pts.isEmpty()) return
        if (pts.size == 1) { center(pts[0], 18.0, animate); return }
        val box = BoundingBox.fromGeoPoints(pts.map { GeoPoint(it.lat, it.lon) })
        val padded = if (box.latitudeSpan < 0.0008 && box.longitudeSpanWithDateLine < 0.0008) box.increaseByScale(4f) else box
        v.post { runCatching { v.zoomToBoundingBox(padded, animate, (48 * v.resources.displayMetrics.density).toInt()) } }
    }
}

@Composable
fun rememberGolfMapState(): GolfMapState = remember { GolfMapState() }

@Composable
fun GolfMap(
    items: List<MapItem>,
    modifier: Modifier = Modifier,
    state: GolfMapState = rememberGolfMapState(),
    satellite: Boolean = true,
    interactive: Boolean = true,
    userLocation: LatLon? = null,
    showLocationButton: Boolean = interactive,
    /** Punkte für den ersten Bildausschnitt; leer = Standort bzw. Mitteleuropa. */
    initialFit: List<LatLon> = emptyList(),
    onTap: ((LatLon) -> Unit)? = null,
) {
    val ctx = LocalContext.current
    val density = LocalDensity.current
    val tapState by rememberUpdatedState(onTap)

    val painters = mapOf(
        MapIcon.FLAG to rememberVectorPainter(Icons.Filled.Flag),
        MapIcon.GOLFER to rememberVectorPainter(Icons.Filled.SportsGolf),
        MapIcon.PIN to rememberVectorPainter(Icons.Filled.Place),
        MapIcon.TARGET to rememberVectorPainter(Icons.Filled.GpsFixed),
    )
    val iconCache = remember { HashMap<MapItem.Dot, Bitmap>() }

    val mapView = remember {
        configureOsm(ctx)
        MapView(ctx).apply {
            setMultiTouchControls(interactive)
            zoomController.setVisibility(CustomZoomButtonsController.Visibility.NEVER)
            isTilesScaledToDpi = true
            setTileSource(if (satellite) EsriWorldImagery else TileSourceFactory.MAPNIK)
            minZoomLevel = 3.0
            maxZoomLevel = 20.0
            controller.setZoom(5.5)
            controller.setCenter(GeoPoint(50.5, 10.5))
            if (!interactive) setOnTouchListener { _, _ -> true }
            // MapView zeichnet sonst über seine Grenzen hinaus (z. B. über die Kopfzeile).
            outlineProvider = android.view.ViewOutlineProvider.BOUNDS
            clipToOutline = true
        }
    }
    state.view = mapView

    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle) {
        val obs = LifecycleEventObserver { _, e ->
            when (e) {
                Lifecycle.Event.ON_RESUME -> mapView.onResume()
                Lifecycle.Event.ON_PAUSE -> mapView.onPause()
                else -> {}
            }
        }
        lifecycle.addObserver(obs)
        mapView.onResume()
        onDispose {
            lifecycle.removeObserver(obs)
            mapView.onPause()
            mapView.onDetach()
            if (state.view === mapView) {
                state.view = null
                state.lastItems = null
                state.userMarker = null
                state.didInitialFit = false
            }
        }
    }

    Box(modifier.clipToBounds()) {
        AndroidView(
            factory = { mapView },
            modifier = Modifier.matchParentSize(),
            update = { mv ->
                val src: ITileSource = if (satellite) EsriWorldImagery else TileSourceFactory.MAPNIK
                if (mv.tileProvider.tileSource.name() != src.name()) mv.setTileSource(src)
                // Nur neu aufbauen, wenn sich der Inhalt geändert hat – sonst bricht z. B.
                // das Ziehen des Pins ab, sobald der Standort (1×/s) aktualisiert wird.
                val key = items.map { if (it is MapItem.Dot) it.copy(onDragEnd = null) else it }
                if (key != state.lastItems) {
                    state.lastItems = key
                    mv.overlays.clear()
                    mv.overlays.add(MapEventsOverlay(object : MapEventsReceiver {
                        override fun singleTapConfirmedHelper(p: GeoPoint): Boolean {
                            val cb = tapState ?: return false
                            cb(LatLon(p.latitude, p.longitude)); return true
                        }
                        override fun longPressHelper(p: GeoPoint): Boolean = false
                    }))
                    for (item in items) addOverlay(mv, item, density, painters, iconCache)
                    state.userMarker = null
                }
                // Eigener Standort als blauer Punkt, oben auf allem anderen.
                val u = userLocation?.takeIf { it.isValid }
                val um = state.userMarker
                if (u == null) {
                    if (um != null) { mv.overlays.remove(um); state.userMarker = null }
                } else if (um == null) {
                    val dot = MapItem.Dot(u, IosColors.blue, sizeDp = 18, border = Color.White)
                    val m = Marker(mv)
                    m.icon = BitmapDrawable(mv.resources, iconCache.getOrPut(dot.copy(at = LatLon(0.0, 0.0))) { renderDot(dot, density, painters) })
                    m.setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_CENTER)
                    m.infoWindow = null
                    m.setOnMarkerClickListener { _, _ -> true }
                    m.position = GeoPoint(u.lat, u.lon)
                    mv.overlays.add(m)
                    state.userMarker = m
                } else {
                    um.position = GeoPoint(u.lat, u.lon)
                }
                if (!state.didInitialFit) {
                    val fit = initialFit.filter { it.isValid }.ifEmpty { listOfNotNull(userLocation?.takeIf { it.isValid }) }
                    if (fit.isNotEmpty()) {
                        state.didInitialFit = true
                        if (fit.size == 1) state.center(fit[0], 17.5, animate = false) else state.fit(fit)
                    }
                }
                mv.invalidate()
            },
        )
        if (showLocationButton && userLocation != null) {
            Box(
                Modifier.align(Alignment.TopEnd).padding(10.dp).size(40.dp)
                    .background(Color.Black.copy(alpha = 0.55f), CircleShape)
                    .border(1.dp, Color.White.copy(alpha = 0.2f), CircleShape)
                    .clickable { Haptics.tap(); state.center(userLocation, 18.0) },
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Filled.MyLocation, contentDescription = "Mein Standort", tint = Color.White, modifier = Modifier.size(20.dp)) }
        }
    }
}

private fun geo(p: LatLon) = GeoPoint(p.lat, p.lon)

private fun addOverlay(
    mv: MapView,
    item: MapItem,
    density: Density,
    painters: Map<MapIcon, Painter>,
    cache: HashMap<MapItem.Dot, Bitmap>,
) {
    when (item) {
        is MapItem.Line -> {
            val pts = item.points.filter { it.isValid }
            if (pts.size < 2) return
            val line = Polyline(mv)
            line.setPoints(pts.map(::geo))
            line.outlinePaint.apply {
                color = item.color.toArgb()
                strokeWidth = item.width * density.density
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
                isAntiAlias = true
                if (item.dashed) pathEffect = DashPathEffect(floatArrayOf(6 * density.density, 4 * density.density), 0f)
            }
            line.infoWindow = null
            mv.overlays.add(line)
        }
        is MapItem.Area -> {
            val pts = item.points.filter { it.isValid }
            if (pts.size < 3) return
            val poly = Polygon(mv)
            poly.setPoints(pts.map(::geo) + geo(pts.first()))
            poly.fillPaint.color = item.fill.toArgb()
            poly.outlinePaint.color = item.stroke.toArgb()
            poly.outlinePaint.strokeWidth = item.width * density.density
            poly.infoWindow = null
            mv.overlays.add(poly)
        }
        is MapItem.Dot -> {
            if (!item.at.isValid) return
            val key = item.copy(at = LatLon(0.0, 0.0), onDragEnd = null)
            val bmp = cache.getOrPut(key) { renderDot(item, density, painters) }
            val m = Marker(mv)
            m.position = geo(item.at)
            m.icon = BitmapDrawable(mv.resources, bmp)
            m.setAnchor(Marker.ANCHOR_CENTER, if (item.bottomAnchor) Marker.ANCHOR_BOTTOM else Marker.ANCHOR_CENTER)
            m.infoWindow = null
            m.setOnMarkerClickListener { _, _ -> true }
            if (item.draggable) {
                m.isDraggable = true
                m.setOnMarkerDragListener(object : Marker.OnMarkerDragListener {
                    override fun onMarkerDrag(marker: Marker) {}
                    override fun onMarkerDragStart(marker: Marker) { Haptics.light() }
                    override fun onMarkerDragEnd(marker: Marker) {
                        item.onDragEnd?.invoke(LatLon(marker.position.latitude, marker.position.longitude))
                    }
                })
            }
            mv.overlays.add(m)
        }
    }
}

/** Runder Marker mit Zahl oder Symbol; als Stecknadel mit Stiel und Fußpunkt. */
private fun renderDot(item: MapItem.Dot, density: Density, painters: Map<MapIcon, Painter>): Bitmap {
    val d = density.density
    val circle = item.sizeDp * d
    val stem = if (item.bottomAnchor) 16 * d else 0f
    val w = (circle + 4 * d).toInt()
    val h = (circle + 4 * d + stem).toInt()
    val img = ImageBitmap(w, h)
    val canvas = androidx.compose.ui.graphics.Canvas(img)
    val nc = canvas.nativeCanvas
    val cx = w / 2f
    val cy = 2 * d + circle / 2
    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    if (item.bottomAnchor) {
        paint.color = item.bg.toArgb()
        nc.drawRect(cx - 1 * d, cy, cx + 1 * d, h - 3 * d, paint)
        nc.drawCircle(cx, h - 3 * d, 3 * d, paint)
    }
    paint.color = android.graphics.Color.argb(90, 0, 0, 0)
    nc.drawCircle(cx, cy + 1.5f * d, circle / 2, paint)
    paint.color = item.bg.toArgb()
    nc.drawCircle(cx, cy, circle / 2, paint)
    item.border?.let {
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 2 * d
        paint.color = it.toArgb()
        nc.drawCircle(cx, cy, circle / 2 - d, paint)
        paint.style = Paint.Style.FILL
    }
    item.text?.let { t ->
        paint.color = item.fg.toArgb()
        paint.textAlign = Paint.Align.CENTER
        paint.isFakeBoldText = true
        paint.textSize = circle * if (t.length > 1) 0.42f else 0.5f
        val fm = paint.fontMetrics
        nc.drawText(t, cx, cy - (fm.ascent + fm.descent) / 2, paint)
    }
    item.icon?.let { ic ->
        val painter = painters[ic] ?: return@let
        val s = circle * 0.56f
        CanvasDrawScope().draw(density, LayoutDirection.Ltr, canvas, Size(w.toFloat(), h.toFloat())) {
            translate(cx - s / 2, cy - s / 2) {
                with(painter) { draw(Size(s, s), colorFilter = ColorFilter.tint(item.fg)) }
            }
        }
    }
    return img.asAndroidBitmap()
}

/** Satellit/Standard-Umschalter wie in ShotTrackerView. */
@Composable
fun SatelliteToggle(isSatellite: Boolean, modifier: Modifier = Modifier, onToggle: () -> Unit) {
    androidx.compose.foundation.layout.Row(
        modifier.background(Color.Black.copy(alpha = if (isSatellite) 0.65f else 0.5f), CircleShape)
            .border(1.dp, Color.White.copy(alpha = if (isSatellite) 0.35f else 0.2f), CircleShape)
            .clickable { Haptics.selection(); onToggle() }
            .padding(horizontal = 12.dp, vertical = 7.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            if (isSatellite) Icons.Filled.Place else Icons.Filled.GpsFixed, contentDescription = null,
            tint = Color.White, modifier = Modifier.size(14.dp),
        )
        androidx.compose.material3.Text(
            if (isSatellite) "Standard" else "Satellit", color = Color.White,
            fontSize = androidx.compose.ui.unit.TextUnit(12f, androidx.compose.ui.unit.TextUnitType.Sp),
            fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold,
            modifier = Modifier.padding(start = 6.dp),
        )
    }
}

/** Farbe als Hilfsfunktion für Gold-Transparenzen auf der Karte. */
fun goldA(alpha: Float) = AppTheme.gold.copy(alpha = alpha)
