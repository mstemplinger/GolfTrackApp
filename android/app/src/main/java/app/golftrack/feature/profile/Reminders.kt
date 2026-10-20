package app.golftrack.feature.profile

import android.content.Context
import app.golftrack.feature.golf.RoundReminders

/**
 * Brücke zu den Erinnerungen (WorkManager, `feature/golf/RoundReminders`).
 * Die Einstellungen selbst liegen unter den iOS-Schlüsseln `notif.*`.
 */
object Reminders {
    /** Beim Start: Inaktivitäts-Erinnerung neu ab heute planen. */
    fun onAppStart(ctx: Context) = runCatching { RoundReminders.scheduleInactivity(ctx.applicationContext) }

    fun rescheduleInactivity(ctx: Context, days: Int) = runCatching { RoundReminders.scheduleInactivity(ctx.applicationContext, days) }

    fun cancelOpenRound(ctx: Context) = runCatching { RoundReminders.cancelOpenRound(ctx.applicationContext) }

    fun canPost(ctx: Context): Boolean = RoundReminders.canPost(ctx)
}
