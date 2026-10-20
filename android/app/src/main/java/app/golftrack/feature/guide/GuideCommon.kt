package app.golftrack.feature.guide

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.DirectionsWalk
import androidx.compose.material.icons.automirrored.filled.KeyboardTab
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.automirrored.filled.Redo
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.Accessibility
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Adjust
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.Apps
import androidx.compose.material.icons.filled.ArrowCircleDown
import androidx.compose.material.icons.filled.ArrowCircleRight
import androidx.compose.material.icons.filled.ArrowCircleUp
import androidx.compose.material.icons.filled.Assessment
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.BatteryFull
import androidx.compose.material.icons.filled.BlurCircular
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ConfirmationNumber
import androidx.compose.material.icons.filled.Contrast
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.FormatListNumbered
import androidx.compose.material.icons.filled.FrontHand
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Height
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.LooksOne
import androidx.compose.material.icons.filled.ManageSearch
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.MoreTime
import androidx.compose.material.icons.filled.NorthEast
import androidx.compose.material.icons.filled.PanTool
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PinDrop
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.RemoveCircle
import androidx.compose.material.icons.filled.RemoveCircleOutline
import androidx.compose.material.icons.filled.RemoveRedEye
import androidx.compose.material.icons.filled.Repeat
import androidx.compose.material.icons.filled.RepeatOne
import androidx.compose.material.icons.filled.Replay
import androidx.compose.material.icons.filled.Restore
import androidx.compose.material.icons.filled.RotateRight
import androidx.compose.material.icons.filled.Scale
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.SelfImprovement
import androidx.compose.material.icons.filled.SouthEast
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material.icons.filled.SportsGolf
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.SupervisedUserCircle
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.SwapHorizontalCircle
import androidx.compose.material.icons.filled.SwapVert
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.ThumbUp
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.Umbrella
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.Whatshot
import androidx.compose.material.icons.filled.Wifi
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Map
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.golftrack.ui.common.Haptics
import app.golftrack.ui.theme.AppTheme

/** iOS-Systemfarben (Dark Mode), wie sie die Swift-Quellen mit `.red`, `.orange` … nutzen. */
object IosColor {
    val red = Color(0xFFFF453A)
    val orange = Color(0xFFFF9F0A)
    val yellow = Color(0xFFFFD60A)
    val green = Color(0xFF30D158)
    val mint = Color(0xFF63E6E2)
    val teal = Color(0xFF40C8E0)
    val blue = Color(0xFF0A84FF)
    val purple = Color(0xFFBF5AF2)
    val gray = Color(0xFF8E8E93)
}

/** `Color(red:green:blue:)` aus Swift. */
fun rgb(r: Float, g: Float, b: Float): Color = Color(r, g, b)

/** `Color(white:)` aus Swift. */
fun white(w: Float): Color = Color(w, w, w)

/** iOS-Schriftgrößen (Dynamic Type „Large“). */
object IosFont {
    val largeTitle = 34.sp
    val title = 28.sp
    val title2 = 22.sp
    val title3 = 20.sp
    val headline = 17.sp
    val body = 17.sp
    val callout = 16.sp
    val subheadline = 15.sp
    val footnote = 13.sp
    val caption = 12.sp
    val caption2 = 11.sp
}

/** SF-Symbol-Name → passendes Material-Symbol. */
fun sfIcon(name: String): ImageVector = when (name) {
    "figure.golf", "figure.golf.circle", "figure.golf.circle.fill" -> Icons.Filled.SportsGolf
    "leaf.fill", "leaf.circle.fill" -> Icons.Filled.Eco
    "circle.bottomhalf.filled" -> Icons.Filled.Contrast
    "drop.fill" -> Icons.Filled.WaterDrop
    "circle.fill" -> Icons.Filled.Circle
    "magnifyingglass" -> Icons.Filled.Search
    "magnifyingglass.circle.fill" -> Icons.Filled.ManageSearch
    "xmark.circle.fill", "xmark.seal.fill" -> Icons.Filled.Cancel
    "arrow.up.and.down.circle.fill", "arrow.up.arrow.down" -> Icons.Filled.SwapVert
    "person.fill" -> Icons.Filled.Person
    "person.2.fill" -> Icons.Filled.People
    "person.2.circle.fill" -> Icons.Filled.SupervisedUserCircle
    "person.3.fill", "person.3.sequence.fill", "person.2.wave.2.fill" -> Icons.Filled.Groups
    "trophy.fill" -> Icons.Filled.EmojiEvents
    "book.closed.fill" -> Icons.AutoMirrored.Filled.MenuBook
    "book.fill" -> Icons.Filled.Book
    "list.number" -> Icons.Filled.FormatListNumbered
    "mappin.and.ellipse" -> Icons.Filled.PinDrop
    "mappin.circle.fill" -> Icons.Filled.LocationOn
    "checklist" -> Icons.Filled.Checklist
    "chart.bar.fill" -> Icons.Filled.BarChart
    "chart.bar.doc.horizontal.fill" -> Icons.Filled.Assessment
    "target" -> Icons.Filled.GpsFixed
    "scope" -> Icons.Filled.Adjust
    "star" -> Icons.Outlined.StarOutline
    "star.fill" -> Icons.Filled.Star
    "star.circle.fill" -> Icons.Filled.Stars
    "brain.head.profile" -> Icons.Filled.Psychology
    "map" -> Icons.Outlined.Map
    "map.fill" -> Icons.Filled.Map
    "graduationcap.fill" -> Icons.Filled.School
    "hands.clap.fill", "hand.raised.fingers.spread.fill" -> Icons.Filled.FrontHand
    "hand.raised.fill" -> Icons.Filled.PanTool
    "hand.thumbsup.fill" -> Icons.Filled.ThumbUp
    "arrow.up.circle.fill" -> Icons.Filled.ArrowCircleUp
    "arrow.down.circle.fill" -> Icons.Filled.ArrowCircleDown
    "arrow.right.circle.fill" -> Icons.Filled.ArrowCircleRight
    "arrow.up.right", "arrow.up.right.circle.fill" -> Icons.Filled.NorthEast
    "arrow.down.right", "arrow.down.right.circle.fill" -> Icons.Filled.SouthEast
    "eye.fill" -> Icons.Filled.Visibility
    "eye.circle.fill" -> Icons.Filled.RemoveRedEye
    "figure.stand" -> Icons.Filled.Accessibility
    "figure.walk" -> Icons.AutoMirrored.Filled.DirectionsWalk
    "wind" -> Icons.Filled.Air
    "repeat", "repeat.circle.fill" -> Icons.Filled.Repeat
    "repeat.1.circle.fill" -> Icons.Filled.RepeatOne
    "flag.fill" -> Icons.Filled.Flag
    "circle.dotted" -> Icons.Filled.BlurCircular
    "arrow.clockwise", "arrow.clockwise.circle.fill", "rotate.right" -> Icons.Filled.RotateRight
    "lungs.fill" -> Icons.Filled.SelfImprovement
    "tortoise.fill" -> Icons.Filled.Spa
    "slider.horizontal.3" -> Icons.Filled.Tune
    "flame.fill" -> Icons.Filled.LocalFireDepartment
    "flame.circle.fill" -> Icons.Filled.Whatshot
    "cloud.rain.fill" -> Icons.Filled.Umbrella
    "speedometer" -> Icons.Filled.Speed
    "timer" -> Icons.Filled.Timer
    "minus.circle.fill" -> Icons.Filled.RemoveCircle
    "minus.circle" -> Icons.Filled.RemoveCircleOutline
    "bolt.circle.fill" -> Icons.Filled.Bolt
    "chart.line.uptrend.xyaxis" -> Icons.AutoMirrored.Filled.TrendingUp
    "chart.line.downtrend.xyaxis" -> Icons.AutoMirrored.Filled.TrendingDown
    "lightbulb.fill" -> Icons.Filled.Lightbulb
    "arrow.up.and.line.horizontal.and.arrow.down" -> Icons.Filled.Height
    "checkmark.circle.fill" -> Icons.Filled.CheckCircle
    "checkmark" -> Icons.Filled.Check
    "arrow.left.and.right" -> Icons.Filled.SwapHoriz
    "arrow.left.and.right.circle.fill" -> Icons.Filled.SwapHorizontalCircle
    "sparkles" -> Icons.Filled.AutoAwesome
    "scalemass.fill" -> Icons.Filled.Scale
    "ruler.fill" -> Icons.Filled.Straighten
    "exclamationmark.triangle.fill" -> Icons.Filled.Warning
    "exclamationmark.circle" -> Icons.Outlined.ErrorOutline
    "arrow.right.to.line" -> Icons.AutoMirrored.Filled.KeyboardTab
    "1.circle.fill" -> Icons.Filled.LooksOne
    "heart.fill" -> Icons.Filled.Favorite
    "seal.fill", "checkmark.seal.fill" -> Icons.Filled.Verified
    "ticket.fill" -> Icons.Filled.ConfirmationNumber
    "arrow.triangle.2.circlepath", "arrow.triangle.2.circlepath.circle.fill" -> Icons.Filled.Sync
    "clock" -> Icons.Filled.Schedule
    "clock.badge" -> Icons.Filled.MoreTime
    "doc.text.fill" -> Icons.Filled.Description
    "arrow.uturn.backward" -> Icons.AutoMirrored.Filled.Undo
    "arrow.uturn.backward.circle.fill" -> Icons.Filled.Replay
    "arrow.uturn.right.circle.fill" -> Icons.AutoMirrored.Filled.Redo
    "arrow.counterclockwise" -> Icons.Filled.Restore
    "ellipsis.circle" -> Icons.Filled.MoreHoriz
    "photo", "photo.fill" -> Icons.Filled.Image
    "info.circle" -> Icons.Outlined.Info
    "trash" -> Icons.Filled.Delete
    "xmark" -> Icons.Filled.Close
    "plus" -> Icons.Filled.Add
    "minus" -> Icons.Filled.Remove
    "plus.circle.fill" -> Icons.Filled.AddCircle
    "calendar" -> Icons.Filled.CalendarToday
    "chevron.left" -> Icons.Filled.KeyboardArrowLeft
    "chevron.right" -> Icons.Filled.KeyboardArrowRight
    "chevron.up" -> Icons.Filled.KeyboardArrowUp
    "chevron.down" -> Icons.Filled.KeyboardArrowDown
    "wifi" -> Icons.Filled.Wifi
    "battery.100" -> Icons.Filled.BatteryFull
    "play.fill" -> Icons.Filled.PlayArrow
    "arrow.right" -> Icons.AutoMirrored.Filled.ArrowForward
    "square.grid.3x3.fill" -> Icons.Filled.Apps
    "gearshape.fill" -> Icons.Filled.Settings
    else -> Icons.Filled.Circle
}

@Composable
fun SfIcon(name: String, tint: Color, size: Dp, modifier: Modifier = Modifier) {
    Icon(sfIcon(name), contentDescription = null, tint = tint, modifier = modifier.size(size))
}

/** Hält Inhalte auf Tablets auf lesbarer Breite (wie `.readableWidth()` auf iOS). */
@Composable
fun ReadableWidth(maxWidth: Dp = 720.dp, content: @Composable BoxScope.() -> Unit) {
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Box(Modifier.widthIn(max = maxWidth).fillMaxWidth(), content = content)
    }
}

/** Quadratische, eingefärbte Icon-Kachel wie in den iOS-Listenzeilen. */
@Composable
fun IconTile(icon: String, color: Color, size: Dp = 44.dp, iconSize: Dp = 22.dp, radius: Dp = 10.dp, bgAlpha: Float = 0.15f) {
    Box(
        Modifier.size(size).background(color.copy(alpha = bgAlpha), RoundedCornerShape(radius)),
        contentAlignment = Alignment.Center,
    ) { SfIcon(icon, color, iconSize) }
}

/** Eine Zeile im „insetGrouped“-Listenstil: eigene Karte, rechts ein Chevron. */
@Composable
fun ListCardRow(onClick: (() -> Unit)?, chevron: Boolean = onClick != null, content: @Composable BoxScope.() -> Unit) {
    var m = Modifier.fillMaxWidth().background(AppTheme.card, RoundedCornerShape(12.dp))
    // Navigationszeilen bewusst ohne Haptik (wie NavigationLink auf iOS).
    if (onClick != null) m = m.clickable { onClick() }
    Row(
        m.padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(Modifier.weight(1f), content = content)
        if (chevron) SfIcon("chevron.right", AppTheme.textTer, 20.dp)
    }
}

/** Abgerundete Fläche mit Hintergrund – wie `.background(color, in: RoundedRectangle)`. */
fun Modifier.rounded(color: Color, radius: Dp = 14.dp): Modifier = this.background(color, RoundedCornerShape(radius))

@Composable
fun T(
    text: String,
    size: TextUnit = IosFont.body,
    color: Color = AppTheme.text,
    weight: FontWeight? = null,
    modifier: Modifier = Modifier,
    maxLines: Int = Int.MAX_VALUE,
    align: androidx.compose.ui.text.style.TextAlign? = null,
    lineHeight: TextUnit = TextUnit.Unspecified,
) {
    Text(
        text, modifier = modifier, color = color, fontSize = size, fontWeight = weight,
        maxLines = maxLines, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis,
        textAlign = align, lineHeight = lineHeight,
    )
}

/** Box mit Inhalt, Spalte mit festen Abständen – kleiner Helfer für Detailkarten. */
@Composable
fun VStack(modifier: Modifier = Modifier, spacing: Dp = 0.dp, alignment: Alignment.Horizontal = Alignment.Start, content: @Composable ColumnScope.() -> Unit) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(spacing), horizontalAlignment = alignment, content = content)
}
