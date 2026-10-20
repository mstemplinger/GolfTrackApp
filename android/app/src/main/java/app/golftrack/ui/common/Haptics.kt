package app.golftrack.ui.common

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import app.golftrack.data.Prefs

/**
 * Zentrale Haptik wie `Haptics` in GolfTrackShared/Haptics.swift. Alle Screens
 * spielen Feedback nur hierüber; der Schalter "hapticsEnabled" gilt global.
 */
object Haptics {
    const val ENABLED_KEY = "hapticsEnabled"
    private var vibrator: Vibrator? = null

    fun init(context: Context) {
        vibrator = if (Build.VERSION.SDK_INT >= 31) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private val enabled: Boolean get() = Prefs.bool(ENABLED_KEY, true)

    private fun predefined(id: Int, fallbackMs: Long) {
        val v = vibrator ?: return
        if (!enabled || !v.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= 29) v.vibrate(VibrationEffect.createPredefined(id))
        else v.vibrate(VibrationEffect.createOneShot(fallbackMs, VibrationEffect.DEFAULT_AMPLITUDE))
    }

    private fun waveform(timings: LongArray, amplitudes: IntArray) {
        val v = vibrator ?: return
        if (!enabled || !v.hasVibrator()) return
        v.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
    }

    fun tap() = predefined(VibrationEffect.EFFECT_TICK, 10)
    fun selection() = predefined(VibrationEffect.EFFECT_TICK, 8)
    fun light() = predefined(VibrationEffect.EFFECT_TICK, 10)
    fun medium() = predefined(VibrationEffect.EFFECT_CLICK, 20)
    fun heavy() = predefined(VibrationEffect.EFFECT_HEAVY_CLICK, 35)
    fun success() = waveform(longArrayOf(0, 20, 60, 30), intArrayOf(0, 120, 0, 200))
    fun warning() = waveform(longArrayOf(0, 30, 80, 30), intArrayOf(0, 180, 0, 120))
    fun error() = waveform(longArrayOf(0, 30, 50, 30, 50, 30), intArrayOf(0, 200, 0, 200, 0, 200))

    /** Ein Schlag gezählt. */
    fun stroke() = medium()
    /** Score eines Lochs eingetragen. */
    fun score() = medium()
    fun holeFinished() = success()
    /** Birdie, bestandene Prüfung, Runde fertig. */
    fun celebrate() = waveform(longArrayOf(0, 25, 50, 25, 50, 60), intArrayOf(0, 150, 0, 200, 0, 255))
}
