package app.golftrack.feature.golf

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Looper
import android.os.SystemClock
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.platform.LocalContext
import app.golftrack.data.GolfStore
import app.golftrack.data.Prefs
import app.golftrack.data.RoundTrack
import app.golftrack.data.TrackPoint
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LocationService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Zeichnet während einer Runde die Laufspur auf – wie RoundTrackingService.swift.
 *
 * Nur mit doppelter Zustimmung: Schalter "tracking.roundPath.enabled" in den
 * Einstellungen *und* Standort-Berechtigung. Android-Abweichung: Die
 * Aufzeichnung läuft, solange die Zählkarte offen ist (kein Foreground-Service –
 * der bräuchte Einträge im gemeinsamen Manifest). Der Puffer wird beim Wechsel
 * in den Hintergrund weggeschrieben.
 */
object RoundTracker {
    const val ENABLED_KEY = "tracking.roundPath.enabled"

    val isEnabledByUser: Boolean get() = Prefs.bool(ENABLED_KEY, false)

    private val _isTracking = MutableStateFlow(false)
    val isTracking: StateFlow<Boolean> = _isTracking.asStateFlow()
    private val _pointCount = MutableStateFlow(0)
    val pointCount: StateFlow<Int> = _pointCount.asStateFlow()

    /** Punkte schlechter als 20 m sind für Abschlag/Grün wertlos. */
    private const val MAX_ACCURACY = 20.0
    private const val MIN_DISTANCE = 4.0
    /** Auch Stillstand (Putten!) soll Punkte erzeugen. */
    private const val MIN_INTERVAL_S = 10.0
    private const val FLUSH_THRESHOLD = 20

    private var roundId: String? = null
    private var currentHole = 0
    private var startedAt = 0L
    private val buffer = mutableListOf<TrackPoint>()
    private var lastKept: Location? = null
    private var listener: LocationListener? = null
    private var manager: LocationManager? = null

    @SuppressLint("MissingPermission")
    fun start(ctx: Context, roundId: String, hole: Int) {
        if (!isEnabledByUser || _isTracking.value) return
        if (!LocationService.hasPermission(ctx)) return
        val round = GolfStore.current.round(roundId) ?: return
        this.roundId = roundId
        currentHole = hole

        // Bestehenden Track fortsetzen (Runde unterbrochen und wieder geöffnet).
        val track = round.track?.copy(endedAt = null) ?: RoundTrack(startedAt = System.currentTimeMillis())
        startedAt = track.startedAt
        GolfStore.updateRound(roundId) { it.copy(track = track) }
        _pointCount.value = track.points.size
        buffer.clear()
        lastKept = null

        val lm = ctx.applicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        manager = lm
        val l = LocationListener { loc -> onLocation(loc) }
        listener = l
        val providers = lm.getProviders(true)
        if (LocationManager.GPS_PROVIDER in providers) {
            runCatching { lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1_000L, MIN_DISTANCE.toFloat(), l, Looper.getMainLooper()) }
        }
        _isTracking.value = true
    }

    fun setCurrentHole(hole: Int) {
        if (hole == currentHole) return
        flush()
        currentHole = hole
    }

    fun stop() {
        if (!_isTracking.value) return
        flush()
        roundId?.let { id -> GolfStore.updateRound(id) { r -> r.copy(track = r.track?.copy(endedAt = System.currentTimeMillis())) } }
        listener?.let { manager?.removeUpdates(it) }
        listener = null
        manager = null
        roundId = null
        _isTracking.value = false
    }

    fun flush() {
        val id = roundId ?: return
        if (buffer.isEmpty()) return
        val pts = buffer.toList()
        buffer.clear()
        GolfStore.updateRound(id) { r ->
            val t = r.track ?: RoundTrack(startedAt = startedAt)
            r.copy(track = t.copy(points = t.points + pts))
        }
        _pointCount.value = GolfStore.current.round(id)?.track?.points?.size ?: _pointCount.value
    }

    private fun shouldKeep(loc: Location): Boolean {
        if (!loc.hasAccuracy() || loc.accuracy <= 0 || loc.accuracy > MAX_ACCURACY) return false
        // Veraltete Fixes (Cache-Wert beim Start) ignorieren.
        val ageMs = (SystemClock.elapsedRealtimeNanos() - loc.elapsedRealtimeNanos) / 1_000_000
        if (abs(ageMs) > 30_000) return false
        val last = lastKept ?: return true
        val moved = loc.distanceTo(last) >= MIN_DISTANCE
        val waited = (loc.time - last.time) / 1000.0 >= MIN_INTERVAL_S
        return moved || waited
    }

    private fun onLocation(loc: Location) {
        if (!shouldKeep(loc)) return
        buffer += TrackPoint(
            latitude = loc.latitude,
            longitude = loc.longitude,
            timeOffset = (loc.time - startedAt) / 1000.0,
            accuracy = loc.accuracy.toDouble(),
            holeNumber = currentHole,
        )
        lastKept = loc
        if (buffer.size >= FLUSH_THRESHOLD) flush()
        else _pointCount.value = (GolfStore.current.round(roundId)?.track?.points?.size ?: 0) + buffer.size
    }
}

// --- Plausibilität der Laufspur (wie RoundTrack.swift) ---

/** Aufgezeichnete Dauer in Sekunden. */
val RoundTrack.durationSeconds: Double
    get() = ((endedAt ?: System.currentTimeMillis()) - startedAt) / 1000.0

val TrackPoint.isValid: Boolean get() = coordinate.isValid

val RoundTrack.totalDistanceMeters: Double
    get() {
        val pts = points.filter { it.isValid }
        if (pts.size < 2) return 0.0
        return (1 until pts.size).sumOf { pts[it].coordinate.distanceTo(pts[it - 1].coordinate) }
    }

/** Weniger als 3 Minuten je Loch sind beim Golf nicht spielbar → eher nachgetragen. */
fun RoundTrack.looksBackfilled(playedHoles: Int): Boolean {
    if (points.isEmpty() || playedHoles <= 0 || durationSeconds <= 0) return false
    return durationSeconds / 60 / playedHoles < 3.0
}

/** Schütteln erkennen – wie ShakeDetector auf iOS (Beschleunigungssensor statt motionEnded). */
@Composable
fun ShakeEffect(onShake: () -> Unit) {
    val ctx = LocalContext.current
    val cb by rememberUpdatedState(onShake)
    DisposableEffect(Unit) {
        val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val acc = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        var lastShake = 0L
        var peaks = 0
        var firstPeak = 0L
        val l = object : SensorEventListener {
            override fun onSensorChanged(e: SensorEvent) {
                val (x, y, z) = Triple(e.values[0], e.values[1], e.values[2])
                val g = sqrt(x * x + y * y + z * z) / SensorManager.GRAVITY_EARTH
                if (g < 2.5f) return
                val now = SystemClock.elapsedRealtime()
                if (now - firstPeak > 800) { firstPeak = now; peaks = 0 }
                peaks++
                if (peaks >= 3 && now - lastShake > 1500) {
                    lastShake = now
                    peaks = 0
                    Haptics.medium()
                    cb()
                }
            }
            override fun onAccuracyChanged(s: Sensor?, a: Int) {}
        }
        if (acc != null) sm.registerListener(l, acc, SensorManager.SENSOR_DELAY_UI)
        onDispose { sm.unregisterListener(l) }
    }
}
