package app.golftrack.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.golftrack.ui.theme.AppTheme

/** Standard-Gerüst für Unterseiten: dunkle Leiste mit Zurück-Pfeil, Titel weiß, Akzent gold. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppScaffold(
    title: String,
    onBack: (() -> Unit)?,
    actions: @Composable RowScope.() -> Unit = {},
    content: @Composable (Modifier) -> Unit,
) {
    Scaffold(
        containerColor = AppTheme.bg,
        topBar = {
            TopAppBar(
                title = { Text(title, fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    if (onBack != null) {
                        IconButton(onClick = { Haptics.tap(); onBack() }) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Zurück", tint = AppTheme.gold)
                        }
                    }
                },
                actions = actions,
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = AppTheme.bg,
                    titleContentColor = AppTheme.text,
                    actionIconContentColor = AppTheme.gold,
                ),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) { content(Modifier.fillMaxSize()) }
    }
}

/** Karte im App-Stil (AppTheme.card, Radius 16). */
@Composable
fun Card(modifier: Modifier = Modifier, onClick: (() -> Unit)? = null, content: @Composable ColumnScope.() -> Unit) {
    var m = modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))
    if (onClick != null) m = m.clickable { Haptics.tap(); onClick() }
    Column(m.padding(16.dp), content = content)
}

/** Gold-Knopf wie `.goldButton()` auf iOS. */
@Composable
fun GoldButton(text: String, modifier: Modifier = Modifier, enabled: Boolean = true, onClick: () -> Unit) {
    Box(
        modifier.fillMaxWidth()
            .background(if (enabled) AppTheme.gold else AppTheme.gold.copy(alpha = 0.4f), RoundedCornerShape(14.dp))
            .clickable(enabled = enabled) { Haptics.tap(); onClick() }
            .padding(vertical = 16.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(text, color = AppTheme.onGold, fontWeight = FontWeight.SemiBold)
    }
}

/** Nur für Stubs während des Aufbaus. */
@Composable
fun Placeholder(title: String) {
    Box(Modifier.fillMaxSize().background(AppTheme.bg), contentAlignment = Alignment.Center) {
        Text(title, color = AppTheme.textSec)
    }
}
