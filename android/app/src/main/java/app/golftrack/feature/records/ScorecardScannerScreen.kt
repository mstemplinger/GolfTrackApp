package app.golftrack.feature.records

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.DocumentScanner
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.TableChart
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.toMutableStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.FileProvider
import androidx.navigation.NavController
import app.golftrack.data.Course
import app.golftrack.data.GolfStore
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File
import java.util.Locale

private sealed interface ScanPhase {
    data object Choose : ScanPhase
    data object Processing : ScanPhase
    data class Confirming(val data: ParsedScorecardData) : ScanPhase
    data class Failed(val message: String) : ScanPhase
}

/**
 * Wie ScorecardScannerView.swift. Statt des VisionKit-Dokumentscanners gibt
 * es auf Android Foto aufnehmen (Kamera-App) oder ein Bild aus der Galerie;
 * die Texterkennung macht ML Kit auf dem Gerät.
 */
@Composable
internal fun ScorecardScannerScreen(nav: NavController) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var phase by remember { mutableStateOf<ScanPhase>(ScanPhase.Choose) }
    var captureUri by remember { mutableStateOf<Uri?>(null) }

    fun close() {
        if (!nav.popBackStack(RecordsInternalRoutes.ADD_COURSE, inclusive = false)) nav.popBackStack()
    }

    fun run(block: suspend () -> ParsedScorecardData, cleanup: () -> Unit = {}) {
        phase = ScanPhase.Processing
        scope.launch {
            phase = try {
                ScanPhase.Confirming(block())
            } catch (e: Exception) {
                Haptics.error()
                ScanPhase.Failed(e.message ?: "Das Bild konnte nicht verarbeitet werden.")
            } finally {
                cleanup()
            }
        }
    }

    val takePicture = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok ->
        val uri = captureUri
        if (ok && uri != null) run({ ScorecardParser.parse(ctx, uri) }, { deleteCapture(ctx, uri) })
        else uri?.let { deleteCapture(ctx, it) }
    }
    val takePreview = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { bmp ->
        if (bmp != null) run({ ScorecardParser.parse(bmp) })
    }
    val pickImage = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        if (uri != null) run({ ScorecardParser.parse(ctx, uri) })
    }

    fun openCamera() {
        Haptics.tap()
        try {
            val uri = createCaptureUri(ctx)
            captureUri = uri
            if (uri != null) takePicture.launch(uri) else takePreview.launch(null)
        } catch (e: Exception) {
            phase = ScanPhase.Failed("Auf diesem Gerät ist keine Kamera-App verfügbar.")
        }
    }

    when (val p = phase) {
        ScanPhase.Choose -> AppScaffold("Scorecard scannen", onBack = { nav.popBackStack() }) { m ->
            Column(
                m.verticalScroll(rememberScrollState()).padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                Spacer(Modifier.height(24.dp))
                Box(Modifier.size(120.dp).background(AppTheme.gold.copy(alpha = 0.12f), CircleShape), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.DocumentScanner, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(52.dp))
                }
                Text("Scorecard scannen", color = AppTheme.text, fontSize = IosFont.title3, fontWeight = FontWeight.Bold)
                Text(
                    "Halte die gedruckte Scorecard vor die Kamera – GolfTrack liest Par, HCP und Distanzen automatisch aus.",
                    color = AppTheme.textSec, fontSize = IosFont.subheadline, textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(8.dp))
                ChoiceButton(Icons.Filled.PhotoCamera, "Foto aufnehmen", primary = true) { openCamera() }
                ChoiceButton(Icons.Filled.PhotoLibrary, "Aus Fotos wählen", primary = false) {
                    Haptics.tap()
                    pickImage.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }
            }
        }
        ScanPhase.Processing -> ProcessingView()
        is ScanPhase.Confirming -> ScorecardConfirmView(
            initial = p.data,
            onCancel = { Haptics.tap(); close() },
            onSave = { course ->
                GolfStore.upsertCourse(course)
                if (!nav.popBackStack(RecordsInternalRoutes.ADD_COURSE, inclusive = true)) nav.popBackStack()
            },
        )
        is ScanPhase.Failed -> Box(Modifier.fillMaxSize().background(AppTheme.bg), contentAlignment = Alignment.Center) {
            Column(
                Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                Icon(Icons.Filled.Cancel, contentDescription = null, tint = IosColor.red, modifier = Modifier.size(56.dp))
                Text("Scan fehlgeschlagen", color = AppTheme.text, fontSize = IosFont.title3, fontWeight = FontWeight.Bold)
                Text(p.message, color = AppTheme.textSec, fontSize = IosFont.body, textAlign = TextAlign.Center)
                ScanGoldButton("Schließen") { Haptics.tap(); nav.popBackStack() }
            }
        }
    }
}

@Composable
private fun ChoiceButton(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String, primary: Boolean, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(if (primary) AppTheme.gold else AppTheme.card, RoundedCornerShape(14.dp))
            .clickable { onClick() }.padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = if (primary) AppTheme.bg else AppTheme.gold, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(8.dp))
        Text(text, color = if (primary) AppTheme.bg else AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold)
    }
}

/** Gold-Knopf wie `GoldButtonStyle` im Scanner (Text in Hintergrundgrün). */
@Composable
private fun ScanGoldButton(text: String, icon: androidx.compose.ui.graphics.vector.ImageVector? = null, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.gold, RoundedCornerShape(14.dp)).clickable { onClick() }.padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        if (icon != null) {
            Icon(icon, contentDescription = null, tint = AppTheme.bg, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
        }
        Text(text, color = AppTheme.bg, fontSize = IosFont.headline, fontWeight = FontWeight.SemiBold)
    }
}

private fun hasFileProvider(ctx: Context): Boolean = runCatching {
    ctx.packageManager.resolveContentProvider("${ctx.packageName}.fileprovider", 0) != null
}.getOrDefault(false)

/** Zielort für das Kamerafoto – FileProvider, sonst MediaStore (ab Android 10), sonst nur Vorschaubild. */
private fun createCaptureUri(ctx: Context): Uri? {
    if (hasFileProvider(ctx)) {
        val dir = File(ctx.cacheDir, "shared").apply { mkdirs() }
        return FileProvider.getUriForFile(ctx, "${ctx.packageName}.fileprovider", File(dir, "scorecard-scan.jpg"))
    }
    if (Build.VERSION.SDK_INT >= 29) {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "GolfTrack-Scan-${System.currentTimeMillis()}.jpg")
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/GolfTrack")
        }
        return ctx.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
    }
    return null
}

/** Das Scan-Foto wird nach dem Auslesen nicht mehr gebraucht. */
private fun deleteCapture(ctx: Context, uri: Uri) {
    if (uri.authority == MediaStore.AUTHORITY) runCatching { ctx.contentResolver.delete(uri, null, null) }
}

// MARK: - Verarbeitung

@Composable
private fun ProcessingView() {
    val steps = listOf("Scorecard wird erkannt", "Text wird ausgelesen", "Par & HCP werden analysiert", "Platz wird vorbereitet")
    var step by remember { mutableIntStateOf(0) }
    var dots by remember { mutableStateOf("") }
    LaunchedEffect(Unit) { while (step <= 20) { delay(1_400); step++ } }
    LaunchedEffect(Unit) { while (true) { delay(500); dots = if (dots.length >= 3) "" else "$dots." } }

    Box(Modifier.fillMaxSize().background(AppTheme.bg).statusBarsPadding().navigationBarsPadding()) {
        Column(Modifier.align(Alignment.Center), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(32.dp)) {
            Box(Modifier.size(140.dp).background(AppTheme.gold.copy(alpha = 0.07f), CircleShape), contentAlignment = Alignment.Center) {
                Box(Modifier.size(110.dp).background(AppTheme.gold.copy(alpha = 0.12f), CircleShape), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.DocumentScanner, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(48.dp))
                }
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text("Scorecard wird gelesen$dots", color = AppTheme.text, fontSize = IosFont.title3, fontWeight = FontWeight.Bold)
                Text(steps[step % steps.size], color = AppTheme.textSec, fontSize = IosFont.subheadline)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                steps.indices.forEach { i ->
                    val active = i == step % steps.size
                    val w: Dp by animateDpAsState(if (active) 24.dp else 8.dp, spring(dampingRatio = Spring.DampingRatioNoBouncy), label = "dot")
                    Box(Modifier.size(width = w, height = 8.dp).background(if (i <= step % steps.size) AppTheme.gold else AppTheme.textTer, RoundedCornerShape(50)))
                }
            }
        }
        Text(
            "Einen Moment bitte …", color = AppTheme.textTer, fontSize = IosFont.caption,
            modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 40.dp),
        )
    }
}

// MARK: - Ergebnis prüfen

@Composable
private fun ScorecardConfirmView(initial: ParsedScorecardData, onCancel: () -> Unit, onSave: (Course) -> Unit) {
    var data by remember { mutableStateOf(initial) }
    var crText by remember { mutableStateOf(initial.courseRating?.let { String.format(Locale.US, "%.1f", it) } ?: "") }
    var srText by remember { mutableStateOf(initial.slopeRating?.toString() ?: "") }
    var showEditor by remember { mutableStateOf(false) }

    AppScaffold(
        "Scan-Ergebnis prüfen", onBack = null,
        actions = { ToolbarTextButton("Abbrechen") { onCancel() } },
    ) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(start = 16.dp, end = 16.dp, bottom = 32.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            // Platzname
            ScanCard {
                CardLabel(Icons.Filled.Flag, "Platzname")
                PlainField(
                    data.name, { data = data.copy(name = it) }, "Platzname",
                    modifier = Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(10.dp)).padding(12.dp),
                    style = TextStyle(color = AppTheme.text, fontSize = IosFont.title3, fontWeight = FontWeight.Bold),
                )
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Löcher", color = AppTheme.textSec, fontSize = IosFont.caption)
                        Text("${data.numberOfHoles}", color = AppTheme.text, fontSize = IosFont.headline, fontWeight = FontWeight.Bold)
                    }
                    Box(Modifier.width(1.dp).height(30.dp).background(AppTheme.textTer))
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Gesamt Par", color = AppTheme.textSec, fontSize = IosFont.caption)
                        Text("${data.parValues.sum()}", color = AppTheme.gold, fontSize = IosFont.headline, fontWeight = FontWeight.Bold)
                    }
                }
            }
            // Ratings
            ScanCard {
                CardLabel(Icons.Filled.BarChart, "Ratings")
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    RatingField("Course Rating", crText, "z.B. 72.4", Modifier.weight(1f)) {
                        crText = it; data = data.copy(courseRating = it.replace(',', '.').toDoubleOrNull())
                    }
                    RatingField("Slope Rating", srText, "z.B. 125", Modifier.weight(1f)) {
                        srText = it; data = data.copy(slopeRating = it.toIntOrNull())
                    }
                }
            }
            // Loch-Details
            ScanCard {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    CardLabel(Icons.Filled.TableChart, "Loch-Details", Modifier.weight(1f))
                    Text(
                        "Bearbeiten", color = AppTheme.gold, fontSize = IosFont.caption, fontWeight = FontWeight.Bold,
                        modifier = Modifier.clickable { Haptics.tap(); showEditor = true }.padding(4.dp),
                    )
                }
                Row {
                    HeaderCell("Loch", 44.dp); HeaderCell("Par", 44.dp); HeaderCell("HCP", 44.dp); HeaderCell("Meter", 60.dp)
                }
                for (i in 0 until data.numberOfHoles) {
                    Row(
                        Modifier.background(if (i % 2 == 0) AppTheme.cardAlt.copy(alpha = 0.5f) else Color.Transparent, RoundedCornerShape(6.dp)),
                    ) {
                        Cell("${i + 1}", 44.dp, bold = true)
                        val par = data.parValues.getOrNull(i)
                        Cell(par?.toString() ?: "–", 44.dp, color = when (par) { 3 -> Color(0xFF66D97F); 5 -> AppTheme.gold; else -> AppTheme.text })
                        Cell(data.hcpValues.getOrNull(i)?.toString() ?: "–", 44.dp)
                        Cell(data.holeLengths.getOrNull(i)?.toString() ?: "–", 60.dp)
                    }
                }
                if (data.parValues.isEmpty()) {
                    Text(
                        "Keine Par-Werte erkannt – bitte manuell im Bearbeiten-Modus eingeben.",
                        color = IosColor.orange, fontSize = IosFont.caption, modifier = Modifier.padding(top = 4.dp),
                    )
                }
            }
            ScanGoldButton("Platz speichern", Icons.Filled.CheckCircle) {
                Haptics.success()
                onSave(
                    Course(
                        name = data.name.ifEmpty { "Unbekannter Platz" },
                        numberOfHoles = data.numberOfHoles,
                        parValues = data.parValues.ifEmpty { Course.defaultPars(18) },
                        courseRating = data.courseRating ?: 72.0,
                        slopeRating = data.slopeRating ?: 113,
                        hcpValues = data.hcpValues,
                        holeLengths = data.holeLengths,
                    ),
                )
            }
        }
    }

    if (showEditor) {
        HoleEditorDialog(data, onDismiss = { showEditor = false }) { data = it; showEditor = false }
    }
}

@Composable
private fun ScanCard(content: @Composable () -> Unit) {
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) { content() }
}

@Composable
private fun CardLabel(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
        Icon(icon, contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
        Text(text, color = AppTheme.gold, fontSize = IosFont.caption, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun RatingField(label: String, value: String, placeholder: String, modifier: Modifier, onChange: (String) -> Unit) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(label, color = AppTheme.textSec, fontSize = IosFont.caption)
        PlainField(
            value, onChange, placeholder, KeyboardType.Decimal,
            modifier = Modifier.fillMaxWidth().background(AppTheme.cardAlt, RoundedCornerShape(10.dp)).padding(10.dp),
            style = TextStyle(color = AppTheme.text, fontSize = IosFont.body, fontWeight = FontWeight.Bold),
        )
    }
}

@Composable
private fun HeaderCell(text: String, width: Dp) {
    Text(text, color = AppTheme.textSec, fontSize = IosFont.caption2, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center, modifier = Modifier.width(width))
}

@Composable
private fun Cell(text: String, width: Dp, bold: Boolean = false, color: Color = AppTheme.text) {
    Text(
        text, color = color, fontSize = IosFont.caption, fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
        textAlign = TextAlign.Center, modifier = Modifier.width(width).padding(vertical = 5.dp),
    )
}

/** „Löcher bearbeiten" – wie `HoleEditorSheet`. */
@Composable
private fun HoleEditorDialog(data: ParsedScorecardData, onDismiss: () -> Unit, onApply: (ParsedScorecardData) -> Unit) {
    fun padded(list: List<Int>) = List(18) { list.getOrNull(it)?.toString() ?: "" }
    var holes by remember { mutableIntStateOf(if (data.numberOfHoles == 0) 18 else data.numberOfHoles) }
    val pars = remember { padded(data.parValues).toMutableStateList() }
    val hcps = remember { padded(data.hcpValues).toMutableStateList() }
    val lengths = remember { padded(data.holeLengths).toMutableStateList() }

    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        AppScaffold(
            "Löcher bearbeiten", onBack = null,
            actions = {
                ToolbarTextButton("Abbrechen") { Haptics.tap(); onDismiss() }
                ToolbarTextButton("Übernehmen", bold = true) {
                    Haptics.success()
                    onApply(
                        data.copy(
                            parValues = pars.take(holes).mapNotNull { it.toIntOrNull() },
                            hcpValues = hcps.take(holes).mapNotNull { it.toIntOrNull() },
                            holeLengths = lengths.take(holes).mapNotNull { it.toIntOrNull() },
                        ),
                    )
                }
            },
        ) { m ->
            Column(m.verticalScroll(rememberScrollState()).padding(bottom = 32.dp)) {
                SectionHeader("Anzahl Löcher", Modifier.padding(top = 8.dp))
                GroupCard {
                    SegmentedPicker(
                        listOf(9 to "9 Loch", 18 to "18 Loch"), holes, Modifier.fillMaxWidth().padding(12.dp), fill = true,
                    ) { Haptics.selection(); holes = it }
                }
                SectionHeader("Loch-Werte", Modifier.padding(top = 20.dp))
                GroupCard {
                    for (i in 0 until holes) {
                        if (i > 0) FormDivider()
                        Row(Modifier.padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            Text("L ${i + 1}", color = AppTheme.gold, fontSize = IosFont.caption, fontWeight = FontWeight.Bold, modifier = Modifier.width(36.dp))
                            NumField("Par", pars[i], Modifier.weight(1f)) { pars[i] = it }
                            NumField("HCP", hcps[i], Modifier.weight(1f)) { hcps[i] = it }
                            NumField("m", lengths[i], Modifier.weight(1f)) { lengths[i] = it }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun NumField(placeholder: String, value: String, modifier: Modifier, onChange: (String) -> Unit) {
    PlainField(
        value, { v -> onChange(v.filter { it.isDigit() }.take(3)) }, placeholder, KeyboardType.Number,
        modifier = modifier.background(AppTheme.cardAlt, RoundedCornerShape(8.dp)).padding(6.dp),
        align = TextAlign.Center,
    )
}
