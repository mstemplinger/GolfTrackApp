package app.golftrack.feature.records

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.DocumentScanner
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.LocationOn
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.data.GolfStore
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.data.catalog.GolfCourseEntry
import app.golftrack.data.catalog.formatKm
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.Routes
import app.golftrack.ui.common.rememberLocation
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.delay

private const val NEARBY_RADIUS = 30_000.0

/**
 * Wie AddCourseSheetView.swift: Plätze aus dem Verzeichnis in der Nähe, Suche
 * im Verzeichnis, dazu Scorecard-Scan und manuelles Anlegen. Die Online-Suche
 * über golfcourseapi.com braucht einen eigenen API-Key und fehlt deshalb.
 */
@Composable
internal fun AddCourseScreen(nav: NavController) {
    val data by GolfStore.data.collectAsState()
    val catalog by CourseCatalog.golfCourses.collectAsState()
    var query by rememberSaveable { mutableStateOf("") }
    val here = rememberLocation()
    var timedOut by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { CourseCatalog.refreshIfNeeded() }
    LaunchedEffect(Unit) { delay(2_000); timedOut = true }
    val locationDetermined = here != null || timedOut
    val savedNames = data.courses.map { it.name }.toSet()

    val sorted = if (here == null) catalog else catalog.sortedBy { it.distance(here) }
    val nearby = when {
        !locationDetermined -> emptyList()
        here == null -> sorted
        else -> sorted.filter { it.distance(here) <= NEARBY_RADIUS }
    }
    val q = query.trim().lowercase()
    val searchResults = if (q.isEmpty()) emptyList() else catalog.filter {
        it.name.lowercase().contains(q) || it.location.lowercase().contains(q)
    }

    fun import(entry: GolfCourseEntry) {
        if (entry.name in savedNames) return
        Haptics.success()
        GolfStore.upsertCourse(entry.toCourse())
        nav.popBackStack()
    }

    AppScaffold(
        title = "Platz hinzufügen",
        onBack = { nav.popBackStack() },
        actions = { ToolbarTextButton("Fertig", bold = true) { Haptics.tap(); nav.popBackStack() } },
    ) { m ->
        LazyColumn(m) {
            item { SearchField(query, { query = it }, "Platzname oder Club suchen") }

            if (q.isEmpty()) {
                item {
                    Row(Modifier.padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        val (icon, title) = when {
                            !locationDetermined -> Icons.Outlined.LocationOn to "Golfplätze in der Nähe"
                            here != null -> Icons.Filled.LocationOn to "Golfplätze in der Nähe (30 km)"
                            else -> Icons.Filled.Map to "Alle Golfplätze"
                        }
                        Icon(icon, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                        Spacer(Modifier.width(4.dp))
                        Text(title.uppercase(), color = AppTheme.gold, fontSize = IosFont.footnote, modifier = Modifier.weight(1f))
                        if (!locationDetermined) CircularProgressIndicator(Modifier.size(14.dp), color = AppTheme.textSec, strokeWidth = 2.dp)
                    }
                }
                if (!locationDetermined) {
                    item {
                        GroupCard {
                            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                                CircularProgressIndicator(Modifier.size(18.dp), color = AppTheme.textSec, strokeWidth = 2.dp)
                                Spacer(Modifier.width(10.dp))
                                Text("Standort wird ermittelt …", color = AppTheme.textSec, fontSize = IosFont.subheadline)
                            }
                        }
                    }
                } else {
                    entryGroup(nearby, savedNames, here, ::import)
                    item {
                        SectionFooter(
                            if (here != null) "Plätze im 30-km-Umkreis. Weiter entfernte Plätze sind per Suche erreichbar."
                            else "Standort nicht verfügbar – alle Plätze werden angezeigt.",
                        )
                    }
                }
            } else if (searchResults.isNotEmpty()) {
                item { SectionHeader("Plätze aus der Datenbank", Modifier.padding(top = 8.dp)) }
                entryGroup(searchResults, savedNames, here, ::import)
            } else {
                item {
                    Column(
                        Modifier.fillMaxWidth().padding(32.dp),
                        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Icon(Icons.Filled.Search, contentDescription = null, tint = AppTheme.textSec, modifier = Modifier.size(40.dp))
                        Text("Keine Ergebnisse für „${query.trim()}“", color = AppTheme.text, fontSize = IosFont.title3, fontWeight = FontWeight.Bold)
                        Text("Überprüfe die Schreibweise oder versuche eine neue Suche.", color = AppTheme.textSec, fontSize = IosFont.subheadline)
                    }
                }
            }

            // Platz nicht dabei?
            item { SectionHeader("Platz nicht dabei?", Modifier.padding(top = 16.dp)) }
            item {
                GroupCard {
                    ActionRow(Icons.Filled.DocumentScanner, "Scorecard scannen", AppTheme.gold) {
                        Haptics.tap(); nav.navigate(RecordsInternalRoutes.SCAN)
                    }
                    HorizontalDivider(Modifier.padding(start = 52.dp), color = AppTheme.textTer.copy(alpha = 0.3f))
                    ActionRow(Icons.Filled.AddCircle, "Eigenen Platz manuell erstellen", AppTheme.textSec) {
                        Haptics.tap(); nav.navigate(Routes.courseEdit(NEW_COURSE_ID))
                    }
                }
            }
            item {
                SectionFooter("Halte die gedruckte Scorecard vor die Kamera – GolfTrack liest Par, HCP und Distanzen automatisch aus.")
            }
            item { Spacer(Modifier.height(32.dp)) }
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.entryGroup(
    entries: List<GolfCourseEntry>,
    savedNames: Set<String>,
    here: app.golftrack.data.LatLon?,
    onImport: (GolfCourseEntry) -> Unit,
) {
    itemsIndexed(entries) { i, entry ->
        val first = i == 0
        val last = i == entries.size - 1
        val shape = RoundedCornerShape(
            topStart = if (first) 12.dp else 0.dp, topEnd = if (first) 12.dp else 0.dp,
            bottomStart = if (last) 12.dp else 0.dp, bottomEnd = if (last) 12.dp else 0.dp,
        )
        Column(Modifier.padding(horizontal = 16.dp).background(AppTheme.card, shape)) {
            BundledCourseRow(entry, entry.name in savedNames, here) { onImport(entry) }
            if (!last) HorizontalDivider(Modifier.padding(start = 16.dp), color = AppTheme.textTer.copy(alpha = 0.3f))
        }
    }
}

@Composable
private fun BundledCourseRow(entry: GolfCourseEntry, alreadySaved: Boolean, here: app.golftrack.data.LatLon?, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth()
            .background(if (alreadySaved) AppTheme.gold.copy(alpha = 0.05f) else Color.Transparent)
            .clickable(enabled = !alreadySaved) { onClick() }
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(
                entry.name, color = if (alreadySaved) AppTheme.textSec else AppTheme.text,
                fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold,
            )
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
                IconLabel(Icons.Outlined.LocationOn, entry.location, Modifier.weight(1f, fill = false))
                Text("${entry.holes} Loch", color = AppTheme.textSec, fontSize = IosFont.caption)
            }
        }
        Spacer(Modifier.width(8.dp))
        if (alreadySaved) {
            Icon(Icons.Filled.CheckCircle, contentDescription = "Gespeichert", tint = AppTheme.gold, modifier = Modifier.size(24.dp))
        } else {
            Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                if (here != null) {
                    Text(formatKm(entry.distance(here)), color = AppTheme.gold, fontSize = IosFont.caption, fontWeight = FontWeight.Bold)
                }
                Icon(Icons.Outlined.AddCircleOutline, contentDescription = "Hinzufügen", tint = AppTheme.gold, modifier = Modifier.size(24.dp))
            }
        }
    }
}

@Composable
private fun ActionRow(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String, color: Color, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable { onClick() }.padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(22.dp))
        Spacer(Modifier.width(14.dp))
        Text(text, color = color, fontSize = IosFont.body)
    }
}

/** Suchfeld wie `.searchable` (grau hinterlegt, Lupe, Löschen-Knopf). */
@Composable
internal fun SearchField(value: String, onChange: (String) -> Unit, placeholder: String, onSubmit: () -> Unit = {}) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp)
            .background(AppTheme.cardAlt, RoundedCornerShape(10.dp)).padding(horizontal = 10.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.Search, contentDescription = null, tint = AppTheme.textSec, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(6.dp))
        Box(Modifier.weight(1f)) {
            if (value.isEmpty()) Text(placeholder, color = AppTheme.textTer, fontSize = IosFont.body)
            BasicTextField(
                value = value, onValueChange = onChange, singleLine = true,
                textStyle = TextStyle(color = AppTheme.text, fontSize = IosFont.body),
                cursorBrush = SolidColor(AppTheme.gold),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { onSubmit() }),
                modifier = Modifier.fillMaxWidth(),
            )
        }
        if (value.isNotEmpty()) {
            Icon(
                Icons.Filled.Cancel, contentDescription = "Löschen", tint = AppTheme.textSec,
                modifier = Modifier.size(18.dp).clickable { onChange("") },
            )
        }
    }
}
