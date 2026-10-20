package app.golftrack.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material3.Icon
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.R
import app.golftrack.data.AppFocus
import app.golftrack.data.Prefs
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

private data class FocusInfo(val title: String, val subtitle: String, val icon: ImageVector, val highlights: List<String>)

private fun info(f: AppFocus) = when (f) {
    AppFocus.GOLF -> FocusInfo(
        "Golf", "Runden auf dem Platz, Handicap & Schlagverfolgung", Icons.Filled.SportsGolf,
        listOf(
            "WHS-Handicap wird automatisch berechnet",
            "Schläge, Distanzen und Laufwege auf der Karte",
            "Spielformen, Regeln und Platzreife-Training",
        ),
    )
    AppFocus.MINIGOLF -> FocusInfo(
        "Minigolf", "Schnelle Spiele mit Freunden, Schlag für Schlag gezählt", Icons.Filled.EmojiEvents,
        listOf(
            "In Sekunden startklar – kein Tutorial nötig",
            "Bis zu 8 Spieler auf einer Scorekarte",
            "Golf-Funktionen bleiben jederzeit verfügbar",
        ),
    )
}

/**
 * Allererster Screen beim App-Start: Golf oder Minigolf? (AppFocusSelectionView.swift)
 * Läuft vor dem Tutorial; bei Minigolf wird das Tutorial übersprungen.
 */
@Composable
fun AppFocusSelection(onChosen: (AppFocus) -> Unit) {
    var selection by remember { mutableStateOf<AppFocus?>(null) }
    var appear by remember { mutableStateOf(false) }
    val alpha by animateFloatAsState(if (appear) 1f else 0f, tween(350), label = "appear")
    LaunchedEffect(Unit) { appear = true }

    Box(
        Modifier.fillMaxSize()
            .background(Brush.verticalGradient(listOf(Color(0xFF091A10), AppTheme.bg)))
            // Klicks nicht an die App darunter durchreichen.
            .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) {}
            .alpha(alpha),
    ) {
        Column(
            Modifier.fillMaxSize().safeDrawingPadding().verticalScroll(rememberScrollState()).padding(top = 36.dp, bottom = 30.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Image(
                painterResource(R.mipmap.ic_launcher), null,
                modifier = Modifier.size(68.dp).shadow(14.dp, RoundedCornerShape(16.dp)).clip(RoundedCornerShape(16.dp)),
                contentScale = ContentScale.Crop,
            )
            Spacer(Modifier.height(14.dp))
            Text("Willkommen bei GolfTrack", color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            Spacer(Modifier.height(8.dp))
            Text(
                "Was möchtest du hauptsächlich tracken?", color = AppTheme.textSec, fontSize = 15.sp,
                textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 28.dp),
            )
            Column(Modifier.padding(horizontal = 22.dp).padding(top = 28.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                AppFocus.entries.forEach { f ->
                    FocusCard(f, selection == f) { Haptics.selection(); selection = f }
                }
            }
            val enabled = selection != null
            Row(
                Modifier.padding(horizontal = 22.dp).padding(top = 26.dp).fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(if (enabled) AppTheme.gold else AppTheme.gold.copy(alpha = 0.35f))
                    .clickable(enabled = enabled) {
                        val choice = selection ?: return@clickable
                        Haptics.success()
                        // Minigolf-Spieler bekommen kein Tutorial – es erklärt nur Golf-Features.
                        if (choice == AppFocus.MINIGOLF) Prefs.set("hasSeenOnboarding", true)
                        onChosen(choice)
                    }
                    .padding(vertical = 16.dp),
                horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(if (selection == AppFocus.MINIGOLF) "Los geht's" else "Weiter", color = AppTheme.onGold, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.width(7.dp))
                Icon(Icons.AutoMirrored.Filled.ArrowForward, null, tint = AppTheme.onGold, modifier = Modifier.size(16.dp))
            }
            Text(
                "Du kannst das später jederzeit im Profil ändern.", color = AppTheme.textTer, fontSize = 12.sp,
                textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 32.dp).padding(top = 14.dp),
            )
        }
    }
}

@Composable
private fun FocusCard(focus: AppFocus, selected: Boolean, onClick: () -> Unit) {
    val i = info(focus)
    Column(
        Modifier.fillMaxWidth()
            .shadow(if (selected) 18.dp else 10.dp, RoundedCornerShape(20.dp))
            .clip(RoundedCornerShape(20.dp))
            .background(AppTheme.card)
            .border(if (selected) 2.dp else 1.dp, if (selected) AppTheme.gold else Color.White.copy(alpha = 0.08f), RoundedCornerShape(20.dp))
            .clickable { onClick() }
            .padding(18.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(52.dp).background(if (selected) AppTheme.gold.copy(alpha = 0.22f) else AppTheme.cardAlt, CircleShape),
                contentAlignment = Alignment.Center,
            ) { Icon(i.icon, null, tint = if (selected) AppTheme.gold else AppTheme.textSec, modifier = Modifier.size(24.dp)) }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(i.title, color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                Text(i.subtitle, color = AppTheme.textSec, fontSize = 12.sp)
            }
            Spacer(Modifier.width(4.dp))
            Box(
                Modifier.size(24.dp)
                    .background(if (selected) AppTheme.gold else Color.Transparent, CircleShape)
                    .border(if (selected) 0.dp else 1.5.dp, if (selected) Color.Transparent else Color.White.copy(alpha = 0.22f), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                if (selected) Icon(Icons.Filled.Check, null, tint = Color(0xFF0F2414), modifier = Modifier.size(14.dp))
            }
        }
        AnimatedVisibility(selected, enter = fadeIn() + expandVertically(), exit = fadeOut() + shrinkVertically()) {
            Column(Modifier.padding(top = 14.dp), verticalArrangement = Arrangement.spacedBy(7.dp)) {
                i.highlights.forEach { line ->
                    Row {
                        Icon(Icons.Filled.CheckCircle, null, tint = AppTheme.gold, modifier = Modifier.padding(top = 2.dp).size(13.dp))
                        Spacer(Modifier.width(8.dp))
                        Text(line, color = AppTheme.textSec, fontSize = 13.sp)
                    }
                }
            }
        }
    }
}
