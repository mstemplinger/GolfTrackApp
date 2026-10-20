package app.golftrack.data

import kotlin.math.abs
import kotlin.math.roundToLong

/** Wie HandicapCalculator.swift (WHS). `rounds` neueste zuerst, nur abgeschlossene. */
object HandicapCalculator {
    fun scoreDifferential(grossScore: Int, courseRating: Double, slopeRating: Int): Double {
        val slope = slopeRating.coerceIn(55, 155).toDouble()
        return (113.0 / slope) * (grossScore - courseRating)
    }

    fun bestCount(roundCount: Int): Int = when (roundCount) {
        in 3..5 -> 1
        in 6..8 -> 2
        in 9..11 -> 3
        in 12..14 -> 4
        in 15..16 -> 5
        in 17..18 -> 6
        19 -> 7
        else -> 8
    }

    data class ProgressInfo(
        val usedRounds: Int,
        val eligibleRounds: Int,
        val bestDifferentials: List<Double>,
        val allDifferentials: List<Double>,
        val handicapIndex: Double,
    )

    private fun differentials(rounds: List<Round>, data: GolfData): List<Double> =
        rounds.take(20).mapNotNull { r ->
            val c = data.course(r.courseId) ?: return@mapNotNull null
            if (r.totalStrokes <= 0 || c.courseRating <= 0 || c.slopeRating <= 0) null
            else scoreDifferential(r.totalStrokes, c.courseRating, c.slopeRating)
        }

    fun progressInfo(rounds: List<Round>, data: GolfData): ProgressInfo? {
        if (rounds.take(20).size < 3) return null
        val diffs = differentials(rounds, data)
        if (diffs.size < 3) return null
        val count = bestCount(diffs.size)
        val best = diffs.sorted().take(count)
        val index = maxOf(0.0, (best.average() * 0.96 * 10).roundToLong() / 10.0)
        return ProgressInfo(count, diffs.size, best, diffs, index)
    }

    fun handicapIndex(rounds: List<Round>, data: GolfData): Double? = progressInfo(rounds, data)?.handicapIndex

    fun displayString(rounds: List<Round>, data: GolfData): String =
        handicapIndex(rounds, data)?.let { String.format(java.util.Locale.GERMANY, "%.1f", it) } ?: "–"
}

data class MatchplayStatus(val holesUp: Int, val holesPlayed: Int, val totalHoles: Int, val isFinished: Boolean) {
    val holesRemaining: Int get() = totalHoles - holesPlayed
    val statusLabel: String
        get() {
            if (holesPlayed <= 0) return "Noch nicht gestartet"
            if (isFinished) {
                if (holesUp > 0) return "$holesUp&$holesRemaining gewonnen"
                if (holesUp < 0) return "${abs(holesUp)}&$holesRemaining verloren"
                return "All Square – Stechen"
            }
            if (holesUp == 0) return "All Square nach $holesPlayed"
            val ud = if (holesUp > 0) "Up" else "Down"
            return "${abs(holesUp)} $ud nach $holesPlayed"
        }
    val playerLeads: Boolean get() = holesUp > 0
    val opponentLeads: Boolean get() = holesUp < 0
}

enum class HoleOutcome(val shortLabel: String) { PLAYER("W"), OPPONENT("L"), HALVED("H"), NOT_PLAYED("·") }

data class SkinsSummary(
    val skinsPerPlayer: Map<Int, Int> = emptyMap(),
    /** Loch → Sieger-Index (-1 = geteilt/übertragen). */
    val holeWinners: Map<Int, Int> = emptyMap(),
    val openSkins: Int = 0,
)

data class EradoResult(val total: Int, val scratchedHoles: Set<Int>)

/** Wie GameScoringEngine.swift. Spieler 0 = Hauptspieler (`holeScores`), 1… = `playerHoleScores`. */
object GameScoringEngine {
    fun matchplayHoleOutcome(playerStrokes: Int, opponentStrokes: Int): HoleOutcome = when {
        playerStrokes <= 0 || opponentStrokes <= 0 -> HoleOutcome.NOT_PLAYED
        playerStrokes < opponentStrokes -> HoleOutcome.PLAYER
        playerStrokes > opponentStrokes -> HoleOutcome.OPPONENT
        else -> HoleOutcome.HALVED
    }

    private fun matchStatus(round: Round, holeValues: (HoleScore) -> Pair<Int, Int>?): MatchplayStatus {
        val sorted = round.sortedScores
        val total = sorted.size
        var up = 0
        var played = 0
        for (hs in sorted) {
            val (mine, theirs) = holeValues(hs) ?: continue
            played++
            when (matchplayHoleOutcome(mine, theirs)) {
                HoleOutcome.PLAYER -> up++
                HoleOutcome.OPPONENT -> up--
                else -> {}
            }
            if (abs(up) > total - played) return MatchplayStatus(up, played, total, true)
        }
        return MatchplayStatus(up, played, total, played == total)
    }

    fun matchplayStatus(round: Round): MatchplayStatus = matchStatus(round) { hs ->
        val opp = round.opponentScore(1, hs.holeNumber)
        if (hs.strokes > 0 && opp != null && opp.strokes > 0) hs.strokes to opp.strokes else null
    }

    fun betterBallMatchplayStatus(round: Round): MatchplayStatus = matchStatus(round) { hs ->
        if (hs.strokes <= 0) return@matchStatus null
        val opp1 = round.opponentScore(2, hs.holeNumber)?.takeIf { it.strokes > 0 } ?: return@matchStatus null
        val partner = round.opponentScore(1, hs.holeNumber)?.takeIf { it.strokes > 0 }
        val myBest = partner?.let { minOf(hs.strokes, it.strokes) } ?: hs.strokes
        val opp2 = round.opponentScore(3, hs.holeNumber)?.takeIf { it.strokes > 0 }
        val oppBest = opp2?.let { minOf(opp1.strokes, it.strokes) } ?: opp1.strokes
        myBest to oppBest
    }

    fun skinsResult(round: Round): SkinsSummary {
        val n = round.otherPlayerNames.size
        if (n <= 0) return SkinsSummary()
        val perPlayer = mutableMapOf<Int, Int>()
        val winners = mutableMapOf<Int, Int>()
        var carry = 0
        for (hs in round.sortedScores) {
            if (hs.strokes <= 0) continue
            val scores = mutableListOf(0 to hs.strokes)
            var all = true
            for (i in 1..n) {
                val opp = round.opponentScore(i, hs.holeNumber)
                if (opp != null && opp.strokes > 0) scores += i to opp.strokes else { all = false; break }
            }
            if (!all) continue
            val min = scores.minOf { it.second }
            val w = scores.filter { it.second == min }
            if (w.size == 1) {
                perPlayer[w[0].first] = (perPlayer[w[0].first] ?: 0) + 1 + carry
                winners[hs.holeNumber] = w[0].first
                carry = 0
            } else {
                winners[hs.holeNumber] = -1
                carry++
            }
        }
        return SkinsSummary(perPlayer, winners, carry)
    }

    fun betterBallHoleValue(holeScore: HoleScore, partnerScore: PlayerHoleScore?, par: Int, stableford: Boolean): Int {
        val ps = holeScore.strokes
        val pp = partnerScore?.strokes ?: 0
        return if (stableford) {
            maxOf(
                if (ps > 0) GameMode.stablefordPoints(ps, par) else 0,
                if (pp > 0) GameMode.stablefordPoints(pp, par) else 0,
            )
        } else when {
            ps <= 0 -> pp
            pp <= 0 -> ps
            else -> minOf(ps, pp)
        }
    }

    fun betterBallTeamTotal(round: Round, course: Course?, stableford: Boolean): Int {
        if (course == null) return 0
        return round.sortedScores.sumOf { hs ->
            if (hs.strokes <= 0) return@sumOf 0
            val par = course.parValues.getOrNull(hs.holeNumber - 1) ?: return@sumOf 0
            betterBallHoleValue(hs, round.opponentScore(1, hs.holeNumber), par, stableford)
        }
    }

    fun bestBallHoleValue(round: Round, holeScore: HoleScore, par: Int, stableford: Boolean): Int {
        val strokes = buildList {
            if (holeScore.strokes > 0) add(holeScore.strokes)
            for (i in 1..3) round.opponentScore(i, holeScore.holeNumber)?.takeIf { it.strokes > 0 }?.let { add(it.strokes) }
        }
        if (strokes.isEmpty()) return 0
        return if (stableford) strokes.maxOf { GameMode.stablefordPoints(it, par) } else strokes.min()
    }

    fun bestBallTeamTotal(round: Round, course: Course?, stableford: Boolean): Int {
        if (course == null) return 0
        return round.sortedScores.sumOf { hs ->
            val par = course.parValues.getOrNull(hs.holeNumber - 1) ?: return@sumOf 0
            bestBallHoleValue(round, hs, par, stableford)
        }
    }

    fun eradoResult(round: Round, course: Course?): EradoResult {
        if (course == null) return EradoResult(round.totalStrokes, emptySet())
        val played = round.playedScores
        if (played.isEmpty()) return EradoResult(0, emptySet())
        val scratchCount = if (course.numberOfHoles >= 18) 2 else 1
        data class D(val hole: Int, val strokes: Int, val diff: Int)
        val holes = played.mapNotNull { s ->
            course.parValues.getOrNull(s.holeNumber - 1)?.let { D(s.holeNumber, s.strokes, s.strokes - it) }
        }
        val scratched = holes.sortedByDescending { it.diff }.take(scratchCount).map { it.hole }.toSet()
        return EradoResult(holes.filter { it.hole !in scratched }.sumOf { it.strokes }, scratched)
    }
}
