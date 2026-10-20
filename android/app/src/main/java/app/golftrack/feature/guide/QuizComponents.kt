package app.golftrack.feature.guide

import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

/** Dunkle Schrift auf Gold – wie `Color(red: 0.10, green: 0.22, blue: 0.13)` auf iOS. */
val OnGoldDark = rgb(0.10f, 0.22f, 0.13f)

// MARK: - Knöpfe

/** `.goldButton()` mit optionalem Symbol. */
@Composable
fun GoldLabelButton(text: String, icon: String? = null, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Row(
        modifier.fillMaxWidth().background(AppTheme.gold, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick).padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) SfIcon(icon, AppTheme.onGold, 20.dp)
        T(text, IosFont.headline, AppTheme.onGold, FontWeight.SemiBold)
    }
}

/** Flächiger Knopf mit getönter Füllung (z. B. „Antworten durchsehen“, „Fertig“). */
@Composable
fun TintedButton(text: String, fg: Color, bg: Color, icon: String? = null, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(bg, RoundedCornerShape(14.dp)).clickable(onClick = onClick).padding(vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) SfIcon(icon, fg, 18.dp)
        T(text, IosFont.headline, fg, FontWeight.SemiBold)
    }
}

/** `.bordered` bzw. `.borderedProminent` aus SwiftUI. */
@Composable
fun IosButton(
    text: String,
    prominent: Boolean = false,
    tint: Color = AppTheme.gold,
    enabled: Boolean = true,
    icon: String? = null,
    onClick: () -> Unit,
) {
    val bg = when {
        prominent -> tint
        tint == AppTheme.gold && icon != null -> tint.copy(alpha = 0.15f)
        else -> Color.White.copy(alpha = 0.12f)
    }
    val fg = when {
        prominent -> Color.White
        icon != null -> tint
        else -> AppTheme.gold
    }
    Row(
        Modifier.background(if (enabled) bg else bg.copy(alpha = bg.alpha * 0.5f), RoundedCornerShape(50))
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        val c = if (enabled) fg else fg.copy(alpha = 0.35f)
        if (icon != null) SfIcon(icon, c, 16.dp)
        T(text, IosFont.subheadline, c, FontWeight.SemiBold)
    }
}

/** Textknopf in der Titelleiste (iOS-Toolbar). */
@Composable
fun BarTextButton(text: String, bold: Boolean = false, onClick: () -> Unit) {
    T(
        text, IosFont.body, AppTheme.gold, if (bold) FontWeight.SemiBold else null,
        modifier = Modifier.clickable { onClick() }.padding(horizontal = 4.dp, vertical = 8.dp),
    )
}

/**
 * Titelleiste für bildschirmfüllende Ansichten (`fullScreenCover`) – Knöpfe als Text
 * statt Zurück-Pfeil, Titel mittig wie `.navigationBarTitleDisplayMode(.inline)`.
 */
@Composable
fun CoverScaffold(
    title: String,
    leading: @Composable RowScope.() -> Unit = {},
    trailing: @Composable RowScope.() -> Unit = {},
    content: @Composable () -> Unit,
) {
    Column(Modifier.fillMaxSize().background(AppTheme.bg).statusBarsPadding().navigationBarsPadding()) {
        Box(Modifier.fillMaxWidth().heightIn(min = 52.dp).padding(horizontal = 12.dp)) {
            Row(Modifier.align(Alignment.CenterStart), verticalAlignment = Alignment.CenterVertically, content = leading)
            T(title, IosFont.headline, weight = FontWeight.SemiBold, maxLines = 1, modifier = Modifier.align(Alignment.Center).padding(horizontal = 96.dp))
            Row(Modifier.align(Alignment.CenterEnd), verticalAlignment = Alignment.CenterVertically, content = trailing)
        }
        Box(Modifier.weight(1f).fillMaxWidth()) { content() }
    }
}

@Composable
fun IosProgress(value: Float, tint: Color, modifier: Modifier = Modifier) {
    LinearProgressIndicator(
        progress = { value.coerceIn(0f, 1f) },
        modifier = modifier.fillMaxWidth(),
        color = tint,
        trackColor = Color.White.copy(alpha = 0.15f),
        strokeCap = StrokeCap.Round,
        gapSize = 0.dp,
        drawStopIndicator = {},
    )
}

// MARK: - Fragekarten

enum class QuizOptionState { IDLE, SELECTED, CORRECT, WRONG, DIMMED }

fun optionLetter(index: Int): String = ('A' + index).toString()

/** Eine Antwortmöglichkeit – dieselbe Karte in Lernrunde, Prüfung und Auswertung. */
@Composable
fun QuizOptionRow(index: Int, text: String, state: QuizOptionState, onClick: (() -> Unit)? = null) {
    val accent = when (state) {
        QuizOptionState.IDLE, QuizOptionState.DIMMED -> Color.White.copy(alpha = 0.25f)
        QuizOptionState.SELECTED, QuizOptionState.CORRECT -> AppTheme.gold
        QuizOptionState.WRONG -> IosColor.red
    }
    val bg = when (state) {
        QuizOptionState.IDLE, QuizOptionState.DIMMED -> AppTheme.card
        QuizOptionState.SELECTED, QuizOptionState.CORRECT -> AppTheme.gold.copy(alpha = 0.10f)
        QuizOptionState.WRONG -> IosColor.red.copy(alpha = 0.10f)
    }
    val border = when (state) {
        QuizOptionState.IDLE -> Color.White.copy(alpha = 0.12f)
        QuizOptionState.DIMMED -> Color.White.copy(alpha = 0.06f)
        QuizOptionState.SELECTED, QuizOptionState.CORRECT -> AppTheme.gold.copy(alpha = 0.6f)
        QuizOptionState.WRONG -> IosColor.red.copy(alpha = 0.45f)
    }
    val shape = RoundedCornerShape(12.dp)
    var m = Modifier.fillMaxWidth().heightIn(min = 56.dp).background(bg, shape).border(1.5.dp, border, shape)
    if (onClick != null) m = m.clickable(onClick = onClick)
    Row(m.padding(16.dp), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(28.dp).background(accent, CircleShape), contentAlignment = Alignment.Center) {
            T(optionLetter(index), IosFont.caption, Color.White, FontWeight.Bold)
        }
        T(
            text, IosFont.body, AppTheme.text.copy(alpha = if (state == QuizOptionState.DIMMED) 0.6f else 1f),
            modifier = Modifier.weight(1f),
        )
        when (state) {
            QuizOptionState.SELECTED, QuizOptionState.CORRECT -> SfIcon("checkmark.circle.fill", AppTheme.gold, 22.dp)
            QuizOptionState.WRONG -> SfIcon("xmark.circle.fill", IosColor.red, 22.dp)
            else -> {}
        }
    }
}

@Composable
fun QuizCategoryBadge(category: QuizCategory) {
    Row(
        Modifier.background(category.color.copy(alpha = 0.12f), RoundedCornerShape(50)).padding(horizontal = 10.dp, vertical = 5.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        SfIcon(category.icon, category.color, 13.dp)
        T(category.rawValue, IosFont.caption, category.color, FontWeight.Bold)
    }
}

@Composable
fun QuizQuestionHeader(question: QuizQuestion) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        QuizCategoryBadge(question.category)
        T(question.question, IosFont.title3, weight = FontWeight.Bold, modifier = Modifier.fillMaxWidth())
    }
}

/** `wasCorrect == null` in der Auswertung – dort gibt es kein „Richtig/Falsch“, nur die Erklärung. */
@Composable
fun QuizExplanationCard(question: QuizQuestion, wasCorrect: Boolean? = null) {
    val tint = when (wasCorrect) {
        null -> AppTheme.gold
        true -> AppTheme.gold
        false -> IosColor.orange
    }
    val icon = when (wasCorrect) {
        false -> "arrow.uturn.right.circle.fill"
        true -> "checkmark.circle.fill"
        null -> "lightbulb.fill"
    }
    val title = when (wasCorrect) {
        true -> "Richtig!"
        false -> "Nicht ganz – die Frage kommt gleich noch einmal"
        null -> "Erklärung"
    }
    Row(
        Modifier.fillMaxWidth().background(tint.copy(alpha = 0.12f), RoundedCornerShape(14.dp)).padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        SfIcon(icon, tint, 22.dp, Modifier.padding(top = 1.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            T(title, IosFont.caption, if (wasCorrect == null) AppTheme.textSec else tint, FontWeight.Bold)
            T(question.explanation, IosFont.body)
        }
    }
}

// MARK: - Falsche Antworten (WrongAnswerReviewSheet)

/** Blatt mit allen falsch beantworteten Fragen einer Lernrunde, richtige Antwort markiert. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WrongAnswerReviewSheet(
    wrongAnswers: List<Pair<QuizQuestion, Int>>,
    currentIndex: Int,
    onIndexChange: (Int) -> Unit,
    onDismiss: () -> Unit,
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = AppTheme.bg,
        dragHandle = null,
    ) {
        if (wrongAnswers.getOrNull(currentIndex) == null) return@ModalBottomSheet
        Column(Modifier.fillMaxSize()) {
            Box(Modifier.fillMaxWidth().heightIn(min = 52.dp).padding(horizontal = 16.dp)) {
                T("Falsche Antworten", IosFont.headline, weight = FontWeight.SemiBold, modifier = Modifier.align(Alignment.Center))
                Box(Modifier.align(Alignment.CenterEnd)) { BarTextButton("Fertig", bold = true) { Haptics.tap(); onDismiss() } }
            }
            // Fortschritt
            Column(Modifier.fillMaxWidth().background(AppTheme.card).padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                T("${currentIndex + 1} von ${wrongAnswers.size} falsch beantwortet", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
                IosProgress((currentIndex + 1f) / wrongAnswers.size, IosColor.orange)
            }
            Box(Modifier.weight(1f)) {
                AnimatedContent(currentIndex, label = "wrong") { idx ->
                    val (q, chosen) = wrongAnswers[idx]
                    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                        ReadableWidth {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                                QuizQuestionHeader(q)
                                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                    q.options.forEachIndexed { i, option ->
                                        QuizOptionRow(
                                            i, option,
                                            when (i) {
                                                q.correctIndex -> QuizOptionState.CORRECT
                                                chosen -> QuizOptionState.WRONG
                                                else -> QuizOptionState.DIMMED
                                            },
                                        )
                                    }
                                }
                                QuizExplanationCard(q)
                            }
                        }
                    }
                }
            }
            Row(
                Modifier.fillMaxWidth().background(AppTheme.card).padding(16.dp).navigationBarsPadding(),
                horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically,
            ) {
                if (currentIndex > 0) IosButton("Zurück") { Haptics.selection(); onIndexChange(currentIndex - 1) }
                Spacer(Modifier.weight(1f))
                if (currentIndex < wrongAnswers.size - 1) {
                    IosButton("Nächste", prominent = true) { Haptics.selection(); onIndexChange(currentIndex + 1) }
                } else {
                    IosButton("Fertig", prominent = true) { Haptics.tap(); onDismiss() }
                }
            }
        }
    }
}

@Composable
fun FinishTile(value: String, label: String, color: Color, modifier: Modifier) {
    Column(
        modifier.background(AppTheme.card, RoundedCornerShape(14.dp)).padding(vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        T(value, IosFont.title2, color, FontWeight.Bold, maxLines = 1)
        T(label, IosFont.caption, AppTheme.textSec)
    }
}

@Composable
fun BigHeader(icon: String, iconColor: Color, iconSize: Dp, title: String, titleColor: Color, subtitle: String) {
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        SfIcon(icon, iconColor, iconSize)
        T(title, IosFont.title, titleColor, FontWeight.Bold, align = TextAlign.Center)
        T(subtitle, IosFont.subheadline, AppTheme.textSec, align = TextAlign.Center)
    }
}
