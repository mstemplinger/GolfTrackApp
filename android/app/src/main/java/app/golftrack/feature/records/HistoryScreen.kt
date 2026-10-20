package app.golftrack.feature.records

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Icon
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.GolfStore
import app.golftrack.data.Round
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.launch

/** Wie HistoryView.swift: abgeschlossene Runden, neueste zuerst. */
@Composable
internal fun HistoryScreen(nav: NavController) {
    val data by GolfStore.data.collectAsState()
    val rounds = data.completedRounds
    var editMode by rememberSaveable { mutableStateOf(false) }
    var roundToDelete by remember { mutableStateOf<Round?>(null) }
    var showDeleteAll by remember { mutableStateOf(false) }

    AppScaffold(
        title = "Verlauf",
        onBack = { nav.popBackStack() },
        actions = {
            if (rounds.isNotEmpty()) {
                if (editMode) {
                    ToolbarTextButton("Alle löschen", color = IosColor.red) { Haptics.tap(); showDeleteAll = true }
                }
                ToolbarTextButton(if (editMode) "Fertig" else "Bearbeiten", bold = editMode) {
                    Haptics.selection(); editMode = !editMode
                }
            }
        },
    ) { m ->
        if (rounds.isEmpty()) {
            EmptyState(Icons.Filled.Schedule, "Keine Runden", "Abgeschlossene Runden erscheinen hier", m)
        } else {
            LazyColumn(m, contentPadding = PaddingValues(vertical = 6.dp)) {
                items(rounds, key = { it.id }) { round ->
                    val course = data.course(round.courseId)
                    SwipeDeleteRow(
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp),
                        onDelete = { Haptics.tap(); roundToDelete = round },
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            AnimatedVisibility(editMode) {
                                Icon(
                                    Icons.Filled.RemoveCircle, contentDescription = "Löschen", tint = IosColor.red,
                                    modifier = Modifier.padding(end = 10.dp).size(24.dp)
                                        .clickable { Haptics.tap(); roundToDelete = round },
                                )
                            }
                            RoundRow(
                                round, course, Modifier.weight(1f),
                                onClick = if (editMode) null else ({ nav.navigate(Routes.roundDetail(round.id)) }),
                            )
                        }
                    }
                }
            }
        }
    }

    roundToDelete?.let { r ->
        val name = data.course(r.courseId)?.name ?: "Unbekannter Platz"
        ConfirmDialog(
            title = "Runde löschen?",
            message = "$name · ${formatDateAbbreviated(r.date)}",
            confirmText = "Löschen",
            onConfirm = { Haptics.warning(); GolfStore.deleteRound(r.id); roundToDelete = null },
            onDismiss = { roundToDelete = null },
        )
    }
    if (showDeleteAll) {
        ConfirmDialog(
            title = "Alle ${rounds.size} Runden löschen?",
            message = "Diese Aktion kann nicht rückgängig gemacht werden.",
            confirmText = "Alle löschen",
            onConfirm = {
                Haptics.warning()
                val ids = rounds.map { it.id }.toSet()
                GolfStore.update { d -> d.copy(rounds = d.rounds.filter { it.id !in ids }) }
                editMode = false
                showDeleteAll = false
            },
            onDismiss = { showDeleteAll = false },
        )
    }
}

/** Wischen nach links zeigt „Löschen" (wie `.swipeActions`). */
@Composable
internal fun SwipeDeleteRow(modifier: Modifier = Modifier, onDelete: () -> Unit, content: @Composable () -> Unit) {
    val state = rememberSwipeToDismissBoxState()
    val scope = rememberCoroutineScope()
    SwipeToDismissBox(
        state = state,
        modifier = modifier,
        enableDismissFromStartToEnd = false,
        onDismiss = { value ->
            if (value == SwipeToDismissBoxValue.EndToStart) onDelete()
            scope.launch { state.reset() }
        },
        backgroundContent = {
            // Nur beim Wischen rot hinterlegen – sonst blitzt es an den runden Ecken durch.
            if (state.dismissDirection != SwipeToDismissBoxValue.EndToStart) return@SwipeToDismissBox
            Box(
                Modifier.fillMaxSize().background(IosColor.red, RoundedCornerShape(12.dp)).padding(horizontal = 20.dp),
                contentAlignment = Alignment.CenterEnd,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Filled.Delete, contentDescription = null, tint = AppTheme.text)
                    Text("Löschen", color = AppTheme.text, fontSize = IosFont.caption)
                }
            }
        },
    ) { content() }
}

/** Wie RoundRowView.swift. */
@Composable
internal fun RoundRow(round: Round, course: Course?, modifier: Modifier = Modifier, onClick: (() -> Unit)? = null) {
    var m = modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(12.dp))
    if (onClick != null) m = m.clickable { Haptics.tap(); onClick() }
    Row(m.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                course?.name ?: "Unbekannter Platz", color = AppTheme.text, fontSize = IosFont.headline,
                fontWeight = FontWeight.SemiBold, maxLines = 2, overflow = TextOverflow.Ellipsis,
            )
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(formatDateAbbreviated(round.date), color = AppTheme.textSec, fontSize = IosFont.caption)
                if (!round.isComplete) {
                    Text(
                        "Aktiv", color = IosColor.orange, fontSize = IosFont.caption2, fontWeight = FontWeight.Bold,
                        modifier = Modifier.background(IosColor.orange.copy(alpha = 0.2f), RoundedCornerShape(50))
                            .padding(horizontal = 6.dp, vertical = 2.dp),
                    )
                }
            }
        }
        Spacer(Modifier.width(8.dp))
        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                round.scoreLabel(course), color = golfScoreColor(round.scoreToPar(course)),
                fontSize = IosFont.title3, fontWeight = FontWeight.Bold,
            )
            if (round.totalStrokes > 0) {
                Text("${round.totalStrokes} Schläge", color = AppTheme.textSec, fontSize = IosFont.caption)
            }
        }
    }
}
