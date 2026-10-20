package app.golftrack.data

import android.content.Context
import android.content.SharedPreferences
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember

/**
 * Ersatz für `@AppStorage`/`UserDefaults`. Schlüssel wie auf iOS benennen
 * (z. B. "distanceUnit", "playerName", "hasSeenOnboarding").
 */
object Prefs {
    lateinit var sp: SharedPreferences
        private set

    fun init(context: Context) {
        sp = context.getSharedPreferences("golftrack", Context.MODE_PRIVATE)
    }

    fun string(key: String, def: String = ""): String = sp.getString(key, def) ?: def
    fun bool(key: String, def: Boolean = false): Boolean = sp.getBoolean(key, def)
    fun int(key: String, def: Int = 0): Int = sp.getInt(key, def)
    fun set(key: String, v: String) = sp.edit().putString(key, v).apply()
    fun set(key: String, v: Boolean) = sp.edit().putBoolean(key, v).apply()
    fun set(key: String, v: Int) = sp.edit().putInt(key, v).apply()
    fun remove(key: String) = sp.edit().remove(key).apply()

    var distanceUnit: DistanceUnit
        get() = DistanceUnit.fromRaw(sp.getString("distanceUnit", null))
        set(v) = set("distanceUnit", v.raw)

    var playerName: String
        get() = string("playerName")
        set(v) = set("playerName", v)

    var appFocus: AppFocus
        get() = AppFocus.fromRaw(sp.getString("appFocus", null))
        set(v) = set("appFocus", v.raw)
}

/** Compose-Gegenstück zu `@AppStorage` – liest und schreibt live. */
@Composable
fun rememberPrefString(key: String, def: String = ""): MutableState<String> =
    rememberPref(key, { Prefs.string(key, def) }, { Prefs.set(key, it) })

@Composable
fun rememberPrefBool(key: String, def: Boolean = false): MutableState<Boolean> =
    rememberPref(key, { Prefs.bool(key, def) }, { Prefs.set(key, it) })

@Composable
fun rememberPrefInt(key: String, def: Int = 0): MutableState<Int> =
    rememberPref(key, { Prefs.int(key, def) }, { Prefs.set(key, it) })

@Composable
private fun <T> rememberPref(key: String, read: () -> T, write: (T) -> Unit): MutableState<T> {
    val state = remember(key) {
        val inner = mutableStateOf(read())
        object : MutableState<T> by inner {
            override var value: T
                get() = inner.value
                set(v) { inner.value = v; write(v) }
        }
    }
    DisposableEffect(key) {
        val l = SharedPreferences.OnSharedPreferenceChangeListener { _, k ->
            if (k == key) state.value.let { cur -> val fresh = read(); if (fresh != cur) state.value = fresh }
        }
        Prefs.sp.registerOnSharedPreferenceChangeListener(l)
        onDispose { Prefs.sp.unregisterOnSharedPreferenceChangeListener(l) }
    }
    return state
}
