package app.golftrack.feature.guide

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.GolfStore
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LaterBadge
import app.golftrack.ui.common.LaterFeature
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme
import java.util.Calendar

// MARK: - Tipps-Tab (TipsView)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TipsScreen(nav: NavController) {
    val data by GolfStore.data.collectAsState()
    val recommendations = remember(data.rounds, data.courses) {
        TrainingRecommender.recommendations(data.rounds, { data.course(it.courseId) })
    }
    val dailyTip = remember {
        val dayOfYear = Calendar.getInstance().get(Calendar.DAY_OF_YEAR)
        DailyTip.all[(dayOfYear - 1) % DailyTip.all.size]
    }
    var showDailyTip by remember { mutableStateOf(false) }

    Column(Modifier.fillMaxSize().background(AppTheme.bg).verticalScroll(rememberScrollState())) {
        ReadableWidth {
            Column(Modifier.padding(top = 4.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                T(
                    "Tipps & Coaching", IosFont.title2, weight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp),
                )

                // Tipp des Tages
                IconLinkCard(
                    dailyTip.icon, "Pro Tipp des Tages", "${dailyTip.title} – ${dailyTip.body}", haptic = true,
                ) { showDailyTip = true }

                // Persönliche Empfehlungen aus den Statistiken
                if (recommendations.isNotEmpty()) {
                    RecommendationsSection(recommendations) { nav.navigate(Routes.comingLater(LaterFeature.AUDIOBOOKS)) }
                }

                IconLinkCard("graduationcap.fill", "Golf-Ratgeber", "Platzreife Quiz & Shot-Scope-Strategie") {
                    nav.navigate(Routes.GUIDE)
                }
                IconLinkCard("chart.bar.fill", "Meine Statistiken", "Fairways, Greens, Putts & Score-Verlauf") {
                    nav.navigate(Routes.STATISTICS)
                }

                T("Kategorien", IosFont.headline, weight = FontWeight.SemiBold, modifier = Modifier.padding(horizontal = 16.dp))

                Column(Modifier.padding(horizontal = 16.dp).fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))) {
                    val cats = TipsCategoryContent.categories
                    cats.forEachIndexed { i, cat ->
                        Row(
                            Modifier.fillMaxWidth().clickable { nav.navigate(GuideNav.tipsCategory(i)) }
                                .padding(horizontal = 18.dp, vertical = 14.dp),
                            horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(Modifier.size(40.dp).background(cat.color.copy(alpha = 0.18f), CircleShape), contentAlignment = Alignment.Center) {
                                SfIcon(cat.icon, cat.color, 19.dp)
                            }
                            T(cat.name, IosFont.subheadline, weight = FontWeight.Bold, modifier = Modifier.weight(1f))
                            SfIcon("chevron.right", AppTheme.textTer, 18.dp)
                        }
                        if (i < cats.lastIndex) {
                            Box(Modifier.padding(start = 66.dp).fillMaxWidth().height(0.5.dp).background(AppTheme.cardAlt))
                        }
                    }
                }
                Spacer(Modifier.height(30.dp))
            }
        }
    }

    if (showDailyTip) {
        ModalBottomSheet(
            onDismissRequest = { showDailyTip = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = AppTheme.bg,
            dragHandle = null,
        ) { DailyTipDetail(dailyTip) { Haptics.tap(); showDailyTip = false } }
    }
}

@Composable
private fun IconLinkCard(icon: String, title: String, subtitle: String, haptic: Boolean = false, onClick: () -> Unit) {
    Row(
        Modifier.padding(horizontal = 16.dp).fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))
            .clickable { if (haptic) Haptics.tap(); onClick() }.padding(18.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(52.dp).background(AppTheme.cardAlt, RoundedCornerShape(12.dp)), contentAlignment = Alignment.Center) {
            SfIcon(icon, AppTheme.gold, 24.dp)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            T(title, IosFont.headline, weight = FontWeight.SemiBold, maxLines = 1)
            T(subtitle, IosFont.caption, AppTheme.textSec, maxLines = 1)
        }
        SfIcon("chevron.right", AppTheme.textTer, 20.dp)
    }
}

@Composable
private fun RecommendationsSection(recommendations: List<TrainingRecommendation>, onOpen: () -> Unit) {
    Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            SfIcon("sparkles", AppTheme.gold, 16.dp)
            T("Für dich empfohlen", IosFont.headline, weight = FontWeight.SemiBold)
        }
        T("Audio-Lektionen, die zu deinen aktuellen Statistiken passen", IosFont.caption, AppTheme.textSec)

        Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))) {
            recommendations.forEachIndexed { i, rec ->
                Row(
                    Modifier.fillMaxWidth().clickable { Haptics.tap(); onOpen() }.padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically,
                ) {
                    val color = rec.lesson.category.color
                    Box(Modifier.size(52.dp).background(color.copy(alpha = 0.18f), RoundedCornerShape(12.dp)), contentAlignment = Alignment.Center) {
                        SfIcon("play.fill", color, 20.dp)
                    }
                    Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                            T(rec.lesson.title, IosFont.subheadline, weight = FontWeight.Bold, maxLines = 1, modifier = Modifier.weight(1f, fill = false))
                            LaterBadge()
                        }
                        T(rec.reason, IosFont.caption, AppTheme.textSec, maxLines = 3)
                        rec.statLabel?.let {
                            T(
                                it, IosFont.caption2, AppTheme.gold, FontWeight.Bold,
                                modifier = Modifier.padding(top = 1.dp).background(AppTheme.gold.copy(alpha = 0.12f), RoundedCornerShape(50))
                                    .padding(horizontal = 8.dp, vertical = 3.dp),
                            )
                        }
                    }
                    SfIcon("chevron.right", AppTheme.textTer, 18.dp)
                }
                if (i < recommendations.lastIndex) {
                    Box(Modifier.padding(start = 66.dp).fillMaxWidth().height(0.5.dp).background(AppTheme.cardAlt))
                }
            }
        }
    }
}

// MARK: - Tipp des Tages (DailyTipDetailView)

@Composable
private fun DailyTipDetail(tip: DailyTip, onClose: () -> Unit) {
    Column(Modifier.fillMaxSize().navigationBarsPadding()) {
        Row(Modifier.fillMaxWidth().padding(start = 20.dp, end = 20.dp, top = 20.dp)) {
            Spacer(Modifier.weight(1f))
            Box(Modifier.clickable { onClose() }) { SfIcon("xmark.circle.fill", AppTheme.textTer, 28.dp) }
        }
        Column(Modifier.verticalScroll(rememberScrollState())) {
            ReadableWidth(600.dp) {
                Column(
                    Modifier.fillMaxWidth().padding(horizontal = 24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(28.dp),
                ) {
                    Box(
                        Modifier.padding(top = 12.dp).size(88.dp).background(AppTheme.gold.copy(alpha = 0.15f), CircleShape),
                        contentAlignment = Alignment.Center,
                    ) { SfIcon(tip.icon, AppTheme.gold, 40.dp) }
                    androidx.compose.material3.Text(
                        "PRO TIPP DES TAGES",
                        style = TextStyle(fontSize = IosFont.caption, fontWeight = FontWeight.Bold, letterSpacing = 1.2.sp, color = AppTheme.gold),
                        modifier = Modifier.background(AppTheme.gold.copy(alpha = 0.12f), RoundedCornerShape(50)).padding(horizontal = 14.dp, vertical = 6.dp),
                    )
                    T(tip.title, IosFont.title2, weight = FontWeight.Bold, align = TextAlign.Center)
                    T(
                        tip.body, IosFont.body, AppTheme.textSec, align = TextAlign.Center, lineHeight = 27.sp,
                        modifier = Modifier.padding(horizontal = 8.dp),
                    )
                    Spacer(Modifier.height(40.dp))
                }
            }
        }
    }
}

// MARK: - Kategorie (TipsCategoryDetailView)

@Composable
fun TipsCategoryScreen(nav: NavController, categoryIndex: Int) {
    val category = TipsCategoryContent.categories.getOrNull(categoryIndex) ?: return
    val tips = TipsCategoryContent.tips(category)
    AppScaffold(category.name, onBack = { nav.popBackStack() }) { m ->
        Column(m.background(AppTheme.bg).verticalScroll(rememberScrollState())) {
            ReadableWidth {
                Column(Modifier.padding(top = 4.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Row(
                        Modifier.padding(start = 16.dp, end = 16.dp, top = 8.dp).fillMaxWidth()
                            .background(AppTheme.card, RoundedCornerShape(16.dp)).padding(18.dp),
                        horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(Modifier.size(52.dp).background(category.color.copy(alpha = 0.18f), CircleShape), contentAlignment = Alignment.Center) {
                            SfIcon(category.icon, category.color, 24.dp)
                        }
                        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            T(category.name, IosFont.title3, weight = FontWeight.Bold)
                            T("${tips.size} Tipps", IosFont.caption, AppTheme.textSec)
                        }
                    }
                    Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        tips.forEachIndexed { i, tip ->
                            Row(
                                Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))
                                    .clickable { nav.navigate(GuideNav.tip(categoryIndex, i)) }.padding(16.dp),
                                horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically,
                            ) {
                                IconTile(tip.icon, category.color, iconSize = 20.dp)
                                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                    T(tip.title, IosFont.subheadline, weight = FontWeight.Bold)
                                    T(tip.body, IosFont.caption, AppTheme.textSec, maxLines = 2)
                                }
                                SfIcon("chevron.right", AppTheme.textTer, 18.dp)
                            }
                        }
                    }
                    Spacer(Modifier.height(30.dp))
                }
            }
        }
    }
}

// MARK: - Tipp (TipDetailView)

@Composable
fun TipDetailScreen(nav: NavController, categoryIndex: Int, tipIndex: Int) {
    val category = TipsCategoryContent.categories.getOrNull(categoryIndex) ?: return
    val tip = TipsCategoryContent.tips(category).getOrNull(tipIndex) ?: return
    AppScaffold(tip.title, onBack = { nav.popBackStack() }) { m ->
        Column(m.background(AppTheme.bg).verticalScroll(rememberScrollState())) {
            ReadableWidth {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(20.dp)) {
                    Box(
                        Modifier.padding(top = 24.dp).size(90.dp).background(category.color.copy(alpha = 0.15f), CircleShape),
                        contentAlignment = Alignment.Center,
                    ) { SfIcon(tip.icon, category.color, 40.dp) }
                    T(tip.title, IosFont.title2, weight = FontWeight.Bold, align = TextAlign.Center, modifier = Modifier.padding(horizontal = 16.dp))
                    Column(
                        Modifier.padding(horizontal = 16.dp).fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp),
                    ) {
                        Row(Modifier.padding(bottom = 10.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                            SfIcon("lightbulb.fill", AppTheme.gold, 13.dp)
                            T("Tipp", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
                        }
                        T(tip.body, IosFont.body, lineHeight = 27.sp)
                    }
                    Spacer(Modifier.height(40.dp))
                }
            }
        }
    }
}
