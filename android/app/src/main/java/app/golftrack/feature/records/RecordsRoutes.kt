package app.golftrack.feature.records

import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import app.golftrack.ui.common.Routes

/** Ziele, die nur innerhalb dieses Pakets angesprungen werden. */
internal object RecordsInternalRoutes {
    const val ADD_COURSE = "records/courses/add"
    const val SCAN = "records/courses/scan"
    const val GEOMETRY = "records/geometry/{courseId}"
    fun geometry(courseId: String) = "records/geometry/$courseId"
    const val GEOMETRY_HOLE = "records/geometry/{courseId}/hole/{hole}"
    fun geometryHole(courseId: String, hole: Int) = "records/geometry/$courseId/hole/$hole"
    const val FAIRWAY = "records/fairway/{courseId}"
    fun fairway(courseId: String) = "records/fairway/$courseId"
}

fun NavGraphBuilder.recordsRoutes(nav: NavController) {
    composable(Routes.HISTORY) { HistoryScreen(nav) }
    composable(Routes.ROUND_DETAIL) { e -> RoundDetailScreen(nav, e.arguments?.getString("roundId") ?: "") }
    composable(Routes.STATISTICS) { StatisticsScreen(nav) }
    composable(Routes.COURSES) { CourseListScreen(nav) }
    composable(Routes.COURSE_EDIT) { e -> CourseEditScreen(nav, e.arguments?.getString("courseId") ?: NEW_COURSE_ID) }
    composable(RecordsInternalRoutes.ADD_COURSE) { AddCourseScreen(nav) }
    composable(RecordsInternalRoutes.SCAN) { ScorecardScannerScreen(nav) }
    composable(RecordsInternalRoutes.GEOMETRY) { e -> CourseGeometryReviewScreen(nav, e.arguments?.getString("courseId") ?: "") }
    composable(RecordsInternalRoutes.GEOMETRY_HOLE) { e ->
        HoleGeometryDetailScreen(nav, e.arguments?.getString("courseId") ?: "", e.arguments?.getString("hole")?.toIntOrNull() ?: 1)
    }
    composable(RecordsInternalRoutes.FAIRWAY) { e -> FairwayCorridorScreen(nav, e.arguments?.getString("courseId") ?: "") }
}
