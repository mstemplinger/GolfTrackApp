package app.golftrack.feature.ads

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.GoldButton
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

/**
 * Zwischenseite einer Anzeige – Gegenstück zu golftrack.app/werbung/<id>:
 * Inhalt der Anzeige, Weg zur Website des Werbenden und warum sie hier steht.
 */
@Composable
fun AdDetailScreen(nav: NavController, adId: String) {
    val ctx = LocalContext.current
    remember { AdCatalog.init(ctx.applicationContext) }
    LaunchedEffect(Unit) { AdCatalog.refreshIfNeeded() }
    val ads by AdCatalog.ads.collectAsState()
    val ad = ads.firstOrNull { it.id == adId }

    fun open(url: String) {
        runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
    }

    AppScaffold("Anzeige", onBack = { nav.popBackStack() }) { m ->
        Column(
            m.verticalScroll(rememberScrollState()).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            if (ad == null) {
                Text("Diese Anzeige ist nicht mehr verfügbar.", color = AppTheme.textSec)
                return@Column
            }
            Column(
                Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                if (ad.imageURL.isNotEmpty()) {
                    RemoteImage(
                        ad.imageURL,
                        Modifier.fillMaxWidth().aspectRatio(16f / 9f).clip(RoundedCornerShape(12.dp)),
                    ) {
                        Box(
                            Modifier.fillMaxWidth().aspectRatio(16f / 9f).background(AppTheme.cardAlt, RoundedCornerShape(12.dp)),
                            contentAlignment = Alignment.Center,
                        ) { Icon(Icons.Filled.Campaign, null, tint = AppTheme.gold, modifier = Modifier.size(36.dp)) }
                    }
                }
                Text("ANZEIGE", color = AppTheme.textTer, fontSize = 10.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 1.sp)
                Text(ad.title, color = AppTheme.text, fontSize = 20.sp, fontWeight = FontWeight.Bold)
                if (ad.subtitle.isNotEmpty()) Text(ad.subtitle, color = AppTheme.textSec, fontSize = 15.sp)
                if (ad.advertiser.isNotEmpty()) Text(ad.advertiser, color = AppTheme.gold, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
            }
            if (ad.linkURL.isNotEmpty()) {
                GoldButton("Zur Website") { open(ad.linkURL) }
            }
            Row(
                Modifier.fillMaxWidth().background(AppTheme.cardDark, RoundedCornerShape(14.dp)).padding(14.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(Icons.Filled.Info, null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
                Column {
                    Text("Warum sehe ich das?", color = AppTheme.text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(Modifier.height(4.dp))
                    Text(
                        when {
                            ad.courseID.isNotEmpty() -> "Die Anzeige ist für diese Anlage gebucht."
                            ad.radiusKm != null -> "Die Anzeige gilt für die Region um ${ad.radiusKm} km rund um ihren Standort – deine Anlage liegt darin oder ist die nächstgelegene."
                            else -> "Die Anzeige erscheint auf allen Anlagen."
                        } + " GolfTrack schickt dafür keine Gerätekennung und keinen Standort an den Server – gezählt wird nur, wie oft die Anzeige zu sehen war und angetippt wurde.",
                        color = AppTheme.textSec, fontSize = 13.sp,
                    )
                    TextButton(onClick = { Haptics.tap(); open(ad.landingURL) }, contentPadding = androidx.compose.foundation.layout.PaddingValues(0.dp)) {
                        Text("Mehr auf golftrack.app", color = AppTheme.gold, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
    }
}
