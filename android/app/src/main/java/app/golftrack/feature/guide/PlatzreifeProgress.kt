package app.golftrack.feature.guide

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import app.golftrack.data.Prefs
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

// MARK: - Fortschritt je Frage

/**
 * Lernstand einer einzelnen Platzreife-Frage.
 *
 * Wer eine Frage auf Anhieb richtig beantwortet, kann sie – sie gilt sofort als sicher.
 * Wer sich einmal vertan hat, muss sie danach zweimal in Folge richtig beantworten.
 * So wiederholt die App nur, was wirklich wackelt, statt alle 150 Fragen doppelt abzufragen.
 */
@Serializable
data class QuestionProgress(
    val streak: Int = 0,
    val timesAnswered: Int = 0,
    val timesWrong: Int = 0,
    /** Millisekunden seit 1970. */
    val lastAnswered: Long? = null,
    val lastWasWrong: Boolean = false,
) {
    val requiredStreak: Int get() = if (timesWrong == 0) 1 else 2

    val status: QuestionStatus
        get() = when {
            timesAnswered == 0 -> QuestionStatus.NEW
            lastWasWrong -> QuestionStatus.WRONG
            streak >= requiredStreak -> QuestionStatus.MASTERED
            else -> QuestionStatus.LEARNING
        }

    fun recorded(correct: Boolean, at: Long): QuestionProgress = copy(
        timesAnswered = timesAnswered + 1,
        lastAnswered = at,
        lastWasWrong = !correct,
        streak = if (correct) streak + 1 else 0,
        timesWrong = if (correct) timesWrong else timesWrong + 1,
    )
}

enum class QuestionStatus { NEW, WRONG, LEARNING, MASTERED }

data class QuizStatusCounts(
    val new: Int = 0,
    val wrong: Int = 0,
    val learning: Int = 0,
    val mastered: Int = 0,
) {
    val total: Int get() = new + wrong + learning + mastered
    /** Fragen, die noch einmal drankommen sollten. */
    val toRepeat: Int get() = wrong + learning

    /** Anteil, der für die Prüfung sitzt – halb gelernte Fragen zählen halb. */
    val readiness: Double
        get() = if (total == 0) 0.0 else (mastered + learning * 0.5) / total
}

// MARK: - Lernrunde zusammenstellen

object QuizSessionBuilder {
    /** Fragen pro Lernrunde – kurz genug für die Bahnfahrt, lang genug für Fortschritt. */
    const val SESSION_SIZE = 20

    /**
     * Reihenfolge: zuerst Fehler (älteste zuerst), dann angefangene, dann neue,
     * zum Auffüllen schließlich sichere Fragen, die am längsten nicht dran waren.
     */
    fun session(
        pool: List<QuizQuestion>,
        progress: Map<String, QuestionProgress>,
        limit: Int = SESSION_SIZE,
        mistakesOnly: Boolean = false,
    ): List<QuizQuestion> {
        fun entry(q: QuizQuestion) = progress[q.id] ?: QuestionProgress()
        val oldestFirst = compareBy<QuizQuestion> { entry(it).lastAnswered ?: Long.MIN_VALUE }

        val wrong = pool.filter { entry(it).status == QuestionStatus.WRONG }.sortedWith(oldestFirst)
        val learning = pool.filter { entry(it).status == QuestionStatus.LEARNING }.sortedWith(oldestFirst)
        var picked = wrong + learning
        if (!mistakesOnly) {
            val fresh = pool.filter { entry(it).status == QuestionStatus.NEW }.shuffled()
            val mastered = pool.filter { entry(it).status == QuestionStatus.MASTERED }.sortedWith(oldestFirst)
            picked = picked + fresh + mastered
        }
        return picked.take(limit).shuffled()
    }
}

// MARK: - Speicher

/**
 * Hält den Lernstand aller Platzreife-Fragen und legt ihn in den Prefs ab
 * (gleicher Schlüssel wie auf iOS). Schlüssel je Eintrag ist der Fragetext.
 */
object PlatzreifeProgressStore {
    private const val STORAGE_KEY = "platzreife.progress.v1"
    private val json = Json { ignoreUnknownKeys = true }

    /** Beobachtbar für Compose – jede Änderung ersetzt die Map. */
    var entries: Map<String, QuestionProgress> by mutableStateOf(load())
        private set

    private fun load(): Map<String, QuestionProgress> {
        val raw = Prefs.string(STORAGE_KEY)
        if (raw.isEmpty()) return emptyMap()
        return runCatching { json.decodeFromString<Map<String, QuestionProgress>>(raw) }.getOrDefault(emptyMap())
    }

    fun progress(question: QuizQuestion): QuestionProgress = entries[question.id] ?: QuestionProgress()

    fun status(question: QuizQuestion): QuestionStatus = progress(question).status

    fun record(question: QuizQuestion, correct: Boolean, at: Long = System.currentTimeMillis()) {
        entries = entries + (question.id to progress(question).recorded(correct, at))
        save()
    }

    fun counts(pool: List<QuizQuestion>): QuizStatusCounts {
        var new = 0; var wrong = 0; var learning = 0; var mastered = 0
        for (q in pool) {
            when (status(q)) {
                QuestionStatus.NEW -> new++
                QuestionStatus.WRONG -> wrong++
                QuestionStatus.LEARNING -> learning++
                QuestionStatus.MASTERED -> mastered++
            }
        }
        return QuizStatusCounts(new, wrong, learning, mastered)
    }

    fun session(pool: List<QuizQuestion>, mistakesOnly: Boolean = false): List<QuizQuestion> =
        QuizSessionBuilder.session(pool, entries, mistakesOnly = mistakesOnly)

    fun reset() {
        entries = emptyMap()
        Prefs.remove(STORAGE_KEY)
    }

    private fun save() {
        Prefs.set(STORAGE_KEY, json.encodeToString(entries))
    }
}
