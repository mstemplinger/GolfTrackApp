package app.golftrack.feature.minigolf

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.GolfCourse
import androidx.compose.material.icons.filled.Place
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import java.util.Locale

/** Alle gespeicherten Minigolf-Partien – wie `MinigolfHistoryView`. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun MinigolfHistoryScreen(nav: NavController) {
    var history by remember { mutableStateOf(MinigolfGameStore.loadHistory()) }
    var selected by remember { mutableStateOf<MinigolfHistoryEntry?>(null) }
    var showClearConfirm by remember { mutableStateOf(false) }

    AppScaffold(
        "Minigolf-Verlauf",
        onBack = { nav.popBackStack() },
        actions = {
            if (history.isNotEmpty()) {
                TextButton(onClick = { Haptics.tap(); showClearConfirm = true }) { Text("Alle löschen", color = MgRed) }
            }
        },
    ) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp).animateContentSize(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            if (history.isEmpty()) {
                Column(
                    Modifier.mgCard().padding(vertical = 24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    Icon(Icons.Filled.GolfCourse, null, tint = AppTheme.gold.copy(alpha = 0.6f), modifier = Modifier.size(44.dp))
                    MgText("Noch keine Partie gespeichert", MgFont.headline, weight = FontWeight.SemiBold)
                    MgText("Sobald du ein Minigolf-Spiel beendest, landet es hier.", MgFont.subheadline, AppTheme.textSec,
                        textAlign = TextAlign.Center)
                }
            } else {
                // Kopf
                val averages = history.mapNotNull { e ->
                    val best = e.scores.map { it.sum() }.minOrNull()
                    if (e.numberOfHoles > 0 && best != null && best > 0) best.toDouble() / e.numberOfHoles else null
                }
                val bestAverage = averages.minOrNull()?.let { String.format(Locale.GERMANY, "%.1f", it) } ?: "–"
                val aces = history.sumOf { e -> e.scores.sumOf { row -> row.count { it == 1 } } }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    Stat("Partien", "${history.size}", Modifier.weight(1f))
                    Stat("Bester Schnitt", bestAverage, Modifier.weight(1f))
                    Stat("Asse", "$aces", Modifier.weight(1f))
                }

                history.forEach { entry ->
                    var menu by remember(entry.id) { mutableStateOf(false) }
                    val totals = entry.scores.map { it.sum() }
                    val winner = totals.indices.minByOrNull { totals[it] }
                    Box {
                        Row(
                            Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))
                                .combinedClickable(
                                    onClick = { Haptics.tap(); selected = entry },
                                    onLongClick = { Haptics.medium(); menu = true },
                                )
                                .padding(16.dp),
                        ) {
                            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                                MgText(winner?.let { "🥇 ${entry.playerNames.getOrElse(it) { "" }}" } ?: "Partie",
                                    MgFont.subheadline, weight = FontWeight.Bold, maxLines = 1)
                                MgText("${entry.playerNames.joinToString(", ")} · ${entry.numberOfHoles} Bahnen",
                                    MgFont.caption, AppTheme.textSec, maxLines = 2)
                                entry.courseName?.let {
                                    MgLabel(it, Icons.Filled.Place, MgFont.caption2, FontWeight.Normal,
                                        iconTint = AppTheme.textSec, color = AppTheme.textSec)
                                }
                            }
                            Spacer(Modifier.width(8.dp))
                            Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                MgText(winner?.let { "${totals[it]}" } ?: "–", MgFont.title3, AppTheme.gold, FontWeight.Bold)
                                MgText(formatDateTime(entry.dateMillis), MgFont.caption2, AppTheme.textSec)
                            }
                        }
                        DropdownMenu(menu, { menu = false }, containerColor = AppTheme.cardAlt) {
                            DropdownMenuItem(
                                text = { Text("Löschen", color = MgRed) },
                                leadingIcon = { Icon(Icons.Filled.Delete, null, tint = MgRed) },
                                onClick = {
                                    menu = false
                                    Haptics.warning()
                                    history = history.filter { it.id != entry.id }
                                    MinigolfGameStore.saveHistory(history)
                                },
                            )
                        }
                    }
                }
            }
        }
    }

    if (showClearConfirm) {
        AlertDialog(
            onDismissRequest = { showClearConfirm = false },
            containerColor = AppTheme.card,
            title = { Text("Ganzen Verlauf löschen?") },
            confirmButton = {
                TextButton(onClick = {
                    Haptics.warning()
                    MinigolfGameStore.saveHistory(emptyList())
                    history = emptyList()
                    showClearConfirm = false
                }) { Text("Alle Partien löschen", color = MgRed) }
            },
            dismissButton = {
                TextButton(onClick = { Haptics.tap(); showClearConfirm = false }) { Text("Abbrechen", color = AppTheme.gold) }
            },
        )
    }

    selected?.let { e ->
        MinigolfResultsSheet(e.playerNames, e.numberOfHoles, e.scores, e.challengeList, onFinish = null) { selected = null }
    }
}

@Composable
private fun Stat(title: String, value: String, modifier: Modifier) {
    Column(modifier.background(AppTheme.card, RoundedCornerShape(14.dp)).padding(14.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
        MgText(title, MgFont.caption, AppTheme.textSec, maxLines = 1)
        MgText(value, 26.sp, AppTheme.text, FontWeight.Bold)
    }
}
