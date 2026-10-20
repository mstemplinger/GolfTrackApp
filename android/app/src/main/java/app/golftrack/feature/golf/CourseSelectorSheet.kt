package app.golftrack.feature.golf

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.LocationOff
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.TravelExplore
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
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.data.Course
import app.golftrack.data.GolfStore
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.data.catalog.GolfCourseEntry
import app.golftrack.data.catalog.formatKm
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.rememberLocation
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.delay

/** Eintrag der Auswahl: eigener Platz oder Platz aus dem Verzeichnis (noch nicht übernommen). */
private sealed interface CourseOption {
    val name: String
    val location: String
    val holes: Int
    val par: Int
    val distance: Double?

    data class Stored(val course: Course, override val distance: Double?) : CourseOption {
        override val name get() = course.name
        override val location get() = course.location
        override val holes get() = course.numberOfHoles
        override val par get() = course.totalPar
    }

    data class Catalog(val entry: GolfCourseEntry, override val distance: Double?) : CourseOption {
        override val name get() = entry.name
        override val location get() = entry.location
        override val holes get() = entry.holes
        override val par get() = entry.parValues.ifEmpty { Course.defaultPars(entry.holes) }.sum()
    }
}

/**
 * Wie CourseSelectorView.swift: Plätze im Umkreis von 30 km, sonst alle; Suche
 * über Namen. Zusätzlich zu den eigenen Plätzen erscheint das Platzverzeichnis
 * (die Online-Suche über die Golf-API von iOS gibt es auf Android nicht).
 */
@Composable
fun CourseSelectorSheet(selectedCourseId: String?, onSelect: (String) -> Unit, onDismiss: () -> Unit) {
    val data by GolfStore.data.collectAsState()
    val catalog by CourseCatalog.golfCourses.collectAsState()
    val here = rememberLocation(highAccuracy = false)
    var locationDetermined by remember { mutableStateOf(false) }
    var search by remember { mutableStateOf("") }
    val nearbyRadius = 30_000.0

    LaunchedEffect(Unit) { delay(700); locationDetermined = true }
    LaunchedEffect(here) { if (here != null) locationDetermined = true }

    val storedNames = data.courses.map { it.name.lowercase() }.toSet()
    val stored = data.courses.map { CourseOption.Stored(it, here?.let { h -> it.distance(h) }) }
    val fromCatalog = catalog.filter { it.name.lowercase() !in storedNames }
        .map { CourseOption.Catalog(it, here?.let { h -> it.distance(h) }) }

    fun pick(o: CourseOption) {
        Haptics.success()
        val id = when (o) {
            is CourseOption.Stored -> o.course.id
            is CourseOption.Catalog -> GolfStore.storedCourse(o.entry.toCourse()).id
        }
        onSelect(id)
    }

    val query = search.trim().lowercase()
    val searchActive = query.isNotEmpty()

    FullSheet(onDismiss) {
        Column(Modifier.fillMaxSize()) {
            SheetTopBar("Platz wählen", leading = { BarButton("Abbrechen") { Haptics.tap(); onDismiss() } })
            // Suchfeld (searchable, displayMode .always)
            Row(
                Modifier.padding(horizontal = 16.dp, vertical = 6.dp).fillMaxWidth()
                    .background(AppTheme.cardAlt, RoundedCornerShape(10.dp)).padding(horizontal = 10.dp, vertical = 9.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Search, null, tint = AppTheme.textSec, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Box(Modifier.weight(1f)) {
                    if (search.isEmpty()) Text("Platz suchen…", color = AppTheme.textTer, fontSize = 16.sp)
                    BasicTextField(
                        search, { search = it }, singleLine = true,
                        textStyle = TextStyle(color = AppTheme.text, fontSize = 16.sp),
                        cursorBrush = SolidColor(AppTheme.gold), modifier = Modifier.fillMaxWidth(),
                    )
                }
            }

            LazyColumn(Modifier.fillMaxSize().padding(horizontal = 16.dp).navigationBarsPadding()) {
                if (searchActive) {
                    val localHits = stored.filter { it.name.lowercase().contains(query) }.sortedBy { it.name.lowercase() }
                    val catalogHits = fromCatalog.filter {
                        it.name.lowercase().contains(query) || it.location.lowercase().contains(query)
                    }.sortedBy { it.distance ?: Double.MAX_VALUE }.take(50)
                    if (localHits.isNotEmpty()) {
                        item { SectionHeader("Gespeicherte Plätze") }
                        item { OptionGroup(localHits, selectedCourseId, here != null, ::pick) }
                    }
                    if (catalogHits.isNotEmpty()) {
                        item { SectionHeader("Platzverzeichnis") }
                        item { OptionGroup(catalogHits, selectedCourseId, here != null, ::pick) }
                    }
                    if (localHits.isEmpty() && catalogHits.isEmpty()) {
                        item {
                            Column(Modifier.fillMaxWidth().padding(top = 60.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                                Icon(Icons.Filled.Search, null, tint = AppTheme.textSec, modifier = Modifier.size(44.dp))
                                Spacer(Modifier.height(10.dp))
                                Text("Keine Ergebnisse für „$search“", color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                                Text("Überprüfe die Schreibweise oder versuche es mit einer neuen Suche.", color = AppTheme.textSec, fontSize = 14.sp,
                                    modifier = Modifier.padding(top = 6.dp))
                            }
                        }
                    }
                } else if (stored.isEmpty() && fromCatalog.isEmpty()) {
                    item {
                        GroupCard(Modifier.padding(top = 16.dp)) {
                            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Filled.LocationOff, null, tint = AppTheme.textSec)
                                Spacer(Modifier.width(10.dp))
                                Text("Noch keine Plätze gespeichert.", color = AppTheme.textSec)
                            }
                        }
                    }
                } else if (here != null) {
                    // In der Nähe (30 km): eigene Plätze ohne Koordinate immer, Verzeichnis nur im Umkreis.
                    val nearby = (stored.filter { it.distance == null || it.distance <= nearbyRadius } +
                        fromCatalog.filter { (it.distance ?: Double.MAX_VALUE) <= nearbyRadius })
                        .sortedBy { it.distance ?: Double.MAX_VALUE }
                    item { NearbyHeader("In der Nähe (30 km)", located = true, loading = false) }
                    if (nearby.isNotEmpty()) item { OptionGroup(nearby, selectedCourseId, true, ::pick) }
                    else item { Text("Kein Platz im Umkreis von 30 km.", color = AppTheme.textSec, fontSize = 14.sp, modifier = Modifier.padding(16.dp)) }
                    if (nearby.size < stored.size + fromCatalog.size) {
                        item { SectionFooter("Weitere Plätze sind per Suche erreichbar.") }
                    }
                } else {
                    item { NearbyHeader("Meine Plätze", located = false, loading = !locationDetermined) }
                    if (stored.isNotEmpty()) item { OptionGroup(stored.sortedBy { it.name.lowercase() }, selectedCourseId, false, ::pick) }
                    if (fromCatalog.isNotEmpty()) {
                        item { SectionHeader("Platzverzeichnis") }
                        item { OptionGroup(fromCatalog.sortedBy { it.name.lowercase() }, selectedCourseId, false, ::pick) }
                    }
                }
                item { Spacer(Modifier.height(24.dp)) }
            }
        }
    }
}

@Composable
private fun NearbyHeader(title: String, located: Boolean, loading: Boolean) {
    Row(Modifier.padding(start = 16.dp, top = 18.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(if (located) Icons.Filled.MyLocation else Icons.Filled.TravelExplore, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
        Spacer(Modifier.width(6.dp))
        Text(title.uppercase(), color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Medium, modifier = Modifier.weight(1f))
        if (loading) CircularProgressIndicator(color = AppTheme.textSec, strokeWidth = 2.dp, modifier = Modifier.size(14.dp))
    }
}

@Composable
private fun OptionGroup(options: List<CourseOption>, selectedId: String?, showDistance: Boolean, onPick: (CourseOption) -> Unit) {
    GroupCard {
        options.forEachIndexed { i, o ->
            val selected = o is CourseOption.Stored && o.course.id == selectedId
            Row(
                Modifier.fillMaxWidth().background(if (selected) AppTheme.gold.copy(alpha = 0.08f) else Color.Transparent)
                    .clickable { onPick(o) }.padding(horizontal = 16.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Place, null, tint = if (selected) AppTheme.gold else AppTheme.textSec, modifier = Modifier.size(24.dp))
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(o.name, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    Row {
                        if (o.location.isNotEmpty()) {
                            Text(o.location, color = AppTheme.textSec, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f, fill = false))
                            Spacer(Modifier.width(8.dp))
                        }
                        Text("${o.holes} Loch · Par ${o.par}", color = AppTheme.textSec, fontSize = 12.sp, maxLines = 1)
                    }
                }
                if (showDistance && o.distance != null) {
                    Text(formatKm(o.distance!!), color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(start = 8.dp))
                }
                if (selected) Icon(Icons.Filled.CheckCircle, null, tint = AppTheme.gold, modifier = Modifier.padding(start = 8.dp))
            }
            if (i < options.lastIndex) HorizontalDivider(color = AppTheme.cardAlt, modifier = Modifier.padding(start = 52.dp))
        }
    }
}
