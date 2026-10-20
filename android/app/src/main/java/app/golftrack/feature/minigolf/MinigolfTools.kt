package app.golftrack.feature.minigolf

import android.content.Context
import android.graphics.DashPathEffect
import android.graphics.drawable.GradientDrawable
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.MotionEvent
import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.NearMe
import androidx.compose.material.icons.filled.NorthEast
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.navigation.NavController
import app.golftrack.data.LatLon
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LocationService
import app.golftrack.ui.common.rememberLocation
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.delay
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.OnlineTileSourceBase
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.util.MapTileIndex
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import org.osmdroid.views.overlay.Polyline
import java.util.Locale
import java.util.UUID
import kotlin.math.asin
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

private val IosBlue = Color(0xFF0A84FF)
private val IosOrange = Color(0xFFFF9F0A)

/** Distanzmessung per GPS – wie `DistanceTracker` in MinigolfView.swift. */
@Stable
internal class DistanceTracker {
    var startLocation by mutableStateOf<LatLon?>(null)
    var currentLocation by mutableStateOf<LatLon?>(null)
    var currentDistance by mutableStateOf<Double?>(null)
    var isTracking by mutableStateOf(false)
    var currentHeading by mutableStateOf<Double?>(null)
    var lockedHeading by mutableStateOf<Double?>(null)
    val savedDistances = mutableStateListOf<SavedShotDistance>()

    data class SavedShotDistance(val id: String = UUID.randomUUID().toString(), val distance: Double)

    fun start() {
        val initial = LocationService.lastLatLon
        startLocation = initial
        currentLocation = initial
        currentDistance = if (initial != null) 0.0 else null
        isTracking = true
    }

    /** Läuft jede Sekunde, solange gemessen wird. */
    fun tick() {
        val loc = LocationService.lastLatLon
        if (startLocation == null) startLocation = loc
        currentLocation = loc
        val s = startLocation
        if (s != null && loc != null) currentDistance = loc.distanceTo(s)
    }

    fun setNewStart() {
        startLocation = LocationService.lastLatLon
        currentDistance = 0.0
        lockedHeading = null
    }

    fun stop() {
        isTracking = false
        startLocation = null
        currentLocation = null
        currentDistance = null
        currentHeading = null
        lockedHeading = null
    }

    fun lockHeading() { lockedHeading = currentHeading }
    fun clearLockedHeading() { lockedHeading = null }

    fun saveDistance() {
        val d = currentDistance ?: return
        if (d > 0.5) savedDistances.add(SavedShotDistance(distance = d))
    }

    companion object {
        fun formatDistance(m: Double): String = when {
            m >= 1000 -> String.format(Locale.GERMANY, "%.2f km", m / 1000)
            m >= 100 -> String.format(Locale.GERMANY, "%.0f m", m)
            else -> String.format(Locale.GERMANY, "%.1f m", m)
        }

        /** Punkt in `distanceMeters` Entfernung von `coord` in Richtung `bearing` (Grad). */
        fun destination(coord: LatLon, bearing: Double, distanceMeters: Double): LatLon {
            val r = 6_371_000.0
            val d = distanceMeters / r
            val t = Math.toRadians(bearing)
            val p1 = Math.toRadians(coord.lat)
            val l1 = Math.toRadians(coord.lon)
            val p2 = asin(sin(p1) * cos(d) + cos(p1) * sin(d) * cos(t))
            val l2 = l1 + atan2(sin(t) * sin(d) * cos(p1), cos(d) - sin(p1) * sin(p2))
            return LatLon(Math.toDegrees(p2), Math.toDegrees(l2))
        }

        fun compassPoint(deg: Double): String {
            val d = ((deg % 360) + 360) % 360
            return when {
                d < 22.5 || d >= 337.5 -> "N"
                d < 67.5 -> "NO"
                d < 112.5 -> "O"
                d < 157.5 -> "SO"
                d < 202.5 -> "S"
                d < 247.5 -> "SW"
                d < 292.5 -> "W"
                else -> "NW"
            }
        }
    }
}

/** „Distanz & Karte" – wie `MinigolfToolsView`. */
@Composable
internal fun MinigolfToolsScreen(nav: NavController) {
    val tracker = remember { DistanceTracker() }
    rememberLocation(highAccuracy = true)
    val ctx = LocalContext.current

    LaunchedEffect(tracker.isTracking) {
        while (tracker.isTracking) {
            tracker.tick()
            delay(1000)
        }
    }
    // Kompass nur während der Messung
    DisposableEffect(tracker.isTracking) {
        val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        val listener = object : SensorEventListener {
            private val rot = FloatArray(9)
            private val orient = FloatArray(3)
            override fun onSensorChanged(e: SensorEvent) {
                SensorManager.getRotationMatrixFromVector(rot, e.values)
                SensorManager.getOrientation(rot, orient)
                val deg = (Math.toDegrees(orient[0].toDouble()) + 360) % 360
                val cur = tracker.currentHeading
                // headingFilter = 2° wie auf iOS
                if (cur == null || kotlin.math.abs(((deg - cur + 540) % 360) - 180) >= 2) tracker.currentHeading = deg
            }
            override fun onAccuracyChanged(s: Sensor?, a: Int) {}
        }
        if (tracker.isTracking && sensor != null) sm.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_UI)
        onDispose { sm.unregisterListener(listener) }
    }

    AppScaffold("Distanz & Karte", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            DistanceTrackerCard(tracker)
            DistanceMapCard(tracker)
        }
    }
}

@Composable
private fun DistanceTrackerCard(tracker: DistanceTracker) {
    Column(Modifier.mgCard().animateContentSize(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MgLabel("Distanz messen", Icons.Filled.MyLocation, iconTint = IosBlue)
            Spacer(Modifier.weight(1f))
            if (tracker.isTracking) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Box(Modifier.size(7.dp).background(AppTheme.gold, CircleShape))
                    MgText("Live", MgFont.caption2, AppTheme.gold, FontWeight.Bold)
                }
            }
        }
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
            val d = tracker.currentDistance
            when {
                d != null -> MgText(DistanceTracker.formatDistance(d), 52.sp, weight = FontWeight.Bold)
                tracker.isTracking -> MgText("Warte auf GPS…", MgFont.subheadline, AppTheme.textSec)
                else -> MgText("— m", 52.sp, AppTheme.textSec, FontWeight.Bold)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            if (tracker.isTracking) {
                MgPillButton("Neu setzen", Icons.Filled.Refresh, IosBlue.copy(alpha = 0.12f), IosBlue, Modifier.weight(1f),
                    haptic = { Haptics.medium() }) { tracker.setNewStart() }
                MgPillButton("Stop", Icons.Filled.Stop, AppTheme.cardAlt, AppTheme.textSec, Modifier.weight(1f)) { tracker.stop() }
            } else {
                MgPillButton("Startpunkt setzen", Icons.Filled.NearMe, IosBlue, Color.White, Modifier.weight(1f),
                    haptic = { Haptics.medium() }) { tracker.start() }
            }
        }
        if (tracker.isTracking && (tracker.currentDistance ?: 0.0) > 0.5) {
            MgPillButton("Distanz speichern", Icons.Filled.Bookmark, AppTheme.gold.copy(alpha = 0.13f), AppTheme.gold,
                Modifier.fillMaxWidth(), haptic = { Haptics.success() }) { tracker.saveDistance() }
        }
        if (tracker.savedDistances.isNotEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    MgText("Gespeicherte Distanzen", MgFont.subheadline, weight = FontWeight.Bold)
                    CountBadge(tracker.savedDistances.size, 22.dp, MgFont.caption)
                    Spacer(Modifier.weight(1f))
                    MgText("Alle löschen", MgFont.caption, MgRed, FontWeight.Bold,
                        Modifier.clickable { Haptics.warning(); tracker.savedDistances.clear() }.padding(4.dp))
                }
                tracker.savedDistances.forEachIndexed { i, shot ->
                    Row(
                        Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(10.dp))
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        MgText("Schlag ${i + 1}", MgFont.subheadline, AppTheme.textSec, modifier = Modifier.weight(1f))
                        MgText(DistanceTracker.formatDistance(shot.distance), MgFont.subheadline, AppTheme.gold, FontWeight.Bold)
                        // Statt Wischen zum Löschen: kleines x
                        Spacer(Modifier.width(10.dp))
                        Icon(Icons.Filled.Close, "Löschen", tint = AppTheme.textTer, modifier = Modifier.size(16.dp).clickable {
                            Haptics.warning()
                            tracker.savedDistances.removeAll { it.id == shot.id }
                        })
                    }
                }
            }
        }
    }
}

/** Luftbild wie auf der Website (Esri World Imagery, Kachelreihenfolge z/y/x). */
private val esriImagery = object : OnlineTileSourceBase(
    "EsriWorldImagery", 0, 19, 256, ".jpg",
    arrayOf("https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/"),
    "Esri, Maxar, Earthstar Geographics",
) {
    override fun getTileURLString(index: Long): String =
        baseUrl + MapTileIndex.getZoom(index) + "/" + MapTileIndex.getY(index) + "/" + MapTileIndex.getX(index)
}

private fun dot(fill: Color, sizePx: Int, stroke: Color? = null, strokePx: Int = 0) = GradientDrawable().apply {
    shape = GradientDrawable.OVAL
    setColor(fill.toArgb())
    if (stroke != null) setStroke(strokePx, stroke.toArgb())
    setSize(sizePx, sizePx)
}

@Composable
private fun DistanceMapCard(tracker: DistanceTracker) {
    val ctx = LocalContext.current
    var isSatellite by remember { mutableStateOf(false) }
    var centered by remember { mutableStateOf(false) }
    val here = rememberLocation(highAccuracy = true, askPermission = false)

    Column(Modifier.mgCard(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            MgLabel("Karte", Icons.Filled.Map)
            Spacer(Modifier.weight(1f))
            val d = tracker.currentDistance
            if (tracker.isTracking && d != null) MgText(DistanceTracker.formatDistance(d), MgFont.caption, IosBlue, FontWeight.Bold)
        }

        // Kompasszeile während der Messung
        if (tracker.isTracking) {
            val locked = tracker.lockedHeading
            Row(
                Modifier.fillMaxWidth()
                    .background(if (locked != null) IosOrange.copy(alpha = 0.08f) else IosBlue.copy(alpha = 0.06f), RoundedCornerShape(10.dp))
                    .padding(horizontal = 10.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                MgText("🧭", MgFont.body)
                Spacer(Modifier.width(4.dp))
                val h = tracker.currentHeading
                if (h != null) {
                    MgText(String.format(Locale.GERMANY, "%.0f°", h) + " " + DistanceTracker.compassPoint(h),
                        MgFont.subheadline, if (locked != null) IosOrange else IosBlue, FontWeight.Bold)
                } else MgText("—", MgFont.subheadline, AppTheme.textSec)
                Spacer(Modifier.weight(1f))
                if (locked == null) {
                    MgPillButton("Richtungslinie setzen", Icons.Filled.NorthEast, IosOrange, Color.White, radius = 50.dp,
                        vertical = 6.dp, size = MgFont.caption, haptic = { Haptics.success() }) { tracker.lockHeading() }
                } else {
                    MgText(String.format(Locale.GERMANY, "%.0f°", locked) + " " + DistanceTracker.compassPoint(locked),
                        MgFont.caption, IosOrange, FontWeight.Bold)
                    Spacer(Modifier.width(6.dp))
                    MgPillButton("Linie entfernen", Icons.Filled.Close, AppTheme.textSec.copy(alpha = 0.15f), AppTheme.textSec,
                        radius = 50.dp, vertical = 6.dp, size = MgFont.caption) { tracker.clearLockedHeading() }
                }
            }
        }

        Box(Modifier.fillMaxWidth().height(210.dp).clip(RoundedCornerShape(12.dp))) {
            AndroidView(
                factory = { c ->
                    Configuration.getInstance().apply {
                        load(c, c.getSharedPreferences("osmdroid", Context.MODE_PRIVATE))
                        userAgentValue = "app.golftrack"
                    }
                    MapView(c).apply {
                        setMultiTouchControls(true)
                        zoomController.setVisibility(org.osmdroid.views.CustomZoomButtonsController.Visibility.NEVER)
                        controller.setZoom(18.0)
                        // Karte in der ScrollView bedienbar halten
                        setOnTouchListener { v, e ->
                            if (e.action == MotionEvent.ACTION_DOWN) v.parent.requestDisallowInterceptTouchEvent(true)
                            false
                        }
                    }
                },
                update = { map ->
                    map.setTileSource(if (isSatellite) esriImagery else TileSourceFactory.MAPNIK)
                    map.overlays.clear()
                    val density = ctx.resources.displayMetrics.density
                    val start = tracker.startLocation
                    val current = tracker.currentLocation ?: here
                    if (start != null && current != null && tracker.isTracking) {
                        map.overlays.add(Polyline(map).apply {
                            setPoints(listOf(GeoPoint(start.lat, start.lon), GeoPoint(current.lat, current.lon)))
                            outlinePaint.color = IosBlue.copy(alpha = 0.7f).toArgb()
                            outlinePaint.strokeWidth = 3 * density
                            outlinePaint.pathEffect = DashPathEffect(floatArrayOf(6 * density, 4 * density), 0f)
                        })
                    }
                    val heading = tracker.lockedHeading
                    if (start != null && heading != null && tracker.isTracking) {
                        val end = DistanceTracker.destination(start, heading, 250.0)
                        map.overlays.add(Polyline(map).apply {
                            setPoints(listOf(GeoPoint(start.lat, start.lon), GeoPoint(end.lat, end.lon)))
                            outlinePaint.color = IosOrange.toArgb()
                            outlinePaint.strokeWidth = 3 * density
                            outlinePaint.pathEffect = DashPathEffect(floatArrayOf(8 * density, 5 * density), 0f)
                        })
                        map.overlays.add(Marker(map).apply {
                            position = GeoPoint(end.lat, end.lon)
                            icon = dot(IosOrange, (18 * density).toInt(), Color.White, (2 * density).toInt())
                            setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_CENTER)
                            setInfoWindow(null)
                        })
                    }
                    if (start != null) {
                        map.overlays.add(Marker(map).apply {
                            position = GeoPoint(start.lat, start.lon)
                            icon = dot(IosBlue, (12 * density).toInt(), Color.White, (2 * density).toInt())
                            setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_CENTER)
                            setInfoWindow(null)
                        })
                    }
                    if (current != null) {
                        map.overlays.add(Marker(map).apply {
                            position = GeoPoint(current.lat, current.lon)
                            icon = dot(IosBlue.copy(alpha = 0.9f), (16 * density).toInt(), Color.White, (3 * density).toInt())
                            setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_CENTER)
                            setInfoWindow(null)
                        })
                        if (!centered) {
                            centered = true
                            map.controller.setCenter(GeoPoint(current.lat, current.lon))
                        }
                    }
                    map.invalidate()
                },
                onRelease = { it.onDetach() },
                modifier = Modifier.fillMaxWidth().height(210.dp),
            )
            // Karte / Luftbild
            Box(
                Modifier.align(Alignment.TopStart).padding(10.dp)
                    .background(AppTheme.cardDark.copy(alpha = 0.85f), RoundedCornerShape(50))
                    .clickable { Haptics.selection(); isSatellite = !isSatellite }
                    .padding(8.dp),
            ) {
                Icon(if (isSatellite) Icons.Filled.Map else Icons.Filled.Public, "Kartenstil", tint = AppTheme.text, modifier = Modifier.size(18.dp))
            }
            if (!tracker.isTracking) {
                MgPillButton("Start", Icons.Filled.NearMe, IosBlue, Color.White,
                    Modifier.align(Alignment.BottomEnd).padding(10.dp), radius = 50.dp, vertical = 6.dp, size = MgFont.caption,
                    haptic = { Haptics.medium() }) { tracker.start() }
            }
        }
    }
}
