package app.golftrack.ui.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.navigation.NavController
import app.golftrack.data.Prefs
import app.golftrack.data.rememberPrefBool
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** Schlüssel wie auf iOS. */
object LaunchKeys {
    const val SHOW_INTRO = "showLaunchIntro"
    const val HAS_SEEN_ONBOARDING = "hasSeenOnboarding"
    const val HAS_CHOSEN_FOCUS = "hasChosenAppFocus"
    const val WHATS_NEW_SEEN = "whatsNew.lastSeenRelease"
    const val WHATS_NEW_RELEASE = "positions-tracking-1"

    /** Ziel der Update-Einführung (registriert in `profileRoutes`). */
    const val WHATS_NEW_ROUTE = "profile/whatsnew"
}

/** Nur einmal je Prozess: Intro und Update-Einführung beim Start. */
private object LaunchSession {
    var splashDone = false
    var whatsNewChecked = false
}

/**
 * Alles, was beim Start über der App liegt: Intro-Animation (falls im Profil
 * eingeschaltet), Update-Einführung und das Tutorial. Steht auf der
 * Startseite und im Profil (dort lässt sich das Tutorial neu starten).
 */
@Composable
fun LaunchOverlays(nav: NavController) {
    val hasChosenFocus by rememberPrefBool(LaunchKeys.HAS_CHOSEN_FOCUS)
    var hasSeenOnboarding by rememberPrefBool(LaunchKeys.HAS_SEEN_ONBOARDING)
    var showSplash by remember { mutableStateOf(!LaunchSession.splashDone && Prefs.bool(LaunchKeys.SHOW_INTRO)) }

    if (showSplash) {
        SplashOverlay {
            LaunchSession.splashDone = true
            showSplash = false
        }
        return
    }
    LaunchSession.splashDone = true

    // Update-Einführung nur für Bestandsnutzer – Neuinstallationen sehen das Tutorial.
    LaunchedEffect(hasChosenFocus) {
        if (!hasChosenFocus || LaunchSession.whatsNewChecked) return@LaunchedEffect
        LaunchSession.whatsNewChecked = true
        if (!Prefs.bool(LaunchKeys.HAS_SEEN_ONBOARDING)) {
            Prefs.set(LaunchKeys.WHATS_NEW_SEEN, LaunchKeys.WHATS_NEW_RELEASE)
        } else if (Prefs.string(LaunchKeys.WHATS_NEW_SEEN) != LaunchKeys.WHATS_NEW_RELEASE) {
            Prefs.set(LaunchKeys.WHATS_NEW_SEEN, LaunchKeys.WHATS_NEW_RELEASE)
            nav.navigate(LaunchKeys.WHATS_NEW_ROUTE)
        }
    }

    if (hasChosenFocus && !hasSeenOnboarding) {
        OnboardingOverlay(onFinish = { hasSeenOnboarding = true })
    }
}

// --- Tutorial ---

private data class Step(val icon: ImageVector, val color: Color, val title: String, val body: String)

private val steps = listOf(
    Step(Icons.Filled.SportsGolf, AppTheme.gold, "Willkommen bei GolfTrack",
        "In wenigen Schritten zeigen wir dir alles Wichtige. Tippe auf Weiter, um zu starten."),
    Step(Icons.Filled.Home, AppTheme.gold, "Dein Dashboard",
        "Hier siehst du dein Handicap, das aktuelle Wetter und deine letzte Runde auf einen Blick."),
    Step(Icons.Filled.AddCircle, Color(0xFF4DD980), "Neue Runde starten",
        "Tippe auf „Neue Runde spielen\", um eine Runde zu beginnen. Du wählst Platz, Modus und Löcherzahl."),
    Step(Icons.Filled.Place, Color(0xFFFF453A), "Lochposition setzen",
        "Tippe beim Scoring auf \"Lochposition festlegen\" und markiere den Pin auf der Karte. Die App zeigt dir danach die genaue Distanz zum Loch."),
    Step(Icons.Filled.SportsGolf, AppTheme.gold, "Schlägerverwaltung",
        "Basierend auf deinen gespeicherten Schlägerdistanzen empfiehlt die App automatisch den besten Schläger. Deine Messungen werden mit jeder Runde genauer."),
    Step(Icons.Filled.Map, Color(0xFF66B3FF), "Schläge tracken",
        "Tippe auf \"Schläge aufzeichnen\", setze Abschlag und Landepunkt auf der Karte. Distanz wird berechnet und dem Schläger gutgeschrieben."),
    Step(Icons.Filled.AccountCircle, AppTheme.gold, "Dein Profil",
        "Ändere im Profil deinen Namen und dein Foto. Deine Statistiken findest du direkt darunter."),
    Step(Icons.Filled.EmojiEvents, AppTheme.gold, "Handicap & Errungenschaften",
        "Dein WHS-Handicap wird nach jeder Runde automatisch berechnet. Scrolle im Profil für Golfplatz-Einstellungen."),
    Step(Icons.AutoMirrored.Filled.MenuBook, Color(0xFF8CB3FF), "Spielregeln & Tipps",
        "Alle offiziellen Golf-Regeln und Profi-Tipps sind immer griffbereit — egal ob auf dem Platz oder zuhause."),
    Step(Icons.Filled.CheckCircle, Color(0xFF4DD980), "Du bist startklar!",
        "Das war der Schnelleinstieg. Viel Spaß auf dem Platz!"),
)

/** Tutorial wie OnboardingOverlayView.swift – auf Android als zentrierte Karten ohne Spotlight. */
@Composable
fun OnboardingOverlay(onFinish: () -> Unit) {
    var current by remember { mutableIntStateOf(0) }
    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(usePlatformDefaultWidth = false, dismissOnBackPress = false, dismissOnClickOutside = false, decorFitsSystemWindows = false),
    ) {
        Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.85f)), contentAlignment = Alignment.Center) {
            AnimatedContent(
                current,
                transitionSpec = { (fadeIn(tween(250)) + scaleIn(initialScale = 0.93f)) togetherWith fadeOut(tween(150)) },
                label = "step",
            ) { idx ->
                val step = steps[idx]
                val last = idx == steps.lastIndex
                Column(
                    Modifier.padding(horizontal = 24.dp).fillMaxWidth()
                        .background(AppTheme.card, RoundedCornerShape(26.dp)).padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(20.dp),
                ) {
                    Box(
                        Modifier.padding(top = 8.dp).size(90.dp).background(step.color.copy(alpha = 0.14f), CircleShape),
                        contentAlignment = Alignment.Center,
                    ) { Icon(step.icon, null, tint = step.color, modifier = Modifier.size(40.dp)) }
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text(step.title, color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
                        Text(step.body, color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.Center, lineHeight = 21.sp)
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                        steps.indices.forEach { i ->
                            Box(
                                Modifier.height(6.dp).width(if (i == idx) 18.dp else 6.dp)
                                    .background(if (i == idx) AppTheme.gold else Color.White.copy(alpha = 0.2f), CircleShape),
                            )
                        }
                    }
                    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            if (idx > 1) {
                                Box(
                                    Modifier.clip(RoundedCornerShape(14.dp)).background(AppTheme.cardAlt)
                                        .clickable { Haptics.selection(); current -= 1 }.padding(horizontal = 18.dp, vertical = 14.dp),
                                ) { Text("Zurück", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold) }
                            }
                            Box(
                                Modifier.weight(1f).clip(RoundedCornerShape(14.dp)).background(AppTheme.gold)
                                    .clickable {
                                        if (last) { Haptics.success(); onFinish() } else { Haptics.selection(); current += 1 }
                                    }
                                    .padding(vertical = 14.dp),
                                contentAlignment = Alignment.Center,
                            ) {
                                Text(if (last) "Tutorial beenden" else "Weiter", color = Color(0xFF0F2414), fontSize = 15.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                        if (!last) {
                            Text(
                                "Überspringen", color = AppTheme.textSec, fontSize = 15.sp,
                                modifier = Modifier.clip(RoundedCornerShape(8.dp)).clickable { Haptics.tap(); onFinish() }.padding(6.dp),
                            )
                        }
                    }
                }
            }
        }
    }
}

// --- Intro-Animation (SplashView.swift) ---

@Composable
fun SplashOverlay(onComplete: () -> Unit) {
    val bg = Color(0xFF0D2E14)
    val mid = Color(0xFF175726)
    val ballScale = remember { Animatable(0.04f) }
    val ballAlpha = remember { Animatable(1f) }
    val ballDrop = remember { Animatable(0f) }
    val holePulse = remember { Animatable(1f) }
    val ripple = remember { Animatable(0f) }
    val titleAlpha = remember { Animatable(0f) }
    val titleY = remember { Animatable(28f) }
    val subtitleAlpha = remember { Animatable(0f) }
    val overlayAlpha = remember { Animatable(1f) }

    LaunchedEffect(Unit) {
        launch { delay(150); ballScale.animateTo(1f, tween(850, easing = FastOutSlowInEasing)) }
        launch {
            delay(1000)
            launch { ballDrop.animateTo(1f, tween(320, easing = LinearEasing)) }
            ballAlpha.animateTo(0f, tween(320))
        }
        launch {
            delay(1050)
            holePulse.animateTo(1.22f, tween(180))
            Haptics.medium()
            holePulse.animateTo(1f, spring(dampingRatio = 0.6f, stiffness = Spring.StiffnessMedium))
        }
        launch { delay(1180); ripple.animateTo(1f, tween(850)) }
        launch {
            delay(1450)
            launch { titleAlpha.animateTo(1f, tween(400)) }
            titleY.animateTo(0f, spring(dampingRatio = 0.72f, stiffness = Spring.StiffnessLow))
        }
        launch { delay(1750); subtitleAlpha.animateTo(1f, tween(350)) }
        delay(3300)
        overlayAlpha.animateTo(0f, tween(550))
        onComplete()
    }

    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(usePlatformDefaultWidth = false, dismissOnBackPress = false, dismissOnClickOutside = false, decorFitsSystemWindows = false),
    ) {
        Box(Modifier.fillMaxSize().alpha(overlayAlpha.value).background(bg), contentAlignment = Alignment.Center) {
            // Mähstreifen
            Canvas(Modifier.fillMaxSize().alpha(0.35f)) {
                val stripe = 46.dp.toPx()
                var x = 0f
                var i = 0
                while (x < size.width) {
                    if (i % 2 == 0) drawRect(mid, Offset(x, 0f), Size(stripe, size.height))
                    x += stripe; i++
                }
            }
            Box(Modifier.size(440.dp).background(Brush.radialGradient(listOf(mid.copy(alpha = 0.9f), mid.copy(alpha = 0f)))))
            // Ripples
            if (ripple.value > 0f) {
                for (k in 0 until 3) {
                    val p = (ripple.value - k * 0.15f).coerceIn(0f, 1f)
                    Canvas(Modifier.size(48.dp)) {
                        drawCircle(Color.White.copy(alpha = (1f - p) * 0.5f), radius = size.minDimension / 2 * (1f + p * 2.5f), style = androidx.compose.ui.graphics.drawscope.Stroke(2.dp.toPx()))
                    }
                }
            }
            // Loch
            Box(Modifier.scale(holePulse.value), contentAlignment = Alignment.Center) {
                Box(Modifier.size(62.dp).blur(5.dp).background(Color.Black.copy(alpha = 0.5f), CircleShape))
                Box(Modifier.size(48.dp).background(Color.Black.copy(alpha = 0.92f), CircleShape))
            }
            // Ball
            Box(
                Modifier.offset(y = (-ballDrop.value * 4).dp).scale(ballScale.value * (1f - ballDrop.value * 0.55f)).alpha(ballAlpha.value)
                    .size(34.dp).background(Brush.radialGradient(listOf(Color.White, Color(0xFFD9D9D9)), center = Offset(30f, 30f)), CircleShape),
            )
            Column(
                Modifier.align(Alignment.Center).offset(y = 120.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    "GolfTrack", color = Color.White, fontSize = 40.sp, fontWeight = FontWeight.Bold,
                    modifier = Modifier.alpha(titleAlpha.value).offset(y = titleY.value.dp),
                )
                Spacer(Modifier.height(6.dp))
                Text(
                    "Dein persönlicher Golfbegleiter", color = AppTheme.gold, fontSize = 15.sp,
                    modifier = Modifier.alpha(subtitleAlpha.value),
                )
            }
        }
    }
}
