package app.golftrack.feature.profile

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Equalizer
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.SportsEsports
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.FlutterDash
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.data.GolfData
import app.golftrack.data.Prefs
import app.golftrack.ui.common.Haptics
import app.golftrack.feature.range.RangeClubDefaults
import app.golftrack.feature.range.RangeClubStats
import app.golftrack.feature.range.RangeSession
import app.golftrack.feature.range.RangeStore
import androidx.compose.ui.platform.LocalContext
import androidx.compose.material.icons.filled.EventAvailable
import androidx.compose.material.icons.filled.Apps
import androidx.compose.material.icons.filled.Hive
import androidx.compose.material.icons.filled.NorthEast
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.SportsGolf
import app.golftrack.ui.theme.AppTheme
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json

/** Errungenschaften wie `GCAchievement` – lokal ausgewertet, ohne Game Center. */
enum class Achievement(val key: String, val title: String, val description: String, val icon: ImageVector, val hint: String) {
    FIRST_ROUND("firstRound", "Erste Runde", "Schließe deine erste Runde ab", Icons.Filled.Flag,
        "Spiele eine vollständige Runde (alle Löcher eintragen) und schließe sie ab."),
    ROUNDS_10("rounds10", "10 Runden", "Schließe 10 Runden ab", Icons.Filled.Equalizer,
        "Spiele 10 Runden bis zum Ende. Jede abgeschlossene Runde zählt – egal auf welchem Platz."),
    ROUNDS_50("rounds50", "50 Runden", "Schließe 50 Runden ab", Icons.Filled.Equalizer,
        "Spiele 50 abgeschlossene Runden. Dein Fortschritt wird automatisch gespeichert."),
    FIRST_PAR("firstPar", "Erstes Par", "Spiele dein erstes Par", Icons.Filled.Flag,
        "Spiele auf einem Loch genau so viele Schläge wie der Par-Wert des Lochs beträgt (z. B. 4 Schläge auf Par 4)."),
    FIRST_BIRDIE("firstBirdie", "Erstes Birdie", "Spiele dein erstes Birdie", Icons.Filled.FlutterDash,
        "Spiele auf einem Loch einen Schlag weniger als Par (z. B. 3 Schläge auf Par 4). Ein toller Schlag!"),
    FIRST_EAGLE("firstEagle", "Erstes Eagle", "Spiele dein erstes Eagle", Icons.Filled.Star,
        "Spiele auf einem Loch zwei Schläge weniger als Par (z. B. 2 Schläge auf Par 4). Sehr selten und beeindruckend!"),
    HANDICAP_SUB_18("handicapSub18", "Handicap < 18", "Erreiche ein Handicap unter 18", Icons.Filled.Equalizer,
        "Senke dein Handicap auf unter 18. Das gelingt durch regelmäßiges Spielen und konstante Verbesserung."),
    HANDICAP_SUB_10("handicapSub10", "Handicap < 10", "Erreiche ein Handicap unter 10", Icons.Filled.Equalizer,
        "Senke dein Handicap auf unter 10. Das erfordert viel Übung – du bist dann ein sehr erfahrener Golfer!"),
    ALL_CATEGORIES("allCategories", "Alleskönner", "Schließe Runden auf 5 verschiedenen Plätzen ab", Icons.Filled.Map,
        "Schließe Runden auf 5 verschiedenen Golfplätzen ab. Erkunde neue Plätze in deiner Region oder auf Reisen."),
    // Driving Range
    FIRST_RANGE_SESSION("firstRangeSession", "Erste Range-Einheit", "Schließe deine erste Einheit auf der Driving Range ab", Icons.Filled.SportsGolf,
        "Starte auf der Startseite die Driving Range, trage ein paar Schläge ein und beende die Einheit."),
    RANGE_SESSIONS_10("rangeSessions10", "Range-Stammgast", "Schließe 10 Einheiten auf der Driving Range ab", Icons.Filled.EventAvailable,
        "Beende 10 Einheiten auf der Driving Range. Regelmäßiges Training zahlt sich auf dem Platz aus."),
    RANGE_SHOTS_100("rangeShots100", "100 Range-Bälle", "Trage 100 Schläge auf der Range ein", Icons.Filled.Apps,
        "Trage auf der Driving Range insgesamt 100 Schläge mit Schläger und Weite ein – über alle Einheiten zusammen."),
    RANGE_SHOTS_1000("rangeShots1000", "1000 Range-Bälle", "Trage 1000 Schläge auf der Range ein", Icons.Filled.Hive,
        "Trage auf der Driving Range insgesamt 1000 Schläge ein. Das ist echtes Fleißtraining!"),
    DRIVE_200("drive200", "200-m-Drive", "Schlage den Driver mindestens 200 m weit", Icons.Filled.NorthEast,
        "Trage auf der Driving Range einen Driver-Schlag mit mindestens 200 m ein."),
    DRIVE_250("drive250", "250-m-Drive", "Schlage den Driver mindestens 250 m weit", Icons.Filled.LocalFireDepartment,
        "Trage auf der Driving Range einen Driver-Schlag mit mindestens 250 m ein. Das schaffen nur sehr lange Hitter."),
    RANGE_FULL_BAG("rangeFullBag", "Ganzes Bag", "Schlage 10 verschiedene Schläger auf der Range", Icons.Filled.ShoppingBag,
        "Trainiere auf der Driving Range mit 10 verschiedenen Schlägern – nicht nur mit dem Driver."),
    RANGE_PERSONAL_BEST("rangePersonalBest", "Neue Bestweite", "Übertriff deine Bestweite mit einem Schläger", Icons.Filled.ShowChart,
        "Schlage einen Schläger in einer späteren Einheit weiter als jemals zuvor. Vergleiche dich auf der Range mit dir selbst."),
}

/** Fortschritt in Prozent je Errungenschaft, wie `gc_achievement_progress` auf iOS (steigt nur). */
object AchievementStore {
    private const val KEY = "gc_achievement_progress"
    private val json = Json { ignoreUnknownKeys = true }
    private val ser = MapSerializer(String.serializer(), Double.serializer())

    fun progress(): Map<String, Double> =
        runCatching { json.decodeFromString(ser, Prefs.string(KEY).ifEmpty { "{}" }) }.getOrDefault(emptyMap())

    /** Driving Range auswerten wie `evaluateRangeAchievements` auf iOS. */
    fun evaluateRange(sessions: List<RangeSession>): Map<String, Double> {
        val old = progress()
        val p = old.toMutableMap()
        var celebrate = false
        fun unlock(a: Achievement, pct: Double = 100.0) {
            val cur = p[a.key] ?: 0.0
            if (pct <= cur) return
            if (pct >= 100 && cur < 100) celebrate = true
            p[a.key] = pct
        }
        val finished = sessions.filter { it.endedAt != null && it.shots.isNotEmpty() }
        val shots = sessions.flatMap { it.shots }
        if (finished.isNotEmpty()) unlock(Achievement.FIRST_RANGE_SESSION)
        unlock(Achievement.RANGE_SESSIONS_10, minOf(100.0, finished.size / 10.0 * 100))
        unlock(Achievement.RANGE_SHOTS_100, minOf(100.0, shots.size / 100.0 * 100))
        unlock(Achievement.RANGE_SHOTS_1000, minOf(100.0, shots.size / 1000.0 * 100))
        val longestDrive = shots.filter { RangeClubDefaults.isDriver(it.clubName) }.maxOfOrNull { it.distanceMeters } ?: 0.0
        unlock(Achievement.DRIVE_200, minOf(100.0, longestDrive / 200.0 * 100))
        unlock(Achievement.DRIVE_250, minOf(100.0, longestDrive / 250.0 * 100))
        unlock(Achievement.RANGE_FULL_BAG, minOf(100.0, shots.map { it.clubName }.toSet().size / 10.0 * 100))
        if (hasBeatenEarlierBest(sessions)) unlock(Achievement.RANGE_PERSONAL_BEST)
        if (p != old) {
            Prefs.set(KEY, json.encodeToString(ser, p))
            if (celebrate) Haptics.celebrate()
        }
        return p
    }

    /**
     * Wahr, sobald ein Schläger in einer Einheit weiter flog als in allen
     * früheren Einheiten zusammen – die erste Einheit selbst zählt nicht.
     */
    private fun hasBeatenEarlierBest(sessions: List<RangeSession>): Boolean {
        val best = mutableMapOf<String, Double>()
        for (session in sessions.sortedBy { it.date }) {
            val stats = RangeClubStats.byClub(session.shots)
            if (stats.any { (club, s) -> best[club]?.let { s.best > it } == true }) return true
            stats.forEach { (club, s) -> best[club] = maxOf(best[club] ?: 0.0, s.best) }
        }
        return false
    }

    /** Wertet die abgeschlossenen Runden aus; gibt true zurück, wenn etwas neu freigeschaltet wurde. */
    fun evaluate(data: GolfData): Map<String, Double> {
        val old = progress()
        val p = old.toMutableMap()
        var celebrate = false
        fun unlock(a: Achievement, pct: Double = 100.0) {
            val cur = p[a.key] ?: 0.0
            if (pct <= cur) return
            if (pct >= 100 && cur < 100) celebrate = true
            p[a.key] = pct
        }
        val completed = data.completedRounds
        if (completed.isNotEmpty()) unlock(Achievement.FIRST_ROUND)
        unlock(Achievement.ROUNDS_10, minOf(100.0, completed.size / 10.0 * 100))
        unlock(Achievement.ROUNDS_50, minOf(100.0, completed.size / 50.0 * 100))
        var par = false; var birdie = false; var eagle = false
        for (r in completed) {
            val c = data.course(r.courseId) ?: continue
            for (h in r.holeScores) {
                val parV = c.parValues.getOrNull(h.holeNumber - 1) ?: continue
                if (h.strokes <= 0) continue
                if (h.strokes == parV) par = true
                if (h.strokes == parV - 1) birdie = true
                if (h.strokes <= parV - 2) eagle = true
            }
        }
        if (par) unlock(Achievement.FIRST_PAR)
        if (birdie) unlock(Achievement.FIRST_BIRDIE)
        if (eagle) unlock(Achievement.FIRST_EAGLE)
        val courseCount = completed.mapNotNull { data.course(it.courseId)?.name }.toSet().size
        unlock(Achievement.ALL_CATEGORIES, minOf(100.0, courseCount / 5.0 * 100))
        if (p != old) {
            Prefs.set(KEY, json.encodeToString(ser, p))
            // Frisch freigeschaltet – spürbar machen.
            if (celebrate && old.isNotEmpty()) Haptics.celebrate()
        }
        return p
    }
}

@Composable
internal fun AchievementsCard(data: GolfData) {
    var progress by remember { mutableStateOf(AchievementStore.progress()) }
    val ctx = LocalContext.current
    LaunchedEffect(data.completedRounds.size) {
        AchievementStore.evaluate(data)
        RangeStore.init(ctx)
        progress = AchievementStore.evaluateRange(RangeStore.data.value.sessions)
    }
    var selected by remember { mutableStateOf<Achievement?>(null) }

    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text("Errungenschaften", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                Text("Lokal auf diesem Gerät", color = AppTheme.textSec, fontSize = 12.sp)
            }
            Icon(Icons.Filled.SportsEsports, null, tint = AppTheme.gold)
        }
        HorizontalDivider(color = AppTheme.cardAlt)
        Achievement.entries.chunked(2).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                row.forEach { a ->
                    val pct = progress[a.key] ?: 0.0
                    Badge(a, pct >= 100, pct, Modifier.weight(1f)) { Haptics.tap(); selected = a }
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }
    }

    selected?.let { a ->
        val pct = progress[a.key] ?: 0.0
        AchievementDetailSheet(a, pct >= 100, pct) { selected = null }
    }
}

@Composable
private fun Badge(a: Achievement, unlocked: Boolean, progress: Double, modifier: Modifier, onClick: () -> Unit) {
    Column(
        modifier.background(if (unlocked) AppTheme.gold.copy(alpha = 0.07f) else AppTheme.cardAlt, RoundedCornerShape(12.dp))
            .clickable { onClick() }.padding(vertical = 10.dp, horizontal = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        AchievementIcon(a, unlocked, progress, 44.dp, if (unlocked) AppTheme.gold.copy(alpha = 0.2f) else AppTheme.cardAlt, 2.dp)
        Text(
            a.title, color = if (unlocked) AppTheme.text else AppTheme.textTer, fontSize = 10.sp,
            fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center, maxLines = 2,
        )
    }
}

@Composable
private fun AchievementIcon(a: Achievement, unlocked: Boolean, progress: Double, size: Dp, fill: Color, ring: Dp) {
    Box(Modifier.size(size), contentAlignment = Alignment.Center) {
        Box(Modifier.size(size).background(fill, CircleShape))
        Icon(a.icon, null, tint = if (unlocked) AppTheme.gold else AppTheme.textTer, modifier = Modifier.size(size * 0.42f))
        if (!unlocked && progress > 0) {
            Canvas(Modifier.size(size)) {
                val w = ring.toPx()
                drawArc(
                    AppTheme.gold.copy(alpha = 0.55f), -90f, (progress / 100 * 360).toFloat(), false,
                    topLeft = Offset(w / 2, w / 2), size = Size(this.size.width - w, this.size.height - w),
                    style = Stroke(w, cap = StrokeCap.Round),
                )
            }
        }
    }
}

/** Wie AchievementDetailSheet.swift. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AchievementDetailSheet(a: Achievement, unlocked: Boolean, progress: Double, onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = Color(0xFF0F2414)) {
        Column(
            Modifier.fillMaxWidth().navigationBarsPadding().padding(bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            AchievementIcon(a, unlocked, progress, 80.dp, if (unlocked) AppTheme.gold.copy(alpha = 0.2f) else Color.White.copy(alpha = 0.08f), 3.dp)
            Spacer(Modifier.height(16.dp))
            Text(
                if (unlocked) "Erreicht ✓" else if (progress > 0) "In Arbeit" else "Noch gesperrt",
                color = if (unlocked) AppTheme.gold else Color.White.copy(alpha = 0.4f), fontSize = 12.sp, fontWeight = FontWeight.Bold,
                modifier = Modifier.background(if (unlocked) AppTheme.gold.copy(alpha = 0.15f) else Color.White.copy(alpha = 0.07f), CircleShape)
                    .padding(horizontal = 12.dp, vertical = 4.dp),
            )
            Spacer(Modifier.height(14.dp))
            Text(a.title, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            Spacer(Modifier.height(8.dp))
            Text(
                a.description, color = Color.White.copy(alpha = 0.6f), fontSize = 15.sp, textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 32.dp),
            )
            Spacer(Modifier.height(20.dp))
            if (!unlocked && progress > 0) {
                Box(Modifier.padding(horizontal = 32.dp).fillMaxWidth().height(6.dp).background(Color.White.copy(alpha = 0.08f), RoundedCornerShape(4.dp))) {
                    Box(Modifier.fillMaxWidth((progress / 100).toFloat()).height(6.dp).background(AppTheme.gold.copy(alpha = 0.7f), RoundedCornerShape(4.dp)))
                }
                Spacer(Modifier.height(6.dp))
                Text("${progress.toInt()} %", color = Color.White.copy(alpha = 0.4f), fontSize = 12.sp)
                Spacer(Modifier.height(20.dp))
            }
            Row(
                Modifier.padding(horizontal = 24.dp).fillMaxWidth().background(Color.White.copy(alpha = 0.06f), RoundedCornerShape(14.dp)).padding(16.dp),
            ) {
                Icon(Icons.Filled.Lightbulb, null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(10.dp))
                Text(a.hint, color = Color.White.copy(alpha = 0.75f), fontSize = 15.sp)
            }
        }
    }
}
