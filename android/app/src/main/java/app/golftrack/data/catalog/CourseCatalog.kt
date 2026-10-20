package app.golftrack.data.catalog

import android.content.Context
import app.golftrack.data.Prefs
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * Platzverzeichnis wie `CourseCatalogService` auf iOS: eingebaute Plätze plus
 * die von https://golftrack.app/api/v1/courses nachgeladenen (Cache auf Platte).
 *
 * VERTRAG (von anderen Features genutzt – Signaturen nicht ändern):
 *  - golfCourses / minigolfCourses: zusammengeführte Listen als StateFlow
 *  - golfCourse(slug), minigolfCourse(id)
 *  - suspend refresh(), suspend refreshIfNeeded()
 */
object CourseCatalog {
    private const val FEED_URL = "https://golftrack.app/api/v1/courses"
    private const val STATUS_URL = "https://golftrack.app/api/v1/catalog"

    /** Frühestens nach dieser Zeit wird erneut geladen. */
    private const val REFRESH_INTERVAL_MS = 6L * 60 * 60 * 1000

    /** So lange gilt ein Platz als neu. */
    const val NEW_COURSE_LIFETIME_MS = 30L * 24 * 3600 * 1000

    private const val KNOWN_IDS_KEY = "catalog.knownCourseIDs"
    private const val NEW_IDS_KEY = "catalog.newCourses"
    private const val STATUS_KEY = "catalog.serverStatus"

    private val _golf = MutableStateFlow<List<GolfCourseEntry>>(BundledCourses.all)
    private val _minigolf = MutableStateFlow<List<MinigolfCourseEntry>>(MinigolfCourses.all)
    val golfCourses: StateFlow<List<GolfCourseEntry>> = _golf.asStateFlow()
    val minigolfCourses: StateFlow<List<MinigolfCourseEntry>> = _minigolf.asStateFlow()

    /** Nur die von der Website geladenen Golfplätze (tragen eine Kennung). */
    private val _remoteGolf = MutableStateFlow<List<GolfCourseEntry>>(emptyList())
    val remoteGolfCourses: StateFlow<List<GolfCourseEntry>> = _remoteGolf.asStateFlow()
    private var remoteMinigolf: List<MinigolfCourseEntry> = emptyList()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    var lastError: String? = null
        private set
    var lastUpdated: Long? = null
        private set

    private var cacheFile: File? = null
    private var loadedFromDisk = false
    private val mutex = Mutex()
    private val checkMutex = Mutex()
    private var lastStatusCheck = 0L

    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true; explicitNulls = false }

    fun init(context: Context) {
        val dir = File(context.filesDir, "catalog").apply { mkdirs() }
        cacheFile = File(dir, "remote-courses.json")
        loadCache()
    }

    fun golfCourse(slug: String): GolfCourseEntry? = _golf.value.firstOrNull { it.slug == slug }
    fun minigolfCourse(id: String): MinigolfCourseEntry? =
        remoteMinigolf.firstOrNull { it.id == id } ?: MinigolfCourses.course(id)

    // --- Neue Plätze ---

    private val _newCourses = MutableStateFlow<Map<String, Long>>(emptyMap())
    val newCourses: StateFlow<Map<String, Long>> = _newCourses.asStateFlow()

    val newCourseIDs: Set<String>
        get() {
            val grenze = System.currentTimeMillis() - NEW_COURSE_LIFETIME_MS
            return _newCourses.value.filterValues { it > grenze }.keys
        }

    fun markNewCoursesSeen(ids: Collection<String>) {
        _newCourses.value = _newCourses.value - ids.toSet()
        saveNewCourses()
    }

    /** Zurückgezogene und abgelaufene Plätze fliegen aus den offenen Hinweisen. */
    fun mergeNewCourses(offen: Map<String, Long>, known: Set<String>, current: Set<String>,
                        now: Long = System.currentTimeMillis()): Map<String, Long> {
        val grenze = now - NEW_COURSE_LIFETIME_MS
        val ergebnis = offen.filter { it.key in current && it.value > grenze }.toMutableMap()
        for (id in current - known) ergebnis[id] = now
        return ergebnis
    }

    /** Beim allerersten Laden ist alles „neu" – dann merkt sich die App nur den Stand. */
    private fun recordNewCourses(feed: RemoteCourseFeed) {
        val aktuell = feed.courses.map { it.id }.toSet()
        val bekannt = Prefs.string(KNOWN_IDS_KEY).takeIf { it.isNotEmpty() }
            ?.let { runCatching { json.decodeFromString(ListSerializer(String.serializer()), it) }.getOrNull() }
        if (bekannt != null) {
            _newCourses.value = mergeNewCourses(_newCourses.value, bekannt.toSet(), aktuell)
            saveNewCourses()
        }
        Prefs.set(KNOWN_IDS_KEY, json.encodeToString(ListSerializer(String.serializer()), aktuell.toList()))
    }

    private fun loadNewCourses() {
        val raw = Prefs.string(NEW_IDS_KEY)
        if (raw.isEmpty()) return
        runCatching { json.decodeFromString(MapSerializer(String.serializer(), Long.serializer()), raw) }
            .onSuccess { _newCourses.value = it }
    }

    private fun saveNewCourses() {
        Prefs.set(NEW_IDS_KEY, json.encodeToString(MapSerializer(String.serializer(), Long.serializer()), _newCourses.value))
    }

    // --- Abgleich beim Start ---

    /**
     * Fragt den Server knapp, ob sich der Katalog geändert hat, und lädt ihn
     * nur dann neu. Mehrfache Aufrufe warten auf denselben Abgleich.
     */
    suspend fun checkForUpdates() {
        if (checkMutex.isLocked) { checkMutex.withLock { }; return }
        checkMutex.withLock {
            if (System.currentTimeMillis() - lastStatusCheck < 5 * 60 * 1000) return
            performUpdateCheck()
            lastStatusCheck = System.currentTimeMillis()
        }
    }

    private suspend fun performUpdateCheck() {
        val status = runCatching { json.decodeFromString(CatalogStatus.serializer(), httpGet(STATUS_URL, 8_000)) }.getOrNull()
        if (status == null) {
            // Kein Netz oder ein Server ohne den Endpunkt: wie bisher nach Alter.
            refreshIfNeeded()
            return
        }
        val merker = "${status.count}|${status.lastChangedAt ?: ""}"
        val unveraendert = Prefs.string(STATUS_KEY) == merker
        if (unveraendert && lastUpdated != null) return
        refresh()
        if (lastError == null) Prefs.set(STATUS_KEY, merker)
    }

    // --- Laden ---

    suspend fun refreshIfNeeded() {
        if (!loadedFromDisk) loadCache()
        val last = lastUpdated
        if (last != null && System.currentTimeMillis() - last <= REFRESH_INTERVAL_MS) return
        refresh()
    }

    /** Holt die Liste unabhängig vom Alter des Caches. */
    suspend fun refresh() {
        if (mutex.isLocked) { mutex.withLock { }; return }
        mutex.withLock {
            _isLoading.value = true
            try {
                val text = httpGet(FEED_URL, 15_000)
                val feed = json.decodeFromString(RemoteCourseFeed.serializer(), text)
                adopt(feed)
                recordNewCourses(feed)
                lastUpdated = System.currentTimeMillis()
                withContext(Dispatchers.IO) {
                    cacheFile?.let { f ->
                        val tmp = File(f.parentFile, f.name + ".tmp")
                        tmp.writeText(text)
                        tmp.renameTo(f)
                    }
                }
                lastError = null
            } catch (e: Exception) {
                // Ohne Netz bleibt der Cache stehen – kein Fehlerfall für die Oberfläche.
                lastError = e.message ?: "Serverantwort ungültig"
            } finally {
                _isLoading.value = false
            }
        }
    }

    private suspend fun httpGet(url: String, timeoutMs: Int): String = withContext(Dispatchers.IO) {
        val c = URL(url).openConnection() as HttpURLConnection
        try {
            c.connectTimeout = timeoutMs
            c.readTimeout = timeoutMs
            c.useCaches = false
            c.setRequestProperty("Accept", "application/json")
            c.setRequestProperty("User-Agent", "app.golftrack (Android)")
            if (c.responseCode !in 200..299) throw IllegalStateException("Serverantwort ungültig")
            c.inputStream.bufferedReader().use { it.readText() }
        } finally {
            c.disconnect()
        }
    }

    private fun loadCache() {
        loadedFromDisk = true
        loadNewCourses()
        val f = cacheFile ?: return
        if (!f.exists()) return
        runCatching { json.decodeFromString(RemoteCourseFeed.serializer(), f.readText()) }
            .onSuccess { adopt(it); lastUpdated = f.lastModified() }
    }

    /** Bei gleichem Namen (Golf) bzw. gleicher Kennung (Minigolf) gewinnt der Eintrag der Website. */
    private fun adopt(feed: RemoteCourseFeed) {
        val remoteGolf = feed.courses.filter { it.kind == "golf" }.map { r ->
            r.golfEntry(BundledCourses.all.firstOrNull { it.name.equals(r.name, ignoreCase = true) })
        }
        val remoteMini = feed.courses.filter { it.kind == "minigolf" }.map { r ->
            r.minigolfEntry(MinigolfCourses.course(r.id))
        }
        _remoteGolf.value = remoteGolf
        remoteMinigolf = remoteMini
        val ersetzt = remoteGolf.map { it.name.lowercase() }.toSet()
        _golf.value = BundledCourses.all.filter { it.name.lowercase() !in ersetzt } + remoteGolf
        val ersetztMini = remoteMini.map { it.id }.toSet()
        _minigolf.value = MinigolfCourses.all.filter { it.id !in ersetztMini } + remoteMini
    }
}

// --- Format der API ---

@Serializable
internal data class CatalogStatus(val count: Int = 0, val lastChangedAt: String? = null)

@Serializable
internal data class RemoteCourseFeed(
    val version: Int = 1,
    val generatedAt: String? = null,
    val courses: List<RemoteCourse> = emptyList(),
)

@Serializable
internal data class RemoteHint(val kind: String = "info", val text: String = "") {
    /** Unbekannte Art fällt auf `info` zurück. */
    fun toHint() = CourseHint(runCatching { CourseHintKind.valueOf(kind) }.getOrDefault(CourseHintKind.info), text)
}

@Serializable
internal data class RemoteCourse(
    val id: String,
    val kind: String,
    val name: String,
    val location: String = "",
    val holes: Int = 0,
    val lat: Double? = null,
    val lon: Double? = null,
    val firstTeeLat: Double? = null,
    val firstTeeLon: Double? = null,
    val parValues: List<Int> = emptyList(),
    val hcpValues: List<Int> = emptyList(),
    val holeLengths: List<Int> = emptyList(),
    val courseRating: Double? = null,
    val slopeRating: Int? = null,
    val facilityNotes: String = "",
    val facilityHints: List<RemoteHint>? = null,
    val welcome: String = "",
    val teeLatitudes: List<Double> = emptyList(),
    val teeLongitudes: List<Double> = emptyList(),
    val flagLatitudes: List<Double> = emptyList(),
    val flagLongitudes: List<Double> = emptyList(),
) {
    fun golfEntry(fb: GolfCourseEntry?): GolfCourseEntry = GolfCourseEntry(
        name = name,
        location = location.ifEmpty { fb?.location ?: "" },
        holes = if (holes > 0) holes else (fb?.holes ?: holes),
        lat = lat ?: fb?.lat ?: 0.0,
        lon = lon ?: fb?.lon ?: 0.0,
        parValues = parValues.ifEmpty { fb?.parValues ?: emptyList() },
        hcpValues = hcpValues.ifEmpty { fb?.hcpValues ?: emptyList() },
        holeLengths = holeLengths.ifEmpty { fb?.holeLengths ?: emptyList() },
        courseRating = courseRating ?: fb?.courseRating ?: 72.0,
        slopeRating = slopeRating ?: fb?.slopeRating ?: 113,
        facilityNotes = facilityNotes.ifEmpty { fb?.facilityNotes ?: "" },
        hints = facilityHints?.map { it.toHint() } ?: fb?.hints ?: emptyList(),
        teeLatitudes = teeLatitudes.ifEmpty { fb?.teeLatitudes ?: emptyList() },
        teeLongitudes = teeLongitudes.ifEmpty { fb?.teeLongitudes ?: emptyList() },
        flagLatitudes = flagLatitudes.ifEmpty { fb?.flagLatitudes ?: emptyList() },
        flagLongitudes = flagLongitudes.ifEmpty { fb?.flagLongitudes ?: emptyList() },
        slug = id,
        firstTeeLat = firstTeeLat ?: fb?.firstTeeLat,
        firstTeeLon = firstTeeLon ?: fb?.firstTeeLon,
    )

    fun minigolfEntry(fb: MinigolfCourseEntry?): MinigolfCourseEntry {
        val gruss = welcome.ifEmpty { fb?.welcome ?: "" }
        return MinigolfCourseEntry(
            id = id,
            name = name,
            location = location.ifEmpty { fb?.location ?: "" },
            holes = if (holes > 0) holes else (fb?.holes ?: holes),
            lat = lat ?: fb?.lat ?: 0.0,
            lon = lon ?: fb?.lon ?: 0.0,
            welcome = gruss.ifEmpty { "Willkommen! Ab jetzt zählen wir für dich mit – Bahn für Bahn." },
            notes = facilityNotes.ifEmpty { fb?.notes ?: "" },
            hints = facilityHints?.map { it.toHint() } ?: fb?.hints ?: emptyList(),
            firstTeeLat = firstTeeLat ?: fb?.firstTeeLat,
            firstTeeLon = firstTeeLon ?: fb?.firstTeeLon,
        )
    }
}
