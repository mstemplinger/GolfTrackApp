package app.golftrack.feature.minigolf

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsRun
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.SportsScore
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Zusatzwertungen für eine Minigolf-Runde ("Wettkämpfe") – wie
 * GolfTrackShared/MinigolfChallenge.swift. Sie laufen parallel zur
 * Schlagwertung; gewertet wird immer die komplette Scorecard.
 */
enum class MinigolfChallenge(
    val raw: String,
    val displayName: String,
    /** Die Regel in einem Satz – steht in der Auswahl unter dem Namen. */
    val rule: String,
    /** Einheit hinter dem Zahlenwert in der Tabelle. */
    val unit: String,
    val trophy: String,
) {
    STREAK("streak", "Serie",
        "Wer schafft die längste Serie an Bahnen hintereinander mit höchstens 2 Schlägen?", "in Folge", "🔥"),
    ACES("aces", "Ass-Jäger",
        "Wer locht am häufigsten mit dem ersten Schlag ein?", "Asse", "🎯"),
    HOLE_WINS("holeWins", "Bahnenduell",
        "Wer gewinnt die meisten Bahnen allein? Bei Gleichstand auf einer Bahn bekommt sie niemand.", "Bahnen", "🏁"),
    STEADY("steady", "Nervenstark",
        "Wer leistet sich die wenigsten Patzer mit 4 Schlägen oder mehr?", "Patzer", "🛡️"),
    COMEBACK("comeback", "Aufholjagd",
        "Wer spielt die zweite Hälfte am deutlichsten besser als die erste?", "Schläge besser", "📈"),
    FINISH("finish", "Schlussspurt",
        "Wer braucht auf den letzten 3 Bahnen die wenigsten Schläge?", "Schläge", "🚀");

    val icon: ImageVector
        get() = when (this) {
            STREAK -> Icons.Filled.LocalFireDepartment
            ACES -> Icons.Filled.GpsFixed
            HOLE_WINS -> Icons.Filled.SportsScore
            STEADY -> Icons.Filled.Shield
            COMEBACK -> Icons.AutoMirrored.Filled.TrendingUp
            FINISH -> Icons.AutoMirrored.Filled.DirectionsRun
        }

    companion object {
        /** Ab wie vielen Schlägen eine Bahn nicht mehr zur Serie zählt. */
        const val STREAK_LIMIT = 2
        /** Ab wie vielen Schlägen eine Bahn als Patzer gilt. */
        const val BLOW_UP_LIMIT = 4
        /** Wie viele Bahnen der Schlussspurt umfasst. */
        const val FINISH_HOLES = 3

        fun fromRaw(raw: String): MinigolfChallenge? = entries.firstOrNull { it.raw == raw }
    }
}

/** Ein Spieler in der Wertung eines Wettkampfs. */
data class MinigolfChallengeStanding(
    val playerIndex: Int,
    val name: String,
    /** Sortierwert – größer ist immer besser. */
    val rank: Int,
    /** Der Wert in Anzeigerichtung. */
    val value: Int,
    val qualifies: Boolean,
)

class MinigolfChallengeResult(val challenge: MinigolfChallenge, val standings: List<MinigolfChallengeStanding>) {
    /** Aktuell Führende (mehrere bei Gleichstand), leer solange niemand die Bedingung erfüllt. */
    val leaders: List<MinigolfChallengeStanding>
        get() {
            val best = standings.firstOrNull { it.qualifies } ?: return emptyList()
            return standings.filter { it.qualifies && it.rank == best.rank }
        }

    val leaderNames: String get() = leaders.joinToString(", ") { it.name }

    val leaderValueText: String? get() = leaders.firstOrNull()?.let { valueText(it) }

    fun valueText(standing: MinigolfChallengeStanding): String =
        if (standing.qualifies) "${standing.value} ${challenge.unit}" else "–"
}

object MinigolfChallengeEngine {
    private data class Raw(val rank: Int, val value: Int, val qualifies: Boolean)

    /** `scores[spieler][bahn]`, 0 = noch nicht gespielt. */
    fun evaluate(challenge: MinigolfChallenge, scores: List<List<Int>>, names: List<String>): MinigolfChallengeResult {
        val raw = when (challenge) {
            MinigolfChallenge.STREAK -> streak(scores)
            MinigolfChallenge.ACES -> aces(scores)
            MinigolfChallenge.HOLE_WINS -> holeWins(scores)
            MinigolfChallenge.STEADY -> steady(scores)
            MinigolfChallenge.COMEBACK -> comeback(scores)
            MinigolfChallenge.FINISH -> finish(scores)
        }
        val standings = raw.mapIndexed { i, r ->
            MinigolfChallengeStanding(i, names.getOrElse(i) { "${i + 1}" }, r.rank, r.value, r.qualifies)
        }.sortedWith { l, r ->
            when {
                l.qualifies != r.qualifies -> if (l.qualifies) -1 else 1
                l.rank != r.rank -> r.rank.compareTo(l.rank)
                else -> l.playerIndex.compareTo(r.playerIndex)
            }
        }
        return MinigolfChallengeResult(challenge, standings)
    }

    fun results(challenges: List<MinigolfChallenge>, scores: List<List<Int>>, names: List<String>) =
        challenges.map { evaluate(it, scores, names) }

    private fun streak(scores: List<List<Int>>) = scores.map { row ->
        var best = 0
        var current = 0
        for (s in row) {
            if (s > 0 && s <= MinigolfChallenge.STREAK_LIMIT) {
                current += 1
                best = maxOf(best, current)
            } else current = 0
        }
        Raw(best, best, best >= 2)
    }

    private fun aces(scores: List<List<Int>>) = scores.map { row ->
        val c = row.count { it == 1 }
        Raw(c, c, c > 0)
    }

    private fun holeWins(scores: List<List<Int>>): List<Raw> {
        val holeCount = scores.firstOrNull()?.size ?: 0
        val wins = IntArray(scores.size)
        for (hole in 0 until holeCount) {
            val strokes = scores.map { it[hole] }
            // Nur vollständig gespielte Bahnen werden gewertet.
            if (!strokes.all { it > 0 }) continue
            val best = strokes.min()
            val winners = strokes.indices.filter { strokes[it] == best }
            // Geteilte Bahnen zählen für niemanden.
            if (winners.size == 1) wins[winners[0]] += 1
        }
        return wins.map { Raw(it, it, it > 0) }
    }

    private fun steady(scores: List<List<Int>>) = scores.map { row ->
        val played = row.filter { it > 0 }
        val blowUps = played.count { it >= MinigolfChallenge.BLOW_UP_LIMIT }
        // Weniger ist besser → negativer Sortierwert.
        Raw(-blowUps, blowUps, played.isNotEmpty())
    }

    private fun comeback(scores: List<List<Int>>): List<Raw> {
        val half = (scores.firstOrNull()?.size ?: 0) / 2
        if (half <= 0) return scores.map { Raw(0, 0, false) }
        return scores.map { row ->
            val first = row.take(half)
            val second = row.takeLast(half)
            // Nur vergleichbar, wenn beide Hälften komplett gespielt sind.
            if (!first.all { it > 0 } || !second.all { it > 0 }) Raw(Int.MIN_VALUE, 0, false)
            else {
                val gain = first.sum() - second.sum()
                Raw(gain, gain, gain > 0)
            }
        }
    }

    private fun finish(scores: List<List<Int>>): List<Raw> {
        val count = minOf(MinigolfChallenge.FINISH_HOLES, scores.firstOrNull()?.size ?: 0)
        if (count <= 0) return scores.map { Raw(0, 0, false) }
        return scores.map { row ->
            val last = row.takeLast(count)
            if (!last.all { it > 0 }) Raw(Int.MIN_VALUE, 0, false)
            else {
                val total = last.sum()
                Raw(-total, total, true)
            }
        }
    }
}
