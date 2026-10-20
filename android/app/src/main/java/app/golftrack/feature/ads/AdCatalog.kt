package app.golftrack.feature.ads

import android.content.Context
import app.golftrack.data.LatLon
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs
import kotlin.random.Random

/**
 * Anzeigen für die Werbefläche in den Zählkarten – wie `AdCatalogService` auf iOS.
 *
 * Einmal geladen, liegt die Liste im Cache und funktioniert auch ohne Netz.
 * Gezählt wird nur, wie oft eine Anzeige zu sehen war und wie oft jemand
 * darauf getippt hat – ohne Gerätekennung, ohne Standort.
 */
object AdCatalog {
    private const val FEED_URL = "https://golftrack.app/api/v1/ads"
    private const val EVENT_URL = "https://golftrack.app/api/v1/ads/event"

    /** Anzeigen wechseln häufiger als Plätze, deshalb kürzer als dort. */
    private const val REFRESH_INTERVAL_MS = 2L * 60 * 60 * 1000

    /** Wie weit der Rand eines anderen Umkreises entfernt sein darf, um noch als „gleich nah" zu gelten. */
    const val NEAREST_TOLERANCE = 5_000.0

    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true; explicitNulls = false }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val _ads = MutableStateFlow<List<RemoteAd>>(emptyList())
    val ads: StateFlow<List<RemoteAd>> = _ads.asStateFlow()

    private var lastUpdated: Long? = null
    private var cacheFile: File? = null
    private var loadedFromDisk = false
    private val mutex = Mutex()

    /** Verschiebt die Reihenfolge pro Start, damit nicht immer dieselbe Anzeige auf Bahn 1 landet. */
    private val rotationSeed = Random.nextInt(0, 1000)

    private val pendingImpressions = mutableMapOf<String, Int>()
    private val pendingClicks = mutableMapOf<String, Int>()
    private var flushJob: Job? = null

    fun init(context: Context) {
        if (cacheFile != null) return
        cacheFile = File(context.filesDir, "catalog/remote-ads.json").also { it.parentFile?.mkdirs() }
    }

    fun ad(id: String): RemoteAd? = _ads.value.firstOrNull { it.id == id }

    // --- Auswahl ---

    /**
     * Rangfolge: die auf diese Anlage gebuchte Anzeige, dann die Anzeigen, deren
     * Umkreis sie abdeckt, dann – liegt der Platz in keinem Umkreis – die des
     * nächstgelegenen Umkreises, zuletzt die allgemeinen. Innerhalb einer Stufe
     * entscheidet `weight`.
     */
    fun ad(placement: AdPlacement, courseId: String?, coordinate: LatLon? = null, rotation: Int = 0): RemoteAd? {
        val today = Date()
        val candidates = _ads.value.filter { it.placement == placement.raw && it.isRunning(today) }
        if (candidates.isEmpty()) return null
        val pool = pool(candidates, courseId, coordinate)
        if (pool.isEmpty()) return null
        // Gewichtung als Wiederholung im Los: Gewicht 3 liegt dreimal drin.
        val weighted = pool.flatMap { ad -> List(ad.weight.coerceIn(1, 100)) { ad } }
        val index = abs(rotation + rotationSeed) % weighted.size
        return weighted[index]
    }

    fun pool(candidates: List<RemoteAd>, courseId: String?, coordinate: LatLon?): List<RemoteAd> {
        if (courseId != null) {
            val local = candidates.filter { it.courseID == courseId }
            if (local.isNotEmpty()) return local
        }
        if (coordinate != null) {
            // Platzgebundene Anzeigen anderer Anlagen gehören nie hierher.
            val regional = candidates.mapNotNull { ad ->
                if (ad.courseID.isNotEmpty()) null else ad.distanceToArea(coordinate)?.let { ad to it }
            }
            val inside = regional.filter { it.second == 0.0 }.map { it.first }
            if (inside.isNotEmpty()) return inside
            // Außerhalb jedes Umkreises springt die nächstgelegene Region ein.
            regional.minOfOrNull { it.second }?.let { nearest ->
                return regional.filter { it.second <= nearest + NEAREST_TOLERANCE }.map { it.first }
            }
        }
        return candidates.filter { it.isEverywhere }
    }

    // --- Zählen ---

    @Synchronized
    fun countImpression(ad: RemoteAd) {
        pendingImpressions[ad.id] = (pendingImpressions[ad.id] ?: 0) + 1
        scheduleFlush()
    }

    @Synchronized
    fun countClick(ad: RemoteAd) {
        pendingClicks[ad.id] = (pendingClicks[ad.id] ?: 0) + 1
        scheduleFlush()
    }

    /** Gesammelt nach kurzer Pause verschicken statt bei jeder Einblendung. */
    private fun scheduleFlush() {
        flushJob?.cancel()
        flushJob = scope.launch {
            delay(30_000)
            flushCounters()
        }
    }

    /** Fehler sind hier belanglos – im Zweifel geht eine Runde Reichweite verloren. */
    suspend fun flushCounters() {
        val events = synchronized(this) {
            val e = pendingImpressions.map { AdEvent(it.key, "impression", it.value) } +
                pendingClicks.map { AdEvent(it.key, "click", it.value) }
            pendingImpressions.clear()
            pendingClicks.clear()
            e
        }
        if (events.isEmpty()) return
        withContext(Dispatchers.IO) {
            for (chunk in events.chunked(50)) {
                runCatching {
                    val c = URL(EVENT_URL).openConnection() as HttpURLConnection
                    try {
                        c.requestMethod = "POST"
                        c.connectTimeout = 10_000
                        c.readTimeout = 10_000
                        c.doOutput = true
                        c.setRequestProperty("Content-Type", "application/json")
                        c.outputStream.use { it.write(json.encodeToString(AdEventBatch.serializer(), AdEventBatch(chunk)).toByteArray()) }
                        c.responseCode
                    } finally {
                        c.disconnect()
                    }
                }
            }
        }
    }

    // --- Laden ---

    suspend fun refreshIfNeeded() {
        if (!loadedFromDisk) withContext(Dispatchers.IO) { loadCache() }
        val last = lastUpdated
        if (last != null && System.currentTimeMillis() - last <= REFRESH_INTERVAL_MS) return
        refresh()
    }

    suspend fun refresh() {
        if (mutex.isLocked) return
        mutex.withLock {
            withContext(Dispatchers.IO) {
                runCatching {
                    val c = URL(FEED_URL).openConnection() as HttpURLConnection
                    val text = try {
                        c.connectTimeout = 15_000
                        c.readTimeout = 15_000
                        c.setRequestProperty("Accept", "application/json")
                        if (c.responseCode !in 200..299) return@runCatching
                        c.inputStream.bufferedReader().use { it.readText() }
                    } finally {
                        c.disconnect()
                    }
                    val feed = json.decodeFromString(RemoteAdFeed.serializer(), text)
                    _ads.value = feed.ads
                    lastUpdated = System.currentTimeMillis()
                    cacheFile?.let { f ->
                        val tmp = File(f.parentFile, f.name + ".tmp")
                        tmp.writeText(text)
                        tmp.renameTo(f)
                    }
                }
                // Ohne Netz bleibt der Cache stehen – das ist kein Fehlerfall.
            }
        }
    }

    private fun loadCache() {
        loadedFromDisk = true
        val f = cacheFile ?: return
        if (!f.exists()) return
        runCatching { json.decodeFromString(RemoteAdFeed.serializer(), f.readText()) }
            .onSuccess { _ads.value = it.ads; lastUpdated = f.lastModified() }
    }
}

/** Wo eine Anzeige stehen kann – Kennungen wie im Adminpanel der Website. */
enum class AdPlacement(val raw: String) {
    MINIGOLF_SCORING("minigolf_scoring"),
    GOLF_SCORING("golf_scoring"),
}

@Serializable
data class RemoteAdFeed(val version: Int = 1, val generatedAt: String? = null, val ads: List<RemoteAd> = emptyList())

@Serializable
data class RemoteAd(
    val id: String,
    val placement: String = "",
    /** Kennung der Anlage – leer heißt „überall". */
    val courseID: String = "",
    val title: String = "",
    val subtitle: String = "",
    val imageURL: String = "",
    val linkURL: String = "",
    val advertiser: String = "",
    val weight: Int = 1,
    /** Tagesdaten im Format `JJJJ-MM-TT`, null heißt unbegrenzt. */
    val startsOn: String? = null,
    val endsOn: String? = null,
    val lat: Double? = null,
    val lon: Double? = null,
    val radiusKm: Int? = null,
) {
    /** Gilt überall: weder auf einen Platz gebucht noch auf einen Umkreis. */
    val isEverywhere: Boolean get() = courseID.isEmpty() && radiusKm == null

    /** Zwischenseite mit Link und Erklärung statt direkt zum Werbenden. */
    val landingURL: String get() = "https://golftrack.app/werbung/$id"

    /** Abstand vom Platz bis zum Rand des gebuchten Umkreises in Metern – 0 im Umkreis, null ohne Umkreis. */
    fun distanceToArea(from: LatLon): Double? {
        val la = lat ?: return null
        val lo = lon ?: return null
        val r = radiusKm ?: return null
        if (r <= 0) return null
        return maxOf(0.0, LatLon(la, lo).distanceTo(from) - r * 1000.0)
    }

    /** Der Cache kann Tage alt sein, deshalb prüft das Gerät den Zeitraum selbst. */
    fun isRunning(on: Date): Boolean {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(on)
        if (startsOn != null && today < startsOn) return false
        if (endsOn != null && today > endsOn) return false
        return true
    }
}

@Serializable
private data class AdEvent(val id: String, val type: String, val count: Int)

@Serializable
private data class AdEventBatch(val events: List<AdEvent>)
