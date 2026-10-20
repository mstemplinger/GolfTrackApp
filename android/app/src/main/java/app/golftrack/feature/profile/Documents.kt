package app.golftrack.feature.profile

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.DocumentScanner
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Euro
import androidx.compose.material.icons.filled.InsertDriveFile
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.navigation.NavController
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import java.io.File
import java.util.UUID

// --- Modell & Ablage (GolfDocument.swift) ---

enum class GolfDocumentType(val title: String, val icon: ImageVector) {
    membershipCard("Mitgliedskarte", Icons.Filled.CreditCard),
    greenFeeReceipt("Greenfee-Beleg", Icons.Filled.Description),
    tournamentEntry("Turnierregistrierung", Icons.Filled.EmojiEvents),
    startingFee("Startgeld", Icons.Filled.Euro),
    other("Sonstiges", Icons.Filled.InsertDriveFile),
}

@Serializable
data class GolfDocument(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val type: String,
    /** Millisekunden seit 1970. */
    val date: Long,
    /** Dateinamen der gespeicherten Seiten (JPEG). */
    val imageFilenames: List<String>,
) {
    val pageCount: Int get() = imageFilenames.size
    val docType: GolfDocumentType get() = runCatching { GolfDocumentType.valueOf(type) }.getOrDefault(GolfDocumentType.other)
}

object GolfDocumentStore {
    private val json = Json { ignoreUnknownKeys = true }
    private val ser = ListSerializer(GolfDocument.serializer())

    private fun dir(ctx: Context) = File(ctx.filesDir, "golf_documents").apply { mkdirs() }
    private fun meta(ctx: Context) = File(dir(ctx), "metadata.json")

    fun loadAll(ctx: Context): List<GolfDocument> =
        runCatching { json.decodeFromString(ser, meta(ctx).readText()) }.getOrDefault(emptyList()).sortedByDescending { it.date }

    fun save(ctx: Context, title: String, type: GolfDocumentType, images: List<Bitmap>): GolfDocument {
        val names = images.mapIndexedNotNull { i, bmp ->
            val name = "${UUID.randomUUID()}_p$i.jpg"
            runCatching { ImageTools.saveJpeg(bmp, File(dir(ctx), name)) }.map { name }.getOrNull()
        }
        val doc = GolfDocument(title = title, type = type.name, date = System.currentTimeMillis(), imageFilenames = names)
        saveMeta(ctx, listOf(doc) + loadAll(ctx))
        return doc
    }

    fun loadImage(ctx: Context, filename: String, maxSide: Int = 2048): Bitmap? = ImageTools.load(File(dir(ctx), filename), maxSide)

    fun delete(ctx: Context, doc: GolfDocument) {
        doc.imageFilenames.forEach { File(dir(ctx), it).delete() }
        saveMeta(ctx, loadAll(ctx).filter { it.id != doc.id })
    }

    private fun saveMeta(ctx: Context, docs: List<GolfDocument>) {
        val f = meta(ctx)
        val tmp = File(f.parentFile, f.name + ".tmp")
        tmp.writeText(json.encodeToString(ser, docs))
        tmp.renameTo(f)
    }
}

@Composable
private fun Thumbnail(filename: String?, modifier: Modifier) {
    val ctx = LocalContext.current
    val bmp by produceState<Bitmap?>(null, filename) {
        value = filename?.let { withContext(Dispatchers.IO) { GolfDocumentStore.loadImage(ctx, it, 400) } }
    }
    Box(modifier.background(AppTheme.cardAlt), contentAlignment = Alignment.Center) {
        val b = bmp
        if (b != null) Image(b.asImageBitmap(), null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
        else Icon(Icons.Filled.InsertDriveFile, null, tint = AppTheme.textTer, modifier = Modifier.size(28.dp))
    }
}

// --- Karte im Profil (DocumentsCard.swift) ---

@Composable
internal fun DocumentsCard(nav: NavController, limit: Int = Int.MAX_VALUE) {
    val ctx = LocalContext.current
    var docs by remember { mutableStateOf<List<GolfDocument>>(emptyList()) }
    LifecycleResumeEffect(Unit) {
        docs = GolfDocumentStore.loadAll(ctx)
        onPauseOrDispose { }
    }
    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f).clickable(enabled = docs.size > limit) { Haptics.tap(); nav.navigate(app.golftrack.ui.common.Routes.DOCUMENTS) }) {
                Text("Dokumente", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                Text("Mitgliedskarte, Belege & mehr", color = AppTheme.textSec, fontSize = 12.sp)
            }
            Row(
                Modifier.clip(CircleShape).background(AppTheme.gold.copy(alpha = 0.15f))
                    .clickable { Haptics.tap(); nav.navigate(ProfileExtraRoutes.ADD_DOCUMENT) }
                    .padding(horizontal = 11.dp, vertical = 7.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Add, null, tint = AppTheme.gold, modifier = Modifier.size(13.dp))
                Spacer(Modifier.width(5.dp))
                Text("Hinzufügen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
            }
        }
        HorizontalDivider(color = AppTheme.cardAlt)
        if (docs.isEmpty()) {
            Column(Modifier.fillMaxWidth().padding(vertical = 10.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Box(Modifier.size(52.dp).background(AppTheme.cardAlt, CircleShape), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.DocumentScanner, null, tint = AppTheme.textTer, modifier = Modifier.size(24.dp))
                }
                Text("Noch keine Dokumente", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                Text("Scanne deine Mitgliedskarte oder Greenfee-Belege für schnellen Zugriff.", color = AppTheme.textTer, fontSize = 12.sp, textAlign = TextAlign.Center)
                Row(
                    Modifier.padding(top = 4.dp).fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(AppTheme.gold)
                        .clickable { Haptics.tap(); nav.navigate(ProfileExtraRoutes.ADD_DOCUMENT) }.padding(vertical = 12.dp),
                    horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.DocumentScanner, null, tint = Color(0xFF0F2414), modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("Erstes Dokument scannen", color = Color(0xFF0F2414), fontSize = 15.sp, fontWeight = FontWeight.Bold)
                }
            }
        } else {
            docs.take(limit).chunked(2).forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    row.forEach { d -> DocumentTile(d, Modifier.weight(1f)) { Haptics.tap(); nav.navigate(ProfileExtraRoutes.document(d.id)) } }
                    if (row.size == 1) Spacer(Modifier.weight(1f))
                }
            }
            if (docs.size > limit) {
                Row(
                    Modifier.fillMaxWidth().clickable { Haptics.tap(); nav.navigate(app.golftrack.ui.common.Routes.DOCUMENTS) },
                    horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Alle ${docs.size} Dokumente", color = AppTheme.gold, fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp))
                }
            }
        }
    }
}

@Composable
private fun DocumentTile(doc: GolfDocument, modifier: Modifier, onClick: () -> Unit) {
    Column(
        modifier.clip(RoundedCornerShape(12.dp)).background(AppTheme.card).border(1.dp, AppTheme.cardAlt, RoundedCornerShape(12.dp)).clickable { onClick() },
    ) {
        Box {
            Thumbnail(doc.imageFilenames.firstOrNull(), Modifier.fillMaxWidth().height(90.dp).clip(RoundedCornerShape(10.dp)))
            if (doc.pageCount > 1) {
                Text(
                    "${doc.pageCount} Seiten", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.align(Alignment.BottomEnd).padding(6.dp).background(Color.Black.copy(alpha = 0.55f), CircleShape).padding(horizontal = 6.dp, vertical = 3.dp),
                )
            }
        }
        Column(Modifier.padding(horizontal = 8.dp).padding(top = 6.dp, bottom = 8.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(doc.docType.icon, null, tint = AppTheme.gold, modifier = Modifier.size(10.dp))
                Spacer(Modifier.width(4.dp))
                Text(doc.docType.title, color = AppTheme.gold, fontSize = 9.sp, fontWeight = FontWeight.SemiBold)
            }
            Text(doc.title, color = AppTheme.text, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
            Text(app.golftrack.feature.home.formatDateShort(doc.date), color = AppTheme.textTer, fontSize = 10.sp)
        }
    }
}

/** Alle Dokumente als eigene Seite (`Routes.DOCUMENTS`). */
@Composable
fun DocumentsScreen(nav: NavController) {
    AppScaffold("Dokumente", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp)) { DocumentsCard(nav) }
    }
}

// --- Hinzufügen (DocumentScannerSheet.swift): Kamera oder Galerie ---

@Composable
fun AddDocumentScreen(nav: NavController) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val images = remember { mutableStateListOf<Bitmap>() }
    var type by remember { mutableStateOf(GolfDocumentType.membershipCard) }
    var title by remember { mutableStateOf("") }
    var saving by remember { mutableStateOf(false) }
    var pendingCamera by remember { mutableStateOf<Uri?>(null) }

    fun afterAdd() { if (title.isEmpty()) title = type.title }

    val picker = rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(10)) { uris ->
        if (uris.isEmpty()) return@rememberLauncherForActivityResult
        scope.launch {
            val loaded = withContext(Dispatchers.IO) { uris.mapNotNull { ImageTools.decode(ctx, it) } }
            images.addAll(loaded); afterAdd()
        }
    }
    val camera = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok ->
        val uri = pendingCamera ?: return@rememberLauncherForActivityResult
        pendingCamera = null
        scope.launch {
            val bmp = withContext(Dispatchers.IO) {
                val b = if (ok) ImageTools.decode(ctx, uri) else null
                // Das Foto gehört ins Dokument, nicht in die Galerie.
                runCatching { ctx.contentResolver.delete(uri, null, null) }
                b
            }
            if (bmp != null) { images.add(bmp); afterAdd() }
        }
    }
    val cameraPreview = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { bmp ->
        if (bmp != null) { images.add(bmp); afterAdd() }
    }

    fun openCamera() {
        if (Build.VERSION.SDK_INT >= 29) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, "golftrack_scan_${System.currentTimeMillis()}.jpg")
                put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                put(MediaStore.Images.Media.IS_PENDING, 0)
            }
            val uri = runCatching { ctx.contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) }.getOrNull()
            if (uri != null) {
                pendingCamera = uri
                runCatching { camera.launch(uri) }.onFailure { pendingCamera = null }
                return
            }
        }
        runCatching { cameraPreview.launch(null) }
    }

    AppScaffold("Dokument scannen", onBack = { nav.popBackStack() }, actions = {
        if (images.isNotEmpty()) {
            TextButton(enabled = !saving, onClick = {
                Haptics.success()
                saving = true
                val finalTitle = title.ifEmpty { type.title }
                scope.launch {
                    withContext(Dispatchers.IO) { GolfDocumentStore.save(ctx, finalTitle, type, images.toList()) }
                    nav.popBackStack()
                }
            }) { Text("Speichern", color = AppTheme.gold, fontWeight = FontWeight.Bold) }
        }
    }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            if (images.isEmpty()) {
                Text(
                    "Wie möchtest du das Dokument hinzufügen?", color = AppTheme.textSec, fontSize = 15.sp,
                    textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(top = 8.dp),
                )
                SourceButton(Icons.Filled.CameraAlt, "Dokument fotografieren", "Mit der Kamera aufnehmen", AppTheme.gold) { openCamera() }
                SourceButton(Icons.Filled.PhotoLibrary, "Aus Fotos wählen", "Bereits gemachte Fotos", iosBlue) {
                    picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }
                TypePicker(type) { t -> if (title.isEmpty() || GolfDocumentType.entries.any { it.title == title }) title = t.title; type = t }
            } else {
                Column(Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(if (images.size == 1) "1 Seite" else "${images.size} Seiten", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                        Row(Modifier.clickable { Haptics.tap(); images.clear() }, verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.Refresh, null, tint = AppTheme.gold, modifier = Modifier.size(14.dp))
                            Spacer(Modifier.width(4.dp))
                            Text("Neu scannen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        images.forEachIndexed { i, b ->
                            Box(Modifier.size(100.dp, 140.dp).clip(RoundedCornerShape(10.dp)).border(1.dp, AppTheme.gold.copy(alpha = 0.4f), RoundedCornerShape(10.dp))) {
                                Image(b.asImageBitmap(), null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                                Text(
                                    "S.${i + 1}", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold,
                                    modifier = Modifier.align(Alignment.BottomStart).padding(4.dp).background(Color.Black.copy(alpha = 0.5f), RoundedCornerShape(4.dp)).padding(horizontal = 5.dp, vertical = 2.dp),
                                )
                            }
                        }
                        // Weitere Seite
                        Box(
                            Modifier.size(100.dp, 140.dp).clip(RoundedCornerShape(10.dp)).background(AppTheme.cardAlt).clickable { Haptics.tap(); openCamera() },
                            contentAlignment = Alignment.Center,
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Icon(Icons.Filled.CameraAlt, null, tint = AppTheme.gold)
                                Text("Seite hinzufügen", color = AppTheme.textSec, fontSize = 10.sp, textAlign = TextAlign.Center)
                            }
                        }
                    }
                }
                TypePicker(type) { t -> if (title.isEmpty() || GolfDocumentType.entries.any { it.title == title }) title = t.title; type = t }
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Titel", color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 4.dp))
                    OutlinedTextField(
                        title, { title = it }, singleLine = true, modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("z.B. Mitgliedskarte 2025", color = AppTheme.textTer) }, colors = fieldColors(),
                    )
                }
            }
            if (saving) CircularProgressIndicator(color = AppTheme.gold, modifier = Modifier.align(Alignment.CenterHorizontally))
        }
    }
}

@Composable
private fun SourceButton(icon: ImageVector, title: String, subtitle: String, color: Color, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(AppTheme.card).clickable { Haptics.tap(); onClick() }.padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconBadge(icon, color, 46.dp, 10.dp)
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(title, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            Text(subtitle, color = AppTheme.textSec, fontSize = 12.sp)
        }
        Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))
    }
}

@Composable
private fun TypePicker(selected: GolfDocumentType, onSelect: (GolfDocumentType) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Kategorie", color = AppTheme.textSec, fontSize = 12.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(horizontal = 2.dp))
        GolfDocumentType.entries.chunked(3).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                row.forEach { t ->
                    val sel = t == selected
                    Column(
                        Modifier.weight(1f).clip(RoundedCornerShape(12.dp))
                            .background(if (sel) AppTheme.gold.copy(alpha = 0.1f) else AppTheme.card)
                            .border(1.5.dp, if (sel) AppTheme.gold else Color.Transparent, RoundedCornerShape(12.dp))
                            .clickable { Haptics.selection(); onSelect(t) }.padding(vertical = 12.dp, horizontal = 4.dp),
                        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(7.dp),
                    ) {
                        Box(Modifier.size(40.dp).background(if (sel) AppTheme.gold.copy(alpha = 0.2f) else AppTheme.cardAlt, CircleShape), contentAlignment = Alignment.Center) {
                            Icon(t.icon, null, tint = if (sel) AppTheme.gold else AppTheme.textSec, modifier = Modifier.size(18.dp))
                        }
                        Text(t.title, color = if (sel) AppTheme.gold else AppTheme.textSec, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center, maxLines = 2)
                    }
                }
                repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}

// --- Vollbild-Ansicht (DocumentDetailView.swift) ---

@Composable
fun DocumentDetailScreen(nav: NavController, id: String) {
    val ctx = LocalContext.current
    val doc = remember(id) { GolfDocumentStore.loadAll(ctx).firstOrNull { it.id == id } }
    var confirmDelete by remember { mutableStateOf(false) }
    if (doc == null) {
        LaunchedEffect(Unit) { nav.popBackStack() }
        return
    }
    val pager = rememberPagerState { doc.pageCount }
    Column(Modifier.fillMaxSize().background(Color.Black)) {
        AppScaffold(doc.title, onBack = { nav.popBackStack() }, actions = {
            IconButton(onClick = { Haptics.tap(); confirmDelete = true }) { Icon(Icons.Filled.Delete, "Löschen", tint = iosRed) }
        }) { m ->
            Column(m.background(Color.Black)) {
                HorizontalPager(pager, Modifier.weight(1f).fillMaxWidth()) { page ->
                    val bmp by produceState<Bitmap?>(null, page) {
                        value = withContext(Dispatchers.IO) { GolfDocumentStore.loadImage(ctx, doc.imageFilenames[page]) }
                    }
                    Box(Modifier.fillMaxSize().padding(12.dp), contentAlignment = Alignment.Center) {
                        val b = bmp
                        if (b != null) Image(b.asImageBitmap(), null, Modifier.fillMaxSize(), contentScale = ContentScale.Fit)
                        else CircularProgressIndicator(color = Color.White.copy(alpha = 0.4f))
                    }
                }
                Row(Modifier.fillMaxWidth().background(Color.Black).navigationBarsPadding().padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                    IconBadge(doc.docType.icon, AppTheme.gold, 34.dp, 8.dp)
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(doc.docType.title, color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        Text(app.golftrack.feature.home.formatDateShort(doc.date), color = Color.White.copy(alpha = 0.5f), fontSize = 11.sp)
                    }
                    if (doc.pageCount > 1) {
                        Row(horizontalArrangement = Arrangement.spacedBy(5.dp), verticalAlignment = Alignment.CenterVertically) {
                            repeat(doc.pageCount) { i ->
                                val cur = i == pager.currentPage
                                Box(Modifier.size(if (cur) 7.dp else 5.dp).background(if (cur) AppTheme.gold else Color.White.copy(alpha = 0.3f), CircleShape))
                            }
                        }
                    }
                }
            }
        }
    }
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            containerColor = AppTheme.card,
            title = { Text("Dokument löschen?", color = AppTheme.text) },
            text = { Text("\"${doc.title}\" wird unwiderruflich gelöscht.", color = AppTheme.textSec) },
            confirmButton = {
                TextButton(onClick = {
                    Haptics.warning(); confirmDelete = false
                    GolfDocumentStore.delete(ctx, doc)
                    nav.popBackStack()
                }) { Text("Löschen", color = iosRed) }
            },
            dismissButton = { TextButton(onClick = { Haptics.tap(); confirmDelete = false }) { Text("Abbrechen", color = AppTheme.gold) } },
        )
    }
}
