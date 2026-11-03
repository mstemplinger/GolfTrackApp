package app.golftrack.feature.lobby

import android.content.Context
import android.location.Location
import app.golftrack.data.GolfStore
import app.golftrack.data.LatLon
import app.golftrack.data.Prefs
import app.golftrack.data.Round
import app.golftrack.ui.common.LocationService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.put
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.time.Instant

// MARK: - Datenvertrag mit golftrack.app (`web/src/lib/lobby.ts`)

@Serializable
data class LobbyShot(
    val n: Int,
    val club: String = "",
    val lat: Double? = null,
    val lon: Double? = null,
    val meters: Double? = null,
)

@Serializable
data class LobbyHole(
    val hole: Int,
    val strokes: Int,
    val putts: Int = 0,
    val fairway: Boolean = false,
    val gir: Boolean = false,
    val shots: List<LobbyShot> = emptyList(),
)

@Serializable
data class LobbyLocation(
    val lat: Double,
    val lon: Double,
    val accuracy: Double = 0.0,
    val at: String = "",
) {
    val point: LatLon get() = LatLon(lat, lon)
    val atMillis: Long get() = parseIso(at)
}

@Serializable
data class LobbyMember(
    val id: String,
    val name: String,
    val isHost: Boolean = false,
    val currentHole: Int = 0,
    val scores: List<LobbyHole> = emptyList(),
    val seenAt: String = "",
    val location: LobbyLocation? = null,
) {
    fun hole(number: Int): LobbyHole? = scores.firstOrNull { it.hole == number }
    val playedHoles: List<LobbyHole> get() = scores.filter { it.strokes > 0 }
    val totalStrokes: Int get() = playedHoles.sumOf { it.strokes }
    val seenAtMillis: Long get() = parseIso(seenAt)

    /** Ergebnis zum Par über die gespielten Löcher. */
    fun toPar(pars: List<Int>): Int? {
        val played = playedHoles.filter { it.hole - 1 < pars.size }
        if (played.isEmpty()) return null
        return played.sumOf { it.strokes - pars[it.hole - 1] }
    }

    /** Länger als zwei Minuten nichts gehört – Funkloch oder App zu. */
    val isStale: Boolean get() = System.currentTimeMillis() - seenAtMillis > 120_000
}

@Serializable
data class LobbyState(
    val code: String,
    val courseName: String = "",
    val courseSlug: String = "",
    val holes: Int = 18,
    val tracking: Boolean = true,
    val me: String,
    val members: List<LobbyMember> = emptyList(),
) {
    val others: List<LobbyMember> get() = members.filter { it.id != me }
    val host: LobbyMember? get() = members.firstOrNull { it.isHost }
}

/** Was in der App gespeichert bleibt, damit die Lobby einen Neustart übersteht. */
@Serializable
data class LobbySession(val code: String, val memberId: String, val token: String, val isHost: Boolean)

@Serializable
private data class LobbyReply(val code: String, val memberId: String, val token: String)

private fun parseIso(raw: String): Long =
    runCatching { Instant.parse(raw).toEpochMilli() }.getOrDefault(System.currentTimeMillis())

private class LobbyException(val kind: Kind) : Exception() {
    enum class Kind { GONE, NOT_FOUND, FULL, RATE_LIMITED, SERVER }

    val userMessage: String
        get() = when (kind) {
            Kind.GONE, Kind.NOT_FOUND -> "Zu diesem Code gibt es keine Lobby. Prüf die fünf Ziffern."
            Kind.FULL -> "Die Lobby ist voll – mehr als acht Spieler gehen nicht."
            Kind.RATE_LIMITED -> "Zu viele Versuche. Warte ein paar Minuten."
            Kind.SERVER -> "Der Server hat nicht geantwortet. Versuch es gleich noch einmal."
        }
}

// MARK: - Dienst

/**
 * Lobby für gemeinsame Runden (wie LobbyService.swift): Code anlegen oder
 * beitreten, eigenen Stand melden, den der Freunde abholen und – wenn alle
 * einverstanden sind – sich gegenseitig auf dem Platz wiederfinden.
 *
 * Jeder spielt auf dem eigenen Handy. Der Server (`golftrack.app/api/v1/lobby`)
 * hält nur den letzten Stand jedes Mitspielers. Abgeglichen wird per Abfrage
 * alle 4 Sekunden, solange die App vorn ist. Android-Abweichung: Der Standort
 * geht nur bei offener Zählkarte im Vordergrund raus (kein Foreground-Service,
 * wie die Laufspur in `RoundTracker`).
 */
object LobbyService {
    private const val BASE_URL = "https://golftrack.app/api/v1/lobby"

    /** Link im QR-Code – mit der Kamera-App gescannt öffnet er den Beitritt. */
    fun joinUrl(code: String) = "https://golftrack.app/lobby/$code"

    private const val SESSION_KEY = "lobby.session"
    private const val SHARE_LOCATION_KEY = "lobby.shareLocation"
    private const val POLL_INTERVAL_MS = 4_000L
    /** Standort höchstens so oft melden – genug, um sich auf dem Platz zu finden. */
    private const val LOCATION_INTERVAL_MS = 10_000L

    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true; explicitNulls = false }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val _session = MutableStateFlow(loadSession())
    val session: StateFlow<LobbySession?> = _session.asStateFlow()

    private val _state = MutableStateFlow<LobbyState?>(null)
    val state: StateFlow<LobbyState?> = _state.asStateFlow()

    private val _isBusy = MutableStateFlow(false)
    val isBusy: StateFlow<Boolean> = _isBusy.asStateFlow()

    val errorMessage = MutableStateFlow<String?>(null)

    /** Die Lobby wurde vom Gastgeber beendet oder man wurde entfernt. */
    val endedNotice = MutableStateFlow<String?>(null)

    /** Code aus einem gescannten Link – die Lobby-Karte beim Rundenstart tritt damit bei. */
    val pendingJoinCode = MutableStateFlow<String?>(null)

    private val _shareLocation = MutableStateFlow(if (Prefs.sp.contains(SHARE_LOCATION_KEY)) Prefs.bool(SHARE_LOCATION_KEY) else true)
    val shareLocation: StateFlow<Boolean> = _shareLocation.asStateFlow()

    private val _myLocation = MutableStateFlow<LatLon?>(null)
    val myLocation: StateFlow<LatLon?> = _myLocation.asStateFlow()
    private var myAccuracy = 0.0

    private var pollJob: Job? = null
    private var locationJob: Job? = null
    private var locationContext: Context? = null
    private var lastLocationSent = 0L
    private var lastScoresSent: List<LobbyHole>? = null
    private var lastHoleSent: Int? = null
    private var attachedRoundId: String? = null
    private var inForeground = true

    val isActive: Boolean get() = _session.value != null
    val isHost: Boolean get() = _session.value?.isHost ?: false
    val code: String? get() = _session.value?.code

    fun setShareLocation(value: Boolean, ctx: Context) {
        _shareLocation.value = value
        Prefs.set(SHARE_LOCATION_KEY, value)
        updateLocationUpdates(ctx)
        val loc = if (value) currentLocationPayload() else null
        scope.launch { push(shareLocation = value, location = loc?.let { PushLocation.Set(it) }) }
    }

    // MARK: Anlegen, Beitreten, Verlassen

    fun create(name: String, courseName: String, courseSlug: String, holes: Int, tracking: Boolean, onDone: () -> Unit = {}) {
        scope.launch {
            perform {
                val body = buildJsonObject {
                    put("name", clean(name))
                    put("courseName", courseName.take(120))
                    put("courseSlug", courseSlug.take(120))
                    put("holes", holes.coerceIn(1, 36))
                    put("tracking", tracking)
                }
                val reply = json.decodeFromString<LobbyReply>(request(BASE_URL, "POST", body.toString()))
                begin(LobbySession(reply.code, reply.memberId, reply.token, isHost = true))
            }
            onDone()
        }
    }

    fun join(rawCode: String, name: String, onDone: (Boolean) -> Unit = {}) {
        val code = rawCode.filter { it.isDigit() }
        if (code.length != 5) {
            errorMessage.value = "Der Lobby-Code hat fünf Ziffern."
            onDone(false)
            return
        }
        scope.launch {
            perform {
                val body = buildJsonObject { put("name", clean(name)) }
                val reply = json.decodeFromString<LobbyReply>(request("$BASE_URL/$code/join", "POST", body.toString()))
                begin(LobbySession(reply.code, reply.memberId, reply.token, isHost = false))
            }
            onDone(isActive)
        }
    }

    fun leave(onDone: () -> Unit = {}) {
        val session = _session.value ?: run { onDone(); return }
        scope.launch {
            runCatching { request("$BASE_URL/${session.code}", "DELETE", null) }
            end()
            onDone()
        }
    }

    /** Nur der Gastgeber: gegenseitiges Orten für alle an- oder ausschalten. */
    fun setTracking(enabled: Boolean) = settings(buildJsonObject { put("tracking", enabled) })

    /** Nur der Gastgeber: Platz der Lobby ändern – die Gäste übernehmen ihn. */
    fun setCourse(name: String, slug: String, holes: Int) {
        val state = _state.value ?: return
        if (!isHost || (state.courseName == name && state.holes == holes)) return
        settings(buildJsonObject {
            put("course", buildJsonObject {
                put("name", name.take(120))
                put("slug", slug.take(120))
                put("holes", holes.coerceIn(1, 36))
            })
        })
    }

    /** Nur der Gastgeber: jemanden aus der Lobby nehmen. */
    fun remove(member: LobbyMember) = settings(buildJsonObject { put("kick", member.id) })

    // MARK: Runde

    /**
     * Verbindet die laufende Runde mit der Lobby: eigener Stand geht raus,
     * der Stand der Freunde landet – bei Spielformen mit Mitspielern – in
     * deren Scorekarte.
     */
    fun attach(round: Round, ctx: Context) {
        if (!isActive || round.lobbyCode != code) return
        attachedRoundId = round.id
        startPolling()
        updateLocationUpdates(ctx)
    }

    fun detach(round: Round, ctx: Context) {
        if (attachedRoundId != round.id) return
        attachedRoundId = null
        updateLocationUpdates(ctx)
    }

    /** Eigenen Stand melden, wenn er sich geändert hat. */
    fun publish(round: Round, currentHole: Int) {
        if (!isActive || round.lobbyCode != code) return
        val scores = payload(round)
        val newScores = scores.takeIf { it != lastScoresSent }
        val newHole = currentHole.takeIf { it != lastHoleSent }
        if (newScores == null && newHole == null) return
        scope.launch { push(currentHole = newHole, scores = newScores) }
    }

    /** Runde abgeschlossen: Stand ein letztes Mal melden, Standort nicht mehr teilen. */
    fun roundFinished(round: Round, ctx: Context) {
        if (!isActive || round.lobbyCode != code) return
        attachedRoundId = null
        updateLocationUpdates(ctx)
        scope.launch { push(scores = payload(round), location = PushLocation.Clear) }
    }

    // MARK: Vorder-/Hintergrund

    /** App geht in den Hintergrund: nicht weiter abfragen, Standort ruhen lassen. */
    fun onBackground(ctx: Context) {
        inForeground = false
        stopPolling()
        updateLocationUpdates(ctx)
    }

    fun onForeground(ctx: Context) {
        inForeground = true
        updateLocationUpdates(ctx)
    }

    // MARK: Abgleich

    fun startPolling() {
        if (!isActive || pollJob?.isActive == true || !inForeground) return
        pollJob = scope.launch {
            while (true) {
                tick()
                delay(POLL_INTERVAL_MS)
            }
        }
    }

    /** Außerhalb von Lobby-Karte und Runde nicht weiter abfragen. */
    fun pauseIfIdle() {
        if (attachedRoundId == null) stopPolling()
    }

    fun stopPolling() {
        pollJob?.cancel()
        pollJob = null
    }

    /**
     * Ein Abgleich. Steht der eigene Standort länger als 10 s nicht beim Server
     * (man bewegt sich nicht), geht er gleich mit – sonst gälte er nach 15 Minuten als veraltet.
     */
    private suspend fun tick() {
        if (wantsLocation && System.currentTimeMillis() - lastLocationSent >= LOCATION_INTERVAL_MS) {
            val loc = currentLocationPayload()
            if (loc != null) {
                lastLocationSent = System.currentTimeMillis()
                push(location = PushLocation.Set(loc))
                return
            }
        }
        refresh()
    }

    suspend fun refresh() {
        val session = _session.value ?: return
        try {
            apply(json.decodeFromString<LobbyState>(request("$BASE_URL/${session.code}", "GET", null)))
        } catch (e: LobbyException) {
            if (e.kind == LobbyException.Kind.GONE) endedByServer()
        } catch (_: Exception) {
            // Funkloch: beim nächsten Durchgang wieder.
        }
    }

    private sealed interface PushLocation {
        data class Set(val loc: Triple<Double, Double, Double>) : PushLocation
        data object Clear : PushLocation
    }

    /** Teilmeldung an `/state` – nur gesetzte Felder werden übertragen. */
    private suspend fun push(
        currentHole: Int? = null,
        scores: List<LobbyHole>? = null,
        shareLocation: Boolean? = null,
        location: PushLocation? = null,
    ) {
        val session = _session.value ?: return
        val body = buildJsonObject {
            currentHole?.let { put("currentHole", it.coerceIn(0, 36)) }
            scores?.let { put("scores", json.encodeToJsonElement(it)) }
            shareLocation?.let { put("shareLocation", it) }
            when (location) {
                is PushLocation.Set -> put("location", buildJsonObject {
                    put("lat", location.loc.first)
                    put("lon", location.loc.second)
                    put("accuracy", location.loc.third.coerceIn(0.0, 10_000.0))
                })
                PushLocation.Clear -> put("location", JsonNull)
                null -> {}
            }
        }
        try {
            val fresh = json.decodeFromString<LobbyState>(request("$BASE_URL/${session.code}/state", "POST", body.toString()))
            scores?.let { lastScoresSent = it }
            currentHole?.let { lastHoleSent = it }
            apply(fresh)
        } catch (e: LobbyException) {
            if (e.kind == LobbyException.Kind.GONE) endedByServer()
        } catch (_: Exception) {
        }
    }

    private fun settings(body: JsonObject) {
        val session = _session.value ?: return
        if (!session.isHost) return
        scope.launch {
            perform {
                apply(json.decodeFromString<LobbyState>(request("$BASE_URL/${session.code}/settings", "POST", body.toString())))
            }
        }
    }

    private fun apply(fresh: LobbyState) {
        _state.value = fresh
        // Auch für eine erst später erteilte Standort-Berechtigung – der Aufruf ist billig.
        locationContext?.let { updateLocationUpdates(it) }
        attachedRoundId?.let { mirror(fresh, it) }
    }

    // MARK: Sitzung

    private fun begin(new: LobbySession) {
        _session.value = new
        lastScoresSent = null
        lastHoleSent = null
        Prefs.set(SESSION_KEY, json.encodeToString(new))
        startPolling()
    }

    private fun end() {
        stopPolling()
        _session.value = null
        _state.value = null
        attachedRoundId = null
        locationContext?.let { updateLocationUpdates(it) }
        Prefs.remove(SESSION_KEY)
    }

    private fun endedByServer() {
        val wasHost = isHost
        end()
        endedNotice.value = if (wasHost) "Die Lobby ist abgelaufen."
        else "Die Lobby wurde beendet oder du wurdest entfernt."
    }

    private fun loadSession(): LobbySession? =
        Prefs.string(SESSION_KEY).takeIf { it.isNotEmpty() }?.let { runCatching { json.decodeFromString<LobbySession>(it) }.getOrNull() }

    // MARK: Standort

    private val wantsLocation: Boolean
        get() = isActive && inForeground && _shareLocation.value && (_state.value?.tracking ?: false) && attachedRoundId != null

    private fun updateLocationUpdates(ctx: Context) {
        val app = ctx.applicationContext
        locationContext = app
        if (!wantsLocation || !LocationService.hasPermission(app)) {
            if (locationJob != null) {
                locationJob?.cancel()
                locationJob = null
                LocationService.stop(app)
            }
            return
        }
        if (locationJob != null) return
        LocationService.start(app, highAccuracy = true)
        locationJob = scope.launch {
            LocationService.location.collect { loc -> if (loc != null) received(loc) }
        }
    }

    private fun currentLocationPayload(): Triple<Double, Double, Double>? =
        _myLocation.value?.let { Triple(it.lat, it.lon, maxOf(0.0, myAccuracy)) }

    private fun received(location: Location) {
        _myLocation.value = LatLon(location.latitude, location.longitude)
        myAccuracy = location.accuracy.toDouble()
        if (!wantsLocation) return
        val now = System.currentTimeMillis()
        if (now - lastLocationSent < LOCATION_INTERVAL_MS) return
        lastLocationSent = now
        val loc = currentLocationPayload() ?: return
        scope.launch { push(location = PushLocation.Set(loc)) }
    }

    /** Für die Karte: eigener Standort auch ohne Teilen (Abstand zu den Freunden). */
    fun noteLocation(here: LatLon?) {
        if (here != null) _myLocation.value = here
    }

    // MARK: Abbildung Runde ↔ Lobby

    private fun payload(round: Round): List<LobbyHole> = round.sortedScores.map { score ->
        LobbyHole(
            hole = score.holeNumber,
            strokes = score.strokes,
            putts = score.putts,
            fairway = score.fairwayHit,
            gir = score.greenInRegulation,
            shots = score.sortedShots.take(40).map { shot ->
                val located = shot.fromLatitude != 0.0 || shot.fromLongitude != 0.0
                val meters = shot.distanceMeters
                LobbyShot(
                    n = shot.shotNumber.coerceIn(1, 40),
                    club = shot.club.take(40),
                    lat = if (located) shot.fromLatitude else null,
                    lon = if (located) shot.fromLongitude else null,
                    meters = if (located && meters > 0 && meters.isFinite()) minOf(meters, 1000.0) else null,
                )
            },
        )
    }

    /**
     * Bei Spielformen mit Mitspielern stehen die Freunde als Mitspieler in der
     * Runde (`Round.lobbyMemberIDs`). Ihre Schläge kommen von ihrem eigenen
     * Handy und werden hier eingetragen – Matchplay, Skins usw. rechnen dann
     * wie gewohnt.
     */
    private fun mirror(state: LobbyState, roundId: String) {
        val round = GolfStore.current.round(roundId) ?: return
        val ids = round.lobbyMemberIDs
        if (ids.isEmpty()) return
        var changed = false
        val updated = round.playerHoleScores.map { entry ->
            val id = ids.getOrNull(entry.playerIndex - 1) ?: return@map entry
            val member = state.members.firstOrNull { it.id == id } ?: return@map entry
            // Nur gespielte Löcher – solange der Freund nichts eingetragen hat,
            // bleibt stehen, was hier von Hand eingetragen wurde.
            val hole = member.hole(entry.holeNumber)?.takeIf { it.strokes > 0 } ?: return@map entry
            val next = entry.copy(strokes = hole.strokes, putts = hole.putts, fairwayHit = hole.fairway, greenInRegulation = hole.gir)
            if (next != entry) changed = true
            next
        }
        if (changed) GolfStore.updateRound(roundId) { it.copy(playerHoleScores = updated) }
    }

    // MARK: Netz

    private suspend fun perform(work: suspend () -> Unit) {
        _isBusy.value = true
        errorMessage.value = null
        try {
            work()
        } catch (e: LobbyException) {
            errorMessage.value = e.userMessage
        } catch (_: Exception) {
            errorMessage.value = "Keine Verbindung zum Server. Prüf die Internetverbindung."
        } finally {
            _isBusy.value = false
        }
    }

    private suspend fun request(url: String, method: String, body: String?): String = withContext(Dispatchers.IO) {
        val conn = URL(url).openConnection() as HttpURLConnection
        try {
            conn.requestMethod = method
            conn.connectTimeout = 15_000
            conn.readTimeout = 15_000
            conn.setRequestProperty("Accept", "application/json")
            _session.value?.token?.let { conn.setRequestProperty("Authorization", "Bearer $it") }
            if (body != null) {
                conn.doOutput = true
                conn.setRequestProperty("Content-Type", "application/json")
                conn.outputStream.use { it.write(body.toByteArray()) }
            }
            when (val status = conn.responseCode) {
                in 200..299 -> conn.inputStream.bufferedReader().use { it.readText() }
                401 -> throw LobbyException(LobbyException.Kind.GONE)
                // Beim Beitreten heißt 404 „falscher Code“, sonst ist die Lobby weg.
                404 -> throw LobbyException(
                    if (url.endsWith("/join") || _session.value == null) LobbyException.Kind.NOT_FOUND else LobbyException.Kind.GONE,
                )
                409 -> throw LobbyException(LobbyException.Kind.FULL)
                429 -> throw LobbyException(LobbyException.Kind.RATE_LIMITED)
                else -> throw if (status <= 0) IOException("HTTP $status") else LobbyException(LobbyException.Kind.SERVER)
            }
        } finally {
            conn.disconnect()
        }
    }

    private fun clean(name: String): String = name.trim().ifEmpty { "Golfer" }.take(30)
}
