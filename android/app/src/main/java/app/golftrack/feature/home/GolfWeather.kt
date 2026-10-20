package app.golftrack.feature.home

import android.annotation.SuppressLint
import android.content.Context
import android.location.Geocoder
import android.location.LocationManager
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AcUnit
import androidx.compose.material.icons.filled.Cloud
import androidx.compose.material.icons.filled.Grain
import androidx.compose.material.icons.filled.NightsStay
import androidx.compose.material.icons.filled.Thunderstorm
import androidx.compose.material.icons.filled.Umbrella
import androidx.compose.material.icons.filled.WbCloudy
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.Water
import androidx.compose.material.icons.filled.FilterDrama
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import app.golftrack.data.LatLon
import app.golftrack.data.Prefs
import app.golftrack.ui.common.LocationService
import app.golftrack.ui.theme.AppTheme
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

// --- Golf-Wetter-Grenzen (Einstellungen → Golf-Wetter) ---

/** Vom Nutzer einstellbare Grenzen für „Golf-Wetter" – gleiche Schlüssel wie auf iOS. */
data class GolfWeatherRules(
    val maxRainMm: Double,
    val maxWindKmh: Double,
    val minTemperature: Double,
    val minWindowHours: Int,
) {
    companion object {
        val DEFAULT = GolfWeatherRules(0.2, 30.0, 3.0, 2)
        const val MAX_RAIN_KEY = "golfWeather.maxRainMm"
        const val MAX_WIND_KEY = "golfWeather.maxWindKmh"
        const val MIN_TEMPERATURE_KEY = "golfWeather.minTemperature"
        const val MIN_WINDOW_KEY = "golfWeather.minWindowHours"
        val KEYS = listOf(MAX_RAIN_KEY, MAX_WIND_KEY, MIN_TEMPERATURE_KEY, MIN_WINDOW_KEY)

        fun double(key: String, fallback: Double): Double =
            if (Prefs.sp.contains(key)) Prefs.sp.getFloat(key, fallback.toFloat()).toDouble() else fallback

        fun setDouble(key: String, v: Double) = Prefs.sp.edit().putFloat(key, v.toFloat()).apply()

        val current: GolfWeatherRules
            get() = GolfWeatherRules(
                maxRainMm = double(MAX_RAIN_KEY, DEFAULT.maxRainMm),
                maxWindKmh = double(MAX_WIND_KEY, DEFAULT.maxWindKmh),
                minTemperature = double(MIN_TEMPERATURE_KEY, DEFAULT.minTemperature),
                minWindowHours = Prefs.int(MIN_WINDOW_KEY, DEFAULT.minWindowHours),
            )

        fun reset() {
            val e = Prefs.sp.edit()
            KEYS.forEach { e.remove(it) }
            e.apply()
        }
    }
}

// --- Modelle ---

data class HourlyForecast(
    /** Beginn der Stunde in Millisekunden. */
    val date: Long,
    val weatherCode: Int,
    val temperature: Double,
    val precipitationMm: Double,
    val precipitationProbability: Int,
    val windKmh: Double,
    val isDaylight: Boolean,
) {
    val symbol: WeatherSymbol get() = GolfWeather.weatherInfo(weatherCode, isDaylight).second

    fun isPlayable(rules: GolfWeatherRules = GolfWeatherRules.current): Boolean =
        isDaylight &&
            precipitationMm <= rules.maxRainMm + 0.001 &&
            windKmh <= rules.maxWindKmh &&
            temperature >= rules.minTemperature &&
            weatherCode !in UNPLAYABLE_CODES

    companion object {
        /** Nebel, Eis, Schnee und Gewitter sind unabhängig von der Regenmenge kein Golfwetter. */
        private val UNPLAYABLE_CODES = setOf(45, 48, 56, 57, 66, 67, 71, 73, 75, 77, 85, 86, 95, 96, 99)
    }
}

/** Zusammenhängende Spielzeit an einem Tag, `end` exklusiv. */
data class GolfWindow(val start: Long, val end: Long) {
    val label: String get() = "${hourLabel(start)}–${hourLabel(end)} Uhr"
}

internal fun hourLabel(ms: Long): String {
    val c = Calendar.getInstance().apply { timeInMillis = ms }
    return c.get(Calendar.HOUR_OF_DAY).toString()
}

object GolfWindowFinder {
    /**
     * Fasst aufeinanderfolgende spielbare Stunden zu Fenstern zusammen. Stunden,
     * die vor `now` enden, werden ignoriert; Fenster kürzer als `minWindowHours` zählen nicht.
     */
    fun windows(hours: List<HourlyForecast>, now: Long? = null, rules: GolfWeatherRules = GolfWeatherRules.current): List<GolfWindow> {
        val minimum = rules.minWindowHours * 3_600_000L
        val result = mutableListOf<GolfWindow>()
        var start: Long? = null
        var end: Long? = null
        fun close() {
            val s = start; val e = end
            if (s != null && e != null && e - s >= minimum) result.add(GolfWindow(s, e))
            start = null; end = null
        }
        for (h in hours.sortedBy { it.date }) {
            val hourEnd = h.date + 3_600_000L
            if (now != null && hourEnd <= now) continue
            if (h.isPlayable(rules)) {
                // Lücken in den Daten beenden ein Fenster ebenfalls.
                end?.let { if (it != h.date) close() }
                if (start == null) start = maxOf(h.date, now ?: h.date)
                end = hourEnd
            } else close()
        }
        close()
        return result
    }
}

data class DailyForecast(
    val id: String,
    val date: Long,
    val weatherCode: Int,
    val maxTemp: Double,
    val minTemp: Double,
    val precipitationMm: Double,
    val maxWindKmh: Double,
    val conditionText: String,
    val symbol: WeatherSymbol,
    val hours: List<HourlyForecast> = emptyList(),
) {
    val isToday: Boolean get() = sameDay(date, System.currentTimeMillis())

    /** Für heute nur die noch kommenden Stunden. */
    fun golfWindows(rules: GolfWeatherRules = GolfWeatherRules.current): List<GolfWindow> =
        GolfWindowFinder.windows(hours, if (isToday) System.currentTimeMillis() else null, rules)

    fun isGoodGolfWeather(rules: GolfWeatherRules = GolfWeatherRules.current): Boolean =
        if (hours.isEmpty()) weatherCode < 45 && maxWindKmh <= 30 else golfWindows(rules).isNotEmpty()

    val daylightHours: List<HourlyForecast> get() = hours.filter { it.isDaylight }

    val dayLabel: String
        get() {
            val now = System.currentTimeMillis()
            if (sameDay(date, now)) return "Heute"
            if (sameDay(date, now + 86_400_000L)) return "Morgen"
            return SimpleDateFormat("EEE, d. MMM", Locale.GERMANY).format(date)
        }
}

internal fun sameDay(a: Long, b: Long): Boolean {
    val ca = Calendar.getInstance().apply { timeInMillis = a }
    val cb = Calendar.getInstance().apply { timeInMillis = b }
    return ca.get(Calendar.YEAR) == cb.get(Calendar.YEAR) && ca.get(Calendar.DAY_OF_YEAR) == cb.get(Calendar.DAY_OF_YEAR)
}

/** Ersatz für die mehrfarbigen SF Symbols: Material-Symbol plus Farbe. */
data class WeatherSymbol(val icon: ImageVector, val tint: Color)

private val sunColor = Color(0xFFFFC93C)
private val cloudColor = Color(0xFFD9DEE3)
private val rainColor = Color(0xFF5AB4FF)
private val moonColor = Color(0xFFE8E2C0)

// --- Open-Meteo ---

@Serializable
private data class OpenMeteoResponse(
    val current: Current,
    val daily: Daily,
    val hourly: Hourly? = null,
    @SerialName("utc_offset_seconds") val utcOffsetSeconds: Int? = null,
) {
    @Serializable
    data class Current(
        @SerialName("temperature_2m") val temperature2m: Double,
        @SerialName("apparent_temperature") val apparentTemperature: Double,
        @SerialName("weather_code") val weatherCode: Int,
        @SerialName("wind_speed_10m") val windSpeed10m: Double,
        @SerialName("relative_humidity_2m") val relativeHumidity2m: Int,
        @SerialName("is_day") val isDay: Int? = null,
    )

    @Serializable
    data class Daily(
        val time: List<String>,
        @SerialName("weather_code") val weatherCode: List<Int?> = emptyList(),
        @SerialName("temperature_2m_max") val temperature2mMax: List<Double?> = emptyList(),
        @SerialName("temperature_2m_min") val temperature2mMin: List<Double?> = emptyList(),
        @SerialName("precipitation_sum") val precipitationSum: List<Double?> = emptyList(),
        @SerialName("wind_speed_10m_max") val windSpeed10mMax: List<Double?> = emptyList(),
    )

    @Serializable
    data class Hourly(
        val time: List<String>,
        @SerialName("weather_code") val weatherCode: List<Int?> = emptyList(),
        @SerialName("temperature_2m") val temperature2m: List<Double?> = emptyList(),
        val precipitation: List<Double?> = emptyList(),
        @SerialName("precipitation_probability") val precipitationProbability: List<Int?>? = null,
        @SerialName("wind_speed_10m") val windSpeed10m: List<Double?> = emptyList(),
        @SerialName("is_day") val isDay: List<Int?> = emptyList(),
    )
}

/** Zustand der Wetteranzeige – ein gemeinsamer Stand für Startseite und Vorhersage. */
data class WeatherState(
    val temperature: String = "--",
    val feelsLike: String = "--",
    val conditionText: String = "Golf-Wetter",
    val symbol: WeatherSymbol = WeatherSymbol(Icons.Filled.WbSunny, sunColor),
    val windSpeed: String = "",
    val humidity: String = "",
    val uvIndex: String = "",
    val locationName: String = "",
    val isLoading: Boolean = false,
    val hasData: Boolean = false,
    val authDenied: Boolean = false,
    val errorMessage: String? = null,
    val dailyForecast: List<DailyForecast> = emptyList(),
    val rawWeatherCode: Int = -1,
    val rawWindSpeed: Double = 0.0,
    /** null = Mein Standort, sonst Name des gewählten Platzes. */
    val selectedCourseName: String? = null,
) {
    private val hasHourlyData: Boolean get() = dailyForecast.any { it.isToday && it.hours.isNotEmpty() }

    fun todayWindows(rules: GolfWeatherRules): List<GolfWindow> =
        dailyForecast.firstOrNull { it.isToday }?.golfWindows(rules) ?: emptyList()

    fun isGoodGolfWeather(rules: GolfWeatherRules): Boolean {
        if (!hasData) return true
        if (!hasHourlyData) return rawWeatherCode < 45 && rawWindSpeed <= 30
        return todayWindows(rules).isNotEmpty()
    }

    fun golfWeatherLabel(rules: GolfWeatherRules): String {
        if (!hasData || !hasHourlyData) return if (isGoodGolfWeather(rules)) "Golf-Wetter" else "schlechtes Wetter"
        val next = todayWindows(rules).firstOrNull() ?: return "Heute kein Golf-Wetter"
        return if (next.start <= System.currentTimeMillis()) "Golf-Wetter bis ${hourLabel(next.end)} Uhr"
        else "Golf-Wetter ab ${hourLabel(next.start)} Uhr"
    }
}

/** Wetter von Open-Meteo wie `GolfWeatherService` auf iOS. */
object GolfWeather {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }

    private val _state = MutableStateFlow(WeatherState())
    val state: StateFlow<WeatherState> = _state.asStateFlow()

    /** Wetter am eigenen Standort. Ohne Berechtigung wird `authDenied` gesetzt. */
    @SuppressLint("MissingPermission")
    fun fetch(context: Context) {
        val s = _state.value
        if (s.isLoading) return
        if (!LocationService.hasPermission(context)) {
            _state.value = s.copy(isLoading = false, authDenied = true, errorMessage = null, selectedCourseName = null)
            return
        }
        _state.value = s.copy(isLoading = true, errorMessage = null, authDenied = false, selectedCourseName = null)
        scope.launch {
            val here = LocationService.lastLatLon ?: withContext(Dispatchers.IO) { lastKnown(context) }
            if (here == null) {
                _state.value = _state.value.copy(isLoading = false, errorMessage = "Standort nicht verfügbar")
                return@launch
            }
            val name = withContext(Dispatchers.IO) { locality(context, here) }
            _state.value = _state.value.copy(locationName = name ?: "")
            fetchWeather(here)
        }
    }

    /** Wetter für einen Platz (ohne GPS). */
    fun fetchForCoordinate(lat: Double, lon: Double, name: String) {
        if (_state.value.isLoading) return
        _state.value = _state.value.copy(isLoading = true, errorMessage = null, authDenied = false, locationName = name, selectedCourseName = name)
        scope.launch { fetchWeather(LatLon(lat, lon)) }
    }

    @SuppressLint("MissingPermission")
    private fun lastKnown(context: Context): LatLon? {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return lm.getProviders(true)
            .mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }
            .maxByOrNull { it.time }
            ?.let { LatLon(it.latitude, it.longitude) }
    }

    @Suppress("DEPRECATION")
    private fun locality(context: Context, p: LatLon): String? = runCatching {
        if (!Geocoder.isPresent()) return null
        Geocoder(context, Locale.GERMANY).getFromLocation(p.lat, p.lon, 1)?.firstOrNull()?.locality
    }.getOrNull()

    private suspend fun fetchWeather(p: LatLon) {
        val url = "https://api.open-meteo.com/v1/forecast" +
            "?latitude=${p.lat}&longitude=${p.lon}" +
            "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m,is_day" +
            "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max" +
            "&hourly=weather_code,temperature_2m,precipitation,precipitation_probability,wind_speed_10m,is_day" +
            "&forecast_days=7&wind_speed_unit=kmh&timezone=auto"
        try {
            val text = withContext(Dispatchers.IO) {
                val c = URL(url).openConnection() as java.net.HttpURLConnection
                try {
                    c.connectTimeout = 15_000
                    c.readTimeout = 15_000
                    c.inputStream.bufferedReader().use { it.readText() }
                } finally {
                    c.disconnect()
                }
            }
            val d = json.decodeFromString(OpenMeteoResponse.serializer(), text)
            val cur = d.current
            val (ct, sym) = weatherInfo(cur.weatherCode, (cur.isDay ?: 1) == 1)
            val offset = d.utcOffsetSeconds ?: 0
            val hoursByDay = parseHourly(d.hourly, offset)
            val dayFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply { timeZone = tz(offset) }
            val daily = d.daily.time.mapIndexedNotNull { i, t ->
                val date = runCatching { dayFmt.parse(t)?.time }.getOrNull() ?: return@mapIndexedNotNull null
                val code = d.daily.weatherCode.getOrNull(i) ?: 0
                val (dct, dsym) = weatherInfo(code)
                DailyForecast(
                    id = t, date = date, weatherCode = code,
                    maxTemp = d.daily.temperature2mMax.getOrNull(i) ?: 0.0,
                    minTemp = d.daily.temperature2mMin.getOrNull(i) ?: 0.0,
                    precipitationMm = d.daily.precipitationSum.getOrNull(i) ?: 0.0,
                    maxWindKmh = d.daily.windSpeed10mMax.getOrNull(i) ?: 0.0,
                    conditionText = dct, symbol = dsym,
                    hours = hoursByDay[t] ?: emptyList(),
                )
            }
            _state.value = _state.value.copy(
                temperature = String.format(Locale.GERMANY, "%.0f°C", cur.temperature2m),
                feelsLike = String.format(Locale.GERMANY, "%.0f°C", cur.apparentTemperature),
                windSpeed = String.format(Locale.GERMANY, "%.0f km/h", cur.windSpeed10m),
                humidity = "${cur.relativeHumidity2m}%",
                uvIndex = "–",
                rawWeatherCode = cur.weatherCode,
                rawWindSpeed = cur.windSpeed10m,
                conditionText = ct,
                symbol = sym,
                dailyForecast = daily,
                hasData = true,
                isLoading = false,
            )
        } catch (e: Exception) {
            _state.value = _state.value.copy(isLoading = false, errorMessage = "Wetter nicht verfügbar")
        }
    }

    private fun tz(offsetSeconds: Int): TimeZone = TimeZone.getTimeZone("GMT").apply { rawOffset = offsetSeconds * 1000 }

    /** Open-Meteo liefert Ortszeit ohne Zone; gruppiert wird nach dem Datumsteil. */
    private fun parseHourly(h: OpenMeteoResponse.Hourly?, offset: Int): Map<String, List<HourlyForecast>> {
        h ?: return emptyMap()
        val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm", Locale.US).apply { timeZone = tz(offset) }
        val result = linkedMapOf<String, MutableList<HourlyForecast>>()
        h.time.forEachIndexed { i, t ->
            val date = runCatching { fmt.parse(t)?.time }.getOrNull() ?: return@forEachIndexed
            val code = h.weatherCode.getOrNull(i) ?: return@forEachIndexed
            val temp = h.temperature2m.getOrNull(i) ?: return@forEachIndexed
            val wind = h.windSpeed10m.getOrNull(i) ?: return@forEachIndexed
            result.getOrPut(t.take(10)) { mutableListOf() }.add(
                HourlyForecast(
                    date = date, weatherCode = code, temperature = temp,
                    precipitationMm = h.precipitation.getOrNull(i) ?: 0.0,
                    precipitationProbability = h.precipitationProbability?.getOrNull(i) ?: 0,
                    windKmh = wind,
                    isDaylight = (h.isDay.getOrNull(i) ?: 1) == 1,
                ),
            )
        }
        return result
    }

    /** WMO-Wettercode → Text + Symbol. Nachts Mond statt Sonne. */
    fun weatherInfo(code: Int, isDay: Boolean = true): Pair<String, WeatherSymbol> {
        val sun = WeatherSymbol(Icons.Filled.WbSunny, sunColor)
        val partly = WeatherSymbol(Icons.Filled.WbCloudy, cloudColor)
        val cloud = WeatherSymbol(Icons.Filled.Cloud, cloudColor)
        val fog = WeatherSymbol(Icons.Filled.FilterDrama, cloudColor.copy(alpha = 0.7f))
        val drizzle = WeatherSymbol(Icons.Filled.Grain, rainColor)
        val rain = WeatherSymbol(Icons.Filled.Umbrella, rainColor)
        val heavy = WeatherSymbol(Icons.Filled.Water, rainColor)
        val snow = WeatherSymbol(Icons.Filled.AcUnit, Color.White)
        val bolt = WeatherSymbol(Icons.Filled.Thunderstorm, sunColor)
        val moon = WeatherSymbol(Icons.Filled.NightsStay, moonColor)
        if (!isDay) {
            when (code) {
                0 -> return "Klar" to moon
                1 -> return "Meist klar" to moon
                2 -> return "Teils bewölkt" to moon
                80, 81 -> return "Regenschauer" to rain
            }
        }
        return when (code) {
            0 -> "Sonnig" to sun
            1 -> "Meist sonnig" to sun
            2 -> "Teils bewölkt" to partly
            3 -> "Bedeckt" to cloud
            45, 48 -> "Neblig" to fog
            51, 53, 55 -> "Nieselregen" to drizzle
            56, 57 -> "Eisregen" to snow
            61, 63 -> "Regen" to rain
            65 -> "Starkregen" to heavy
            66, 67 -> "Gefrierender Regen" to snow
            71, 73 -> "Schnee" to snow
            75 -> "Starker Schnee" to snow
            77 -> "Schneegriesel" to snow
            80, 81 -> "Regenschauer" to rain
            82 -> "Starke Schauer" to heavy
            85, 86 -> "Schneeschauer" to snow
            95 -> "Gewitter" to bolt
            96, 99 -> "Starke Gewitter" to bolt
            else -> "Wechselhaft" to partly
        }
    }
}

/** Live-Grenzen für Compose: aktualisiert sich, wenn sich eine der Einstellungen ändert. */
@androidx.compose.runtime.Composable
fun rememberGolfWeatherRules(): GolfWeatherRules {
    val state = androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(GolfWeatherRules.current) }
    androidx.compose.runtime.DisposableEffect(Unit) {
        val l = android.content.SharedPreferences.OnSharedPreferenceChangeListener { _, k ->
            if (k in GolfWeatherRules.KEYS || k == null) state.value = GolfWeatherRules.current
        }
        Prefs.sp.registerOnSharedPreferenceChangeListener(l)
        onDispose { Prefs.sp.unregisterOnSharedPreferenceChangeListener(l) }
    }
    return state.value
}

internal val goodColor = Color(0xFF34C759)
internal val warnColor = Color(0xFFFF9F0A)
internal val rainBlue = rainColor
