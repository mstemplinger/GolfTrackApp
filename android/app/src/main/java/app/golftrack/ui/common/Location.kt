package app.golftrack.ui.common

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Looper
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import app.golftrack.data.LatLon
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Standort ohne Google-Play-Dienste (die APK läuft auch auf Geräten ohne Play
 * Store). Nutzt GPS + Netzwerk über den `LocationManager`.
 *
 * In Compose: `val here = rememberLocation(highAccuracy = true)` – fragt beim
 * ersten Aufruf nach der Berechtigung und liefert laufend die letzte Position
 * (oder null). Beim Verlassen des Screens werden die Updates beendet.
 */
object LocationService {
    private val _location = MutableStateFlow<Location?>(null)
    val location: StateFlow<Location?> = _location.asStateFlow()

    val lastLatLon: LatLon? get() = _location.value?.let { LatLon(it.latitude, it.longitude) }

    private var users = 0
    private var listener: LocationListener? = null

    fun hasPermission(ctx: Context): Boolean =
        ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

    @SuppressLint("MissingPermission")
    fun start(ctx: Context, highAccuracy: Boolean) {
        users++
        if (!hasPermission(ctx) || listener != null) return
        val lm = ctx.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = lm.getProviders(true)
        providers.mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }
            .maxByOrNull { it.time }?.let { if (_location.value == null) _location.value = it }
        val l = LocationListener { loc ->
            val cur = _location.value
            // Ungenaue Netzwerkposition nicht über eine frische GPS-Position legen.
            if (cur == null || loc.time - cur.time > 10_000 || loc.accuracy <= cur.accuracy) _location.value = loc
        }
        listener = l
        val interval = if (highAccuracy) 1_000L else 10_000L
        val minDist = if (highAccuracy) 1f else 25f
        for (p in listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)) {
            if (p in providers) runCatching { lm.requestLocationUpdates(p, interval, minDist, l, Looper.getMainLooper()) }
        }
    }

    fun stop(ctx: Context) {
        users = maxOf(0, users - 1)
        if (users > 0) return
        listener?.let { (ctx.getSystemService(Context.LOCATION_SERVICE) as LocationManager).removeUpdates(it) }
        listener = null
    }
}

@Composable
fun rememberLocation(highAccuracy: Boolean = false, askPermission: Boolean = true): LatLon? {
    val ctx = LocalContext.current
    val loc by LocationService.location.collectAsState()
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { res ->
        if (res.values.any { it }) {
            LocationService.stop(ctx)
            LocationService.start(ctx, highAccuracy)
        }
    }
    LaunchedEffect(Unit) {
        if (askPermission && !LocationService.hasPermission(ctx)) {
            launcher.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION))
        }
    }
    DisposableEffect(highAccuracy) {
        LocationService.start(ctx, highAccuracy)
        onDispose { LocationService.stop(ctx) }
    }
    return loc?.let { LatLon(it.latitude, it.longitude) }
}
