package app.golftrack

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.mutableStateOf
import android.net.Uri
import app.golftrack.ui.AppRoot
import app.golftrack.ui.theme.AppTheme
import app.golftrack.ui.theme.GolfTrackTheme
import androidx.compose.ui.graphics.toArgb

class MainActivity : ComponentActivity() {

    /** Zuletzt eingetroffener Link (QR-Code, golftrack://…) – AppRoot verarbeitet und leert ihn. */
    private val pendingLink = mutableStateOf<Uri?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.dark(AppTheme.bg.toArgb()),
            navigationBarStyle = SystemBarStyle.dark(AppTheme.cardDark.toArgb()),
        )
        pendingLink.value = intent?.data
        setContent {
            GolfTrackTheme {
                AppRoot(pendingLink = pendingLink.value, onLinkHandled = { pendingLink.value = null })
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.data?.let { pendingLink.value = it }
    }
}
