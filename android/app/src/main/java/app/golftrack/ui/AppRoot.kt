package app.golftrack.ui

import android.net.Uri
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import app.golftrack.data.AppFocus
import app.golftrack.data.GolfStore
import app.golftrack.data.Prefs
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.data.rememberPrefBool
import app.golftrack.data.rememberPrefString
import app.golftrack.feature.golf.golfRoutes
import app.golftrack.feature.records.recordsRoutes
import app.golftrack.feature.guide.RulesTab
import app.golftrack.feature.guide.TipsTab
import app.golftrack.feature.guide.guideRoutes
import app.golftrack.feature.home.HomeScreen
import app.golftrack.feature.home.homeRoutes
import app.golftrack.feature.minigolf.MinigolfTab
import app.golftrack.feature.minigolf.minigolfRoutes
import app.golftrack.feature.profile.ProfileTab
import app.golftrack.feature.profile.profileRoutes
import app.golftrack.ui.common.ComingLaterContent
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.common.LaterFeature
import app.golftrack.ui.common.Routes
import app.golftrack.ui.theme.AppTheme

/** Wie ContentView.swift: fünf Tabs, darüber die bildschirmfüllenden Unterseiten. */
@Composable
fun AppRoot(pendingLink: Uri?, onLinkHandled: () -> Unit) {
    val nav = rememberNavController()
    var hasChosenFocus by rememberPrefBool("hasChosenAppFocus")
    var deepLinkLoading by remember { mutableStateOf(false) }
    var deepLinkError by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) { CourseCatalog.refreshIfNeeded() }

    LaunchedEffect(pendingLink) {
        val uri = pendingLink ?: return@LaunchedEffect
        onLinkHandled()
        val link = DeepLinks.parse(uri)
        if (link == null) {
            DeepLinks.handleScheme(uri, nav)
            return@LaunchedEffect
        }
        if (DeepLinks.open(link, nav)) return@LaunchedEffect
        deepLinkLoading = true
        CourseCatalog.refresh()
        deepLinkLoading = false
        if (DeepLinks.open(link, nav)) return@LaunchedEffect
        Haptics.error()
        deepLinkError = if (CourseCatalog.lastError != null)
            "Das Platzverzeichnis ließ sich nicht laden. Prüf die Internetverbindung und scanne den Code noch einmal."
        else
            "Diese Anlage steht noch nicht im Verzeichnis. Wurde sie gerade erst freigegeben, versuch es in ein paar Minuten noch einmal."
    }

    Box(Modifier.fillMaxSize()) {
        NavHost(nav, startDestination = Routes.MAIN) {
            composable(Routes.MAIN) { MainTabs(nav) }
            composable(Routes.COMING_LATER) { entry ->
                val f = runCatching { LaterFeature.valueOf(entry.arguments?.getString("feature") ?: "") }
                    .getOrDefault(LaterFeature.AUDIOBOOKS)
                AppScaffold(f.title, onBack = { nav.popBackStack() }) { m -> ComingLaterContent(f, m) }
            }
            homeRoutes(nav)
            golfRoutes(nav)
            recordsRoutes(nav)
            minigolfRoutes(nav)
            guideRoutes(nav)
            profileRoutes(nav)
        }

        if (!hasChosenFocus) {
            AppFocusSelection(onChosen = { focus ->
                Prefs.appFocus = focus
                hasChosenFocus = true
            })
        }

        if (deepLinkLoading) {
            AlertDialog(
                onDismissRequest = {},
                confirmButton = {},
                title = { Text("Anlage wird gesucht …") },
                text = { Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator(color = AppTheme.gold) } },
            )
        }
        deepLinkError?.let { msg ->
            AlertDialog(
                onDismissRequest = { deepLinkError = null },
                confirmButton = { TextButton(onClick = { Haptics.tap(); deepLinkError = null }) { Text("OK") } },
                title = { Text("Anlage nicht gefunden") },
                text = { Text(msg) },
                containerColor = AppTheme.card,
            )
        }
    }
}

private data class Tab(val title: String, val icon: ImageVector)

@Composable
private fun MainTabs(nav: NavController) {
    var selected by rememberSaveable { mutableStateOf(0) }
    val focus by rememberPrefString("appFocus", AppFocus.GOLF.raw)
    val minigolfFocus = focus == AppFocus.MINIGOLF.raw

    // Golfregeln-Tab wird bei Minigolf-Schwerpunkt zum Minigolf-Tab (wie iOS).
    val tabs = listOf(
        Tab("Home", Icons.Filled.Home),
        Tab("Training", Icons.Filled.SportsGolf),
        if (minigolfFocus) Tab("Minigolf", Icons.Filled.EmojiEvents) else Tab("Regeln", Icons.AutoMirrored.Filled.MenuBook),
        Tab("Tipps", Icons.Filled.Lightbulb),
        Tab("Profil", Icons.Filled.Person),
    )

    Scaffold(
        containerColor = AppTheme.bg,
        bottomBar = {
            NavigationBar(containerColor = AppTheme.tabBg) {
                tabs.forEachIndexed { i, t ->
                    NavigationBarItem(
                        selected = selected == i,
                        onClick = { if (selected != i) Haptics.selection(); selected = i },
                        icon = { Icon(t.icon, contentDescription = null) },
                        label = { Text(t.title) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = AppTheme.gold,
                            selectedTextColor = AppTheme.gold,
                            unselectedIconColor = AppTheme.text.copy(alpha = 0.45f),
                            unselectedTextColor = AppTheme.text.copy(alpha = 0.45f),
                            indicatorColor = AppTheme.card,
                        ),
                    )
                }
            }
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding).consumeWindowInsets(padding)) {
            when (selected) {
                0 -> HomeScreen(nav)
                1 -> ComingLaterContent(LaterFeature.AUDIOBOOKS)
                2 -> if (minigolfFocus) MinigolfTab(nav) else RulesTab(nav)
                3 -> TipsTab(nav)
                else -> ProfileTab(nav)
            }
        }
    }
}
