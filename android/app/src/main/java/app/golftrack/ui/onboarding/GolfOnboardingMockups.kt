package app.golftrack.ui.onboarding

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.BatteryFull
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.FormatListNumbered
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.SignalCellularAlt
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.WbCloudy
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.Wifi
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.R
import app.golftrack.ui.common.LaterBadge
import app.golftrack.ui.theme.AppTheme

// Nachgebaute App-Ansichten für die Golf-Einführung (GolfOnboardingMockups.swift).
// Gebaut für die feste Zeichenfläche `OnbCanvas` und in `OnbStage` auf den
// Bildschirm skaliert, darum stehen hier echte Schriftgrößen statt Mini-Werten.

internal object OnbCanvas {
    /** Zeichenfläche mit etwas Luft um das Gerät für dessen Schatten. */
    val width = 310.dp
    val height = 640.dp
    val phoneWidth = 296.dp
    val phoneHeight = 628.dp
    /** Willkommen und Abschluss zeigen kein Gerät und nutzen die Breite. */
    val wideWidth = 380.dp
    val wideHeight = 600.dp
}

private val onbDarkText = Color(0xFF0F2414)

// --- Gerät ---

/** Telefonrahmen mit Kamera-Aussparung, mittig in der Zeichenfläche. */
@Composable
private fun OnbPhone(content: @Composable BoxScope.() -> Unit) {
    Box(Modifier.size(OnbCanvas.width, OnbCanvas.height), contentAlignment = Alignment.Center) {
        Box(
            Modifier.size(OnbCanvas.phoneWidth, OnbCanvas.phoneHeight)
                .shadow(26.dp, RoundedCornerShape(46.dp))
                .background(Color(0xFF1A1A1A), RoundedCornerShape(46.dp))
                .border(2.dp, Brush.linearGradient(listOf(Color.White.copy(alpha = 0.28f), Color.White.copy(alpha = 0.06f))), RoundedCornerShape(46.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Box(
                Modifier.size(OnbCanvas.phoneWidth - 16.dp, OnbCanvas.phoneHeight - 16.dp)
                    .clip(RoundedCornerShape(38.dp)).background(AppTheme.bg),
                content = content,
            )
            Box(Modifier.align(Alignment.TopCenter).padding(top = 22.dp).size(14.dp).background(Color.Black, CircleShape))
        }
    }
}

@Composable
private fun OnbStatusBar() {
    Row(Modifier.fillMaxWidth().height(50.dp).padding(horizontal = 28.dp), verticalAlignment = Alignment.CenterVertically) {
        Text("9:41", color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.weight(1f))
        listOf(Icons.Filled.SignalCellularAlt, Icons.Filled.Wifi, Icons.Filled.BatteryFull).forEach {
            Icon(it, null, tint = Color.White, modifier = Modifier.padding(start = 3.dp).size(13.dp))
        }
    }
}

/** Bildschirm mit Statusleiste und – falls gesetzt – der Tab-Leiste. */
@Composable
private fun OnbScreen(tab: Int? = null, content: @Composable ColumnScope.() -> Unit) {
    Box(Modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            OnbStatusBar()
            content()
        }
        if (tab != null) OnbTabBar(tab, Modifier.align(Alignment.BottomCenter).padding(start = 12.dp, end = 12.dp, bottom = 14.dp))
    }
}

private val tabItems = listOf(
    Icons.Filled.Home to "Home", Icons.Filled.SportsGolf to "Training", Icons.AutoMirrored.Filled.MenuBook to "Regeln",
    Icons.Filled.Lightbulb to "Tipps", Icons.Filled.Person to "Profil",
)

@Composable
private fun OnbTabBar(selected: Int, modifier: Modifier) {
    Row(
        modifier.fillMaxWidth().shadow(10.dp, CircleShape).background(Color(0xF5123020), CircleShape)
            .border(1.dp, Color.White.copy(alpha = 0.10f), CircleShape).padding(4.dp),
    ) {
        tabItems.forEachIndexed { i, (icon, label) ->
            val c = if (i == selected) AppTheme.gold else Color.White.copy(alpha = 0.85f)
            Column(
                Modifier.weight(1f).background(if (i == selected) Color.White.copy(alpha = 0.10f) else Color.Transparent, CircleShape).padding(vertical = 6.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Icon(icon, null, tint = c, modifier = Modifier.size(15.dp))
                Text(label, color = c, fontSize = 8.sp, fontWeight = FontWeight.Medium)
            }
        }
    }
}

private fun Modifier.onbCard(radius: Dp = 16.dp, padding: Dp = 12.dp): Modifier =
    fillMaxWidth().background(AppTheme.card, RoundedCornerShape(radius)).padding(padding)

/** Pulsierender Goldrahmen um das Element, um das es auf der Seite geht. */
@Composable
private fun Modifier.onbHighlight(active: Boolean, radius: Dp = 14.dp): Modifier {
    val pulse by rememberInfiniteTransition(label = "pulse").animateFloat(
        0.45f, 1f, infiniteRepeatable(tween(900), RepeatMode.Reverse), label = "pulse",
    )
    return border(2.5.dp, AppTheme.gold.copy(alpha = if (active) pulse else 0f), RoundedCornerShape(radius + 4.dp))
}

/** Erscheinen mit Verzögerung, sobald die Seite sichtbar ist. */
@Composable
private fun Modifier.onbAppear(active: Boolean, index: Int, dx: Dp = 0.dp, dy: Dp = 12.dp, baseDelay: Int = 0): Modifier {
    val p by animateFloatAsState(
        if (active) 1f else 0f,
        if (active) tween(450, delayMillis = baseDelay + 50 * index) else tween(0),
        label = "appear",
    )
    return alpha(p).offset(x = dx * (1 - p), y = dy * (1 - p))
}

@Composable
private fun AppLogo(size: Dp, radius: Dp) {
    Image(
        painterResource(R.mipmap.ic_launcher), null, contentScale = ContentScale.Crop,
        modifier = Modifier.size(size).shadow(16.dp, RoundedCornerShape(radius), spotColor = AppTheme.gold).clip(RoundedCornerShape(radius)),
    )
}

@Composable
private fun GoldPill(text: String, modifier: Modifier = Modifier, fontSize: Int = 14) {
    Box(
        modifier.fillMaxWidth().background(AppTheme.gold, RoundedCornerShape(13.dp)).padding(vertical = 12.dp),
        contentAlignment = Alignment.Center,
    ) { Text(text, color = onbDarkText, fontSize = fontSize.sp, fontWeight = FontWeight.Bold) }
}

@Composable
private fun SmallLabel(text: String) =
    Text(text.uppercase(), color = AppTheme.textSec, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.sp)

// --- Willkommen ---

/** Raster aller Bereiche – füllt die Bühne statt eines einzelnen Symbols. */
@Composable
internal fun OnbWelcomeVisual(active: Boolean) {
    val tiles = listOf(
        Icons.Filled.FormatListNumbered to "Zählkarte", Icons.Filled.MyLocation to "GPS-Distanzen",
        Icons.Filled.ShoppingBag to "Schläger & Bag", Icons.Filled.ShowChart to "WHS-Handicap",
        Icons.AutoMirrored.Filled.DirectionsWalk to "Laufspur", Icons.Filled.WbCloudy to "Golf-Wetter",
        Icons.Filled.Headphones to "Audio-Training", Icons.Filled.SportsGolf to "Driving Range",
        Icons.Filled.School to "Platzreife", Icons.Filled.EmojiEvents to "Minigolf",
    )
    Column(
        Modifier.size(OnbCanvas.wideWidth, OnbCanvas.wideHeight).padding(horizontal = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(22.dp, Alignment.CenterVertically),
    ) {
        AppLogo(92.dp, 22.dp)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            tiles.chunked(2).forEachIndexed { r, row ->
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    row.forEachIndexed { c, (icon, label) ->
                        Row(
                            Modifier.weight(1f).onbAppear(active, r * 2 + c)
                                .background(AppTheme.card, RoundedCornerShape(16.dp))
                                .border(1.dp, Color.White.copy(alpha = 0.06f), RoundedCornerShape(16.dp)).padding(9.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(Modifier.size(38.dp).background(AppTheme.gold.copy(alpha = 0.14f), RoundedCornerShape(11.dp)), contentAlignment = Alignment.Center) {
                                Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(19.dp))
                            }
                            Spacer(Modifier.width(10.dp))
                            Text(label, color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        }
                    }
                }
            }
        }
    }
}

// --- Startseite ---

@Composable
internal fun OnbHomeMock(active: Boolean) {
    OnbPhone {
        OnbScreen(tab = 0) {
            Column(Modifier.padding(horizontal = 14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    AppLogo(28.dp, 7.dp)
                    Spacer(Modifier.width(8.dp))
                    Text("GolfTrack", color = Color.White, fontSize = 19.sp, fontWeight = FontWeight.Bold)
                }
                Row(Modifier.onbCard(), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text("Willkommen zurück,", color = AppTheme.textSec, fontSize = 11.sp)
                        Text("Alex!", color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                    }
                    Icon(Icons.Filled.WbSunny, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("19°", color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                }
                // Platz in der Nähe – darum geht es auf dieser Seite.
                Row(Modifier.onbHighlight(active).onbCard(14.dp, 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Flag, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.weight(1f)) {
                        Text("Du bist hier", color = AppTheme.gold, fontSize = 9.sp, fontWeight = FontWeight.SemiBold)
                        Text("Golfclub Bayerwald", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                    Text(
                        "Starten", color = onbDarkText, fontSize = 11.sp, fontWeight = FontWeight.Bold,
                        modifier = Modifier.background(AppTheme.gold, CircleShape).padding(horizontal = 10.dp, vertical = 6.dp),
                    )
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    MiniStat("Handicap", "18.4", "WHS", Modifier.weight(1f))
                    MiniStat("Letzte Runde", "86", "+14", Modifier.weight(1f))
                }
                // Golf-Wetter als Stundenverlauf
                Column(Modifier.onbCard(14.dp, 10.dp), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.WbCloudy, null, tint = Color.White, modifier = Modifier.size(12.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Golf-Wetter", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                        Text("10–15", color = AppTheme.gold, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                    }
                    val levels = listOf(0.35f, 0.5f, 0.8f, 0.9f, 1f, 0.95f, 0.85f, 0.6f, 0.4f, 0.3f)
                    Row(Modifier.height(30.dp), horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.Bottom) {
                        levels.forEachIndexed { i, l ->
                            Box(Modifier.weight(1f).height(30.dp * l).background(if (i in 2..6) AppTheme.gold else AppTheme.cardAlt, RoundedCornerShape(3.dp)))
                        }
                    }
                }
                GoldIconPill("Neue Runde spielen", Icons.Filled.AddCircle)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    GreenMini("Platzreife lernen", Icons.Filled.School, Modifier.weight(1f))
                    GreenMini("Verlauf", Icons.Filled.History, Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun MiniStat(title: String, value: String, sub: String, modifier: Modifier) {
    Column(modifier.background(AppTheme.card, RoundedCornerShape(14.dp)).padding(10.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(title, color = AppTheme.textSec, fontSize = 10.sp)
        Text(value, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
        Text(sub, color = AppTheme.gold, fontSize = 9.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun GoldIconPill(text: String, icon: ImageVector) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.gold, RoundedCornerShape(13.dp)).padding(vertical = 12.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = onbDarkText, modifier = Modifier.size(15.dp))
        Spacer(Modifier.width(6.dp))
        Text(text, color = onbDarkText, fontSize = 14.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun GreenMini(text: String, icon: ImageVector, modifier: Modifier) {
    Row(
        modifier.background(AppTheme.greenMid, RoundedCornerShape(12.dp)).padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = Color.White, modifier = Modifier.size(12.dp))
        Spacer(Modifier.width(4.dp))
        Text(text, color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
    }
}

// --- Neue Runde ---

@Composable
internal fun OnbNewRoundMock(active: Boolean) {
    OnbPhone {
        OnbScreen {
            Column(Modifier.padding(horizontal = 14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(Modifier.fillMaxWidth()) {
                    Text("Abbrechen", color = AppTheme.gold, fontSize = 13.sp, modifier = Modifier.align(Alignment.CenterStart))
                    Text("Neue Runde", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold, modifier = Modifier.align(Alignment.Center))
                }
                MockSection("Platz") {
                    Row(Modifier.onbHighlight(active).onbCard(14.dp, 10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(32.dp).background(AppTheme.gold, RoundedCornerShape(9.dp)), contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.Flag, null, tint = onbDarkText, modifier = Modifier.size(15.dp))
                        }
                        Spacer(Modifier.width(10.dp))
                        Column(Modifier.weight(1f)) {
                            Text("Golfclub Bayerwald", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                            Text("18 Löcher · Par 72", color = AppTheme.textSec, fontSize = 10.sp)
                        }
                        Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(14.dp))
                    }
                }
                MockSection("Spielform") {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        MockChip("Zählspiel", true); MockChip("Stableford", false); MockChip("Matchplay", false)
                    }
                }
                MockSection("Bag") {
                    Row(Modifier.onbCard(14.dp, 10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.ShoppingBag, null, tint = AppTheme.gold, modifier = Modifier.size(15.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Mein Bag", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                        Text("14 Schläger", color = AppTheme.textSec, fontSize = 11.sp)
                    }
                }
                MockSection("Abschlag") {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        listOf(Color.White, Color(0xFFFFD60A), Color(0xFF0A84FF), Color(0xFFFF453A)).forEachIndexed { i, c ->
                            Box(
                                Modifier.size(26.dp).background(c, CircleShape)
                                    .border(2.dp, if (i == 1) AppTheme.gold else Color.Transparent, CircleShape),
                            )
                        }
                    }
                }
                MockSection("Spieler") {
                    Column(Modifier.onbCard(14.dp, 10.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(28.dp).background(AppTheme.gold, CircleShape), contentAlignment = Alignment.Center) {
                                Text("A", color = onbDarkText, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                            }
                            Spacer(Modifier.width(8.dp))
                            Text("Alex", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            Text("HCP 18.4", color = AppTheme.textSec, fontSize = 10.sp, fontWeight = FontWeight.SemiBold)
                        }
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.AddCircle, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                            Spacer(Modifier.width(6.dp))
                            Text("Spieler hinzufügen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
                GoldPill("Runde starten")
            }
        }
    }
}

@Composable
private fun MockSection(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(5.dp)) {
        SmallLabel(title)
        content()
    }
}

@Composable
private fun MockChip(title: String, selected: Boolean) {
    Text(
        title, color = if (selected) onbDarkText else Color.White, fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
        modifier = Modifier.background(if (selected) AppTheme.gold else AppTheme.card, CircleShape).padding(horizontal = 11.dp, vertical = 7.dp),
    )
}

// --- Zählen ---

@Composable
internal fun OnbScoringMock(active: Boolean) {
    OnbPhone {
        OnbScreen {
            Column(Modifier.padding(horizontal = 14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(verticalAlignment = Alignment.Bottom) {
                    Column(Modifier.weight(1f)) {
                        Text("AKTUELLES LOCH", color = AppTheme.gold, fontSize = 9.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.5.sp)
                        Text("07", color = Color.White, fontSize = 52.sp, fontWeight = FontWeight.Black)
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text("PAR 4", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.sp)
                        Text("Par", color = AppTheme.textSec, fontSize = 10.sp)
                    }
                }
                Row(Modifier.onbHighlight(active).onbCard(14.dp, 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.MyLocation, null, tint = AppTheme.gold, modifier = Modifier.size(15.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Noch 142 m zum Loch", color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                    Text(
                        "LIVE", color = onbDarkText, fontSize = 8.sp, fontWeight = FontWeight.Black,
                        modifier = Modifier.background(AppTheme.gold, CircleShape).padding(horizontal = 6.dp, vertical = 3.dp),
                    )
                }
                Row(Modifier.onbCard(14.dp, 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column {
                        Text("EMPFOHLEN", color = AppTheme.gold, fontSize = 8.sp, fontWeight = FontWeight.Black, letterSpacing = 1.sp)
                        Text("7i", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Black)
                    }
                    Spacer(Modifier.width(10.dp))
                    Text("Ø 140 m", color = AppTheme.textSec, fontSize = 11.sp, modifier = Modifier.weight(1f))
                    listOf("8i", "6i").forEach {
                        Text(
                            it, color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(start = 6.dp).background(AppTheme.cardAlt, CircleShape).padding(horizontal = 9.dp, vertical = 5.dp),
                        )
                    }
                }
                Column(Modifier.onbCard(16.dp, 12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("SCHLÄGE", color = AppTheme.textSec, fontSize = 9.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 2.sp)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        RoundMini("−")
                        Text("4", color = Color.White, fontSize = 60.sp, fontWeight = FontWeight.Black, modifier = Modifier.padding(horizontal = 26.dp))
                        RoundMini("+", gold = true)
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    MiniValue("Putts", "2", Modifier.weight(1f))
                    MiniToggle("Fairway", true, Modifier.weight(1f))
                    MiniToggle("GIR", false, Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    (1..9).forEach { n ->
                        val cur = n == 7
                        Box(
                            Modifier.weight(1f).height(24.dp).background(
                                if (cur) AppTheme.gold else if (n < 7) AppTheme.cardAlt else AppTheme.card, RoundedCornerShape(6.dp),
                            ),
                            contentAlignment = Alignment.Center,
                        ) { Text("$n", color = if (cur) onbDarkText else Color.White, fontSize = 10.sp, fontWeight = FontWeight.Bold) }
                    }
                }
                Row(Modifier.onbCard(14.dp, 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("SCORE GESAMT", color = AppTheme.textSec, fontSize = 9.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.5.sp, modifier = Modifier.weight(1f))
                    Text("27", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.width(6.dp))
                    Text("+3", color = Color(0xFFFFBF4D), fontSize = 12.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
private fun RoundMini(sign: String, gold: Boolean = false) {
    Box(Modifier.size(44.dp).background(if (gold) AppTheme.gold else AppTheme.cardAlt, CircleShape), contentAlignment = Alignment.Center) {
        Text(sign, color = if (gold) onbDarkText else Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun MiniValue(title: String, value: String, modifier: Modifier) {
    Column(modifier.background(AppTheme.card, RoundedCornerShape(12.dp)).padding(8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(title, color = AppTheme.textSec, fontSize = 10.sp)
        Text(value, color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun MiniToggle(title: String, on: Boolean, modifier: Modifier) {
    Column(modifier.background(AppTheme.card, RoundedCornerShape(12.dp)).padding(8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(title, color = AppTheme.textSec, fontSize = 10.sp)
        Icon(
            if (on) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked, null,
            tint = if (on) AppTheme.gold else AppTheme.textTer, modifier = Modifier.padding(top = 3.dp).size(22.dp),
        )
    }
}

// --- Karte: Fahne und Schläge ---

/** Skizze eines Lochs: Fairway, Grün, Bunker und die Schlaglinien. */
@Composable
private fun OnbHoleMap(modifier: Modifier, showTrack: Boolean = false) {
    Canvas(modifier) {
        val w = size.width
        val h = size.height
        drawRect(Color(0xFF1F5A2E))
        val fairway = Path().apply {
            moveTo(w * 0.42f, h * 0.95f)
            cubicTo(w * 0.30f, h * 0.70f, w * 0.75f, h * 0.55f, w * 0.60f, h * 0.22f)
        }
        drawPath(fairway, Color(0xFF3E8C4F), style = Stroke(w * 0.28f, cap = StrokeCap.Round))
        drawCircle(Color(0xFF66B36E), w * 0.16f, Offset(w * 0.6f, h * 0.18f))
        drawCircle(Color(0xFFE3D3A0), w * 0.06f, Offset(w * 0.78f, h * 0.26f))
        drawCircle(Color(0xFFE3D3A0), w * 0.05f, Offset(w * 0.28f, h * 0.52f))
        if (showTrack) {
            val track = Path().apply {
                moveTo(w * 0.40f, h * 0.94f)
                cubicTo(w * 0.22f, h * 0.72f, w * 0.70f, h * 0.62f, w * 0.66f, h * 0.48f)
                cubicTo(w * 0.62f, h * 0.36f, w * 0.52f, h * 0.30f, w * 0.58f, h * 0.20f)
            }
            drawPath(track, Color(0xFF66B3FF), style = Stroke(3.dp.toPx(), cap = StrokeCap.Round, pathEffect = PathEffect.dashPathEffect(floatArrayOf(8f, 6f))))
        } else {
            val tee = Offset(w * 0.42f, h * 0.92f)
            val land = Offset(w * 0.55f, h * 0.55f)
            val pin = Offset(w * 0.6f, h * 0.18f)
            drawLine(Color.White, tee, land, 2.5.dp.toPx(), StrokeCap.Round)
            drawLine(Color.White.copy(alpha = 0.8f), land, pin, 2.5.dp.toPx(), StrokeCap.Round, PathEffect.dashPathEffect(floatArrayOf(10f, 8f)))
            drawCircle(Color(0xFF0A84FF), 6.dp.toPx(), tee)
            drawCircle(Color(0xFFFF9F0A), 6.dp.toPx(), land)
        }
    }
}

@Composable
private fun ShotLabel(club: String, meters: String, modifier: Modifier) {
    Row(modifier.background(Color.Black.copy(alpha = 0.55f), CircleShape).padding(3.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(club, color = onbDarkText, fontSize = 10.sp, fontWeight = FontWeight.Black, modifier = Modifier.background(AppTheme.gold, CircleShape).padding(horizontal = 6.dp, vertical = 2.dp))
        Spacer(Modifier.width(5.dp))
        Text(meters, color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(end = 5.dp))
    }
}

@Composable
internal fun OnbShotMapMock(active: Boolean) {
    OnbPhone {
        Box(Modifier.fillMaxSize()) {
            OnbHoleMap(Modifier.fillMaxSize())
            Icon(Icons.Filled.Flag, null, tint = Color(0xFFFF453A), modifier = Modifier.offset(x = 158.dp, y = 82.dp).size(26.dp))
            ShotLabel("Dr", "212 m", Modifier.offset(x = 160.dp, y = 420.dp))
            ShotLabel("7i", "138 m", Modifier.offset(x = 160.dp, y = 200.dp))
            Column(Modifier.fillMaxSize()) {
                OnbStatusBar()
                Row(
                    Modifier.padding(horizontal = 14.dp).fillMaxWidth().background(AppTheme.card.copy(alpha = 0.92f), RoundedCornerShape(14.dp)).padding(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Loch 7 · Par 4", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                    Icon(Icons.Filled.CheckCircle, null, tint = AppTheme.gold, modifier = Modifier.size(12.dp))
                    Spacer(Modifier.width(4.dp))
                    Text("Pin gesetzt", color = AppTheme.gold, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                }
                Spacer(Modifier.weight(1f))
                Row(
                    Modifier.padding(14.dp).fillMaxWidth().onbHighlight(active).background(AppTheme.card.copy(alpha = 0.95f), RoundedCornerShape(14.dp)).padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(Modifier.weight(1f)) {
                        Text("Zur Fahne", color = AppTheme.textSec, fontSize = 10.sp)
                        Text("142 m", color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Black)
                    }
                    Row(
                        Modifier.background(AppTheme.gold, CircleShape).padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.AddCircle, null, tint = onbDarkText, modifier = Modifier.size(13.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Schlag", color = onbDarkText, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }
    }
}

// --- Laufspur ---

@Composable
internal fun OnbTrackingMock(active: Boolean) {
    OnbPhone {
        Box(Modifier.fillMaxSize()) {
            OnbHoleMap(Modifier.fillMaxSize(), showTrack = true)
            // Erkannte Punkte: Abschlag und Grün
            MapBadge("A", Modifier.offset(x = 104.dp, y = 520.dp).onbAppear(active, 0, baseDelay = 200))
            MapBadge("G", Modifier.offset(x = 150.dp, y = 92.dp).onbAppear(active, 1, baseDelay = 200))
            Column(Modifier.fillMaxSize()) {
                OnbStatusBar()
                Spacer(Modifier.weight(1f))
                Row(
                    Modifier.padding(14.dp).fillMaxWidth().background(AppTheme.card.copy(alpha = 0.95f), RoundedCornerShape(14.dp)).padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.AutoMirrored.Filled.DirectionsWalk, null, tint = AppTheme.gold, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(10.dp))
                    Column {
                        Text("Deine Laufspur", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                        Text("6,4 km · 4:12 h", color = AppTheme.textSec, fontSize = 10.sp)
                    }
                }
            }
        }
    }
}

@Composable
private fun MapBadge(letter: String, modifier: Modifier) {
    Box(modifier.size(26.dp).background(AppTheme.gold, CircleShape).border(2.dp, Color.White, CircleShape), contentAlignment = Alignment.Center) {
        Text(letter, color = onbDarkText, fontSize = 12.sp, fontWeight = FontWeight.Black)
    }
}

// --- Runde abgeschlossen ---

@Composable
internal fun OnbRoundCompleteMock(active: Boolean) {
    OnbPhone {
        OnbScreen {
            Column(Modifier.padding(horizontal = 14.dp), verticalArrangement = Arrangement.spacedBy(10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.size(56.dp).background(AppTheme.gold.copy(alpha = 0.18f), CircleShape), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.EmojiEvents, null, tint = AppTheme.gold, modifier = Modifier.size(28.dp))
                }
                Text("Runde abgeschlossen!", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    BigStat("Score", "86", "+14", AppTheme.textSec, Modifier.weight(1f))
                    BigStat("Handicap", "17.9", "▼ 0.5", Color(0xFF66D980), Modifier.weight(1f).onbHighlight(active))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    SmallStat("Putts", "32", Modifier.weight(1f))
                    SmallStat("Fairway", "57 %", Modifier.weight(1f))
                    SmallStat("GIR", "33 %", Modifier.weight(1f))
                }
                Column(Modifier.onbCard(14.dp, 10.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Passend zu dieser Runde", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    LessonRow("Putten auf Distanz", "04 · 32 Putts")
                    LessonRow("Der Weg aufs Grün", "11 · GIR 33 %")
                    LessonRow("Gelassen bis zum letzten Loch", "16 · Back 9 +9")
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(
                        Modifier.weight(1f).background(AppTheme.card, RoundedCornerShape(13.dp)).padding(vertical = 12.dp),
                        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.Share, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                        Spacer(Modifier.width(5.dp))
                        Text("Teilen", color = AppTheme.gold, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                    GoldPill("Fertig", Modifier.weight(1f), 13)
                }
            }
        }
    }
}

@Composable
private fun BigStat(title: String, value: String, sub: String, subColor: Color, modifier: Modifier) {
    Column(modifier.background(AppTheme.card, RoundedCornerShape(14.dp)).padding(10.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(title, color = AppTheme.textSec, fontSize = 10.sp)
        Text(value, color = Color.White, fontSize = 28.sp, fontWeight = FontWeight.Black)
        Text(sub, color = subColor, fontSize = 11.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun SmallStat(title: String, value: String, modifier: Modifier) {
    Column(modifier.background(AppTheme.card, RoundedCornerShape(12.dp)).padding(8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        Text(title, color = AppTheme.textSec, fontSize = 9.sp)
    }
}

@Composable
private fun LessonRow(title: String, sub: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(26.dp).background(AppTheme.gold, CircleShape), contentAlignment = Alignment.Center) {
            Icon(Icons.Filled.PlayArrow, null, tint = onbDarkText, modifier = Modifier.size(14.dp))
        }
        Spacer(Modifier.width(8.dp))
        Column {
            Text(title, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
            Text(sub, color = AppTheme.textSec, fontSize = 9.sp)
        }
    }
}

// --- Training ---

@Composable
internal fun OnbTrainingMock(active: Boolean) {
    OnbPhone {
        OnbScreen(tab = 1) {
            Column(Modifier.padding(horizontal = 14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("Training", color = Color.White, fontSize = 24.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                    // Auf Android kommen die Audio-Trainings erst mit einer späteren Version.
                    LaterBadge()
                }
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    MockChip("Alle", true); MockChip("Schwung", false); MockChip("Putten", false); MockChip("Mental", false)
                }
                Column(Modifier.onbCard(16.dp, 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(Modifier.size(44.dp).background(AppTheme.gold, RoundedCornerShape(11.dp)), contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.SportsGolf, null, tint = onbDarkText, modifier = Modifier.size(20.dp))
                        }
                        Spacer(Modifier.width(10.dp))
                        Column {
                            Text("07", color = AppTheme.gold, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                            Text("Ruhig bleiben unter Druck", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    Box(Modifier.fillMaxWidth().height(4.dp).background(AppTheme.cardAlt, CircleShape)) {
                        Box(Modifier.fillMaxWidth(0.68f).height(4.dp).background(AppTheme.gold, CircleShape))
                    }
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly, verticalAlignment = Alignment.CenterVertically) {
                        Text("−15", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                        Box(Modifier.size(46.dp).background(AppTheme.gold, CircleShape), contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.Pause, null, tint = onbDarkText, modifier = Modifier.size(22.dp))
                        }
                        Text("+15", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                    Text("68 %", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                }
                Row(Modifier.onbHighlight(active).onbCard(14.dp, 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(34.dp).background(AppTheme.gold.copy(alpha = 0.15f), RoundedCornerShape(9.dp)), contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.School, null, tint = AppTheme.gold, modifier = Modifier.size(17.dp))
                    }
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.weight(1f)) {
                        Text("Platzreife lernen", color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                        Text("Regeln, Etikette und Quiz", color = AppTheme.textSec, fontSize = 10.sp)
                    }
                    Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(14.dp))
                }
                listOf("Der lange Schwung" to "12 min", "Putten auf Distanz" to "9 min", "Routine vor dem Schlag" to "11 min").forEach { (t, l) ->
                    Row(Modifier.onbCard(12.dp, 10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Headphones, null, tint = AppTheme.gold, modifier = Modifier.size(15.dp))
                        Spacer(Modifier.width(8.dp))
                        Text(t, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                        Text(l, color = AppTheme.textSec, fontSize = 10.sp)
                    }
                }
            }
        }
    }
}

// --- Profil ---

@Composable
internal fun OnbProfileMock(active: Boolean) {
    OnbPhone {
        OnbScreen(tab = 4) {
            Column(Modifier.padding(horizontal = 14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(54.dp).background(AppTheme.gold, CircleShape), contentAlignment = Alignment.Center) {
                        Text("A", color = onbDarkText, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                    }
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text("Alex", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                        Text("Ambitionierter Golfer", color = AppTheme.textSec, fontSize = 11.sp)
                    }
                }
                Column(Modifier.onbHighlight(active).onbCard(14.dp, 12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("WHS-Handicap", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                        Text("17.9", color = AppTheme.gold, fontSize = 20.sp, fontWeight = FontWeight.Black)
                    }
                    Canvas(Modifier.fillMaxWidth().height(54.dp)) {
                        val values = listOf(21.2f, 20.6f, 20.9f, 19.8f, 19.1f, 19.4f, 18.6f, 18.4f, 17.9f)
                        val max = values.max(); val min = values.min()
                        val pts = values.mapIndexed { i, v ->
                            Offset(size.width * i / (values.size - 1), size.height * (v - min) / (max - min))
                        }
                        val path = Path().apply { pts.forEachIndexed { i, p -> if (i == 0) moveTo(p.x, p.y) else lineTo(p.x, p.y) } }
                        drawPath(path, AppTheme.gold, style = Stroke(2.dp.toPx(), cap = StrokeCap.Round))
                        drawCircle(AppTheme.gold, 3.5.dp.toPx(), pts.last())
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    SmallStat("Runden", "12", Modifier.weight(1f))
                    SmallStat("Bestleistung", "81", Modifier.weight(1f))
                    SmallStat("Ø Putts", "31.5", Modifier.weight(1f))
                }
                Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))) {
                    ProfileRow(Icons.Filled.ShoppingBag, "Meine Schläger", "14")
                    ProfileRow(Icons.Filled.CreditCard, "Mitgliedskarte", null)
                    ProfileRow(Icons.Filled.BarChart, "Statistiken", null)
                    ProfileRow(Icons.Filled.EmojiEvents, "Errungenschaften", null)
                }
            }
        }
    }
}

@Composable
private fun ProfileRow(icon: ImageVector, title: String, detail: String?) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(28.dp).background(AppTheme.gold.copy(alpha = 0.15f), RoundedCornerShape(7.dp)), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
        }
        Spacer(Modifier.width(10.dp))
        Text(title, color = Color.White, fontSize = 13.sp, modifier = Modifier.weight(1f))
        if (detail != null) Text(detail, color = AppTheme.textSec, fontSize = 11.sp)
        Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(14.dp))
    }
}

// --- Abschluss: Wo finde ich was? ---

/** Die fünf Tabs mit je einem Satz – die Bühne zeigt den Weg durch die App. */
@Composable
internal fun OnbTabGuideVisual(active: Boolean) {
    val rows = listOf(
        Triple(Icons.Filled.Home, "Home", "Runde starten, Wetter, Verlauf"),
        Triple(Icons.Filled.SportsGolf, "Training", "Audio-Lektionen für dein Spiel"),
        Triple(Icons.AutoMirrored.Filled.MenuBook, "Regeln", "Alle Golfregeln mit Skizzen"),
        Triple(Icons.Filled.Lightbulb, "Tipps", "Tipps passend zu deinen Runden"),
        Triple(Icons.Filled.Person, "Profil", "Handicap, Bag, Statistik, Einstellungen"),
    )
    val checkScale by animateFloatAsState(
        if (active) 1f else 0.6f, spring(dampingRatio = 0.5f, stiffness = Spring.StiffnessMediumLow), label = "check",
    )
    Column(
        Modifier.size(OnbCanvas.wideWidth, OnbCanvas.wideHeight).padding(horizontal = 2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
    ) {
        Box(
            Modifier.padding(bottom = 10.dp).scale(checkScale).size(80.dp).shadow(22.dp, CircleShape, spotColor = AppTheme.gold).background(AppTheme.gold, CircleShape),
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Filled.Check, null, tint = onbDarkText, modifier = Modifier.size(38.dp)) }
        rows.forEachIndexed { i, (icon, title, text) ->
            Row(
                Modifier.fillMaxWidth().onbAppear(active, i, dx = 24.dp, dy = 0.dp, baseDelay = 150)
                    .background(AppTheme.card, RoundedCornerShape(18.dp)).padding(10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(46.dp).background(AppTheme.gold.copy(alpha = 0.14f), RoundedCornerShape(13.dp)), contentAlignment = Alignment.Center) {
                    Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(20.dp))
                }
                Spacer(Modifier.width(14.dp))
                Column {
                    Text(title, color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.Bold)
                    Text(text, color = AppTheme.textSec, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
        }
    }
}
