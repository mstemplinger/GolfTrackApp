package app.golftrack.feature.guide

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.data.GameMode
import app.golftrack.data.GameModeCategory
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme

/** SF-Symbol je Spielform (GameMode.sfSymbol auf iOS). */
val GameMode.sfSymbol: String
    get() = when (this) {
        GameMode.STROKE_PLAY -> "figure.golf"
        GameMode.STABLEFORD -> "star.circle.fill"
        GameMode.ERADO -> "ticket.fill"
        GameMode.SKINS -> "seal.fill"
        GameMode.DUPLICATE_STABLEFORD -> "repeat.circle.fill"
        GameMode.MATCHPLAY -> "person.2.fill"
        GameMode.BETTER_BALL_STROKE, GameMode.BETTER_BALL_STABLEFORD, GameMode.BETTER_BALL_MATCHPLAY -> "flame.fill"
        GameMode.SCRAMBLE_2_MANN -> "person.2.wave.2.fill"
        GameMode.VIERER -> "arrow.triangle.2.circlepath.circle.fill"
        GameMode.GREENSOME -> "person.2.circle.fill"
        GameMode.SCRAMBLE_MATCHPLAY -> "person.3.sequence.fill"
        GameMode.BEST_BALL_STROKE, GameMode.BEST_BALL_STABLEFORD -> "flame.circle.fill"
        GameMode.SCRAMBLE_TEAM -> "person.3.fill"
        GameMode.MATCH_NET -> "chart.bar.doc.horizontal.fill"
        GameMode.DUPLICATE_SCRAMBLE -> "repeat.1.circle.fill"
        GameMode.IRISH_RUMBLE -> "leaf.circle.fill"
    }

val GameModeCategory.icon: String
    get() = when (this) {
        GameModeCategory.INDIVIDUAL -> "person.fill"
        GameModeCategory.PARTNER -> "person.2.fill"
        GameModeCategory.TEAM -> "person.3.fill"
    }

// MARK: - Übersicht (GameModesView)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GameModesScreen(nav: NavController) {
    var unavailableMode by remember { mutableStateOf<GameMode?>(null) }

    AppScaffold("Spielmodi", onBack = { nav.popBackStack() }) { m ->
        Column(m.background(AppTheme.bg).verticalScroll(rememberScrollState())) {
            GameModeCategory.entries.forEach { category ->
                // Abschnittskopf in Gold
                Row(
                    Modifier.fillMaxWidth().background(AppTheme.gold).padding(horizontal = 16.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    T(category.title.uppercase(), IosFont.caption, Color.White, FontWeight.Bold, modifier = Modifier.weight(1f))
                    SfIcon(category.icon, Color.White.copy(alpha = 0.8f), 18.dp)
                }
                ReadableWidth(900.dp) {
                    Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        GameMode.entries.filter { it.category == category }.chunked(2).forEach { row ->
                            Row(Modifier.height(androidx.compose.foundation.layout.IntrinsicSize.Max), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                row.forEach { mode ->
                                    ModeCard(mode, Modifier.weight(1f).fillMaxHeight()) {
                                        if (mode.isAvailable) {
                                            nav.navigate(GuideNav.gameMode(mode))
                                        } else {
                                            Haptics.tap()
                                            unavailableMode = mode
                                        }
                                    }
                                }
                                if (row.size == 1) Spacer(Modifier.weight(1f))
                            }
                        }
                    }
                }
            }
            Spacer(Modifier.height(24.dp))
        }
    }

    unavailableMode?.let { mode ->
        ModalBottomSheet(
            onDismissRequest = { unavailableMode = null },
            sheetState = rememberModalBottomSheetState(),
            containerColor = AppTheme.bg,
        ) {
            Column(Modifier.fillMaxWidth().navigationBarsPadding()) {
                Box(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
                    Box(Modifier.align(Alignment.CenterEnd)) {
                        BarTextButton("Schließen") { Haptics.tap(); unavailableMode = null }
                    }
                }
                Column(
                    Modifier.fillMaxWidth().padding(bottom = 32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp),
                ) {
                    SfIcon(mode.sfSymbol, AppTheme.textSec, 64.dp, Modifier.padding(top = 16.dp))
                    T(mode.displayName, IosFont.title2, weight = FontWeight.Bold)
                    T(mode.description, IosFont.body, AppTheme.textSec, align = TextAlign.Center, modifier = Modifier.padding(horizontal = 16.dp))
                    Row(Modifier.padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        SfIcon("clock.badge", IosColor.orange, 18.dp)
                        T("Dieser Spielmodus kommt bald", IosFont.subheadline, IosColor.orange)
                    }
                }
            }
        }
    }
}

@Composable
private fun ModeCard(mode: GameMode, modifier: Modifier, onClick: () -> Unit) {
    val shape = RoundedCornerShape(12.dp)
    Box(
        modifier.heightIn(min = 110.dp).background(AppTheme.card, shape)
            .border(1.5.dp, if (mode.isAvailable) AppTheme.gold.copy(alpha = 0.4f) else Color.Transparent, shape)
            .clickable(onClick = onClick),
    ) {
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
            SfIcon(mode.sfSymbol, if (mode.isAvailable) AppTheme.gold else AppTheme.textSec, 36.dp, Modifier.padding(top = 16.dp))
            Column(
                Modifier.padding(start = 8.dp, end = 8.dp, bottom = 10.dp),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                T(mode.displayName, IosFont.subheadline, weight = FontWeight.Bold, align = TextAlign.Center)
                if (mode.subtitle.isNotEmpty()) T(mode.subtitle, IosFont.caption2, AppTheme.textSec)
            }
        }
        if (!mode.isAvailable) {
            T(
                "Bald", IosFont.caption2, Color.White, FontWeight.Bold,
                modifier = Modifier.align(Alignment.TopEnd).padding(top = 4.dp, end = 8.dp)
                    .background(IosColor.orange, RoundedCornerShape(50)).padding(horizontal = 5.dp, vertical = 2.dp),
            )
        }
    }
}

// MARK: - Detail (GameModeDetailView)

@Composable
fun GameModeDetailScreen(nav: NavController, mode: GameMode) {
    AppScaffold(mode.displayName, onBack = { nav.popBackStack() }) { m ->
        Column(m.background(AppTheme.bg)) {
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState())) {
                Box(Modifier.fillMaxWidth().height(180.dp).background(AppTheme.gold.copy(alpha = 0.15f)), contentAlignment = Alignment.Center) {
                    SfIcon(mode.sfSymbol, AppTheme.gold, 80.dp)
                }
                ReadableWidth {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                        Row(verticalAlignment = Alignment.Top) {
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                T(mode.displayName, IosFont.title2, weight = FontWeight.Bold)
                                if (mode.subtitle.isNotEmpty()) T(mode.subtitle, IosFont.subheadline, AppTheme.textSec)
                            }
                            Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                SfIcon(mode.category.icon, AppTheme.textSec, 18.dp)
                                T(
                                    when (mode.category) {
                                        GameModeCategory.INDIVIDUAL -> "Individuell"
                                        GameModeCategory.PARTNER -> "Partner"
                                        GameModeCategory.TEAM -> "Team"
                                    },
                                    IosFont.caption, AppTheme.textSec,
                                )
                            }
                        }
                        Box(Modifier.fillMaxWidth().height(0.5.dp).background(Color.White.copy(alpha = 0.15f)))
                        T(mode.description, IosFont.body, lineHeight = IosFont.body * 1.35f)
                        if (mode == GameMode.STABLEFORD) StablefordTable()
                        Spacer(Modifier.height(40.dp))
                    }
                }
            }
            // Unterer Bereich wie `.safeAreaInset(edge: .bottom)`
            Box(Modifier.fillMaxWidth().background(AppTheme.bg).padding(16.dp)) {
                if (mode.isAvailable) {
                    GoldLabelButton("Runde starten – ${mode.displayName}", "flag.fill") {
                        Haptics.medium()
                        nav.navigate(Routes.newRound(mode = mode.raw))
                    }
                } else {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically) {
                        SfIcon("clock.badge", IosColor.orange, 18.dp)
                        T("Dieses Spielformat wird bald verfügbar sein.", IosFont.subheadline, AppTheme.textSec)
                    }
                }
            }
        }
    }
}

@Composable
private fun StablefordTable() {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        T("Punktetabelle", IosFont.headline, weight = FontWeight.SemiBold)
        val rows = listOf("Albatross" to -3, "Eagle" to -2, "Birdie" to -1, "Par" to 0, "Bogey" to 1, "Double+" to 2)
        val points = listOf(5, 4, 3, 2, 1, 0)
        Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(10.dp))) {
            rows.forEachIndexed { i, (name, diff) ->
                val p = points[i]
                Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    T(name, IosFont.subheadline, modifier = Modifier.weight(1f))
                    T(if (diff < 0) "$diff" else if (diff == 0) "E" else "+$diff", IosFont.caption, AppTheme.textSec)
                    T(
                        "$p Pkt.", IosFont.subheadline,
                        if (p >= 3) AppTheme.gold else if (p == 0) AppTheme.textSec else AppTheme.text,
                        FontWeight.Bold, align = TextAlign.End, modifier = Modifier.width(60.dp),
                    )
                }
                if (i < rows.lastIndex) Box(Modifier.fillMaxWidth().height(0.5.dp).background(Color.White.copy(alpha = 0.15f)))
            }
        }
    }
}
