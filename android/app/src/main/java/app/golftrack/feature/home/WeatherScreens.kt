package app.golftrack.feature.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Thermostat
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import app.golftrack.data.Prefs
import app.golftrack.feature.profile.GroupCard
import app.golftrack.feature.profile.RowDivider
import app.golftrack.feature.profile.SectionFooter
import app.golftrack.feature.profile.SectionHeader
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme
import java.util.Locale
import kotlin.math.roundToInt

/** Vorhersage wie WeatherForecastView.swift. */
@Composable
fun WeatherForecastScreen(nav: NavController) {
    val weather by GolfWeather.state.collectAsState()
    val rules = rememberGolfWeatherRules()
    var expandedDay by remember { mutableStateOf<String?>(null) }

    AppScaffold(weather.locationName.ifEmpty { "Wettervorhersage" }, onBack = { nav.popBackStack() }) { m ->
        Column(
            m.verticalScroll(rememberScrollState()).padding(top = 16.dp, bottom = 30.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            CurrentSummary(weather, rules)

            val now = System.currentTimeMillis()
            val upcoming = weather.dailyForecast.flatMap { it.hours }.filter { it.date + 3_600_000 > now }.take(24)
            if (upcoming.isNotEmpty()) {
                Column {
                    Text(
                        "Nächste Stunden", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 20.dp).padding(bottom = 12.dp),
                    )
                    HourStrip(
                        upcoming, rules,
                        Modifier.padding(horizontal = 16.dp).fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(vertical = 12.dp),
                    )
                }
            }

            if (weather.dailyForecast.isNotEmpty()) {
                Column {
                    Text(
                        "7-Tage-Vorhersage", color = AppTheme.textSec, fontSize = 15.sp, fontWeight = FontWeight.Bold,
                        modifier = Modifier.padding(horizontal = 20.dp).padding(bottom = 12.dp),
                    )
                    Column(Modifier.padding(horizontal = 16.dp).fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp))) {
                        weather.dailyForecast.forEachIndexed { i, day ->
                            DayRow(day, rules, i == weather.dailyForecast.lastIndex, expandedDay == day.id) {
                                if (day.hours.isNotEmpty()) {
                                    Haptics.selection()
                                    expandedDay = if (expandedDay == day.id) null else day.id
                                }
                            }
                        }
                    }
                }
            }

            Row(
                Modifier.padding(horizontal = 16.dp).fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(AppTheme.card)
                    .clickable { Haptics.tap(); nav.navigate(HomeExtraRoutes.WEATHER_SETTINGS) }.padding(vertical = 14.dp),
                horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Filled.Tune, null, tint = AppTheme.gold, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text("Golf-Wetter-Grenzen anpassen", color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun CurrentSummary(weather: WeatherState, rules: GolfWeatherRules) {
    val good = weather.isGoodGolfWeather(rules)
    val badge = if (good) goodColor else warnColor
    Column(Modifier.padding(horizontal = 16.dp).fillMaxWidth().background(AppTheme.card, RoundedCornerShape(16.dp)).padding(20.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            Row(
                Modifier.background(badge.copy(alpha = 0.12f), CircleShape).padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(Modifier.size(6.dp).background(badge, CircleShape))
                Spacer(Modifier.width(4.dp))
                Text(weather.golfWeatherLabel(rules), color = badge, fontSize = 11.sp, fontWeight = FontWeight.Bold)
            }
        }
        Row(Modifier.height(IntrinsicSize.Min), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Icon(weather.symbol.icon, null, tint = weather.symbol.tint, modifier = Modifier.size(46.dp))
                Text(weather.temperature, color = AppTheme.text, fontSize = 36.sp, fontWeight = FontWeight.Bold)
                Text(weather.conditionText, color = AppTheme.textSec, fontSize = 12.sp)
            }
            VerticalDivider(Modifier.height(80.dp), color = AppTheme.cardAlt)
            Column(Modifier.weight(1f).padding(start = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                WeatherDetail(Icons.Filled.Thermostat, "Gefühlt", weather.feelsLike)
                WeatherDetail(Icons.Filled.Air, "Wind", weather.windSpeed)
                WeatherDetail(Icons.Filled.WaterDrop, "Feuchte", weather.humidity)
            }
        }
    }
}

/** Grün = spielbar, Orange = Regen/Wind/Kälte, Grau = dunkel. */
private fun hourColor(h: HourlyForecast, rules: GolfWeatherRules): Color =
    if (!h.isDaylight) AppTheme.textTer.copy(alpha = 0.3f) else if (h.isPlayable(rules)) goodColor else warnColor

@Composable
private fun HourStrip(hours: List<HourlyForecast>, rules: GolfWeatherRules, modifier: Modifier = Modifier) {
    Row(modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 12.dp), horizontalArrangement = Arrangement.spacedBy(4.dp)) {
        hours.forEach { h ->
            Column(Modifier.width(44.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(hourLabel(h.date) + " Uhr", color = AppTheme.textSec, fontSize = 10.sp, maxLines = 1)
                Icon(h.symbol.icon, null, tint = h.symbol.tint, modifier = Modifier.size(22.dp))
                Text("${h.temperature.roundToInt()}°", color = AppTheme.text, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                Text(
                    if (h.precipitationMm >= 0.1) String.format(Locale.GERMANY, "%.1f", h.precipitationMm) else " ",
                    color = rainBlue.copy(alpha = 0.8f), fontSize = 10.sp,
                )
                Box(Modifier.fillMaxWidth().height(4.dp).background(hourColor(h, rules), CircleShape))
            }
        }
    }
}

@Composable
private fun DayRow(day: DailyForecast, rules: GolfWeatherRules, isLast: Boolean, expanded: Boolean, onClick: () -> Unit) {
    val windows = day.golfWindows(rules)
    val arrow by animateFloatAsState(if (expanded) 180f else 0f, label = "arrow")
    Column(Modifier.fillMaxWidth().clickable(enabled = day.hours.isNotEmpty()) { onClick() }) {
        Row(
            Modifier.padding(horizontal = 16.dp).padding(top = 14.dp, bottom = if (day.hours.isEmpty()) 14.dp else 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(day.dayLabel, color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold, modifier = Modifier.width(100.dp), maxLines = 1)
            Icon(day.symbol.icon, null, tint = day.symbol.tint, modifier = Modifier.size(24.dp))
            Spacer(Modifier.width(12.dp))
            Text(day.conditionText, color = AppTheme.textSec, fontSize = 12.sp, maxLines = 1, modifier = Modifier.weight(1f))
            Column(horizontalAlignment = Alignment.End) {
                Text("${day.maxTemp.roundToInt()}°", color = AppTheme.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                Text("${day.minTemp.roundToInt()}°", color = AppTheme.textSec, fontSize = 12.sp)
            }
            Spacer(Modifier.width(12.dp))
            if (day.hours.isNotEmpty()) {
                Icon(Icons.Filled.KeyboardArrowDown, null, tint = AppTheme.textTer, modifier = Modifier.size(18.dp).rotate(arrow))
            } else {
                val ok = day.isGoodGolfWeather(rules)
                Icon(if (ok) Icons.Filled.CheckCircle else Icons.Filled.Cancel, null, tint = if (ok) goodColor else warnColor, modifier = Modifier.size(20.dp))
            }
        }
        // Golf-Fenster statt eines Urteils über den ganzen Tag
        if (day.hours.isNotEmpty()) {
            Column(Modifier.padding(horizontal = 16.dp).padding(bottom = 10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                val now = System.currentTimeMillis()
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                    day.daylightHours.forEach { h ->
                        Box(
                            Modifier.weight(1f).height(6.dp).alpha(if (h.date + 3_600_000 <= now) 0.25f else 1f)
                                .background(hourColor(h, rules), RoundedCornerShape(2.dp)),
                        )
                    }
                }
                val col = if (windows.isEmpty()) warnColor else goodColor
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(if (windows.isEmpty()) Icons.Filled.Cancel else Icons.Filled.SportsGolf, null, tint = col, modifier = Modifier.size(13.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(windowText(windows, day.isToday), color = col, fontSize = 12.sp, fontWeight = FontWeight.Bold, maxLines = 2)
                }
            }
        }
        if (day.precipitationMm > 0 || day.maxWindKmh > 20) {
            Row(Modifier.padding(horizontal = 16.dp).padding(bottom = 10.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                if (day.precipitationMm > 0) {
                    SmallLabel(Icons.Filled.WaterDrop, String.format(Locale.GERMANY, "%.1f mm", day.precipitationMm), rainBlue.copy(alpha = 0.8f))
                }
                if (day.maxWindKmh > 0) {
                    SmallLabel(Icons.Filled.Air, String.format(Locale.GERMANY, "%.0f km/h", day.maxWindKmh), if (day.maxWindKmh > 30) warnColor else AppTheme.textSec)
                }
            }
        }
        AnimatedVisibility(expanded) {
            HourStrip(day.daylightHours, rules, Modifier.padding(bottom = 12.dp))
        }
        if (!isLast) HorizontalDivider(Modifier.padding(start = 16.dp), color = AppTheme.cardAlt)
    }
}

@Composable
private fun SmallLabel(icon: ImageVector, text: String, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = color, modifier = Modifier.size(11.dp))
        Spacer(Modifier.width(3.dp))
        Text(text, color = color, fontSize = 11.sp)
    }
}

private fun windowText(windows: List<GolfWindow>, isToday: Boolean): String {
    if (windows.isEmpty()) return if (isToday) "Heute kein Golf-Fenster mehr" else "Kein Golf-Fenster"
    val labels = windows.map { it.label }
    val list = if (labels.size == 1) labels[0] else labels.dropLast(1).joinToString(", ") + " und " + labels.last()
    return "Golf-Wetter: $list"
}

// --- Einstellungen „Golf-Wetter" (GolfWeatherSettingsView.swift) ---

@Composable
fun GolfWeatherSettingsScreen(nav: NavController) {
    val rules = rememberGolfWeatherRules()
    val isDefault = rules == GolfWeatherRules.DEFAULT

    AppScaffold("Golf-Wetter", onBack = { nav.popBackStack() }) { m ->
        Column(m.verticalScroll(rememberScrollState()).padding(16.dp)) {
            SectionHeader("Spielbare Stunde")
            GroupCard {
                SliderRow(
                    Icons.Filled.WaterDrop, "Regen pro Stunde",
                    if (rules.maxRainMm < 0.05) "kein Regen" else String.format(Locale.GERMANY, "%.1f mm", rules.maxRainMm),
                    rules.maxRainMm, 0.0, 2.0, 0.1,
                ) { GolfWeatherRules.setDouble(GolfWeatherRules.MAX_RAIN_KEY, it) }
                RowDivider(16.dp)
                SliderRow(Icons.Filled.Air, "Wind", "${rules.maxWindKmh.toInt()} km/h", rules.maxWindKmh, 10.0, 60.0, 5.0) {
                    GolfWeatherRules.setDouble(GolfWeatherRules.MAX_WIND_KEY, it)
                }
                RowDivider(16.dp)
                SliderRow(Icons.Filled.Thermostat, "Mindesttemperatur", "${rules.minTemperature.toInt()}°C", rules.minTemperature, -5.0, 20.0, 1.0) {
                    GolfWeatherRules.setDouble(GolfWeatherRules.MIN_TEMPERATURE_KEY, it)
                }
            }
            SectionFooter("Eine Stunde zählt als Golf-Wetter, wenn höchstens so viel Regen fällt, der Wind nicht stärker ist und es mindestens so warm ist. Nebel, Schnee, Glätte, Gewitter und Dunkelheit zählen immer als schlecht.")

            Spacer(Modifier.height(20.dp))
            SectionHeader("Golf-Fenster")
            GroupCard {
                Row(Modifier.padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.AccessTime, null, tint = AppTheme.gold, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(12.dp))
                    Text("Mindestdauer", color = AppTheme.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
                    Text("${rules.minWindowHours} h", color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.width(12.dp))
                    Stepper(
                        canDec = rules.minWindowHours > 1, canInc = rules.minWindowHours < 5,
                        onDec = { Prefs.set(GolfWeatherRules.MIN_WINDOW_KEY, rules.minWindowHours - 1) },
                        onInc = { Prefs.set(GolfWeatherRules.MIN_WINDOW_KEY, rules.minWindowHours + 1) },
                    )
                }
            }
            SectionFooter("So viele gute Stunden am Stück braucht es, damit ein Zeitraum als Golf-Fenster angezeigt wird. Neun Loch dauern etwa 2 Stunden, 18 Loch etwa 4.")

            Spacer(Modifier.height(20.dp))
            GroupCard {
                Text(
                    "Auf Standard zurücksetzen",
                    color = if (isDefault) AppTheme.textTer else AppTheme.gold, fontSize = 15.sp,
                    modifier = Modifier.fillMaxWidth().clickable(enabled = !isDefault) { Haptics.tap(); GolfWeatherRules.reset() }
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                )
            }
        }
    }
}

@Composable
private fun SliderRow(
    icon: ImageVector, title: String, value: String, current: Double,
    min: Double, max: Double, step: Double, onChange: (Double) -> Unit,
) {
    Column(Modifier.padding(horizontal = 16.dp, vertical = 10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, null, tint = AppTheme.gold, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(12.dp))
            Text(title, color = AppTheme.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
            Text(value, color = AppTheme.gold, fontSize = 15.sp, fontWeight = FontWeight.Bold)
        }
        val steps = ((max - min) / step).roundToInt() - 1
        Slider(
            value = current.toFloat(),
            onValueChange = { v ->
                val snapped = (Math.round((v - min) / step) * step + min)
                onChange((snapped * 10).roundToInt() / 10.0)
            },
            onValueChangeFinished = { Haptics.selection() },
            valueRange = min.toFloat()..max.toFloat(),
            steps = steps,
            colors = SliderDefaults.colors(
                thumbColor = Color.White, activeTrackColor = AppTheme.gold, inactiveTrackColor = AppTheme.cardAlt,
                activeTickColor = Color.Transparent, inactiveTickColor = Color.Transparent,
            ),
        )
    }
}

/** Plus/Minus wie `Stepper` auf iOS. */
@Composable
internal fun Stepper(canDec: Boolean, canInc: Boolean, onDec: () -> Unit, onInc: () -> Unit) {
    Row(Modifier.background(AppTheme.cardAlt, RoundedCornerShape(8.dp))) {
        Box(
            Modifier.clip(RoundedCornerShape(8.dp)).clickable(enabled = canDec) { Haptics.selection(); onDec() }.padding(horizontal = 12.dp, vertical = 6.dp),
        ) { Icon(Icons.Filled.Remove, "Weniger", tint = if (canDec) AppTheme.text else AppTheme.textTer, modifier = Modifier.size(18.dp)) }
        Box(Modifier.width(1.dp).height(30.dp).background(AppTheme.card))
        Box(
            Modifier.clip(RoundedCornerShape(8.dp)).clickable(enabled = canInc) { Haptics.selection(); onInc() }.padding(horizontal = 12.dp, vertical = 6.dp),
        ) { Icon(Icons.Filled.Add, "Mehr", tint = if (canInc) AppTheme.text else AppTheme.textTer, modifier = Modifier.size(18.dp)) }
    }
}
