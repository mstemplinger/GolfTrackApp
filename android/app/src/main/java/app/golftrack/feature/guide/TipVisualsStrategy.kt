package app.golftrack.feature.guide

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.golftrack.ui.theme.AppTheme
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

// Nachbau von TipVisualsStrategy.swift.

private val water = rgb(0.12f, 0.42f, 0.78f)
private val sand = rgb(0.87f, 0.78f, 0.56f)
private val greenTurf = rgb(0.25f, 0.66f, 0.36f)

// MARK: - Course Management

private val spread = listOf(
    Offset(0f, 0f), Offset(0.85f, 0.3f), Offset(-0.6f, -0.55f), Offset(0.45f, -0.9f),
    Offset(-0.9f, 0.45f), Offset(0.95f, -0.25f), Offset(0.1f, 0.85f),
)

private class CourseLayout(val width: Float, val height: Float) {
    val greenCenter = Offset(width * 0.58f, height / 2)
    val greenRect = Rect(greenCenter.x - 66, greenCenter.y - 52, greenCenter.x + 66, greenCenter.y + 52)
    val pin = Offset(greenCenter.x + 44, greenCenter.y - 10)
    val water = Rect(greenCenter.x + 62, 18f, width - 8, height - 18)
    fun isOnGreen(p: Offset): Boolean {
        val dx = (p.x - greenCenter.x) / 66
        val dy = (p.y - greenCenter.y) / 52
        return dx * dx + dy * dy <= 1 && !water.contains(p)
    }
}

/** Streuung der Schläge: auf die Fahne neben dem Wasser gegen auf die Grünmitte. */
@Composable
internal fun CourseManagementVisual(color: Color) {
    val period = 4.0
    val t = rememberLoopSeconds()
    val pin = (t / period).toLong() % 2 == 0L
    val x = Loop.local(t, period)
    val visible = min(spread.size, max(0, ((x - 0.5) / 0.28).toInt() + 1))
    // Lage relativ zur Grünmitte ist breitenunabhängig, daher reicht eine feste Breite
    val layout = CourseLayout(325f, 210f)
    val aimRef = if (pin) layout.pin else layout.greenCenter
    val onGreen = spread.take(visible).count { layout.isOnGreen(Offset(aimRef.x + it.x * 40, aimRef.y + it.y * 30)) }
    TipVisualCard(210.dp, stage = { _, _ ->
        TipCanvas {
            val l = CourseLayout(w, h)
            val aim = if (pin) l.pin else l.greenCenter
            // Fairway, Wasser, Bunker, Grün
            roundRect(Rect(16f, l.greenCenter.y - 24, l.greenCenter.x - 24, l.greenCenter.y + 24), 24f, AppTheme.green.copy(alpha = 0.55f))
            roundRect(l.water, 22f, water)
            ellipse(l.greenRect, greenTurf)
            ellipse(Rect(l.greenCenter.x + 4, l.greenRect.bottom - 14, l.greenCenter.x + 48, l.greenRect.bottom + 8), sand)
            flag(l.pin, color, 26f)

            // Ziel und Streukreis
            val tee = Offset(30f, l.greenCenter.y)
            line(tee, aim, Color.White.copy(alpha = 0.4f), 1.2f, floatArrayOf(4f, 4f))
            strokeEllipse(Rect(aim.x - 44, aim.y - 33, aim.x + 44, aim.y + 33), Color.White.copy(alpha = 0.6f), 1.4f, floatArrayOf(3f, 3f))
            ball(tee, 5f)
            spread.take(visible).forEachIndexed { i, d ->
                val p = Offset(aim.x + d.x * 40, aim.y + d.y * 30)
                val ok = l.isOnGreen(p)
                circle(p, if (i == visible - 1) 6f else 5f, if (ok) Color.White else tipRed)
                if (!ok) ring(p, 8f, tipRed.copy(alpha = 0.6f), 1.5f)
            }
        }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            TipHint(
                if (pin) "Auf die Fahne: Fehlschläge landen im Wasser" else "Grünmitte: auch Fehlschläge bleiben auf dem Grün",
                if (pin) tipRed else color,
            )
            T("$onGreen von $visible auf dem Grün", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
            PhasePills(listOf("Auf die Fahne", "Grünmitte"), if (pin) 0 else 1, if (pin) tipRed else color)
        }
    }
}

// MARK: - Handicap klug nutzen

private val strokeIndex = listOf(7, 15, 3, 11, 1, 17, 9, 13, 5, 8, 16, 4, 12, 2, 18, 10, 14, 6)
private const val HCP = 9

/** 18 Löcher mit Schwierigkeitsindex: Vorgabeschläge fallen auf die schwersten Löcher. */
@Composable
internal fun HandicapStrokesVisual(color: Color) {
    val x = Loop.local(rememberLoopSeconds(), 7.5)
    // Stand der Verteilung: 0 … hcp, als Dezimalzahl für das Fallen
    val progress = max(0.0, (x - 0.5) / 0.45)
    TipVisualCard(170.dp, stage = { _, _ ->
        Column(
            Modifier.align(Alignment.Center).fillMaxWidth().padding(horizontal = 12.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(3.dp), verticalAlignment = Alignment.Bottom) {
                for (i in 0 until 18) {
                    val si = strokeIndex[i]
                    val drop = (progress - (si - 1)).coerceIn(0.0, 1.0)
                    val gets = si <= HCP
                    Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        DText("${i + 1}", 9f, AppTheme.textTer, FontWeight.Bold, maxLines = 1)
                        Box(Modifier.height(64.dp).fillMaxWidth(), contentAlignment = Alignment.BottomCenter) {
                            Box(
                                Modifier.fillMaxWidth().height((64 - si * 2.2f).dp),
                                contentAlignment = Alignment.TopCenter,
                            ) {
                                Box(
                                    Modifier.matchParentSize()
                                        .background(if (gets && drop >= 1) color.copy(alpha = 0.25f) else Color.White.copy(alpha = 0.07f), RoundedCornerShape(4.dp)),
                                )
                                if (gets && drop > 0) {
                                    Box(
                                        Modifier.offset(y = (-30 + 36 * Loop.smooth(drop)).toFloat().dp)
                                            .alpha(min(drop * 3, 1.0).toFloat())
                                            .size(9.dp).background(color, CircleShape),
                                    )
                                }
                            }
                        }
                        DText("$si", 9f, if (gets) color else AppTheme.textTer, if (gets) FontWeight.Black else FontWeight.Normal, maxLines = 1)
                    }
                }
            }
            Row {
                DText("Loch", 11f, AppTheme.textTer)
                Spacer(Modifier.weight(1f))
                DText("Höhe = Schwierigkeit, unten: SI", 11f, AppTheme.textTer)
            }
        }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            T("Handicap $HCP: je ein Vorgabeschlag auf SI 1–$HCP", IosFont.caption, AppTheme.text, FontWeight.Bold)
            TipHint("Ein Netto-Par auf den schwersten Löchern ist Gold wert", color)
        }
    }
}

// MARK: - Wind berücksichtigen

/** Seitenansicht: Flugbahn bei Gegen- und Rückenwind gegen die windstille Bahn. */
@Composable
internal fun WindVisual(color: Color) {
    val period = 3.6
    val t = rememberLoopSeconds()
    val head = (t / period).toLong() % 2 == 0L
    val x = Loop.local(t, period)
    TipVisualCard(200.dp, stage = { _, _ ->
        TipCanvas {
            val ground = h - 30
            val ball = Offset(28f, ground - 4)
            val calm = Offset(w * 0.7f, ground - 4)
            val end = if (head) Offset(w * 0.52f, ground - 4) else Offset(w * 0.86f, ground - 4)
            val calmControl = Offset((ball.x + calm.x) / 2, 10f)
            val control = if (head) Offset((ball.x + end.x) * 0.58f, -20f) else Offset((ball.x + end.x) / 2, 30f)

            line(Offset(10f, ground), Offset(w - 10, ground), Color.White.copy(alpha = 0.25f), 1f)
            // Windstriche ziehen in Windrichtung
            for (i in 0 until 7) {
                val raw = i * 53.0 + t * 60.0
                val span = (w + 60).toDouble()
                var px = (raw % span).toFloat() - 30
                if (head) px = w - px
                val py = 24f + (i * 37) % 90
                val dir = if (head) -1f else 1f
                line(Offset(px, py), Offset(px + dir * 22, py), Color.White.copy(alpha = 0.22f), 1.6f)
            }
            // Windstille Bahn als Vergleich
            stroke(quadPath(ball, calmControl, calm, 1.0), Color.White.copy(alpha = 0.3f), 1.4f, floatArrayOf(3f, 5f), StrokeCap.Butt)
            circle(calm, 3f, Color.White.copy(alpha = 0.4f))
            // Aktuelle Bahn
            val fly = Loop.ramp(x, 0.3, 1.8)
            stroke(quadPath(ball, control, end, fly), color, 2.2f)
            ball(quadPoint(ball, control, end, fly))
            if (x > 1.8) label(if (head) "−15 m" else "+12 m", Offset(end.x, ground + 14), color, 12f, FontWeight.Bold)
            label("windstill", Offset(calm.x, ground + 14), AppTheme.textTer)
        }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            TipHint(if (head) "Gegenwind: einen Schläger mehr, ruhiger schwingen" else "Rückenwind: der Ball fliegt und rollt weiter", color)
            PhasePills(listOf("Gegenwind", "Rückenwind"), if (head) 0 else 1, color)
        }
    }
}

// MARK: - Putt-Strategie

/** Draufsicht aufs Grün: erster Putt in die 50-cm-Zone, zweiter fest ins Loch. */
@Composable
internal fun PuttStrategyVisual(color: Color) {
    val x = Loop.local(rememberLoopSeconds(), 6.0)
    val second = x > 2.9
    TipVisualCard(190.dp, stage = { _, _ ->
        TipCanvas {
            val hole = Offset(w - 70, h / 2 - 6)
            val start = Offset(34f, h / 2 + 30)
            val rest = Offset(hole.x - 20, hole.y + 12)

            ellipse(Rect(8f, 14f, w - 8, h - 14), greenTurf.copy(alpha = 0.55f))
            // Zone
            circle(hole, 34f, color.copy(alpha = 0.14f))
            ring(hole, 34f, color, 1.6f, floatArrayOf(4f, 4f))
            label("50 cm", Offset(hole.x, hole.y - 44), color, 11f, FontWeight.Bold)
            circle(hole, 6f, Color.Black.copy(alpha = 0.7f))

            // Erster Putt mit leichtem Break, rollt aus
            val control = Offset((start.x + rest.x) / 2, start.y + 34)
            val roll1 = 1 - (1 - Loop.smooth((x - 0.4) / 2.0)).pow(2)
            val roll2 = Loop.ramp(x, 3.2, 3.9).toFloat()
            var ball = if (x < 0.4) start else quadPoint(start, control, rest, roll1.coerceIn(0.0, 1.0))
            stroke(quadPath(start, control, rest, roll1.coerceIn(0.001, 1.0)), Color.White.copy(alpha = 0.35f), 1.4f, floatArrayOf(2f, 4f), StrokeCap.Butt)
            if (second) {
                ball = Offset(rest.x + (hole.x - rest.x) * roll2, rest.y + (hole.y - rest.y) * roll2)
                line(rest, ball, Color.White.copy(alpha = 0.5f), 1.4f)
            }
            if (roll2 < 1) {
                ball(ball, 5f)
            } else {
                val r = Loop.ramp(x, 3.9, 4.5).toFloat()
                ring(hole, 9 + 8 * r, color.copy(alpha = 1 - r), 2f)
            }
            label("10 m", Offset(start.x + 4, start.y + 18), AppTheme.textTer, 11f, FontWeight.Bold)
        }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            TipHint(if (second) "Kurzer Putt: festes Tempo, aufs Loch schauen" else "Langer Putt: nur in die Zone, kein Dreiputt", color)
            PhasePills(listOf("1. Putt: Zone", "2. Putt: einlochen"), if (second) 1 else 0, color)
        }
    }
}

// MARK: - Risiko vs. Belohnung

/** Über das Wasser (Platsch, Strafschlag) gegen sicheres Vorlegen. */
@Composable
internal fun RiskRewardVisual(color: Color) {
    val period = 4.4
    val t = rememberLoopSeconds()
    val risky = (t / period).toLong() % 2 == 0L
    val x = Loop.local(t, period)
    TipVisualCard(210.dp, stage = { _, _ ->
        TipCanvas {
            val tee = Offset(30f, h - 36)
            val pin = Offset(w - 46, 54f)
            val pond = Rect(w / 2 - 62, 40f, w / 2 + 62, 136f)

            val fair = Path().apply {
                moveTo(18f, h - 14)
                quadraticTo(w / 2, h + 20, w - 20, 90f)
            }
            stroke(fair, AppTheme.green.copy(alpha = 0.6f), 38f)
            ellipse(pond, water)
            ellipse(Rect(pin.x - 38, pin.y - 26, pin.x + 38, pin.y + 26), greenTurf)
            flag(pin, color, 24f)
            circle(tee, 7f, Color.White.copy(alpha = 0.25f))

            if (risky) {
                val splash = Offset(pond.center.x + 26, pond.center.y - 6)
                val control = Offset((tee.x + splash.x) / 2, 10f)
                val fly = Loop.ramp(x, 0.3, 1.6)
                stroke(quadPath(tee, control, splash, fly), tipRed, 2f)
                if (fly < 1) {
                    ball(quadPoint(tee, control, splash, fly), 5f)
                } else {
                    for (k in 0 until 3) {
                        val r = Loop.ramp(x, 1.6 + k * 0.25, 2.8 + k * 0.25).toFloat()
                        ring(splash, 4 + 22 * r, Color.White.copy(alpha = 0.8f * (1 - r)), 1.6f)
                    }
                    label("+1 Strafschlag", Offset(splash.x, pond.bottom + 14), tipRed, 12f, FontWeight.Bold)
                }
            } else {
                val layup = Offset(w / 2 + 8, h - 46)
                val near = Offset(pin.x - 10, pin.y + 8)
                val c1 = Offset((tee.x + layup.x) / 2, h - 120)
                val c2 = Offset((layup.x + near.x) / 2 + 20, 40f)
                val f1 = Loop.ramp(x, 0.3, 1.4)
                val f2 = Loop.ramp(x, 1.8, 2.9)
                stroke(quadPath(tee, c1, layup, f1), color, 2f)
                if (x > 1.8) stroke(quadPath(layup, c2, near, f2), color, 2f)
                ball(if (x < 1.8) quadPoint(tee, c1, layup, f1) else quadPoint(layup, c2, near, f2), 5f)
            }
        }
    }) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            TipHint(
                if (risky) "Über das Wasser: geht es schief, droht ein Doppelbogey" else "Vorlegen: zwei sichere Schläge, Bogey im Sack",
                if (risky) tipRed else color,
            )
            PhasePills(listOf("Über das Wasser", "Vorlegen"), if (risky) 0 else 1, if (risky) tipRed else color)
        }
    }
}
