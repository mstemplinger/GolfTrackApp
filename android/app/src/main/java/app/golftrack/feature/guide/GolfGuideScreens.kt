package app.golftrack.feature.guide

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme

// MARK: - Golf-Ratgeber (GolfGuideView)

@Composable
fun GolfGuideScreen(nav: NavController) {
    AppScaffold("Golf-Ratgeber", onBack = { nav.popBackStack() }) { m ->
        LazyColumn(m.background(AppTheme.bg)) {
            item {
                GuideSection {
                    T(
                        "Basierend auf Daten von über 100.000 Golfrunden analysiert Shot Scope die häufigsten Fehler von Handicap-Golfern.",
                        IosFont.subheadline, AppTheme.textSec,
                        modifier = Modifier.fillMaxWidth().rounded(AppTheme.card, 12.dp).padding(horizontal = 16.dp, vertical = 14.dp),
                    )
                }
            }
            item {
                GuideSection {
                    ListCardRow(onClick = { nav.navigate(Routes.PLATZREIFE) }) {
                        Row(Modifier.padding(vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
                            IconTile("graduationcap.fill", AppTheme.gold, bgAlpha = 0.13f)
                            Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                T("Platzreife lernen", IosFont.headline, weight = FontWeight.SemiBold)
                                T("Lernrunden, Probeprüfung & Fortschritt", IosFont.caption, AppTheme.textSec, maxLines = 1)
                                T("${PlatzreifeQuestions.all.size} offizielle Prüfungsfragen", IosFont.caption2, AppTheme.gold, FontWeight.SemiBold)
                            }
                        }
                    }
                }
            }
            itemsIndexed(GolfGuideContent.chapters) { i, chapter ->
                GuideSection {
                    ListCardRow(onClick = { nav.navigate(GuideNav.chapter(i)) }) { ChapterRow(chapter) }
                }
            }
            item {
                GuideSection {
                    T(
                        "Strategie-Insights: Shot Scope Ltd.  ·  Regeln: R&A / USGA 2023",
                        IosFont.caption, AppTheme.textTer, align = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth().rounded(AppTheme.card, 12.dp).padding(14.dp),
                    )
                }
                Spacer(Modifier.height(24.dp))
            }
        }
    }
}

/** Ein Abschnitt im „insetGrouped“-Stil. */
@Composable
fun GuideSection(content: @Composable () -> Unit) {
    ReadableWidth { Box(Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) { content() } }
}

@Composable
private fun ChapterRow(chapter: GuideChapter) {
    Row(Modifier.padding(vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
        IconTile(chapter.icon, chapter.color)
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            T("Kapitel ${chapter.number}", IosFont.caption, chapter.color, FontWeight.SemiBold)
            T(chapter.title, IosFont.headline, weight = FontWeight.SemiBold)
            T(chapter.subtitle, IosFont.caption, AppTheme.textSec, maxLines = 1)
        }
    }
}

// MARK: - Kapitel

@Composable
fun ChapterDetailScreen(nav: NavController, chapterIndex: Int) {
    val chapter = GolfGuideContent.chapters.getOrNull(chapterIndex) ?: return
    AppScaffold(chapter.title, onBack = { nav.popBackStack() }) { m ->
        LazyColumn(m.background(AppTheme.bg)) {
            itemsIndexed(chapter.lessons) { i, lesson ->
                GuideSection {
                    ListCardRow(onClick = { nav.navigate(GuideNav.lesson(chapterIndex, i)) }) {
                        LessonRow(lesson, i + 1, chapter.color)
                    }
                }
            }
            item { Spacer(Modifier.height(24.dp)) }
        }
    }
}

@Composable
private fun LessonRow(lesson: GuideLesson, index: Int, color: Color) {
    Row(Modifier.padding(vertical = 2.dp), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(24.dp).background(color.copy(alpha = 0.12f), CircleShape), contentAlignment = Alignment.Center) {
            T("$index", IosFont.caption, color, FontWeight.Bold)
        }
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            T(lesson.title, IosFont.subheadline, weight = FontWeight.Bold)
            if (lesson.stats.isNotEmpty()) {
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                    SfIcon("chart.bar.fill", AppTheme.textSec, 11.dp)
                    T("${lesson.stats.size} Statistiken", IosFont.caption, AppTheme.textSec)
                }
            }
        }
    }
}

// MARK: - Lektion

@Composable
fun LessonDetailScreen(nav: NavController, chapterIndex: Int, lessonIndex: Int) {
    val chapter = GolfGuideContent.chapters.getOrNull(chapterIndex) ?: return
    val lesson = chapter.lessons.getOrNull(lessonIndex) ?: return
    AppScaffold(lesson.title, onBack = { nav.popBackStack() }) { m ->
        Column(m.background(AppTheme.bg).verticalScroll(rememberScrollState())) {
            ReadableWidth {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    // Text
                    Column(Modifier.fillMaxWidth().rounded(AppTheme.cardAlt).padding(16.dp)) {
                        lesson.body.split("\n\n").forEach { paragraph ->
                            if (paragraph.startsWith("**")) {
                                T(paragraph.replace("**", ""), IosFont.subheadline, weight = FontWeight.Bold, modifier = Modifier.padding(bottom = 6.dp))
                            } else {
                                T(paragraph, IosFont.body, modifier = Modifier.padding(bottom = 12.dp))
                            }
                        }
                    }

                    // Zahlen & Fakten
                    if (lesson.stats.isNotEmpty()) {
                        Column(Modifier.fillMaxWidth().rounded(AppTheme.cardAlt), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Row(
                                Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp),
                                horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically,
                            ) {
                                SfIcon("chart.bar.fill", AppTheme.gold, 18.dp)
                                T("Zahlen & Fakten", IosFont.headline, weight = FontWeight.SemiBold)
                            }
                            lesson.stats.forEachIndexed { i, stat ->
                                Row(
                                    Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    T(stat.label, IosFont.subheadline, AppTheme.textSec, modifier = Modifier.weight(1f).padding(end = 8.dp))
                                    T(stat.value, IosFont.subheadline, stat.color, FontWeight.Bold)
                                }
                                if (i < lesson.stats.lastIndex) {
                                    Box(Modifier.padding(horizontal = 16.dp).fillMaxWidth().height(0.5.dp).background(Color.White.copy(alpha = 0.15f)))
                                }
                            }
                            Spacer(Modifier.height(10.dp))
                        }
                    }

                    // Top-Tipp
                    lesson.tip?.let { tip ->
                        Row(
                            Modifier.fillMaxWidth().rounded(AppTheme.gold.copy(alpha = 0.12f)).padding(16.dp),
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            SfIcon("lightbulb.fill", AppTheme.gold, 22.dp, Modifier.padding(top = 2.dp))
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                T("Top-Tipp", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
                                T(tip, IosFont.subheadline)
                            }
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                }
            }
        }
    }
}
