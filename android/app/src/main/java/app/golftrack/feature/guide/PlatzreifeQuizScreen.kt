package app.golftrack.feature.guide

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.data.GolfStore
import app.golftrack.data.QuizResult
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// MARK: - Übersicht (PlatzreifeQuizView)

@Composable
fun PlatzreifeQuizScreen(nav: NavController) {
    val data by GolfStore.data.collectAsState()
    val results = remember(data.quizResults) { data.quizResults.sortedByDescending { it.date } }
    val store = PlatzreifeProgressStore
    val catalog = PlatzreifeQuestions.all
    val counts = store.counts(catalog)
    val examResults = results.filter { it.mode == "exam" }
    val bestExam = examResults.maxByOrNull { it.percentage }

    var showMenu by remember { mutableStateOf(false) }
    var showResetConfirm by remember { mutableStateOf(false) }
    var showDeleteAllConfirm by remember { mutableStateOf(false) }
    var showAllResults by rememberSaveable { mutableStateOf(false) }

    AppScaffold(
        "Platzreife lernen", onBack = { nav.popBackStack() },
        actions = {
            Box {
                IconButton(onClick = { Haptics.tap(); showMenu = true }) { SfIcon("ellipsis.circle", AppTheme.gold, 24.dp) }
                DropdownMenu(showMenu, onDismissRequest = { showMenu = false }, containerColor = AppTheme.cardAlt) {
                    DropdownMenuItem(
                        text = { Text("Lernfortschritt zurücksetzen", color = IosColor.red) },
                        leadingIcon = { SfIcon("arrow.counterclockwise", IosColor.red, 20.dp) },
                        onClick = { Haptics.tap(); showMenu = false; showResetConfirm = true },
                    )
                }
            }
        },
    ) { m ->
        Column(m.background(AppTheme.bg).verticalScroll(rememberScrollState())) {
            ReadableWidth(1000.dp) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
                    ReadinessCard(counts)
                    LearnActions(counts, bestExam, nav)
                    CategorySection(catalog, nav)
                    if (results.isNotEmpty()) {
                        HistorySection(
                            results, examResults, bestExam, showAllResults,
                            onToggleAll = { Haptics.tap(); showAllResults = !showAllResults },
                            onDeleteAll = { Haptics.tap(); showDeleteAllConfirm = true },
                        )
                    }
                    RulesLink { nav.navigate(Routes.RULES) }
                }
            }
        }
    }

    if (showResetConfirm) {
        ConfirmDialog(
            title = "Lernfortschritt zurücksetzen?",
            message = "Alle Fragen gelten danach wieder als neu. Deine Prüfungsergebnisse bleiben erhalten.",
            confirm = "Zurücksetzen", destructive = true,
            onConfirm = { Haptics.warning(); store.reset(); showResetConfirm = false },
            onDismiss = { Haptics.tap(); showResetConfirm = false },
        )
    }
    if (showDeleteAllConfirm) {
        ConfirmDialog(
            title = "Alle Ergebnisse löschen?", message = null,
            confirm = "Alle löschen", destructive = true,
            onConfirm = {
                Haptics.warning()
                GolfStore.update { it.copy(quizResults = emptyList()) }
                showDeleteAllConfirm = false
            },
            onDismiss = { Haptics.tap(); showDeleteAllConfirm = false },
        )
    }
}

@Composable
fun ConfirmDialog(
    title: String,
    message: String?,
    confirm: String,
    destructive: Boolean,
    cancel: String = "Abbrechen",
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        containerColor = AppTheme.card,
        title = { Text(title, color = AppTheme.text) },
        text = message?.let { { Text(it, color = AppTheme.textSec) } },
        confirmButton = {
            TextButton(onClick = onConfirm) { Text(confirm, color = if (destructive) IosColor.red else AppTheme.gold, fontWeight = FontWeight.SemiBold) }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(cancel, color = AppTheme.gold) } },
    )
}

// MARK: Prüfungsreife

@Composable
private fun ReadinessCard(counts: QuizStatusCounts) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(20.dp)).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(20.dp), verticalAlignment = Alignment.CenterVertically) {
            ReadinessRing(counts.readiness, Modifier.size(112.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                T("PRÜFUNGSREIFE", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
                T("${counts.mastered} von ${counts.total} Fragen sitzen", IosFont.title3, weight = FontWeight.Bold)
                T(hintText(counts), IosFont.subheadline, AppTheme.textSec)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            StatusChip(counts.mastered, "Sicher", AppTheme.gold, Modifier.weight(1f))
            StatusChip(counts.toRepeat, "Wiederholen", IosColor.orange, Modifier.weight(1f))
            StatusChip(counts.new, "Neu", AppTheme.textSec, Modifier.weight(1f))
        }
    }
}

private fun hintText(counts: QuizStatusCounts): String = when {
    counts.total == counts.new -> "Starte mit einer Lernrunde: 20 gemischte Fragen aus allen Themen."
    counts.readiness >= 0.9 -> "Du bist gut vorbereitet. Teste dich jetzt in einer Probeprüfung."
    counts.toRepeat > 0 -> "${counts.toRepeat} Fragen solltest du noch einmal üben."
    else -> "Weiter so – jede Lernrunde bringt dich näher an die Prüfung."
}

@Composable
private fun StatusChip(count: Int, label: String, color: Color, modifier: Modifier) {
    Column(
        modifier.background(AppTheme.cardAlt, RoundedCornerShape(12.dp)).padding(horizontal = 12.dp, vertical = 10.dp),
        verticalArrangement = Arrangement.spacedBy(2.dp),
    ) {
        T("$count", IosFont.headline, color, FontWeight.SemiBold)
        T(label, IosFont.caption, AppTheme.textSec, maxLines = 1)
    }
}

@Composable
private fun ReadinessRing(value: Double, modifier: Modifier) {
    var started by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { started = true }
    val shown by animateFloatAsState(if (started) value.toFloat() else 0f, tween(800), label = "ring")
    Box(modifier, contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val sw = 12.dp.toPx()
            val inset = sw / 2
            val arcSize = Size(size.width - sw, size.height - sw)
            drawArc(Color.White.copy(alpha = 0.08f), 0f, 360f, false, Offset(inset, inset), arcSize, style = Stroke(sw))
            drawArc(AppTheme.gold, -90f, 360f * shown, false, Offset(inset, inset), arcSize, style = Stroke(sw, cap = StrokeCap.Round))
        }
        T("${Math.round(value * 100)} %", IosFont.title2, weight = FontWeight.Bold)
    }
}

// MARK: Lernen & Prüfen

@Composable
private fun LearnActions(counts: QuizStatusCounts, bestExam: QuizResult?, nav: NavController) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            Modifier.fillMaxWidth().background(AppTheme.gold, RoundedCornerShape(16.dp))
                .clickable { Haptics.medium(); nav.navigate(GuideNav.session(null, false)) }
                .padding(18.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically,
        ) {
            SfIcon("brain.head.profile", OnGoldDark, 28.dp)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                T(if (counts.total == counts.new) "Erste Lernrunde starten" else "Weiterlernen", IosFont.headline, OnGoldDark, FontWeight.SemiBold)
                T("20 Fragen · Fehler kommen zuerst dran", IosFont.caption, OnGoldDark.copy(alpha = 0.8f))
            }
            SfIcon("chevron.right", OnGoldDark, 20.dp)
        }

        if (counts.toRepeat > 0) {
            ActionRow("arrow.uturn.backward.circle.fill", IosColor.orange, "Fehler üben", "${counts.toRepeat} Fragen, die noch wackeln") {
                nav.navigate(GuideNav.session(null, true))
            }
        }

        ActionRow(
            "checkmark.seal.fill", AppTheme.gold, "Probeprüfung",
            bestExam?.let { "30 Fragen · 30 Minuten · Bestwert ${it.percentage.toInt()} %" } ?: "30 Fragen · 30 Minuten · bestanden ab 75 %",
        ) { nav.navigate(GuideNav.EXAM) }
    }
}

@Composable
fun ActionRow(icon: String, color: Color, title: String, subtitle: String, haptic: Boolean = true, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))
            .clickable { if (haptic) Haptics.medium(); onClick() }.padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        IconTile(icon, color, radius = 12.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            T(title, IosFont.headline, AppTheme.text, FontWeight.SemiBold)
            T(subtitle, IosFont.caption, AppTheme.textSec)
        }
        SfIcon("chevron.right", AppTheme.textTer, 20.dp)
    }
}

// MARK: Themengebiete

@Composable
private fun CategorySection(catalog: List<QuizQuestion>, nav: NavController) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        T("Themengebiete", IosFont.headline, weight = FontWeight.SemiBold)
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val columns = maxOf(1, ((maxWidth.value + 12) / (150 + 12)).toInt())
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                QuizCategory.entries.chunked(columns).forEach { row ->
                    Row(Modifier.fillMaxWidth().height(androidx.compose.foundation.layout.IntrinsicSize.Max), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        row.forEach { category ->
                            CategoryCard(category, catalog.filter { it.category == category }, Modifier.weight(1f).fillMaxHeight()) {
                                nav.navigate(GuideNav.session(category, false))
                            }
                        }
                        repeat(columns - row.size) { Spacer(Modifier.weight(1f)) }
                    }
                }
            }
        }
    }
}

@Composable
private fun CategoryCard(category: QuizCategory, pool: List<QuizQuestion>, modifier: Modifier, onClick: () -> Unit) {
    val c = PlatzreifeProgressStore.counts(pool)
    Column(
        modifier.background(AppTheme.card, RoundedCornerShape(16.dp)).clickable { Haptics.medium(); onClick() }.padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconTile(category.icon, category.color, size = 36.dp, iconSize = 18.dp)
            Spacer(Modifier.weight(1f))
            if (c.wrong > 0) {
                T(
                    "${c.wrong}", IosFont.caption2, Color.White, FontWeight.Bold,
                    modifier = Modifier.background(IosColor.orange, RoundedCornerShape(50)).padding(horizontal = 7.dp, vertical = 3.dp),
                )
            }
        }
        androidx.compose.material3.Text(
            category.rawValue, color = AppTheme.text, fontSize = IosFont.subheadline, fontWeight = FontWeight.Bold,
            minLines = 2, maxLines = 2,
        )
        T("${c.mastered} von ${c.total} sicher", IosFont.caption, AppTheme.textSec)
        ProgressSegments(c, category.color)
    }
}

/** Fortschrittsbalken mit zwei Stufen: sicher (voll) und angefangen (blass). */
@Composable
private fun ProgressSegments(counts: QuizStatusCounts, tint: Color) {
    val total = maxOf(counts.total, 1).toFloat()
    val mastered = counts.mastered / total
    val started = (counts.learning + counts.wrong) / total
    Box(Modifier.fillMaxWidth().height(6.dp).background(Color.White.copy(alpha = 0.08f), CircleShape)) {
        if (mastered + started > 0) Box(Modifier.fillMaxWidth(mastered + started).fillMaxHeight().background(tint.copy(alpha = 0.35f), CircleShape))
        if (mastered > 0) Box(Modifier.fillMaxWidth(mastered).fillMaxHeight().background(tint, CircleShape))
    }
}

// MARK: Ergebnisse

private val resultDateFormat = SimpleDateFormat("d. MMM yyyy, HH:mm", Locale.GERMAN)

@Composable
private fun HistorySection(
    results: List<QuizResult>,
    examResults: List<QuizResult>,
    bestExam: QuizResult?,
    showAll: Boolean,
    onToggleAll: () -> Unit,
    onDeleteAll: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            T("Ergebnisse", IosFont.headline, weight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
            Row(
                Modifier.clickable { onDeleteAll() }.padding(4.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically,
            ) {
                SfIcon("trash", IosColor.red, 14.dp)
                T("Alle löschen", IosFont.caption, IosColor.red)
            }
        }

        if (examResults.isNotEmpty()) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                StatCell("${examResults.size}", "Prüfungen", "doc.text.fill", AppTheme.gold, Modifier.weight(1f))
                StatCell("${examResults.count { it.passed }}", "Bestanden", "checkmark.circle.fill", AppTheme.gold, Modifier.weight(1f))
                bestExam?.let { StatCell("${it.percentage.toInt()} %", "Bestleistung", "star.fill", IosColor.orange, Modifier.weight(1f)) }
            }
        }

        val displayed = if (showAll) results else results.take(5)
        Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))) {
            displayed.forEachIndexed { i, result ->
                ResultRow(result)
                if (i < displayed.lastIndex) {
                    Box(Modifier.padding(start = 62.dp).fillMaxWidth().height(0.5.dp).background(Color.White.copy(alpha = 0.15f)))
                }
            }
        }

        if (results.size > 5) {
            Row(
                Modifier.fillMaxWidth().clickable { onToggleAll() }.padding(vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically,
            ) {
                T(if (showAll) "Weniger anzeigen" else "Alle ${results.size} Ergebnisse anzeigen", IosFont.subheadline, AppTheme.gold)
                SfIcon(if (showAll) "chevron.up" else "chevron.down", AppTheme.gold, 18.dp)
            }
        }
    }
}

@Composable
private fun StatCell(value: String, label: String, icon: String, color: Color, modifier: Modifier) {
    Column(
        modifier.background(AppTheme.card, RoundedCornerShape(14.dp)).padding(vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        SfIcon(icon, color, 22.dp)
        T(value, IosFont.title3, weight = FontWeight.Bold)
        T(label, IosFont.caption2, AppTheme.textSec)
    }
}

@Composable
private fun ResultRow(result: QuizResult) {
    val isExam = result.mode == "exam"
    val tint = if (isExam) (if (result.passed) AppTheme.gold else IosColor.red) else IosColor.blue
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(36.dp).background(tint.copy(alpha = 0.13f), CircleShape), contentAlignment = Alignment.Center) {
            SfIcon(if (isExam) (if (result.passed) "checkmark.seal.fill" else "xmark.seal.fill") else "brain.head.profile", tint, 17.dp)
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            T(if (isExam) "Probeprüfung" else "Lernrunde", IosFont.subheadline, weight = FontWeight.Bold)
            T(resultDateFormat.format(Date(result.date)), IosFont.caption, AppTheme.textSec)
            if (isExam) {
                T(if (result.passed) "Bestanden ✓" else "Nicht bestanden", IosFont.caption2, tint, FontWeight.Bold)
            } else {
                T(result.durationFormatted, IosFont.caption2, AppTheme.textSec)
            }
        }
        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
            T("${result.score}/${result.total}", IosFont.subheadline, tint, FontWeight.Bold)
            T("${result.percentage.toInt()} %", IosFont.caption, AppTheme.textSec)
        }
        Box(
            Modifier.background(IosColor.red.copy(alpha = 0.08f), CircleShape)
                .clickable {
                    Haptics.warning()
                    GolfStore.update { d -> d.copy(quizResults = d.quizResults.filter { it.id != result.id }) }
                }
                .padding(8.dp),
        ) { SfIcon("trash", IosColor.red.copy(alpha = 0.7f), 14.dp) }
    }
}

// MARK: Regeln

@Composable
private fun RulesLink(onClick: () -> Unit) {
    ActionRow("book.closed.fill", IosColor.red, "Golfregeln nachlesen", "Das Regelwerk mit Diagrammen – zum Nachschlagen beim Lernen", haptic = false, onClick = onClick)
}
