package app.golftrack.feature.minigolf

import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.Accessibility
import androidx.compose.material.icons.filled.Adjust
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Directions
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.GridView
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SportsScore
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.ViewInAr
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

// MARK: - Regeln

data class MinigolfRule(val title: String, val icon: ImageVector, val points: List<String>)

object MinigolfRules {
    /** Zusammenfassung der offiziellen Bahnengolf-Regeln (DMV/WMF). Kein Regelwerk-Ersatz. */
    val all: List<MinigolfRule> = listOf(
        MinigolfRule("Ziel und Zählweise", Icons.Filled.SportsScore, listOf(
            "Der Ball wird vom Abschlag mit möglichst wenigen Schlägen ins Ziel gespielt.",
            "Pro Bahn hat man höchstens 6 Schläge. Liegt der Ball danach nicht im Ziel, wird 7 notiert.",
            "Auch für eine nicht gespielte Bahn werden 7 Schläge notiert.",
            "Gewonnen hat, wer über alle Bahnen zusammen die wenigsten Schläge braucht.",
        )),
        MinigolfRule("Ball verlässt die Bahn", Icons.AutoMirrored.Filled.Undo, listOf(
            "Springt der Ball heraus, bevor er das Hindernis bzw. die Grenzlinie korrekt überwunden hat, wird der nächste Schlag wieder vom Abschlag gespielt – ohne Strafschlag.",
            "Ist die Grenzlinie schon überwunden, wird der Ball dort eingelegt, wo er die Bahn verlassen hat, und von da weitergespielt.",
        )),
        MinigolfRule("Ablegen", Icons.Filled.SwapHoriz, listOf(
            "Liegt der Ball an der Bande oder an einem Hindernis, darf er bis zur Ablegemarkierung abgelegt werden – üblich sind 20 cm von der Bande.",
            "Einzelne Bahnen haben eigene Ablegeregeln, etwa Pyramiden, Stäbe oder Mittelhügel.",
            "Abgelegt wird ohne Strafschlag.",
        )),
        MinigolfRule("Vorgesehener Weg", Icons.Filled.Directions, listOf(
            "Manche Bahnen schreiben den Weg vor: Rohr, Fensterbahnen, Salto, liegende Schleife, Labyrinth, Rampe und Sprungschanze.",
            "Bei den übrigen Bahnen ist der Weg frei – links oder rechts am Hindernis vorbei ist beides erlaubt.",
            "Springt der Ball über ein Hindernis, das er durchlaufen müsste, gilt der Weg als verlassen.",
        )),
        MinigolfRule("Ball und Ausrüstung", Icons.Filled.Adjust, listOf(
            "Während einer Bahn darf der Ball nicht gewechselt werden.",
            "Gespielt wird mit dem Putter; der Ball wird geschlagen, nicht geschoben.",
        )),
        MinigolfRule("Auf der Anlage", Icons.Filled.Accessibility, listOf(
            "Bahnen und Hindernisse dürfen nicht betreten werden. Auf die Banden darf man für einen Schlag treten.",
            "Bei Netz, Schüssel, Vulkan und Plateau darf man die Bahn betreten, um den Ball aus dem Ziel zu nehmen.",
            "Etwa zwei Meter Abstand zum Spieler halten, der gerade schlägt.",
        )),
        MinigolfRule("Die Anlage selbst", Icons.Filled.Straighten, listOf(
            "Eine genormte Miniaturgolfbahn ist ${MinigolfStandardLanes.LANE_LENGTH} lang und ${MinigolfStandardLanes.LANE_WIDTH} breit, der Zielkreis hat ${MinigolfStandardLanes.TARGET_CIRCLE_DIAMETER} Durchmesser.",
            "Eine zugelassene Anlage besteht aus 18 der 28 genormten Bahnen, in beliebiger Reihenfolge.",
            "Deshalb ist Bahn 7 vor Ort nicht dieselbe wie Bahn 7 in dieser Liste.",
        )),
    )
}

// MARK: - Tab-Inhalt

/** „Bahnen & Regeln": die 28 genormten Bahnen mit Skizze und darüber die Regeln. */
@Composable
internal fun MinigolfLanesTabContent(onLane: (MinigolfStandardLane) -> Unit) {
    var expandedRule by rememberSaveable { mutableStateOf<String?>(null) }
    var query by rememberSaveable { mutableStateOf("") }

    // Regeln
    Column(Modifier.mgCard(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        MgLabel("Regeln", Icons.AutoMirrored.Filled.MenuBook)
        MgText("Die offiziellen Bahnengolf-Regeln, kurz gefasst.", MgFont.caption, AppTheme.textSec)
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            MinigolfRules.all.forEach { rule ->
                val isOpen = expandedRule == rule.title
                Column(
                    Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(10.dp))
                        .animateContentSize().padding(horizontal = 12.dp, vertical = 10.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Row(
                        Modifier.fillMaxWidth().clickable {
                            Haptics.tap()
                            expandedRule = if (isOpen) null else rule.title
                        },
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        Icon(rule.icon, null, tint = AppTheme.gold, modifier = Modifier.size(18.dp).width(20.dp))
                        MgText(rule.title, MgFont.subheadline, weight = FontWeight.Bold, modifier = Modifier.weight(1f))
                        val rot by animateFloatAsState(if (isOpen) 0f else -90f, label = "chevron")
                        Icon(Icons.Filled.ExpandMore, null, tint = AppTheme.textSec, modifier = Modifier.size(18.dp).rotate(rot))
                    }
                    if (isOpen) {
                        Column(Modifier.padding(start = 30.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            rule.points.forEach { point ->
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    Box(Modifier.padding(top = 6.dp).size(4.dp).background(AppTheme.gold.copy(alpha = 0.6f), CircleShape))
                                    MgText(point, MgFont.caption, AppTheme.textSec)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Bahnen
    val q = query.trim().lowercase()
    val lanes = if (q.isEmpty()) MinigolfStandardLanes.all else MinigolfStandardLanes.all.filter {
        it.name.lowercase().contains(q) || it.hindernis.lowercase().contains(q) || it.normNumber.toString() == q
    }
    Column(Modifier.mgCard(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        MgLabel("Die 28 genormten Bahnen", Icons.Filled.GridView)
        MgText(
            "Jede zugelassene Miniaturgolfanlage besteht aus 18 davon. Tippe eine Bahn an für Weg, Maße und Tipp.",
            MgFont.caption, AppTheme.textSec,
        )
        Row(
            Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(10.dp))
                .padding(horizontal = 12.dp, vertical = 9.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(Icons.Filled.Search, null, tint = AppTheme.textSec, modifier = Modifier.size(16.dp))
            Box(Modifier.weight(1f)) {
                if (query.isEmpty()) MgText("Bahn suchen", MgFont.subheadline, AppTheme.textTer)
                BasicTextField(
                    query, { query = it }, singleLine = true,
                    textStyle = TextStyle(color = AppTheme.text, fontSize = MgFont.subheadline),
                    cursorBrush = SolidColor(AppTheme.gold),
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.None, autoCorrectEnabled = false),
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            if (query.isNotEmpty()) {
                Icon(Icons.Filled.Cancel, "Leeren", tint = AppTheme.textSec,
                    modifier = Modifier.size(16.dp).clickable { Haptics.tap(); query = "" })
            }
        }
        if (lanes.isEmpty()) {
            Box(Modifier.fillMaxWidth().padding(vertical = 20.dp), contentAlignment = Alignment.Center) {
                MgText("Keine Bahn gefunden.", MgFont.caption, AppTheme.textSec)
            }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                lanes.forEach { lane ->
                    Row(
                        Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(10.dp))
                            // NavigationLinks spielen auf iOS bewusst keine Haptik.
                            .clickable { onLane(lane) }
                            .padding(horizontal = 12.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        MinigolfLaneSketch(lane.shape, lane.glyph, 1.3f, Modifier.width(100.dp).height(40.dp))
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            MgText("${lane.normNumber}. ${lane.name}", MgFont.subheadline, weight = FontWeight.Bold, maxLines = 1)
                            MgText(lane.hindernis, MgFont.caption, AppTheme.textSec, maxLines = 2)
                        }
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textSec)
                    }
                }
            }
        }
    }
}

// MARK: - Detail einer Bahn

@Composable
internal fun MinigolfLaneDetailScreen(nav: NavController, lane: MinigolfStandardLane) {
    AppScaffold("Bahn ${lane.normNumber}", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Column(Modifier.mgCard(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(Modifier.size(32.dp).background(AppTheme.gold, CircleShape), contentAlignment = Alignment.Center) {
                        MgText("${lane.normNumber}", MgFont.headline, MgOnGoldDark, FontWeight.Bold)
                    }
                    MgText(lane.name, MgFont.title3, weight = FontWeight.Bold)
                }
                MinigolfLaneSketch(lane.shape, lane.glyph, 2f, Modifier.fillMaxWidth().height(110.dp).padding(vertical = 6.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                    Legend(Color.White.copy(alpha = 0.8f), "Abschlag")
                    Legend(AppTheme.gold, "Hindernis")
                    // Bei der Sprungschanze ist das Netz selbst das Ziel.
                    if (lane.shape != LaneShape.jump) Legend(SketchTargetColor, "Ziel") else Legend(AppTheme.gold, "Netz")
                }
            }
            Section(Icons.Filled.ViewInAr, "Hindernis", lane.hindernis)
            Section(Icons.Filled.Directions, "Vorgesehener Weg", lane.weg)
            Section(Icons.Filled.Straighten, "Maße & Besonderheiten", lane.mass)
            Section(Icons.Filled.Lightbulb, "Tipp", lane.tipp, accent = true)
            MgText(
                "Nummer der Normbahn nach den Normungsbestimmungen für Miniaturgolf (DMV/WMF). Auf der Anlage kann sie an jeder Position stehen. Verbindlich sind die Zeichnungen des Weltverbands – die Skizze hier ist schematisch.",
                MgFont.caption2, AppTheme.textSec, modifier = Modifier.padding(horizontal = 4.dp),
            )
        }
    }
}

@Composable
private fun Legend(color: Color, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
        Box(Modifier.size(7.dp).background(color, CircleShape))
        MgText(text, MgFont.caption2, AppTheme.textSec)
    }
}

@Composable
private fun Section(icon: ImageVector, title: String, text: String, accent: Boolean = false) {
    val shape = RoundedCornerShape(16.dp)
    Column(
        Modifier.fillMaxWidth()
            .background(if (accent) AppTheme.gold.copy(alpha = 0.10f) else AppTheme.card, shape)
            .then(if (accent) Modifier.border(1.dp, AppTheme.gold.copy(alpha = 0.3f), shape) else Modifier)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        MgLabel(title, icon, MgFont.subheadline, FontWeight.Bold, color = if (accent) AppTheme.gold else AppTheme.text)
        MgText(text, MgFont.subheadline, AppTheme.textSec)
    }
}
