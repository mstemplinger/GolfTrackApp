package app.golftrack.ui.onboarding

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.FastForward
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.TrackChanges
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material.icons.filled.WbCloudy
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.ContextCompat
import app.golftrack.R
import app.golftrack.data.AppFocus
import app.golftrack.data.Prefs
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Einführung wie GolfOnboardingView.swift – läuft direkt nach der
 * Schwerpunkt-Auswahl und lässt sich im Profil neu starten. Minigolf-Spieler
 * sehen nur Name und Berechtigungen, die Tour erklärt ausschließlich Golf.
 *
 * Jede Seite hat denselben Aufbau: oben die Bühne mit einer nachgebauten
 * App-Ansicht, darunter Titel, Text und zwei Stichpunkte in fester Höhe.
 */
@Composable
fun GolfOnboarding(onFinish: () -> Unit) {
    // Der Name ist Pflicht und kommt vor der Tour, danach die Berechtigungen.
    var step by remember { mutableStateOf(OnbStep.NAME) }
    val isMinigolf = Prefs.appFocus == AppFocus.MINIGOLF

    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(
            usePlatformDefaultWidth = false, dismissOnBackPress = false, dismissOnClickOutside = false, decorFitsSystemWindows = false,
        ),
    ) {
        Box(
            Modifier.fillMaxSize()
                .background(Brush.verticalGradient(listOf(Color(0xFF091A10), AppTheme.bg)))
                .statusBarsPadding().navigationBarsPadding(),
        ) {
            AnimatedContent(
                step,
                transitionSpec = {
                    (fadeIn(tween(350)) + slideInHorizontally(tween(350)) { it / 4 }) togetherWith
                        (fadeOut(tween(250)) + slideOutHorizontally(tween(350)) { -it / 4 })
                },
                label = "onboardingStep",
            ) { s ->
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopCenter) {
                    Box(Modifier.widthIn(max = 560.dp).fillMaxSize()) {
                        when (s) {
                            OnbStep.NAME -> OnbNameStep { name ->
                                Prefs.playerName = name
                                Haptics.success()
                                step = OnbStep.PERMISSIONS
                            }
                            OnbStep.PERMISSIONS -> OnbPermissionStep(isMinigolf) {
                                if (isMinigolf) onFinish() else step = OnbStep.TOUR
                            }
                            OnbStep.TOUR -> OnbTour(onFinish)
                        }
                    }
                }
            }
        }
    }
}

private enum class OnbStep { NAME, PERMISSIONS, TOUR }

// --- Seiten ---

private enum class OnbPageId { WELCOME, HOME, NEW_ROUND, SCORING, MAP, TRACKING, FINISH, LEARN, PROFILE, DONE }

private data class OnbPage(val id: OnbPageId, val chips: List<Pair<ImageVector, String>>, val title: String, val text: String)

private val onbPages = listOf(
    OnbPage(
        OnbPageId.WELCOME, listOf(Icons.Filled.Schedule to "Rund 2 Minuten", Icons.Filled.FastForward to "Jederzeit überspringbar"),
        "Dein Golf. Alles in einer App.",
        "Zählen, messen, besser werden: In zwei Minuten zeigen wir dir, was GolfTrack auf und neben dem Platz für dich erledigt.",
    ),
    OnbPage(
        OnbPageId.HOME, listOf(Icons.Filled.MyLocation to "Platz in der Nähe erkannt", Icons.Filled.WbCloudy to "Golf-Wetter stündlich"),
        "Alles Wichtige auf einen Blick",
        "Stehst du am Platz, schlägt GolfTrack ihn dir direkt vor. Dazu dein Handicap, die letzte Runde und das Golf-Wetter mit den besten Stunden zum Spielen.",
    ),
    OnbPage(
        OnbPageId.NEW_ROUND, listOf(Icons.Filled.QrCode to "QR-Code am Platz", Icons.Filled.Groups to "18 Spielformen"),
        "In Sekunden auf der Runde",
        "Platz wählen oder den QR-Code am Platz scannen, eine von 18 Spielformen aussuchen, Bag und Mitspieler dazu – fertig.",
    ),
    // Ohne Watch-Hinweis: Android hat keine Uhr-App.
    OnbPage(
        OnbPageId.SCORING, listOf(Icons.Filled.TrackChanges to "Entfernung zur Fahne"),
        "Zählen mit einem Tipp",
        "Schläge, Putts, Fairway und Grün in Regulation pro Loch. Die Entfernung zur Fahne und der passende Schläger stehen direkt darüber.",
    ),
    OnbPage(
        OnbPageId.MAP, listOf(Icons.Filled.Flag to "Fahne per Tipp", Icons.Filled.ShoppingBag to "Weiten pro Schläger"),
        "Jeder Schlag auf der Karte",
        "Fahne setzen, Schläge aufzeichnen: Jede Weite landet bei deinem Schläger. So werden die Empfehlungen mit jeder Runde genauer.",
    ),
    OnbPage(
        OnbPageId.TRACKING, listOf(Icons.Filled.Place to "Abschlag & Grün erkannt", Icons.Filled.Lock to "Nur mit Erlaubnis"),
        "Die App lernt deinen Platz",
        "Mit deiner Erlaubnis merkt sich GolfTrack deinen Weg über den Platz und erkennt daraus Abschlag, Grün und Fairway-Verlauf jedes Lochs.",
    ),
    OnbPage(
        OnbPageId.FINISH, listOf(Icons.Filled.BarChart to "Putts, Fairway, GIR", Icons.Filled.Share to "Scorekarte teilen"),
        "Handicap sofort aktuell",
        "Nach der Runde steht dein WHS-Handicap fest. Dazu Statistiken, eine Scorekarte zum Teilen und Audio-Lektionen passend zu dieser Runde.",
    ),
    OnbPage(
        OnbPageId.LEARN, listOf(Icons.Filled.Headphones to "Hören statt lesen", Icons.Filled.Verified to "Fit für die Platzreife"),
        "Besser werden – auch zuhause",
        "Audio-Trainings für Schwung, kurzes Spiel und Kopf, alle Golfregeln mit Skizzen und ein Quiz, mit dem du dich auf die Platzreife vorbereitest.",
    ),
    OnbPage(
        OnbPageId.PROFILE, listOf(Icons.Filled.ShowChart to "Handicap-Verlauf", Icons.Filled.CreditCard to "Mitgliedskarte dabei"),
        "Dein Golf-Zuhause",
        "Handicap-Verlauf, Bestleistungen und dein Bag mit den echten Weiten jedes Schlägers. Die Mitgliedskarte hast du ebenfalls immer dabei.",
    ),
    OnbPage(
        OnbPageId.DONE, listOf(Icons.Filled.Refresh to "Im Profil neu starten", Icons.Filled.Settings to "Einstellungen im Profil"),
        "Bereit für die erste Runde",
        "Unten in der Leiste erreichst du alle Bereiche. Das Tutorial findest du jederzeit wieder unter Profil → Tutorial neu starten.",
    ),
)

@Composable
private fun OnbTour(onFinish: () -> Unit) {
    val pager = rememberPagerState { onbPages.size }
    val scope = rememberCoroutineScope()
    val index = pager.currentPage
    val isLast = index == onbPages.lastIndex

    LaunchedEffect(pager) {
        var first = true
        snapshotFlow { pager.currentPage }.collect { if (!first) Haptics.selection(); first = false }
    }
    BackHandler(enabled = index > 0) { scope.launch { pager.animateScrollToPage(index - 1) } }

    Column(Modifier.fillMaxSize()) {
        // Kopfzeile: Fortschritt und „Überspringen"
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 22.dp).padding(top = 8.dp).heightIn(min = 32.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                onbPages.indices.forEach { i ->
                    val c by animateColorAsState(if (i <= index) AppTheme.gold else Color.White.copy(alpha = 0.14f), tween(250), label = "bar")
                    Box(Modifier.weight(1f).height(4.dp).background(c, CircleShape))
                }
            }
            Spacer(Modifier.width(14.dp))
            Text(
                "Überspringen", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Medium,
                modifier = Modifier.alpha(if (isLast) 0f else 1f).clip(RoundedCornerShape(6.dp))
                    .clickable(enabled = !isLast) { Haptics.tap(); onFinish() }.padding(4.dp),
            )
        }

        HorizontalPager(pager, Modifier.weight(1f)) { page ->
            OnbPageView(onbPages[page], active = pager.currentPage == page)
        }

        // Fußzeile
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 22.dp).padding(bottom = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically,
        ) {
            AnimatedVisibility(index > 0, enter = scaleIn() + fadeIn(), exit = scaleOut() + fadeOut()) {
                Box(
                    Modifier.size(54.dp).clip(CircleShape).background(AppTheme.card)
                        .clickable { Haptics.tap(); scope.launch { pager.animateScrollToPage(index - 1) } },
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Zurück", tint = AppTheme.text, modifier = Modifier.size(20.dp)) }
            }
            OnbGoldButton(
                if (isLast) "Los geht's" else if (index == 0) "Tour starten" else "Weiter",
                if (isLast) Icons.Filled.Check else Icons.AutoMirrored.Filled.ArrowForward,
                Modifier.weight(1f),
            ) {
                if (isLast) { Haptics.success(); onFinish() } else scope.launch { pager.animateScrollToPage(index + 1) }
            }
        }
    }
}

@Composable
private fun OnbPageView(page: OnbPage, active: Boolean) {
    Column(Modifier.fillMaxSize()) {
        OnbStage(active, wide = page.id == OnbPageId.WELCOME || page.id == OnbPageId.DONE, modifier = Modifier.weight(1f).padding(top = 10.dp)) {
            when (page.id) {
                OnbPageId.WELCOME -> OnbWelcomeVisual(active)
                OnbPageId.HOME -> OnbHomeMock(active)
                OnbPageId.NEW_ROUND -> OnbNewRoundMock(active)
                OnbPageId.SCORING -> OnbScoringMock(active)
                OnbPageId.MAP -> OnbShotMapMock(active)
                OnbPageId.TRACKING -> OnbTrackingMock(active)
                OnbPageId.FINISH -> OnbRoundCompleteMock(active)
                OnbPageId.LEARN -> OnbTrainingMock(active)
                OnbPageId.PROFILE -> OnbProfileMock(active)
                OnbPageId.DONE -> OnbTabGuideVisual(active)
            }
        }
        // Feste Höhe: das Gerät darüber bleibt auf jeder Seite gleich groß.
        Column(
            Modifier.fillMaxWidth().heightIn(min = 186.dp).padding(horizontal = 26.dp).padding(top = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(page.title, color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            Text(page.text, color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.Center, lineHeight = 21.sp)
            Row(Modifier.padding(top = 4.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                page.chips.forEach { (icon, text) ->
                    Row(
                        Modifier.background(AppTheme.gold.copy(alpha = 0.13f), CircleShape).padding(horizontal = 10.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(12.dp))
                        Spacer(Modifier.width(4.dp))
                        Text(text, color = AppTheme.gold, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    }
                }
            }
        }
    }
}

/**
 * Gleich große Fläche für jede Visualisierung, mit leichtem Lichtkegel
 * dahinter. Die Inhalte werden für eine feste Zeichenfläche gebaut und auf
 * den verfügbaren Platz skaliert – so sehen sie auf jedem Gerät gleich aus.
 */
@Composable
private fun OnbStage(active: Boolean, wide: Boolean, modifier: Modifier, content: @Composable () -> Unit) {
    val cw = if (wide) OnbCanvas.wideWidth else OnbCanvas.width
    val ch = if (wide) OnbCanvas.wideHeight else OnbCanvas.height
    val emphasis by animateFloatAsState(if (active) 1f else 0f, tween(450), label = "stage")
    BoxWithConstraints(
        modifier.fillMaxWidth().background(
            Brush.radialGradient(listOf(AppTheme.gold.copy(alpha = 0.20f), AppTheme.green.copy(alpha = 0.10f), Color.Transparent)),
        ),
        contentAlignment = Alignment.Center,
    ) {
        val scale = minOf(maxWidth / cw, maxHeight / ch)
        Box(
            Modifier.requiredSize(cw, ch).graphicsLayer {
                val s = scale * (0.94f + 0.06f * emphasis)
                scaleX = s; scaleY = s
                alpha = 0.6f + 0.4f * emphasis
            },
            contentAlignment = Alignment.Center,
        ) { content() }
    }
}

@Composable
private fun OnbGoldButton(text: String, icon: ImageVector?, modifier: Modifier = Modifier, enabled: Boolean = true, onClick: () -> Unit) {
    Row(
        modifier.fillMaxWidth().alpha(if (enabled) 1f else 0.45f).clip(RoundedCornerShape(14.dp)).background(AppTheme.gold)
            .clickable(enabled = enabled) { onClick() }.padding(vertical = 16.dp),
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text, color = AppTheme.onGold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
        if (icon != null) {
            Spacer(Modifier.width(8.dp))
            Icon(icon, null, tint = AppTheme.onGold, modifier = Modifier.size(18.dp))
        }
    }
}

// --- Name ---

/**
 * Erster Schritt: der Name, mit dem die App begrüßt und der in Runden und
 * Scorekarten steht. Ohne Namen geht es nicht weiter.
 */
@Composable
private fun OnbNameStep(onContinue: (String) -> Unit) {
    // Nur einen selbst gewählten Namen vorschlagen, nicht den Platzhalter.
    var name by remember { mutableStateOf(Prefs.playerName.let { if (it == "Golfer") "" else it }) }
    var focused by remember { mutableStateOf(false) }
    val focus = remember { FocusRequester() }
    val focusManager = LocalFocusManager.current
    val trimmed = name.trim()
    fun submit() {
        if (trimmed.isEmpty()) return
        focusManager.clearFocus()
        onContinue(trimmed.take(30))
    }
    // Erst nach dem Aufbau des Dialogfensters, sonst landet die Tastatur nicht im Feld.
    LaunchedEffect(Unit) { delay(350); runCatching { focus.requestFocus() } }

    Column(Modifier.fillMaxSize().imePadding().padding(horizontal = 26.dp).padding(bottom = 12.dp)) {
        Column(
            Modifier.weight(1f).verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(48.dp))
            Image(
                painterResource(R.mipmap.ic_launcher), null, contentScale = ContentScale.Crop,
                modifier = Modifier.size(84.dp).shadow(22.dp, RoundedCornerShape(20.dp), spotColor = AppTheme.gold).clip(RoundedCornerShape(20.dp)),
            )
            Spacer(Modifier.height(26.dp))
            Text("Willkommen bei GolfTrack", color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            Spacer(Modifier.height(10.dp))
            Text(
                "Wie dürfen wir dich nennen? Dein Name steht auf deinen Scorekarten und begrüßt dich auf der Startseite.",
                color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.Center, lineHeight = 21.sp,
            )
            Spacer(Modifier.height(28.dp))
            BasicTextField(
                value = name,
                onValueChange = { name = it },
                singleLine = true,
                textStyle = TextStyle(color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center),
                cursorBrush = SolidColor(AppTheme.gold),
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words, autoCorrectEnabled = false, imeAction = ImeAction.Next),
                keyboardActions = KeyboardActions(onNext = { submit() }),
                modifier = Modifier.fillMaxWidth().focusRequester(focus).onFocusChanged { focused = it.isFocused },
                decorationBox = { inner ->
                    Box(
                        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp))
                            .border(1.5.dp, if (focused) AppTheme.gold else Color.White.copy(alpha = 0.08f), RoundedCornerShape(14.dp))
                            .padding(vertical = 16.dp, horizontal = 18.dp),
                        contentAlignment = Alignment.Center,
                    ) {
                        if (name.isEmpty()) Text("Dein Name", color = AppTheme.textTer, fontSize = 20.sp, fontWeight = FontWeight.SemiBold)
                        inner()
                    }
                },
            )
        }
        Spacer(Modifier.height(12.dp))
        OnbGoldButton("Weiter", Icons.AutoMirrored.Filled.ArrowForward, enabled = trimmed.isNotEmpty()) { submit() }
    }
}

// --- Berechtigungen ---

private const val TRACKING_KEY = "tracking.roundPath.enabled"

/**
 * Zweiter Schritt: Mitteilungen und Standort nacheinander erfragen, dann das
 * Positions-Tracking anbieten. Android zeichnet nur auf, solange GolfTrack
 * geöffnet ist – darum entfällt die Frage nach „Standort immer".
 */
@Composable
private fun OnbPermissionStep(isMinigolf: Boolean, onDone: () -> Unit) {
    val ctx = LocalContext.current
    var tracking by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }

    fun afterAsking() {
        busy = false
        if (isMinigolf) onDone() else tracking = true
    }
    val locationLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { afterAsking() }
    fun askLocation() {
        val granted = ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (granted) afterAsking()
        else {
            Prefs.set(LaunchKeys.LOCATION_ASKED, true)
            locationLauncher.launch(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION))
        }
    }
    // Erst Mitteilungen, dann Standort – die zweite Rückfrage erscheint erst, wenn die erste beantwortet ist.
    val notificationLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { askLocation() }
    fun askSystemPermissions() {
        Haptics.tap()
        busy = true
        val needsNotification = Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        if (needsNotification) {
            Prefs.set("notif.permissionAsked", true)
            notificationLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        } else askLocation()
    }

    Column(Modifier.fillMaxSize().padding(horizontal = 26.dp).padding(bottom = 12.dp)) {
        Box(Modifier.weight(1f).fillMaxWidth().verticalScroll(rememberScrollState()), contentAlignment = Alignment.Center) {
            AnimatedContent(tracking, transitionSpec = { fadeIn(tween(300)) togetherWith fadeOut(tween(300)) }, label = "perm") { t ->
                Column(Modifier.fillMaxWidth().padding(vertical = 24.dp), verticalArrangement = Arrangement.spacedBy(22.dp)) {
                    if (!t) {
                        PermHeader(
                            Icons.Filled.VerifiedUser, "Zwei kurze Fragen",
                            "Android fragt gleich nach deiner Erlaubnis. Du kannst beides später in den Einstellungen ändern.",
                        )
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            PermRow(Icons.Filled.NotificationsActive, "Mitteilungen", "Erinnerungen an offene Runden und ans Spielen.")
                            PermRow(
                                Icons.Filled.MyLocation, "Standort",
                                if (isMinigolf) "Anlagen in deiner Nähe und das Wetter für deine Partie."
                                else "Platz in der Nähe, Golf-Wetter und Entfernung zur Fahne.",
                            )
                        }
                    } else {
                        PermHeader(
                            Icons.Filled.Place, "Positions-Tracking einschalten?",
                            "Mit deiner Erlaubnis merkt sich GolfTrack deinen Weg über den Platz und erkennt daraus Abschlag, Grün und Fairway-Verlauf jedes Lochs.",
                        )
                        Column(
                            Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(14.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.AutoMirrored.Filled.DirectionsWalk, null, tint = AppTheme.gold, modifier = Modifier.size(16.dp))
                                Spacer(Modifier.width(6.dp))
                                Text("Nur während der Runde", color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
                            }
                            Text(
                                "Android zeichnet während der Runde weiter auf, solange GolfTrack geöffnet ist. Rechne mit etwas mehr Akkuverbrauch als ohne Tracking.",
                                color = AppTheme.textSec, fontSize = 12.sp,
                            )
                            Text(
                                "Die Aufzeichnung ist standardmäßig aus und läuft nur während einer Runde. Die Daten bleiben auf deinem Gerät und werden nicht übertragen. Du kannst das Tracking jederzeit in den Einstellungen abschalten und die Aufzeichnungen dort löschen.",
                                color = AppTheme.textSec, fontSize = 12.sp,
                            )
                        }
                    }
                }
            }
        }
        if (!tracking) {
            OnbGoldButton("Weiter", Icons.AutoMirrored.Filled.ArrowForward, enabled = !busy) { askSystemPermissions() }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OnbGoldButton("Aufzeichnung einschalten", null) {
                    Haptics.success()
                    Prefs.set(TRACKING_KEY, true)
                    onDone()
                }
                Text(
                    "Später entscheiden", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).clickable { Haptics.tap(); onDone() }.padding(vertical = 12.dp),
                )
            }
        }
    }
}

@Composable
private fun PermHeader(icon: ImageVector, title: String, text: String) {
    Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Box(Modifier.size(84.dp).background(AppTheme.gold.copy(alpha = 0.13f), CircleShape), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(36.dp))
        }
        Text(title, color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        Text(text, color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.Center, lineHeight = 21.sp)
    }
}

@Composable
private fun PermRow(icon: ImageVector, title: String, text: String) {
    Row(
        Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(14.dp)).padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(40.dp).background(AppTheme.gold.copy(alpha = 0.13f), RoundedCornerShape(10.dp)), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(19.dp))
        }
        Spacer(Modifier.width(14.dp))
        Column {
            Text(title, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
            Text(text, color = AppTheme.textSec, fontSize = 12.sp)
        }
    }
}
