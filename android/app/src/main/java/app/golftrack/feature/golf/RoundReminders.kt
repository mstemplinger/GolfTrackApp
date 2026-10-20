package app.golftrack.feature.golf

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import app.golftrack.R
import app.golftrack.data.Prefs
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * Runden-Benachrichtigungen wie im NotificationManager.swift – über WorkManager
 * statt UNUserNotificationCenter. Schlüssel der Einstellungen wie auf iOS
 * ("notif.openRound.enabled", "notif.roundInactivity.enabled", …; fehlend = an).
 */
object RoundReminders {
    private const val ID_INACTIVITY = "de.golftrack.inactivity"
    private const val ID_OPEN_ROUND = "de.golftrack.openRound"
    private const val ID_ROUND_INACTIVITY = "de.golftrack.roundInactivity"
    private const val CHANNEL = "reminders"

    private fun enabled(key: String): Boolean = !Prefs.sp.contains(key) || Prefs.bool(key, true)

    private fun schedule(ctx: Context, id: String, delayMs: Long, title: String, body: String) {
        val req = OneTimeWorkRequestBuilder<ReminderWorker>()
            .setInitialDelay(maxOf(0L, delayMs), TimeUnit.MILLISECONDS)
            .setInputData(workDataOf("id" to id, "title" to title, "body" to body))
            .build()
        WorkManager.getInstance(ctx).enqueueUniqueWork(id, ExistingWorkPolicy.REPLACE, req)
    }

    private fun cancel(ctx: Context, id: String) {
        WorkManager.getInstance(ctx).cancelUniqueWork(id)
        NotificationManagerCompat.from(ctx).cancel(id.hashCode())
    }

    /** Zeitpunkt „in `days` Tagen um `hour` Uhr". */
    private fun delayUntil(days: Int, hour: Int): Long {
        val c = Calendar.getInstance()
        c.add(Calendar.DAY_OF_YEAR, days)
        c.set(Calendar.HOUR_OF_DAY, hour); c.set(Calendar.MINUTE, 0); c.set(Calendar.SECOND, 0); c.set(Calendar.MILLISECOND, 0)
        return c.timeInMillis - System.currentTimeMillis()
    }

    /** Offene Runde: Erinnerung am nächsten Morgen um 8 Uhr. */
    fun scheduleOpenRound(ctx: Context, courseName: String) {
        if (!enabled("notif.openRound.enabled")) return
        schedule(ctx, ID_OPEN_ROUND, delayUntil(1, 8), "Offene Runde wartet",
            "Deine Runde auf $courseName ist noch nicht abgeschlossen.")
    }

    fun cancelOpenRound(ctx: Context) = cancel(ctx, ID_OPEN_ROUND)

    /** Während der Runde: nach `minutes` ohne Eintrag erinnern. */
    fun rescheduleRoundInactivity(ctx: Context) {
        if (!enabled("notif.roundInactivity.enabled")) return
        val stored = Prefs.int("notif.roundInactivity.minutes", 0)
        val minutes = if (stored > 0) stored else 45
        schedule(ctx, ID_ROUND_INACTIVITY, minutes * 60_000L, "Noch auf dem Platz? ⛳",
            "Du hast seit $minutes Minuten kein Ergebnis eingetragen. Vergiss nicht deine Schläge!")
    }

    fun cancelRoundInactivity(ctx: Context) = cancel(ctx, ID_ROUND_INACTIVITY)

    /** „Du hast seit X Tagen nicht gespielt" – um 9 Uhr. */
    fun scheduleInactivity(ctx: Context, afterDays: Int? = null) {
        if (!enabled("notif.inactivity.enabled")) { cancel(ctx, ID_INACTIVITY); return }
        val stored = Prefs.int("notif.inactivity.days", 0)
        val days = afterDays ?: if (stored > 0) stored else 5
        schedule(ctx, ID_INACTIVITY, delayUntil(days, 9), "Zeit für eine Runde Golf ⛳",
            "Du hast seit $days Tagen nicht gespielt. Raus auf den Platz!")
    }

    fun canPost(ctx: Context): Boolean = Build.VERSION.SDK_INT < 33 ||
        ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    internal fun post(ctx: Context, id: String, title: String, body: String) {
        if (!canPost(ctx)) return
        val nm = ctx.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26 && nm.getNotificationChannel(CHANNEL) == null) {
            nm.createNotificationChannel(NotificationChannel(CHANNEL, "Erinnerungen", NotificationManager.IMPORTANCE_DEFAULT))
        }
        val launch = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
        val pi = launch?.let { PendingIntent.getActivity(ctx, id.hashCode(), it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT) }
        val n = NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .apply { if (pi != null) setContentIntent(pi) }
            .build()
        runCatching { NotificationManagerCompat.from(ctx).notify(id.hashCode(), n) }
    }
}

class ReminderWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {
    override suspend fun doWork(): Result {
        val id = inputData.getString("id") ?: return Result.success()
        RoundReminders.post(
            applicationContext, id,
            inputData.getString("title") ?: "", inputData.getString("body") ?: "",
        )
        return Result.success()
    }
}
