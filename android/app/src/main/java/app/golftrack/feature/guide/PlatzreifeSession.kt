package app.golftrack.feature.guide

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import app.golftrack.data.GolfStore
import app.golftrack.data.QuizResult
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

// MARK: - Lernrunde (PlatzreifeSessionView)

/** Zustand einer Lernrunde – als ViewModel, damit er Drehungen übersteht. */
class QuizSessionState(val category: QuizCategory?, val mistakesOnly: Boolean) : ViewModel() {
    private val store = PlatzreifeProgressStore

    val pool: List<QuizQuestion> =
        if (category == null) PlatzreifeQuestions.all else PlatzreifeQuestions.all.filter { it.category == category }

    var sessionQuestions by mutableStateOf<List<QuizQuestion>>(emptyList()); private set
    /** Die aktuelle Frage ist immer `queue.first()`. Falsch beantwortete Fragen werden drei Plätze weiter hinten wieder eingereiht. */
    var queue by mutableStateOf<List<QuizQuestion>>(emptyList()); private set
    var selectedAnswer by mutableStateOf<Int?>(null); private set
    var answeredOnce by mutableStateOf<Set<String>>(emptySet()); private set
    var firstTryCorrect by mutableStateOf<Set<String>>(emptySet()); private set
    var wrongAnswers by mutableStateOf<List<Pair<QuizQuestion, Int>>>(emptyList()); private set
    var masteredBefore by mutableIntStateOf(0); private set
    var readinessBefore by mutableStateOf(0.0); private set
    var startTime by mutableLongStateOf(System.currentTimeMillis()); private set
    var isFinished by mutableStateOf(false); private set
    private var resultSaved = false

    init { startSession() }

    fun startSession() {
        val counts = store.counts(pool)
        masteredBefore = counts.mastered
        readinessBefore = counts.readiness
        sessionQuestions = store.session(pool, mistakesOnly)
        queue = sessionQuestions
        selectedAnswer = null
        answeredOnce = emptySet()
        firstTryCorrect = emptySet()
        wrongAnswers = emptyList()
        resultSaved = false
        startTime = System.currentTimeMillis()
        isFinished = sessionQuestions.isEmpty()
    }

    fun answer(index: Int, question: QuizQuestion) {
        if (selectedAnswer != null) return
        val correct = index == question.correctIndex
        if (correct) Haptics.success() else Haptics.error()
        selectedAnswer = index
        store.record(question, correct)
        if (question.id !in answeredOnce) {
            answeredOnce = answeredOnce + question.id
            if (correct) firstTryCorrect = firstTryCorrect + question.id
            else wrongAnswers = wrongAnswers + (question to index)
        }
    }

    fun nextQuestion() {
        val question = queue.firstOrNull() ?: return
        val rest = queue.drop(1).toMutableList()
        if (selectedAnswer != question.correctIndex) rest.add(minOf(3, rest.size), question)
        queue = rest
        selectedAnswer = null
        if (queue.isEmpty()) {
            Haptics.celebrate()
            saveResult()
            isFinished = true
        }
    }

    val durationSeconds: Int get() = ((System.currentTimeMillis() - startTime) / 1000).toInt()

    fun saveResult() {
        if (resultSaved || answeredOnce.isEmpty()) return
        resultSaved = true
        GolfStore.addQuizResult(QuizResult(mode = "smart", score = firstTryCorrect.size, total = answeredOnce.size, durationSeconds = durationSeconds))
    }
}

fun formatDuration(seconds: Int): String {
    val m = seconds / 60
    val s = seconds % 60
    return if (m > 0) "${m}m ${s}s" else "${s}s"
}

@Composable
fun PlatzreifeSessionScreen(nav: NavController, category: QuizCategory?, mistakesOnly: Boolean) {
    val key = "session-${category?.name}-$mistakesOnly"
    val s: QuizSessionState = viewModel(key = key) { QuizSessionState(category, mistakesOnly) }
    var showQuitConfirm by androidx.compose.runtime.remember { mutableStateOf(false) }

    val title = when {
        mistakesOnly -> "Fehler üben"
        category != null -> category.rawValue
        else -> "Lernrunde"
    }
    val close = { nav.popBackStack(); Unit }
    val requestQuit = {
        Haptics.tap()
        if (s.isFinished || s.answeredOnce.isEmpty()) close() else showQuitConfirm = true
    }
    BackHandler { requestQuit() }

    CoverScaffold(
        title,
        leading = {
            if (s.isFinished) BarTextButton("Schließen") { Haptics.tap(); close() }
            else BarTextButton("Beenden") { requestQuit() }
        },
    ) {
        val question = s.queue.firstOrNull()
        when {
            s.isFinished -> SessionFinishView(s, close)
            question != null -> SessionQuestionView(s, question)
            else -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = AppTheme.gold) }
        }
    }

    if (showQuitConfirm) {
        ConfirmDialog(
            title = "Lernrunde beenden?",
            message = "Was du bisher beantwortet hast, ist gespeichert.",
            confirm = "Beenden", destructive = true, cancel = "Weiterlernen",
            onConfirm = { Haptics.tap(); showQuitConfirm = false; s.saveResult(); close() },
            onDismiss = { Haptics.tap(); showQuitConfirm = false },
        )
    }
}

@Composable
private fun SessionQuestionView(s: QuizSessionState, question: QuizQuestion) {
    val scroll = rememberScrollState()
    LaunchedEffect(s.selectedAnswer) {
        if (s.selectedAnswer != null) scroll.animateScrollTo(scroll.maxValue)
    }
    // Nach einer Antwort wächst der Inhalt – dann bis ans Ende scrollen.
    LaunchedEffect(scroll.maxValue) {
        if (s.selectedAnswer != null) scroll.animateScrollTo(scroll.maxValue)
    }
    LaunchedEffect(question.id, s.queue.size) { scroll.scrollTo(0) }

    Column(Modifier.fillMaxSize().verticalScroll(scroll)) {
        ReadableWidth {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                SessionProgressHeader(s)
                QuizQuestionHeader(question)
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    question.options.forEachIndexed { index, option ->
                        val state = s.selectedAnswer.let { sel ->
                            when {
                                sel == null -> QuizOptionState.IDLE
                                index == question.correctIndex -> QuizOptionState.CORRECT
                                index == sel -> QuizOptionState.WRONG
                                else -> QuizOptionState.DIMMED
                            }
                        }
                        QuizOptionRow(index, option, state) { s.answer(index, question) }
                    }
                }
                val selected = s.selectedAnswer
                AnimatedVisibility(selected != null, enter = fadeIn() + slideInVertically { it / 3 }) {
                    if (selected != null) {
                        Column(verticalArrangement = Arrangement.spacedBy(20.dp)) {
                            QuizExplanationCard(question, wasCorrect = selected == question.correctIndex)
                            GoldLabelButton(
                                if (s.queue.size == 1 && selected == question.correctIndex) "Runde abschließen" else "Nächste Frage",
                            ) { Haptics.tap(); s.nextQuestion() }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SessionProgressHeader(s: QuizSessionState) {
    val done = s.sessionQuestions.size - s.queue.size
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                SfIcon("checkmark.circle.fill", AppTheme.gold, 14.dp)
                T("$done von ${s.sessionQuestions.size} geschafft", IosFont.caption, AppTheme.gold, FontWeight.Bold)
            }
            if (s.wrongAnswers.isNotEmpty()) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    SfIcon("arrow.uturn.backward", IosColor.orange, 14.dp)
                    T("${s.wrongAnswers.size} Fehler", IosFont.caption, IosColor.orange)
                }
            }
        }
        IosProgress(done.toFloat() / maxOf(s.sessionQuestions.size, 1), AppTheme.gold)
    }
}

@Composable
private fun SessionFinishView(s: QuizSessionState, close: () -> Unit) {
    val counts = PlatzreifeProgressStore.counts(s.pool)
    val newlyMastered = maxOf(counts.mastered - s.masteredBefore, 0)
    var showWrongReview by androidx.compose.runtime.remember { mutableStateOf(false) }
    var wrongReviewIndex by androidx.compose.runtime.remember { mutableIntStateOf(0) }

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        ReadableWidth(560.dp) {
            Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
                if (s.sessionQuestions.isEmpty()) {
                    Spacer(Modifier.height(24.dp))
                    BigHeader(
                        "checkmark.seal.fill", AppTheme.gold, 56.dp, "Nichts zu wiederholen", AppTheme.text,
                        "Alle Fehler sind ausgebügelt. Starte eine normale Lernrunde oder eine Probeprüfung.",
                    )
                } else {
                    Spacer(Modifier.height(24.dp))
                    BigHeader(
                        "star.fill", AppTheme.gold, 56.dp, "Lernrunde geschafft!", AppTheme.text,
                        "${s.firstTryCorrect.size} von ${s.sessionQuestions.size} Fragen auf Anhieb richtig.",
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        FinishTile("+$newlyMastered", "Neu sicher", AppTheme.gold, Modifier.weight(1f))
                        FinishTile(
                            "${Math.round(counts.readiness * 100)} %", "Prüfungsreife",
                            if (counts.readiness > s.readinessBefore) AppTheme.gold else AppTheme.text, Modifier.weight(1f),
                        )
                        FinishTile(formatDuration(s.durationSeconds), "Zeit", AppTheme.text, Modifier.weight(1f))
                    }
                }

                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    if (!s.mistakesOnly || counts.toRepeat > 0) {
                        GoldLabelButton("Nächste Lernrunde", "arrow.right.circle.fill") { Haptics.medium(); s.startSession() }
                    }
                    if (s.wrongAnswers.isNotEmpty()) {
                        TintedButton(
                            "${s.wrongAnswers.size} Fehler noch einmal ansehen", IosColor.orange, IosColor.orange.copy(alpha = 0.12f),
                            icon = "exclamationmark.circle",
                        ) { Haptics.tap(); wrongReviewIndex = 0; showWrongReview = true }
                    }
                    TintedButton("Fertig", AppTheme.text, AppTheme.card) { Haptics.tap(); close() }
                }
            }
        }
    }

    if (showWrongReview) {
        WrongAnswerReviewSheet(s.wrongAnswers, wrongReviewIndex, { wrongReviewIndex = it }) { showWrongReview = false }
    }
}
