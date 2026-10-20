package app.golftrack

import android.app.Application
import app.golftrack.data.GolfStore
import app.golftrack.data.Prefs
import app.golftrack.data.catalog.CourseCatalog
import app.golftrack.ui.common.Haptics

class GolfTrackApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Prefs.init(this)
        GolfStore.init(this)
        CourseCatalog.init(this)
        Haptics.init(this)
    }
}
