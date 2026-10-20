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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.AutoFixHigh
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.toMutableStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.GolfStore
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import java.util.Locale

/** Kennung in `Routes.courseEdit(…)` für einen neuen Platz. */
internal const val NEW_COURSE_ID = "new"

/**
 * Neuer Platz wie AddCourseView.swift. Mit vorhandener ID dasselbe Formular
 * zum Bearbeiten, ergänzt um die Loch-Positionen und Löschen.
 */
@Composable
internal fun CourseEditScreen(nav: NavController, courseId: String) {
    val existing = remember(courseId) { if (courseId == NEW_COURSE_ID) null else GolfStore.current.course(courseId) }
    val isNew = existing == null

    var name by rememberSaveable { mutableStateOf(existing?.name ?: "") }
    var location by rememberSaveable { mutableStateOf(existing?.location ?: "") }
    var holes by rememberSaveable { mutableStateOf(existing?.numberOfHoles ?: 18) }
    val pars = remember { (existing?.parValues ?: Course.defaultPars(18)).toMutableStateList() }
    var crText by rememberSaveable { mutableStateOf(String.format(Locale.US, "%.1f", existing?.courseRating ?: 72.0)) }
    var slope by rememberSaveable { mutableStateOf(existing?.slopeRating ?: 113) }
    var showDelete by remember { mutableStateOf(false) }

    fun setHoles(n: Int) {
        if (n == holes) return
        Haptics.selection()
        holes = n
        val defaults = Course.defaultPars(n)
        if (isNew) {
            pars.clear(); pars.addAll(defaults)
        } else {
            while (pars.size < n) pars.add(defaults[pars.size])
        }
    }

    fun save() {
        Haptics.success()
        val cr = crText.replace(',', '.').toDoubleOrNull() ?: 72.0
        val parList = List(holes) { pars.getOrNull(it) ?: Course.defaultPars(holes)[it] }
        if (existing == null) {
            GolfStore.upsertCourse(
                Course(
                    name = name.trim(), location = location.trim(), numberOfHoles = holes,
                    parValues = parList, courseRating = cr, slopeRating = slope,
                ),
            )
            // Zurück zur Platzliste (über „Platz hinzufügen" hinweg), sonst eine Ebene.
            if (!nav.popBackStack(RecordsInternalRoutes.ADD_COURSE, inclusive = true)) nav.popBackStack()
        } else {
            GolfStore.update { d ->
                val cur = d.course(existing.id) ?: existing
                d.copy(courses = d.courses.map {
                    if (it.id != existing.id) it else cur.copy(
                        name = name.trim(), location = location.trim(), numberOfHoles = holes,
                        parValues = parList, courseRating = cr, slopeRating = slope,
                    )
                })
            }
            nav.popBackStack()
        }
    }

    AppScaffold(
        title = if (isNew) "Neuer Platz" else "Platz bearbeiten",
        onBack = { nav.popBackStack() },
        actions = { ToolbarTextButton("Speichern", bold = true, enabled = name.isNotBlank()) { save() } },
    ) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(bottom = 32.dp)) {
            SectionHeader("Platzinformationen", Modifier.padding(top = 8.dp))
            GroupCard {
                FormTextField(name, { name = it }, "Platzname *")
                FormDivider()
                FormTextField(location, { location = it }, "Ort (optional)")
                FormDivider()
                Row(Modifier.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("Löcher", color = AppTheme.text, fontSize = IosFont.body, modifier = Modifier.weight(1f))
                    SegmentedPicker(listOf(9 to "9 Löcher", 18 to "18 Löcher"), holes, onSelect = ::setHoles)
                }
            }

            SectionHeader("Handicap-Daten", Modifier.padding(top = 20.dp))
            GroupCard {
                Row(Modifier.padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("Course Rating (CR)", color = AppTheme.textSec, fontSize = IosFont.body, modifier = Modifier.weight(1f))
                    PlainField(crText, { crText = it }, "72.0", KeyboardType.Decimal, Modifier.width(70.dp), TextAlign.End)
                }
                FormDivider()
                Row(Modifier.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("Slope Rating", color = AppTheme.textSec, fontSize = IosFont.body, modifier = Modifier.weight(1f))
                    Stepper(slope, 55..155) { slope = it }
                }
            }
            SectionFooter("CR und Slope stehen auf der Scorekarte oder der Club-Website. Standard: CR 72.0 / Slope 113.")

            SectionHeader("Par pro Loch", Modifier.padding(top = 20.dp))
            GroupCard {
                for (i in 0 until holes) {
                    if (i > 0) FormDivider()
                    Row(Modifier.padding(horizontal = 16.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text("Loch ${i + 1}", color = AppTheme.textSec, fontSize = IosFont.body, modifier = Modifier.weight(1f))
                        Stepper(pars.getOrNull(i) ?: 4, 3..5) { v -> while (pars.size <= i) pars.add(4); pars[i] = v }
                    }
                }
            }

            if (existing != null) {
                val live = GolfStore.current.course(existing.id) ?: existing
                SectionHeader("Loch-Positionen", Modifier.padding(top = 20.dp))
                GroupCard {
                    Row(
                        Modifier.fillMaxWidth().clickable { Haptics.tap(); nav.navigate(RecordsInternalRoutes.geometry(existing.id)) }
                            .padding(horizontal = 16.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.AutoFixHigh, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(22.dp))
                        Spacer(Modifier.width(14.dp))
                        Text("Loch-Positionen ableiten", color = AppTheme.text, fontSize = IosFont.body, modifier = Modifier.weight(1f))
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = AppTheme.textTer)
                    }
                }
                SectionFooter("Bereits gespeichert: ${live.holePositionCount} von ${live.numberOfHoles} Löchern.")

                Spacer(Modifier.height(20.dp))
                GroupCard {
                    Text(
                        "Platz löschen", color = IosColor.red, fontSize = IosFont.body, textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth().clickable { Haptics.tap(); showDelete = true }.padding(vertical = 14.dp),
                    )
                }
            }
        }
    }

    if (showDelete && existing != null) {
        ConfirmDialog(
            title = "Platz löschen?",
            message = existing.name,
            confirmText = "Löschen",
            onConfirm = {
                Haptics.warning()
                showDelete = false
                nav.popBackStack()
                GolfStore.deleteCourse(existing.id)
            },
            onDismiss = { showDelete = false },
        )
    }
}

// --- Formular-Bausteine ---

@Composable
internal fun FormDivider() {
    HorizontalDivider(Modifier.padding(start = 16.dp), color = AppTheme.textTer.copy(alpha = 0.3f))
}

@Composable
internal fun FormTextField(value: String, onChange: (String) -> Unit, placeholder: String, keyboardType: KeyboardType = KeyboardType.Text) {
    PlainField(value, onChange, placeholder, keyboardType, Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 13.dp))
}

@Composable
internal fun PlainField(
    value: String,
    onChange: (String) -> Unit,
    placeholder: String,
    keyboardType: KeyboardType = KeyboardType.Text,
    modifier: Modifier = Modifier,
    align: TextAlign = TextAlign.Start,
    style: TextStyle = TextStyle(color = AppTheme.text, fontSize = IosFont.body),
) {
    Box(modifier) {
        if (value.isEmpty()) Text(placeholder, color = AppTheme.textTer, fontSize = style.fontSize, textAlign = align, modifier = Modifier.fillMaxWidth())
        BasicTextField(
            value = value, onValueChange = onChange, singleLine = true,
            textStyle = style.copy(textAlign = align),
            cursorBrush = SolidColor(AppTheme.gold),
            keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

/** iOS-`Stepper`: Wert plus −/+-Knöpfe. */
@Composable
internal fun Stepper(value: Int, range: IntRange, onChange: (Int) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("$value", color = AppTheme.text, fontSize = IosFont.body, fontWeight = FontWeight.SemiBold)
        Row(Modifier.background(AppTheme.cardAlt, RoundedCornerShape(8.dp))) {
            StepperButton(Icons.Filled.Remove, value > range.first) { Haptics.selection(); onChange(value - 1) }
            Box(Modifier.width(1.dp).height(32.dp).background(AppTheme.textTer.copy(alpha = 0.3f)))
            StepperButton(Icons.Filled.Add, value < range.last) { Haptics.selection(); onChange(value + 1) }
        }
    }
}

@Composable
private fun StepperButton(icon: androidx.compose.ui.graphics.vector.ImageVector, enabled: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.size(width = 46.dp, height = 32.dp).clickable(enabled = enabled) { onClick() },
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, contentDescription = null, tint = if (enabled) AppTheme.text else AppTheme.textTer, modifier = Modifier.size(18.dp))
    }
}

/** Segmentierter Picker (`.pickerStyle(.segmented)`). */
@Composable
internal fun <T> SegmentedPicker(options: List<Pair<T, String>>, selected: T, modifier: Modifier = Modifier, fill: Boolean = false, onSelect: (T) -> Unit) {
    Row(modifier.background(AppTheme.cardAlt, RoundedCornerShape(8.dp)).padding(2.dp)) {
        options.forEach { (v, label) ->
            val active = v == selected
            Text(
                label,
                color = if (active) AppTheme.onGold else AppTheme.text,
                fontSize = IosFont.footnote, fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal,
                textAlign = TextAlign.Center,
                modifier = (if (fill) Modifier.weight(1f) else Modifier)
                    .background(if (active) AppTheme.gold else Color.Transparent, RoundedCornerShape(7.dp))
                    .clickable { onSelect(v) }
                    .padding(horizontal = 12.dp, vertical = 6.dp),
            )
        }
    }
}
