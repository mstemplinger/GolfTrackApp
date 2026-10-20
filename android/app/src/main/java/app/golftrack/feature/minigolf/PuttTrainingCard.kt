package app.golftrack.feature.minigolf

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LaterBadge
import app.golftrack.ui.common.LaterFeature
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme

/**
 * Die Putt-Lektionen aus dem Training. Auf iOS Teil des Trainings-Abos – in
 * der ersten Android-Version nur als Einstieg mit „Später"-Abzeichen.
 */
@Composable
internal fun PuttTrainingCard(nav: NavController, compact: Boolean = false) {
    val open = { Haptics.tap(); nav.navigate(Routes.comingLater(LaterFeature.AUDIOBOOKS)) }
    val icon = @Composable {
        Box(
            Modifier.size(44.dp).background(AppTheme.gold.copy(alpha = 0.16f), RoundedCornerShape(10.dp)),
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Filled.Headphones, null, tint = AppTheme.gold) }
    }
    if (compact) {
        Row(
            Modifier.fillMaxWidth()
                .background(AppTheme.cardDark, RoundedCornerShape(14.dp))
                .border(1.dp, AppTheme.gold.copy(alpha = 0.22f), RoundedCornerShape(14.dp))
                .clickable { open() }
                .padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            icon()
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    MgText("Putt-Training", MgFont.subheadline, weight = FontWeight.SemiBold)
                    LaterBadge()
                }
                MgText("Audios zum Putten – zwischen zwei Bahnen anhören", MgFont.caption, AppTheme.textSec, maxLines = 2)
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer)
        }
    } else {
        Row(
            Modifier.fillMaxWidth()
                .background(AppTheme.card, RoundedCornerShape(16.dp))
                .border(1.dp, AppTheme.gold.copy(alpha = 0.22f), RoundedCornerShape(16.dp))
                .clickable { open() }
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            icon()
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                    MgText("Putt-Training", MgFont.headline, weight = FontWeight.SemiBold)
                    LaterBadge()
                }
                MgText("Distanzkontrolle und Grün lesen – die Putt-Lektionen aus dem Training.", MgFont.caption, AppTheme.textSec)
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = AppTheme.textTer)
        }
    }
}
