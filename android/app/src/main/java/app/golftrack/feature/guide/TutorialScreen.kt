package app.golftrack.feature.guide

import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.launch

// MARK: - Tutorial (TutorialView)

private const val TOTAL_STEPS = 10
private val screenBg = rgb(0.07f, 0.07f, 0.09f)
private val secondary = Color.White.copy(alpha = 0.6f)

@Composable
fun TutorialScreen(nav: NavController) {
    val pager = rememberPagerState { TOTAL_STEPS }
    val scope = rememberCoroutineScope()
    val close = { nav.popBackStack(); Unit }

    // Eine durchgehende Puls-Animation für alle Seiten.
    val transition = rememberInfiniteTransition(label = "pulse")
    val pulse by transition.animateFloat(
        0f, 1f, infiniteRepeatable(tween(850, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "pulse",
    )

    Column(Modifier.fillMaxSize().background(rgb(0.06f, 0.08f, 0.10f)).statusBarsPadding().navigationBarsPadding()) {
        // Schließen
        Row(Modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 14.dp)) {
            Spacer(Modifier.weight(1f))
            Box(
                Modifier.size(32.dp).background(Color.White.copy(alpha = 0.08f), CircleShape).clickable { Haptics.tap(); close() },
                contentAlignment = Alignment.Center,
            ) { SfIcon("xmark", Color.White.copy(alpha = 0.5f), 14.dp) }
        }

        HorizontalPager(pager, Modifier.weight(1f)) { i -> StepContent(i, pulse) }

        // Navigation
        Column(Modifier.padding(top = 8.dp, bottom = 28.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(5.dp, Alignment.CenterHorizontally)) {
                repeat(TOTAL_STEPS) { i ->
                    val active = i == pager.currentPage
                    val w by animateDpAsState(if (active) 20.dp else 6.dp, spring(), label = "dot")
                    Box(Modifier.width(w).height(6.dp).background(if (active) AppTheme.gold else Color.White.copy(alpha = 0.18f), CircleShape))
                }
            }
            Row(Modifier.fillMaxWidth().padding(horizontal = 28.dp), verticalAlignment = Alignment.CenterVertically) {
                if (pager.currentPage > 0) {
                    Box(
                        Modifier.size(42.dp).background(Color.White.copy(alpha = 0.07f), CircleShape)
                            .clickable { Haptics.selection(); scope.launch { pager.animateScrollToPage(pager.currentPage - 1) } },
                        contentAlignment = Alignment.Center,
                    ) { SfIcon("chevron.left", Color.White.copy(alpha = 0.6f), 22.dp) }
                } else {
                    Spacer(Modifier.size(42.dp))
                }
                Spacer(Modifier.weight(1f))
                val last = pager.currentPage >= TOTAL_STEPS - 1
                Row(
                    Modifier.height(42.dp).background(AppTheme.gold, RoundedCornerShape(50))
                        .clickable {
                            if (!last) {
                                Haptics.selection(); scope.launch { pager.animateScrollToPage(pager.currentPage + 1) }
                            } else {
                                Haptics.success(); close()
                            }
                        }
                        .padding(horizontal = 22.dp)
                        .animateContentSize(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
                ) {
                    T(if (!last) "Weiter" else "Los geht's!", IosFont.subheadline, Color.Black, FontWeight.Bold)
                    SfIcon(if (!last) "arrow.right" else "checkmark", Color.Black, 15.dp)
                }
            }
        }
    }
}

@Composable
private fun StepContent(i: Int, pulse: Float) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(top = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        PhoneFrame {
            when (i) {
                0 -> HomeScreenMockup(pulse)
                1 -> CoursePickerMockup(pulse)
                2 -> ModePickerMockup(pulse)
                3 -> StrokesCounterMockup(pulse)
                4 -> DetailsMockup(pulse)
                5 -> PinSetterMockup(pulse)
                6 -> ClubRecommendationMockup(pulse)
                7 -> ShotTrackerMockup(pulse)
                8 -> FinishButtonMockup(pulse)
                else -> StatsChartMockup(pulse)
            }
        }
        Column(
            Modifier.padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            DText(
                "Schritt ${i + 1} von $TOTAL_STEPS", 11f, AppTheme.gold, FontWeight.Bold,
                Modifier.background(AppTheme.gold.copy(alpha = 0.12f), RoundedCornerShape(50)).padding(horizontal = 12.dp, vertical = 5.dp),
            )
            T(stepTitle(i), IosFont.headline, Color.White, FontWeight.SemiBold, align = TextAlign.Center)
            T(stepDescription(i), IosFont.subheadline, Color.White.copy(alpha = 0.55f), align = TextAlign.Center, modifier = Modifier.padding(horizontal = 12.dp))
        }
        Spacer(Modifier.height(8.dp))
    }
}

private fun stepTitle(i: Int) = when (i) {
    0 -> "Neue Runde starten"
    1 -> "Golfplatz auswählen"
    2 -> "Spielmodus wählen"
    3 -> "Schläge eintragen"
    4 -> "Putts & Details"
    5 -> "Lochposition setzen"
    6 -> "Schlägerverwaltung"
    7 -> "Schläge tracken"
    8 -> "Runde abschließen"
    else -> "Statistiken auswerten"
}

private fun stepDescription(i: Int) = when (i) {
    0 -> "Tippe auf der Startseite auf den goldenen Button, um eine neue Runde zu beginnen."
    1 -> "Wähle deinen Platz aus. Neue Plätze legst du unter Einstellungen → Golfplätze an."
    2 -> "Wähle aus 18 Spielmodi in drei Kategorien: Einzel (z. B. Zählspiel, Stableford, Matchplay), Partner (z. B. Vierer, Greensome) und Team (z. B. Scramble). Das ⓘ erklärt jeden Modus."
    3 -> "Tippe + oder − um Schläge pro Loch einzutragen. Die Zahl aktualisiert sich sofort."
    4 -> "Trage Putts, Fairway-Treffer und GIR ein – die Basis für deine Statistiken."
    5 -> "Tippe auf \"Lochposition festlegen\" und setze den Pin auf der Satellitenkarte. Die App zeigt dir ab sofort die genaue Distanz zum Loch an."
    6 -> "Basierend auf deinen gespeicherten Schlägerdistanzen empfiehlt die App automatisch den besten Schläger für die aktuelle Distanz. Unter Profil → Meine Schläger siehst du alle Messungen."
    7 -> "Tippe auf \"Schläge aufzeichnen\", um jeden Schlag auf der Karte zu markieren. Setze Abschlag und Landepunkt – die Distanz wird automatisch berechnet und dem Schläger gutgeschrieben."
    8 -> "Nach dem letzten Loch tippe auf \"Runde abschließen\". Dein WHS-Handicap wird berechnet."
    else -> "Im Statistik-Tab siehst du Fairway-Quote, GIR, Putts, Handicap-Verlauf und mehr."
}

// MARK: - Telefonrahmen

@Composable
private fun PhoneFrame(content: @Composable ColumnScope.() -> Unit) {
    val outer = RoundedCornerShape(32.dp)
    Box(
        Modifier.size(210.dp, 420.dp).background(white(0.12f), outer).border(1.5.dp, Color.White.copy(alpha = 0.1f), outer),
    ) {
        Column(
            Modifier.fillMaxSize().padding(6.dp).clip(RoundedCornerShape(26.dp)).background(screenBg),
            content = content,
        )
        // Dynamic Island
        Box(Modifier.align(Alignment.TopCenter).padding(top = 12.dp).size(62.dp, 14.dp).background(white(0.12f), CircleShape))
    }
}

/** Goldener, pulsierender Rahmen um das hervorgehobene Element. */
@Composable
private fun Spot(pulse: Float, radius: Dp, modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit) {
    val shape: Shape = if (radius == 0.dp) RectangleShape else RoundedCornerShape(radius)
    Box(modifier) {
        content()
        Box(
            Modifier.matchParentSize()
                .border((1.2f + 0.8f * pulse).dp, AppTheme.gold.copy(alpha = 0.7f + 0.3f * pulse), shape),
        )
    }
}

@Composable
private fun MockStatusBar() {
    Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 2.dp), verticalAlignment = Alignment.CenterVertically) {
        DText("9:41", 8f, Color.White, FontWeight.SemiBold)
        Spacer(Modifier.weight(1f))
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            SfIcon("wifi", Color.White, 9.dp)
            SfIcon("battery.100", Color.White, 9.dp)
        }
    }
}

@Composable
private fun LiveHeader(title: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        SfIcon("chevron.left", AppTheme.gold, 10.dp)
        Spacer(Modifier.weight(1f))
        DText(title, 9f, Color.White, FontWeight.Bold)
        Spacer(Modifier.weight(1f))
        DText("● LIVE", 7f, IosColor.green, FontWeight.Bold)
    }
}

private fun Modifier.box(color: Color, radius: Dp) = this.background(color, RoundedCornerShape(radius))

@Composable
private fun MockDivider() {
    Box(Modifier.fillMaxWidth().height(0.5.dp).background(Color.White.copy(alpha = 0.12f)))
}

// MARK: - Mockup: Startseite

@Composable
private fun ColumnScope.HomeScreenMockup(pulse: Float) {
    MockStatusBar()
    Row(Modifier.padding(horizontal = 12.dp, vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(18.dp).box(AppTheme.gold, 4.dp))
        DText("GolfTrack", 10f, Color.White, FontWeight.Bold)
    }
    Column(Modifier.padding(horizontal = 10.dp).fillMaxWidth().box(white(0.14f), 10.dp).padding(10.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        DText("Willkommen zurück,", 7f, secondary)
        DText("Golfer!", 11f, Color.White, FontWeight.Bold)
    }
    Row(Modifier.padding(start = 10.dp, end = 10.dp, top = 6.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        for ((label, value) in listOf("Handicap" to "24.0", "Letzte Runde" to "92")) {
            Column(Modifier.weight(1f).box(white(0.14f), 9.dp).padding(8.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                DText(label, 6f, secondary)
                DText(value, 12f, Color.White, FontWeight.Bold)
            }
        }
    }
    Spacer(Modifier.weight(1f))
    Spot(pulse, 11.dp, Modifier.padding(start = 10.dp, end = 10.dp, bottom = 16.dp)) {
        Row(
            Modifier.fillMaxWidth().box(AppTheme.gold, 11.dp).padding(vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(5.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically,
        ) {
            SfIcon("plus.circle.fill", Color.Black, 11.dp)
            DText("Neue Runde spielen", 10f, Color.Black, FontWeight.Bold)
        }
    }
}

// MARK: - Mockup: Platzwahl

@Composable
private fun ColumnScope.CoursePickerMockup(pulse: Float) {
    MockStatusBar()
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        DText("Neue Runde", 10f, Color.White, FontWeight.Bold)
        Spacer(Modifier.weight(1f))
        SfIcon("xmark", secondary, 10.dp)
    }
    MockDivider()
    Column(Modifier.padding(top = 10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Column(Modifier.padding(horizontal = 12.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            DText("GOLFPLATZ", 7f, secondary, FontWeight.SemiBold)
            Spot(pulse, 10.dp) {
                Row(
                    Modifier.fillMaxWidth().box(white(0.14f), 10.dp).padding(horizontal = 10.dp, vertical = 9.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
                ) {
                    SfIcon("mappin.circle.fill", AppTheme.gold, 11.dp)
                    DText("Platz auswählen…", 10f, Color.White, modifier = Modifier.weight(1f))
                    SfIcon("chevron.right", secondary, 10.dp)
                }
            }
        }
        Column(Modifier.padding(horizontal = 12.dp).alpha(0.5f), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            DText("DATUM", 7f, secondary, FontWeight.SemiBold)
            Row(
                Modifier.fillMaxWidth().box(white(0.10f), 10.dp).padding(horizontal = 10.dp, vertical = 9.dp),
                horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
            ) {
                SfIcon("calendar", secondary, 11.dp)
                DText("Heute", 10f, Color.White.copy(alpha = 0.4f))
            }
        }
    }
    Spacer(Modifier.weight(1f))
}

// MARK: - Mockup: Spielmodus

@Composable
private fun ColumnScope.ModePickerMockup(pulse: Float) {
    MockStatusBar()
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp)) {
        DText("Neue Runde", 10f, Color.White, FontWeight.Bold)
    }
    MockDivider()
    Column(Modifier.padding(top = 10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(
            Modifier.padding(horizontal = 12.dp).fillMaxWidth().alpha(0.45f).box(white(0.14f), 10.dp).padding(horizontal = 10.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
        ) {
            SfIcon("mappin.circle.fill", AppTheme.gold, 10.dp)
            DText("Golfclub Beispiel", 9f, Color.White)
        }
        Column(Modifier.padding(horizontal = 12.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
            DText("SPIELMODUS", 7f, secondary, FontWeight.SemiBold)
            Spot(pulse, 11.dp) {
                Column(Modifier.fillMaxWidth().box(white(0.12f), 11.dp).padding(6.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    ModeRow("Zählspiel", true)
                    ModeRow("Stableford", false)
                    ModeRow("Matchplay", false)
                }
            }
        }
    }
    Spacer(Modifier.weight(1f))
}

@Composable
private fun ModeRow(name: String, selected: Boolean) {
    Row(
        Modifier.fillMaxWidth().box(white(if (selected) 0.17f else 0.09f), 7.dp).padding(horizontal = 8.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(7.dp).background(if (selected) AppTheme.gold else white(0.25f), CircleShape))
        DText(name, 9f, if (selected) AppTheme.gold else Color.White, if (selected) FontWeight.SemiBold else FontWeight.Normal, Modifier.weight(1f))
        SfIcon("info.circle", secondary, 9.dp)
    }
}

// MARK: - Mockup: Schläge zählen

@Composable
private fun ColumnScope.StrokesCounterMockup(pulse: Float) {
    MockStatusBar()
    LiveHeader("LOCH 1 · 18")
    Column(
        Modifier.padding(start = 10.dp, end = 10.dp, top = 4.dp).fillMaxWidth().box(white(0.12f), 12.dp).padding(vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        DText("AKTUELLES LOCH", 7f, secondary, FontWeight.SemiBold)
        DText("01", 26f, AppTheme.gold, FontWeight.Black, italic = true)
        DText("PAR 4", 8f, secondary, FontWeight.Bold)
    }
    Spacer(Modifier.weight(1f))
    Spot(pulse, 12.dp, Modifier.padding(horizontal = 10.dp)) {
        Column(
            Modifier.fillMaxWidth().box(white(0.12f), 12.dp).padding(horizontal = 20.dp, vertical = 14.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            DText("SCHLÄGE", 7f, secondary, FontWeight.SemiBold)
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(36.dp).box(white(0.18f), 9.dp), contentAlignment = Alignment.Center) { SfIcon("minus", Color.White, 16.dp) }
                DText("4", 36f, Color.White, FontWeight.Black)
                Box(Modifier.size(36.dp).box(AppTheme.gold, 9.dp), contentAlignment = Alignment.Center) { SfIcon("plus", Color.Black, 16.dp) }
            }
        }
    }
    Spacer(Modifier.weight(1f))
    DText(
        "WEITER →", 9f, Color.Black.copy(alpha = 0.6f), FontWeight.Bold,
        Modifier.padding(start = 10.dp, end = 10.dp, bottom = 16.dp).alpha(0.5f).fillMaxWidth()
            .box(AppTheme.gold.copy(alpha = 0.3f), 10.dp).padding(vertical = 9.dp),
        align = TextAlign.Center,
    )
}

// MARK: - Mockup: Putts & Details

@Composable
private fun ColumnScope.DetailsMockup(pulse: Float) {
    MockStatusBar()
    LiveHeader("LOCH 1 · 18")
    Column(
        Modifier.padding(horizontal = 10.dp).alpha(0.45f).fillMaxWidth().box(white(0.10f), 12.dp).padding(vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        DText("SCHLÄGE", 7f, secondary)
        DText("4", 30f, Color.White.copy(alpha = 0.4f), FontWeight.Black)
    }
    Spacer(Modifier.weight(1f))
    Spot(pulse, 10.dp, Modifier.padding(horizontal = 10.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            DetailCell("arrow.triangle.2.circlepath", "Putts", "2", false, Modifier.weight(1f))
            DetailCell("arrow.up.right", "Fairway", "✓", true, Modifier.weight(1f))
            DetailCell("flag.fill", "GIR", "✓", true, Modifier.weight(1f))
        }
    }
    Spacer(Modifier.weight(1f))
    DText(
        "WEITER →", 9f, Color.Black, FontWeight.Bold,
        Modifier.padding(start = 10.dp, end = 10.dp, bottom = 16.dp).alpha(0.5f).fillMaxWidth()
            .box(AppTheme.gold.copy(alpha = 0.4f), 10.dp).padding(vertical = 9.dp),
        align = TextAlign.Center,
    )
}

@Composable
private fun DetailCell(icon: String, label: String, value: String, active: Boolean, modifier: Modifier) {
    Column(
        modifier.box(white(if (active) 0.16f else 0.12f), 9.dp).padding(vertical = 9.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(3.dp),
    ) {
        SfIcon(icon, if (active) AppTheme.gold else secondary, 11.dp)
        DText(label, 6f, secondary)
        DText(value, 10f, if (active) AppTheme.gold else Color.White, FontWeight.Bold)
    }
}

// MARK: - Mockup: Runde abschließen

@Composable
private fun ColumnScope.FinishButtonMockup(pulse: Float) {
    MockStatusBar()
    LiveHeader("LOCH 18 · 18")
    Column(
        Modifier.padding(horizontal = 10.dp).alpha(0.5f).fillMaxWidth().box(white(0.10f), 12.dp).padding(vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        DText("GESAMT", 7f, secondary)
        DText("92", 26f, Color.White.copy(alpha = 0.5f), FontWeight.Black)
        DText("+20", 9f, Color.White.copy(alpha = 0.3f), FontWeight.Bold)
    }
    Column(Modifier.padding(start = 10.dp, end = 10.dp, top = 8.dp).alpha(0.4f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
        for (hole in 16..18) {
            Row(Modifier.fillMaxWidth().box(white(0.10f), 6.dp).padding(horizontal = 10.dp, vertical = 4.dp)) {
                DText("Loch $hole", 8f, secondary, modifier = Modifier.weight(1f))
                DText(if (hole == 18) "5" else "4", 8f, Color.White, FontWeight.SemiBold)
            }
        }
    }
    Spacer(Modifier.weight(1f))
    Spot(pulse, 11.dp, Modifier.padding(start = 10.dp, end = 10.dp, bottom = 16.dp)) {
        Row(
            Modifier.fillMaxWidth().box(AppTheme.gold, 11.dp).padding(vertical = 11.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically,
        ) {
            SfIcon("checkmark.circle.fill", Color.Black, 12.dp)
            DText("Runde abschließen", 10f, Color.Black, FontWeight.Bold)
        }
    }
}

// MARK: - Mockup: Pin setzen

private val mapBg = rgb(0.18f, 0.24f, 0.16f)
private val mapFairway = rgb(0.24f, 0.38f, 0.20f)

@Composable
private fun ColumnScope.PinSetterMockup(pulse: Float) {
    MockStatusBar()
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        SfIcon("chevron.left", AppTheme.gold, 10.dp)
        Spacer(Modifier.weight(1f))
        DText("Loch 1 – Position", 9f, Color.White, FontWeight.Bold)
        Spacer(Modifier.weight(1f))
        DText("Fertig", 9f, AppTheme.gold, FontWeight.SemiBold)
    }
    Row(
        Modifier.fillMaxWidth().background(IosColor.red.copy(alpha = 0.15f)).padding(horizontal = 10.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        SfIcon("mappin.circle.fill", IosColor.red, 11.dp)
        DText("Tippe auf die Karte, um den Pin zu setzen", 7f, Color.White, FontWeight.Medium)
    }
    Spot(pulse, 0.dp, Modifier.weight(1f).fillMaxWidth()) {
        Box(Modifier.fillMaxSize().background(mapBg).clipToBounds(), contentAlignment = Alignment.Center) {
            Box(Modifier.offset(10.dp, 10.dp).rotate(-15f).size(28.dp, 90.dp).box(mapFairway.copy(alpha = 0.8f), 6.dp))
            Box(Modifier.offset(14.dp, (-42).dp).size(28.dp, 22.dp).background(rgb(0.28f, 0.50f, 0.22f).copy(alpha = 0.9f), androidx.compose.foundation.shape.GenericShape { s, _ -> addOval(androidx.compose.ui.geometry.Rect(Offset.Zero, s)) }))
            Box(Modifier.offset(14.dp, (-38).dp), contentAlignment = Alignment.Center) {
                val d = 20f + 8f * pulse
                Box(Modifier.size(d.dp).background(IosColor.red.copy(alpha = 0.1f + 0.15f * pulse), CircleShape))
                SfIcon("mappin.circle.fill", IosColor.red, 19.dp)
            }
            DText(
                "354 m zum Loch", 7f, Color.White, FontWeight.Bold,
                Modifier.offset(14.dp, (-20).dp).background(Color.Black.copy(alpha = 0.7f), RoundedCornerShape(50)).padding(horizontal = 8.dp, vertical = 4.dp),
            )
        }
    }
}

// MARK: - Mockup: Schlägerempfehlung

@Composable
private fun ColumnScope.ClubRecommendationMockup(pulse: Float) {
    MockStatusBar()
    LiveHeader("LOCH 4 · 18")
    Column(
        Modifier.padding(horizontal = 10.dp).alpha(0.45f).fillMaxWidth().box(white(0.10f), 10.dp).padding(vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        DText("PAR 4", 7f, secondary, FontWeight.Bold)
        DText("04", 22f, Color.White.copy(alpha = 0.4f), FontWeight.Black, italic = true)
    }
    Spacer(Modifier.weight(1f))
    Spot(pulse, 12.dp, Modifier.padding(horizontal = 10.dp)) {
        Column(Modifier.fillMaxWidth().box(white(0.14f), 12.dp)) {
            RecoRow("mappin.circle.fill", IosColor.red, "186 m zum Loch", Color.White, "Pin gesetzt · Loch 4")
            Box(Modifier.padding(horizontal = 10.dp)) { MockDivider() }
            RecoRow("figure.golf", AppTheme.gold, "Empfehlung: 5 Wood", AppTheme.gold, "Ø 180 m · aus 12 Messungen")
        }
    }
    Spacer(Modifier.weight(1f))
    Row(
        Modifier.fillMaxWidth().alpha(0.45f).padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(32.dp).box(white(0.18f), 8.dp), contentAlignment = Alignment.Center) { DText("−", 14f, Color.White, FontWeight.Bold) }
        DText("3", 30f, Color.White.copy(alpha = 0.4f), FontWeight.Black)
        Box(Modifier.size(32.dp).box(AppTheme.gold.copy(alpha = 0.4f), 8.dp), contentAlignment = Alignment.Center) { DText("+", 14f, Color.Black, FontWeight.Bold) }
    }
}

@Composable
private fun RecoRow(icon: String, iconColor: Color, title: String, titleColor: Color, sub: String) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(26.dp).background(iconColor.copy(alpha = 0.15f), CircleShape), contentAlignment = Alignment.Center) {
            SfIcon(icon, iconColor, 13.dp)
        }
        Column(verticalArrangement = Arrangement.spacedBy(1.dp)) {
            DText(title, 10f, titleColor, FontWeight.Bold)
            DText(sub, 6f, secondary)
        }
    }
}

// MARK: - Mockup: Schläge aufzeichnen

@Composable
private fun ColumnScope.ShotTrackerMockup(pulse: Float) {
    MockStatusBar()
    Row(
        Modifier.fillMaxWidth().background(IosColor.blue.copy(alpha = 0.1f)).padding(horizontal = 10.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        SfIcon("figure.golf", IosColor.blue, 10.dp)
        DText("Abschlag setzen", 7f, IosColor.blue, FontWeight.SemiBold, Modifier.weight(1f))
        DText(
            "Standort", 7f, Color.White, FontWeight.Bold,
            Modifier.background(IosColor.blue.copy(alpha = 0.7f), RoundedCornerShape(50)).padding(horizontal = 7.dp, vertical = 3.dp),
        )
    }
    Box(Modifier.weight(1f).fillMaxWidth().background(mapBg).clipToBounds()) {
        Box(
            Modifier.align(Alignment.Center).offset((-5).dp, 5.dp).rotate(8f).size(32.dp, 110.dp)
                .box(mapFairway.copy(alpha = 0.75f), 8.dp),
        )
        Draw {
            drawLine(AppTheme.gold.copy(alpha = 0.7f), Offset(50f, 130f), Offset(85f, 75f), 1.5f)
            drawLine(AppTheme.gold, Offset(85f, 75f), Offset(105f, 38f), 2f)
        }
        At(50f, 130f) { ShotMarker("1") }
        At(85f, 75f) { ShotMarker("2") }
        At(105f, 38f) {
            Box(Modifier.size(16.dp).background(Color.White, CircleShape), contentAlignment = Alignment.Center) {
                SfIcon("target", IosColor.orange, 13.dp)
            }
        }
        At(85f, 75f) {
            Box(contentAlignment = Alignment.Center) {
                val d = 16f + 8f * pulse
                Box(Modifier.size(24.dp), contentAlignment = Alignment.Center) {
                    Box(Modifier.size(d.dp).background(IosColor.blue.copy(alpha = 0.1f + 0.2f * pulse), CircleShape))
                }
                ShotMarker("3")
            }
        }
    }
    Column(Modifier.fillMaxWidth().background(white(0.10f)).padding(vertical = 6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Spot(pulse, 10.dp, Modifier.padding(horizontal = 10.dp)) {
            Row(
                Modifier.fillMaxWidth().box(white(0.14f), 10.dp).padding(horizontal = 12.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
                    DText("128 m", 12f, AppTheme.gold, FontWeight.Bold)
                    DText("Meter", 6f, secondary)
                }
                DText(
                    "Speichern", 8f, Color.Black, FontWeight.Bold,
                    Modifier.background(AppTheme.gold, RoundedCornerShape(50)).padding(horizontal = 10.dp, vertical = 5.dp),
                )
            }
        }
        Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 10.dp), horizontalArrangement = Arrangement.spacedBy(5.dp)) {
            for (club in listOf("Driver", "3 Wood", "5 Wood", "7 Eisen")) {
                val sel = club == "5 Wood"
                DText(
                    club, 7f, if (sel) Color.Black else Color.White, FontWeight.SemiBold,
                    Modifier.background(if (sel) AppTheme.gold else white(0.20f), RoundedCornerShape(50)).padding(horizontal = 8.dp, vertical = 4.dp),
                )
            }
        }
        Row(Modifier.padding(horizontal = 12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            SfIcon("figure.golf", secondary, 8.dp)
            DText("Schlag 1 · Driver", 7f, secondary, modifier = Modifier.weight(1f))
            DText("195 m", 7f, AppTheme.gold, FontWeight.Bold)
        }
    }
}

@Composable
private fun ShotMarker(n: String) {
    Box(Modifier.size(18.dp).background(IosColor.blue, CircleShape), contentAlignment = Alignment.Center) {
        DText(n, 7f, Color.White, FontWeight.Bold)
    }
}

// MARK: - Mockup: Statistiken

@Composable
private fun ColumnScope.StatsChartMockup(pulse: Float) {
    MockStatusBar()
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp)) {
        DText("Statistiken", 10f, Color.White, FontWeight.Bold)
    }
    Column(Modifier.padding(top = 4.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(
            Modifier.padding(horizontal = 10.dp).alpha(0.45f).fillMaxWidth().box(white(0.12f), 10.dp).padding(10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                DText("WHS Handicap", 7f, secondary)
                DText("24.0", 18f, AppTheme.gold, FontWeight.Black)
            }
            SfIcon("chart.line.downtrend.xyaxis", AppTheme.gold.copy(alpha = 0.3f), 17.dp)
        }
        Spot(pulse, 11.dp, Modifier.padding(horizontal = 10.dp)) {
            Column(Modifier.fillMaxWidth().box(white(0.14f), 11.dp).padding(10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                DText("SCORE-VERLAUF", 7f, secondary, FontWeight.SemiBold)
                Row(Modifier.height(44.dp), horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.Bottom) {
                    for (h in listOf(0.50f, 0.65f, 0.55f, 0.75f, 0.60f, 0.80f, 0.70f)) {
                        Box(Modifier.weight(1f).height((44 * h).dp).background(AppTheme.gold.copy(alpha = 0.75f), CircleShape))
                    }
                }
            }
        }
        Row(Modifier.padding(horizontal = 10.dp).alpha(0.45f), horizontalArrangement = Arrangement.spacedBy(5.dp)) {
            for ((v, l) in listOf("61%" to "Fairway", "38%" to "GIR", "1.9" to "Putts")) {
                Column(
                    Modifier.weight(1f).box(white(0.12f), 8.dp).padding(vertical = 8.dp),
                    horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp),
                ) {
                    DText(v, 10f, Color.White, FontWeight.Bold)
                    DText(l, 6f, secondary)
                }
            }
        }
    }
    Spacer(Modifier.weight(1f))
}
