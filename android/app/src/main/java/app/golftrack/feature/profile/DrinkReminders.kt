package app.golftrack.feature.profile

import android.content.Context
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import app.golftrack.data.Prefs
import app.golftrack.feature.golf.ReminderWorker
import java.util.concurrent.TimeUnit

/**
 * Trinkerinnerung während der Runde wie in NotificationManager.swift – als
 * Serie einzelner WorkManager-Aufträge (ohne Play-Dienste). Einstellungen unter
 * den iOS-Schlüsseln `notif.drink.enabled` (fehlend = an) und `notif.drink.minutes`.
 */
object DrinkReminders {
    const val ENABLED_KEY = "notif.drink.enabled"
    const val MINUTES_KEY = "notif.drink.minutes"
    private const val PREFIX = "de.golftrack.drink."
    private const val TAG = "de.golftrack.drink"
    /** Beginn der laufenden Serie (ms als Text) – ersetzt die Abfrage offener Mitteilungen. */
    private const val STARTED_KEY = "notif.drink.seriesStart"
    /** Runde, für die die Serie zuletzt gestartet wurde. */
    private const val ROUND_KEY = "notif.drink.roundId"

    /** Länger als jede Runde – so hört die Serie auch dann auf, wenn eine Runde nie abgeschlossen wird. */
    private const val SERIES_MS = 6 * 60 * 60 * 1000L

    private fun enabled(): Boolean = !Prefs.sp.contains(ENABLED_KEY) || Prefs.bool(ENABLED_KEY, true)

    private fun minutes(): Int = Prefs.int(MINUTES_KEY, 0).takeIf { it > 0 } ?: 30

    private fun isRunning(): Boolean {
        val start = Prefs.string(STARTED_KEY).toLongOrNull() ?: return false
        return System.currentTimeMillis() < start + SERIES_MS
    }

    /**
     * Plant ab jetzt alle X Minuten eine Trinkerinnerung. Läuft schon eine
     * Serie, bleibt sie stehen – wer die Runde kurz verlässt und zurückkehrt,
     * setzt den Takt nicht zurück.
     */
    fun start(ctx: Context) {
        if (!enabled() || isRunning()) return
        scheduleSeries(ctx.applicationContext)
    }

    /** Nach einer Änderung des Abstands: eine laufende Serie mit dem neuen Takt neu aufsetzen. */
    fun rescheduleIfRunning(ctx: Context) {
        if (!isRunning()) return
        cancel(ctx)
        if (enabled()) scheduleSeries(ctx.applicationContext)
    }

    fun cancel(ctx: Context) {
        Prefs.remove(STARTED_KEY)
        runCatching { WorkManager.getInstance(ctx.applicationContext).cancelAllWorkByTag(TAG) }
    }

    /**
     * Startet die Serie, sobald eine neue offene Runde auftaucht, und beendet
     * sie, wenn keine Runde mehr offen ist (Abschluss oder Löschen). Alte,
     * liegengebliebene Runden (`roundDate` älter als die Serie) starten nichts.
     */
    fun onOpenRoundChanged(ctx: Context, openRoundId: String?, roundDate: Long?) {
        if (openRoundId == null) {
            if (Prefs.string(ROUND_KEY).isNotEmpty()) {
                Prefs.remove(ROUND_KEY)
                cancel(ctx)
            }
            return
        }
        if (Prefs.string(ROUND_KEY) == openRoundId) return
        Prefs.set(ROUND_KEY, openRoundId)
        if (roundDate != null && System.currentTimeMillis() - roundDate < SERIES_MS) start(ctx)
    }

    private fun scheduleSeries(ctx: Context) {
        val intervalMs = minutes() * 60_000L
        val count = maxOf(1, (SERIES_MS / intervalMs).toInt())
        val wm = runCatching { WorkManager.getInstance(ctx) }.getOrNull() ?: return
        for (i in 1..count) {
            val req = OneTimeWorkRequestBuilder<ReminderWorker>()
                .setInitialDelay(intervalMs * i, TimeUnit.MILLISECONDS)
                .addTag(TAG)
                .setInputData(
                    workDataOf(
                        // Dieselbe Mitteilungs-ID: eine neue ersetzt die vorige statt sich zu stapeln.
                        "id" to TAG,
                        "title" to "Zeit für einen Schluck 💧",
                        "body" to "Trink etwas Wasser – so bleibst du bis zum letzten Loch konzentriert.",
                    ),
                )
                .build()
            wm.enqueueUniqueWork("$PREFIX$i", ExistingWorkPolicy.REPLACE, req)
        }
        Prefs.set(STARTED_KEY, System.currentTimeMillis().toString())
    }
}
