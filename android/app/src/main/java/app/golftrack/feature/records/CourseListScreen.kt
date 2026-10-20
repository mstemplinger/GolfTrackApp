package app.golftrack.feature.records

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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.outlined.FlagCircle
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.GolfStore
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme

/** Schlüssel im `savedStateHandle` des Rundenstarts für die Platzwahl. */
const val SELECTED_COURSE_KEY = "selectedCourseId"

/**
 * Wie CourseListView.swift. Wird die Liste aus dem Rundenstart geöffnet
 * (vorheriges Ziel ist `Routes.NEW_ROUND`), wählt ein Tipp den Platz für die
 * Runde – Ergebnis im `savedStateHandle` unter [SELECTED_COURSE_KEY].
 */
@Composable
internal fun CourseListScreen(nav: NavController) {
    val data by GolfStore.data.collectAsState()
    val courses = data.courses.sortedBy { it.name.lowercase() }
    val selectionHandle = remember {
        nav.previousBackStackEntry?.takeIf { it.destination.route == Routes.NEW_ROUND }?.savedStateHandle
    }
    val selectionMode = selectionHandle != null
    var selectedId by remember {
        mutableStateOf(selectionHandle?.get<String>(SELECTED_COURSE_KEY) ?: nav.previousBackStackEntry?.arguments?.getString("courseId"))
    }
    var courseToDelete by remember { mutableStateOf<Course?>(null) }

    // Neu hinzugefügten Platz gleich für die Runde vorwählen – egal ob aus
    // dem Verzeichnis, dem Scan oder manuell.
    var knownIds by rememberSaveable { mutableStateOf(courses.map { it.id }) }
    LaunchedEffect(courses.map { it.id }) {
        val now = courses.map { it.id }
        val added = now.firstOrNull { it !in knownIds }
        if (added != null && selectionHandle != null) {
            selectedId = added
            selectionHandle[SELECTED_COURSE_KEY] = added
        }
        knownIds = now
    }

    AppScaffold(
        title = "Golfplätze",
        onBack = { nav.popBackStack() },
        actions = {
            IconButton(onClick = { Haptics.tap(); nav.navigate(RecordsInternalRoutes.ADD_COURSE) }) {
                Icon(Icons.Filled.Add, contentDescription = "Hinzufügen", tint = AppTheme.gold)
            }
            if (selectionMode) ToolbarTextButton("Fertig", bold = true) { Haptics.tap(); nav.popBackStack() }
        },
    ) { m ->
        if (courses.isEmpty()) {
            Box(m, contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(24.dp)) {
                    Icon(Icons.Outlined.FlagCircle, contentDescription = null, tint = AppTheme.textSec, modifier = Modifier.size(52.dp))
                    Text("Noch keine Golfplätze", color = AppTheme.text, fontSize = IosFont.title3, fontWeight = FontWeight.Bold)
                    Text(
                        "Suche weltweit nach Plätzen oder lege einen manuell an.", color = AppTheme.textSec,
                        textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 16.dp),
                    )
                    Row(
                        Modifier.widthIn(max = 240.dp).fillMaxWidth().background(AppTheme.gold, RoundedCornerShape(12.dp))
                            .clickable { Haptics.tap(); nav.navigate(RecordsInternalRoutes.ADD_COURSE) }
                            .padding(vertical = 12.dp),
                        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.Add, contentDescription = null, tint = AppTheme.onGold, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Golfplatz hinzufügen", color = AppTheme.onGold, fontWeight = FontWeight.SemiBold)
                    }
                }
            }
            return@AppScaffold
        }
        LazyColumn(m, contentPadding = PaddingValues(vertical = 8.dp)) {
            items(courses, key = { it.id }) { course ->
                val isSelected = selectionMode && selectedId == course.id
                SwipeDeleteRow(Modifier.padding(horizontal = 16.dp, vertical = 4.dp), onDelete = { Haptics.tap(); courseToDelete = course }) {
                    Row(
                        Modifier.fillMaxWidth()
                            .background(if (isSelected) AppTheme.gold.copy(alpha = 0.08f).compositeOverCard() else AppTheme.card, RoundedCornerShape(12.dp))
                            .clickable {
                                if (selectionHandle != null) {
                                    Haptics.selection()
                                    selectedId = course.id
                                    selectionHandle[SELECTED_COURSE_KEY] = course.id
                                    nav.popBackStack()
                                } else {
                                    Haptics.tap()
                                    nav.navigate(Routes.courseEdit(course.id))
                                }
                            }
                            .padding(horizontal = 16.dp, vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        CourseRowContent(course, Modifier.weight(1f))
                        if (selectionMode) {
                            Icon(
                                if (isSelected) Icons.Filled.CheckCircle else Icons.Filled.RadioButtonUnchecked,
                                contentDescription = null, tint = if (isSelected) AppTheme.gold else AppTheme.textTer,
                                modifier = Modifier.padding(start = 10.dp).size(24.dp),
                            )
                        } else {
                            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = AppTheme.textTer, modifier = Modifier.padding(start = 6.dp))
                        }
                    }
                }
            }
            if (selectionMode) {
                item { SectionFooter("Tippe auf einen Platz, um ihn für die Runde zu wählen.") }
            }
            item { Spacer(Modifier.height(24.dp)) }
        }
    }

    courseToDelete?.let { c ->
        ConfirmDialog(
            title = "Platz löschen?",
            message = c.name,
            confirmText = "Löschen",
            onConfirm = { Haptics.warning(); GolfStore.deleteCourse(c.id); courseToDelete = null },
            onDismiss = { courseToDelete = null },
        )
    }
}

private fun androidx.compose.ui.graphics.Color.compositeOverCard() =
    androidx.compose.ui.graphics.Color(
        red = red * alpha + AppTheme.card.red * (1 - alpha),
        green = green * alpha + AppTheme.card.green * (1 - alpha),
        blue = blue * alpha + AppTheme.card.blue * (1 - alpha),
    )

@Composable
private fun CourseRowContent(course: Course, modifier: Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(course.name, color = AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                if (course.location.isNotEmpty()) {
                    IconLabel(Icons.Outlined.LocationOn, course.location, Modifier.weight(1f, fill = false))
                }
                IconLabel(Icons.Filled.Flag, "${course.numberOfHoles} Loch")
                Text("Par ${course.totalPar}", color = AppTheme.gold, fontSize = IosFont.caption, fontWeight = FontWeight.Bold)
            }
        }
        if (course.hasHolePositions) {
            Icon(Icons.Filled.Place, contentDescription = "Loch- & Abschlagpositionen gespeichert", tint = AppTheme.gold, modifier = Modifier.size(20.dp))
        }
    }
}

@Composable
internal fun IconLabel(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(3.dp)) {
        Icon(icon, contentDescription = null, tint = AppTheme.textSec, modifier = Modifier.size(12.dp))
        Text(text, color = AppTheme.textSec, fontSize = IosFont.caption, maxLines = 1)
    }
}
