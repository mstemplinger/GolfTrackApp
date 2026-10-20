package app.golftrack.data

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.io.File

/**
 * Ersatz für den SwiftData-Container: alle Golfdaten in einer JSON-Datei.
 * Die Datenmengen sind klein (ein paar hundert Runden), deshalb wird bei jeder
 * Änderung die ganze Datei atomar neu geschrieben.
 *
 * In Compose: `val data by GolfStore.data.collectAsState()`.
 */
@Serializable
data class GolfData(
    val courses: List<Course> = emptyList(),
    val rounds: List<Round> = emptyList(),
    val bags: List<GolfBag> = emptyList(),
    val quizResults: List<QuizResult> = emptyList(),
) {
    fun course(id: String?): Course? = id?.let { i -> courses.firstOrNull { it.id == i } }
    fun round(id: String?): Round? = id?.let { i -> rounds.firstOrNull { it.id == i } }
    fun bag(id: String?): GolfBag? = id?.let { i -> bags.firstOrNull { it.id == i } }

    /** Runden neueste zuerst. */
    val sortedRounds: List<Round> get() = rounds.sortedByDescending { it.date }
    val completedRounds: List<Round> get() = sortedRounds.filter { it.isComplete }
    val openRound: Round? get() = sortedRounds.firstOrNull { !it.isComplete }
}

object GolfStore {
    val json = Json { ignoreUnknownKeys = true; encodeDefaults = true; allowSpecialFloatingPointValues = true }

    private lateinit var file: File
    private val _data = MutableStateFlow(GolfData())
    val data: StateFlow<GolfData> = _data.asStateFlow()

    val current: GolfData get() = _data.value

    fun init(context: Context) {
        file = File(context.filesDir, "golfdata.json")
        if (file.exists()) {
            runCatching { json.decodeFromString<GolfData>(file.readText()) }
                .onSuccess { _data.value = it }
        }
    }

    @Synchronized
    fun update(transform: (GolfData) -> GolfData) {
        val next = transform(_data.value)
        _data.value = next
        persist(next)
    }

    private fun persist(d: GolfData) {
        if (!::file.isInitialized) return
        val tmp = File(file.parentFile, file.name + ".tmp")
        tmp.writeText(json.encodeToString(GolfData.serializer(), d))
        tmp.renameTo(file)
    }

    // --- Bequeme Einzeloperationen ---

    fun upsertCourse(c: Course) = update { d ->
        d.copy(courses = d.courses.filter { it.id != c.id } + c)
    }

    fun deleteCourse(id: String) = update { d ->
        d.copy(
            courses = d.courses.filter { it.id != id },
            rounds = d.rounds.map { if (it.courseId == id) it.copy(courseId = null) else it },
        )
    }

    fun upsertRound(r: Round) = update { d ->
        d.copy(rounds = d.rounds.filter { it.id != r.id } + r)
    }

    fun updateRound(id: String, transform: (Round) -> Round) = update { d ->
        d.copy(rounds = d.rounds.map { if (it.id == id) transform(it) else it })
    }

    fun deleteRound(id: String) = update { d -> d.copy(rounds = d.rounds.filter { it.id != id }) }

    fun upsertBag(b: GolfBag) = update { d ->
        d.copy(bags = d.bags.filter { it.id != b.id } + b)
    }

    fun deleteBag(id: String) = update { d ->
        d.copy(
            bags = d.bags.filter { it.id != id },
            rounds = d.rounds.map { if (it.bagId == id) it.copy(bagId = null) else it },
        )
    }

    fun addQuizResult(r: QuizResult) = update { d -> d.copy(quizResults = d.quizResults + r) }

    /**
     * Platz aus dem Verzeichnis als eigener Eintrag – wiedererkannt am Namen,
     * damit nicht bei jedem Start ein zweiter Eintrag entsteht (wie
     * `storedCourse(for:)` in ContentView.swift).
     */
    fun storedCourse(entry: Course): Course {
        current.courses.firstOrNull { it.name.equals(entry.name, ignoreCase = true) }?.let { return it }
        upsertCourse(entry)
        return entry
    }
}
