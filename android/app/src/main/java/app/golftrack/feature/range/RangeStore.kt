package app.golftrack.feature.range

import android.content.Context
import app.golftrack.data.newId
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.File

/**
 * Ein Schlag auf der Range. Der Schläger hängt bewusst nur am Namen:
 * Bags dürfen gelöscht oder neu angelegt werden, ohne die Historie zu verlieren.
 */
@Serializable
data class RangeShot(
    val id: String = newId(),
    val clubName: String,
    /** Immer in Metern gespeichert, angezeigt in der gewählten Einheit. */
    val distanceMeters: Double,
    val date: Long = System.currentTimeMillis(),
)

/** Eine Einheit auf der Driving Range – alle Schläge zwischen „Start" und „Beenden". */
@Serializable
data class RangeSession(
    val id: String = newId(),
    val date: Long = System.currentTimeMillis(),
    val endedAt: Long? = null,
    val shots: List<RangeShot> = emptyList(),
) {
    val sortedShots: List<RangeShot> get() = shots.sortedBy { it.date }

    /** Schläger in der Reihenfolge, in der sie zum ersten Mal geschlagen wurden. */
    val clubNames: List<String> get() = sortedShots.map { it.clubName }.distinct()
}

@Serializable
data class RangeData(val sessions: List<RangeSession> = emptyList())

/** Kennzahlen eines Schlägers über eine Menge von Range-Schlägen. */
data class RangeClubStats(val clubName: String, val count: Int, val average: Double, val best: Double) {
    companion object {
        fun of(clubName: String, distances: List<Double>): RangeClubStats? =
            if (distances.isEmpty()) null
            else RangeClubStats(clubName, distances.size, distances.average(), distances.max())

        fun byClub(shots: List<RangeShot>): Map<String, RangeClubStats> =
            shots.groupBy { it.clubName }.mapNotNull { (club, s) -> of(club, s.map { it.distanceMeters }) }
                .associateBy { it.clubName }
    }
}

object RangeClubDefaults {
    /** Auswahl ohne angelegtes Bag – dieselben Namen wie die Standardschläger im Profil. */
    val names = listOf(
        "Driver", "3 Wood", "5 Wood", "Hybrid", "4 Eisen", "5 Eisen", "6 Eisen",
        "7 Eisen", "8 Eisen", "9 Eisen", "PW", "GW", "SW", "LW",
    )

    /** Driver erkennen, egal wie der Spieler ihn im Bag benannt hat. */
    fun isDriver(name: String): Boolean {
        val n = name.lowercase()
        return "driver" in n || n == "1w" || n == "1 wood" || n == "holz 1"
    }
}

/**
 * Eigener JSON-Speicher für die Driving Range (nach dem Muster von GolfStore),
 * damit die gemeinsamen Golfdaten unberührt bleiben.
 */
object RangeStore {
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private var file: File? = null
    private val _data = MutableStateFlow(RangeData())
    val data: StateFlow<RangeData> = _data.asStateFlow()

    /** Mehrfach aufrufbar – lädt nur beim ersten Mal. */
    @Synchronized
    fun init(context: Context) {
        if (file != null) return
        val f = File(context.applicationContext.filesDir, "rangedata.json")
        file = f
        if (f.exists()) {
            runCatching { json.decodeFromString<RangeData>(f.readText()) }.onSuccess { _data.value = it }
        }
    }

    @Synchronized
    fun update(transform: (RangeData) -> RangeData) {
        val next = transform(_data.value)
        _data.value = next
        val f = file ?: return
        val tmp = File(f.parentFile, f.name + ".tmp")
        tmp.writeText(json.encodeToString(RangeData.serializer(), next))
        tmp.renameTo(f)
    }

    fun upsert(session: RangeSession) = update { d ->
        d.copy(sessions = d.sessions.filter { it.id != session.id } + session)
    }

    fun delete(id: String) = update { d -> d.copy(sessions = d.sessions.filter { it.id != id }) }
}
