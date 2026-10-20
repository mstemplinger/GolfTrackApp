package app.golftrack.feature.guide

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import app.golftrack.data.GolfStore
import app.golftrack.data.QuizResult
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.delay

// MARK: - Probeprüfung (ExamModeView)

class ExamState : ViewModel() {
    companion object {
        const val QUESTION_COUNT = 30
        const val PASS_MARK = 23

        /** 15 Regelfragen (Regeln + Regelanwendung) und 15 allgemeine Fragen, gemischt. */
        fun makeExam(): List<QuizQuestion> {
            val half = QUESTION_COUNT / 2
            val rules = PlatzreifeQuestions.all.filter { it.category.isRulesCategory }.shuffled().take(half)
            val general = PlatzreifeQuestions.all.filter { !it.category.isRulesCategory }.shuffled().take(half)
            return (rules + general).shuffled()
        }
    }

    /** Einmal ausgelost – ein Neuaufbau der Ansicht ändert die Fragen nicht. */
    val questions: List<QuizQuestion> = makeExam()
    var answers by mutableStateOf(List<Int?>(QUESTION_COUNT) { null }); private set
    var currentIndex by mutableIntStateOf(0)
    var timeRemaining by mutableIntStateOf(30 * 60); private set
    var isFinished by mutableStateOf(false); private set
    var reviewMode by mutableStateOf(false)
    var reviewIndex by mutableIntStateOf(0)
    private val startTime = System.currentTimeMillis()

    val correctCount: Int get() = questions.indices.count { answers[it] == questions[it].correctIndex }
    val answeredCount: Int get() = answers.count { it != null }
    val wrongCount: Int get() = questions.indices.count { answers[it] != null && answers[it] != questions[it].correctIndex }
    val passed: Boolean get() = correctCount >= PASS_MARK

    fun select(index: Int) {
        answers = answers.toMutableList().also { it[currentIndex] = index }
    }

    fun tick() {
        if (isFinished) return
        if (timeRemaining > 0) timeRemaining -= 1 else submit()
    }

    fun submit() {
        if (isFinished) return
        questions.forEachIndexed { i, q ->
            val a = answers[i] ?: return@forEachIndexed
            PlatzreifeProgressStore.record(q, a == q.correctIndex)
        }
        val duration = ((System.currentTimeMillis() - startTime) / 1000).toInt()
        val result = QuizResult(mode = "exam", score = correctCount, total = QUESTION_COUNT, durationSeconds = duration)
        if (result.passed) Haptics.celebrate() else Haptics.warning()
        GolfStore.addQuizResult(result)
        isFinished = true
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlatzreifeExamScreen(nav: NavController) {
    val s: ExamState = viewModel()
    var showQuitConfirm by remember { mutableStateOf(false) }
    var showSubmitConfirm by remember { mutableStateOf(false) }
    var showNavigator by remember { mutableStateOf(false) }
    val close = { nav.popBackStack(); Unit }

    LaunchedEffect(s.isFinished) {
        while (!s.isFinished) {
            delay(1000)
            s.tick()
        }
    }

    val requestSubmit = {
        if (s.answeredCount < ExamState.QUESTION_COUNT) {
            Haptics.warning()
            showSubmitConfirm = true
        } else s.submit()
    }

    BackHandler {
        Haptics.tap()
        when {
            s.reviewMode -> s.reviewMode = false
            s.isFinished -> close()
            else -> showQuitConfirm = true
        }
    }

    CoverScaffold(
        "Probeprüfung",
        leading = {
            if (s.reviewMode) BarTextButton("Zurück") { Haptics.tap(); s.reviewMode = false }
            else if (!s.isFinished) BarTextButton("Abbrechen") { Haptics.tap(); showQuitConfirm = true }
        },
        trailing = {
            if (s.reviewMode || s.isFinished) BarTextButton("Schließen", bold = true) { Haptics.tap(); close() }
            else TimerBadge(s.timeRemaining)
        },
    ) {
        when {
            s.reviewMode -> ExamReviewView(s)
            s.isFinished -> ExamResultView(s, nav, close)
            else -> ExamQuestionView(s, onNavigator = { Haptics.tap(); showNavigator = true }, onSubmit = requestSubmit)
        }
    }

    if (showQuitConfirm) {
        ConfirmDialog(
            title = "Prüfung abbrechen?", message = "Das Ergebnis wird nicht gespeichert.",
            confirm = "Abbrechen", destructive = true, cancel = "Weitermachen",
            onConfirm = { Haptics.tap(); showQuitConfirm = false; close() },
            onDismiss = { Haptics.tap(); showQuitConfirm = false },
        )
    }
    if (showSubmitConfirm) {
        ConfirmDialog(
            title = "Prüfung abgeben?",
            message = "${ExamState.QUESTION_COUNT - s.answeredCount} Fragen sind noch offen und zählen als falsch.",
            confirm = "Abgeben", destructive = false, cancel = "Weiter beantworten",
            onConfirm = { showSubmitConfirm = false; s.submit() },
            onDismiss = { Haptics.tap(); showSubmitConfirm = false },
        )
    }
    if (showNavigator) {
        ModalBottomSheet(
            onDismissRequest = { showNavigator = false },
            sheetState = rememberModalBottomSheetState(),
            containerColor = AppTheme.bg,
            dragHandle = null,
        ) {
            Box(Modifier.fillMaxWidth().heightIn(min = 52.dp).padding(horizontal = 16.dp)) {
                T("Übersicht", IosFont.headline, weight = FontWeight.SemiBold, modifier = Modifier.align(Alignment.Center))
                Box(Modifier.align(Alignment.CenterEnd)) { BarTextButton("Fertig", bold = true) { showNavigator = false } }
            }
            Column(Modifier.verticalScroll(rememberScrollState()).navigationBarsPadding()) {
                ExamNavigator(
                    s,
                    onPick = { Haptics.selection(); s.currentIndex = it; showNavigator = false },
                    onSubmit = { Haptics.tap(); showNavigator = false; requestSubmit() },
                )
            }
        }
    }
}

@Composable
private fun TimerBadge(timeRemaining: Int) {
    val isLow = timeRemaining < 5 * 60
    val fg = if (isLow) IosColor.red else AppTheme.text
    Row(
        Modifier.background(if (isLow) IosColor.red.copy(alpha = 0.1f) else Color.White.copy(alpha = 0.1f), RoundedCornerShape(50))
            .padding(horizontal = 10.dp, vertical = 5.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically,
    ) {
        SfIcon("clock", fg, 13.dp)
        T("%02d:%02d".format(timeRemaining / 60, timeRemaining % 60), IosFont.caption, fg, FontWeight.Bold)
    }
}

// MARK: Fragenübersicht

@Composable
private fun ExamNavigator(s: ExamState, onPick: (Int) -> Unit, onSubmit: () -> Unit) {
    Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        T("${s.answeredCount} von ${ExamState.QUESTION_COUNT} beantwortet", IosFont.caption, AppTheme.textSec)
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            s.questions.indices.chunked(5).forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    row.forEach { index ->
                        val answered = s.answers[index] != null
                        val shape = RoundedCornerShape(10.dp)
                        Box(
                            Modifier.weight(1f).heightIn(min = 40.dp)
                                .background(if (answered) AppTheme.gold else AppTheme.cardAlt, shape)
                                .border(if (index == s.currentIndex) 2.dp else 0.dp, if (index == s.currentIndex) Color.White else Color.Transparent, shape)
                                .clickable { onPick(index) },
                            contentAlignment = Alignment.Center,
                        ) {
                            T("${index + 1}", IosFont.subheadline, if (answered) OnGoldDark else AppTheme.text, FontWeight.Bold)
                        }
                    }
                }
            }
        }
        TintedButton("Prüfung abgeben", AppTheme.gold, AppTheme.gold.copy(alpha = 0.15f)) { onSubmit() }
    }
}

// MARK: Frage

@Composable
private fun ExamQuestionView(s: ExamState, onNavigator: () -> Unit, onSubmit: () -> Unit) {
    Column(Modifier.fillMaxSize()) {
        ReadableWidth {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row {
                    T("Frage ${s.currentIndex + 1} von ${ExamState.QUESTION_COUNT}", IosFont.caption, AppTheme.textSec, FontWeight.Bold, Modifier.weight(1f))
                    T("${s.answeredCount} beantwortet", IosFont.caption, AppTheme.textSec)
                }
                IosProgress(s.answeredCount.toFloat() / ExamState.QUESTION_COUNT, AppTheme.gold)
            }
        }
        Box(Modifier.weight(1f)) {
            AnimatedContent(s.currentIndex, label = "exam") { idx ->
                val q = s.questions[idx]
                Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                    ReadableWidth {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                            QuizQuestionHeader(q)
                            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                q.options.forEachIndexed { i, option ->
                                    QuizOptionRow(i, option, if (s.answers[idx] == i) QuizOptionState.SELECTED else QuizOptionState.IDLE) {
                                        Haptics.selection(); s.select(i)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        Box(Modifier.fillMaxWidth().background(AppTheme.card)) {
            ReadableWidth {
                Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    IosButton("Zurück", enabled = s.currentIndex > 0) { Haptics.selection(); s.currentIndex -= 1 }
                    Spacer(Modifier.weight(1f))
                    IosButton("Übersicht", icon = "square.grid.3x3.fill") { onNavigator() }
                    Spacer(Modifier.weight(1f))
                    if (s.currentIndex < ExamState.QUESTION_COUNT - 1) {
                        IosButton("Weiter", prominent = true) { Haptics.selection(); s.currentIndex += 1 }
                    } else {
                        IosButton(
                            "Prüfung abgeben", prominent = true,
                            tint = if (s.answeredCount == ExamState.QUESTION_COUNT) AppTheme.gold else IosColor.orange,
                        ) { onSubmit() }
                    }
                }
            }
        }
    }
}

// MARK: Ergebnis

@Composable
private fun ExamResultView(s: ExamState, nav: NavController, close: () -> Unit) {
    val passed = s.passed
    val tint = if (passed) AppTheme.gold else IosColor.red
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        ReadableWidth(620.dp) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
                Box(Modifier.padding(16.dp)) {
                    BigHeader(
                        if (passed) "checkmark.seal.fill" else "xmark.seal.fill", tint, 64.dp,
                        if (passed) "Bestanden!" else "Nicht bestanden", tint,
                        if (passed) "Herzlichen Glückwunsch! Du hast die Probeprüfung bestanden." else "Übe noch etwas weiter und versuche es erneut.",
                    )
                }

                Column(
                    Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(30.dp, Alignment.CenterHorizontally), verticalAlignment = Alignment.CenterVertically) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            T("${s.correctCount}", 48.sp, tint, FontWeight.Bold)
                            T("Richtig", IosFont.caption, AppTheme.textSec)
                        }
                        T("/", 36.sp, AppTheme.textSec, FontWeight.Thin)
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            T("${ExamState.QUESTION_COUNT}", 48.sp, weight = FontWeight.Bold)
                            T("Gesamt", IosFont.caption, AppTheme.textSec)
                        }
                    }

                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            T("${(s.correctCount.toDouble() / ExamState.QUESTION_COUNT * 100).toInt()} %", IosFont.headline, weight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            T("Mindestens 75 % (23/30)", IosFont.caption, AppTheme.textSec)
                        }
                        BoxWithConstraints(Modifier.fillMaxWidth().height(12.dp)) {
                            val w = maxWidth
                            Box(Modifier.fillMaxSize().background(Color.White.copy(alpha = 0.15f), RoundedCornerShape(6.dp)))
                            Box(
                                Modifier.width(w * (s.correctCount.toFloat() / ExamState.QUESTION_COUNT)).height(12.dp)
                                    .background(tint, RoundedCornerShape(6.dp)),
                            )
                            Box(
                                Modifier.offset(x = w * (ExamState.PASS_MARK.toFloat() / ExamState.QUESTION_COUNT) - 1.dp, y = (-4).dp)
                                    .width(2.dp).height(20.dp).background(Color.White.copy(alpha = 0.4f)),
                            )
                        }
                    }

                    CategoryBreakdown(s)
                }

                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    if (s.wrongCount > 0) {
                        GoldLabelButton("Fehler jetzt üben", "arrow.uturn.backward.circle.fill") {
                            Haptics.medium()
                            nav.navigate(GuideNav.session(null, true))
                        }
                    }
                    TintedButton("Antworten durchsehen", AppTheme.gold, AppTheme.gold.copy(alpha = 0.12f)) {
                        Haptics.tap(); s.reviewIndex = 0; s.reviewMode = true
                    }
                    TintedButton("Fertig", AppTheme.text, AppTheme.card) { Haptics.tap(); close() }
                }
                Spacer(Modifier.height(20.dp))
            }
        }
    }
}

@Composable
private fun CategoryBreakdown(s: ExamState) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        T("Nach Kategorie", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
        QuizCategory.entries.forEach { category ->
            val indices = s.questions.indices.filter { s.questions[it].category == category }
            if (indices.isNotEmpty()) {
                val correct = indices.count { s.answers[it] == s.questions[it].correctIndex }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.width(18.dp), contentAlignment = Alignment.Center) { SfIcon(category.icon, category.color, 13.dp) }
                    T(category.rawValue, IosFont.caption, AppTheme.textSec, modifier = Modifier.weight(1f))
                    T(
                        "$correct/${indices.size}", IosFont.caption,
                        when {
                            correct == indices.size -> AppTheme.gold
                            correct * 2 >= indices.size -> IosColor.orange
                            else -> IosColor.red
                        },
                        FontWeight.Bold,
                    )
                }
            }
        }
    }
}

// MARK: Durchsicht

@Composable
private fun ExamReviewView(s: ExamState) {
    Column(Modifier.fillMaxSize()) {
        Box(Modifier.weight(1f)) {
            AnimatedContent(s.reviewIndex, label = "review") { idx ->
                val question = s.questions[idx]
                val userAnswer = s.answers[idx]
                val isCorrect = userAnswer == question.correctIndex
                val statusColor = if (isCorrect) AppTheme.gold else if (userAnswer == null) AppTheme.textSec else IosColor.red
                Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
                    ReadableWidth {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Row(
                                    Modifier.background(statusColor.copy(alpha = 0.12f), RoundedCornerShape(50)).padding(horizontal = 10.dp, vertical = 5.dp),
                                    horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    SfIcon(
                                        if (isCorrect) "checkmark.circle.fill" else if (userAnswer == null) "minus.circle" else "xmark.circle.fill",
                                        statusColor, 13.dp,
                                    )
                                    T(
                                        if (isCorrect) "Richtig" else if (userAnswer == null) "Nicht beantwortet" else "Falsch",
                                        IosFont.caption, statusColor, FontWeight.Bold,
                                    )
                                }
                                Spacer(Modifier.weight(1f))
                                T("Frage ${idx + 1} von ${ExamState.QUESTION_COUNT}", IosFont.caption, AppTheme.textSec)
                            }
                            QuizQuestionHeader(question)
                            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                question.options.forEachIndexed { i, option ->
                                    QuizOptionRow(
                                        i, option,
                                        when (i) {
                                            question.correctIndex -> QuizOptionState.CORRECT
                                            userAnswer -> QuizOptionState.WRONG
                                            else -> QuizOptionState.DIMMED
                                        },
                                    )
                                }
                            }
                            QuizExplanationCard(question)
                        }
                    }
                }
            }
        }
        Box(Modifier.fillMaxWidth().background(AppTheme.card)) {
            ReadableWidth {
                Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    IosButton("Zurück", enabled = s.reviewIndex > 0) { Haptics.selection(); s.reviewIndex -= 1 }
                    Spacer(Modifier.weight(1f))
                    if (s.reviewIndex < ExamState.QUESTION_COUNT - 1) {
                        IosButton("Nächste", prominent = true) { Haptics.selection(); s.reviewIndex += 1 }
                    } else {
                        IosButton("Fertig", prominent = true) { Haptics.tap(); s.reviewMode = false }
                    }
                }
            }
        }
    }
}
