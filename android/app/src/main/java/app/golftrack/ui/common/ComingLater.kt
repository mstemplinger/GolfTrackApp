package app.golftrack.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material.icons.filled.RecordVoiceOver
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.ui.theme.AppTheme

/** Hinweis „kommt in einer späteren Version" – als Tab-Inhalt oder eigener Screen. */
@Composable
fun ComingLaterContent(feature: LaterFeature, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().background(AppTheme.bg).padding(24.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(
                Modifier.size(88.dp).background(AppTheme.card, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    if (feature == LaterFeature.CADDY) Icons.Filled.RecordVoiceOver else Icons.Filled.Headphones,
                    contentDescription = null, tint = AppTheme.gold, modifier = Modifier.size(42.dp),
                )
            }
            Spacer(Modifier.height(4.dp))
            Text(feature.title, color = AppTheme.text, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Text(
                "Kommt in einer späteren Version",
                color = AppTheme.onGold, fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                modifier = Modifier.background(AppTheme.gold, RoundedCornerShape(50)).padding(horizontal = 12.dp, vertical = 5.dp),
            )
            Text(
                feature.text,
                color = AppTheme.textSec, fontSize = 15.sp, textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp),
            )
        }
    }
}

/** Kleines Abzeichen für Listeneinträge/Karten, die auf ein späteres Feature zeigen. */
@Composable
fun LaterBadge(modifier: Modifier = Modifier) {
    Text(
        "Später",
        color = AppTheme.onGold, fontSize = 11.sp, fontWeight = FontWeight.SemiBold,
        modifier = modifier.background(AppTheme.gold, RoundedCornerShape(50)).padding(horizontal = 8.dp, vertical = 2.dp),
    )
}
