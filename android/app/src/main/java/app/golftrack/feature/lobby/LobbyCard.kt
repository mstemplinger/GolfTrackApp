package app.golftrack.feature.lobby

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.LocationOff
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Tag
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import app.golftrack.data.Course
import app.golftrack.data.GolfStore
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.feature.golf.FullSheet
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.launch
import java.io.File
import java.text.Normalizer

private val darkText = Color(0xFF0F2414)
private val orange = Color(0xFFFF9500)

/**
 * „Mit Freunden spielen“ beim Rundenstart (wie LobbyCard.swift): Lobby anlegen,
 * mit Code oder QR-Code beitreten, wer dabei ist, und ob man sich gegenseitig
 * orten kann. Gäste übernehmen den Platz des Gastgebers über `onSelectCourse`.
 */
@Composable
fun LobbyCard(
    selectedCourse: Course?,
    courses: List<Course>,
    playerName: String,
    onSelectCourse: (String) -> Unit,
) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val session by LobbyService.session.collectAsState()
    val state by LobbyService.state.collectAsState()
    val isBusy by LobbyService.isBusy.collectAsState()
    val error by LobbyService.errorMessage.collectAsState()
    val ended by LobbyService.endedNotice.collectAsState()
    val pending by LobbyService.pendingJoinCode.collectAsState()
    val catalog by CourseCatalog.golfCourses.collectAsState()

    var enteringCode by rememberSaveable { mutableStateOf(false) }
    var codeInput by rememberSaveable { mutableStateOf("") }
    var showQrLarge by remember { mutableStateOf(false) }
    var trackingOnCreate by rememberSaveable { mutableStateOf(true) }
    var captureUri by remember { mutableStateOf<Uri?>(null) }

    /** Gäste spielen den Platz des Gastgebers: aus den eigenen Plätzen, sonst aus dem Verzeichnis. */
    fun adoptHostCourse() {
        val s = LobbyService.state.value ?: return
        if (LobbyService.isHost || s.courseName.isEmpty()) return
        val name = normalizedCourseName(s.courseName)
        if (selectedCourse != null && normalizedCourseName(selectedCourse.name) == name) return
        courses.firstOrNull { normalizedCourseName(it.name) == name }?.let { onSelectCourse(it.id); return }
        val entry = (if (s.courseSlug.isEmpty()) null else CourseCatalog.golfCourse(s.courseSlug))
            ?: catalog.firstOrNull { normalizedCourseName(it.name) == name }
        if (entry != null) onSelectCourse(GolfStore.storedCourse(entry.toCourse()).id)
    }

    fun join(raw: String) {
        Haptics.medium()
        LobbyService.join(raw, playerName) { ok ->
            if (ok) {
                Haptics.success()
                adoptHostCourse()
                enteringCode = false
                codeInput = ""
            } else {
                Haptics.error()
            }
        }
    }

    // Kennung des Platzes im Verzeichnis – damit Gäste ihn auch finden, wenn sie ihn noch nie gespielt haben.
    fun catalogSlug(course: Course?): String {
        course ?: return ""
        if (course.slug.isNotEmpty()) return course.slug
        val name = normalizedCourseName(course.name)
        return catalog.firstOrNull { normalizedCourseName(it.name) == name }?.slug ?: ""
    }

    val takePicture = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { ok ->
        val uri = captureUri ?: return@rememberLauncherForActivityResult
        captureUri = null
        scope.launch {
            val code = if (ok) LobbyQr.decode(ctx, uri) else null
            runCatching { ctx.contentResolver.delete(uri, null, null) }
            if (code != null) {
                Haptics.success()
                join(code)
            } else if (ok) {
                Haptics.error()
                LobbyService.errorMessage.value = "Kein Lobby-QR-Code erkannt. Halte die Kamera auf den QR-Code deines Freundes – oder gib den fünfstelligen Code ein."
            }
        }
    }

    fun openScanner() {
        Haptics.tap()
        try {
            val uri = createScanUri(ctx)
            captureUri = uri
            takePicture.launch(uri)
        } catch (e: Exception) {
            captureUri = null
            LobbyService.errorMessage.value = "Kamera nicht verfügbar – gib den fünfstelligen Code ein."
        }
    }

    // Abgleich, solange die Karte sichtbar ist und die App vorn.
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle) {
        LobbyService.startPolling()
        val obs = LifecycleEventObserver { _, e ->
            when (e) {
                Lifecycle.Event.ON_START -> { LobbyService.onForeground(ctx); LobbyService.startPolling() }
                Lifecycle.Event.ON_STOP -> LobbyService.onBackground(ctx)
                else -> {}
            }
        }
        lifecycle.addObserver(obs)
        onDispose {
            lifecycle.removeObserver(obs)
            LobbyService.pauseIfIdle()
        }
    }
    // Code aus einem gescannten Link: beitreten bzw. die alte Lobby wechseln.
    LaunchedEffect(pending) {
        val code = pending ?: return@LaunchedEffect
        LobbyService.pendingJoinCode.value = null
        if (LobbyService.code == code) return@LaunchedEffect
        if (LobbyService.isActive) LobbyService.leave { join(code) } else join(code)
    }
    // Gastgeber wechselt den Platz → Gäste ziehen mit. Gäste selbst springen auf den Platz der Lobby zurück.
    LaunchedEffect(selectedCourse?.id, state?.courseName, state?.courseSlug, catalog.size) {
        if (LobbyService.isHost && selectedCourse != null) {
            LobbyService.setCourse(selectedCourse.name, catalogSlug(selectedCourse), selectedCourse.numberOfHoles)
        } else {
            adoptHostCourse()
        }
    }

    Column(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        val current = state
        when {
            session != null && current != null -> ActiveContent(current, onShowQr = { showQrLarge = true })
            session != null -> Row(verticalAlignment = Alignment.CenterVertically) {
                CircularProgressIndicator(color = AppTheme.gold, strokeWidth = 2.dp, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(10.dp))
                Text("Lobby wird geladen …", color = AppTheme.textSec, fontSize = 14.sp)
            }
            else -> IdleContent(
                trackingOnCreate = trackingOnCreate,
                onTrackingChange = { trackingOnCreate = it },
                isBusy = isBusy,
                enteringCode = enteringCode,
                codeInput = codeInput,
                onCreate = {
                    Haptics.medium()
                    LobbyService.create(
                        name = playerName,
                        courseName = selectedCourse?.name ?: "",
                        courseSlug = catalogSlug(selectedCourse),
                        holes = selectedCourse?.numberOfHoles ?: 18,
                        tracking = trackingOnCreate,
                    ) { if (LobbyService.isActive) Haptics.success() }
                },
                onToggleCode = { Haptics.tap(); enteringCode = !enteringCode },
                onScan = ::openScanner,
                onCodeChange = { codeInput = it.filter(Char::isDigit).take(5) },
                onJoin = { join(codeInput) },
            )
        }
        error?.let {
            Row(verticalAlignment = Alignment.Top) {
                Icon(Icons.Filled.Warning, null, tint = orange, modifier = Modifier.size(14.dp).padding(top = 1.dp))
                Spacer(Modifier.width(6.dp))
                Text(it, color = orange, fontSize = 12.sp)
            }
        }
    }

    if (showQrLarge) {
        LobbyService.code?.let { code -> LobbyQrSheet(code) { showQrLarge = false } }
    }
    ended?.let { notice ->
        AlertDialog(
            onDismissRequest = { LobbyService.endedNotice.value = null },
            title = { Text("Lobby beendet") },
            text = { Text(notice) },
            confirmButton = {
                TextButton(onClick = { LobbyService.endedNotice.value = null }) { Text("OK", color = AppTheme.gold) }
            },
            containerColor = AppTheme.card,
        )
    }
}

// MARK: Noch keine Lobby

@Composable
private fun IdleContent(
    trackingOnCreate: Boolean,
    onTrackingChange: (Boolean) -> Unit,
    isBusy: Boolean,
    enteringCode: Boolean,
    codeInput: String,
    onCreate: () -> Unit,
    onToggleCode: () -> Unit,
    onScan: () -> Unit,
    onCodeChange: (String) -> Unit,
    onJoin: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(40.dp).background(AppTheme.gold.copy(alpha = 0.15f), RoundedCornerShape(11.dp)),
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Filled.Groups, null, tint = AppTheme.gold, modifier = Modifier.size(20.dp)) }
            Spacer(Modifier.width(12.dp))
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text("Mit Freunden spielen", color = AppTheme.text, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                Text("Jeder zählt auf seinem Handy – ihr seht live die Schläge der anderen.", color = AppTheme.textSec, fontSize = 12.sp)
            }
        }

        ToggleRow(
            title = "Gegenseitig orten",
            subtitle = "Während der Runde seht ihr, wo die anderen gerade sind.",
            checked = trackingOnCreate,
            onChange = { Haptics.selection(); onTrackingChange(it) },
        )

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                Modifier.weight(1f).background(AppTheme.gold.copy(alpha = if (isBusy) 0.5f else 1f), RoundedCornerShape(12.dp))
                    .clickable(enabled = !isBusy) { onCreate() }.padding(vertical = 11.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Add, null, tint = darkText, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text("Lobby erstellen", color = darkText, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            }
            Row(
                Modifier.background(AppTheme.gold.copy(alpha = 0.15f), RoundedCornerShape(12.dp))
                    .clickable { onToggleCode() }.padding(vertical = 11.dp, horizontal = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Tag, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text("Code", color = AppTheme.gold, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            }
            Box(
                Modifier.background(AppTheme.gold.copy(alpha = 0.15f), RoundedCornerShape(12.dp))
                    .clickable { onScan() }.padding(vertical = 11.dp, horizontal = 14.dp),
                contentAlignment = Alignment.Center,
            ) { Icon(Icons.Filled.QrCodeScanner, "QR-Code scannen", tint = AppTheme.gold, modifier = Modifier.size(18.dp)) }
        }

        AnimatedVisibility(enteringCode) {
            val focus = remember { FocusRequester() }
            LaunchedEffect(Unit) { runCatching { focus.requestFocus() } }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier.weight(1f).background(AppTheme.bg, RoundedCornerShape(10.dp)).padding(horizontal = 12.dp, vertical = 9.dp),
                ) {
                    val style = TextStyle(color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.SemiBold, fontFamily = FontFamily.Monospace)
                    if (codeInput.isEmpty()) Text("5-stelliger Code", style = style.copy(color = AppTheme.textTer, fontFamily = FontFamily.Default))
                    BasicTextField(
                        value = codeInput,
                        onValueChange = onCodeChange,
                        singleLine = true,
                        textStyle = style,
                        cursorBrush = SolidColor(AppTheme.gold),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                        modifier = Modifier.fillMaxWidth().focusRequester(focus),
                    )
                }
                val ready = codeInput.length == 5 && !isBusy
                Box(
                    Modifier.background(if (codeInput.length == 5) AppTheme.gold else Color.Gray.copy(alpha = 0.3f), RoundedCornerShape(12.dp))
                        .clickable(enabled = ready) { onJoin() }.padding(vertical = 11.dp, horizontal = 14.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    if (isBusy) CircularProgressIndicator(color = darkText, strokeWidth = 2.dp, modifier = Modifier.size(16.dp))
                    else Text("Beitreten", color = if (codeInput.length == 5) darkText else AppTheme.textSec, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

// MARK: In der Lobby

@Composable
private fun ActiveContent(state: LobbyState, onShowQr: () -> Unit) {
    val ctx = LocalContext.current
    val isHost = LobbyService.isHost
    val share by LobbyService.shareLocation.collectAsState()
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            LobbyQrCode(state.code, Modifier.size(84.dp).clickable { Haptics.tap(); onShowQr() })
            Spacer(Modifier.width(14.dp))
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("LOBBY-CODE", color = AppTheme.textTer, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 0.6.sp)
                Text(spaced(state.code), color = AppTheme.gold, fontSize = 32.sp, fontWeight = FontWeight.Black)
                Row(
                    Modifier.clickable { Haptics.tap(); invite(ctx, state.code) },
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Filled.Share, null, tint = AppTheme.gold, modifier = Modifier.size(13.dp))
                    Spacer(Modifier.width(5.dp))
                    Text("Einladen", color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                }
            }
        }

        if (state.courseName.isNotEmpty()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Flag, null, tint = AppTheme.textSec, modifier = Modifier.size(13.dp))
                Spacer(Modifier.width(6.dp))
                Text(
                    if (isHost) state.courseName else "${state.courseName} – vom Gastgeber übernommen",
                    color = AppTheme.textSec, fontSize = 12.sp, maxLines = 2,
                )
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            state.members.forEach { member -> MemberRow(member, isMe = member.id == state.me, canRemove = isHost) }
            if (state.members.size < 2) {
                Text("Warte auf Freunde – sie scannen den QR-Code oder geben den Code ein.", color = AppTheme.textSec, fontSize = 12.sp)
            }
        }

        HorizontalDivider(color = AppTheme.textTer.copy(alpha = 0.3f))

        if (isHost) {
            ToggleRow("Gegenseitig orten", null, state.tracking) { Haptics.selection(); LobbyService.setTracking(it) }
        } else {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(if (state.tracking) Icons.Filled.LocationOn else Icons.Filled.LocationOff, null, tint = AppTheme.textSec, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(6.dp))
                Text(if (state.tracking) "Gegenseitiges Orten ist an" else "Gegenseitiges Orten ist aus", color = AppTheme.textSec, fontSize = 14.sp)
            }
        }
        if (state.tracking) {
            ToggleRow("Meinen Standort teilen", "Nur während der Runde, nur für diese Lobby.", share) {
                Haptics.selection(); LobbyService.setShareLocation(it, ctx)
            }
        }

        Text(
            if (isHost) "Lobby auflösen" else "Lobby verlassen",
            color = Color(0xFFFF453A), fontSize = 14.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().clickable { Haptics.warning(); LobbyService.leave() }.padding(vertical = 8.dp),
        )
    }
}

@Composable
private fun MemberRow(member: LobbyMember, isMe: Boolean, canRemove: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Initial(member.name, alpha = if (isMe) 0.85f else 0.55f)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(if (isMe) "${member.name} (du)" else member.name, color = AppTheme.text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            if (member.isHost) Text("Gastgeber", color = AppTheme.gold, fontSize = 11.sp)
        }
        if (canRemove && !isMe) {
            Icon(
                Icons.Filled.RemoveCircle, "${member.name} entfernen", tint = AppTheme.textTer,
                modifier = Modifier.size(24.dp).clickable { Haptics.light(); LobbyService.remove(member) },
            )
        }
    }
}

@Composable
internal fun Initial(name: String, alpha: Float = 0.55f, size: Int = 32) {
    Box(Modifier.size(size.dp).background(AppTheme.gold.copy(alpha = alpha), CircleShape), contentAlignment = Alignment.Center) {
        Text(name.take(1).uppercase(), color = darkText, fontSize = 14.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun ToggleRow(title: String, subtitle: String?, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(1.dp)) {
            Text(title, color = AppTheme.text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            subtitle?.let { Text(it, color = AppTheme.textSec, fontSize = 12.sp) }
        }
        Spacer(Modifier.width(8.dp))
        Switch(
            checked = checked, onCheckedChange = onChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White, checkedTrackColor = AppTheme.gold, checkedBorderColor = AppTheme.gold,
                uncheckedThumbColor = Color.White, uncheckedTrackColor = AppTheme.cardAlt, uncheckedBorderColor = AppTheme.cardAlt,
            ),
        )
    }
}

/** Großer QR-Code zum Scannen (wie `LobbyQRSheet`). */
@Composable
private fun LobbyQrSheet(code: String, onDismiss: () -> Unit) {
    FullSheet(onDismiss) {
        Column(
            Modifier.fillMaxSize().padding(24.dp).navigationBarsPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(22.dp, Alignment.CenterVertically),
        ) {
            Text("Zum Beitreten scannen", color = AppTheme.textSec, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
            LobbyQrCode(code, Modifier.widthIn(max = 300.dp).fillMaxWidth())
            Text(spaced(code), color = AppTheme.gold, fontSize = 44.sp, fontWeight = FontWeight.Black)
            Text(
                "Freunde öffnen GolfTrack → Neue Runde → Mit Freunden spielen und scannen den Code – oder geben die fünf Ziffern ein.",
                color = AppTheme.textSec, fontSize = 13.sp, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 24.dp),
            )
            Text(
                "Fertig", color = AppTheme.gold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable { Haptics.tap(); onDismiss() }.padding(8.dp),
            )
        }
    }
}

// MARK: Hilfen

private fun spaced(code: String) = code.toList().joinToString(" ")

private fun invite(ctx: Context, code: String) {
    val text = "Spiel mit mir bei GolfTrack – Lobby-Code $code\n${LobbyService.joinUrl(code)}"
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, text)
    }
    ctx.startActivity(Intent.createChooser(intent, null))
}

/** Foto für den QR-Scan im Cache (`cache/shared/`, siehe res/xml/file_paths.xml). */
private fun createScanUri(ctx: Context): Uri {
    val dir = File(ctx.cacheDir, "shared").apply { mkdirs() }
    val file = File(dir, "lobby-scan.jpg")
    return FileProvider.getUriForFile(ctx, "${ctx.packageName}.fileprovider", file)
}

/**
 * Platznamen vergleichbar machen: „Golf- und Landclub Bayerwald e.V.“ und
 * „golf und landclub bayerwald“ sind derselbe Platz.
 */
fun normalizedCourseName(name: String): String {
    var text = Normalizer.normalize(name.lowercase(), Normalizer.Form.NFD).replace(Regex("\\p{Mn}+"), "")
    for (suffix in listOf(" e.v.", " e. v.", " ev")) {
        if (text.endsWith(suffix)) text = text.dropLast(suffix.length)
    }
    return text.filter { it.isLetterOrDigit() }
}
