package app.golftrack.feature.ads

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Headphones
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.LatLon
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LaterFeature
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme

/**
 * Die Werbefläche in der Zählkarte – bei Minigolf wie bei Golf (wie `AdSlotView` auf iOS).
 *
 * 1. Gibt es eine gebuchte Anzeige für diesen Platz, seinen Umkreis, den
 *    nächstgelegenen Umkreis oder allgemein, steht sie hier – als „Anzeige"
 *    gekennzeichnet. Ein Tipp öffnet die Zwischenseite (`Routes.adDetail`, ohne
 *    `nav` die Seite golftrack.app/werbung/<id> im Browser).
 * 2. Sonst bewirbt sich die App selbst (ohne Werbefrei-Kauf auf Android).
 *
 * Die Anzeige wechselt mit `rotation` – in der Zählkarte die Lochnummer.
 *
 * @param courseId Kennung der Anlage (Slug), null bei einer Runde ohne Verzeichnisplatz.
 * @param coordinate Lage des Platzes für Umkreis-Werbung; ohne Angabe wird im Katalog nachgeschlagen.
 */
@Composable
fun AdSlot(
    placement: AdPlacement,
    courseId: String?,
    rotation: Int,
    modifier: Modifier = Modifier,
    coordinate: LatLon? = null,
    nav: NavController? = null,
) {
    val ctx = LocalContext.current
    remember { AdCatalog.init(ctx.applicationContext) }
    LaunchedEffect(Unit) { AdCatalog.refreshIfNeeded() }
    val ads by AdCatalog.ads.collectAsState()
    val minigolf by CourseCatalog.minigolfCourses.collectAsState()
    val golf by CourseCatalog.golfCourses.collectAsState()

    val effective = coordinate ?: courseId?.let { id ->
        minigolf.firstOrNull { it.id == id }?.let { LatLon(it.lat, it.lon) }
            ?: golf.firstOrNull { it.slug == id }?.let { LatLon(it.lat, it.lon) }
    }
    val booked = remember(ads, courseId, effective, rotation) {
        AdCatalog.ad(placement, courseId, effective, rotation)
    }

    fun openUrl(url: String) {
        runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url))) }
    }

    if (booked != null) {
        LaunchedEffect(booked.id, rotation) { AdCatalog.countImpression(booked) }
        var menu by remember { mutableStateOf(false) }
        Box(modifier) {
            SlotContent(
                badge = "Anzeige",
                title = booked.title,
                // Ohne zweite Zeile rückt der Auftraggeber nach.
                subtitle = booked.subtitle.ifEmpty { booked.advertiser },
                imageUrl = booked.imageURL.ifEmpty { null },
                icon = Icons.Filled.Campaign,
                onClick = {
                    Haptics.tap()
                    AdCatalog.countClick(booked)
                    if (nav != null) nav.navigate(Routes.adDetail(booked.id)) else openUrl(booked.landingURL)
                },
                onLongClick = { Haptics.medium(); menu = true },
            )
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }, containerColor = AppTheme.cardAlt) {
                DropdownMenuItem(
                    text = { Text("Warum sehe ich das?", color = AppTheme.text) },
                    leadingIcon = { Icon(Icons.AutoMirrored.Filled.HelpOutline, null, tint = AppTheme.gold) },
                    onClick = { menu = false; openUrl(booked.landingURL) },
                )
            }
        }
    } else {
        val promos = HousePromo.available(hasNav = nav != null)
        if (promos.isEmpty()) return
        val promo = promos[Math.floorMod(rotation, promos.size)]
        SlotContent(
            badge = "GolfTrack",
            title = promo.title,
            subtitle = promo.subtitle,
            imageUrl = null,
            icon = promo.icon,
            onClick = {
                Haptics.tap()
                when (promo) {
                    HousePromo.TRAINING -> nav?.navigate(Routes.comingLater(LaterFeature.AUDIOBOOKS))
                    HousePromo.CADDY -> nav?.navigate(Routes.comingLater(LaterFeature.CADDY))
                    HousePromo.ADVERTISE -> openUrl("https://golftrack.app/werbung")
                }
            },
            modifier = modifier,
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun SlotContent(
    badge: String,
    title: String,
    subtitle: String,
    imageUrl: String?,
    icon: ImageVector,
    onClick: () -> Unit,
    onLongClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier.fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(AppTheme.card)
            .combinedClickable(onClick = onClick, onLongClick = onLongClick),
    ) {
        Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(44.dp).clip(RoundedCornerShape(10.dp))) {
                val tile: @Composable () -> Unit = {
                    Box(Modifier.fillMaxSize().background(AppTheme.cardAlt), contentAlignment = Alignment.Center) {
                        Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(20.dp))
                    }
                }
                if (imageUrl != null) RemoteImage(imageUrl, Modifier.fillMaxSize(), placeholder = tile) else tile()
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                Text(subtitle, color = AppTheme.textSec, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            Icon(Icons.Filled.ChevronRight, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp))
        }
        Text(
            badge.uppercase(),
            color = AppTheme.textTer, fontSize = 8.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 0.6.sp,
            modifier = Modifier.align(Alignment.TopEnd).padding(horizontal = 8.dp, vertical = 4.dp),
        )
    }
}

/** Eigenwerbung, solange der Platz nicht verkauft ist. Training und Caddy zeigen auf „kommt später". */
private enum class HousePromo(val title: String, val subtitle: String, val icon: ImageVector) {
    TRAINING("Besser putten lernen", "Audio-Trainings für Technik und Kopf", Icons.Filled.Headphones),
    CADDY("Caddy fragen", "Der Assistent für Schlagwahl und Taktik", Icons.Filled.GraphicEq),
    ADVERTISE("Hier könnte Ihre Anlage stehen", "Werbeplatz für Betreiber – golftrack.app", Icons.Filled.Campaign);

    companion object {
        /** Ohne Navigation lassen sich nur Links öffnen. */
        fun available(hasNav: Boolean): List<HousePromo> =
            if (hasNav) entries.toList() else listOf(ADVERTISE)
    }
}
