package app.golftrack.feature.minigolf

import app.golftrack.data.Prefs
import app.golftrack.data.catalog.CourseHint
import app.golftrack.data.catalog.MinigolfCourseEntry
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import java.util.UUID

/** Zustand einer Minigolfrunde und ihre Ablage – wie GolfTrackShared/MinigolfModels.swift. */

// MARK: - Config

data class MinigolfConfig(
    val playerNames: List<String>,
    val numberOfHoles: Int,
    val initialScores: List<List<Int>>? = null,
    val initialHole: Int = 0,
    /** Anlage, an der gespielt wird (per QR-Code gestartet) – sonst `null`. */
    val courseName: String? = null,
    /** Kennung derselben Anlage. */
    val courseID: String? = null,
    /** Aktive Nebenwertungen (Serie, Asse, …) */
    val challenges: List<MinigolfChallenge> = emptyList(),
    /** Hinweise der Anlage – laufen während der Runde mit. */
    val hints: List<CourseHint> = emptyList(),
)

// MARK: - Persistence

/**
 * Datumswerte werden wie der Standard-`JSONEncoder` von iOS als Sekunden seit
 * dem 1.1.2001 abgelegt – so bleibt das Format auf beiden Plattformen gleich.
 */
private const val REFERENCE_DATE_OFFSET = 978_307_200.0

fun nowReferenceSeconds(): Double = System.currentTimeMillis() / 1000.0 - REFERENCE_DATE_OFFSET
fun referenceSecondsToMillis(s: Double): Long = ((s + REFERENCE_DATE_OFFSET) * 1000).toLong()

@Serializable
data class SavedMinigolfGame(
    val playerNames: List<String>,
    val numberOfHoles: Int,
    val scores: List<List<Int>>,
    val currentHole: Int,
    val savedAt: Double? = null,
    val courseName: String? = null,
    val courseID: String? = null,
    /** Optional, damit ältere gespeicherte Spiele weiter geladen werden können. */
    val challenges: List<String>? = null,
) {
    val challengeList: List<MinigolfChallenge> get() = challenges.orEmpty().mapNotNull { MinigolfChallenge.fromRaw(it) }
}

@Serializable
data class MinigolfHistoryEntry(
    val id: String = UUID.randomUUID().toString().uppercase(),
    val date: Double,
    val playerNames: List<String>,
    val numberOfHoles: Int,
    val scores: List<List<Int>>,
    val courseName: String? = null,
    val challenges: List<String>? = null,
) {
    val challengeList: List<MinigolfChallenge> get() = challenges.orEmpty().mapNotNull { MinigolfChallenge.fromRaw(it) }
    val dateMillis: Long get() = referenceSecondsToMillis(date)
}

object MinigolfGameStore {
    private const val GAME_KEY = "minigolf.savedGame"
    private const val NAMES_KEY = "minigolf.savedPlayerNames"
    private const val HISTORY_KEY = "minigolf.history"
    private const val CHALLENGES_KEY = "minigolf.challenges"

    private val json = Json { ignoreUnknownKeys = true; explicitNulls = false }
    private val stringList = ListSerializer(String.serializer())

    fun load(): SavedMinigolfGame? {
        val raw = Prefs.string(GAME_KEY).ifEmpty { return null }
        return runCatching { json.decodeFromString(SavedMinigolfGame.serializer(), raw) }.getOrNull()
    }

    fun save(game: SavedMinigolfGame) = Prefs.set(GAME_KEY, json.encodeToString(SavedMinigolfGame.serializer(), game))

    fun clear() = Prefs.remove(GAME_KEY)

    fun loadNames(): List<String>? {
        val raw = Prefs.string(NAMES_KEY).ifEmpty { return null }
        return runCatching { json.decodeFromString(stringList, raw) }.getOrNull()
    }

    fun saveNames(names: List<String>) = Prefs.set(NAMES_KEY, json.encodeToString(stringList, names))

    /** Zuletzt gewählte Wettkämpfe – Vorschlag für die nächste Runde. */
    fun loadChallenges(): List<MinigolfChallenge> {
        val raw = Prefs.string(CHALLENGES_KEY).ifEmpty { return emptyList() }
        return runCatching { json.decodeFromString(stringList, raw) }.getOrDefault(emptyList())
            .mapNotNull { MinigolfChallenge.fromRaw(it) }
    }

    fun saveChallenges(challenges: List<MinigolfChallenge>) =
        Prefs.set(CHALLENGES_KEY, json.encodeToString(stringList, challenges.map { it.raw }))

    fun loadHistory(): List<MinigolfHistoryEntry> {
        val raw = Prefs.string(HISTORY_KEY).ifEmpty { return emptyList() }
        return runCatching { json.decodeFromString(ListSerializer(MinigolfHistoryEntry.serializer()), raw) }
            .getOrDefault(emptyList())
    }

    fun saveHistory(entries: List<MinigolfHistoryEntry>) =
        Prefs.set(HISTORY_KEY, json.encodeToString(ListSerializer(MinigolfHistoryEntry.serializer()), entries))

    fun appendToHistory(entry: MinigolfHistoryEntry) {
        saveHistory((listOf(entry) + loadHistory()).take(50))
    }
}

/**
 * Übergabe der Runde an die Zählkarte. Die Navigation transportiert nur
 * Strings; die Konfiguration liegt deshalb hier. Fehlt sie (Prozess wurde
 * beendet), nimmt die Zählkarte das gespeicherte Spiel.
 */
internal object MinigolfSession {
    var pending: MinigolfConfig? = null

    fun configFromSaved(game: SavedMinigolfGame) = MinigolfConfig(
        playerNames = game.playerNames,
        numberOfHoles = game.numberOfHoles,
        initialScores = game.scores,
        initialHole = game.currentHole,
        courseName = game.courseName,
        courseID = game.courseID,
        challenges = game.challengeList,
    )
}

// MARK: - Anlagen

/** Reihenfolge für die Anlagenliste: mit Standort nach Entfernung, sonst alphabetisch. Nichts wird weggefiltert. */
fun sortedMinigolfCourses(courses: List<MinigolfCourseEntry>, near: app.golftrack.data.LatLon?): List<MinigolfCourseEntry> {
    val byName = compareBy<MinigolfCourseEntry, String>(String.CASE_INSENSITIVE_ORDER) { it.name }
    if (near == null) return courses.sortedWith(byName)
    return courses.sortedWith(compareBy<MinigolfCourseEntry> { it.distance(near) }.then(byName))
}

/** Spielernamen auffüllen: leer → „Spieler n". */
internal fun resolvedNames(raw: List<String>): List<String> =
    raw.mapIndexed { i, n -> if (n.isBlank()) "Spieler ${i + 1}" else n }
