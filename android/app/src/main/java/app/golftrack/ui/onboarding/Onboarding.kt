package app.golftrack.ui.onboarding

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
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
    /** Standort wurde schon im Onboarding erfragt – die Startseite fragt dann nicht gleich noch einmal. */
    const val LOCATION_ASKED = "onboarding.locationAsked"
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
 * eingeschaltet), Update-Einführung und die Einführung (GolfOnboarding).
 * Steht auf der Startseite; „Tutorial neu starten" im Profil springt zurück
 * auf die Startseite (siehe AppRoot).
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
        GolfOnboarding(onFinish = { hasSeenOnboarding = true })
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
